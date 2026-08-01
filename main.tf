terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.40"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.40"
    }
  }

  # Remote state recommended for staging/production. Local backend kept for candidate review.
  backend "local" {
    path = "terraform.tfstate"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Row access policies are exposed via the google-beta provider.
provider "google-beta" {
  project = var.project_id
  region  = var.region
}

locals {
  name_prefix = "habot-${var.environment}"

  # D0 = Raw Landing, D1 = Staged/Enforced (HabotConnect data layer naming)
  d0_bucket_name = "${local.name_prefix}-d0-raw-landing-${var.project_id}"
  d1_dataset_id  = replace("${local.name_prefix}_d1_staged_enforced", "-", "_")

  labels = {
    application = "habotconnect"
    environment = var.environment
    data_layer  = "controlled"
    managed_by  = "terraform"
    owner_team  = "platform-engineering"
  }
}

# -----------------------------------------------------------------------------
# D0 Raw Landing — Google Cloud Storage
# -----------------------------------------------------------------------------
resource "google_storage_bucket" "d0_raw_landing" {
  name                        = local.d0_bucket_name
  location                    = var.region
  project                     = var.project_id
  force_destroy               = false
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  storage_class               = "STANDARD"

  versioning {
    enabled = true
  }

  # Soft delete retention protects against accidental purge of landing objects.
  soft_delete_policy {
    retention_duration_seconds = 604800 # 7 days
  }

  lifecycle_rule {
    condition {
      age = var.raw_object_retention_days
    }
    action {
      type          = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }

  lifecycle_rule {
    condition {
      age = var.raw_object_retention_days + 90
    }
    action {
      type = "Delete"
    }
  }

  dynamic "encryption" {
    for_each = var.kms_crypto_key_id == null ? [] : [var.kms_crypto_key_id]
    content {
      default_kms_key_name = encryption.value
    }
  }

  labels = merge(local.labels, {
    data_layer = "d0-raw-landing"
  })
}

# -----------------------------------------------------------------------------
# D1 Staged/Enforced — BigQuery dataset and enforced schema table
# -----------------------------------------------------------------------------
resource "google_bigquery_dataset" "d1_staged_enforced" {
  dataset_id                 = local.d1_dataset_id
  project                    = var.project_id
  location                   = var.region
  delete_contents_on_destroy = false
  description                = "D1 Staged and Enforced analytics dataset for HabotConnect student onboarding events. Schema is enforced; Row-Level Security applies."

  labels = merge(local.labels, {
    data_layer = "d1-staged-enforced"
  })

  default_table_expiration_ms = null

  access {
    role          = "OWNER"
    special_group = "projectOwners"
  }

  # Explicit dataset access is also managed in iam.tf for service accounts.
  dynamic "access" {
    for_each = var.dataset_reader_members
    content {
      role          = "READER"
      user_by_email = access.value
    }
  }
}

resource "google_bigquery_table" "student_onboarding_events" {
  dataset_id          = google_bigquery_dataset.d1_staged_enforced.dataset_id
  table_id            = "student_onboarding_events"
  project             = var.project_id
  deletion_protection = true
  description         = "Enforced schema sink aligned with Decide Yes or No validated student onboarding payloads and Pub/Sub streaming."

  labels = merge(local.labels, {
    data_layer = "d1-staged-enforced"
    schema     = "enforced"
  })

  # Schema must match docs/schema-mapping.csv and task3-dcyn serializers.
  schema = jsonencode([
    {
      name        = "event_id"
      type        = "STRING"
      mode        = "REQUIRED"
      description = "Universally unique identifier for the onboarding event"
    },
    {
      name        = "ingested_at"
      type        = "TIMESTAMP"
      mode        = "REQUIRED"
      description = "Coordinated Universal Time timestamp when the event landed in D1"
    },
    {
      name        = "parent_full_name"
      type        = "STRING"
      mode        = "REQUIRED"
      description = "Legal full name of the parent or guardian"
    },
    {
      name        = "parent_electronic_mail"
      type        = "STRING"
      mode        = "REQUIRED"
      description = "Parent electronic mail address"
    },
    {
      name        = "student_full_name"
      type        = "STRING"
      mode        = "REQUIRED"
      description = "Legal full name of the student"
    },
    {
      name        = "student_date_of_birth"
      type        = "DATE"
      mode        = "REQUIRED"
      description = "Student date of birth in International Organization for Standardization 8601 date format"
    },
    {
      name        = "learning_support_region"
      type        = "STRING"
      mode        = "REQUIRED"
      description = "Authorized learning support region code used for Row-Level Security"
    },
    {
      name        = "has_diagnosed_learning_difficulty"
      type        = "BOOLEAN"
      mode        = "REQUIRED"
      description = "Decide Yes or No: whether a diagnosed learning difficulty is declared"
    },
    {
      name        = "requires_learning_support_assistant"
      type        = "BOOLEAN"
      mode        = "REQUIRED"
      description = "Decide Yes or No: whether a Learning Support Assistant is required"
    },
    {
      name        = "consent_to_data_processing"
      type        = "BOOLEAN"
      mode        = "REQUIRED"
      description = "Decide Yes or No: explicit consent for personal data processing"
    },
    {
      name        = "consent_to_analytics_export"
      type        = "BOOLEAN"
      mode        = "REQUIRED"
      description = "Decide Yes or No: explicit consent for analytics export to BigQuery"
    },
    {
      name        = "weekly_support_hours_requested"
      type        = "INTEGER"
      mode        = "REQUIRED"
      description = "Requested weekly support hours; must be between 1 and 40 inclusive"
    },
    {
      name        = "payload_schema_version"
      type        = "STRING"
      mode        = "REQUIRED"
      description = "Schema version string for forward-compatible streaming validation"
    }
  ])

  time_partitioning {
    type  = "DAY"
    field = "ingested_at"
  }

  clustering = ["learning_support_region", "requires_learning_support_assistant"]
}

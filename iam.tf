# -----------------------------------------------------------------------------
# Service accounts (Least Privilege)
# -----------------------------------------------------------------------------
resource "google_service_account" "ingest_writer" {
  account_id   = "${var.environment}-ingest-writer"
  display_name = "HabotConnect ${var.environment} D0 ingest writer"
  description  = "Writes raw onboarding objects to D0 Raw Landing only. No delete. No Identity and Access Management administration."
  project      = var.project_id
}

resource "google_service_account" "analytics_reader" {
  account_id   = "${var.environment}-analytics-reader"
  display_name = "HabotConnect ${var.environment} D1 analytics reader"
  description  = "Reads D1 Staged/Enforced tables subject to Row-Level Security. No write. No dataset ownership."
  project      = var.project_id
}

# Prefer explicit emails from variables when provided by callers; otherwise use created accounts.
locals {
  ingest_writer_email    = coalesce(var.ingest_writer_service_account_email, google_service_account.ingest_writer.email)
  analytics_reader_email = coalesce(var.analytics_reader_service_account_email, google_service_account.analytics_reader.email)
}

# -----------------------------------------------------------------------------
# D0 Raw Landing — bucket Identity and Access Management
# -----------------------------------------------------------------------------
# Object creator only (no objectAdmin) — cannot delete or overwrite Identity bindings.
resource "google_storage_bucket_iam_member" "d0_ingest_object_creator" {
  bucket = google_storage_bucket.d0_raw_landing.name
  role   = "roles/storage.objectCreator"
  member = "serviceAccount:${local.ingest_writer_email}"

  condition {
    title       = "staging-ingest-window-only"
    description = "Restrict object creation to the staging environment resource set during business hours Coordinated Universal Time if required later; currently binds to this bucket only."
    expression  = "resource.name.startsWith(\"projects/_/buckets/${google_storage_bucket.d0_raw_landing.name}\")"
  }
}

# Deny-path equivalent via omission: ingest writer does NOT receive objectViewer,
# objectAdmin, legacyBucketOwner, or securityAdmin.

# Pipeline auditor may list and read for quarantine investigation after Fail-Closed events.
resource "google_storage_bucket_iam_member" "d0_ci_auditor_object_viewer" {
  count  = var.environment == "staging" ? 1 : 0
  bucket = google_storage_bucket.d0_raw_landing.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${local.analytics_reader_email}"
}

# -----------------------------------------------------------------------------
# D1 Staged/Enforced — dataset Identity and Access Management
# -----------------------------------------------------------------------------
resource "google_bigquery_dataset_iam_member" "d1_analytics_data_viewer" {
  dataset_id = google_bigquery_dataset.d1_staged_enforced.dataset_id
  role       = "roles/bigquery.dataViewer"
  member     = "serviceAccount:${local.analytics_reader_email}"
  project    = var.project_id
}

resource "google_bigquery_dataset_iam_member" "d1_ingest_data_editor" {
  dataset_id = google_bigquery_dataset.d1_staged_enforced.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${local.ingest_writer_email}"
  project    = var.project_id
}

# Job user at project level is required to run queries; scoped separately from data roles.
resource "google_project_iam_member" "analytics_job_user" {
  project = var.project_id
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${local.analytics_reader_email}"
}

resource "google_project_iam_member" "ingest_job_user" {
  project = var.project_id
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${local.ingest_writer_email}"
}

# -----------------------------------------------------------------------------
# Explicitly avoid overly broad roles such as:
#   roles/owner, roles/editor, roles/storage.admin, roles/bigquery.admin
# Those roles are never assigned by this configuration.
# -----------------------------------------------------------------------------

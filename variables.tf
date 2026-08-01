variable "project_id" {
  description = "Google Cloud Platform project identifier where staging resources are provisioned."
  type        = string

  validation {
    condition     = length(var.project_id) > 0 && can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "project_id must be a valid Google Cloud Platform project identifier."
  }
}

variable "region" {
  description = "Primary Google Cloud Platform region for the Storage bucket and BigQuery dataset."
  type        = string
  default     = "asia-south1"
}

variable "environment" {
  description = "Deployment environment name. Allowed values: staging, production."
  type        = string
  default     = "staging"

  validation {
    condition     = contains(["staging", "production"], var.environment)
    error_message = "environment must be either staging or production."
  }
}

variable "raw_object_retention_days" {
  description = "Number of days before D0 Raw Landing objects transition to Nearline storage class."
  type        = number
  default     = 30

  validation {
    condition     = var.raw_object_retention_days >= 7 && var.raw_object_retention_days <= 365
    error_message = "raw_object_retention_days must be between 7 and 365 inclusive."
  }
}

variable "kms_crypto_key_id" {
  description = "Optional Customer-Managed Encryption Key resource name. Leave empty to use Google-managed encryption."
  type        = string
  default     = null
  nullable    = true
}

variable "ingest_writer_service_account_email" {
  description = "Optional existing service account electronic mail for D0 writes. When null, Terraform creates staging-ingest-writer."
  type        = string
  default     = null
  nullable    = true
}

variable "analytics_reader_service_account_email" {
  description = "Optional existing service account electronic mail for D1 reads. When null, Terraform creates staging-analytics-reader."
  type        = string
  default     = null
  nullable    = true
}

variable "dataset_reader_members" {
  description = "Additional human user electronic mail addresses granted BigQuery dataset READER access."
  type        = list(string)
  default     = []
}

variable "row_level_security_region_filter" {
  description = "Learning support region code enforced by BigQuery Row-Level Security for the analytics reader."
  type        = string
  default     = "IN-WEST"

  validation {
    condition     = can(regex("^[A-Z]{2}-[A-Z]+$", var.row_level_security_region_filter))
    error_message = "row_level_security_region_filter must look like IN-WEST or SG-CENTRAL."
  }
}

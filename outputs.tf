output "d0_raw_landing_bucket_name" {
  description = "Name of the D0 Raw Landing Google Cloud Storage bucket."
  value       = google_storage_bucket.d0_raw_landing.name
}

output "d0_raw_landing_bucket_url" {
  description = "Uniform Resource Locator of the D0 Raw Landing bucket."
  value       = google_storage_bucket.d0_raw_landing.url
}

output "d1_dataset_id" {
  description = "BigQuery dataset identifier for D1 Staged and Enforced."
  value       = google_bigquery_dataset.d1_staged_enforced.dataset_id
}

output "d1_student_onboarding_table_id" {
  description = "Fully qualified BigQuery table identifier for student onboarding events."
  value       = "${var.project_id}.${google_bigquery_dataset.d1_staged_enforced.dataset_id}.${google_bigquery_table.student_onboarding_events.table_id}"
}

output "ingest_writer_service_account_email" {
  description = "Service account used for D0 ingest writes and D1 data edits."
  value       = local.ingest_writer_email
}

output "analytics_reader_service_account_email" {
  description = "Service account used for D1 analytics reads under Row-Level Security."
  value       = local.analytics_reader_email
}

output "row_level_security_region_filter" {
  description = "Learning support region enforced by Row-Level Security."
  value       = var.row_level_security_region_filter
}

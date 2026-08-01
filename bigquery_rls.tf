# -----------------------------------------------------------------------------
# BigQuery Row-Level Security (RLS)
# Restricts analytics readers to rows for an authorized learning support region.
# -----------------------------------------------------------------------------

resource "google_bigquery_row_access_policy" "region_filter_for_analytics_reader" {
  provider = google-beta

  project    = var.project_id
  dataset_id = google_bigquery_dataset.d1_staged_enforced.dataset_id
  table_id   = google_bigquery_table.student_onboarding_events.table_id
  policy_id  = "learning_support_region_filter"

  filter_predicate = "learning_support_region = \"${var.row_level_security_region_filter}\""

  grantees = [
    "serviceAccount:${local.analytics_reader_email}",
  ]
}

# Consent-gated analytics: readers may only see rows where analytics export consent is true.
resource "google_bigquery_row_access_policy" "consent_filter_for_analytics_reader" {
  provider = google-beta

  project    = var.project_id
  dataset_id = google_bigquery_dataset.d1_staged_enforced.dataset_id
  table_id   = google_bigquery_table.student_onboarding_events.table_id
  policy_id  = "analytics_export_consent_filter"

  filter_predicate = "consent_to_analytics_export = TRUE"

  grantees = [
    "serviceAccount:${local.analytics_reader_email}",
  ]
}

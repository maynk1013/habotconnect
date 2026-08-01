# Task 3: Schema Mapping and Decide Yes or No Validation

**Candidate Full Name:** Mayank  
**Contact Electronic Mail Address:** mayankrai0310@gmail.com 
**Contact Telephone Number:** 9711200512

## Objective

Deconstruct an incoming student onboarding JavaScript Object Notation payload into a binary Yes or No logic library (Decide Yes or No). Enforce exact field validation limits in a Django REST Framework serializer so human judgment is eliminated at the application boundary.

## Decide Yes or No Library

Every business checkpoint that historically relied on discretionary review becomes a deterministic boolean:

| Decision Function | Yes Means | No Means |
| --- | --- | --- |
| `is_student_age_eligible` | Age is between 5 and 18 inclusive | Outside range — reject |
| `has_diagnosed_learning_difficulty` | Parent declared diagnosis | No diagnosis declared |
| `requires_learning_support_assistant` | Assistance required | Assistance not required |
| `has_valid_parent_consent_to_process` | Explicit processing consent | Missing consent — reject |
| `has_valid_analytics_export_consent` | Explicit analytics consent | Missing consent — row excluded by Row-Level Security |
| `is_weekly_support_hours_within_limit` | Hours between 1 and 40 | Outside limit — reject |
| `is_learning_support_region_recognized` | Region in allowlist | Unknown region — reject |
| `is_schema_version_supported` | Version equals `1.0.0` | Unsupported — reject |
| `is_onboarding_acceptable` | All hard gates are Yes | Any hard gate is No |

## Alignment With BigQuery

Field names and types match `docs/schema-mapping.csv` and `task1-terraform/main.tf` so Pub/Sub to BigQuery streaming cannot diverge from the application contract.

## Quick Test

```bash
pip install -r requirements.txt
python -c "import json; from dcyn.serializers import validate_onboarding_payload as v; print(v(json.load(open('sample_payload.json'))))"
python -c "import json; from dcyn.serializers import validate_onboarding_payload as v; print(v(json.load(open('sample_payload_invalid.json'))))"
```

# Presentation Outline (Maximum 15 Slides)

**Candidate Full Name:** Mayank  
**Contact Electronic Mail Address:** REPLACE_WITH_YOUR_EMAIL  
**Contact Telephone Number:** REPLACE_WITH_YOUR_PHONE  

Copy these slides into Google Slides or PowerPoint. Keep the total at or under 15 slides. Link this Git repository Uniform Resource Locator on the closing slide.

---

## Slide 1 — Title

- HabotConnect Hiring Project
- Junior Cloud and DevOps Engineer (Google Cloud Platform / Django / React)
- Candidate: Mayank
- Date: August 2026

## Slide 2 — Why This Project Exists

- Reality-mimicking staging incident: hardcoded secrets + schema mismatch
- Goal: restore integrity with Poka-Yoke (mistake-proofing), not hope

## Slide 3 — Assessment Areas Covered

1. Infrastructure as Code
2. Fail-Closed continuous integration gates
3. Schema validation and Decide Yes or No logic
4. Identity and Access Management / Least Privilege
5. Documentation rigor

## Slide 4 — Architecture Overview

- React form → Django REST Framework → D0 Google Cloud Storage → D1 BigQuery
- Diagram from `docs/architecture-overview.md`

## Slide 5 — Task 1: D0 Raw Landing Bucket

- Uniform bucket-level access enforced
- Public access prevention enforced
- Versioning and soft-delete retention
- Object creator only for ingest writer (not object admin)

## Slide 6 — Task 1: D1 Staged/Enforced BigQuery

- Enforced table schema matching the onboarding contract
- Partition by `ingested_at`, cluster by region and Learning Support Assistant flag
- Deletion protection enabled

## Slide 7 — Task 1: Identity and Row-Level Security

- Separate ingest writer and analytics reader service accounts
- Row-Level Security: region filter + analytics consent filter
- No Owner / Editor / Storage Admin roles in the data path

## Slide 8 — Task 2: Poka-Yoke Gate Design

- Formatting (Ruff format --check)
- Lint (Ruff check)
- Terraform fmt + validate
- Secret scan (custom patterns + Gitleaks)
- Serializer validation

## Slide 9 — Fail-Closed Demonstration

- Show `task2-cicd/scripts/demonstrate-fail-closed.sh` output
- Temporary hardcoded key ⇒ non-zero exit ⇒ quarantine marker
- Secure sample ⇒ zero findings

## Slide 10 — Quarantine Behavior

- `artifacts/quarantine/quarantine-<commit>.txt`
- Deploy job depends on all gates with `needs` + `if: success()`
- No warn-and-continue for secret findings

## Slide 11 — Task 3: Decide Yes or No Library

- Binary decisions only (Yes / No)
- Hard gates: age, processing consent, hours range, region, schema version
- Soft/informational: diagnosis flag, Learning Support Assistant requirement

## Slide 12 — Task 3: Django REST Framework Serializer

- Exact min/max lengths and numeric bounds
- Choice fields for region and schema version
- `validate()` rejects when Decide Yes or No hard gates fail

## Slide 13 — Schema Mapping Contract

- Single spreadsheet: `docs/schema-mapping.csv`
- Wrap Text enabled; Full Forms Only
- Prevents Pub/Sub → BigQuery drift

## Slide 14 — Evidence and Repository Map

- `task1-terraform/`
- `task2-cicd/` + `.github/workflows/poka-yoke-build-gate.yml`
- `task3-dcyn/`
- `docs/`

## Slide 15 — Closing

- Repository Uniform Resource Locator: (paste after you push to GitHub)
- Contact: Mayank / REPLACE_WITH_YOUR_EMAIL / REPLACE_WITH_YOUR_PHONE
- Ready for panel questions on Least Privilege, Fail-Closed design, and schema enforcement

# Architectural Overview and Logic Flow

**Candidate Full Name:** Mayank  
**Contact Electronic Mail Address:** REPLACE_WITH_YOUR_EMAIL  
**Contact Telephone Number:** REPLACE_WITH_YOUR_PHONE  

## Problem Restatement

A junior developer pushed changes that:

1. Left unencrypted application programming interface credentials in raw application code.
2. Introduced a database schema mismatch that broke downstream analytics.

This blueprint restores integrity with automated mistake-proofing rather than human memory.

## End-to-End Flow

```text
Parent submits student onboarding form (React)
        |
        v
Django REST Framework serializer + Decide Yes or No hard gates
        |
        +-- Reject (HTTP 400) if any hard gate is No
        |
        v
Validated event written to transactional store
        |
        v
Object copy / event published to D0 Raw Landing (Google Cloud Storage)
        |
        v
Streaming / load into D1 Staged/Enforced (BigQuery) with identical schema
        |
        v
Row-Level Security limits analytics readers by region and consent
```

## Continuous Integration Fail-Closed Gate

```text
Pull Request / Push
   |
   +--> Formatting and Lint Gate  ---- fail? ----> HALT (no deploy)
   |
   +--> Secret Scan Gate ---------- fail? ----> QUARANTINE + HALT
   |
   +--> Serializer Validation Gate - fail? ----> HALT
   |
   v
Staging deploy permitted only when all gates succeed
```

## Least Privilege Identity Model

| Principal | May | Must Not |
| --- | --- | --- |
| Ingest writer service account | Create objects in D0; edit D1 rows | Delete bucket objects as admin; change Identity and Access Management; own dataset |
| Analytics reader service account | Read D1 under Row-Level Security; run jobs | Write D1; read other regions; bypass consent filter |
| Human project owners | Break-glass ownership | Day-to-day data plane access via owner role in application paths |

## Why This Prevents Recurrence

1. **Secrets cannot merge** — custom pattern scan plus Gitleaks fail the build.
2. **Schema cannot drift silently** — one mapping sheet drives Django, Terraform, and tests.
3. **Analytics cannot leak cross-region** — BigQuery Row-Level Security binds readers to an authorized region and consent flag.
4. **Formatting debt cannot accumulate** — Ruff format check is Fail-Closed.

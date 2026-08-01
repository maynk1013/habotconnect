# Schema Mapping Spreadsheet Instructions

**Candidate Full Name:** Mayank  
**Contact Electronic Mail Address:** REPLACE_WITH_YOUR_EMAIL  
**Contact Telephone Number:** REPLACE_WITH_YOUR_PHONE  

## How to Import

1. Open Google Sheets or Microsoft Excel.
2. Import `docs/schema-mapping.csv`.
3. Select all data cells.
4. Enable **Wrap Text** so every validation rule remains fully visible.
5. Use Full Forms Only — do not replace field names with slang, abbreviations, or placeholders.

## Purpose

This mapping is the single contract between:

- Django REST Framework serializers (`task3-dcyn/dcyn/serializers.py`)
- Decide Yes or No hard gates (`task3-dcyn/dcyn/library.py`)
- BigQuery enforced schema (`task1-terraform/main.tf`)
- Row-Level Security predicates (`task1-terraform/bigquery_rls.tf`)

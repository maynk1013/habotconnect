# INTENTIONAL INSECURE FIXTURE — for Fail-Closed demonstration only.
# This file is allowlisted in continuous integration so the repository remains green.
# Do not copy these patterns into application code.


def get_legacy_client():
    # Simulated mistake from the hiring scenario: raw credentials in application code.
    api_key = "FAKESECRET_e3f4g5h6i7j8k9l0m1n2"
    django_secret = "DJANGO_SECRET_KEY = 'insecure-django-secret-key-value'"
    return {"api_key": api_key, "note": django_secret}

"""
Django REST Framework serializers with exact field validation limits.

Candidate Full Name: Mayank

Human judgment is eliminated: acceptance is entirely determined by field
validators plus the Decide Yes or No hard-gate matrix.
"""

from __future__ import annotations

import uuid
from typing import Any

import django
from django.conf import settings

if not settings.configured:
    settings.configure(
        DEBUG=False,
        USE_I18N=False,
        USE_TZ=True,
        SECRET_KEY=f"ci-bootstrap-{uuid.uuid4()}",
        ROOT_URLCONF=__name__,
        INSTALLED_APPS=[
            "django.contrib.contenttypes",
            "django.contrib.auth",
            "rest_framework",
        ],
    )
    django.setup()

from rest_framework import serializers

from dcyn.library import (
    MAXIMUM_WEEKLY_SUPPORT_HOURS,
    MINIMUM_WEEKLY_SUPPORT_HOURS,
    RECOGNIZED_LEARNING_SUPPORT_REGIONS,
    SUPPORTED_SCHEMA_VERSIONS,
    DecideYesOrNoLibrary,
)


class StudentOnboardingSerializer(serializers.Serializer):
    """Validates a student onboarding JavaScript Object Notation payload."""

    event_id = serializers.UUIDField(required=True)
    parent_full_name = serializers.CharField(
        required=True,
        min_length=2,
        max_length=120,
        trim_whitespace=True,
    )
    parent_electronic_mail = serializers.EmailField(
        required=True,
        max_length=254,
    )
    student_full_name = serializers.CharField(
        required=True,
        min_length=2,
        max_length=120,
        trim_whitespace=True,
    )
    student_date_of_birth = serializers.DateField(
        required=True,
        input_formats=["%Y-%m-%d"],
    )
    learning_support_region = serializers.ChoiceField(
        required=True,
        choices=sorted(RECOGNIZED_LEARNING_SUPPORT_REGIONS),
    )
    has_diagnosed_learning_difficulty = serializers.BooleanField(required=True)
    requires_learning_support_assistant = serializers.BooleanField(required=True)
    consent_to_data_processing = serializers.BooleanField(required=True)
    consent_to_analytics_export = serializers.BooleanField(required=True)
    weekly_support_hours_requested = serializers.IntegerField(
        required=True,
        min_value=MINIMUM_WEEKLY_SUPPORT_HOURS,
        max_value=MAXIMUM_WEEKLY_SUPPORT_HOURS,
    )
    payload_schema_version = serializers.ChoiceField(
        required=True,
        choices=sorted(SUPPORTED_SCHEMA_VERSIONS),
    )

    def validate_student_date_of_birth(self, value):
        if not DecideYesOrNoLibrary.is_student_age_eligible(value):
            raise serializers.ValidationError(
                "Student age must be between 5 and 18 years inclusive on the date of submission."
            )
        return value

    def validate_consent_to_data_processing(self, value):
        if not DecideYesOrNoLibrary.has_valid_parent_consent_to_process(value):
            raise serializers.ValidationError(
                "Consent to data processing must be Yes (true). Soft consent is not accepted."
            )
        return value

    def validate(self, attrs: dict[str, Any]) -> dict[str, Any]:
        decisions = DecideYesOrNoLibrary.evaluate(attrs)
        if not decisions["is_onboarding_acceptable"]:
            failed = [
                name
                for name, passed in decisions.items()
                if name != "is_onboarding_acceptable" and not passed
            ]
            raise serializers.ValidationError(
                {
                    "decide_yes_or_no": (
                        "Onboarding rejected by Decide Yes or No hard gates. "
                        f"Failed decisions: {', '.join(failed)}."
                    ),
                    "decisions": decisions,
                }
            )
        attrs["decide_yes_or_no_decisions"] = decisions
        return attrs


def validate_onboarding_payload(payload: dict[str, Any]) -> dict[str, Any]:
    """Convenience wrapper used by continuous integration and local checks."""
    serializer = StudentOnboardingSerializer(data=payload)
    if serializer.is_valid():
        return {
            "is_valid": True,
            "validated_data": serializer.validated_data,
            "decisions": serializer.validated_data.get("decide_yes_or_no_decisions"),
            "errors": None,
        }
    return {
        "is_valid": False,
        "validated_data": None,
        "decisions": DecideYesOrNoLibrary.evaluate(payload),
        "errors": serializer.errors,
    }

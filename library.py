"""
Decide Yes or No (DCYN) binary logic library.

Candidate Full Name: Mayank

Every function returns a strict boolean. There is no "maybe", soft pass,
or reviewer override path. Application programming interface handlers must
reject the payload when any hard gate returns False.
"""

from __future__ import annotations

from datetime import date, datetime
from typing import Any

SUPPORTED_SCHEMA_VERSIONS = frozenset({"1.0.0"})
RECOGNIZED_LEARNING_SUPPORT_REGIONS = frozenset(
    {
        "IN-WEST",
        "IN-NORTH",
        "IN-SOUTH",
        "IN-EAST",
        "SG-CENTRAL",
        "AE-DUBAI",
    }
)
MINIMUM_STUDENT_AGE_YEARS = 5
MAXIMUM_STUDENT_AGE_YEARS = 18
MINIMUM_WEEKLY_SUPPORT_HOURS = 1
MAXIMUM_WEEKLY_SUPPORT_HOURS = 40


class DecideYesOrNoLibrary:
    """Binary decision helpers for student onboarding payloads."""

    @staticmethod
    def _as_date(value: Any) -> date | None:
        if isinstance(value, date) and not isinstance(value, datetime):
            return value
        if isinstance(value, datetime):
            return value.date()
        if isinstance(value, str):
            try:
                return date.fromisoformat(value)
            except ValueError:
                return None
        return None

    @classmethod
    def is_student_age_eligible(cls, student_date_of_birth: Any, as_of: date | None = None) -> bool:
        birth = cls._as_date(student_date_of_birth)
        if birth is None:
            return False
        today = as_of or date.today()
        age = today.year - birth.year - ((today.month, today.day) < (birth.month, birth.day))
        return MINIMUM_STUDENT_AGE_YEARS <= age <= MAXIMUM_STUDENT_AGE_YEARS

    @staticmethod
    def has_diagnosed_learning_difficulty(value: Any) -> bool:
        return value is True

    @staticmethod
    def requires_learning_support_assistant(value: Any) -> bool:
        return value is True

    @staticmethod
    def has_valid_parent_consent_to_process(value: Any) -> bool:
        return value is True

    @staticmethod
    def has_valid_analytics_export_consent(value: Any) -> bool:
        return value is True

    @staticmethod
    def is_weekly_support_hours_within_limit(hours: Any) -> bool:
        if isinstance(hours, bool) or not isinstance(hours, int):
            return False
        return MINIMUM_WEEKLY_SUPPORT_HOURS <= hours <= MAXIMUM_WEEKLY_SUPPORT_HOURS

    @staticmethod
    def is_learning_support_region_recognized(region: Any) -> bool:
        return isinstance(region, str) and region in RECOGNIZED_LEARNING_SUPPORT_REGIONS

    @staticmethod
    def is_schema_version_supported(version: Any) -> bool:
        return isinstance(version, str) and version in SUPPORTED_SCHEMA_VERSIONS

    @classmethod
    def evaluate(cls, payload: dict[str, Any]) -> dict[str, bool]:
        """Return the full Decide Yes or No matrix for a payload dictionary."""
        decisions = {
            "is_student_age_eligible": cls.is_student_age_eligible(
                payload.get("student_date_of_birth")
            ),
            "has_diagnosed_learning_difficulty": cls.has_diagnosed_learning_difficulty(
                payload.get("has_diagnosed_learning_difficulty")
            ),
            "requires_learning_support_assistant": cls.requires_learning_support_assistant(
                payload.get("requires_learning_support_assistant")
            ),
            "has_valid_parent_consent_to_process": cls.has_valid_parent_consent_to_process(
                payload.get("consent_to_data_processing")
            ),
            "has_valid_analytics_export_consent": cls.has_valid_analytics_export_consent(
                payload.get("consent_to_analytics_export")
            ),
            "is_weekly_support_hours_within_limit": cls.is_weekly_support_hours_within_limit(
                payload.get("weekly_support_hours_requested")
            ),
            "is_learning_support_region_recognized": cls.is_learning_support_region_recognized(
                payload.get("learning_support_region")
            ),
            "is_schema_version_supported": cls.is_schema_version_supported(
                payload.get("payload_schema_version")
            ),
        }
        hard_gates = (
            "is_student_age_eligible",
            "has_valid_parent_consent_to_process",
            "is_weekly_support_hours_within_limit",
            "is_learning_support_region_recognized",
            "is_schema_version_supported",
        )
        decisions["is_onboarding_acceptable"] = all(decisions[name] for name in hard_gates)
        return decisions

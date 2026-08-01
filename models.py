"""
Django model aligned with the BigQuery D1 enforced schema.

Candidate Full Name: Mayank

This model is the transactional source of truth. Field names and constraints
must remain identical to docs/schema-mapping.csv and task1-terraform/main.tf.
"""

from __future__ import annotations

import uuid

from django.core.validators import MaxValueValidator, MinValueValidator
from django.db import models

from dcyn.library import MAXIMUM_WEEKLY_SUPPORT_HOURS, MINIMUM_WEEKLY_SUPPORT_HOURS


class StudentOnboardingEvent(models.Model):
    """Transactional record for a validated student onboarding submission."""

    class LearningSupportRegion(models.TextChoices):
        IN_WEST = "IN-WEST", "India West"
        IN_NORTH = "IN-NORTH", "India North"
        IN_SOUTH = "IN-SOUTH", "India South"
        IN_EAST = "IN-EAST", "India East"
        SG_CENTRAL = "SG-CENTRAL", "Singapore Central"
        AE_DUBAI = "AE-DUBAI", "United Arab Emirates Dubai"

    event_id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    ingested_at = models.DateTimeField(auto_now_add=True)
    parent_full_name = models.CharField(max_length=120)
    parent_electronic_mail = models.EmailField(max_length=254)
    student_full_name = models.CharField(max_length=120)
    student_date_of_birth = models.DateField()
    learning_support_region = models.CharField(
        max_length=32,
        choices=LearningSupportRegion.choices,
    )
    has_diagnosed_learning_difficulty = models.BooleanField()
    requires_learning_support_assistant = models.BooleanField()
    consent_to_data_processing = models.BooleanField()
    consent_to_analytics_export = models.BooleanField()
    weekly_support_hours_requested = models.PositiveSmallIntegerField(
        validators=[
            MinValueValidator(MINIMUM_WEEKLY_SUPPORT_HOURS),
            MaxValueValidator(MAXIMUM_WEEKLY_SUPPORT_HOURS),
        ]
    )
    payload_schema_version = models.CharField(max_length=16, default="1.0.0")

    class Meta:
        ordering = ("-ingested_at",)
        verbose_name = "Student Onboarding Event"
        verbose_name_plural = "Student Onboarding Events"

    def __str__(self) -> str:
        return f"{self.student_full_name} ({self.event_id})"

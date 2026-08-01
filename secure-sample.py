"""Secure configuration pattern — secrets loaded from environment variables only."""

from __future__ import annotations

import os


def get_application_programming_interface_key() -> str:
    value = os.environ.get("HABOT_API_KEY")
    if not value:
        raise RuntimeError(
            "HABOT_API_KEY environment variable is required. "
            "Hardcoded application programming interface keys are forbidden."
        )
    return value

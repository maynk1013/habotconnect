#!/usr/bin/env bash
# Quarantine marker writer for Fail-Closed builds
# Candidate Full Name: Mayank

set -euo pipefail

COMMIT_SHA="${1:-unknown}"
SOURCE_GATE="${2:-unspecified}"
STAMP="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
OUT_DIR="artifacts/quarantine"
mkdir -p "${OUT_DIR}"

MARKER="${OUT_DIR}/quarantine-${COMMIT_SHA}.txt"

cat >"${MARKER}" <<EOF
HabotConnect Build Quarantine Record
====================================
Status: QUARANTINED (Fail-Closed)
Commit: ${COMMIT_SHA}
Gate: ${SOURCE_GATE}
Timestamp Coordinated Universal Time: ${STAMP}
Action: Do not deploy. Do not merge until secrets and formatting violations are remediated.
EOF

echo "Quarantine marker written to ${MARKER}"
exit 0

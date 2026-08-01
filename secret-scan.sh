#!/usr/bin/env bash
# HabotConnect custom secret pattern scanner — Fail-Closed
# Candidate Full Name: Mayank
#
# Exit codes:
#   0 = no hardcoded secret patterns found
#   1 = one or more findings (pipeline must fail and quarantine)

set -euo pipefail

TARGET="${1:-.}"
FINDINGS=0
REPORT="$(mktemp)"

# Patterns intentionally cover common accidental leaks from the hiring scenario:
# raw application programming interface credentials in application code.
PATTERNS=(
  'API_KEY[[:space:]]*=[[:space:]]*['\''"][A-Za-z0-9_\-]{16,}['\''"]'
  'api_key[[:space:]]*=[[:space:]]*['\''"][A-Za-z0-9_\-]{16,}['\''"]'
  'SECRET_KEY[[:space:]]*=[[:space:]]*['\''"][^'\''"]{8,}['\''"]'
  'AWS_SECRET_ACCESS_KEY[[:space:]]*=[[:space:]]*['\''"][^'\''"]+['\''"]'
  'private_key[[:space:]]*=[[:space:]]*['\''"]-----BEGIN'
  'AIza[0-9A-Za-z\-_]{35}'
  'ghp_[A-Za-z0-9]{36}'
  'xox[baprs]-[A-Za-z0-9-]{10,}'
  'BEGIN OPENSSH PRIVATE KEY'
  'DJANGO_SECRET_KEY[[:space:]]*=[[:space:]]*['\''"][^'\''"]{8,}['\''"]'
)

# Paths that are allowed to contain intentional insecure fixtures for demonstration.
ALLOWLIST_REGEX='(examples/insecure-sample\.py|task2-cicd/scripts/secret-scan\.sh|task2-cicd/scripts/demonstrate-fail-closed\.sh|\.gitleaksignore|presentation-outline\.md|README\.md)'

echo "Scanning path: ${TARGET}"
echo "Mode: Fail-Closed (any finding outside allowlist fails the build)"

while IFS= read -r -d '' file; do
  rel="${file#./}"
  if [[ "${rel}" =~ ${ALLOWLIST_REGEX} ]]; then
    continue
  fi
  # Skip binary and vendored noise
  case "${rel}" in
    .git/*|*/.git/*|.venv/*|*/.venv/*|venv/*|*/venv/*|node_modules/*|*/node_modules/*|artifacts/*|*/__pycache__/*|*.png|*.jpg|*.pdf|*.zip|*.pyc|*.tfstate|*.tfstate.*)
      continue
      ;;
  esac

  for pattern in "${PATTERNS[@]}"; do
    if grep -E -n -H --binary-files=without-match -e "${pattern}" "${file}" >>"${REPORT}" 2>/dev/null; then
      FINDINGS=$((FINDINGS + 1))
    fi
  done
done < <(find "${TARGET}" \
  \( -name .git -o -name .venv -o -name venv -o -name node_modules -o -name artifacts -o -name __pycache__ -o -name .terraform \) -prune -o \
  -type f -print0)

if [[ "${FINDINGS}" -gt 0 ]]; then
  echo "FAIL-CLOSED: hardcoded secret patterns detected (${FINDINGS} pattern hit(s))."
  echo "----- findings -----"
  sort -u "${REPORT}" | head -n 200
  rm -f "${REPORT}"
  exit 1
fi

echo "Secret pattern scan passed with zero findings."
rm -f "${REPORT}"
exit 0

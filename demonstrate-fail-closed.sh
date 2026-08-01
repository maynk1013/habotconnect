#!/usr/bin/env bash
# Demonstrates Fail-Closed behavior without poisoning the committed tree.
# Candidate Full Name: Mayank

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
TMP="$(mktemp -t habot-secret-demo.XXXXXX.py)"

cleanup() { rm -f "${TMP}"; }
trap cleanup EXIT

cat >"${TMP}" <<'PY'
# Temporary file used only for demonstration
API_KEY = "FAKESECRET_s1t2u3v4w5x6y7z8a9b0"
PY

echo "=== Expect FAIL-CLOSED on temporary insecure file ==="
set +e
"${REPO_ROOT}/task2-cicd/scripts/secret-scan.sh" "${TMP}"
code=$?
set -e
echo "Exit code: ${code} (non-zero means Fail-Closed worked)"

echo
echo "=== Expect PASS on secure sample ==="
"${REPO_ROOT}/task2-cicd/scripts/secret-scan.sh" "${REPO_ROOT}/examples/secure-sample.py"
echo "Exit code: 0 (secure sample clean)"

if [[ "${code}" -ne 0 ]]; then
  echo
  echo "Demonstration successful: insecure commit would be halted and quarantined."
  exit 0
fi

echo "Demonstration failed: scanner did not reject the temporary secret."
exit 1

#!/bin/bash

set -euo pipefail

readonly SCRIPT_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
readonly REPO_ROOT="$(cd -P "${SCRIPT_DIR}/.." && pwd -P)"
readonly WORKFLOW_DIR="${REPO_ROOT}/.github/workflows"

fail() {
  /bin/echo "error: GitHub Actions validation failed: $*" >&2
  exit 1
}

[[ -d "${WORKFLOW_DIR}" ]] || fail "workflow directory is missing: ${WORKFLOW_DIR}"
command -v actionlint >/dev/null 2>&1 || fail "required tool is unavailable: actionlint"

if ! (
  cd "${REPO_ROOT}"
  actionlint -no-color
); then
  fail "workflow syntax, expressions, or runner context usage is invalid"
fi

/bin/echo "GitHub Actions validation: passed"

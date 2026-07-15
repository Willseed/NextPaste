#!/bin/bash

set -euo pipefail

readonly SCRIPT_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
readonly REPO_ROOT="$(cd -P "${SCRIPT_DIR}/.." && pwd -P)"
readonly WORKFLOW_DIR="${REPO_ROOT}/.github/workflows"
readonly FULL_UI_WORKFLOW="${WORKFLOW_DIR}/full-ui.yml"

fail() {
  /bin/echo "error: GitHub Actions validation failed: $*" >&2
  exit 1
}

[[ -d "${WORKFLOW_DIR}" ]] || fail "workflow directory is missing: ${WORKFLOW_DIR}"
[[ -f "${FULL_UI_WORKFLOW}" ]] || fail "Full UI workflow is missing: ${FULL_UI_WORKFLOW}"
command -v actionlint >/dev/null 2>&1 || fail "required tool is unavailable: actionlint"

if ! (
  cd "${REPO_ROOT}"
  actionlint -no-color
); then
  fail "workflow syntax, expressions, or runner context usage is invalid"
fi

require_full_ui_fragment() {
  local fragment="$1"
  /usr/bin/grep -Fq -- "${fragment}" "${FULL_UI_WORKFLOW}" \
    || fail "Full UI workflow is missing required Verify handoff: ${fragment}"
}

require_full_ui_fragment 'workflow_run:'
require_full_ui_fragment 'workflows: [Verify]'
require_full_ui_fragment 'types: [completed]'
require_full_ui_fragment 'branches: [main]'
require_full_ui_fragment 'group: full-ui-${{ github.event_name }}-${{ github.event.workflow_run.event || github.ref }}-${{ github.event.workflow_run.conclusion || github.ref }}'
require_full_ui_fragment "github.event.workflow_run.conclusion == 'success'"
require_full_ui_fragment "github.event.workflow_run.event == 'push'"
require_full_ui_fragment 'github.event.workflow_run.head_repository.full_name == github.repository'
require_full_ui_fragment "github.event.workflow_run.head_branch == 'main'"
require_full_ui_fragment 'uses: actions/checkout@9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0 # v7.0.0'
require_full_ui_fragment 'ref: ${{ github.event.workflow_run.head_sha || github.sha }}'
require_full_ui_fragment 'persist-credentials: false'
require_full_ui_fragment 'EXPECTED_SHA: ${{ github.event.workflow_run.head_sha }}'
require_full_ui_fragment 'test "$(git rev-parse HEAD)" = "$EXPECTED_SHA"'
require_full_ui_fragment 'timeout-minutes: 22'
require_full_ui_fragment 'timeout-minutes: 18'
require_full_ui_fragment 'contents: read'
require_full_ui_fragment 'workflow_dispatch:'
require_full_ui_fragment 'schedule:'

/bin/echo "GitHub Actions validation: passed"

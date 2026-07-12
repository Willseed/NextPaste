#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
readonly SCRIPT_DIR
REPO_ROOT="$(cd -P "${SCRIPT_DIR}/.." && pwd -P)"
readonly REPO_ROOT
readonly PROJECT_PATH="${REPO_ROOT}/NextPaste.xcodeproj"
readonly SCHEME_NAME="NextPasteCI"
readonly CI_SCHEME_PATH="${PROJECT_PATH}/xcshareddata/xcschemes/${SCHEME_NAME}.xcscheme"
readonly TEST_PLAN_NAME="NextPaste"
readonly SHARD_MANIFEST="${SCRIPT_DIR}/ui-test-shards.txt"
readonly BUILD_CONFIGURATION="Debug"
readonly VISION_INTEGRATION_SELECTOR="NextPasteTests/VisionImageTextRecognizerIntegrationTests"
readonly APPEARANCE_INTEGRATION_SELECTOR="NextPasteTests/AppKitAppearanceIntegrationTests"
readonly FOCUSED_VALUE_WARNING="FocusedValue update tried to update multiple times per frame."
readonly SETTINGS_WARNING="Please use SettingsLink for opening the Settings scene."

MODE="pr"
SHARD=""
DRY_RUN=0

while (($# > 0)); do
  case "$1" in
    --mode)
      [[ $# -ge 2 ]] || { /bin/echo "error: --mode requires pr or full-ui" >&2; exit 64; }
      MODE="$2"
      shift 2
      ;;
    --shard)
      [[ $# -ge 2 ]] || { /bin/echo "error: --shard requires a number" >&2; exit 64; }
      SHARD="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --help|-h)
      /bin/echo "Usage: Scripts/ci-test.sh [--mode pr|full-ui] [--shard 1|2|3|4] [--dry-run]"
      exit 0
      ;;
    *)
      /bin/echo "error: unknown argument: $1" >&2
      exit 64
      ;;
  esac
done

case "${MODE}" in
  pr)
    [[ -z "${SHARD}" ]] || { /bin/echo "error: --shard is valid only with --mode full-ui" >&2; exit 64; }
    ;;
  full-ui)
    [[ "${SHARD}" =~ ^[1-4]$ ]] || { /bin/echo "error: full-ui mode requires --shard 1, 2, 3, or 4" >&2; exit 64; }
    ;;
  *)
    /bin/echo "error: unsupported mode: ${MODE}" >&2
    exit 64
    ;;
esac

note() {
  /bin/echo "==> $*"
}

fail() {
  /bin/echo "error: $*" >&2
  exit 1
}

print_command() {
  printf '+'
  printf ' %q' "$@"
  printf '\n'
}

resolve_developer_dir() {
  local candidate="${DEVELOPER_DIR:-}"
  if [[ -z "${candidate}" ]] && ! candidate="$(/usr/bin/xcode-select -p 2>/dev/null)"; then
    candidate=""
  fi
  if [[ ! -x "${candidate}/usr/bin/xcodebuild" && -x /Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild ]]; then
    candidate="/Applications/Xcode.app/Contents/Developer"
  fi

  [[ "${candidate}" == *.app/Contents/Developer ]] \
    || fail "DEVELOPER_DIR must identify a complete Xcode.app Contents/Developer directory: ${candidate:-unset}"
  [[ -x "${candidate}/usr/bin/xcodebuild" ]] || fail "xcodebuild is unavailable in ${candidate}"
  [[ -x "${candidate}/usr/bin/xcresulttool" ]] || fail "xcresulttool is unavailable in ${candidate}"
  [[ -x "${candidate}/usr/bin/xccov" ]] || fail "xccov is unavailable in ${candidate}"
  export DEVELOPER_DIR="${candidate}" || return "${?}"
  return 0
}

resolve_developer_dir

readonly XCODEBUILD="${DEVELOPER_DIR}/usr/bin/xcodebuild"
readonly XCRESULTTOOL="${DEVELOPER_DIR}/usr/bin/xcresulttool"
readonly XCCOV="${DEVELOPER_DIR}/usr/bin/xccov"
HOST_ARCH="$(/usr/bin/uname -m)"
readonly HOST_ARCH
case "${HOST_ARCH}" in
  arm64|x86_64) ;;
  *) fail "unsupported macOS runner architecture: ${HOST_ARCH}" ;;
esac
readonly DESTINATION="platform=macOS,arch=${HOST_ARCH}"

validate_ci_scheme_launchers() {
  [[ -f "${CI_SCHEME_PATH}" ]] || fail "missing shared CI scheme: ${CI_SCHEME_PATH}"
  [[ -x /usr/bin/xmllint ]] || fail "xmllint is required to validate the shared CI scheme"

  local action debugger_identifier launcher_identifier
  for action in TestAction LaunchAction; do
    debugger_identifier="$(
      /usr/bin/xmllint --xpath "string(/Scheme/${action}/@selectedDebuggerIdentifier)" "${CI_SCHEME_PATH}"
    )"
    launcher_identifier="$(
      /usr/bin/xmllint --xpath "string(/Scheme/${action}/@selectedLauncherIdentifier)" "${CI_SCHEME_PATH}"
    )"
    [[ -z "${debugger_identifier}" ]] \
      || fail "${SCHEME_NAME} ${action} must not attach a debugger: ${debugger_identifier}"
    [[ "${launcher_identifier}" == "Xcode.IDEFoundation.Launcher.PosixSpawn" ]] \
      || fail "${SCHEME_NAME} ${action} must use PosixSpawn: ${launcher_identifier:-unset}"
  done
  return 0
}

validate_ci_scheme_launchers

artifacts_root="${CI_ARTIFACTS_DIR:-${RUNNER_TEMP:-${TMPDIR:-/tmp}}/NextPasteCI}"
/bin/mkdir -p "${artifacts_root}"
artifacts_root="$(cd -P "${artifacts_root}" && pwd -P)"

require_external_directory() {
  local purpose="$1"
  local directory="$2"
  case "${directory}/" in
    "${REPO_ROOT}/"*) fail "${purpose} must be outside the repository: ${directory}" ;;
    /*) ;;
    *) fail "unable to classify ${purpose} path '${directory}': expected an absolute path" ;;
  esac
  return 0
}

require_external_directory "CI artifacts" "${artifacts_root}"
readonly RUN_DIR="${artifacts_root}/${MODE}${SHARD:+-shard-${SHARD}}"
readonly DERIVED_DATA_PATH="${CI_DERIVED_DATA_PATH:-${RUN_DIR}/DerivedData}"
/bin/rm -rf "${RUN_DIR}"
/bin/mkdir -p "${RUN_DIR}" "${DERIVED_DATA_PATH}"

plist_value() {
  local key="$1"
  local file="$2"
  local plutil_status=0
  /usr/bin/plutil -extract "${key}" raw -o - "${file}" || plutil_status=$?
  return "${plutil_status}"
}

validate_shard_manifest() {
  [[ -f "${SHARD_MANIFEST}" ]] || fail "missing UI shard manifest: ${SHARD_MANIFEST}"
  local discovered="${RUN_DIR}/ui-classes-discovered.txt"
  local assigned="${RUN_DIR}/ui-classes-assigned.txt"

  /usr/bin/env rg -INo --replace "\$1" \
    '^final class ([A-Za-z0-9_]+): UITestCase' \
    "${REPO_ROOT}/NextPasteUITests"/*.swift | /usr/bin/sort > "${discovered}"
  /usr/bin/awk '!/^#/ && NF == 2 { print $2 }' "${SHARD_MANIFEST}" | /usr/bin/sort > "${assigned}"

  [[ -s "${discovered}" ]] || fail "no concrete UI test classes were discovered"
  [[ "$(/usr/bin/uniq -d "${assigned}" | /usr/bin/wc -l | /usr/bin/tr -d ' ')" == "0" ]] \
    || fail "UI shard manifest assigns at least one class more than once"
  /usr/bin/diff -u "${discovered}" "${assigned}" \
    || fail "UI shard manifest must assign every concrete UI test class exactly once"
  /bin/echo "UI shard manifest: exhaustive and unique ($(wc -l < "${assigned}" | tr -d ' ') classes)"
}

collect_crash_reports() {
  local destination="${RUN_DIR}/crash-reports"
  local source="${HOME}/Library/Logs/DiagnosticReports"
  [[ -d "${source}" ]] || return 0
  /bin/mkdir -p "${destination}"
  local report
  while IFS= read -r report; do
    /bin/cp -p "${report}" "${destination}/"
  done < <(/usr/bin/find "${source}" -maxdepth 1 -type f \
    \( -name 'NextPaste*' -o -name 'xctest*' -o -name '*UITests-Runner*' \) -print 2>/dev/null)
}

terminate_tree() {
  local pid="$1"
  local signal="$2"
  local child children
  if children="$(/usr/bin/pgrep -P "${pid}" 2>/dev/null)"; then
    while IFS= read -r child; do
      [[ -n "${child}" ]] && terminate_tree "${child}" "${signal}"
    done <<< "${children}"
  fi
  if ! /bin/kill "-${signal}" "${pid}" 2>/dev/null; then
    :
  fi
}

ACTIVE_PID=""
cleanup_active_process() {
  if [[ -n "${ACTIVE_PID}" ]] && /bin/kill -0 "${ACTIVE_PID}" 2>/dev/null; then
    terminate_tree "${ACTIVE_PID}" TERM
    /bin/sleep 2
    terminate_tree "${ACTIVE_PID}" KILL
  fi
}
trap cleanup_active_process EXIT
trap 'cleanup_active_process; exit 130' INT TERM

run_with_watchdog() {
  local timeout_seconds="$1"
  local label="$2"
  local log_path="$3"
  shift 3
  local command=("$@")

  note "${label} (watchdog=${timeout_seconds}s)"
  print_command "${command[@]}"
  if (( DRY_RUN )); then
    return 0
  fi

  (
    set -o pipefail
    "${command[@]}" 2>&1 | /usr/bin/tee "${log_path}"
  ) &
  ACTIVE_PID=$!
  local started deadline now status timed_out=0
  started="$(/bin/date +%s)"
  deadline=$((started + timeout_seconds))

  while /bin/kill -0 "${ACTIVE_PID}" 2>/dev/null; do
    now="$(/bin/date +%s)"
    if (( now >= deadline )); then
      timed_out=1
      /bin/echo "error: ${label} exceeded ${timeout_seconds}s; terminating xcodebuild and descendants" \
        | /usr/bin/tee -a "${log_path}" >&2
      /usr/bin/touch "${RUN_DIR}/${label// /-}.timeout"
      terminate_tree "${ACTIVE_PID}" TERM
      local grace_deadline=$((now + 10))
      while /bin/kill -0 "${ACTIVE_PID}" 2>/dev/null && (( $(/bin/date +%s) < grace_deadline )); do
        /bin/sleep 1
      done
      if /bin/kill -0 "${ACTIVE_PID}" 2>/dev/null; then
        terminate_tree "${ACTIVE_PID}" KILL
      fi
      break
    fi
    /bin/sleep 2
  done

  status=0
  wait "${ACTIVE_PID}" || status=$?
  ACTIVE_PID=""
  if (( timed_out )); then
    collect_crash_reports
    return 124
  fi
  return "${status}"
}

summarize_test_result() {
  local label="$1"
  local result_bundle="$2"
  local require_coverage="$3"
  local summary_path="${RUN_DIR}/${label}-summary.json"
  local details_path="${RUN_DIR}/${label}-tests.json"

  [[ -d "${result_bundle}" ]] || fail "${label} did not produce ${result_bundle}"
  "${XCRESULTTOOL}" get test-results summary --path "${result_bundle}" > "${summary_path}" \
    || fail "unable to read ${label} test summary"

  local total passed failed skipped expected_failures result
  total="$(plist_value totalTestCount "${summary_path}")"
  passed="$(plist_value passedTests "${summary_path}")"
  failed="$(plist_value failedTests "${summary_path}")"
  skipped="$(plist_value skippedTests "${summary_path}")"
  expected_failures="$(plist_value expectedFailures "${summary_path}")"
  result="$(plist_value result "${summary_path}")"
  /bin/echo "${label}: result=${result} total=${total} passed=${passed} failed=${failed} skipped=${skipped} expectedFailures=${expected_failures}"

  if [[ "${result}" != "Passed" ]] || (( total <= 0 || passed != total || failed != 0 || skipped != 0 || expected_failures != 0 )); then
    if ! "${XCRESULTTOOL}" get test-results tests --path "${result_bundle}" --compact > "${details_path}"; then
      /bin/echo "warning: unable to export detailed ${label} test results" >&2
    fi
    fail "${label} must pass every selected test with no failures, skips, or expected failures"
  fi

  if [[ "${require_coverage}" == "YES" ]]; then
    "${XCCOV}" view --report --only-targets "${result_bundle}" > "${RUN_DIR}/${label}-coverage.txt" \
      || fail "unable to extract ${label} coverage"
    /usr/bin/grep -q 'NextPaste.app' "${RUN_DIR}/${label}-coverage.txt" \
      || fail "${label} coverage does not include NextPaste.app"
  fi
}

run_build_for_testing() {
  local coverage="$1"
  local result_bundle="${RUN_DIR}/BuildForTesting.xcresult"
  local command=(
    "${XCODEBUILD}"
    -project "${PROJECT_PATH}"
    -scheme "${SCHEME_NAME}"
    -testPlan "${TEST_PLAN_NAME}"
    -destination "${DESTINATION}"
    -configuration "${BUILD_CONFIGURATION}"
    -derivedDataPath "${DERIVED_DATA_PATH}"
    -enableCodeCoverage "${coverage}"
    -resultBundlePath "${result_bundle}"
    build-for-testing
  )
  run_with_watchdog 2100 "build-for-testing" "${RUN_DIR}/build-for-testing.log" "${command[@]}" \
    || fail "build-for-testing failed or timed out"
}

run_test_phase() {
  local label="$1"
  local test_configuration="$2"
  local timeout_seconds="$3"
  local coverage="$4"
  local parallel="$5"
  shift 5
  local selectors=("$@")
  local result_bundle="${RUN_DIR}/${label}.xcresult"
  local command=(
    "${XCODEBUILD}"
    -project "${PROJECT_PATH}"
    -scheme "${SCHEME_NAME}"
    -testPlan "${TEST_PLAN_NAME}"
    -only-test-configuration "${test_configuration}"
    -destination "${DESTINATION}"
    -configuration "${BUILD_CONFIGURATION}"
    -derivedDataPath "${DERIVED_DATA_PATH}"
    -enableCodeCoverage "${coverage}"
    -parallel-testing-enabled "${parallel}"
    -resultBundlePath "${result_bundle}"
  )
  command+=("${selectors[@]}" test-without-building)

  local status=0
  run_with_watchdog "${timeout_seconds}" "${label}" "${RUN_DIR}/${label}.log" "${command[@]}" || status=$?
  if (( status != 0 )); then
    collect_crash_reports
    fail "${label} failed or timed out with status ${status}"
  fi
  (( DRY_RUN )) || summarize_test_result "${label}" "${result_bundle}" "${coverage}"
}

capture_ui_runtime_log() {
  local start_time="$1"
  local destination="$2"
  if ! /usr/bin/log show --style compact --start "${start_time}" \
      --predicate 'process == "NextPaste" OR process CONTAINS "NextPasteUITests"' > "${destination}" 2>&1; then
    /bin/echo "warning: unable to capture unified UI runtime log" >&2
  fi
}

assert_no_swiftui_runtime_warnings() {
  local label="$1"
  local start_time="$2"
  local unified_log="${RUN_DIR}/${label}-unified.log"
  (( DRY_RUN )) && return 0
  capture_ui_runtime_log "${start_time}" "${unified_log}"
  if /usr/bin/grep -F -e "${FOCUSED_VALUE_WARNING}" -e "${SETTINGS_WARNING}" \
      "${RUN_DIR}/${label}.log" "${unified_log}" >/dev/null 2>&1; then
    fail "${label} emitted a prohibited SwiftUI runtime warning"
  fi
}

note "Toolchain and automation preflight"
{
  /bin/echo "DEVELOPER_DIR=${DEVELOPER_DIR}"
  /usr/bin/xcode-select -p
  "${XCODEBUILD}" -version
  /usr/bin/xcrun --find xcodebuild
  /usr/bin/sw_vers
  /usr/bin/uname -m
  /usr/bin/automationmodetool
} 2>&1 | /usr/bin/tee "${RUN_DIR}/preflight.log"

resolved_xcodebuild="$(DEVELOPER_DIR="${DEVELOPER_DIR}" /usr/bin/xcrun --find xcodebuild)"
[[ "${resolved_xcodebuild}" == "${DEVELOPER_DIR}"/* ]] \
  || fail "xcrun xcodebuild does not resolve inside DEVELOPER_DIR: ${resolved_xcodebuild}"
automation_mode_status="$(/usr/bin/automationmodetool)"
if (( DRY_RUN == 0 )) && [[ "${automation_mode_status}" != *"DOES NOT REQUIRE"* ]]; then
  fail "UI Automation requires interactive authorization on this host; refusing to start UI tests"
fi

validate_shard_manifest

if [[ "${MODE}" == "pr" ]]; then
  note "Repository policy checks"
  "${SCRIPT_DIR}/check-macos-host-compatibility.sh" "${RUN_DIR}/macos-host-compatibility.txt"
  "${SCRIPT_DIR}/check-test-hygiene.sh"
  if command -v actionlint >/dev/null 2>&1; then
    "${SCRIPT_DIR}/check-github-actions.sh"
  else
    /bin/echo "actionlint unavailable; workflow syntax validation is deferred to the workflow tool-install step"
  fi

  run_build_for_testing YES
  run_test_phase Unit Unit 1800 YES YES \
    -only-testing:NextPasteTests \
    -skip-testing:"${VISION_INTEGRATION_SELECTOR}" \
    -skip-testing:"${APPEARANCE_INTEGRATION_SELECTOR}"
  run_test_phase Integration Integration 900 NO YES \
    -only-testing:"${VISION_INTEGRATION_SELECTOR}" \
    -only-testing:"${APPEARANCE_INTEGRATION_SELECTOR}"

  ui_start_time="$(/bin/date '+%Y-%m-%d %H:%M:%S%z')"
  run_test_phase UISmoke UI 1200 NO NO \
    -only-testing:NextPasteUITests/NextPasteUITests/testDefaultPathConfigurationFeedsTheActiveLaunchEnvironment \
    -only-testing:NextPasteUITests/NextPasteUITests/testCustomPathConfigurationPropagatesStorageAndTraceURLs \
    -only-testing:NextPasteUITests/NextPasteUITests/testIsolatedLaunchExposesReadyMainWindow \
    -only-testing:NextPasteUITests/HistoryListUITests/testHistoryShowsNewestFirstAndReadableLongMultilinePreview \
    -only-testing:NextPasteUITests/SettingsUITests/testToolbarSettingsLinkOpensSingleSettingsWindow \
    -only-testing:NextPasteUITests/PinScrollAutomationUITests/testNativePinActionButtonIsAccessibleAndTriggersStableIDMutation \
    -only-testing:NextPasteUITests/SearchAccessibilityUITests/testCommandFFocusesNativeSearchFieldAndTypingFiltersHistory \
    -only-testing:NextPasteUITests/SearchAccessibilityUITests/testRapidFocusChangesAndSettingsRoundTripRemainStable
  assert_no_swiftui_runtime_warnings UISmoke "${ui_start_time}"
else
  run_build_for_testing NO
  shard_selectors=()
  while read -r class_name; do
    [[ -n "${class_name}" ]] && shard_selectors+=("-only-testing:NextPasteUITests/${class_name}")
  done < <(/usr/bin/awk -v shard="${SHARD}" '!/^#/ && $1 == shard { print $2 }' "${SHARD_MANIFEST}")
  ((${#shard_selectors[@]} > 0)) || fail "UI shard ${SHARD} selected no suites"
  ui_start_time="$(/bin/date '+%Y-%m-%d %H:%M:%S%z')"
  run_test_phase "FullUIShard${SHARD}" UI 4500 NO NO "${shard_selectors[@]}"
  assert_no_swiftui_runtime_warnings "FullUIShard${SHARD}" "${ui_start_time}"
fi

note "CI verification passed"
/bin/echo "mode=${MODE}${SHARD:+ shard=${SHARD}} destination=${DESTINATION} artifacts=${RUN_DIR}"

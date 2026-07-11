#!/bin/bash

set -euo pipefail

readonly SCRIPT_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
readonly REPO_ROOT="$(cd -P "${SCRIPT_DIR}/.." && pwd -P)"
readonly PROJECT_PATH="${REPO_ROOT}/NextPaste.xcodeproj"
readonly SCHEME_NAME="NextPaste"
readonly TEST_PLAN_NAME="NextPaste"
readonly TEST_PLAN_PATH="${REPO_ROOT}/NextPaste.xctestplan"
readonly DESTINATION="platform=macOS"
readonly BUILD_CONFIGURATION="Debug"
readonly LOCALIZATION_CATALOG="${REPO_ROOT}/NextPaste/Localizable.xcstrings"
readonly VISION_INTEGRATION_SELECTOR="NextPasteTests/VisionImageTextRecognizerIntegrationTests"
readonly APPEARANCE_INTEGRATION_SELECTOR="NextPasteTests/AppKitAppearanceIntegrationTests"

DRY_RUN=0
case "${1:-}" in
  "")
    ;;
  --dry-run)
    DRY_RUN=1
    ;;
  --help|-h)
    /bin/echo "Usage: Scripts/verify.sh [--dry-run]"
    /bin/echo "  --dry-run  Validate repository configuration and print xcodebuild commands without building or testing."
    exit 0
    ;;
  *)
    /bin/echo "error: unknown argument: $1" >&2
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

assert_no_repository_build_artifacts() {
  local checkpoint="$1"
  local matches
  matches="$(
    /usr/bin/find "${REPO_ROOT}" \
      -path "${REPO_ROOT}/.git" -prune -o \
      -type d \( \
        -name DerivedData -o \
        -name build -o \
        -name .build -o \
        -name '*.xcresult' -o \
        -name '*.xcarchive' -o \
        -name '*.dSYM' -o \
        -name '*.app' \
      \) -prune -print -o \
      -type f \( -name '*.profraw' -o -name '*.profdata' \) -print
  )"
  if [[ -n "${matches}" ]]; then
    /bin/echo "${matches}" >&2
    fail "${checkpoint}: generated build products or result artifacts exist inside the repository."
  fi
  /bin/echo "${checkpoint}: passed"
}

print_command() {
  printf '+'
  printf ' %q' "$@"
  printf '\n'
}

resolve_developer_dir() {
  local candidate="${DEVELOPER_DIR:-}"

  if [[ -z "${candidate}" ]]; then
    local selected
    selected="$(/usr/bin/xcode-select -p 2>/dev/null || true)"
    if [[ -n "${selected}" && -x "${selected}/usr/bin/xcodebuild" && "${selected}" == *.app/Contents/Developer ]]; then
      candidate="${selected}"
    elif [[ -x "/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild" ]]; then
      candidate="/Applications/Xcode.app/Contents/Developer"
    fi
  fi

  [[ -n "${candidate}" ]] || fail "A full Xcode installation is required; set DEVELOPER_DIR to its Contents/Developer directory."
  [[ -x "${candidate}/usr/bin/xcodebuild" ]] || fail "DEVELOPER_DIR does not contain xcodebuild: ${candidate}"
  [[ -x "${candidate}/usr/bin/xcresulttool" ]] || fail "DEVELOPER_DIR does not contain xcresulttool: ${candidate}"
  [[ -x "${candidate}/usr/bin/xccov" ]] || fail "DEVELOPER_DIR does not contain xccov: ${candidate}"

  export DEVELOPER_DIR="${candidate}"
}

resolve_developer_dir

readonly XCODEBUILD="${DEVELOPER_DIR}/usr/bin/xcodebuild"
readonly XCRESULTTOOL="${DEVELOPER_DIR}/usr/bin/xcresulttool"
readonly XCCOV="${DEVELOPER_DIR}/usr/bin/xccov"

[[ -d "${PROJECT_PATH}" ]] || fail "Missing Xcode project: ${PROJECT_PATH}"
[[ -f "${TEST_PLAN_PATH}" ]] || fail "Missing Xcode test plan: ${TEST_PLAN_PATH}"
[[ -f "${LOCALIZATION_CATALOG}" ]] || fail "Missing String Catalog: ${LOCALIZATION_CATALOG}"
note "Repository artifact preflight"
assert_no_repository_build_artifacts "preflight artifact gate"

artifacts_root="${VERIFY_ARTIFACTS_DIR:-${TMPDIR:-/tmp}/NextPasteVerification}"
/bin/mkdir -p "${artifacts_root}"
artifacts_root="$(cd -P "${artifacts_root}" && pwd -P)"
case "${artifacts_root}/" in
  "${REPO_ROOT}/"*) fail "Verification output must be outside the repository: ${artifacts_root}" ;;
esac
readonly RUN_DIR="$(/usr/bin/mktemp -d "${artifacts_root}/run.XXXXXX")"
derived_data_path="${VERIFY_DERIVED_DATA_PATH:-${RUN_DIR}/DerivedData}"
/bin/mkdir -p "${derived_data_path}"
derived_data_path="$(cd -P "${derived_data_path}" && pwd -P)"
case "${derived_data_path}/" in
  "${REPO_ROOT}/"*) fail "DerivedData must be outside the repository: ${derived_data_path}" ;;
esac
readonly DERIVED_DATA_PATH="${derived_data_path}"

TOTAL_TESTS=0
TOTAL_PASSED=0
TOTAL_FAILED=0
TOTAL_SKIPPED=0
TOTAL_EXPECTED_FAILURES=0

plist_value() {
  local key="$1"
  local file="$2"
  /usr/bin/plutil -extract "${key}" raw -o - "${file}"
}

summarize_xcresult() {
  local label="$1"
  local result_bundle="$2"
  local expected_test_count="$3"
  local summary_path="${RUN_DIR}/${label}-summary.json"
  local details_path="${RUN_DIR}/${label}-tests.json"
  local coverage_path="${RUN_DIR}/${label}-coverage.txt"
  local coverage_json_path="${RUN_DIR}/${label}-coverage.json"

  [[ -d "${result_bundle}" ]] || {
    /bin/echo "error: ${label} did not produce an xcresult bundle at ${result_bundle}" >&2
    return 1
  }

  if ! "${XCRESULTTOOL}" get test-results summary --path "${result_bundle}" > "${summary_path}"; then
    /bin/echo "error: unable to read ${label} test summary from ${result_bundle}" >&2
    return 1
  fi

  local total passed failed skipped expected_failures result
  total="$(plist_value totalTestCount "${summary_path}")"
  passed="$(plist_value passedTests "${summary_path}")"
  failed="$(plist_value failedTests "${summary_path}")"
  skipped="$(plist_value skippedTests "${summary_path}")"
  expected_failures="$(plist_value expectedFailures "${summary_path}")"
  result="$(plist_value result "${summary_path}")"

  /bin/echo "${label}: result=${result} total=${total} passed=${passed} failed=${failed} skipped=${skipped} expectedFailures=${expected_failures}"

  TOTAL_TESTS=$((TOTAL_TESTS + total))
  TOTAL_PASSED=$((TOTAL_PASSED + passed))
  TOTAL_FAILED=$((TOTAL_FAILED + failed))
  TOTAL_SKIPPED=$((TOTAL_SKIPPED + skipped))
  TOTAL_EXPECTED_FAILURES=$((TOTAL_EXPECTED_FAILURES + expected_failures))

  if [[ "${result}" != "Passed" ]] \
      || (( total != expected_test_count \
          || passed != total \
          || failed != 0 \
          || skipped != 0 \
          || expected_failures != 0 )); then
    if ! "${XCRESULTTOOL}" get test-results tests --path "${result_bundle}" --compact > "${details_path}"; then
      /bin/echo "warning: unable to export detailed ${label} test results" >&2
    fi
    /bin/echo "error: ${label} must execute its complete ${expected_test_count}-test inventory with every test passed and zero failures, skips, or expected failures." >&2
    /bin/echo "Detailed results: ${details_path}" >&2
    return 1
  fi

  if ! "${XCCOV}" view --report --only-targets "${result_bundle}" > "${coverage_path}"; then
    /bin/echo "error: unable to extract ${label} code coverage from ${result_bundle}" >&2
    return 1
  fi
  if ! /usr/bin/grep -q "NextPaste.app" "${coverage_path}"; then
    /bin/echo "error: ${label} coverage does not contain the NextPaste app target." >&2
    return 1
  fi
  if ! "${XCCOV}" view --report --json "${result_bundle}" > "${coverage_json_path}"; then
    /bin/echo "error: unable to export ${label} code coverage JSON from ${result_bundle}" >&2
    return 1
  fi

  /bin/echo "${label} coverage:"
  /bin/cat "${coverage_path}"
}

run_build_phase() {
  local label="$1"
  local configuration="$2"
  local destination="$3"
  shift 3
  local result_bundle="${RUN_DIR}/${label}.xcresult"
  local summary_path="${RUN_DIR}/${label}-build-summary.json"
  local command=(
    "${XCODEBUILD}"
    -quiet
    -project "${PROJECT_PATH}"
    -scheme "${SCHEME_NAME}"
    -destination "${destination}"
    -configuration "${configuration}"
    -derivedDataPath "${DERIVED_DATA_PATH}"
    -resultBundlePath "${result_bundle}"
    "$@"
  )

  note "${label}"
  if (( DRY_RUN )); then
    print_command "${command[@]}"
    return 0
  fi

  local command_status=0
  print_command "${command[@]}"
  "${command[@]}" || command_status=$?

  [[ -d "${result_bundle}" ]] || fail "${label} did not produce ${result_bundle}"
  if ! "${XCRESULTTOOL}" get build-results --path "${result_bundle}" > "${summary_path}"; then
    fail "Unable to read ${label} build summary from ${result_bundle}."
  fi

  local build_status error_count warning_count analyzer_warning_count
  build_status="$(plist_value status "${summary_path}")" || fail "${label} build summary is missing status."
  error_count="$(plist_value errorCount "${summary_path}")" || fail "${label} build summary is missing errorCount."
  warning_count="$(plist_value warningCount "${summary_path}")" || fail "${label} build summary is missing warningCount."
  analyzer_warning_count="$(plist_value analyzerWarningCount "${summary_path}")" || fail "${label} build summary is missing analyzerWarningCount."
  /bin/echo "${label}: status=${build_status} errors=${error_count} warnings=${warning_count} analyzerWarnings=${analyzer_warning_count}"
  /bin/echo "${label} result bundle: ${result_bundle}"

  if (( command_status != 0 \
      || error_count != 0 \
      || warning_count != 0 \
      || analyzer_warning_count != 0 )) \
      || [[ "${build_status}" != "succeeded" ]]; then
    /bin/echo "error: ${label} failed; see ${summary_path}" >&2
    if (( command_status != 0 )); then
      return "${command_status}"
    fi
    return 1
  fi
}

run_test_phase() {
  local label="$1"
  local configuration="$2"
  shift 2
  local result_bundle="${RUN_DIR}/${label}.xcresult"
  local inventory_path="${RUN_DIR}/${label}-inventory.json"
  local common_arguments=(
    "${XCODEBUILD}"
    -quiet
    -project "${PROJECT_PATH}"
    -scheme "${SCHEME_NAME}"
    -testPlan "${TEST_PLAN_NAME}"
    -only-test-configuration "${configuration}"
    -destination "${DESTINATION}"
    -configuration "${BUILD_CONFIGURATION}"
    -derivedDataPath "${DERIVED_DATA_PATH}"
    -enableCodeCoverage YES
    "$@"
  )
  local enumeration_command=(
    "${common_arguments[@]}"
    -enumerate-tests
    -test-enumeration-style flat
    -test-enumeration-format json
    -test-enumeration-output-path "${inventory_path}"
    test-without-building
  )
  local command=(
    "${common_arguments[@]}"
    -resultBundlePath "${result_bundle}"
    test-without-building
  )

  note "${label} tests"
  local command_status=0
  if (( DRY_RUN )); then
    print_command "${enumeration_command[@]}"
    print_command "${command[@]}"
    return 0
  fi

  print_command "${enumeration_command[@]}"
  "${enumeration_command[@]}"
  [[ -f "${inventory_path}" ]] || fail "${label} test enumeration did not produce ${inventory_path}."
  local enumeration_errors expected_test_count
  enumeration_errors="$(plist_value errors "${inventory_path}")"
  expected_test_count="$(plist_value values.0.enabledTests "${inventory_path}")"
  (( enumeration_errors == 0 )) || fail "${label} test enumeration reported ${enumeration_errors} errors."
  (( expected_test_count > 0 )) || fail "${label} test enumeration selected no tests."
  /bin/echo "${label}: enumerated=${expected_test_count} inventory=${inventory_path}"

  print_command "${command[@]}"
  "${command[@]}" || command_status=$?

  local summary_status=0
  summarize_xcresult "${label}" "${result_bundle}" "${expected_test_count}" || summary_status=$?
  if (( command_status != 0 )); then
    /bin/echo "error: ${label} xcodebuild exited with ${command_status}" >&2
    return "${command_status}"
  fi
  return "${summary_status}"
}

note "Preflight"
"${XCODEBUILD}" -version
"${XCODEBUILD}" -list -json -project "${PROJECT_PATH}" > "${RUN_DIR}/xcodebuild-list.json"
"${XCODEBUILD}" -project "${PROJECT_PATH}" -scheme "${SCHEME_NAME}" -showTestPlans > "${RUN_DIR}/test-plans.txt"
/usr/bin/grep -q "${TEST_PLAN_NAME}" "${RUN_DIR}/test-plans.txt" || fail "Scheme ${SCHEME_NAME} is not associated with test plan ${TEST_PLAN_NAME}."
/usr/bin/plutil -convert json -o /dev/null "${TEST_PLAN_PATH}"
if /usr/bin/grep -Eq '"(skippedTests|selectedTests)"[[:space:]]*:' "${TEST_PLAN_PATH}"; then
  fail "Test Plan may not hide or narrow tests with skippedTests/selectedTests entries."
fi
[[ "$(plist_value configurations "${TEST_PLAN_PATH}")" == "3" ]] || fail "Test plan must contain exactly Unit, Integration, and UI configurations."
[[ "$(plist_value configurations.0.name "${TEST_PLAN_PATH}")" == "Unit" ]] || fail "Test plan is missing the Unit configuration."
[[ "$(plist_value configurations.1.name "${TEST_PLAN_PATH}")" == "Integration" ]] || fail "Test plan is missing the Integration configuration."
[[ "$(plist_value configurations.2.name "${TEST_PLAN_PATH}")" == "UI" ]] || fail "Test plan is missing the UI configuration."
[[ "$(plist_value defaultOptions.codeCoverage "${TEST_PLAN_PATH}")" == "true" ]] || fail "Test plan code coverage must be enabled."
[[ "$(plist_value defaultOptions.testTimeoutsEnabled "${TEST_PLAN_PATH}")" == "true" ]] || fail "Test plan timeouts must be enabled."
[[ "$(plist_value defaultOptions.codeCoverageTargets "${TEST_PLAN_PATH}")" == "1" ]] || fail "Test plan must collect coverage for exactly one product target."
[[ "$(plist_value defaultOptions.codeCoverageTargets.0.name "${TEST_PLAN_PATH}")" == "NextPaste" ]] || fail "Test plan coverage target must be NextPaste."
[[ "$(plist_value defaultOptions.codeCoverageTargets.0.identifier "${TEST_PLAN_PATH}")" == "F6E915E12FEBA508008C9AAA" ]] || fail "Test plan coverage target identifier drifted."
[[ "$(plist_value testTargets "${TEST_PLAN_PATH}")" == "2" ]] || fail "Test plan must contain exactly the unit and UI test targets."
[[ "$(plist_value testTargets.0.target.name "${TEST_PLAN_PATH}")" == "NextPasteTests" ]] || fail "Test plan is missing NextPasteTests."
[[ "$(plist_value testTargets.0.target.identifier "${TEST_PLAN_PATH}")" == "F6E915F22FEBA509008C9AAA" ]] || fail "NextPasteTests target identifier drifted."
[[ "$(plist_value testTargets.0.parallelizable "${TEST_PLAN_PATH}")" == "true" ]] || fail "NextPasteTests must remain parallelizable."
[[ "$(plist_value testTargets.1.target.name "${TEST_PLAN_PATH}")" == "NextPasteUITests" ]] || fail "Test plan is missing NextPasteUITests."
[[ "$(plist_value testTargets.1.target.identifier "${TEST_PLAN_PATH}")" == "F6E915FC2FEBA509008C9AAA" ]] || fail "NextPasteUITests target identifier drifted."
[[ "$(plist_value testTargets.1.parallelizable "${TEST_PLAN_PATH}")" == "false" ]] || fail "NextPasteUITests must remain serialized."

note "Formatter"
/bin/echo "Project not configured: no repository formatter command or configuration was found."

note "Lint"
/bin/echo "Project not configured: no repository lint command or SwiftLint configuration was found."

note "GitHub Actions validation"
"${SCRIPT_DIR}/check-github-actions.sh"

note "Test-source hygiene"
"${SCRIPT_DIR}/check-test-hygiene.sh"

run_build_phase DebugBuild Debug "${DESTINATION}" build
run_build_phase ReleaseBuild Release "${DESTINATION}" build
run_build_phase TestBuild Debug "${DESTINATION}" \
  -testPlan "${TEST_PLAN_NAME}" -enableCodeCoverage YES build-for-testing

run_test_phase Unit Unit \
  -only-testing:NextPasteTests \
  -skip-testing:"${VISION_INTEGRATION_SELECTOR}" \
  -skip-testing:"${APPEARANCE_INTEGRATION_SELECTOR}"

run_test_phase Integration Integration \
  -only-testing:"${VISION_INTEGRATION_SELECTOR}" \
  -only-testing:"${APPEARANCE_INTEGRATION_SELECTOR}"

run_test_phase UI UI \
  -parallel-testing-enabled NO \
  -only-testing:NextPasteUITests

note "Localization JSON validation"
/usr/bin/plutil -convert json -o /dev/null "${LOCALIZATION_CATALOG}"
/bin/echo "Localization completeness is enforced by LocalizationCatalogTests in the Unit configuration."

note "Repository artifact postflight"
assert_no_repository_build_artifacts "postflight artifact gate"

if (( DRY_RUN )); then
  note "Dry run complete"
  /bin/echo "No build or test command was executed."
  /bin/echo "Planned artifacts directory: ${RUN_DIR}"
  exit 0
fi

note "Verification summary"
/bin/echo "total=${TOTAL_TESTS} passed=${TOTAL_PASSED} failed=${TOTAL_FAILED} skipped=${TOTAL_SKIPPED} expectedFailures=${TOTAL_EXPECTED_FAILURES}"
/bin/echo "Artifacts: ${RUN_DIR}"

(( TOTAL_TESTS > 0 )) || fail "No tests executed."
(( TOTAL_PASSED == TOTAL_TESTS )) || fail "Not every discovered test passed."
(( TOTAL_FAILED == 0 )) || fail "Test failures were reported."
(( TOTAL_SKIPPED == 0 )) || fail "Skipped tests were reported."
(( TOTAL_EXPECTED_FAILURES == 0 )) || fail "Expected failures were reported."

note "Verification passed"

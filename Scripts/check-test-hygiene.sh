#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
readonly REPO_ROOT
readonly LOOP_INVENTORY="${SCRIPT_DIR}/ui-test-loop-inventory.txt"
readonly SWIFT_FILE_GLOB='*.swift'
EMPTY_TEST_SCANNER=""
# read returns nonzero at EOF because the script contains no NUL delimiter; the
# populated value is the intended result, so accept that specific termination.
IFS= read -r -d '' EMPTY_TEST_SCANNER <<'PERL' || [[ -n "${EMPTY_TEST_SCANNER}" ]]
while (/\bfunc\s+(test[A-Za-z0-9_]+)\s*\([^)]*\)\s*(?:async\s*)?(?:throws\s*)?\{\s*\}/sg) {
  print "$ARGV: empty XCTest method $1\n";
}
while (/@Test\b(?:\s*\([^)]*\))?(?:\s*@[A-Za-z_][A-Za-z0-9_]*(?:\([^)]*\))?)*\s*func\s+(`[^`]+`|[A-Za-z_][A-Za-z0-9_]*)\s*\([^)]*\)\s*(?:async\s*)?(?:throws\s*)?\{\s*\}/sg) {
  print "$ARGV: empty Swift Testing function $1\n";
}
PERL
readonly EMPTY_TEST_SCANNER
readonly TEST_ROOTS=(
  "${REPO_ROOT}/NextPasteTests"
  "${REPO_ROOT}/NextPasteUITests"
)

fail() {
  /bin/echo "error: test-source hygiene failed: $*" >&2
  exit 1
}

for tool in rg perl xargs sort diff mktemp; do
  command -v "${tool}" >/dev/null 2>&1 || fail "required tool is unavailable: ${tool}"
done
for root in "${TEST_ROOTS[@]}"; do
  swift_sources=""
  [[ -d "${root}" ]] || fail "test source root is missing: ${root}"
  swift_sources="$(/usr/bin/env rg --files --glob "${SWIFT_FILE_GLOB}" "${root}")" || \
    fail "unable to enumerate Swift files under: ${root}"
  [[ -n "${swift_sources}" ]] || fail "test source root contains no readable Swift files: ${root}"
done
[[ -f "${LOOP_INVENTORY}" ]] || fail "reviewed UI-test loop inventory is missing"

assert_no_match() {
  local description="$1"
  local pattern="$2"
  local matches status

  if matches="$(/usr/bin/env rg --pcre2 -n --glob "${SWIFT_FILE_GLOB}" "${pattern}" "${TEST_ROOTS[@]}" 2>&1)"; then
    /bin/echo "${matches}" >&2
    fail "${description}"
  else
    status=$?
    if (( status != 1 )); then
      /bin/echo "${matches}" >&2
      fail "source scan failed while checking: ${description}"
    fi
  fi
  return 0
}

assert_no_match \
  "XCTSkip/XCTExpectFailure may not hide required coverage" \
  'XCTSkip|XCTExpectFailure'

assert_no_match \
  "Swift Testing disabled/conditional/known-issue traits may not hide required coverage" \
  '\.disabled\s*\(|\.enabled\s*\(\s*if:|withKnownIssue\s*\('

assert_no_match \
  "fixed-duration sleeps and run-loop pumping are prohibited in tests" \
  'Task\.sleep\s*\(|Thread\.sleep\s*\(|(?<![A-Za-z])usleep\s*\(|(?<![A-Za-z.])sleep\s*\(|DispatchQueue\.main\.asyncAfter\s*\(|RunLoop\.current\.run\s*\('

assert_no_match \
  "commented-out tests or assertions are prohibited" \
  '^[[:space:]]*//[[:space:]]*(@Test|func[[:space:]]+test|XCTAssert|#expect)'

assert_no_match \
  "literal always-true assertions are prohibited" \
  'XCTAssertTrue\s*\(\s*true|XCTAssertFalse\s*\(\s*false|#expect\s*\(\s*true\s*\)'

swift_file_count="$(/usr/bin/env rg --files --glob "${SWIFT_FILE_GLOB}" "${TEST_ROOTS[@]}" | /usr/bin/wc -l | /usr/bin/tr -d ' ')"
(( swift_file_count > 0 )) || fail "no Swift test sources were available for empty-test analysis"

empty_tests="$(
  /usr/bin/env rg --files --glob "${SWIFT_FILE_GLOB}" "${TEST_ROOTS[@]}" -0 \
    | /usr/bin/xargs -0 /usr/bin/perl -0777 -ne "${EMPTY_TEST_SCANNER}"
)"
[[ -z "${empty_tests}" ]] || {
  /bin/echo "${empty_tests}" >&2
  fail "empty XCTest or Swift Testing functions are prohibited"
}

# Every line-start `for` or `while` token in the UI-test target is captured,
# normalized, sorted, and compared byte-for-byte with a reviewed inventory.
# This intentionally includes helper/data loops as well as direct input loops:
# any newly introduced retry, symbolic bound, range form, or while loop must be
# reviewed instead of being silently missed by a narrow numeric regex.
actual_loop_inventory="$(/usr/bin/mktemp "${TMPDIR:-/tmp}/NextPaste-ui-loops.XXXXXX")"
trap '/bin/rm -f "${actual_loop_inventory}"' EXIT
if ! (
  cd "${REPO_ROOT}"
  LC_ALL=C /usr/bin/env rg -n --glob "${SWIFT_FILE_GLOB}" '^[[:space:]]*(for|while)[[:space:]]' NextPasteUITests \
    | /usr/bin/perl -pe 's/^([^:]+):[0-9]+:[ \t]*/$1|/; s/[ \t\r]+$//' \
    | LC_ALL=C /usr/bin/sort > "${actual_loop_inventory}"
); then
  fail "unable to build the UI-test loop inventory"
fi

if ! /usr/bin/diff -u "${LOOP_INVENTORY}" "${actual_loop_inventory}"; then
  fail "UI-test loop inventory changed without review"
fi

/bin/echo "Test-source hygiene: passed"

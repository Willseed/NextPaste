#!/bin/bash

set -euo pipefail

fail() {
  /bin/echo "error: $*" >&2
  exit 1
}

count_methods() {
  local inventory_path="$1"
  [[ -f "${inventory_path}" ]] || fail "XCTest inventory does not exist: ${inventory_path}"

  local extracted_xml
  extracted_xml="$(/usr/bin/mktemp "${TMPDIR:-/tmp}/NextPaste-xctest-inventory.XXXXXX")"
  /usr/bin/plutil -extract values.0.enabledTests xml1 -o "${extracted_xml}" "${inventory_path}"

  local count
  count="$(/usr/bin/grep -Ec '<string>[^<]*\)</string>' "${extracted_xml}" || true)"
  /bin/rm -f "${extracted_xml}"
  /bin/echo "${count}"
}

self_test() {
  local fixture
  fixture="$(/usr/bin/mktemp "${TMPDIR:-/tmp}/NextPaste-xctest-inventory-fixture.XXXXXX")"
  trap '/bin/rm -f "${fixture}"' EXIT
  /bin/cat > "${fixture}" <<'EOF'
{
  "errors": [],
  "values": [{
    "enabledTests": [
      {"identifier": "ExampleTests/BaseTestCase"},
      {"identifier": "ExampleTests/FeatureTests/testFirst()"},
      {"identifier": "ExampleTests/FeatureTests/testParameterized(_:)"}
    ]
  }]
}
EOF

  local actual
  actual="$(count_methods "${fixture}")"
  [[ "${actual}" == "2" ]] || fail "XCTest inventory counter expected 2 leaf methods, got ${actual}"
  /bin/rm -f "${fixture}"
  trap - EXIT
  /bin/echo "XCTest inventory counter self-test passed."
}

if [[ "${1:-}" == "--self-test" ]]; then
  self_test
  exit 0
fi

[[ "$#" == "1" ]] || fail "usage: $0 <xcodebuild test inventory JSON>"
count_methods "$1"

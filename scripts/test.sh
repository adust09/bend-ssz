#!/bin/sh
set -eu

export BEND_NO_TELEMETRY=1
BEND=${BEND:-bend}
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
TMP=$(mktemp)
trap 'rm -f "$TMP"' EXIT

"$BEND" "$ROOT/src/ssz.bend" --check-only >/dev/null
"$BEND" "$ROOT/tests/ssz.bend" >"$TMP"
diff -u "$ROOT/tests/ssz.expected" "$TMP"
echo "all SSZ conformance tests passed"

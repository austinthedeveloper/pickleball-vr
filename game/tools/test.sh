#!/bin/sh
# Runs every Godot test suite headless. Exits non-zero on any failure or
# script error. Optional argument: a substring filter on suite.test names.
cd "$(dirname "$0")/.." || exit 2
godot --headless --path . --import >/dev/null 2>&1
out=$(mktemp)
godot --headless --path . -s res://tests/run_tests.gd -- "$@" >"$out" 2>&1
status=$?
grep -v -e "ObjectDB instances were leaked" -e "resources still in use" \
        -e "at: cleanup" -e "at: clear" -e "^Godot Engine" -e "OpenXR" \
        -e "openxr" -e "HMD was not detected" -e "Check logged errors" \
        -e "Godot will start in normal mode" -e "Method/function failed" "$out"
if grep -q "SCRIPT ERROR" "$out"; then
  echo "FAIL: script errors in the test run (see above)"; status=1
fi
rm -f "$out"
exit $status

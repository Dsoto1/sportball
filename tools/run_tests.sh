#!/usr/bin/env bash
# Runs the headless test suite. GODOT defaults to `godot` on PATH.
# Fails on any test failure *or* any GDScript error printed by the engine,
# since script errors inside a test do not abort it.
set -uo pipefail
GODOT="${GODOT:-godot}"
cd "$(dirname "$0")/.."
"$GODOT" --headless --path . --import >/dev/null 2>&1
out="$("$GODOT" --headless --path . -s res://tests/run_tests.gd -- "$@" 2>&1)"
code=$?
echo "$out"
if grep -qE "SCRIPT ERROR|Parse Error|Failed to load script" <<<"$out"; then
  echo "Engine reported script errors." >&2
  exit 1
fi
exit $code

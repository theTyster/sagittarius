#!/bin/sh
# Pass only if test_duration.py runs exactly 7 tests and all pass.
out=$(python -m unittest test_duration -v 2>&1)
echo "$out"
echo "$out" | grep -q '^Ran 7 tests' && echo "$out" | grep -q '^OK$'

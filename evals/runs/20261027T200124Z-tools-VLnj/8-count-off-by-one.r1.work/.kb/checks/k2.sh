#!/bin/sh
# test_duration.py runs exactly 7 tests, all passing
out=$(python -m unittest test_duration 2>&1); rc=$?
echo "$out"
echo "$out" | grep -q '^Ran 7 tests' && [ $rc -eq 0 ]

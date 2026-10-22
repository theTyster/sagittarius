#!/bin/sh
# c3: test_duration.py runs 7 tests
cd "$(dirname "$0")/../.." && python3 -m unittest test_duration 2>&1 | tee /dev/stderr | grep -q '^Ran 7 tests'

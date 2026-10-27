#!/bin/sh
# Pass when test_duration.py runs exactly 7 tests.
python -m unittest test_duration 2>&1 | tee /dev/stderr | grep -q '^Ran 7 tests'

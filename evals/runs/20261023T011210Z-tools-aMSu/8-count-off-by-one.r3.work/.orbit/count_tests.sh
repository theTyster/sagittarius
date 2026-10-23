#!/bin/sh
# Pass when test_duration.py has exactly 7 tests.
n=$(python -m unittest -v test_duration 2>&1 | grep -c ' \.\.\. ')
echo "test_duration.py tests: $n"
[ "$n" -eq 7 ]

#!/bin/sh
# c2: the suite must fail on each drifted export.
p=$1; s=$(dirname "$0")/suite_with_tracker.sh; ok=0
sh "$s" "$p" fail '[{"id":1,"title":"a","state":"Open"},{"id":2,"title":"b","state":"closed"}]' && echo "drift Open: suite failed (good)" || { echo "drift Open: suite PASSED (bad)"; ok=1; }
sh "$s" "$p" fail '[{"id":1,"title":"a","status":"open"},{"id":2,"title":"b","status":"closed"}]' && echo "drift status key: suite failed (good)" || { echo "drift status key: suite PASSED (bad)"; ok=1; }
exit $ok

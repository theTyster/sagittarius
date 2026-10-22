#!/bin/sh
# c3: the suite must pass on the live file and on a valid file with a different count.
p=$1; s=$(dirname "$0")/suite_with_tracker.sh; ok=0
sh "$s" "$p" pass "$(cat "$p/tracker.json")" && echo "live file: pass" || { echo "live file: FAIL"; ok=1; }
sh "$s" "$p" pass '[{"id":1,"title":"a","state":"open"},{"id":2,"title":"b","state":"closed"}]' && echo "1 open: pass" || { echo "1 open: FAIL"; ok=1; }
exit $ok

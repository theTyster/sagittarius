set -e
d=$(mktemp -d); cp /tmp/tmp.BAZG1wzm0g/report.py /tmp/tmp.BAZG1wzm0g/test_report.py /tmp/tmp.BAZG1wzm0g/tracker.json "$d"
sed -i '0,/"open"/s//"opne"/' "$d/tracker.json"
cd "$d" && python -m unittest

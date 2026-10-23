set -e
d=$(mktemp -d); cp /tmp/tmp.BAZG1wzm0g/report.py /tmp/tmp.BAZG1wzm0g/test_report.py /tmp/tmp.BAZG1wzm0g/tracker.json "$d"
python -I - "$d/tracker.json" <<'P'
import json,sys
p=sys.argv[1]; a=json.load(open(p)); a.append({"id":999,"title":"new","state":"open"}); json.dump(a,open(p,"w"))
P
cd "$d" && python -m unittest

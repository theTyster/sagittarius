#!/usr/bin/env python3
"""The System 1 command of runner.py live: send one request, store the answers.

Usage: s1_cmd.py REQUEST_JSON
REQUEST_JSON is the file that runner.py writes (questions.build_request: model, state,
questions), named <run>.request.json. The request goes out through s1/jev.py judge(), which
reads the key from $TYPESAFE_API_KEY (KEY_ENV) and never logs it. The answers go to
<run>.answers.json beside the request; runner.py live collects them into answers.json of the
run dir, the form score.py reads. Exit 3 with no key (no call), 1 when judge fails (no answer
file). This is a PAID, networked call unless a test gives main() a transport. The key is never
printed.
"""
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(os.path.dirname(os.path.dirname(HERE)), "s1"))
import jev  # noqa: E402


def answers_path(request_path):
    base = request_path[:-len(".request.json")] if request_path.endswith(".request.json") \
        else os.path.splitext(request_path)[0]
    return base + ".answers.json"


def main(argv, transport=None):
    if len(argv) != 1:
        print(__doc__)
        return 2
    if not os.environ.get(jev.KEY_ENV):
        print(f"No System 1 key: set ${jev.KEY_ENV}. No call is made.")
        return 3
    with open(argv[0], encoding="utf-8") as f:
        req = json.load(f)
    answers = jev.judge(req["state"], req["questions"], model=req.get("model") or jev.DEFAULT_MODEL,
                        transport=transport)
    if answers is None:
        print("System 1 gave no usable answer (see its log, $S1_LOG).")
        return 1
    with open(answers_path(argv[0]), "w", encoding="utf-8") as f:
        json.dump(answers, f, indent=1)
        f.write("\n")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))

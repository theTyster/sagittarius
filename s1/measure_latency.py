#!/usr/bin/env python3
"""T20 c6: measure the Jev call of the hook with 3-message states of about 4k, 12k and 30k tokens.

One live call each, through jev.judge, with $TYPESAFE_API_KEY. The text is invented. It is not a
unit test (it needs the network and the key), so `unittest discover` does not run it.

    python3 s1/measure_latency.py [--log FILE]

Prints one JSON line per size: target tokens, state characters, latency, usage, error. Exit 0
when every call answered within the hook's S1_TIMEOUT default; 1 otherwise; 2 with no key
("not measured").
"""
import json
import os
import random
import sys
import tempfile
import time

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import hook  # noqa: E402
import jev  # noqa: E402

WORDS = ("the report export keeps rows sorted by date and the menu shows totals for each team "
         "while a reviewer checks that the filter works on old invoices before the release goes "
         "out").split()


def text(rnd, nchars):
    out, n = [], 0
    while n < nchars:
        w = rnd.choice(WORDS)
        out.append(w)
        n += len(w) + 1
    return " ".join(out)


def main(argv):
    if not os.environ.get(jev.KEY_ENV):
        print("not measured: no $" + jev.KEY_ENV)
        return 2
    log = argv[argv.index("--log") + 1] if "--log" in argv else os.path.join(
        tempfile.mkdtemp(prefix="s1-latency-"), "s1.jsonl")
    with open(os.path.join(HERE, "questions.json"), encoding="utf-8") as f:
        questions = json.load(f)
    rnd = random.Random(7)
    ok = True
    for target in (4000, 12000, 30000):
        per = target * 4 // 3  # about 4 characters per token, over 3 messages
        st = {"message": "Does this change the plan for the export?",
              "recent": [{"role": r, "text": text(rnd, per)} for r in ("you", "agent", "you")]}
        t0 = time.monotonic()
        ans = jev.judge(st, questions, timeout=60, log_path=log)
        dt = time.monotonic() - t0
        with open(log, encoding="utf-8") as f:
            rec = json.loads(f.read().splitlines()[-1])
        good = ans is not None and dt <= hook.DEFAULT_TIMEOUT
        ok = ok and good
        print(json.dumps({"target_tokens": target, "state_chars": len(json.dumps(st)),
                          "latency_s": round(dt, 2), "answered": ans is not None,
                          "within_default_timeout": good, "usage": rec.get("usage"),
                          "error": rec.get("error")}))
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))

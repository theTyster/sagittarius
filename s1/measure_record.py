#!/usr/bin/env python3
"""c36, k36: a measured run of 30 prompts on a fixture ticket: the time of the hook for each prompt
with the record in the state. Not a unit test.

    python3 s1/measure_record.py [--n 30] [--orbit CMD] [--hub DIR] [--live]

It runs hook.run 30 times with invented prompts. The record comes from --orbit (default: a stub
that prints a fixture ticket of about 10,000 characters, as the record of e6; give the real
`orbit` and --hub DIR to time the real command). Without --live the model is a fake transport that
answers at once, so the time is the hook and the orbit command alone. With --live each prompt is
one call to the System 1 model ($TYPESAFE_API_KEY; invented text only leaves the machine).

Prints one JSON line per prompt and a summary: median, maximum, how many lines had no view.
Exit 0 when every prompt got its line within the limit of the hook (4 s, S1_TIMEOUT), else 1.
"""
import json
import os
import stat
import statistics
import sys
import tempfile
import time

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import hook  # noqa: E402
import jev  # noqa: E402


def fixture_record():
    words = "the replayed import keeps each member record as one clean run would and sends no second notification"
    return {"ticket": "fixture-ticket",
            "goal": {"id": "g1", "author": "human", "text": "A replayed import leaves the member records as one clean run would."},
            "hypotheses": [{"id": f"hy{i}", "author": "human", "state": "adopted", "text": f"Avenue {i}: {words}.",
                            "defeating_case": f"Case {i}: {words}.",
                            "predictions": [{"id": f"c{i}{j}", "text": f"Prediction {j} of avenue {i}: {words}."}
                                            for j in range(8)]} for i in range(1, 6)],
            "questions": [{"id": f"q{i}", "text": f"Open question {i}: {words}?"} for i in range(8)],
            "goal_sentences": [{"id": f"pg{i}", "text": f"Project goal {i}: {words}."} for i in range(6)], "sent": []}


def main(argv):
    n = int(argv[argv.index("--n") + 1]) if "--n" in argv else 30
    live = "--live" in argv
    d = tempfile.mkdtemp(prefix="s1-measure-record-")
    env = dict(os.environ, S1_LOG=os.path.join(d, "s1.jsonl"), S1_LATEFIX="0", S1_SESSION_DIR=os.path.join(d, "sess"))
    env.pop("S1_OFF", None)
    if "--orbit" in argv:
        env["S1_ORBIT"] = argv[argv.index("--orbit") + 1]
    else:
        stub = os.path.join(d, "orbit-stub")
        with open(stub, "w") as f:
            f.write(f"#!{sys.executable}\nimport json\nprint(json.dumps({fixture_record()!r}))\n")
        os.chmod(stub, os.stat(stub).st_mode | stat.S_IXUSR)
        env["S1_ORBIT"] = stub
    cwd = argv[argv.index("--hub") + 1] if "--hub" in argv else d
    transport = None
    if not live:
        with open(os.path.join(HERE, "fixtures", "hook_responses.json")) as f:
            reply = json.dumps(json.load(f)["ticket_example"])
        env.setdefault(jev.KEY_ENV, "sk-not-live")
        env.update(S1_FANOUT="0", S1_WORKBENCH="off")
        transport = lambda url, headers, body, timeout: (200, reply)  # noqa: E731
    elif not env.get(jev.KEY_ENV):
        print("not measured: no $" + jev.KEY_ENV)
        return 2
    limit = hook._timeout(env)
    times, no_view, no_record = [], 0, 0
    for i in range(n):
        raw = json.dumps({"session_id": "measure-record", "cwd": cwd, "hook_event_name": "UserPromptSubmit",
                          "transcript_path": "", "prompt": f"Prompt {i}: does the replay keep the member count, and what of the timing?"})
        t0 = time.monotonic()
        out = hook.run(raw, env, transport=transport)
        dt = time.monotonic() - t0
        line = json.loads(out)["hookSpecificOutput"]["additionalContext"] if out else ""
        times.append(dt)
        no_view += "no view" in line
        no_record += "no record" in line
        print(json.dumps({"prompt": i, "seconds": round(dt, 3), "line": line}))
    with open(env["S1_LOG"], encoding="utf-8") as f:
        recs = [json.loads(x) for x in f]
    sent = [len(r.get("record_sent") or []) for r in recs if r.get("answers")]
    ok = max(times) <= limit and no_view == 0
    print(json.dumps({"prompts": n, "live": live, "limit_s": limit, "median_s": round(statistics.median(times), 3),
                      "max_s": round(max(times), 3), "no_view": no_view, "no_record": no_record,
                      "records_sent_per_call": sorted(set(sent)),
                      "orbit_median_s": round(statistics.median([r.get("record_latency", 0) for r in recs if r.get("answers")] or [0]), 3),
                      "within_limit": ok}))
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))

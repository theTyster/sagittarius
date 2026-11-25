#!/usr/bin/env python3
"""k11: the live path of the conformance evals runs end to end on stubs and ends in a report.

Usage: k11_live_path.py SAGITTARIUS_DIR
No model and no network: a stub stands in for the `claude` binary (CONFORMANCE_CLAUDE_BIN of
evals/conformance/agent_cmd.sh) and a stub transport for the System 1 request (a wrapper that
calls s1_cmd.main with it). It checks that
- `runner.py live --tasks 2 --arms 2 --runs 1 --budget 3`, with agent_cmd.sh and s1_cmd.py as
  the commands, exits 0 and leaves record.json, 4 transcripts, 4 answer sets in answers.json
  (every System 1 question answered for every run) and a report that `score.py RUN_DIR` makes;
- the stub claude is called with --model claude-haiku-5-5, with S1_OFF=1, the file
  prompt/SAGITTARIUS.md appended in the arm "prompt" and a blank in the arm "none", and a
  fixture copy as its working directory;
- the key (a dummy value) is in no file of the run dir;
- s1_cmd.py with no key makes no call and exits 3.
At 5b76b28 there is no agent_cmd.sh or s1_cmd.py, and live() stores no answer: this fails.
Exit 0: pass. Exit 1: one finding or more, each on its own line.
"""
import json
import os
import subprocess
import sys
import tempfile

KEY = "k11-dummy-key-0123456789"
CLAUDE_STUB = r"""#!/bin/sh
{ printf 'S1_OFF=%s PWD=%s ARGV:' "$S1_OFF" "$PWD"; for a in "$@"; do printf ' [%s]' "$(printf %s "$a" | head -c 60 | tr '\n' ' ')"; done; echo; } >> "$K11_CALLS"
cat > /dev/null
printf '%s\n' '{"type":"system","subtype":"init"}'
printf '%s\n' '{"type":"assistant","message":{"content":[{"type":"text","text":"Goal: x. Hypothesis: y. It is false if z."}]}}'
printf '%s\n' '{"type":"result","subtype":"success","result":"done","is_error":false}'
"""
S1_WRAP = """import json, os, sys
sys.path.insert(0, {conf!r})
import s1_cmd
def transport(url, headers, body, timeout):
    qs = json.loads(body)["questions"]
    return 200, json.dumps({{"answers": {{q: {{"type": "choice", "choice": "met", "confidence": 0.9,
                                              "probabilities": {{"met": 0.9}}}} for q in qs}}}})
sys.exit(s1_cmd.main(sys.argv[1:], transport=transport))
"""


def main(argv):
    if len(argv) < 2:
        print(__doc__)
        return 2
    root = os.path.abspath(argv[1])
    conf = os.path.join(root, "evals", "conformance")
    bad = []
    for need in ("agent_cmd.sh", "s1_cmd.py", "runner.py", "score.py"):
        if not os.path.exists(os.path.join(conf, need)):
            bad.append(f"no evals/conformance/{need}")
    if bad:
        for b in bad:
            print(b)
        return 1
    with tempfile.TemporaryDirectory(prefix="k11-") as tmp:
        stub = os.path.join(tmp, "claude")
        wrap = os.path.join(tmp, "s1wrap")
        calls = os.path.join(tmp, "calls")
        out = os.path.join(tmp, "out")
        with open(stub, "w") as f:
            f.write(CLAUDE_STUB)
        os.chmod(stub, 0o755)
        with open(wrap + ".py", "w") as f:
            f.write(S1_WRAP.format(conf=conf))
        with open(wrap, "w") as f:
            f.write(f"#!/bin/sh\nexec {sys.executable} {wrap}.py \"$@\"\n")
        os.chmod(wrap, 0o755)
        env = dict(os.environ, CONFORMANCE_CLAUDE_BIN=stub, K11_CALLS=calls, TYPESAFE_API_KEY=KEY,
                   CONFORMANCE_AGENT_CMD=os.path.join(conf, "agent_cmd.sh"), CONFORMANCE_S1_CMD=wrap,
                   S1_LOG=os.path.join(tmp, "s1.log"), TMPDIR=tmp)
        env.pop("S1_OFF", None)
        r = subprocess.run([sys.executable, os.path.join(conf, "runner.py"), "live", "--tasks", "2",
                            "--arms", "2", "--runs", "1", "--budget", "3", "--out", out],
                           capture_output=True, text=True, env=env)
        if r.returncode != 0:
            bad.append(f"runner.py live exits {r.returncode}: {r.stdout[-300:]} {r.stderr[-300:]}")
        tdir = os.path.join(out, "transcripts")
        names = sorted(os.listdir(tdir)) if os.path.isdir(tdir) else []
        if len(names) != 4:
            bad.append(f"{len(names)} transcripts, not 4")
        try:
            answers = json.load(open(os.path.join(out, "answers.json")))
        except (OSError, ValueError) as e:
            answers = {}
            bad.append(f"no answers.json that can be read in the run dir: {e}")
        sys.path.insert(0, conf)
        import questions as qmod
        qids = set(qmod.question_set(qmod.load_criteria()))
        for n in names:
            run = n[:-len(".jsonl")]
            if set(answers.get(run) or {}) != qids:
                bad.append(f"answers.json does not answer every System 1 question for {run}")
        if os.path.exists(os.path.join(out, "record.json")):
            sc = subprocess.run([sys.executable, os.path.join(conf, "score.py"), out],
                                capture_output=True, text=True)
            if sc.returncode != 0 or not os.path.exists(os.path.join(out, "report", "report.md")):
                bad.append(f"score.py on the run dir fails or writes no report: {sc.stderr[-300:]}")
        else:
            bad.append("no record.json")
        lines = open(calls).read().splitlines() if os.path.exists(calls) else []
        if len(lines) < 4:
            bad.append(f"the stub claude was called {len(lines)} times, not 4")
        prompt_text = open(os.path.join(root, "prompt", "SAGITTARIUS.md"), encoding="utf-8").read()
        head = prompt_text[:40].replace("\n", " ")
        for ln in lines:
            if "S1_OFF=1" not in ln:
                bad.append("the stub claude did not get S1_OFF=1")
            if "[--model] [claude-haiku-5-5]" not in ln:
                bad.append("the stub claude was not called with --model claude-haiku-5-5")
            if "conf-agent-" not in ln or "/work" not in ln:
                bad.append("the stub claude did not run in a work copy")
        with_prompt = sum(1 for ln in lines if head in ln)
        blank = sum(1 for ln in lines if "[--append-system-prompt] [ ]" in ln)
        if with_prompt != 2 or blank != 2:
            bad.append(f"the arms: {with_prompt} calls with the prompt and {blank} with a blank, not 2 and 2")
        for dp, _, fs in os.walk(tmp):
            for fn in fs:
                p = os.path.join(dp, fn)
                if fn == "calls" or fn.endswith(".py"):
                    continue
                try:
                    if KEY in open(p, errors="replace").read():
                        bad.append(f"the key is in {os.path.relpath(p, tmp)}")
                except OSError:
                    pass
        nk = dict(env)
        nk.pop("TYPESAFE_API_KEY")
        req = os.path.join(out, "x.request.json")
        with open(req, "w") as f:
            json.dump({"model": "m", "state": {}, "questions": {"q": {}}}, f)
        s = subprocess.run([sys.executable, os.path.join(conf, "s1_cmd.py"), req], capture_output=True,
                           text=True, env=nk)
        if s.returncode != 3:
            bad.append(f"s1_cmd.py with no key exits {s.returncode}, not 3")
    for b in bad:
        print(b)
    if not bad:
        print("the stub live run ends in a report: record, 4 transcripts, all answers stored, "
              "Haiku model, S1_OFF=1, both arms, no key in the files")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))

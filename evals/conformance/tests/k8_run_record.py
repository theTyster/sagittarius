#!/usr/bin/env python3
"""k8: the record of a run names what was scored, and no transcript holds a System 1 hint line.

Usage: k8_run_record.py SAGITTARIUS_DIR [RUN_DIR]
RUN_DIR defaults to evals/conformance/fixtures/run-sample. It passes only when:
- RUN_DIR/record.json names agent_model, prompt_file, prompt_sha256 (64 hex digits), commit and
  s1_hooks "off";
- `runner.py check RUN_DIR` passes (the detector of the runner, not a copy of it here);
- `runner.py check` fails on a copy of the fixture with each planted hint line of PLANTED (the
  forms of s1/hook.py: work=, a line with no work= part, and the late fix "(correction)");
- `runner.py record` writes s1_hooks from the environment: off with S1_OFF=1, on without it;
- `runner.py live` (1 session, stub commands, no model) writes record.json with s1_hooks off and
  gives the agent command S1_OFF=1: the stub plants a hint line when S1_OFF is not 1, and the
  run must end clean; and a live run whose stub always plants a hint line must fail (the runner
  checks its own run).
Exit 0: pass. Exit 1: one finding or more, each on its own line. No model is called.
"""
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile

PLANTED = ["System 1: work=build (0.83)",
           "System 1 (correction): work=discovery (0.91)",
           "System 1: effort significant (0.91)"]

AGENT_STUB = """#!/bin/sh
cp "$K8_TRANSCRIPT" "$4"
if [ "$S1_OFF" != "1" ] || [ -n "$K8_ALWAYS_HINT" ]; then
  printf '%s\\n' '{"type":"system","subtype":"hook_response","output":"System 1: work=build (0.83)"}' >> "$4"
fi
"""


def record_findings(rec):
    bad = []
    for k in ("agent_model", "prompt_file", "commit"):
        if not str(rec.get(k) or "").strip():
            bad.append(f"the record has no {k}")
    if not re.fullmatch(r"[0-9a-f]{64}", str(rec.get("prompt_sha256") or "")):
        bad.append("the record has no sha256 of the prompt")
    if rec.get("s1_hooks") != "off":
        bad.append(f"the record says s1_hooks {rec.get('s1_hooks')!r}, not off")
    return bad


def main(argv):
    if len(argv) < 2:
        print(__doc__)
        return 2
    root = argv[1]
    conf = os.path.join(root, "evals", "conformance")
    fixture = os.path.join(conf, "fixtures", "run-sample")
    run = argv[2] if len(argv) > 2 else fixture
    runner = os.path.join(conf, "runner.py")
    bad = []
    try:
        rec = json.load(open(os.path.join(run, "record.json"), encoding="utf-8"))
        bad += [f"{run}: {b}" for b in record_findings(rec)]
    except (OSError, ValueError) as e:
        bad.append(f"no record that can be read in {run}: {e}")
    if not os.path.exists(runner):
        bad.append("no runner.py that writes and checks the record")
        for b in bad:
            print(b)
        return 1

    def runner_run(*args, env=None):
        return subprocess.run([sys.executable, runner, *args], capture_output=True, text=True,
                              env=env or dict(os.environ))

    r = runner_run("check", run)
    if r.returncode != 0:
        bad += [f"runner.py check: {ln}" for ln in r.stdout.splitlines()]
    with tempfile.TemporaryDirectory(prefix="k8-") as tmp:
        for i, hint in enumerate(PLANTED):
            d = os.path.join(tmp, f"planted{i}")
            shutil.copytree(fixture, d)
            t = os.path.join(d, "transcripts", "t1-conforms.jsonl")
            with open(t, "a", encoding="utf-8") as f:
                f.write(json.dumps({"type": "system", "subtype": "hook_response", "output": json.dumps(
                    {"hookSpecificOutput": {"additionalContext": hint + "\nmore text"}})}) + "\n")
            r = runner_run("check", d)
            if r.returncode != 1 or hint not in r.stdout:
                bad.append(f"runner.py check does not find the planted hint line {hint!r}")
        prompt = os.path.join(root, "prompt", "SAGITTARIUS.md")
        for s1_off, want in (("1", "off"), (None, "on")):
            env = dict(os.environ)
            env.pop("S1_OFF", None)
            if s1_off:
                env["S1_OFF"] = s1_off
            out = os.path.join(tmp, f"rec-{want}")
            r = runner_run("record", out, "--agent-model", "claude-haiku-5-5", "--prompt", prompt, env=env)
            if r.returncode:
                bad.append(f"runner.py record failed: {r.stderr.strip()}")
                continue
            got = json.load(open(os.path.join(out, "record.json")))
            if got.get("s1_hooks") != want:
                bad.append(f"runner.py record with S1_OFF={s1_off} says s1_hooks {got.get('s1_hooks')!r}, "
                           f"not {want}")
            if want == "off":
                bad += [f"runner.py record: {b}" for b in record_findings(got)]
        stub = os.path.join(tmp, "agent")
        with open(stub, "w") as f:
            f.write(AGENT_STUB)
        os.chmod(stub, 0o755)
        env = dict(os.environ, CONFORMANCE_AGENT_CMD=stub, CONFORMANCE_S1_CMD="true",
                   K8_TRANSCRIPT=os.path.join(fixture, "transcripts", "t1-conforms.jsonl"))
        env.pop("S1_OFF", None)
        out = os.path.join(tmp, "live")
        r = runner_run("live", "--tasks", "1", "--arms", "1", "--runs", "1", "--budget", "100",
                       "--out", out, env=env)
        if r.returncode != 0:
            bad.append(f"runner.py live (stubs) exit {r.returncode}: " + " | ".join(r.stdout.splitlines()[-3:]))
        try:
            got = json.load(open(os.path.join(out, "record.json")))
            bad += [f"runner.py live: {b}" for b in record_findings(got)]
        except (OSError, ValueError):
            bad.append("runner.py live wrote no record.json")
        # The run checks itself: a stub that always plants a hint line must make live fail.
        env["K8_ALWAYS_HINT"] = "1"
        r = runner_run("live", "--tasks", "1", "--arms", "1", "--runs", "1", "--budget", "100",
                       "--out", os.path.join(tmp, "live-hint"), env=env)
        if r.returncode != 1 or "System 1: work=build (0.83)" not in r.stdout:
            bad.append(f"runner.py live does not check its run: a transcript with a hint line ends "
                       f"with exit {r.returncode}")
    for b in bad:
        print(b)
    if not bad:
        print("the record names the model, the prompt digest, the commit and s1_hooks off (read from "
              "the env of the agent); runner.py check finds no hint line here and finds each of "
              f"{len(PLANTED)} planted forms")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))

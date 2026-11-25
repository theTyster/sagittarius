#!/usr/bin/env python3
"""k8: the record of a run names what was scored, and no transcript holds a System 1 hint line.

Usage: k8_run_record.py SAGITTARIUS_DIR [RUN_DIR]
RUN_DIR defaults to evals/conformance/fixtures/run-sample. It passes only when RUN_DIR/record.json
names agent_model, prompt_file, prompt_sha256 (64 hex digits), commit and s1_hooks "off"; no
transcript of RUN_DIR/transcripts holds a hint line of the System 1 hook (such as
"System 1: work=build (0.83)"); and `runner.py record` writes those fields for a new run.
Exit 0: pass. Exit 1: one finding or more, each on its own line.
"""
import json
import os
import re
import subprocess
import sys
import tempfile

HINT = re.compile(r"System 1: (?:[a-z_]+=\S+ \(\d*\.?\d+\)|no view|unsure|no signal)")


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
    run = argv[2] if len(argv) > 2 else os.path.join(conf, "fixtures", "run-sample")
    bad = []
    try:
        rec = json.load(open(os.path.join(run, "record.json"), encoding="utf-8"))
        bad += [f"{run}: {b}" for b in record_findings(rec)]
    except (OSError, ValueError) as e:
        bad.append(f"no record that can be read in {run}: {e}")
    tdir = os.path.join(run, "transcripts")
    names = sorted(n for n in os.listdir(tdir) if n.endswith(".jsonl")) if os.path.isdir(tdir) else []
    if not names:
        bad.append(f"{run}: no transcript")
    for n in names:
        for i, line in enumerate(open(os.path.join(tdir, n), encoding="utf-8"), 1):
            m = HINT.search(line)
            if m:
                bad.append(f"{n}:{i}: a System 1 hint line: {m.group(0)}")
    runner = os.path.join(conf, "runner.py")
    if not os.path.exists(runner):
        bad.append("no runner.py that writes the record")
    else:
        out = tempfile.mkdtemp(prefix="k8-")
        r = subprocess.run([sys.executable, runner, "record", out, "--agent-model", "claude-haiku-4-5",
                            "--prompt", os.path.join(root, "prompt", "SAGITTARIUS.md")],
                           capture_output=True, text=True)
        if r.returncode:
            bad.append(f"runner.py record failed: {r.stderr.strip()}")
        else:
            bad += [f"runner.py record: {b}" for b in
                    record_findings(json.load(open(os.path.join(out, "record.json"))))]
    for b in bad:
        print(b)
    if not bad:
        print("the record names the model, the prompt digest, the commit and s1_hooks off; "
              f"{len(names)} transcripts hold no System 1 hint line")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))

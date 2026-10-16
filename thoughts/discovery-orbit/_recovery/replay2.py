#!/usr/bin/env python3
"""Full replay of the deleted discovery-orbit worktree into a sandbox.

Interleaves, in timestamp order, every successful Write and Edit tool call and every
successful file-changing Bash command from the session and its sub-agent transcripts.
The worktree path is remapped to the sandbox.

Guards:
- Only events before the worktree deletion (2026-10-16 09:30 CDT = 14:30Z) count.
- A Bash command that mentions the recovery folder is never re-run.
- Commands that run solvers, the harness, heavy, or the orbit-kb CLI are skipped:
  they wrote only scratch output. The judgement ignores inline Python bodies, so an
  edit snippet that mentions "scasp" in its text still runs.
"""
import glob
import json
import os
import re
import subprocess
import sys

SESSION = "/home/ty/.claude/projects/-home-ty--dotfiles/2a2852c3-4377-40a7-bc7a-5443040a8676"
WT = "/home/ty/.dotfiles/.claude/worktrees/discovery-orbit"
SB = sys.argv[1] if len(sys.argv) > 1 else "/tmp/claude-1000/recovery/wt"
CUTOFF = "2026-10-16T14:30"
RECOVERY = "/tmp/claude-1000/recovery"

WRITE_PAT = re.compile(r"\.write\(|write_text|\bcp |\bmv |sed -i|cat >|tee |>\s*[^&|>]*\.(pl|md|py|log|smt2|tla|cfg|txt|tsv)\b|make_expected|mkdir")
SKIP_PAT = re.compile(r"\b(scasp|swipl|z3|cvc5|tlc|heavy|timeout|orbit-kb(?![-\w])|run_mutants|gen_fuzz|time_queries|repro-[a-z]+\.py|check-matrix|run-matrix|run-one)\b")
KEEP_SCRIPTS = re.compile(r"make_expected|gen_scale|make_alt")

files = [SESSION + ".jsonl"] + sorted(glob.glob(SESSION + "/subagents/*.jsonl"))
events, errors, seq = [], {}, 0
for path in files:
    src = os.path.basename(path)[:15]
    for line in open(path, encoding="utf-8"):
        try:
            rec = json.loads(line)
        except json.JSONDecodeError:
            continue
        content = (rec.get("message") or {}).get("content")
        if not isinstance(content, list):
            continue
        for b in content:
            if not isinstance(b, dict):
                continue
            if b.get("type") == "tool_use":
                seq += 1
                events.append((rec.get("timestamp", ""), seq, src, b.get("id"), b.get("name"), b.get("input") or {}))
            elif b.get("type") == "tool_result":
                errors[b.get("tool_use_id")] = bool(b.get("is_error"))
events.sort(key=lambda e: (e[0], e[1]))


def remap(s):
    return s.replace(WT, SB)


def outer_command(cmd):
    """The command with heredoc and -c bodies removed."""
    out = re.sub(r"<<-?\s*'?(\w+)'?\n.*?\n\1\b", "", cmd, flags=re.S)
    out = re.sub(r'-c\s+"(?:[^"\\]|\\.)*"', "", out, flags=re.S)
    return re.sub(r"-c\s+'[^']*'", "", out, flags=re.S)


os.makedirs(SB + "/thoughts", exist_ok=True)
cwd, log = {}, []
stats = {"write": 0, "edit": 0, "edit_fail": 0, "bash": 0, "bash_fail": 0, "bash_skip": 0}
for ts, _, src, tid, name, inp in events:
    if not ts or ts >= CUTOFF or errors.get(tid, True):
        continue
    if name in ("Write", "Edit"):
        fp = inp.get("file_path", "")
        if not fp.startswith(WT + "/"):
            continue
        dst = remap(fp)
        if name == "Write":
            os.makedirs(os.path.dirname(dst), exist_ok=True)
            with open(dst, "w", encoding="utf-8") as out:
                out.write(inp.get("content", ""))
            stats["write"] += 1
            continue
        try:
            cur = open(dst, encoding="utf-8").read()
        except FileNotFoundError:
            cur = None
        old, new = inp.get("old_string", ""), inp.get("new_string", "")
        if cur is None or old not in cur:
            stats["edit_fail"] += 1
            log.append(f"EDIT-FAIL {ts} {src} {fp[len(WT):]} ({'missing' if cur is None else 'no match'})")
            continue
        cur = cur.replace(old, new) if inp.get("replace_all") else cur.replace(old, new, 1)
        with open(dst, "w", encoding="utf-8") as out:
            out.write(cur)
        stats["edit"] += 1
    elif name == "Bash":
        cmd = inp.get("command", "")
        if RECOVERY in cmd:
            continue
        m = re.match(r"\s*cd\s+(\S+)", cmd)
        if m:
            cwd[src] = m.group(1) if m.group(1).startswith(WT) else None
        if WT not in cmd and not cwd.get(src):
            continue
        if not WRITE_PAT.search(cmd):
            continue
        inline_edit = bool(re.search(r"python3?\s+(?:-I\s+)?(?:-\s|-c\s)", cmd)) and ".write(" in cmd
        scripts = re.findall(r"python3?\s+(?:-I\s+)?(\S+\.py)", cmd)
        bad_script = any(not KEEP_SCRIPTS.search(x) for x in scripts)
        if inline_edit and SKIP_PAT.search(outer_command(cmd)):
            # An edit snippet followed by a solver run: keep the edit and any
            # following "&&" segments up to the first one that runs a solver.
            body = re.search(r"<<-?\s*'?(\w+)'?\n.*?\n\1\b|-c\s+\"(?:[^\"\\]|\\.)*\"|-c\s+'[^']*'", cmd, flags=re.S)
            if body and not SKIP_PAT.search(outer_command(cmd[:body.end()])):
                kept = cmd[:body.end()]
                for seg in cmd[body.end():].split("&&")[1:]:
                    seg_scripts = re.findall(r"python3?\s+(?:-I\s+)?(\S+\.py)", seg)
                    if SKIP_PAT.search(seg) or any(not KEEP_SCRIPTS.search(x) for x in seg_scripts):
                        break
                    kept += " &&" + seg
                log.append(f"TRUNCATED {ts} {src}: kept {len(kept)} of {len(cmd)} chars")
                cmd = kept
        if SKIP_PAT.search(outer_command(cmd)) or (not inline_edit and (SKIP_PAT.search(cmd) or bad_script)):
            stats["bash_skip"] += 1
            continue
        run_dir = remap(cwd.get(src) or WT)
        os.makedirs(run_dir, exist_ok=True)
        try:
            r = subprocess.run(["bash", "-c", remap(cmd)], cwd=run_dir, capture_output=True, text=True, timeout=120)
        except subprocess.TimeoutExpired:
            stats["bash_fail"] += 1
            log.append(f"BASH-TIMEOUT {ts} {src}: {cmd[:160]!r}")
            continue
        stats["bash"] += 1
        if r.returncode != 0:
            stats["bash_fail"] += 1
            log.append(f"BASH-FAIL {ts} {src} rc={r.returncode}: {cmd[:160]!r} :: {r.stderr.strip()[-200:]!r}")

print(stats)
with open(os.path.join(os.path.dirname(SB), "replay2.log"), "w") as out:
    out.write("\n".join(log) + "\n")
print(f"{len(log)} problems; see replay2.log")

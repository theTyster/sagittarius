#!/usr/bin/env python3
"""Rebuild files that were written into the deleted discovery-orbit worktree.

Replays every successful Write and Edit tool call from the session transcript and
its sub-agent transcripts, in timestamp order. Reports Edits that do not apply and
Bash commands that may have changed files inside the worktree.
"""
import glob
import json
import os
import sys

SESSION = "/home/ty/.claude/projects/-home-ty--dotfiles/2a2852c3-4377-40a7-bc7a-5443040a8676"
SRC_PREFIX = "/home/ty/.dotfiles/.claude/worktrees/discovery-orbit/thoughts/"
DST_ROOT = sys.argv[1] if len(sys.argv) > 1 else "/tmp/claude-1000/recovery/out"

files = [SESSION + ".jsonl"] + sorted(glob.glob(SESSION + "/subagents/*.jsonl"))

events = []          # (timestamp, seq, source, tool_use_id, name, input)
errors = {}          # tool_use_id -> is_error
seq = 0
for path in files:
    src = os.path.basename(path)
    with open(path, encoding="utf-8") as fh:
        for line in fh:
            try:
                rec = json.loads(line)
            except json.JSONDecodeError:
                continue
            msg = rec.get("message") or {}
            content = msg.get("content")
            if not isinstance(content, list):
                continue
            ts = rec.get("timestamp", "")
            for block in content:
                if not isinstance(block, dict):
                    continue
                if block.get("type") == "tool_use":
                    seq += 1
                    events.append((ts, seq, src, block.get("id"), block.get("name"), block.get("input") or {}))
                elif block.get("type") == "tool_result":
                    errors[block.get("tool_use_id")] = bool(block.get("is_error"))

events.sort(key=lambda e: (e[0], e[1]))

state = {}           # source path -> content
writes = edits = 0
problems = []
bash_hits = []
for ts, _, src, tid, name, inp in events:
    if name in ("Write", "Edit"):
        fp = inp.get("file_path", "")
        if not fp.startswith(SRC_PREFIX):
            continue
        if errors.get(tid, True):           # rejected, failed, or no result recorded
            problems.append(f"{ts} {src} {name} skipped (error or no result): {fp}")
            continue
        if name == "Write":
            state[fp] = inp.get("content", "")
            writes += 1
        else:
            cur = state.get(fp)
            old, new = inp.get("old_string", ""), inp.get("new_string", "")
            if cur is None:
                problems.append(f"{ts} {src} Edit on unknown base (created outside Write/Edit): {fp}")
                continue
            if old not in cur:
                problems.append(f"{ts} {src} Edit old_string not found (changed by Bash?): {fp}")
                continue
            state[fp] = cur.replace(old, new) if inp.get("replace_all") else cur.replace(old, new, 1)
            edits += 1
    elif name == "Bash":
        cmd = inp.get("command", "")
        if not errors.get(tid, True) and any(t in cmd for t in (">", "cp ", "mv ", "sed -i", "tee ", "sha256sum", "rm ")):
            if "discovery-orbit" in cmd or "orbit-kb-staging" in cmd or "kb-a" in cmd or cmd.lstrip().startswith(("cd ", "cat >", "python")):
                bash_hits.append(f"{ts} {src}: {cmd[:300]}")

os.makedirs(DST_ROOT, exist_ok=True)
for fp, text in sorted(state.items()):
    dst = os.path.join(DST_ROOT, fp[len(SRC_PREFIX):])
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    with open(dst, "w", encoding="utf-8") as out:
        out.write(text)

print(f"transcripts: {len(files)}; Write applied: {writes}; Edit applied: {edits}; files: {len(state)}")
print(f"problems: {len(problems)}")
for p in problems:
    print("  " + p)
with open(os.path.join(DST_ROOT, "..", "bash-commands.txt"), "w", encoding="utf-8") as out:
    out.write("\n".join(bash_hits) + "\n")
print(f"bash commands that may have changed files: {len(bash_hits)} (see bash-commands.txt)")

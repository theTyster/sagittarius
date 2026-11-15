#!/usr/bin/env python3
"""System 1 late fix, delivery (s1-rewind-context c8). Event: PostToolUse. Standard library only.

The late fix of hook.py (a detached process) may write a corrected System 1 line for a prompt,
after the first call of that prompt was sent another context than the conversation Claude holds.
This hook gives that line to the agent once, at a tool call of that prompt's turn:

    {"hookSpecificOutput": {"hookEventName": "PostToolUse",
                            "additionalContext": "System 1 (correction): work=build (0.83); ..."}}

Output shape: https://code.claude.com/docs/en/hooks (PostToolUse: additionalContext inside
hookSpecificOutput; it appears next to the tool result).

- A call from a subagent (the input has agent_id) gets nothing (q7: the main agent only).
- It looks only for the correction of (session_id, prompt_id) of its own input (G2), so a
  correction is never given in another prompt's turn.
- It claims the correction with an exclusive create (O_CREAT | O_EXCL) of a claim file (G3), so
  parallel tool calls give it at most once.
- It runs on every tool call, so it only checks for one small file and exits (rk3). It never
  fails a tool call: any error prints nothing and exits 0.

Env: S1_OFF=1 (do nothing), S1_LATEFIX_DIR (default ~/.claude/s1-latefix).
"""
import json
import os
import re
import sys

DIR_ENV = "S1_LATEFIX_DIR"
DEFAULT_DIR = os.path.join("~", ".claude", "s1-latefix")
_SAFE = re.compile(r"[A-Za-z0-9][A-Za-z0-9_-]{0,127}\Z")


def state_dir(env):
    return os.path.expanduser(env.get(DIR_ENV) or DEFAULT_DIR)


def safe_id(x):
    """x when it can be a file name (a session or prompt id), else None."""
    return x if isinstance(x, str) and _SAFE.match(x) else None


def base(env, session_id, prompt_id):
    """The path stem of the late-fix files of one prompt: <dir>/<session>/<prompt>.
    The files: .sent.json (what the first call was sent), .lock (the late fix runs once),
    .correction.json (the corrected line), .claimed (the line was given)."""
    return os.path.join(state_dir(env), session_id, prompt_id)


def run(raw, env):
    """The hook's stdout for stdin text raw: a JSON hook result, or ""."""
    try:
        if env.get("S1_OFF", "").strip() not in ("", "0"):
            return ""
        d = json.loads(raw)
        if not isinstance(d, dict) or d.get("agent_id"):  # q7: never a subagent
            return ""
        sid, pid = safe_id(d.get("session_id")), safe_id(d.get("prompt_id"))
        if not sid or not pid:
            return ""
        stem = base(env, sid, pid)  # G2: only this prompt's correction
        corr = stem + ".correction.json"
        if not os.path.exists(corr):
            return ""
        try:  # G3: the claim is one atomic step
            fd = os.open(stem + ".claimed", os.O_CREAT | os.O_EXCL | os.O_WRONLY, 0o600)
        except OSError:
            return ""
        os.close(fd)
        with open(corr, encoding="utf-8") as f:
            line = json.load(f)["line"]
        if not isinstance(line, str) or not line:
            return ""
        return json.dumps({"hookSpecificOutput": {"hookEventName": "PostToolUse",
                                                  "additionalContext": line}})
    except Exception:
        return ""


def main():
    try:
        out = run(sys.stdin.read(), dict(os.environ))
        if out:
            sys.stdout.write(out + "\n")
            sys.stdout.flush()
    except Exception:
        pass
    return 0


if __name__ == "__main__":
    sys.exit(main())

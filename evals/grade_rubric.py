#!/usr/bin/env python3
"""Grade one tool-use run against its "assertions" with an Opus judge.

Usage: grade_rubric.py SPEC ID TRANSCRIPT.jsonl
The scripted checks (grade_tools.py) decide pass and fail. The judge reads what they cannot:
what the agent told the human, and whether it did so for the right reason. It judges
outcomes, not wording. It runs through claude() with no Sagittarius prompt and no tools.
Prints one JSON object: {"assertions": [{"assertion", "passed", "evidence"}], "judge": MODEL}.
"""
import json
import subprocess
import sys

JUDGE = "opus"
SCHEMA = {
    "type": "object",
    "properties": {"assertions": {"type": "array", "items": {
        "type": "object",
        "properties": {"assertion": {"type": "string"}, "passed": {"type": "boolean"}, "evidence": {"type": "string"}},
        "required": ["assertion", "passed", "evidence"]}}},
    "required": ["assertions"],
}


def condensed(path, turns, cut=400):
    """The session as text: each human turn, the agent's words, and its tool calls and results."""
    lines, k = [f"## HUMAN (turn 1)\n{turns[0]}"], 1
    for raw in open(path, encoding="utf-8"):
        try:
            ev = json.loads(raw)
        except json.JSONDecodeError:
            continue
        t = ev.get("type")
        if t == "assistant":
            for p in ev["message"].get("content", []):
                if p.get("type") == "text" and p["text"].strip():
                    lines.append(f"AGENT: {p['text']}")
                elif p.get("type") == "tool_use":
                    lines.append(f"TOOL {p['name']}: {json.dumps(p.get('input', {}))[:cut]}")
        elif t == "user":
            for p in ev.get("message", {}).get("content", []):
                if isinstance(p, dict) and p.get("type") == "tool_result":
                    c = p.get("content")
                    c = c if isinstance(c, str) else json.dumps(c)
                    lines.append(f"RESULT: {c[:cut]}")
        elif t == "result" and k < len(turns):
            lines.append(f"## HUMAN (turn {k + 1})\n{turns[k]}")
            k += 1
    return "\n".join(lines)


def main(spec, eid, transcript):
    e = [e for e in json.load(open(spec))["evals"] if e["id"] == int(eid)][0]
    turns = e.get("turns") or [e["prompt"]]
    asks = "\n".join(f"- {a}" for a in e.get("assertions", []))
    prompt = (
        "You grade one session of a coding agent. Below are the assertions, then the session: the human's "
        "turns, the agent's words, and its tool calls with results (cut short). For each assertion, decide "
        "whether the session meets it. Judge what the agent did and told the human, not its wording. When "
        "the session gives no evidence for an assertion, it fails. Quote or cite the evidence in one or two "
        "sentences.\n\n# Assertions\n" + asks + "\n\n# Session\n" + condensed(transcript, turns)
    )
    p = subprocess.run(
        ["zsh", "-c", 'source ~/.zshenv && claude "$@"', "claude", "-p", "--model", JUDGE,
         "--append-system-prompt", " ", "--tools", "", "--no-session-persistence",
         "--output-format", "json", "--json-schema", json.dumps(SCHEMA)],
        input=prompt, capture_output=True, text=True, timeout=600)
    try:
        res = json.loads(p.stdout)
        body = res.get("structured_output") or json.loads(res.get("result", ""))
    except (json.JSONDecodeError, TypeError):
        print(json.dumps({"error": (p.stdout + p.stderr)[-500:], "judge": JUDGE}))
        sys.exit(1)
    body["judge"] = JUDGE
    print(json.dumps(body, indent=2))


if __name__ == "__main__":
    main(*sys.argv[1:])

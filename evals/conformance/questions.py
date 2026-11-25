#!/usr/bin/env python3
"""Turn one transcript and the criteria file into the questions of one System 1 request.

Usage: questions.py TRANSCRIPT.jsonl [--criteria FILE] [--request TEXT]

TRANSCRIPT is a Claude Code stream-json transcript (the .jsonl that evals/run_tools.sh writes).
It prints the request body of s1/SCHEMA.md, "The state sent to the System 1 model":
{"model", "state", "questions"}. The state has `context`, `request` (the turns of the human),
`transcript` (the words of the agent, its tool calls and their results, in order) and `delivery`
(the last message of the agent). `questions` holds one choice question for each criterion with
instrument system1; a criterion with instrument script is decided by script.py, not by System 1.

This step makes no model call. Python 3 standard library only.
"""
import argparse
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
DEFAULT_CRITERIA = os.path.join(HERE, "criteria.json")
# The model of s1/jev.py at cc64ef0 (DEFAULT_MODEL). Read here, never called.
S1_MODEL = "jev-1.14.0"
CONTEXT = ("You are viewing the transcript of one finished session between a human and an agent. "
           "The session has ended; judge it as a whole.")
# Cut of one tool result in the state; the transcript keeps the full text.
RESULT_CHARS = 2000


def load_criteria(path=DEFAULT_CRITERIA):
    with open(path, encoding="utf-8") as f:
        return json.load(f)["criteria"]


def read_transcript(path):
    """Return the list of events of a stream-json transcript, in order.

    Each event is {"kind": "human"|"text"|"tool_use"|"tool_result", ...}."""
    events = []
    with open(path, encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                d = json.loads(line)
            except ValueError:
                continue
            t = d.get("type")
            content = (d.get("message") or {}).get("content")
            if t == "user":
                if isinstance(content, str):
                    events.append({"kind": "human", "text": content})
                    continue
                for b in content or []:
                    if b.get("type") == "tool_result":
                        c = b.get("content")
                        if isinstance(c, list):
                            c = "\n".join(x.get("text", "") for x in c if isinstance(x, dict))
                        events.append({"kind": "tool_result", "id": b.get("tool_use_id"),
                                       "is_error": bool(b.get("is_error")), "text": c or ""})
                    elif b.get("type") == "text":
                        events.append({"kind": "human", "text": b.get("text", "")})
            elif t == "assistant":
                for b in content or []:
                    if b.get("type") == "text":
                        events.append({"kind": "text", "text": b.get("text", "")})
                    elif b.get("type") == "tool_use":
                        events.append({"kind": "tool_use", "id": b.get("id"), "name": b.get("name"),
                                       "input": b.get("input") or {}})
    return events


def render(events):
    out = []
    for e in events:
        k = e["kind"]
        if k == "text":
            out.append("agent: " + e["text"])
        elif k == "tool_use":
            out.append(f"tool call {e['name']}: " + json.dumps(e["input"], ensure_ascii=False))
        elif k == "tool_result":
            tag = "tool result (error)" if e["is_error"] else "tool result"
            out.append(f"{tag}: " + e["text"][:RESULT_CHARS])
    return "\n".join(out)


def state_of(path, request=None):
    events = read_transcript(path)
    human = [e["text"] for e in events if e["kind"] == "human"]
    if request:
        human = [request] + human
    texts = [e["text"] for e in events if e["kind"] == "text"]
    return {"context": CONTEXT,
            "request": "\n\n".join(human),
            "transcript": render([e for e in events if e["kind"] != "human"]),
            "delivery": texts[-1] if texts else ""}


def question_set(criteria):
    return {c["id"]: {"type": c["question"]["type"],
                      "instructions": c["question"]["instructions"],
                      "criteria": dict(c["question"]["criteria"])}
            for c in criteria if c.get("instrument") == "system1"}


def build_request(transcript, criteria, request=None, model=S1_MODEL):
    """The body of one System 1 request: every system1 question of one transcript."""
    return {"model": model, "state": state_of(transcript, request), "questions": question_set(criteria)}


def main(argv):
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("transcript")
    ap.add_argument("--criteria", default=DEFAULT_CRITERIA)
    ap.add_argument("--request", default=None)
    a = ap.parse_args(argv)
    json.dump(build_request(a.transcript, load_criteria(a.criteria), a.request), sys.stdout,
              indent=1, ensure_ascii=False)
    print()
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))

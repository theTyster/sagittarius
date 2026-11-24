#!/usr/bin/env python3
"""The stop event of System 1 (scientific-method-overhaul c30, q15). Event: Stop. Python 3
standard library only. Entry: `python3 hook.py --event stop` (or this file).

Before a delivery reaches the human, it compares what the last message of the agent treats as
success with the predictions of the active hypothesis (trees.read_drift). A prediction that is
dropped or changed with no message of the human that changed it gives one hint that names it.
A change that the human made is a revision: no hint, and it is proposed for the record through
`orbit propose` (a note on the claim).

It is inert until the drift tree ships: with d_success, d_kept and d_revised not all in the
question set (s1/questions.json), it reads nothing, calls nothing, logs nothing and prints nothing
(c35).

How the hint reaches the agent (the choice): `hookSpecificOutput.additionalContext` of the Stop
event. Claude Code gives it to the agent as a reminder at the end of the turn, and the agent goes
on once; it is not shown as an error. S1_STOP_MODE=block prints {"decision": "block", "reason"}
instead, for a Claude Code that does not read additionalContext at a stop. It never loops: with
stop_hook_active true in the input it prints nothing, and it gives at most one hint for each
prompt of a session (the session file keeps the prompt id, or the hash of the delivery).

Fails open: any error, no record, no predictions, no answer, or a timeout prints nothing and
exits 0. The limit is S1_TIMEOUT (default 4 s), as for a prompt.
"""
import hashlib
import json
import os
import sys
import threading

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import jev  # noqa: E402
import record  # noqa: E402
import trees  # noqa: E402


def _questions(env):
    import hook
    with open(hook.question_path(env, hook.workbench(env)), encoding="utf-8") as f:
        qs = json.load(f)
    return qs if isinstance(qs, dict) else {}


def run(raw, env, transport=None):
    """The stdout of the stop event for stdin text raw: a JSON hook result, or "". Never raises."""
    try:
        if env.get("S1_OFF", "").strip() not in ("", "0"):
            return ""
        payload = json.loads(raw)
        if not isinstance(payload, dict) or payload.get("stop_hook_active") is True or payload.get("agent_id"):
            return ""
        questions = _questions(env)
        if not trees.promoted(questions, trees.STOP_IDS):
            return ""  # c35: the drift tree did not ship: nothing runs
        import hook
        log_path = env.get(jev.LOG_ENV) or jev.DEFAULT_LOG
        key = env.get(jev.KEY_ENV) or ""
        sid = payload.get("session_id")
        tpath = payload.get("transcript_path") if isinstance(payload.get("transcript_path"), str) else ""
        extra = {"session_id": sid, "transcript": os.path.basename(tpath) or None, "event": "stop"}
        if not key:
            return ""
        timeout = hook._timeout(env)
        box = {}

        def call():
            rec = record.fetch(env, payload)
            recent = hook.recent_messages(tpath, hook._count(env) + 1)
            delivery = payload.get("last_assistant_message")
            if not isinstance(delivery, str) or not delivery.strip():
                delivery = next((m["text"] for m in reversed(recent) if m["role"] == "agent"), "")
            if recent and recent[-1]["role"] == "agent":
                recent = recent[:-1]
            if not delivery.strip() or not rec.get("record") or not trees.predictions(rec["record"]):
                hook._skip(log_path, key, "stop: no record with a prediction, or no delivery", extra,
                           record=rec.get("source"))
                return
            mark = payload.get("prompt_id") if isinstance(payload.get("prompt_id"), str) else \
                hashlib.sha256(delivery.encode("utf-8")).hexdigest()[:16]
            sess = record.load_session(env, sid)
            if sess.get("stop") == mark:
                return  # one hint for each delivery
            state = {"context": hook.STATE_CONTEXT, "delivery": delivery, "recent": recent[-hook._count(env):]}
            asked = trees.ask_drift(questions, rec["record"])
            lx = dict(extra)
            lx.update(record.attach(state, rec, asked, False, (hook.CONTEXT_CHARS, hook.LONG_CONTEXT_CHARS)))
            if "record" not in state:
                return
            answers = jev.judge(state, asked, timeout=max(timeout - rec["took"], 0.1), key=key,
                                log_path=log_path, transport=transport, log_extra=lx)
            out = trees.read_drift(answers, state["record"])
            done = 0
            for r in out["revisions"][:3]:  # a revision by the human: proposed for the record
                done += record.propose(rec, env, f"note({r['id']}, {record.quote('System 1: the human revised this prediction in the conversation; the delivery no longer holds it as written.')})",
                                       note="revision by the human (System 1, the stop event)")
            if out["hint"]:
                sess = record.load_session(env, sid)
                sess["stop"] = mark
                record.save_session(env, sid, sess)
            jev._log(log_path, key, dict(lx, time=jev._now(), stop={
                "drifts": [d["id"] for d in out["drifts"]], "revisions": [r["id"] for r in out["revisions"]],
                "proposed": done, "hint": out["hint"]}))
            box["hint"] = out["hint"]

        t = threading.Thread(target=call, daemon=True)
        t.start()
        t.join(timeout + 0.5)
        hint = box.get("hint")
        if t.is_alive() or not hint:
            return ""
        if env.get("S1_STOP_MODE", "").strip().lower() == "block":
            return json.dumps({"decision": "block", "reason": hint})
        return json.dumps({"hookSpecificOutput": {"hookEventName": "Stop", "additionalContext": hint}})
    except Exception:
        return ""


def main(transport=None):
    try:
        out = run(sys.stdin.read(), dict(os.environ), transport=transport)
        if out:
            sys.stdout.write(out + "\n")
            sys.stdout.flush()
    except Exception:
        pass
    return 0


if __name__ == "__main__":
    sys.exit(main())

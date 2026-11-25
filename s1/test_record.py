"""Tests for the record in the state of System 1 (scientific-method-overhaul c29, c34, c36, c46).
No network: a fake transport, and a stub executable in place of `orbit` ($S1_ORBIT).

    python3 -m unittest s1.test_record -v
"""
import json
import os
import stat
import sys
import time
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import test_hook as th  # noqa: E402
from test_hook import Fake, RECORDED, TICKET_LINE  # noqa: E402

RECORD = {
    "ticket": "replayed-imports",
    "goal": {"id": "g1", "author": "human", "text": "A replayed import leaves the member records as one clean run would."},
    "hypotheses": [
        {"id": "hy1", "author": "human", "state": "adopted", "text": "Skipping each record ID that was seen before makes a replay safe.",
         "defeating_case": "A correction arrives under a seen ID and is discarded.",
         "predictions": [{"id": "c1", "text": "After a replay the member count equals the count of one clean run."},
                         {"id": "c2", "text": "A replay finishes in the time of one run."}]},
        {"id": "hy2", "author": "agent", "state": "proposed", "text": "Skip only a record that equals the stored one.",
         "defeating_case": None, "predictions": []}],
    "questions": [{"id": "q4", "text": "Does a second notification count as the same result?"}],
    "goal_sentences": [{"id": "pg1", "text": "Agents deliver results that the human wants."}],
    "sent": ["goal:g1"],
    "ledger_note": "MUST NOT LEAVE THE MACHINE",
}
SENT = ["goal:g1", "hypothesis:hy1", "claim:c1", "claim:c2", "hypothesis:hy2", "question:q4", "goal_sentence:pg1"]


class Base(th.Base):
    def stub(self, body):
        """An executable that stands for orbit. body: Python source; argv is sys.argv[1:]."""
        p = os.path.join(self.dir, "orbit-stub")
        with open(p, "w") as f:
            f.write(f"#!{sys.executable}\nimport json, sys, time\nargv = sys.argv[1:]\n"
                    f"open({os.path.join(self.dir, 'orbit-calls')!r}, 'a').write(json.dumps(argv) + '\\n')\n" + body)
        os.chmod(p, os.stat(p).st_mode | stat.S_IXUSR)
        return p

    def record_stub(self, record=RECORD):
        return self.stub(f"if argv[0] == 's1-record':\n    print(json.dumps({record!r}))\n".replace("None", "None"))

    def calls(self):
        try:
            with open(os.path.join(self.dir, "orbit-calls")) as f:
                return [json.loads(x) for x in f.read().splitlines()]
        except OSError:
            return []

    def hub(self, modules=None):
        with open(os.path.join(self.dir, ".hub-template.json"), "w") as f:
            json.dump({"modules": modules or {}}, f)

    def call_line(self):
        return [r for r in self.log_lines() if r.get("answers")][0]


class C29Record(Base):
    """c29, k29: the state holds the goal, each current hypothesis with its author and its
    predictions, and the open questions."""

    def test_the_state_holds_the_record_beside_the_conversation(self):
        fake = Fake()
        env = dict(self.env, S1_ORBIT=self.record_stub(), HUB_SESSION="build")
        self.assertEqual(self.context(self.run_hook(fake, env=env)), TICKET_LINE)
        st = fake.state()
        self.assertEqual(list(st), ["context", "message", "recent", "record"])
        r = st["record"]
        self.assertEqual(r["goal"], RECORD["goal"])
        self.assertEqual([(h["id"], h["author"]) for h in r["hypotheses"]], [("hy1", "human"), ("hy2", "agent")])
        self.assertEqual([c["id"] for c in r["hypotheses"][0]["predictions"]], ["c1", "c2"])
        self.assertEqual(r["questions"], RECORD["questions"])
        argv = self.calls()[0]
        self.assertEqual(argv[0], "s1-record")
        self.assertIn("--json", argv)
        self.assertEqual(argv[argv.index("--session") + 1], "build")

    def test_in_a_hub_the_command_gets_the_hub(self):
        self.hub()
        self.run_hook(Fake(), env=dict(self.env, S1_ORBIT=self.record_stub()))
        argv = self.calls()[0]
        self.assertEqual(argv[argv.index("--hub") + 1], self.dir)

    def test_the_hubs_own_orbit_is_the_default(self):
        self.hub()
        d = os.path.join(self.dir, ".claude", "orbit-kb", "bin")
        os.makedirs(d)
        os.rename(self.record_stub(), os.path.join(d, "orbit"))
        fake = Fake()
        self.run_hook(fake)
        self.assertEqual(fake.state()["record"]["ticket"], "replayed-imports")

    def test_no_ticket_gives_what_the_session_stated(self):
        import record
        env = dict(self.env, S1_ORBIT=self.record_stub(dict(RECORD, ticket=None, goal=None, hypotheses=[], questions=[],
                                                              goal_sentences=[])),
                   S1_SESSION_DIR=os.path.join(self.dir, "sess"))
        record.state_goal(env, "sess-fixture-1", "The export keeps its rows sorted.")
        record.state_hypothesis(env, "sess-fixture-1", "Sorting in the query is enough.")
        fake = Fake()
        self.assertEqual(self.context(self.run_hook(fake, env=env)), TICKET_LINE)
        r = fake.state()["record"]
        self.assertIsNone(r["ticket"])
        self.assertEqual(r["goal"]["text"], "The export keeps its rows sorted.")
        self.assertEqual([h["text"] for h in r["hypotheses"]], ["Sorting in the query is enough."])
        self.assertEqual(self.call_line()["record"], "session")

    def test_no_record_at_all_sends_the_state_of_today_and_the_line_says_so(self):
        empty = dict(RECORD, ticket=None, goal=None, hypotheses=[], questions=[], goal_sentences=[])
        env = dict(self.env, S1_ORBIT=self.record_stub(empty), S1_SESSION_DIR=os.path.join(self.dir, "sess"))
        fake = Fake()
        self.assertEqual(self.context(self.run_hook(fake, env=env)), TICKET_LINE + "; no record (no ticket)")
        self.assertEqual(list(fake.state()), ["context", "message", "recent"])
        line = self.call_line()
        self.assertEqual((line["record"], line["record_why"]), ("none", "no ticket"))
        self.assertNotIn("record_sent", line)

    def test_outside_a_hub_with_no_command_the_line_is_the_line_of_today(self):
        fake = Fake()
        self.assertEqual(self.context(self.run_hook(fake)), TICKET_LINE)
        self.assertEqual(list(fake.state()), ["context", "message", "recent"])
        self.assertEqual(self.call_line()["record"], "none")

    def test_a_record_too_large_for_the_context_is_cut_not_the_messages(self):
        big = json.loads(json.dumps(RECORD))
        big["goal_sentences"] = [{"id": f"pg{i}", "text": "x" * 3000} for i in range(40)]
        fake = Fake()
        self.run_hook(fake, env=dict(self.env, S1_ORBIT=self.record_stub(big)))
        self.assertEqual(fake.state()["record"]["goal_sentences"], [])
        self.assertEqual(fake.state()["record"]["goal"], RECORD["goal"])
        self.assertNotIn(th.LONG_HEADER, fake.calls[0]["headers"])
        self.assertEqual(self.call_line()["record_cut"], ["goal_sentences"])


class C46OnlyTheRecord(Base):
    """c46, k46: only the fields of s1-record leave the machine; the log names them; the switch."""

    def test_a_field_that_the_contract_does_not_name_is_not_sent(self):
        fake = Fake()
        self.run_hook(fake, env=dict(self.env, S1_ORBIT=self.record_stub()))
        self.assertNotIn(b"MUST NOT LEAVE", fake.calls[0]["body"])
        self.assertEqual(sorted(fake.state()["record"]), ["goal", "goal_sentences", "hypotheses", "questions", "ticket"])

    def test_the_log_line_names_the_records_that_were_sent(self):
        self.run_hook(Fake(), env=dict(self.env, S1_ORBIT=self.record_stub()))
        line = self.call_line()
        self.assertEqual(line["record_sent"], SENT)
        self.assertEqual((line["record"], line["record_ticket"]), ("ticket", "replayed-imports"))

    def body_of(self, env):
        fake = Fake()
        line = self.context(self.run_hook(fake, env=env))
        return fake.calls[0]["body"], line

    def test_switched_off_the_request_is_the_request_of_0_7_2_byte_for_byte(self):
        base, base_line = self.body_of(self.env)  # no orbit, no hub: the path of 0.7.2
        import hook
        qs = json.load(open(self.env["S1_QUESTIONS"]))
        st = {"context": hook.STATE_CONTEXT, "message": "Looks good. Ask Zorblax about it.",
              "recent": [{"role": "you", "text": "Rename the tab."},
                         {"role": "agent", "text": "I renamed the tab to Reports for Acme Widgets."}]}
        want = json.dumps({"model": th.jev.DEFAULT_MODEL, "state": st, "questions": qs}).encode()
        self.assertEqual(base, want)  # the body as jev.py of 0.7.2 builds it from the fields of 0.7.2
        off, off_line = self.body_of(dict(self.env, S1_ORBIT=self.record_stub(), S1_RECORD="0"))
        self.assertEqual(off, want)
        self.assertEqual(off_line, base_line)
        self.assertEqual(self.calls(), [])  # off: the command is not run at all
        self.hub({"s1_record": False})
        hub_off, hub_line = self.body_of(dict(self.env, S1_ORBIT=self.record_stub()))
        self.assertEqual(hub_off, want)
        self.assertEqual(hub_line, base_line)
        self.assertEqual(self.calls(), [])
        self.assertEqual(self.log_lines()[-1]["record"], "off")


class C36FailOpen(Base):
    """c36, k36: a slow, failing or missing orbit never delays the hook beyond its budget."""

    def assertOpen(self, env, why, most=1.5):
        fake = Fake()
        t0 = time.monotonic()
        out = self.context(self.run_hook(fake, env=env))
        took = time.monotonic() - t0
        self.assertEqual(out, TICKET_LINE + f"; no record ({why})")
        self.assertEqual(list(fake.state()), ["context", "message", "recent"])
        self.assertLess(took, most)
        return fake

    def test_a_slow_command_is_cut_at_its_budget(self):
        env = dict(self.env, S1_ORBIT=self.stub("time.sleep(5)\n"))
        fake = self.assertOpen(env, "orbit timeout")  # default budget 0.5 s
        self.assertLess(fake.calls[0]["timeout"], 4.0)  # the model call gets what is left of the 4 s
        self.assertGreater(fake.calls[0]["timeout"], 3.0)
        self.assertAlmostEqual(self.call_line()["record_latency"], 0.5, delta=0.3)

    def test_the_budget_is_a_setting(self):
        self.assertOpen(dict(self.env, S1_ORBIT=self.stub("time.sleep(5)\n"), S1_ORBIT_TIMEOUT="0.1"), "orbit timeout", 1.0)

    def test_a_failing_command(self):
        self.assertOpen(dict(self.env, S1_ORBIT=self.stub("sys.exit(3)\n")), "orbit failed")

    def test_a_command_that_prints_no_json(self):
        self.assertOpen(dict(self.env, S1_ORBIT=self.stub("print('usage: orbit ...')\n")), "bad record")

    def test_a_missing_command(self):
        self.assertOpen(dict(self.env, S1_ORBIT=os.path.join(self.dir, "no-such-orbit")), "orbit missing")

    def test_the_default_limit_is_still_4_s_and_the_budget_is_far_under_it(self):
        import hook, record
        self.assertEqual(hook.DEFAULT_TIMEOUT, 4.0)
        self.assertLessEqual(record.ORBIT_TIMEOUT, 0.5)

    def test_the_script_exits_0_with_a_hanging_command(self):
        env = dict(self.env, S1_ORBIT=self.stub("time.sleep(30)\n"))
        p, took = th.subprocess_hook(self.payload(), env, fake_spec={"payload": RECORDED["ticket_example"]})
        self.assertEqual(p.returncode, 0)
        self.assertIn("no record (orbit timeout)", p.stdout)
        self.assertLess(took, 3)


TAGGED = {
    "task-notification": "<task-notification>\n<task-id>a1</task-id>\n<status>completed</status>\nThe subagent ended.</task-notification>",
    "cross-session-message": "<cross-session-message from=\"review\">The check k3 fails on your branch.</cross-session-message>",
    "agent-message": "<agent-message>Done with part 2.</agent-message>",
}


class C34NotFromTheHuman(Base):
    """c34 (first half), k34, q25: a prompt that starts with a tag is marked as not from the human
    by code; it gets no effort and no change-of-plan signal; a divergence is still shown."""

    def test_the_three_tags_and_nothing_else(self):
        import record
        for tag, text in TAGGED.items():
            self.assertEqual(record.source_of(text), tag)
            self.assertEqual(record.source_of("  \n" + text), tag)
        for text in ("Looks good.", "<command-name>/clear</command-name>", "<bash-input>ls</bash-input>",
                     "See <task-notification> below", "<task-notifications>", ""):
            self.assertIsNone(record.source_of(text), text)

    def test_no_effort_and_no_change_of_plan_signal_and_the_divergence_stays(self):
        for tag, text in TAGGED.items():
            fake = Fake(RECORDED["both_likely"])
            human = self.context(self.run_hook(Fake(RECORDED["both_likely"])))
            self.assertIn("change of plan likely", human)
            out = self.context(self.run_hook(fake, raw=self.payload(prompt=text)))
            self.assertTrue(out.startswith(f"System 1: not from the human ({tag}); "), out)
            self.assertIn("divergence likely (0.80)", out)
            self.assertNotIn("change of plan", out)
            self.assertNotIn("effort", out)
        out = self.context(self.run_hook(Fake(), raw=self.payload(prompt=TAGGED["task-notification"])))
        self.assertNotIn("effort", out)  # ticket_example: effort significant (0.91) for a human
        self.assertIn("divergence likely (0.85)", out)

    def test_effort_alone_names_no_formal_tool_for_such_a_message(self):
        resp = json.loads(json.dumps(RECORDED["ticket_example"]))
        resp["answers"]["h_divergence"]["noul"] = 0.5
        self.assertIn("formal tool", self.context(self.run_hook(Fake(resp))))
        out = self.context(self.run_hook(Fake(resp), raw=self.payload(prompt=TAGGED["agent-message"])))
        self.assertNotIn("formal tool", out)

    def test_the_log_names_the_source_and_keeps_the_answers_of_the_model(self):
        self.run_hook(Fake(), raw=self.payload(prompt=TAGGED["task-notification"]))
        line = self.call_line()
        self.assertEqual(line["source"], "task-notification")
        self.assertEqual(line["answers"]["h_effort"]["noul"], 0.91)
        self.run_hook(Fake())
        self.assertNotIn("source", self.log_lines()[-1])

    def test_the_status_line_shows_no_effort_for_such_a_message(self):
        import statusline
        self.run_hook(Fake())
        self.assertIn("eff 0.91", statusline.render("sess-fixture-1", self.log))
        self.run_hook(Fake(), raw=self.payload(prompt=TAGGED["task-notification"]))
        seg = statusline.render("sess-fixture-1", self.log)
        self.assertNotIn("eff", seg)
        self.assertIn("div 0.85", seg)

    def test_a_hook_with_no_view_still_names_the_source(self):
        out = self.context(self.run_hook(Fake(status=500), raw=self.payload(prompt=TAGGED["agent-message"])))
        self.assertEqual(out, "System 1: not from the human (agent-message); no view (no answer)")
        self.assertEqual(self.context(self.run_hook(Fake(status=500))), "System 1: no view (no answer)")

    def test_a_workbench_routing_gets_the_same_rule(self):
        wb = os.path.join(self.dir, "wb")
        os.makedirs(wb)
        with open(os.path.join(wb, "pipeline.py"), "w") as f:
            f.write("def run(state, ask, questions):\n    return ask(questions)\n")
        env = dict(self.env, S1_WORKBENCH=wb)
        out = self.context(self.run_hook(Fake(RECORDED["both_likely"]), raw=self.payload(prompt=TAGGED["agent-message"]), env=env))
        self.assertTrue(out.startswith("System 1: not from the human (agent-message); "))
        self.assertNotIn("change of plan", out)


if __name__ == "__main__":
    unittest.main()

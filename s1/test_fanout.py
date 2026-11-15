"""The fan-out of the System 1 hook (hook.split_parts, fanout_questions, combine, and run with a fake
transport). No network. Run: python3 -m unittest s1.test_fanout -v.
Evidence for the rules: s1/research/2026-11-15-question-eval/README.md."""
import json
import os
import sys
import tempfile
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import hook  # noqa: E402

with open(os.path.join(HERE, "fanout.json"), encoding="utf-8") as _f:
    FAN = json.load(_f)
with open(os.path.join(HERE, "questions.json"), encoding="utf-8") as _f:
    QUESTIONS = json.load(_f)


def answer(q, p=0.05, choice=None):
    if q["type"] == "noul":
        return {"type": "noul", "noul": p}
    c = choice or list(q["criteria"])[-1]
    return {"type": "choice", "choice": c, "confidence": 0.9, "probabilities": {k: (0.9 if k == c else 0.0) for k in q["criteria"]}}


def answers_for(state, over=None, choices=None):
    """Quiet answers for the request that the hook would send for this state, with some set by hand."""
    asked = dict(QUESTIONS)
    asked.update(hook.fanout_questions(FAN, len(state["sentences"])))
    out = {k: answer(q, choice=(choices or {}).get(k)) for k, q in asked.items()}
    for k, p in (over or {}).items():
        out[k] = {"type": "noul", "noul": p}
    return out


def state(msg, recent=()):
    return {"message": msg, "recent": list(recent), "sentences": hook.split_parts(msg)}


AGENT = {"role": "agent", "text": "Delivered: the tab is renamed."}
AGENT_ASKS = {"role": "agent", "text": "Should it be blue or green?"}
noul = lambda a, k: a[k]["noul"]  # noqa: E731


class SplitParts(unittest.TestCase):
    def test_a_short_message_is_one_part_for_each_sentence(self):
        self.assertEqual(hook.split_parts("Looks good. Did you test this?"), ["Looks good.", "Did you test this?"])
        self.assertEqual(hook.split_parts("ok"), ["ok"])

    def test_more_sentences_than_the_limit_are_packed(self):
        msg = " ".join(f"Sentence number {i} says one thing." for i in range(40))
        parts = hook.split_parts(msg)
        self.assertLess(len(parts), 40)
        self.assertTrue(all(0 < len(p) <= hook.PART_CHARS for p in parts))
        self.assertEqual(" ".join(parts), msg)

    def test_a_voiced_message_with_no_sentence_ends_is_read_whole(self):
        msg = " ".join(f"word{i}" for i in range(1200))  # about 8,000 characters, no punctuation
        parts = hook.split_parts(msg)
        self.assertGreater(len(parts), 8)
        self.assertTrue(all(0 < len(p) <= hook.PART_CHARS for p in parts))
        self.assertEqual(" ".join(parts).split(), msg.split())  # no word is lost: the end is read too

    def test_a_very_long_message_keeps_the_number_of_parts_bounded(self):
        msg = " ".join(f"word{i}" for i in range(20000))
        parts = hook.split_parts(msg)
        self.assertLessEqual(len(parts), hook.MAX_PARTS + 1)
        self.assertEqual(" ".join(parts).split(), msg.split())

    def test_never_empty(self):
        self.assertEqual(hook.split_parts(""), [""])


class FanoutQuestions(unittest.TestCase):
    def test_each_part_gets_each_question_with_its_own_path(self):
        q = hook.fanout_questions(FAN, 3)
        self.assertEqual(len(q), 3 * len(FAN["part"]) + len(FAN["whole"]))
        self.assertIn("`sentences[2]`", q["doubts@2"]["instructions"])
        self.assertNotIn("{part}", json.dumps(q))
        self.assertIn("{part}", FAN["part"]["doubts"]["instructions"])  # the file itself is not changed


class Combine(unittest.TestCase):
    def test_no_agent_message_means_no_divergence_and_no_change_of_plan(self):
        st = state("The checkout is broken.")
        a = hook.combine(answers_for(st, {"faults@0": 0.95, "doubts@0": 0.9, "changes@0": 0.9}), st)
        self.assertEqual((noul(a, "h_divergence"), noul(a, "h_change_of_plan")), (0.0, 0.0))

    def test_a_doubt_in_the_second_sentence_is_a_divergence(self):
        st = state("Looks good. Did you test this?", [AGENT])
        a = hook.combine(answers_for(st, {"doubts@1": 0.93}), st)
        self.assertEqual(noul(a, "h_divergence"), 0.93)

    def test_a_fault_does_not_count_in_a_part_that_changes_the_request(self):
        st = state("Make it green instead.", [AGENT])
        raw = answers_for(st, {"faults@0": 0.9, "changes@0": 0.92}, {"react@0": "changes_request"})
        a = hook.combine(raw, st)
        self.assertLessEqual(noul(a, "h_divergence"), 0.3)
        self.assertEqual(noul(a, "h_change_of_plan"), 0.92)
        raw["react@0"] = answer(FAN["part"]["react"], choice="corrects")  # the same fault in a part that corrects
        self.assertEqual(noul(hook.combine(raw, st), "h_divergence"), 0.9)

    def test_a_doubt_is_never_blocked(self):
        st = state("Make it green instead?", [AGENT])
        a = hook.combine(answers_for(st, {"doubts@0": 0.8}, {"react@0": "changes_request"}), st)
        self.assertEqual(noul(a, "h_divergence"), 0.8)

    def test_questions_need_a_question_of_the_agent(self):
        over = {"asks@0": 0.9}
        st = state("What would each option change?", [AGENT])
        self.assertEqual(noul(hook.combine(answers_for(st, over), st), "h_questions"), 0.0)
        st = state("What would each option change?", [AGENT_ASKS])
        self.assertEqual(noul(hook.combine(answers_for(st, over), st), "h_questions"), 0.9)
        st = state("I do not know yet.", [AGENT_ASKS])
        self.assertEqual(noul(hook.combine(answers_for(st, {"undecided@0": 0.85}), st), "h_questions"), 0.85)

    def test_a_long_message_takes_the_whole_message_answer_for_questions(self):
        st = state(" ".join(f"word{i}" for i in range(1200)), [AGENT_ASKS])
        self.assertGreater(len(st["sentences"]), hook.SENTENCE_PARTS)
        a = hook.combine(answers_for(st, {"asks@3": 0.9, "f_open": 0.1}), st)
        self.assertEqual(noul(a, "h_questions"), 0.1)

    def test_effort_a_long_message_that_is_not_pasted(self):
        long = "I want this. " * 100
        st = state(long)
        self.assertEqual(noul(hook.combine(answers_for(st, {"h_effort": 0.4, "f_pasted": 0.04}), st), "h_effort"), 0.96)
        self.assertEqual(noul(hook.combine(answers_for(st, {"h_effort": 0.1, "f_pasted": 0.96}), st), "h_effort"), 0.1)
        st = state("Short one.")
        self.assertEqual(noul(hook.combine(answers_for(st, {"h_effort": 0.2, "f_pasted": 0.0}), st), "h_effort"), 0.2)

    def test_reversal_is_the_highest_part(self):
        st = state("Make it blue. No wait, green.")
        a = hook.combine(answers_for(st, {"reverses@1": 0.88}), st)
        self.assertEqual(noul(a, "h_reversal"), 0.88)

    def test_the_other_answers_are_kept(self):
        st = state("ok", [AGENT])
        raw = answers_for(st)
        a = hook.combine(raw, st)
        for k in ("h_work", "h_language", "h_proof", "react@0"):
            self.assertEqual(a[k], raw[k])


class Run(unittest.TestCase):
    def setUp(self):
        d = tempfile.TemporaryDirectory()
        self.addCleanup(d.cleanup)
        self.log = os.path.join(d.name, "s1.jsonl")
        self.transcript = os.path.join(d.name, "t.jsonl")
        with open(self.transcript, "w") as f:
            f.write(json.dumps({"type": "user", "message": {"role": "user", "content": "Rename the tab."}}) + "\n")
            f.write(json.dumps({"type": "assistant", "message": {"role": "assistant", "id": "m1", "content": [
                {"type": "text", "text": "Delivered: the tab is renamed."}]}}) + "\n")
        self.env = {"TYPESAFE_API_KEY": "k-test", "S1_LOG": self.log}
        self.sent = []

    def transport(self, over=None, bad=None):
        def t(url, headers, body, timeout):
            req = json.loads(body)
            self.sent.append(req)
            ans = {k: answer(q) for k, q in req["questions"].items()}
            for k, p in (over or {}).items():
                if k in ans:
                    ans[k] = {"type": "noul", "noul": p}
            ans.update(bad or {})
            return 200, json.dumps({"model": "jev-test", "answers": ans, "usage": {"input_tokens": 1, "output_tokens": 1}})
        return t

    def line(self, prompt, env=None, **kw):
        payload = json.dumps({"session_id": "s", "transcript_path": self.transcript, "prompt": prompt})
        out = hook.run(payload, dict(self.env, **(env or {})), transport=self.transport(**kw))
        return json.loads(out)["hookSpecificOutput"]["additionalContext"]

    def log_lines(self):
        with open(self.log) as f:
            return [json.loads(x) for x in f.read().splitlines()]

    def test_the_request_holds_the_parts_and_their_questions(self):
        self.line("Looks good. Did you test this?")
        req = self.sent[0]
        self.assertEqual(req["state"]["sentences"], ["Looks good.", "Did you test this?"])
        self.assertEqual(req["state"]["message"], "Looks good. Did you test this?")
        for k in list(QUESTIONS) + ["react@1", "doubts@0", "f_pasted"]:
            self.assertIn(k, req["questions"])

    def test_a_doubt_in_one_sentence_reaches_the_line(self):
        line = self.line("Looks good. Did you test this?", over={"doubts@1": 0.93, "h_divergence": 0.2})
        self.assertIn("divergence likely (0.93)", line)

    def test_the_plain_answer_does_not_reach_the_line_when_the_fan_out_is_on(self):
        line = self.line("Also add a footer.", over={"h_change_of_plan": 0.9})
        self.assertIn("change of plan unlikely", line)

    def test_a_reversal_reaches_the_line(self):
        line = self.line("Make it blue. No wait, green.", over={"reverses@1": 0.9})
        self.assertIn("decision reversed in message (0.90)", line)

    def test_the_combined_answers_are_logged_after_the_call(self):
        self.line("Looks good. Did you test this?", over={"doubts@1": 0.93})
        lines = self.log_lines()
        self.assertEqual(len(lines), 2)
        self.assertEqual(lines[0]["parts"], 2)
        self.assertNotIn("combined", lines[0])
        self.assertTrue(lines[1]["combined"])
        self.assertEqual(lines[1]["answers"]["h_divergence"]["noul"], 0.93)
        self.assertNotIn("k-test", json.dumps(lines))

    def test_off_switch_sends_the_plain_request(self):
        line = self.line("Also add a footer.", env={"S1_FANOUT": "0"}, over={"h_change_of_plan": 0.9})
        self.assertEqual(sorted(self.sent[0]["questions"]), sorted(QUESTIONS))
        self.assertNotIn("sentences", self.sent[0]["state"])
        self.assertIn("change of plan likely (0.90)", line)
        self.assertEqual(len(self.log_lines()), 1)

    def test_a_bad_fan_out_answer_fails_open_to_the_plain_answers(self):
        line = self.line("Also add a footer.", over={"h_change_of_plan": 0.9}, bad={"doubts@0": {"type": "noul", "noul": "high"}})
        self.assertIn("change of plan likely (0.90)", line)
        self.assertTrue(any("fan-out" in str(x.get("skipped", "")) for x in self.log_lines()))

    def test_a_missing_fan_out_file_falls_back_to_the_plain_request(self):
        line = self.line("Also add a footer.", env={"S1_FANOUT_FILE": "/nonexistent/fanout.json"}, over={"h_change_of_plan": 0.9})
        self.assertEqual(sorted(self.sent[0]["questions"]), sorted(QUESTIONS))
        self.assertIn("change of plan likely (0.90)", line)


if __name__ == "__main__":
    unittest.main()

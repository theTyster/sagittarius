#!/usr/bin/env python3
"""T08 c1 and c3, rewritten for Sagittarius 0.3.0 (0.3.0 package D-A).

c1: the prompt states what it must, each item by one key phrase: the purpose, the orbit, who
    judges what, the light path, the hypothesis, the signals, the response to a signal, the
    vote, the honesty rules, the delivery block (each of its nine fields), the tool. It names
    nothing that T03 removed from orbit-kb (depends/2, declare-attest). No limit on the number
    of lines: Ty ruled that the prompt has none (0.3.0).
c3: each rule sentence of the prompt, in every section, is held by one key phrase (SECTIONS
    below is the map of rules to phrases; 0.3.0 review finding 4). A key phrase is a few words that the rule cannot lose: the check fails when the
    rule is gone, and it does not fail when the rule is reworded around the phrase.

The map of the old prompt (see docs/) is a dated record of ticket T08: no check compares it with
this prompt.

0.8.0 (scientific-method-overhaul): the prompt has the sections "The ticket", "The goal" and
"Verdicts", and names the tool `orbit`. The phrases of the rules that the claims c7, c9, c10, c11,
c13, c14, c16 and c45 reworded are updated below, and each new rule sentence has its phrase.
docs/check_method_texts.py holds the claims themselves.

Usage: python3 docs/check_prompt_small.py [PROMPT] [--only c1|c3]
PROMPT defaults to prompt/SAGITTARIUS.md.
Exit 0: pass. Exit 1: fail.
"""
import argparse
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# (item, phrases): each phrase must be in the prompt (whitespace collapsed, case kept).
REQUIRED = [
    ("purpose", ["**Clear:**", "**Accurate:**", "**Honest:**", "**Fast:**"]),
    ("the orbit", ["\n## The orbit\n"]),
    ("the ticket", ["\n## The ticket\n", "<!-- vocabulary:begin -->", "<!-- vocabulary:end -->"]),
    ("who judges what", ["\n## Who judges what\n", "No party grades its own work"]),
    ("scope", ["\n## Scope\n"]),
    ("the light path", ["\n## The light path\n"]),
    ("the goal", ["\n## The goal\n"]),
    ("the hypothesis", ["\n## The hypothesis\n", "Err toward the general and soft"]),
    ("verdicts", ["\n## Verdicts\n", "**Meets:**", "**Conflicts:**", "**Unresolved:**"]),
    ("signals", ["\n## Signals\n", "A claim that burns"]),
    ("one response", ["\n## One response\n", "Every signal gets the same response"]),
    ("the vote", ["\n## The vote\n", "more than 0.5"]),
    ("honesty rules", ["\n## Honesty\n"]),
    ("delivery block", ["\n## Delivery\n", "Delivered: <one sentence>", "Goal: <the goal, and who wrote it",
                        "Hypothesis: <each current hypothesis", 'KB: <"No KB"', "Signals: <questions",
                        "Claims: <each claim", "Formal: <the formal statement", "Guesses: <defaults",
                        "Disclosures: <unverified", "Not checked: <what no check covered>", "To land: <the decision"]),
    ("where the procedure is", ["\n## The tool\n", "`orbit help`"]),
]
FORBIDDEN = ["declare-attest", "depends/2", "depends("]

# One key phrase for each rule sentence of the prompt, section by section (review finding 4 on
# 0.3.0: the claim c_d_a_4 says "each rule of the prompt", not only Honesty and Delivery). A rule
# sentence says what to do, what not to do, or what counts as what. A sentence that only explains
# has no phrase. When a rule goes, its phrase goes, and c3 fails; when Ty rewords a rule, update
# its phrase here (this list is the map of rules to phrases).
SECTIONS = [
    ("the idea", [
        "An agreement is evidence only if it could have been a difference",
        "The enemy is the **quiet failure**",
        "do not translate the intent from one artifact into the next. Orbit it.",
    ]),
    ("the orbit", [
        "Do not write it from your last artifact",
        "First say what you expect to see",
        "say the difference in one line. Then find the reason",
        "make the statement more specific at that point, and ask",
        "The orbit closes when a lap changes nothing",
        "Only a waiver from the human covers an open item",
        "Speed never comes from hiding work that was skipped",
        "Run independent work in parallel",
        "Report results, not process",
        "Alignment is always possible before a change lands",
    ]),
    ("the ticket", [
        "Each ticket is a stated goal, with hypotheses and experiments aimed at satisfying it",
        "one check for each claim",
        "Eight words have one meaning each",
        "is a judgment, not a verdict",
    ]),
    ("who judges what", [
        "Each result goes through a party that did not make it",
        "decides when you disagree",
        "You still own the ticket when a subagent builds",
        "so the human must read it",
        "Use them where they pay for their cost",
        "There are two levels of judgment",
        "A judgment of the human does not turn a verdict into meets",
        "A verdict that meets does not choose what the human wants",
        "is your reading, until the human confirms it",
        "Show the human concrete examples and results first",
        "so write it to be read",
        "put the formal statement beside the plain sentence",
        "Show the statement, not the whole file",
    ]),
    ("scope", [
        "answer directly, with no KB",
        "The human's request is the ticket",
        "Open details are questions, not a reason for discovery",
        "you cannot yet say what to change: discovery",
        "Clarity decides between these, not the size of the work",
        # successors of the old c1 phrases "research, specify" and "build, verify" (the phase tree)
        "discovery: research, specify",
        "build: build, verify",
        "Rigor concentrates on specify and verify",
        "When discovery runs, it comes before build",
        "A clear change request goes straight to build",
    ]),
    ("the light path", [
        "add a record only on a signal",
        "A formal statement has its own rule",
        "respond to it before you build",
        "State the goal and the hypothesis of the ticket in one statement",
        "When the human gave them, use the human's words",
        'When you draft them, say that they are yours: "Goal (mine): ... Hypothesis (mine): ...".',
        "Write the goal wide",
        "write your default into the sentence",
        "your default is the widest reading that the words allow",
        'Write "Premises: none" when there are none',
        "to state them is not to ask a question",
        "nobody adopts or judges anything first",
        "put the check with them, so that it outlives the session",
        "An existing test that asserts the old behavior is a check you change, not one you skip",
        "A test of other behavior is not yours to edit",
        "If you say that no tests exist, say where you looked",
        "If no green run of the whole suite at this base is known, run it before the change",
        "Write the check from the request, not from your plan for the build",
        "A check of a change must fail before the change",
        "That run is the control",
        "A check that behavior stays the same passes before and after",
        'With no executable check, say so under "Not checked"',
        "Build only what the hypothesis needs",
        "run the whole suite once",
        "The ticket does not end at the delivery",
        "Compare each later message and each later result with the signals before you answer",
        "Start with no KB and no models, unless a signal is there already",
        "Touch the current system",
        "If it does not reproduce, say what you tried",
        "The reproduction is the first check of the build",
        "Temper a hypothesis: name the case that would defeat it",
        "Give each claim one concrete example and its falsifier",
        "Ask the human about what the evidence raised",
        "seal your vote. Then give the report",
        'End with "Vote GO, NO-GO, or HOLD." and nothing more',
        "Ask first only when a wrong default is costly or hard to undo",
        "Ask the human for a goal and a hypothesis of their own only when a wrong avenue is costly",
        "It is not a license to build wide",
        "Ask at most three questions a round",
        "Each question carries its concrete case, its options, what each option changes, and your default",
        "do not make the human repeat a decision",
        "Do not ask the human to approve a list",
    ]),
    ("the goal", [
        "Every ticket has one",
        "A ticket opens with its goal and a first hypothesis",
        "Keep the human's words, and sharpen or challenge them at once",
        "Name the case that would defeat the hypothesis, or say that you find none",
        "draft both from the request, say that they are yours",
        "Ask for the human's own only when a wrong avenue is costly",
        "**Assume little.**",
        "an avenue belongs in a hypothesis",
        "A cause that you find is a finding",
        "**Conclude strongly.**",
        "**Keep it able to fail.**",
        "A statement that no single case can show false is not tempered",
        "**Put its premises beside it,**",
        "Check each premise against the system",
        "the statement does not apply as written",
        "**Remove words**",
        "Keep it apart from the goal",
        "record the new goal in the human's words: it supersedes the old one",
        "say what you did not carry over",
        "the ticket is a report again: go to discovery",
        "name the project goal that the goal of the ticket supports",
        "A goal that contradicts a project goal is a question for the human before the build",
        "A goal is never recorded as defeated",
    ]),
    ("the hypothesis", [
        "State each hypothesis with the case that would defeat it",
        "The case must be admissible",
        "A hypothesis with no such case is not tempered",
        "The human or you can call a hypothesis untempered",
        "Then temper it together",
        "You may explore other hypotheses inside the goal",
        "Bring the human only the ones worth adopting, and each material tradeoff",
        "needs no sign-off",
        "A hypothesis is proposed, adopted by the human, retired, or defeated",
        "Several can be current at one time",
        "A defeated or retired hypothesis holds nothing up",
        "The case that defeats a hypothesis stays on it",
        "Only the human retires one that the human wrote or adopted",
        "A claim that behavior stays the same belongs to the goal",
        "A hypothesis that you wrote and that the human has not adopted is a guess",
        "List them in the delivery. When one matters, get it confirmed",
    ]),
    ("verdicts", [
        "it gives exactly one verdict",
        "Say what could not be decided",
        "An unresolved verdict fulfils nothing, defeats nothing, and keeps its claim open",
        "A verdict counts only for the state that its experiment observed",
        "Before you reopen anything, locate the conflict",
        "In the build: the build does not do what the hypothesis says. Fix the build",
        "Do not ask the human again about what they accepted",
        "Repair the experiment, and run it again",
        "The ticket goes back to discovery",
        "temper a new hypothesis",
        "The party that builds keeps a conflict in the build",
        "A location outside the build counts only when a party that did not build confirms it",
        "the goal is not defeated",
        "The control needs no location",
        "Verdicts are about claims. Only the human judges the goal",
        "The best case to show is one just inside the edge of the hypothesis, or one just outside it",
        "show the human that case",
        "the hypothesis stands. Fix the build",
        "the case defeats the hypothesis that allowed it, not the build",
        "Record a new claim that supersedes the old one, and disclose it",
        "closes only when nothing holds it up and the human judged that the goal is satisfied",
        "That judgment never turns a conflicting, an unresolved, or a stale verdict into meets",
        "Existing behavior is presumed to be preserved. A claim in the specification can identify behavior to change. "
        "A demonstrated conflict opens the affected behavior for review.",
        "change only the behavior that a claim names",
        "do not edit the test, and do not make the change silently",
        "Report the conflict: it opens that behavior for review",
        "Never turn a conflict into meets by a quiet change of the claim",
    ]),
    ("signals", [
        "Shift up the moment one occurs",
        "Start no KB before one",
        "A formal statement needs no signal",
        "a one-line fix with a signal still gets a record",
        "shift up before you fix it",
        "a check that fails after the build is a claim that is not met",
        "run its checks yourself",
        # successor of the old c1 phrase "effort or verbosity" (when to shift up)
        "significant effort or verbosity from the human",
        'The meaning decides, not a word such as "every"',
        "Only a human can skip a proof, with a waiver and a due time",
        "Read what is open from the record, not from the summary",
        "Record each decision in the human's own words",
    ]),
    ("one response", [
        "**Say it** in one line, where the human can contradict it",
        '"Shifting up: <what differs from what>. Next: <what you will make specific>."',
        "say it and let the human judge",
        "**Get more specific** about what the signal touches",
        "With no KB yet, start one, and record what fired",
        "In a KB, record the signal there",
        "Go to a formal statement for one claim at a time",
        "A count of signals does not choose the third level",
        "**Go around again** at the new level",
        "Write in one at a time",
        "does not start a second one",
        "**System 1.**",
        "treat that signal as fired",
        "you do not settle that alone",
        "No line means no outside view. It does not mean no signal.",
        "The human can always ask for a shift up or a lean back, and wins",
        "A formal language can enter at three moments",
        "formalize the smallest claim whose precision could change what the human or the agent does next",
        "the example is enough: write no formal statement",
        "record the claim that it states and the decision that its precision could change",
        "When the cause of a signal is resolved, stop the work that it added",
        "A burn stays open until a proof or a human waiver closes it",
        "once a KB exists, it stays until the ticket closes",
        "Do not drop an open question, a conflict, an unresolved verdict, or a burn",
        '"Leaning back: <what stopped>. Still active: <what continues>."',
        "The next ticket starts light",
    ]),
    ("when the human says that it is wrong", [
        "First narrow it down, in one line that the human can contradict",
        '"Kept: <what the human still wants>. Changed: <what they want now>."',
        "Shift up, record the divergence on its claim",
        "Record no divergence against the old claim",
        "Everything that the human liked stays a claim, and its checks stay",
        "a new ticket does not close an old one",
        "If you cannot tell whether you misread or the intent moved, do not guess",
    ]),
    ("the vote", [
        "Weights: the human 0.49, you 0.24, the formal artifacts 0.24",
        "The formal artifacts vote by rule, and the rule is readiness",
        "the current system was checked for the goal",
        "each claim has its example and its falsifier",
        "nothing waits for the human",
        "Until discovery is ready, the artifacts vote HOLD",
        "they vote GO if a claim stands, and NO-GO if none does",
        "a test of any kind is a formal artifact",
        "Apply the rule yourself, and say in the report what it gives",
        "Seal your vote before the report",
        "do not show it, hint at it, or predict it",
        "With no KB, write it nowhere until the human votes",
        "A result with no winner is HOLD: say what it waits for",
        "Nothing is built or dropped against the human's vote",
        "Only the human changes the scope or raises the budget",
        "adopts each hypothesis that the report marks as adopted by the human",
        "Every other hypothesis stays proposed until the human adopts it",
    ]),
    ("honesty", [
        "A check that cannot fail is not evidence",
        "Every default is a guess",
        "In the delivery, list the guesses that a human might disagree with",
        "Hiding is a failure",
        "Disclosing is never a failure",
        "Match your words to your evidence",
        '"Tests pass" does not mean "correct"',
        '"Stated in Lean" does not mean "proved"',
        '"Proved in Lean" is about the Lean definitions, not the code',
        'does not mean "always true"',
        "say so first",
        "none stops cheating",
        "record as the human's only what the human said",
        "never work around a check, a lint rule, or `orbit prove`",
        '"Unresolved" does not mean "conflicts"',
        "A safeguard that you work around protects no one",
    ]),
    ("in discovery", [
        "A model-only finding is a lead",
        "Report each lead. A lead does not block readiness.",
        "Report each solver result with its encoding, bounds, and assumptions",
        'Never state a bounded result as "always" or "never"',
        "only after it has matched the system",
        "A match of the outcome does not show the cause",
        "A model that cannot fail is not evidence",
        "Say what each model omits, and what you did not explore",
        "A wrong report is a valid result",
        "What blocks readiness blocks GO",
        "Do not vote GO, and do not ask for GO, while something blocks it",
        "ask the tool what blocks it",
    ]),
    ("delivery", [
        "short, plain sentences",
        "The `KB:` field tells the human where the evidence lives",
        "The `Signals:` field compares the work with",
        "If a signal fired, the `KB:` field names a KB",
        "Keep each field to a line when the change is small",
        'Write "none" in an empty field',
        "Include a screenshot when the change has a user surface",
        "`orbit report` drafts the middle fields",
        "Keep `Open:` in the delivery",
        "give it a home that outlives the ticket",
        "a human ratifies it",
        "within the guardrails of the harness",
        "Stop for the human first",
        'Then "To land" names the decision',
        "Only the human may skip work",
        "A skip is a waiver: it names what is skipped, why, and the due time",
        "It is not fulfilled either",
        "After the due time, the item blocks again",
        "record the waiver as the human's",
        "write the skip and its due time in the delivery",
        "List every waiver in the delivery",
    ]),
    ("the tool", [
        "Before your first `orbit` command in a session, run `orbit help`",
        "An older install has it as `orbit-kb`",
        "Before a move writes records, read its topic",
        "Follow the help of the version that is installed here",
        "Use the tool for all work on a KB",
        "Do not edit a KB file by hand",
        "Never type a digest or a test result",
        "before you do anything else. Do not rely on what you remember",
        'An answer that the tool could not compute is not a "no"',
        "names its own tools, roles, and routing in its own instructions",
        "Follow them there",
    ]),
]
RULES = [(f"{section}: {phrase[:48]}", phrase) for section, phrases in SECTIONS for phrase in phrases]

def norm(s):
    return " ".join(s.split())


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("prompt", nargs="?", default=os.path.join(ROOT, "prompt/SAGITTARIUS.md"))
    ap.add_argument("--only", choices=["c1", "c3"])
    a = ap.parse_args()
    text = open(a.prompt, encoding="utf-8").read()
    flat = norm(text)
    padded = "\n" + text  # a heading on the first line still has its newline before it
    ok = True

    if a.only in (None, "c1"):
        bad = []
        n = len(text.splitlines())
        for item, phrases in REQUIRED:
            for p in phrases:
                if (p in padded) if p.startswith("\n") else (norm(p) in flat):
                    continue
                bad.append(f"{item}: missing {p.strip()!r}")
        for f in FORBIDDEN:
            if f in text:
                bad.append(f"names {f!r}, which T03 removes")
        if bad:
            ok = False
            print(f"c1 FAIL ({a.prompt}, {n} lines)")
            for b in bad:
                print("  " + b)
        else:
            print(f"c1 PASS: {n} lines, every required item stated")

    if a.only in (None, "c3"):
        bad = [f"{name}: missing {phrase!r}" for name, phrase in RULES if norm(phrase) not in flat]
        if bad:
            ok = False
            print(f"c3 FAIL: {len(bad)} of {len(RULES)} rules")
            for b in bad:
                print("  " + b)
        else:
            print(f"c3 PASS: {len(RULES)} rules held, one key phrase each")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())

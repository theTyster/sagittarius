"""Fresh cases, written after the rules of the fan-out were fixed and before any run on them.
Labels are the agent's. Keys: divergence, change, questions, effort, reversal."""
import random, re, sys, os
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "big"))
import gen
R = random.Random(21)
def A(t): return {"role": "agent", "text": t}
def H(t): return {"role": "you", "text": t}
CA = [H("Add a dark mode toggle to the header."), A("Delivered: the header has a dark mode toggle; the choice is saved per user.")]
CB = [H("Write a script that archives invoices older than a year."), A("Delivered: archive_invoices.py moves invoices older than 365 days to cold storage. Dry run on staging moved 4,112 rows.")]
CC = [H("Write a script that archives invoices older than a year."), A("Before I start: should archived invoices stay searchable, or is download-only fine?")]
CE = [H("Build the invoice totals report."), A("Two things I need: 1. Which currency should totals use? 2. Do we round per line or per invoice?")]
CF = [H("Make the payment worker more robust."), A("Plan: I will add the retry queue first, then the alerting.")]
POOL = [s for d in gen.SPEC.values() for s in d] + ["Um, so anyway.", "Let me think about how to say this.", "Okay, where was I.", "Sorry, I am talking this through as I go."]
def long(n, inserts, voiced=False):
    body = []
    while sum(len(x) + 1 for x in body) < n: body.append(R.choice(POOL))
    for frac, s in sorted(inserts, reverse=True): body.insert(int(len(body) * frac), s)
    t = " ".join(body)
    return re.sub(r"[.,;:!?']", "", t.lower()) if voiced else t
N = dict(divergence="no", change="no")
C = [
 (CA, "the toggle resets when I reload", dict(divergence="yes", change="no")),
 (CA, "sweet, merge it", dict(N, questions="no", effort="no", reversal="no")),
 (CA, "hmm did you check it on safari", dict(divergence="yes")),
 (CA, "put the toggle in settings rather than the header", dict(divergence="no", change="yes")),
 (CA, "can it also follow the system theme", N),
 (CB, "4,112? we only have about 900 invoices that old", dict(divergence="yes", change="no")),
 (CB, "run it on prod tonight", dict(N, reversal="no")),
 (CB, "one year is too short, make it three years", dict(divergence="no", change="yes")),
 (CB, "where does cold storage live, s3?", dict(divergence="no", questions="no")),
 (CB, "you were supposed to archive, not move. originals must stay", dict(divergence="yes", change="no")),
 (CC, "download-only is fine", dict(N, questions="no")),
 (CC, "what do support people do today when they need an old one?", dict(questions="yes")),
 (CC, "no idea honestly, ask Priya", dict(questions="yes", divergence="no")),
 (CC, "searchable. and compress them too", dict(questions="no", change="no")),
 (CE, "EUR, and per invoice", dict(questions="no", divergence="no")),
 (CE, "EUR. rounding I need to think about", dict(questions="yes")),
 (CF, "skip alerting for now, queue only", dict(divergence="no", change="yes")),
 (CF, "why the queue first?", dict(divergence="yes")),
 (CF, "fine by me", dict(N, questions="no")),
 (CA, "This is not accessible. No aria label, and contrast fails in dark mode.", dict(divergence="yes", change="no")),
 (CA, "Nice work! Though I wonder if saving per user was needed, did I ask for that?", dict(divergence="yes")),
 (CB, "Good. Also add a restore command. And why 365 and not a calendar year?", dict(divergence="yes", change="no")),
 (CA, "Looks right. Change of heart though: make dark the default.", dict(divergence="no", change="yes")),
 (CC, "Searchable. By the way your last script deleted the staging table, that was not ok.", dict(questions="no", divergence="yes")),
 (CB, "Thanks. The dry run number looks wrong to me, and anyway let's archive after two years instead.", dict(divergence="yes", change="yes")),
 ([], "Set up a nightly job that emails me the failed payments.", dict(N, questions="no", effort="no", reversal="no")),
 ([], "the deploy script is broken again, it hangs on the migrate step", dict(N, questions="no")),
 ([], "Should I use cron or a queue for this? or wait, maybe a queue is overkill. no, let's go with cron.", dict(N, reversal="yes")),
 (CA, "Make the toggle a dropdown. Hmm, no. Keep it a toggle but add an auto option.", dict(divergence="no", reversal="yes")),
 (CB, "Let's delete instead of archive. Actually scratch that, legal would kill me. Keep archiving.", dict(divergence="no", change="no", reversal="yes")),
 (CA, long(1100, [(1.0, "One more thing: I am not convinced the toggle state really survives a logout. Did you try that?")]), dict(divergence="yes", effort="yes")),
 (CB, long(1300, []), dict(N, effort="yes", reversal="no")),
 ([], long(1500, []), dict(N, effort="yes", reversal="no", questions="no")),
 (CB, long(1400, [(.5, "About the archive script I asked for: make the cutoff two years, not one.")]), dict(divergence="no", change="yes", effort="yes")),
 (CC, long(1200, [(.5, "To your question: download-only is fine.")]), dict(questions="no", effort="yes")),
 (CC, long(1200, [(.5, "On your question about search, I honestly do not know yet; what does each option cost us?")]), dict(questions="yes")),
 (CA, long(5000, [(.5, "About the dark mode thing you delivered: it does not work, the toggle resets every time I reload.")], True), dict(divergence="yes", effort="yes")),
 (CA, long(5000, [], True), dict(N, effort="yes", reversal="no")),
 ([], long(5000, [(.2, "So I want the export as a PDF."), (.5, "Actually no, forget the PDF, a spreadsheet is better."), (.8, "Hmm, wait, thinking about it more, go back to PDF, that is my final decision.")], True), dict(N, effort="yes", reversal="yes")),
 (CB, long(4500, [(.2, "So about the archive script, let us make it two years."), (.5, "No wait, three years."), (.8, "Okay, final answer: two years, not the one year I asked for.")], True), dict(change="yes", reversal="yes")),
 (CC, long(4500, [(.5, "To answer your question, download only is fine.")], True), dict(questions="no")),
 (CC, long(4500, [(.5, "On your question, I really do not know yet. What would searchable cost?")], True), dict(questions="yes")),
 (CB, long(4500, [(1.0, "Also that number, four thousand one hundred twelve, seems way too high. Are you sure about it?")], True), dict(divergence="yes")),
 (CE, long(4000, [(.4, "Currency is euros."), (.7, "The rounding thing I have not decided.")], True), dict(questions="yes")),
 ([], gen.log_paste(), dict(effort="no", divergence="no")),
 (CB, "it failed on prod:\n" + gen.log_paste(), dict(divergence="yes", effort="no")),
]
CASES = [dict(id=f"f{i+1}", recent=r, message=m, expect=e) for i, (r, m, e) in enumerate(C)]

import random, gen
from gen import CTX, A, H, DOUBT, APPROVE
R = random.Random(11)
SUBTLE = ["Huh, interesting choice.","I expected a much smaller change.","wait, what?","That's a lot of files for this.","ok... and the tests?","So this just works now? First try?","I'm not convinced.","This feels off to me.","Hm, and you checked the edge cases?","Odd. That is not how I pictured it.","Explain to me why this is correct.","what about the other cases?","Where is the rest?","Is that all?"]
LOOK = ["How do I run this locally?","Which file is that in?","What should I tell the customer about this?","When can this go to production?","Can you summarize what changed for the changelog?","Does the old version need to be removed by hand?","Who else should review this?","What is the next step?","Can you open a pull request for it?","Remind me, what was the ticket number?"]
def cases():
    out = []
    def add(kind, recent, msg, **exp): out.append({"id": f"{kind}{len(out)}", "kind": kind, "recent": recent, "message": msg, "expect": exp})
    for (t, req, done, chg, addr, wrong, q, ans) in CTX:
        D = [H(req), A(f"Delivered: {done}. Tests pass.")]; Q = [H(req), A(f"One question before I start. {q}")]
        for m in R.sample(DOUBT, 4): add("mix_approve_doubt", D, R.choice(["Looks good. ", "Thanks. ", "Nice. "]) + m, divergence="yes", change="no")
        add("mix_dispute_add", D, wrong + " Also, " + addr[0].lower() + addr[1:], divergence="yes", change="no")
        add("mix_dispute_add", D, addr + " And by the way: " + wrong[0].lower() + wrong[1:], divergence="yes", change="no")
        add("mix_dispute_change", D, wrong + " And a change: " + chg[0].lower() + chg[1:], divergence="yes", change="yes")
        for m in R.sample(DOUBT, 2): add("mix_change_doubt", D, chg + " " + m, divergence="yes", change="yes")
        add("mix_answer_open", Q, ans + " But one thing I am unsure about: what happens to the old data?", questions="yes", change="no")
        add("mix_answer_open", Q, ans + " Before you start, though: how long will this take?", questions="yes", change="no")
        add("mix_answer_add", Q, ans + " Also, " + addr[0].lower() + addr[1:], questions="no", change="no", divergence="no")
        add("mix_answer_change", Q, ans + " And one change to what I asked: " + chg[0].lower() + chg[1:], questions="no", change="yes", divergence="no")
        for m in SUBTLE: add("subtle", D, m, divergence="yes", change="no")
        for m in LOOK: add("lookalike", D, m, divergence="no", change="no", questions="no")
    base = gen.cases(); R.shuffle(base)
    keep = [c for c in base if c["kind"] in ("approve","dispute","doubt","change","add","unrelated","answer","open","first","paste","proof")][:1100]
    return out + keep
if __name__ == "__main__":
    import collections; c = cases(); print(len(c), collections.Counter(x["kind"] for x in c).most_common())

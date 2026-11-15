import random, qs
from qs import N, C, M, REACT, REACT2
Q = {k: qs.Q[k] for k in ("sh_divergence","sh_change_of_plan","sh_questions","c_cand","c_cand_ex","q_terse","d_doubts","d_disputes","d_crit","react","react2")}
I = f"What does {M} do, in relation to the agent's last reply?"
PROB = "Reports a problem in the system, or pastes output, without judging the agent's work"
rev = lambda d: dict(reversed(list(d.items())))
def shuf(d, s): ks = list(d); random.Random(s).shuffle(ks); return {k: d[k] for k in ks}
Q.update({
 "react_rev": C(I, rev(REACT)), "react_shuf": C(I, shuf(REACT, 3)), "react_shuf2": C(I, shuf(REACT, 5)),
 "react_plus": C(I, dict(REACT, reports_problem=PROB)),
 "react2_plus": C(I, dict(REACT2, reports_problem={"what": PROB, "examples": ["The checkout throws a 500", "it crashes, see the log below"]})),
 "react2_rev": C(I, rev(REACT2)),
 "react_names": C(I, {k: None for k in REACT}),
 "react_how": C("How does the human respond to the agent's last reply?", REACT),
 "react5": C(I, {"accepts": REACT["accepts"], "faults": "Says the agent's work is wrong or incomplete, or doubts it", "changes_request": REACT["changes_request"], "adds_request": REACT["adds_request"], "other": "Answers a question, asks one, or starts a new topic"}),
 "react_main": C(f"What is the most important thing that {M} does, in relation to the agent's last reply?", REACT),
})
for k, v in REACT.items(): Q["r_" + k] = N(f"Does {M} do this, in relation to the agent's last reply: {v[0].lower() + v[1:]}?")
for k, v in REACT.items(): Q["s_" + k] = N({"question": f"Is this true of {M}?", "statement": "The message " + v[0].lower() + v[1:] + "."})
if __name__ == "__main__":
    import json; print(len(Q), sum(len(json.dumps(v)) for v in Q.values()))

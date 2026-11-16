import json
SH = json.load(open("/home/user/sagittarius/s1/questions.json"))
M = "`message`"
def N(i, t=None, f=None):
    q = {"type": "noul", "instructions": i}
    if t: q["criteria"] = {"true": t, "false": f}
    return q
def S(i, lv): return {"type": "score", "instructions": i, "criteria": lv}
def C(i, o): return {"type": "choice", "instructions": i, "criteria": o}
Q = {k.replace("h_", "sh_"): v for k, v in SH.items()}
REACT = {"accepts": "Accepts or approves what the agent did", "corrects": "Says the agent's work is wrong, incomplete or not what was asked",
 "doubts": "Questions or doubts what the agent did, without saying it is wrong", "changes_request": "Replaces, drops or reverses something the human asked for earlier",
 "adds_request": "Asks for something more, on top of what was asked", "answers": "Answers a question that the agent asked",
 "asks_back": "Leaves the agent's question open, or answers it with a question", "new_topic": "Starts something that has nothing to do with the agent's last reply"}
REACT2 = {k: {"what": v, "examples": e} for (k, v), e in zip(REACT.items(), [["Looks good", "Thanks, merge it"], ["That's not what I asked for", "It still fails"],
 ["Did you test this?", "Why this way?"], ["Actually, make it weekly instead", "Drop the CSV part"], ["Also add it to the other page"], ["The first one", "Yes"],
 ["Not sure yet", "What would each option change?"], ["Unrelated: when is the release?"]])}
Q.update({
 # divergence
 "d_crit": N(f"Does {M} say or suggest that the agent's own result, plan, or reading of the request is wrong, missed something, or is not what was meant?", "Faults the agent's work, or shows doubt, surprise or a pointed question about it", "Reports a problem in the system that the agent did not cause, makes a new request, or changes a preference"),
 "d_unhappy": N(f"Is the human unhappy with what the agent did?"),
 "d_pushback": N(f"Does {M} push back on the agent?"),
 "d_stmt": N("The human thinks that the agent made a mistake, or may have made one."),
 "d_redo": N(f"After reading {M}, does the agent need to recheck or redo its last piece of work?"),
 "d_accepts": N(f"Does {M} accept the agent's last reply as correct?"),
 "d_disputes": N(f"Does {M} say that the agent got something wrong?", "Says a result is wrong, incomplete, or not what was asked for", "Accepts the result, or asks for something else without faulting it"),
 "d_doubts": N(f"Does {M} doubt or question what the agent did?", "Asks whether the agent really did something, why it did it that way, or shows surprise at it", "Asks about the system or the task, not about the agent's own work"),
 "d_misread": N(f"Does {M} say that the agent misunderstood the request?"),
 "d_criticize": N(f"Does {M} criticize, correct or question the agent's work?"),
 "d_complaint": N(f"Is {M} a complaint, a correction, or a sceptical question about the last thing the agent did?", "Complains about, corrects or doubts the agent's last piece of work", "Approves it, changes the request, asks for more, or talks about something else"),
 "d_disagree": N(f"Does {M} show that the human and the agent disagree about what was done or what was wanted?"),
 "d_surprise": N(f"Does {M} show surprise or scepticism at the agent's result?"),
 "d_trust": N(f"Does the human trust the agent's last result as it stands?"),
 "d_score": S("How does the human judge the agent's last piece of work?", ["Accepts it, or moves on to something else", "Questions or doubts it without saying it is wrong", "Says it is wrong, incomplete or not what was asked"]),
 "react": C(f"What does {M} do, in relation to the agent's last reply?", REACT),
 "react2": C(f"What does {M} do, in relation to the agent's last reply?", REACT2),
 # change of plan
 "c_cand": N(f"Does {M} change what the human asked for before?", "Replaces, drops or reverses an earlier request or preference", "Continues the earlier request, corrects a mistake of the agent, or asks for something new"),
 "c_nocrit": N(f"Does {M} replace, drop or reverse something that the human asked for before?"),
 "c_differs": N("Does the human now want something different from what they asked for earlier?"),
 "c_stmt": N("The human has changed their mind about something they asked for."),
 "c_cancel": N(f"Does {M} cancel or replace part of an earlier request of the human?"),
 "c_still_ok": N(f"After {M}, would the earlier request, done exactly as the human first asked, still satisfy the human?"),
 "c_conflict": N(f"Does {M} give an instruction that conflicts with an earlier instruction from the human?"),
 "c_only_adds": N(f"Does {M} only add to what was asked, without changing any of it?"),
 "c_cand_ex": N(f"Does {M} change what the human asked for before?", {"what": "Replaces, drops or reverses an earlier request or preference", "examples": ["Make it weekly instead of daily", "Forget the CSV part"]}, {"what": "Continues the earlier request, corrects a mistake of the agent, or asks for something new", "examples": ["Also add it to the other page", "I asked for weekly and you built daily"]}),
 "c_score": S(f"How does {M} relate to what the human asked for earlier?", ["Keeps the earlier request as it was", "Adds something new on top of the earlier request", "Replaces, drops or reverses part of the earlier request"]),
 # questions not settled
 "q_terse": N(f"Does {M} leave a question of the agent open, or answer it with a new question?", "Says it does not know yet, or asks something back that must be settled first", "Answers what the agent asked, or the agent asked nothing"),
 "q_undecided": N(f"Does {M} say that the human does not know or has not decided something yet?"),
 "q_asks_back": N(f"Does {M} ask the agent a question that must be answered before the work can go on?"),
 "q_lacks": N(f"After {M}, does the agent still lack an answer that it asked for?"),
 "q_fully": N(f"Does {M} fully answer what the agent asked?"),
 "q_can_start": N(f"Can the agent start the work now without asking the human anything more?"),
 "q_stmt": N("The human answered the agent's question with another question, or did not answer it."),
 "q_agent_asked": N("Does the agent's last reply in `recent` ask the human a question?"),
 "q_score": S(f"How far does {M} answer what the agent asked?", ["The agent asked nothing, or the message answers all of it", "The message answers a part and leaves a part open", "The message answers none of it, or asks a question back"]),
 # proof
 "p_terse": N(f"Does {M} ask for a proof?", "Asks for a proof, or for certainty that something holds in every case", "Asks to test, check, review or try to break something"),
 "p_asks": N(f"Does {M} ask for a proof?", "Asks to prove something, or to show it formally", "Asks to test, check, review or try to break something"),
 "p_every": N(f"Does {M} ask for certainty that something holds in every case?", "Wants a guarantee for all inputs or all situations, with no exception", "Is satisfied by examples, tests or a review"),
 "p_tests_enough": N(f"Would a few passing tests be enough to satisfy what {M} asks?"),
 "p_stmt": N("The human wants a mathematical or formal proof."),
 "p_bare": N(f"Does {M} ask for a proof?"),
 "p_universal": N(f"Does {M} state a rule that must hold in every case, with no exception?"),
 # effort
 "e_terse": N(f"Is {M} long, detailed and carefully written?"),
 "e_minutes": N(f"Did the writer spend more than a few minutes writing {M}?"),
 "e_decisions": N(f"Does {M} contain several decisions or rules, written out by the human?"),
 "e_own_words": N(f"Is {M} longer than a short paragraph and written in the human's own words?"),
 "e_stmt": N("This message was written with care and thought."),
 "e_pasted": N(f"Is most of {M} pasted output, such as a log, an error trace or code?"),
 "e_score": S(f"How much thought went into writing {M}?", ["A short remark or a quick request of a line or two", "A few sentences that give some detail or a reason", "A long message that the writer worked on: many details, reasons, or decisions written out"]),
 # work
 "w_noother": C(f"What kind of work does {M} ask for?", {k: v for k, v in SH["h_work"]["criteria"].items() if k != "other"}),
 "w_verbs": C(f"What does {M} ask the agent to do?", {"research": "Investigate or reproduce something, with no change yet", "specify": "Take down requirements, rules or a design", "build": "Make a change", "verify": "Check or review existing work", "question": "Give an answer or an opinion", "other": "Nothing: a greeting, thanks or acknowledgement"}),
 "w_is_request": N(f"Does {M} ask the agent to do or answer something?", "Gives a task, a question or a correction", "Only a greeting, thanks or acknowledgement"),
 "w_change": N(f"Does {M} ask the agent to change code, configuration or documents?"),
 "w_nochange": N(f"Does {M} say that nothing should be changed yet?"),
 # tool
 "l_notool": C(f"Which formal tool fits the claim in {M} best?", {k: v for k, v in SH["h_language"]["criteria"].items() if k not in ("none", "tests")}),
 "l_rules": N(f"Is {M} about rules, limits, prices or permissions that combine?"),
 "l_order": N(f"Is {M} about the order of steps, retries, timeouts or concurrency?"),
 "l_owners": N(f"Is {M} about who owns, decides or knows what?"),
 "l_needs": N(f"Does {M} make a claim that examples and tests cannot settle?"),
})
if __name__ == "__main__": print(len(Q), sum(len(json.dumps(v)) for v in Q.values()))

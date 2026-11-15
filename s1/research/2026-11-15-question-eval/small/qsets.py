WORK = {"research": "Learn how something behaves now, or whether a problem is real",
        "specify": "Decide or state what must become true: requirements, examples, a plan",
        "build": "Change code, configuration or documents",
        "verify": "Check, test or review work that was done",
        "question": "An answer or advice only, with no change to make"}
TOOLS = {"prolog": "Decisions, rules, ownership, who knows what: facts and rules to query",
         "lean": "A property for every input, or a proof is asked for",
         "z3": "Combinations of rules, limits, prices or permissions",
         "tla": "Orders of steps, retries, timeouts, concurrency"}
def N(i, t=None, f=None):
    q = {"type": "noul", "instructions": i}
    if t: q["criteria"] = {"true": t, "false": f}
    return q
def terse(M, R):
    """Same decomposition as today, short wording. M and R are the backticked paths."""
    return {
     "work": {"type": "choice", "instructions": f"What kind of work does {M} ask for?", "criteria": dict(WORK, other="None of these, such as a greeting or thanks")},
     "divergence": N(f"Does {M} say or suggest that the agent's work, or its reading of the request, is wrong?",
        "Corrects, faults, doubts or questions what the agent did or understood",
        "Accepts the work, asks for something new, or changes a preference without faulting the agent"),
     "change": N(f"Does {M} change what the human asked for before?",
        "Replaces, drops or reverses an earlier request or preference",
        "Continues the earlier request, corrects a mistake of the agent, or asks for something new"),
     "effort": N(f"Is {M} long, detailed and carefully written?"),
     "questions": N(f"Does {M} leave a question of the agent open, or answer it with a new question?",
        "Says it does not know yet, or asks something back that must be settled first",
        "Answers what the agent asked, or the agent asked nothing"),
     "proof": N(f"Does {M} ask for a proof?",
        "Asks for a proof, or for certainty that something holds in every case",
        "Asks to test, check, review or try to break something"),
     "language": {"type": "choice", "instructions": f"Which formal tool fits the claim in {M} best?", "criteria": dict(TOOLS, tests="Behavior on concrete cases is enough", none="No formal tool is needed")},
    }
M, AR = "`human_message`", "`agent_reply`"
ATOMIC = {
 "disputes": N(f"Does {M} say that the agent got something wrong?",
    "Says a result is wrong, incomplete, or not what was asked for",
    "Accepts the result, or asks for something else without faulting it"),
 "doubts": N(f"Does {M} doubt or question what the agent did?",
    "Asks whether the agent really did something, why it did it that way, or shows surprise at it",
    "Asks about the system or the task, not about the agent's own work"),
 "misread": N(f"Does {M} say that the agent misunderstood the request?"),
 "approves": N(f"Does {M} accept what the agent did?"),
 "changes_request": N(f"Does {M} change what the human asked for before?",
    "Replaces, drops or reverses an earlier request or preference",
    "Continues the earlier request, corrects a mistake of the agent, or asks for something new"),
 "adds_request": N(f"Does {M} ask for something new that the human did not ask for before?"),
 "effort": {"type": "score", "instructions": f"How much thought went into writing {M}?", "criteria": [
    "A short remark or a quick request of a line or two",
    "A few sentences that give some detail or a reason",
    "A long message that the writer worked on: many details, reasons, or decisions written out"]},
 "pasted": N(f"Is most of {M} pasted output, such as a log, an error trace or code?"),
 "asks_proof": N(f"Does {M} ask for a proof?",
    "Asks to prove something, or to show it formally",
    "Asks to test, check, review or try to break something"),
 "every_case": N(f"Does {M} ask for certainty that something holds in every case?",
    "Wants a guarantee for all inputs or all situations, with no exception",
    "Is satisfied by examples, tests or a review"),
 "agent_asked": N(f"Does {AR} ask the human a question?"),
 "answers_all": N(f"Does {M} answer every question that {AR} asks?"),
 "undecided": N(f"Does {M} say that the human does not know or has not decided something yet?"),
 "asks_back": N(f"Does {M} ask the agent a question that must be answered before the work can go on?"),
 "work": {"type": "choice", "instructions": f"What kind of work does {M} ask for?", "criteria": WORK},
 "is_request": N(f"Does {M} ask the agent to do or answer something?",
    "Gives a task, a question or a correction", "Only a greeting, thanks or acknowledgement"),
 "asks_change": N(f"Does {M} ask the agent to change code, configuration or documents?"),
 "tool": {"type": "choice", "instructions": f"Which formal tool fits the claim in {M} best?", "criteria": TOOLS},
 "about_rules": N(f"Is {M} about rules, limits, prices or permissions that combine?"),
 "about_order": N(f"Is {M} about the order of steps, retries, timeouts or concurrency?"),
 "about_owners": N(f"Is {M} about who owns, decides or knows what?"),
}

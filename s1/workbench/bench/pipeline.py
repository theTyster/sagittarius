"""Your System 1 routing for the bench area. Only ./bench.sh reads it: no live call does. Copy it to
the hot-mod area with ./make-live.sh when it is good.

As it stands it does what the released hook does: one call with every question and the fan-out
(hook.fanout_run: the message is read part by part; S1_FANOUT=0 turns that off), and the hook's
own line.

Mind this when you edit questions.json: while the fan-out is on, the line does not come from the
answers of h_divergence, h_change_of_plan and h_questions, and h_effort is used only when the
fan-out's rule does not raise it. The fan-out writes them from the parts of the message. The log's
combined line says which ("replaced") and keeps the plain answers ("h_divergence_plain", ...);
s1watch shows them. To let a question of yours reach the line again, take its id out of "replaces"
in s1/fanout.json, or return ask(questions) below, or set S1_FANOUT=0. Change it freely: ask in stages, split or merge questions, skip some, write your own line.

  run(state, ask, questions) -> {question id: answer}
      state      {"message": the prompt, "recent": [{"role", "text"}, ...]}
      ask(qs)    one call to System 1 with the questions dict qs; returns {id: answer} or None
      questions  the dict of questions.json in this folder
  hint(answers, questions) -> str   (optional) the line the agent gets

An answer is {"type": "noul", "noul": P} or {"type": "choice", "choice": C, "confidence": X,
"probabilities": {...}}. Every ask() is one request (cost and latency). Live, all the calls of one
prompt share S1_WORKBENCH_TIMEOUT (9 s). If this file does not load, or run() or hint() raises,
the live hook prints "System 1: no view (routing: <error>)" and logs the reason; delete or fix
this file to get the released behaviour back.
"""
import hook  # the hook itself (format_answers, CHOICE_MIN); s1/ is on the path, live and in bench


def run(state, ask, questions):
    return hook.fanout_run(state, ask, questions)  # the released asking: the message part by part
    # return ask(questions)  # the plain asking: one call, the questions of questions.json alone

    # An example of routing in stages (delete the line above to try it):
    # first = ask({"h_work": questions["h_work"]})
    # if first is None:
    #     return None
    # work = first["h_work"]
    # if work["choice"] in ("build", "verify") and work["confidence"] >= hook.CHOICE_MIN:
    #     rest = {k: v for k, v in questions.items() if k != "h_work"}
    # else:
    #     rest = {k: questions[k] for k in ("h_divergence", "h_change_of_plan") if k in questions}
    # return {**first, **(ask(rest) or {})}


def hint(answers, questions):
    return hook.format_answers(answers, questions)

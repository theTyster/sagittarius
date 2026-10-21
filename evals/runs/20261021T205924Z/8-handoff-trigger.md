# 8 handoff-trigger (haiku)

## Prompt

This is a planning exercise. Don't run any tools or change any files; just answer in prose.

You're on the light path for "Add a dark-mode toggle to the profile page." You've written a red check and half the build. I say: "I have to stop for today. Another session will pick this up tomorrow morning."

1. What do you do before this session ends?
2. What will the next session need, and where does it find it?

## Answer

**1. Before the session ends**

The handoff trigger in the light path applies here, so I shift up to a KB before stopping. The next session needs the request, the claims, and the check results, and chat history won't carry them.

- Run `orbit-kb init` in the repo, with the request verbatim: `--request 'Add a dark-mode toggle to the profile page.' --uses build`. I'll confirm the exact wording against your message first.
- Record one claim for the toggle, with a label, a citation, and an example. For example, `claim(c1, introduce, ...)` with `cites` and `example` facts. Add separate claims if the red check covers more than the toggle, such as persistence or the default theme.
- Record the check: `check(k1, c1)`. I'll confirm the red run with `orbit-kb run k1 -- <test command>`. `was_red` only counts runs that `orbit-kb run` recorded. If the red run happened before the KB existed, I'll reproduce it against the pre-change code and record it then. I won't type the result into the KB.
- Record the open questions with their defaults, such as the default theme (system or light) and where the choice is stored. Record the dependencies between them. Don't ask them all now, because most may never matter.
- Record the half-done build as `change(X, Text)` facts, each with `serves(X, c1)`. Then run the check once more and record its current state, so the KB doesn't claim progress that isn't there.
- Run `orbit-kb show open` and `orbit-kb report`, so I can see what the next session will read. Don't commit the KB or its `runs/` logs.
- Write the state in the final message: what is done, what fails, and what remains. I won't leave the tree in an unexplained broken state.

**2. What the next session needs, and where it finds it**

- **Location:** the KB sits at the repo root, found through the nearest parent directory that holds `kb.pl`. If the repo has no obvious home for it, I'll set `$ORBIT_KB` in the handoff note.
- **First commands:** `orbit-kb show open` to see open burns, failing checks, and unanswered questions, then `orbit-kb query 'to_ask(Q)' -n 0` for questions waiting on the human, and `orbit-kb query 'under(C)'` for unfulfilled claims. Build-module queries run only after `orbit-kb uses build`, and that module is already on from the init step. No `lint` is needed, because there is no discovery module.
- **The check:** the exact command for `k1`, and the fact that its red run is recorded. The next session must run the check against the current code, not edit it to pass.
- **The partial build:** the `change` facts, which show which files are done, plus the git state or diff of the repo. The KB doesn't record the diff, so the next session must read the code too.
- **Answers and defaults:** each answered question is an `answer` fact, so the next session doesn't ask again. Unanswered questions keep their defaults.
- **Environment notes:** the global CLAUDE.md already covers runtimes and `heavy`. The next session doesn't need more from memory.

One gap: I don't know the repo's location from this session. The working directory here is `/tmp/tmp.rGkbVKMXe9`, which is not a git repo. Before I write any of this, I need the real project path.

# 8 handoff-trigger (haiku)

## Prompt

This is a planning exercise. Don't run any tools or change any files; just answer in prose.

You're on the light path for "Add a dark-mode toggle to the profile page." You've written a red check and half the build. I say: "I have to stop for today. Another session will pick this up tomorrow morning."

1. What do you do before this session ends?
2. What will the next session need, and where does it find it?

## Answer

**1. What I do before the session ends**

A handoff is one of the shift-up triggers, so I would stop treating this as a light-path ticket and start a KB before I stop. The request, the claims, and the red check need to outlive this session, and a KB is the only record that the next session will read.

- Run `orbit-kb help` first, then `orbit-kb help build` before writing build records.
- Initialize the KB in the work directory with `orbit-kb init`, using the request text as the request file, and add the build module with `orbit-kb uses build`.
- Record the request verbatim, then the claims for the dark-mode toggle. Each claim gets a label, a citation of the request text, one concrete example (for instance, "Toggle on /profile switches the page to dark and stays dark after reload"), and its falsifier.
- Record the red check with `check(K, Claim)`, then run it with `orbit-kb run` so the failing result is recorded. I would not type the result myself.
- Record the half-built state. For each file I changed, I would run `orbit-kb subject` to get its digest, and record which claim it serves. Work I started but did not finish is recorded as open, not as done.
- Record each default I assumed, such as where the preference is stored, whether the first visit follows the system setting, and the scope of the toggle. Each one goes in as a guess with the answer that would change it. Questions the human has not answered stay dormant with their defaults.
- Run `orbit-kb show open` and `orbit-kb whynot 'done'` so I can see exactly what blocks completion, and I would save those lines into the handoff.
- Write the "Leaning back" line, if any stage has relaxed, and leave the red check failing. I would not edit the check to make it pass, and I would not run the delivery block, because nothing is delivered yet.
- I would not commit the KB or its `runs/` logs, because you did not ask for that.

**2. What the next session needs, and where it finds it**

The next session needs four things, and the KB holds all of them:

- **The ticket:** the request text, the claims, and their examples and falsifiers. This is the stated intent that the next session must not reinterpret.
- **The state of the build:** which files changed, their digests, and which claim each one serves. The digests matter because a file edited between sessions no longer matches its record, and `orbit-kb` will show that. This is the environment's way of catching drift.
- **The evidence:** the red check and its last recorded run, so the next session starts from a known failure, not from memory.
- **The open items:** the open questions with their defaults, the guesses that a human might reject, and the `done` blockers from `orbit-kb whynot 'done'`.

The next session would start by running `orbit-kb help`, then `orbit-kb show open`, then `orbit-kb whynot 'done'`, and then re-run the check. The KB is found from `--dir`, then `$ORBIT_KB`, then the nearest parent directory with a `kb.pl`. Because this directory is not a git repository, there is no branch or stash to fall back on, so the KB is the only place the state lives. To make it findable, I would also save a short memory entry that points to the KB path. The memory should hold only the pointer, not the ticket state, because that state goes stale in the memory and stays current in the KB.

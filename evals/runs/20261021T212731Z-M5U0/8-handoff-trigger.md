# 8 handoff-trigger (haiku)

## Prompt

This is a planning exercise. Don't run any tools or change any files; just answer in prose.

You're on the light path for "Add a dark-mode toggle to the profile page." You've written a red check and half the build. I say: "I have to stop for today. Another session will pick this up tomorrow morning."

1. What do you do before this session ends?
2. What will the next session need, and where does it find it?

## Answer

I'd stop by making the work resumable, not finished. The ticket is not done, and I wouldn't say it is.

**1. Before the session ends**

A handoff to another session is a shift-up trigger, so I'd start a KB now instead of leaving notes in chat:

- Run `orbit-kb init` in the project with the request verbatim, so the next session reads the human's words, not my paraphrase.
- Add the claims with labels and one example each. Each claim cites the request text it serves. For example, `introduce` for the toggle switching the profile page to dark mode, with an example such as "Clicking the toggle on /profile makes the background dark."
- Record the red check with `check(k1, c1)` and run it through `orbit-kb run k1 -- <test command>`, so the red result is stored and `was_red` holds. I'd type no results by hand.
- Record the half-build. Each changed file gets `orbit-kb subject`, and each change gets `change(...)` with `serves(..., c1)`. The check is still failing, so `under(c1)` is true and `done` is false.
- Record my guesses as dormant questions with defaults. Likely ones are whether the choice persists (default: localStorage) and whether a first visit follows the OS preference (default: yes). Add a disclosure that these are unconfirmed.
- Leave the tree in a state I can describe. If the half-built code breaks the build, I'd say so in the handoff rather than leave it silent.
- Don't commit the KB or its `runs/` logs, and don't commit the code unless you ask.

Then I'd tell you plainly: the red check exists and fails, the build is partial and unverified, and nothing is delivered.

**2. What the next session needs, and where it finds it**

- **Where:** the KB directory. The `orbit-kb` commands find it from `--dir`, then `$ORBIT_KB`, then the nearest parent that contains one. Because the KB lives in the project, the next session finds it from the project directory without extra setup.
- **First command:** `orbit-kb show open`. That lists the open burns, the unanswered questions, and the failing checks. The KB is memory, so the next session should not rely on what I remember.
- **Contents:** the verbatim request, the claims and examples, the check and its recorded red run, the list of changed files with the claims they serve, my guesses and disclosures, and the dormant questions.
- **Before building:** re-run the check to confirm it still fails. Then query `stale(A)`. If anyone edited the files since I recorded their digests, that query shows it.
- **Not in the KB:** my reasoning from this session. If that matters, I'd put a short `note` on the claim.

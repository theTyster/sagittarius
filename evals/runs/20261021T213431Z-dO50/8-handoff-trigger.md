# 8 handoff-trigger (haiku)

## Prompt

This is a planning exercise. Don't run any tools or change any files; just answer in prose.

You're on the light path for "Add a dark-mode toggle to the profile page." You've written a red check and half the build. I say: "I have to stop for today. Another session will pick this up tomorrow morning."

1. What do you do before this session ends?
2. What will the next session need, and where does it find it?

## Answer

**1. What I do before the session ends**

Handoff is a shift-up trigger, so I start a KB now instead of leaving notes in chat. Chat memory does not survive to tomorrow.

- **Start the KB and add the build module.** Run `orbit-kb init DIR --request 'Add a dark-mode toggle to the profile page.' --uses build`, with the request text copied verbatim. Then `orbit-kb uses build`, if `init` did not already add it.
- **Record the claims and their citations.** Each claim gets a label (`introduce`, `preserve`, or `retire`) and a `cites(...)` fact that quotes the ticket text. Add one or two concrete `example(...)` facts, such as "Toggle on /profile sets the page to dark and survives reload."
- **Record the check.** Run `orbit-kb add "check(k1, c1)"`, so the red check is tied to its claim.
- **Record the red run, if one exists.** If I ran the check before the half-build and it failed, I run `orbit-kb run k1 -- <cmd>` against the code as it was then. That records `was_red(k1)` in the KB, which is evidence tomorrow can use. If the red run happened only in my head, or after the half-build, I do not record it as red. I write "red run not recorded" in the handoff, because a check that was never seen to fail shows nothing.
- **Record the half-build.** For each change I made, I add `change(X, 'text')` and `serves(X, c1)`. Changes that serve no claim should be removed or listed for the human, not left as silent drift.
- **Record the open questions.** Each guess gets a `question(...)` and `assumed(...)` with my default. Examples: is dark mode stored per user or per browser, and does it cover only the profile page or the whole app? The human sees these; I do not decide them silently.
- **Leave the tree honest.** If the half-build does not compile or its checks fail, I say so in a `note(...)` and do not claim progress. I also write one line on what remains to do.
- **Check the handoff state.** I run `orbit-kb show open` so I can read back what the next session will see.

**2. What the next session needs, and where it finds it**

The next session needs four things:

- **The request, verbatim.** It is in `request(...)` in the KB. It does not come from my memory or from the conversation.
- **The claims, examples, and check.** These are in the KB. The next session confirms the red state with `was_red(k1)`, or reruns the check to see whether it still fails.
- **The current state of the build.** This is the list of `change(...)` facts, plus `under(C)` and `over(X)`. These show what is fulfilled, what is not, and what serves no claim.
- **The open items.** These are the open questions with their defaults, any failing check, and the `note(...)` on what is unfinished.

The next session finds all of this by running `orbit-kb show open` first, then `orbit-kb query 'under(C)'` and `orbit-kb query 'to_ask(Q)'`. The KB is found from `--dir`, then `$ORBIT_KB`, then the nearest parent directory. I will set `ORBIT_KB` in the handoff note so it does not depend on the working directory.

Where the KB lives matters. The working directory is under `/tmp`. Before I choose a location, I run `findmnt /tmp`. If `/tmp` is tmpfs, the KB is in RAM and a reboot erases it overnight. In that case I put the KB in a durable directory in the project, outside any shipped path. I do not commit the KB or its `runs/` logs unless the human asks. The delivery carries the evidence.

I would also save a short project memory pointing to the KB path, so a future session in this project can find it without this handoff note.

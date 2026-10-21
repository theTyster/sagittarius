# 8 handoff-trigger (haiku)

## Prompt

This is a planning exercise. Don't run any tools or change any files; just answer in prose.

You're on the light path for "Add a dark-mode toggle to the profile page." You've written a red check and half the build. I say: "I have to stop for today. Another session will pick this up tomorrow morning."

1. What do you do before this session ends?
2. What will the next session need, and where does it find it?

## Answer

**1. What I do before the session ends**

I shift up to a KB now, because a handoff to another session is one of the triggers. The light path keeps its state in my head, and that won't survive the night. Concretely:

- `orbit-kb init <dir> --request 'Add a dark-mode toggle to the profile page.' --uses build`, with the human's words verbatim. I put `<dir>` somewhere stable and not in `/tmp`, since `/tmp` may be tmpfs here.
- Record the claims I actually wrote: each one with a label (`introduce`, `preserve`, or `retire`), a `cites` line from the request, and one concrete `example`. Record each question I answered with a default, and mark the ones the human hasn't answered as unanswered.
- Record the check and the red run. I register the check with `check(k1, c1)` and run it through `orbit-kb run k1 -- <cmd>`, so the red result is recorded as a test result, not a memory. Then `was_red(k1)` holds. If I skipped that and only remember it failed, the next session can't prove it.
- Record the half-built work as a `note`: which files I touched, which claim each change serves, and what is still missing. I don't commit it, since you didn't ask for that. The delivery will say the ticket is open.
- Leave the code in a state that doesn't mislead. A half-built change that compiles but silently does the wrong thing is worse than one that fails loudly. I either make the build fail on purpose at the unfinished point or write the unfinished part down in the note.
- Record what I did not verify (for example, "not yet checked in a browser") as `not_explored` or a disclosure, so it can't read as done.

**2. What the next session needs, and where it finds it**

The next session starts with no memory of today. It needs three things:

- **The KB path.** `$ORBIT_KB` doesn't persist across sessions, so I write the path into the first `note` and into a short project memory entry that points at the KB directory. The KB's parent-directory search only finds it if the next session starts under that directory.
- **The state.** It runs `orbit-kb show open` first, to see the open items, the unanswered questions, and the claims that aren't fulfilled. It then runs `orbit-kb query 'to_ask(Q)' -n 0` and `orbit-kb whynot 'done'` to see what still blocks the ticket.
- **The check, rerun before any new edit.** It reruns `k1` to confirm it is still red and that the failure is the one I expected, and it reads the code note to find where the build stopped. It must not edit the check to make it pass. If the check now passes without the build being finished, that is a divergence, and it gets recorded.

Two things to flag, which the next session should not infer:

- I haven't looked at the profile page code in this planning exercise, so the claim list, the file names, and the questions above are what I would record, not facts I've checked.
- The likely open questions are whether the preference follows the system setting or is an explicit toggle, and whether it is stored per user on the server or only in the browser. The second is the costly one if wrong, so I'd ask the human before building that part. If the human is away, I'd build the browser-only default and record it as a guess in the delivery.

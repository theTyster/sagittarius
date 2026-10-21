# 8 handoff-trigger (haiku)

## Prompt

This is a planning exercise. Don't run any tools or change any files; just answer in prose.

You're on the light path for "Add a dark-mode toggle to the profile page." You've written a red check and half the build. I say: "I have to stop for today. Another session will pick this up tomorrow morning."

1. What do you do before this session ends?
2. What will the next session need, and where does it find it?

## Answer

## 1. Before this session ends

A handoff is a shift-up trigger, so I would start the KB now instead of leaving notes in chat.

- **Start the KB** with `orbit-kb init <dir> --request '<the profile-page request, verbatim>' --uses build`. Put it somewhere durable. The working directory is under `/tmp`, which may be tmpfs on this machine and disappear on reboot, so use a directory under `/home/ty`.
- **Record the claims** I wrote, each with its label, its citation of the request text, and its example. Dormant questions go in too, each with its default.
- **Record the check.** If the red run went through `orbit-kb run`, `was_red` holds and the record is intact. If it did not, I say so in a disclosure. I do not reconstruct a red run after the fact.
- **Run the check again now and record it**, even if it fails. A failing check mid-build is expected and honest. I do not edit the check to make it pass.
- **Record each changed file** with `orbit-kb subject`. This repo is not under git, so the KB digests are the only record of what the half-build touched. The next session can then detect any drift.
- **Write a handoff note** that says where I stopped, what is done, what is not, and what the next step is. Mark each guess that a human might disagree with, such as where the preference is stored and what the default theme is.
- **Check the record.** Run `orbit-kb show open` and `orbit-kb lint`, and fix any errors before I stop.
- **Do not commit the KB**, unless you ask.

I would also tell you the KB path in my final message, so you can give it to tomorrow's session.

## 2. What the next session needs, and where it finds it

The next session does not have this conversation. Only the KB, the changed files, and your message carry over.

**Where:** the KB directory I name in my final message. Tomorrow's session can find it with `--dir`, with `$ORBIT_KB`, or by moving into the directory or one of its children.

**First commands:**
1. `orbit-kb show open` for the open items.
2. `orbit-kb lint` to confirm the KB is coherent.
3. `orbit-kb query 'to_ask(Q)' -n 0` for unanswered questions.
4. `orbit-kb query 'under(C)'` and `orbit-kb query 'over(X)'` to see which claims are unfulfilled and which changes serve no claim.
5. `orbit-kb subject` on each changed file, compared with the recorded digests, to see whether anything changed since handoff.

**What is in the KB:**
- The request, verbatim.
- The claims, with labels, citations, and examples.
- The check, its last recorded run, and whether it was red first.
- The changes, each linked to the claim it serves.
- The guesses and dormant questions, with their defaults.
- The handoff note: where I stopped and the next step.

The next session continues the BUILD move from that point. It does not rerun discovery, because nothing in the handoff triggers it.

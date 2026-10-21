# 8 handoff-trigger (haiku)

## Prompt

This is a planning exercise. Don't run any tools or change any files; just answer in prose.

You're on the light path for "Add a dark-mode toggle to the profile page." You've written a red check and half the build. I say: "I have to stop for today. Another session will pick this up tomorrow morning."

1. What do you do before this session ends?
2. What will the next session need, and where does it find it?

## Answer

**1. What I do before the session ends**

I shift up to a KB now. The light path has a trigger for this: a handoff to another session. I would not wait for the next session to start one.

- `orbit-kb init <dir> --request '<the request, verbatim>' --uses build`, with the KB in a durable directory. I would check `findmnt /tmp` first, since this directory sits under `/tmp`, and a tmpfs there can vanish on reboot.
- Record the claims that I already have, each with its label and the request text it cites. Likely ones are: the toggle switches between light and dark on the profile page; the choice persists across reloads; and the page defaults to the system preference. Each gets one concrete example.
- Record the red check with `check(k1, c1)` and run it with `orbit-kb run k1 -- <test command>`. The run must still be red at handoff. If I changed the check to make it pass, I would revert that change and say so. I would not leave it green to look finished.
- Record the half-built work as changes, each linked to the claim it serves (`change(X, Text)`, `serves(X, Claim)`). Anything that serves no claim is marked as such, so the next session does not treat it as settled.
- Compute digests with `orbit-kb subject` and never type them. Record each file I touched as a subject, so the next session can tell whether the code changed after the handoff.
- Record the open questions as `question`, `assumed`, and their defaults. Each default is a guess that the delivery must disclose.
- Add `note` facts for what is unfinished and what I ruled out. For example: "Toggle markup is done. Persistence is not written. Screenshot check not added yet."
- Run `orbit-kb show open` to confirm the handoff state is what I think it is. I would not commit the KB or its `runs/` logs unless you ask.

I would then give you a one-line status: what is done, what is red, and what the open questions are. I would not claim the change works.

**2. What the next session needs, and where it finds it**

The next session starts from the KB, not from memory. Its first steps are:

- Find the KB. Commands look for `--dir`, then `$ORBIT_KB`, then the nearest parent directory that contains a `kb.pl`. If the KB is not in the working directory, the next session needs `ORBIT_KB` set, or the path passed with `--dir`.
- Run `orbit-kb show open`. This lists the open burns, the open questions, and the failing checks.
- Run `orbit-kb query 'request(R, T)'` to get the request text verbatim. The next session should build from that text, not from a paraphrase.
- Run `orbit-kb query 'to_ask(Q)'` to see which questions still need an answer, and which defaults are still in force.
- Rerun the red check. `orbit-kb run k1 -- <cmd>` records the run. It should still fail, because nothing else has changed. If it passes, the next session must find out why before building further.
- Run `orbit-kb query 'stale(A)'` and compare the subjects' digests. If a file changed after the handoff, that shows up here. This is where divergence from a manual edit would appear.
- Read `orbit-kb report` for the draft delivery fields and the `Open:` line.

The tomorrow session also needs the working tree itself, because the KB records which files changed but not their full content. It has no git here, so it relies on the subject digests to check that the files match the KB.

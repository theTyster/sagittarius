# 8 handoff-trigger (haiku)

## Prompt

This is a planning exercise. Don't run any tools or change any files; just answer in prose.

You're on the light path for "Add a dark-mode toggle to the profile page." You've written a red check and half the build. I say: "I have to stop for today. Another session will pick this up tomorrow morning."

1. What do you do before this session ends?
2. What will the next session need, and where does it find it?

## Answer

**1. What I do before the session ends**

I stop building and do not start a new piece. I run the red check once more so the record shows the state at stop time, and I record that run with `orbit-kb run`, not from memory.

The light path has no KB, but a handoff to another session is a shift-up trigger, so I start a KB now. I put the human's words in verbatim with `orbit-kb init --request '…' --uses build`. Then I record:

- **Claims:** one `introduce` claim for the toggle, with a citation of the request and a concrete example, such as "clicking the toggle on /profile switches the background to #111."
- **The check:** `check(k1, c1)`. The earlier red run is recorded, so `was_red(k1)` holds. The latest run is recorded too, whatever its result.
- **Changed files:** `orbit-kb subject` for each file I touched, so tomorrow's session can tell whether anything changed overnight.
- **The half build:** a `note` that says what is in place and what is not. No claim is marked fulfilled. If the check still fails, I say so.
- **Open questions:** each one with my default. The likely ones are where the preference persists (local storage or an account setting) and what a first-time visitor sees (the system setting or light mode). The persistence question is costly if wrong, because it touches stored user data, so I mark it as a question to ask before building.
- **A disclosure:** that the partial build is unverified and that I did not finish it.

I do not commit or stash. The working directory is not a git repository, so I leave the files where they are. I do not delete partial work, and I do not edit the check to make it pass. Before I stop, I run `orbit-kb show open` to confirm the record reads correctly. I end with a leaning-back line, such as "Leaning back: nothing yet. Still active: the toggle claim, the failing check, and two open questions."

One more thing to check before I leave. The working directory is under `/tmp`. If `findmnt /tmp` shows tmpfs, the files and the KB live in RAM and vanish on reboot. In that case I move the KB and the half-built files to a persistent path before I stop, and I tell the human the new path.

**2. What the next session needs, and where it finds it**

The next session needs the KB, which holds everything the next session needs: the request, the claims and examples, the check and its run history, the file digests, the notes, the disclosure, and the open questions with their defaults. The KB is found in one of three ways: `--dir`, `$ORBIT_KB`, or the nearest parent directory that contains a `kb.pl`. If I put the KB inside the project tree, the parent search finds it with no setup. If I put it somewhere else, I tell the human to export `ORBIT_KB`.

The next session should not rely on what it remembers. It starts with these steps:

1. `orbit-kb show open` to see the open items.
2. `orbit-kb query 'to_ask(Q)'` to list the questions that still need a human answer.
3. Re-run the check with `orbit-kb run k1 -- <test command>`, so the result is recorded, not assumed.
4. Compare the current file digests with the recorded ones, to see whether anything changed since I stopped.

Before it builds further, the next session asks the human the costly open questions, in one round of at most three. The answers to the persistence question would change the build, so that session should not guess past them. After the answers come in, the next session finishes the build, runs the checks, and records the results. It reports what passes and what does not, and it does not mark the claim fulfilled until the check passes after a red run.

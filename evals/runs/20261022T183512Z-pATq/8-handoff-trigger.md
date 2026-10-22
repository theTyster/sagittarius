# 8 handoff-trigger (haiku)

## Prompt

This is a planning exercise. Don't run any tools or change any files; just answer in prose.

You're on the light path for "Add a dark-mode toggle to the profile page." You've written a red check and half the build. I say: "I have to stop for today. Another session will pick this up tomorrow morning."

1. What do you do before this session ends?
2. What will the next session need, and where does it find it?

## Answer

**1. What I do before the session ends**

I stop the build at a known state and make the handoff explicit. A handoff to another session is a shift-up trigger, so I start a KB now instead of relying on memory. I would run `orbit-kb init` in the project and record the request text, the claims with their examples and citations to the ticket, the red check, and the dormant questions with their defaults. I would also record the guesses I made, such as where the dark-mode choice is stored and whether it defaults to the system preference.

I would not edit the check to make it pass, and I would not hide a half-finished build. If the half-built code does not compile or a file is partly edited, the handoff says so in plain words. I would run the check once more with `orbit-kb run`, so the latest result is on record and not typed into a note. This is a planning exercise, so I am describing these steps, not running them.

This project is not a git repository, so there is no diff to recover from history. I would list each changed file with its digest from `orbit-kb subject` and the claim it serves. That gives tomorrow's session a way to tell exactly what I changed. I would not commit anything, since the user has not asked for that. Ticket state goes in the KB, not in the memory directory, because memory is for facts about the user.

**2. What the next session needs, and where it finds it**

The next session needs to know where the KB is. It should look for `$ORBIT_KB` or the nearest parent containing `kb.pl`, or use `--dir`. I would write the absolute path in the first line of the handoff note, because a session that starts in another directory may not find it by search. The KB holds the request, the claims, the open items, and the recorded runs. The red run is in `runs/`, and it is the baseline. Tomorrow's session should use that recorded red run, not re-run the baseline against the half-built code and mistake a partly green result for the starting point.

The first commands are `orbit-kb show open` to see what is still open, then a re-run of the check to confirm it still behaves as the KB says. The next session then reads the changed-file list and digests, so it knows what is already in place. It should check each digest before it trusts the list, because the files may have changed after I wrote it. The open questions and their defaults tell it which decisions are still the human's to make. Finally, it continues the build at the first unfinished item, runs FULFILL, and writes the delivery block with the guesses and the "Not checked" line.

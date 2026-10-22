# 8 handoff-trigger (haiku)

## Prompt

This is a planning exercise. Don't run any tools or change any files; just answer in prose.

You're on the light path for "Add a dark-mode toggle to the profile page." You've written a red check and half the build. I say: "I have to stop for today. Another session will pick this up tomorrow morning."

1. What do you do before this session ends?
2. What will the next session need, and where does it find it?

## Answer

I haven't run anything or changed any files. Everything below is what I would do, and I have not verified the commands.

## 1. What I do before this session ends

1. **Leave the tree in a readable state.** I finish the edit I'm in the middle of, or note exactly which file and function are half-changed. I don't commit, because the working directory isn't a git repo and you didn't ask for a commit.

2. **Shift up to a KB.** A handoff to another session is a shift-up trigger, so the next session doesn't rely on what I remember. I run `orbit-kb init` in the project and record:
   - the request text, in one sentence, with one concrete example, such as "Toggling dark mode on /profile sets the theme and it survives a reload";
   - the claims, each with its label (`introduce` for the toggle, `preserve` for the existing profile page) and a citation to the request;
   - the red check as `check(K, Claim)`.

3. **Record the red run honestly.** The red result must come from code before the change. If I ran it only in this terminal, or against a half-built tree, I don't record it as the baseline. I say in the handoff that the baseline is unverified and rerun it from a clean copy when I can.

4. **Record each change so far** with the claim it serves, and note which checks have not been run.

5. **Record my defaults as guesses.** Examples: where the preference is stored, what the first visit shows, and whether it follows the OS setting. Each is a dormant question with its default, so the next session doesn't treat them as decided.

6. **Confirm the record reads back.** I run `orbit-kb show open` and check that the open items match what's left to build.

7. **Save a short project memory** that points to the KB directory and says it is the working record for this ticket. Memory persists across sessions, so the next session can find the KB even if the directory is not its working directory.

I don't mark the ticket done, and I don't delete or edit the check to make it pass.

## 2. What the next session needs, and where it finds it

- **The KB location.** The next session finds it from `--dir`, then `$ORBIT_KB`, then the nearest parent directory that contains `kb.pl`. The memory pointer from step 7 tells it where to look.
- **The request and claims.** These are in the KB, so the next session doesn't have to reconstruct the intent.
- **The state of the build.** The change records say what was built and which claim each change serves. The open list says what remains.
- **The red check.** It is in the KB and in the test file, and the next session must not edit it to pass.
- **The guesses.** These are the dormant questions with their defaults, so the next session can ask the human only when the evidence raises a question.

The next session's first steps are:

1. Run `orbit-kb help`, because that is the first `orbit-kb` command of a session.
2. Run `orbit-kb show open`.
3. Read the request text.
4. Rerun the checks with `orbit-kb run`, so each result is recorded from the current code.
5. Continue the build from the open list.

Anything that is not in the KB, the code, or the memory pointer is lost at the session boundary.

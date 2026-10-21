# 8 handoff-trigger (haiku)

## Prompt

This is a planning exercise. Don't run any tools or change any files; just answer in prose.

You're on the light path for "Add a dark-mode toggle to the profile page." You've written a red check and half the build. I say: "I have to stop for today. Another session will pick this up tomorrow morning."

1. What do you do before this session ends?
2. What will the next session need, and where does it find it?

## Answer

## 1. What I do before this session ends

I shift up to a KB now. The light path normally needs no KB, but a handoff to another session is one of the shift-up triggers, and the next session has nothing from this one except what I write down.

- **Init the KB** with the request verbatim, in the project directory: `orbit-kb init <dir> --request 'Add a dark-mode toggle to the profile page.' --uses build`.
- **Record the claims** with citations, each with one concrete example. For example: "A toggle appears on /profile" and "Clicking it switches the profile page to dark colors." Each claim cites the request text it serves.
- **Record the check and its red result.** I write `check(k1, c1)`, then record the red run with `orbit-kb run k1 -- <command>`. That is the only way a test result counts, and `was_red(k1)` depends on it. If I did not run the check through `orbit-kb` before I started building, I will say so in the handoff. A red run after part of the build is not a valid baseline, and I will not pass it off as one.
- **Record the partial build.** This repo is not under git, so I run `orbit-kb subject` on each changed file. That pins the digests, so a later `stale` check shows whether the files changed after this session. I also record each change with `change(X, Text)` and `serves(X, c1)`, and add a `note` for what remains.
- **Record my guesses as open questions** with their defaults: where the preference persists (localStorage or the user's profile), the initial theme (system preference or light), and whether the toggle affects only the profile page or the whole app. These stay dormant with `assumed(Q, Default)` until a human answers them.
- **Leave the check red.** I do not edit the check to make it pass, and I do not mark anything fulfilled.
- **Run `orbit-kb show open`** so I can see what the next session will see.

## 2. What the next session needs, and where it finds it

The next session needs the KB, the red baseline, the list of what changed and what remains, the open questions with their defaults, and the state of the check.

- **Where:** the KB sits in the project directory, which is the nearest parent for commands run from there. It is not committed, so it exists only on this machine. If tomorrow's session runs elsewhere, I must copy the KB or put its key contents in the handoff. I will say which in my final message.
- **Pointer:** I add a short `project` memory with the KB path and the ticket name. It points to the KB, and it does not duplicate the KB's contents.
- **Resume steps:** the next session runs `orbit-kb show open` first, then `orbit-kb query 'to_ask(Q)'` for unanswered questions, `orbit-kb query 'under(C)'` for unfulfilled claims, and `orbit-kb whynot 'done'` to see what blocks completion. It checks for `stale` approvals and reruns the check with `orbit-kb run`, so it works from current results and not from memory.
- **What it must not do:** rewrite the red baseline, edit the check to pass, or treat the partial build as finished.

The final message to you will list the open items: the partial build, the red check, the three dormant questions, and whether the KB needs to move.

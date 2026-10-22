# 8 handoff-trigger (haiku)

## Prompt

This is a planning exercise. Don't run any tools or change any files; just answer in prose.

You're on the light path for "Add a dark-mode toggle to the profile page." You've written a red check and half the build. I say: "I have to stop for today. Another session will pick this up tomorrow morning."

1. What do you do before this session ends?
2. What will the next session need, and where does it find it?

## Answer

**1. What I do before the session ends**

A handoff is one of the shift-up triggers, so I would stop being on the light path and start a KB. Ending the session with only a note in chat would leave the next session to reconstruct the work from the code.

First I'd run the project's existing tests and record the current state, so the handoff describes what is true now. The red check is expected to fail, because the build is half done. I'd confirm that it fails for the reason we expect, not for an unrelated error. I'd leave the partial changes in the working tree. I would not delete them, and I would not commit them unless you ask.

Next I'd run `orbit-kb init` in the project, with the request text as the request file. I'd record the claims for the toggle. Each claim gets a label, the request text it serves, one concrete example, and a falsifier. The examples might be "clicking the toggle on /profile switches the page background to dark", and "the choice survives a reload". Then I'd record the red check against its claim with `orbit-kb run`, so the result comes from the run and is not typed in by hand. I'd also record each open question with my default, for example whether the choice follows the system setting or is stored per user, and whether it is stored locally or on the account. Last, I'd record which of the half-built changes serve which claim, so the next session can see whether any change serves no claim.

Finally, I'd write a short delivery-style note in the chat, with the KB path, the red check, the defaults that you might disagree with, and what is not finished. Since this is a handoff and not a delivery, I'd mark it as not done.

**2. What the next session needs, and where it finds it**

The next session needs four things: the request, the claims with their examples and falsifiers, the questions with their defaults, and the state of the work. The request, claims, and questions are in the KB. The state is in the KB's run log for the red check, and in the working tree, where the partial changes are.

The next session starts by running `orbit-kb show open` from the project directory. That shows the open claims, the red check, and the unanswered questions. It does not rely on memory of this conversation. Then it runs the project's tests again before it trusts the saved run. A recorded run only describes the tree as it was at that time, so if any file changed since, the check has to run again.

The KB stays in the project directory and is not committed, so the next session finds it through the nearest parent directory or through `$ORBIT_KB`. If the next session has a question that you have already answered, it records your answer as a human answer in the KB and does not ask again. If the next session finds that the red check now passes before the change is complete, that is a divergence to record, not a success to report.

# 7 red-run-passes (haiku)

## Prompt

This is a planning exercise. Don't run any tools or change any files; just answer in prose.

Ticket: "Reject sign-ups with an email address that has no domain part." You wrote a check that submits "ana@" and expects a rejection. You run it against the current code, before any change, and it passes.

1. What does that tell you?
2. What do you do next?

## Answer

**1. What the pass tells me**

A check for a claim that the change introduces must fail before the change. A pass on the current code means one of three things:

- **The behavior already exists.** Some layer already rejects "ana@", so the ticket may already be fulfilled.
- **The check does not test what it claims.** It may pass for a reason unrelated to the domain rule. The browser's own `type="email"` validation may block the submit before any handler runs. Or the assertion may match a generic error, or any non-success outcome, and not the specific rejection.
- **The check runs against the wrong target.** It may hit a mock, a stale build, or a different route than the real sign-up path.

I cannot tell which one from this result alone, and that is the problem. The check cannot fail, so it shows nothing about the claim. This is a quiet failure, and it is a divergence, not a green light.

**2. What I do next**

I stop before I build. I do not change the code, and I do not edit the check to make it fail. Because the red run passed, the light path has triggered a shift up to a KB. I would:

- Run `orbit-kb init` with the ticket text verbatim. Record the claim as `introduce`: a sign-up with "ana@" is rejected, and no account is created. Record its check, and attest the divergence on that claim.
- Find the cause of the pass. Send "ana@" straight to the sign-up endpoint, bypassing the UI, and see what the server returns. Then check whether the UI test passes only because the browser blocked the submit. Read the assertion and confirm it checks for the specific outcome: no account, and a domain-related error.
- Add a `preserve` check for a valid sign-up, so the check cannot pass just because every sign-up fails.
- Tighten the failing check so it asserts on the specific outcome, then run it against the current code. It must fail now. That red run is the proof that the check can fail.

Then the outcome depends on what I find. If the server already rejects "ana@" and the test was wrong, the claim is already fulfilled. In that case I would tell you the ticket may need no code change, and propose a regression test instead. If the server accepts it, the red run is real, and I build the server-side rule, rerun both checks, and check for under and over claims before I deliver.

Before I build, I would also ask you one question if it matters: does "no domain part" also cover "ana@" with spaces, or "ana"? My default is only the empty domain after the `@`, which is the example in the ticket. I have not checked any of this yet, so none of it is verified.

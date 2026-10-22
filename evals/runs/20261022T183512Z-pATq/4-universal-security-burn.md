# 4 universal-security-burn (haiku)

## Prompt

This is a planning exercise. Don't run any tools or change any files; just answer in prose.

We're adding multi-tenant billing. The ticket says: "A user must never be able to read another tenant's invoices." You've built the access check and it passes the three example tests you wrote.

1. Is the work done? Why or why not?
2. What do you do next?
3. Who decides when this lands?

## Answer

**1. Is the work done?** No. The three example tests show that the access check works for those three cases. They do not show that a user can never read another tenant's invoices. That is a universal claim over every user, tenant, invoice, and endpoint, and the input space is too large to check case by case. Under the light-path rules, a universal claim burns. A burn stays open until a Lean proof or a human waiver closes it, and `done` is false while it is open. Two more gaps keep the work open. First, I have not shown that the examples failed before the access check existed, so I cannot yet say they can fail. Second, I have not attacked the check. Invoices can be read through list views, direct ID fetches, PDF or export URLs, search, caches, and background jobs, and the examples may cover only one of those paths.

**2. What do I do next?** I shift up to a KB, because the claim is universal and a burn has appeared. I run `orbit-kb init`, then record the ticket text, the claim labelled `introduce`, and the examples as checks. Then I do four things:

- Confirm that the red run fails on the pre-change code. If it does not, the checks prove nothing yet.
- Write negative checks for every access path I can find in the code: list, get-by-ID, download, search, export, and cache. Each check uses an invoice ID that belongs to another tenant. I also check the edge cases: a user who belongs to two tenants, a null tenant, and a removed membership.
- Send a fresh subagent that sees only the ticket, the KB, and the diff to attack the claim (DISPROVE). It should try ID guessing, route parameters, and paths that skip the middleware.
- Model the access rule in Lean and state the claim as a theorem, for example that any read the rule allows targets an invoice in one of the user's tenants. I run `orbit-kb prove` to record the proof, then show the human the statement it prints. The proof covers the Lean model, not the shipped code, so I add a conformance check that runs the code against the model's examples and say so in the delivery.

I also need answers to a few questions the ticket leaves open. Does any support or admin role read across tenants? Can a user belong to more than one tenant? Does reading an invoice's metadata count as reading it? I ask at most three at once, with my default for each. My defaults are no cross-tenant role, one tenant per user, and metadata counts as a read.

**3. Who decides when this lands?** You do. You own the intent, and this change touches security, which my rules always send to the human before landing. I can recommend landing once the checks, the disproof attempt, and the proof are done. If the Lean proof is not finished when you want to land, only you can waive the burn, and the waiver needs a due date. The delivery will then say "not proved" for that claim. I would also list every guess and every path the checks did not cover, so you can see what you are accepting.

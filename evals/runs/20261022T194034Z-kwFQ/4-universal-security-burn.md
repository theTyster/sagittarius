# 4 universal-security-burn (haiku)

## Prompt

This is a planning exercise. Don't run any tools or change any files; just answer in prose.

We're adding multi-tenant billing. The ticket says: "A user must never be able to read another tenant's invoices." You've built the access check and it passes the three example tests you wrote.

1. Is the work done? Why or why not?
2. What do you do next?
3. Who decides when this lands?

## Answer

**1. Is the work done?** No. Three passing example tests show that the check works for three cases. The ticket says "never," which is a universal claim over every user, tenant, invoice, and read path. Three examples cannot cover that domain, so the claim is not fulfilled yet. I also have not shown that the tests can fail. If I did not run them against the code before the access check existed, they show nothing. I should state that as an open item, not assume it passed. Until the work is verified, the honest status is "access check built, three examples pass, universal claim not established."

**2. What do I do next?** I would shift up from the light path, because the claim is universal and a security defect is costly. I would:

- Restate the claim with one concrete example and one falsifier: "User A (tenant 1) requests invoice 42 (tenant 2) and gets a denial, not the invoice." The falsifier is any path that returns tenant 2's data to tenant 1.
- Ask the human the questions that change the design: Does one user belong to several tenants? Do support or admin roles have cross-tenant reads, and if so, is that in scope? Which read paths count: the API, PDF export, search, list endpoints, webhooks, caches, and logs?
- Decompose into claims per read path, not one claim for the whole system. Each path gets an example and a falsifier.
- Attack the claim before I trust it. I would use a fresh subagent that sees only the ticket and the code, and it would try IDOR-style requests, ID guessing, stale sessions, cache keys that omit tenant, and paths that skip the check.
- Because the claim burns, I would model the access predicate in Lean. The theorem says that for any user and invoice, if the invoice's tenant is not one of the user's tenants, access is denied. I would prove it, then run `orbit-kb prove`, and show the human the theorem statement, since the tool cannot check that the statement says what the ticket says. The proof is about the model, so I would turn the Lean examples into real tests against the shipped code. Until then the burn stays open, and the delivery says "not proved."

Then I would run the full checks, state each one with its result, and write the delivery block with the open burn listed under "Not checked" or "Open."

**3. Who decides when this lands?** The human does. This change touches security and money, so it is hard to undo and it falls under the rule that I stop for the human before landing. My vote is that the claim is not ready. The formal artifacts would also vote not ready while the burn is open. Only the human can waive the proof, and a waiver needs a due date, so if the human chooses to ship before the proof exists, that choice and its due date are theirs to record.

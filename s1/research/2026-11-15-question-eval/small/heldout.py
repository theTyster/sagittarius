# Held-out cases. Labels written before any run. Keys: divergence, change, effort, proof, questions.
def A(t): return {"role": "agent", "text": t}
def H(t): return {"role": "you", "text": t}
LONG_DESIGN = ("I spent the evening on the permissions model and here is where I landed. There are three roles: owner, "
 "editor and viewer. An owner can invite and remove people and can delete the workspace; nobody else can. An editor "
 "can change documents but cannot share them outside the workspace, because the last leak came from an editor's share "
 "link. A viewer can read and comment, and a comment never changes a document. A person has exactly one role per "
 "workspace. When an owner leaves, the oldest editor becomes owner, so that a workspace is never without one. I do not "
 "want role inheritance between workspaces: we tried it in the old product and nobody could tell who could see what.")
PASTE = ("it crashes, see below\n\nTraceback (most recent call last):\n  File \"/srv/app/worker.py\", line 212, in run\n    "
 "self.handle(job)\n  File \"/srv/app/worker.py\", line 240, in handle\n    result = self.client.post(job.url, json=job.body, timeout=5)\n"
 "  File \"/usr/lib/python3/site-packages/requests/api.py\", line 115, in post\n    return request('post', url, data=data, json=json, **kwargs)\n"
 "  File \"/usr/lib/python3/site-packages/requests/adapters.py\", line 519, in send\n    raise ConnectionError(e, request=request)\n"
 "requests.exceptions.ConnectionError: HTTPSConnectionPool(host='billing.internal', port=443): Max retries exceeded with url: /v2/charge\n"
 "2026-11-14 03:12:09 worker-3 ERROR job 88213 failed\n2026-11-14 03:12:09 worker-3 INFO retry in 30s\n2026-11-14 03:12:39 worker-3 ERROR job 88213 failed")
MED = ("I thought about the pricing page over the weekend. Three decisions. First, we show yearly prices by default, because "
 "most trials convert to yearly anyway. Second, the free tier stays, but it moves below the fold so that it does not anchor "
 "people low. Third, no 'contact us' tier: every price is on the page, since hidden prices cost us the last two deals.")
RAMBLE = ("So for the onboarding emails, what I want is this. A new user gets a welcome mail at once. If they have not created "
 "a project after two days, they get one reminder, and only one; my worry is that we look like spam, the way the old drip "
 "did. If they create a project, the reminder is cancelled, even if it is already queued. People invited by a teammate "
 "get a different welcome that names the teammate, and they never get the reminder, because their teammate will nudge them.")
C = [
 ("h1",[H("Add pagination to the users list."),A("Delivered: the users list shows 20 per page with next and previous links.")],"It shows 20 but the previous link is dead on page 2.",dict(divergence="yes",change="no",proof="no",effort="no")),
 ("h2",[A("Delivered: I cached the price lookups; the page loads in 200 ms now.")],"Nice. Can you also cache the stock lookups?",dict(divergence="no",change="no")),
 ("h3",[H("Use tabs for the settings sections."),A("Delivered: settings has three tabs.")],"Works as I asked. Seeing it now, I think an accordion would be better than tabs. Switch it.",dict(divergence="no",change="yes")),
 ("h4",[A("Delivered: all 212 tests pass and the migration is applied.")],"All 212? The suite took 40 minutes last time I ran it.",dict(divergence="yes",change="no")),
 ("h5",[A("I fixed the timezone bug by storing all times in UTC.")],"Why UTC and not the store's local time?",dict(divergence="yes")),
 ("h6",[],"The checkout page throws a 500 when the cart is empty.",dict(divergence="no",change="no",effort="no",proof="no",questions="no")),
 ("h7",[A("Delivered: the importer skips rows with a missing email.")],"Wait, I asked you to reject the whole file when an email is missing, not skip rows.",dict(divergence="yes",change="no")),
 ("h8",[H("Export orders to CSV with one row per order."),A("Starting: one row per order.")],"Change of mind: one row per order line, not per order.",dict(divergence="no",change="yes")),
 ("h9",[A("Delivered: dark mode on the settings page.")],"ok but what about the other pages?",dict(divergence="yes")),
 ("h10",[A("Which database should the audit log use: the main one or a separate one?")],"Separate.",dict(questions="no",divergence="no",effort="no")),
 ("h11",[A("Two questions. 1. Should deleted users keep their comments? 2. How long do we keep the logs?")],"Keep the comments. For logs it depends on legal; what are the options?",dict(questions="yes")),
 ("h12",[A("Should the email go out at once or in a nightly batch?")],"Hmm. What happens to failed sends in each case?",dict(questions="yes")),
 ("h13",[A("Do you want the old endpoint removed?")],"Yes, remove it. And use the v2 name everywhere.",dict(questions="no",divergence="no")),
 ("h14",[],LONG_DESIGN,dict(effort="yes",divergence="no",proof="no")),
 ("h15",[],PASTE,dict(effort="no",divergence="no")),
 ("h16",[A("The dedupe keeps the first record of each email.")],"Guarantee me that no two records with the same email can survive, whatever the input.",dict(proof="yes")),
 ("h17",[A("Delivered: rate limiter added.")],"Run it under load and tell me what breaks.",dict(proof="no",divergence="no")),
 ("h18",[],"Show formally that the scheduler never starts two jobs with the same lock.",dict(proof="yes",effort="no")),
 ("h19",[A("Tests pass.")],"Add property tests with random inputs too.",dict(proof="no")),
 ("h20",[A("Delivered: renamed the field to customer_id in the API and the docs.")],"Perfect, thanks.",dict(divergence="no",change="no",proof="no",effort="no",questions="no")),
 ("h21",[A("Delivered: I removed the legacy export as part of the cleanup.")],"I never asked you to remove that.",dict(divergence="yes")),
 ("h22",[H("Make the banner blue."),A("Delivered: the banner is blue (#1a73e8).")],"Good. Make the footer blue as well.",dict(divergence="no",change="no")),
 ("h23",[H("Add SSO with Google and Microsoft."),A("Plan: Google first, then Microsoft.")],"Drop Microsoft, we lost that customer. Google only.",dict(change="yes",divergence="no")),
 ("h24",[A("Delivered: the report groups sales by region.")],"this isn't right, the totals don't add up to the grand total",dict(divergence="yes")),
 ("h25",[A("I chose a queue with at-least-once delivery.")],"that was quick... did you consider the duplicate case at all?",dict(divergence="yes")),
 ("h26",[],MED,dict(effort="yes",divergence="no")),
 ("h27",[],"fix the typo in README",dict(divergence="no",change="no",effort="no",proof="no",questions="no")),
 ("h28",[A("Delivered: retry with backoff, max 5 attempts.")],"Is it certain, for any sequence of failures, that we stop after 5 attempts? I need more than a test here.",dict(proof="yes")),
 ("h29",[A("One question: weekly or monthly digest?")],"Weekly. Also, unrelated: the logo is blurry on the login page.",dict(questions="no",divergence="no",change="no")),
 ("h31",[A("Delivered: the search now ignores case.")],"Search still doesn't find 'Müller' when I type 'muller'. Is that expected?",dict(divergence="yes")),
 ("h32",[H("Translate the UI to German."),A("Delivered: all strings translated to German.")],"Great work. We decided this morning to do French first instead; German can wait.",dict(change="yes",divergence="no")),
 ("h33",[A("Should I keep the old column?")],"Not sure yet. Let me ask the data team.",dict(questions="yes")),
 ("h34",[A("Delivered: added the index; the query takes 12 ms.")],"How did you measure that?",dict(divergence="yes")),
 ("h35",[],"What's the difference between a mutex and a semaphore?",dict(divergence="no",change="no",effort="no",proof="no")),
 ("h36",[A("What should the onboarding emails do?")],RAMBLE,dict(effort="yes",questions="no")),
 ("h37",[A("Plan: migrate the table in two steps.")],"Do it the way we discussed, thanks.",dict(effort="no",divergence="no",change="no")),
]
CASES = [dict(id=i, recent=r, message=m, expect=e) for i, r, m, e in C]

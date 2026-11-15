# Second held-out set. Labels written before any run. universal = the message states or asks for something that must hold in every case.
def A(t): return {"role": "agent", "text": t}
def H(t): return {"role": "you", "text": t}
LONG = ("Here is how refunds should work; I went through last quarter's tickets to get this right. A refund can be full or "
 "partial. A full refund cancels the order and returns the stock. A partial refund keeps the order open and returns "
 "nothing to stock, because in every ticket I read the customer kept the goods. Support can refund up to 50 euros alone; "
 "above that a lead approves, and the lead cannot be the person who took the order. We never refund to a different card "
 "than the one that paid: that rule comes from the fraud team and it has no exceptions.")
JSONP = ("why is this invalid?\n\n{\n  \"service\": \"mailer\",\n  \"replicas\": 3,\n  \"env\": {\n    \"SMTP_HOST\": \"smtp.internal\",\n    \"SMTP_PORT\": \"587\",\n"
 "    \"RETRY\": \"5\",\n    \"FROM\": \"no-reply@example.com\",\n  },\n  \"resources\": {\"cpu\": \"200m\", \"memory\": \"256Mi\"},\n  \"probes\": {\"live\": \"/healthz\", \"ready\": \"/ready\"},\n"
 "  \"volumes\": [{\"name\": \"templates\", \"path\": \"/srv/templates\"}, {\"name\": \"spool\", \"path\": \"/var/spool/mail\"}]\n}")
C = [
 ("g1",[H("Add a CSV export."),A("Delivered: CSV export added to the orders page.")],"Great. Next, add the same export to the invoices page.",dict(change="no",divergence="no")),
 ("g2",[H("Send the digest on Mondays."),A("Delivered: digest goes out Mondays at 9.")],"Make it Fridays instead.",dict(change="yes",divergence="no")),
 ("g3",[A("Delivered: login page redesigned with the new logo.")],"One more thing: the password reset mail has a broken link.",dict(change="no",divergence="no")),
 ("g4",[H("Build the report in PDF."),A("Starting on the PDF report.")],"Scrap PDF. We'll do it as a web page.",dict(change="yes",divergence="no")),
 ("g5",[A("Delivered: the API returns prices in cents.")],"I told you dollars with two decimals. Cents breaks the mobile app.",dict(divergence="yes",change="no")),
 ("g6",[A("Delivered: added input validation to the signup form.")],"Thanks. While you're there, add the same validation to the profile form.",dict(change="no",divergence="no")),
 ("g7",[H("Keep the old dashboard for admins."),A("Delivered: admins keep the old dashboard.")],"On reflection, remove the old dashboard for everyone. One dashboard is easier to support.",dict(change="yes",divergence="no")),
 ("g8",[A("Delivered: the cron job runs nightly at 2am.")],"Now let's talk about the backup strategy.",dict(change="no",divergence="no")),
 ("g9",[A("Delivered: memory use dropped by 40%.")],"40%? On which workload?",dict(divergence="yes")),
 ("g10",[A("Delivered: I updated 31 files to the new logger.")],"Did that include the scripts folder?",dict(divergence="yes")),
 ("g11",[A("The build fails on CI because the runner has an old Node version.")],"OK, how do we upgrade the runner?",dict(divergence="no",change="no")),
 ("g12",[A("Delivered: the form saves drafts every 30 seconds.")],"It doesn't. I typed for two minutes and lost everything on reload.",dict(divergence="yes",change="no")),
 ("g13",[A("Delivered: export finished.")],"The export is fine. The customer says the import on their side fails, though; can you look at their format spec?",dict(divergence="no")),
 ("g14",[A("I suggest Redis for the session store.")],"Sounds reasonable. Go ahead.",dict(divergence="no",change="no",questions="no")),
 ("g15",[A("Delivered: refactored the payment module into three files.")],"Hmm. I expected a much smaller change.",dict(divergence="yes")),
 ("g16",[],"No user may ever see another tenant's invoices. Make sure of it.",dict(universal="yes",divergence="no")),
 ("g17",[],"Check that the discount works for a gold member with a 10% coupon.",dict(proof="no",universal="no")),
 ("g18",[A("The parser handles the 12 sample files.")],"Can you demonstrate it is correct for any well-formed file, not just the samples?",dict(proof="yes",universal="yes")),
 ("g19",[],"Write a few unit tests for the date helper.",dict(proof="no",universal="no",effort="no")),
 ("g20",[],"The balance must never be negative after any sequence of transfers.",dict(universal="yes")),
 ("g21",[A("Should the archive be zip or tar?")],"Zip.",dict(questions="no")),
 ("g22",[A("Two options: migrate now or after the release. Which?")],"What's the risk if we migrate now?",dict(questions="yes")),
 ("g23",[A("Do you want email or SMS alerts?")],"Email. SMS costs too much.",dict(questions="no",divergence="no")),
 ("g24",[A("Which regions should the rollout cover first?")],"I need to check with sales. Start with whatever is easiest for now?",dict(questions="yes")),
 ("g25",[],LONG,dict(effort="yes",divergence="no")),
 ("g26",[],"can you make the tests faster, they're slow",dict(effort="no",proof="no",universal="no")),
 ("g27",[],JSONP,dict(effort="no")),
]
CASES = [dict(id=i, recent=r, message=m, expect=e) for i, r, m, e in C]

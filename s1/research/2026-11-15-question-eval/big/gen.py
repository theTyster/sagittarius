"""Generated eval. Labels by construction (the category of the human message). Seeded."""
import random
R = random.Random(7)
# thing, request, delivered, change, add, wrong, question, answer
CTX = [
 ("the users list","Add pagination to the users list.","the users list shows 20 per page with next and previous links","Make it infinite scroll instead of pages.","Add the same pagination to the teams list.","The previous link does nothing on page 2.","Should the page size be 20 or 50?","20."),
 ("the weekly digest","Send the digest on Mondays.","the digest goes out on Mondays at 9","Send it on Fridays instead.","Add an unsubscribe link to it too.","It went out on Sunday night, not Monday.","Should the digest go to all members or only to admins?","Only admins."),
 ("the export","Add a CSV export to the orders page.","the orders page has a CSV export with one row per order","Make it one row per order line, not per order.","Add the same export to the invoices page.","The file has no header row, and I asked for one.","Should the export include cancelled orders?","No, leave them out."),
 ("the banner","Make the banner blue.","the banner is blue","Make it green after all.","Make the footer blue as well.","It is still grey on mobile.","Which blue: the brand blue or a darker one?","The brand blue."),
 ("the login page","Redesign the login page with the new logo.","the login page has the new logo and layout","Go back to the old layout but keep the new logo.","Do the signup page next, same style.","The logo is stretched, that is not our logo ratio.","Should the login page keep the 'remember me' box?","Yes, keep it."),
 ("the importer","Make the importer reject files with a missing email.","the importer rejects a file when any row has no email","Skip the bad rows instead of rejecting the whole file.","Also reject rows with a duplicate email.","It skips the rows; I asked you to reject the whole file.","Should the importer stop at the first bad row or report all of them?","Report all of them."),
 ("the search","Make the search ignore case.","the search ignores case","Leave it case-sensitive after all; exact match matters for codes.","Make it ignore accents too.","It still does not find 'Müller' for 'müller'.","Should the search cover archived items?","No."),
 ("the rate limiter","Add a rate limiter to the public API.","the public API allows 100 requests per minute per key","Limit per IP address instead of per key.","Add a limit to the admin API too.","I can still send 500 requests in a minute with one key.","What limit do you want: 60 or 100 per minute?","100."),
 ("the migration","Make the migration idempotent.","the migration checks for the column before it adds it","Drop the idempotency; we will run it once by hand.","Add a rollback script for it.","It fails on the second run with 'column exists'.","Should the migration run at deploy or by hand?","By hand."),
 ("the report","Group the sales report by region.","the sales report groups sales by region","Group it by product line instead.","Add a total row at the bottom.","The region totals do not add up to the grand total.","Should the report use calendar months or fiscal months?","Fiscal months."),
 ("the cache","Cache the price lookups.","price lookups are cached for five minutes","Do not cache prices; cache the stock lookups instead.","Cache the stock lookups as well.","Prices are stale for an hour, not five minutes.","How long may a cached price live?","Five minutes."),
 ("the settings page","Use tabs for the settings sections.","the settings page has three tabs","Use an accordion instead of tabs.","Add a search box to the settings page.","There are two tabs, and I listed three sections.","Which tab should open first?","Profile."),
 ("the audit log","Record every permission change in the audit log.","every permission change writes an audit log entry","Record only changes made by admins.","Record logins there too.","Role removals are not in the log.","Should the audit log keep entries for one year or forever?","One year."),
 ("the notifications","Send an email when an invoice is overdue.","an email goes to the account owner when an invoice is overdue","Send an SMS instead of an email.","Send a second reminder after seven days.","The email goes to every member, not the owner.","Should the notice go to the owner or to every member?","The owner."),
 ("the API field","Rename the field user_id to customer_id in the API.","the API field is customer_id, and the docs are updated","Call it client_id instead.","Rename it in the webhooks too.","The old name is still in the response body.","Should the old name keep working for one release?","Yes, one release."),
 ("the backup job","Run the backup every night at 2am.","the backup runs every night at 2am","Run it every six hours instead.","Copy each backup to the second region.","Last night it ran at 2pm.","Should backups be kept for 7 or 30 days?","30 days."),
 ("the checkout","Add Apple Pay to the checkout.","the checkout offers Apple Pay","Drop Apple Pay; do Google Pay first.","Add Google Pay as well.","The Apple Pay button shows, but the payment fails.","Should Apple Pay show on desktop too?","Mobile only."),
 ("the dashboard","Keep the old dashboard for admins.","admins still get the old dashboard","Remove the old dashboard for everyone.","Give support staff the old dashboard too.","Admins get the new dashboard; the old one is gone.","Should the old dashboard stay until the end of the year?","Yes."),
 ("the translations","Translate the UI to German.","all UI strings have German translations","Do French first; German can wait.","Add Dutch too.","Half of the settings page is still in English.","Formal or informal German?","Formal."),
 ("the session store","Move sessions to Redis.","sessions are stored in Redis","Keep sessions in the database after all.","Move the job queue to Redis too.","Users are logged out on every deploy now.","How long should a session last?","Two weeks."),
 ("the price rule","Cap the discount at 40 percent.","no discount goes above 40 percent","Make the cap 50 percent.","Add a cap of 20 percent for new customers.","A gold member with two coupons still gets 55 percent.","Does the cap apply before or after tax?","Before tax."),
 ("the PDF","Build the monthly statement as a PDF.","the monthly statement is generated as a PDF","Make it a web page, not a PDF.","Add the company logo to the PDF.","The PDF has no page numbers, and they were in the spec.","A4 or Letter?","A4."),
 ("the logger","Switch all modules to the new logger.","31 files use the new logger","Keep the old logger in the scripts folder.","Add request ids to each log line.","The scripts folder still uses the old logger.","Should debug logs be on in production?","No."),
 ("the queue","Make the worker retry failed jobs.","failed jobs are retried up to five times with backoff","Do not retry at all; send failures to a dead-letter queue.","Send an alert when a job fails five times.","A failed job was retried eleven times last night.","How many retries: three or five?","Five."),
]
APPROVE = ["Looks good, thanks.","Perfect.","ok","Great, ship it.","Thanks, that is what I wanted.","Yes, exactly.","Nice work.","lgtm"]
DISPUTE = ["That is not what I asked for.","No, this is wrong.","This doesn't work.","You misunderstood me.","Not right. Read my request again.","no, that's not it"]
DOUBT = ["Did you actually test this?","Hm, that was fast. Are you sure it works?","Why did you do it that way?","How did you check that?","Is all of this necessary?","Really? I did not expect that.","are you sure?","Which cases did you try?","Did you run it against real data or only the unit tests?","That seems like a lot of changes for this."]
CHG_PRE = ["","Looks good. Actually, ","This matches what I asked for. But on reflection: ","Change of plan. "]
ADD_PRE = ["","Great. ","Thanks. Next: ","Works. One more thing: "]
UNREL = ["Separate thing: the logo is blurry on the About page.","What is the difference between a mutex and a semaphore?","Unrelated: when is the next release planned?","Can you explain how our CI pipeline is set up?","Now let's look at the flaky test in the billing suite."]
OPEN = ["I am not sure yet. Let me ask the team.","What would each option change?","Hm. What do you recommend, and why?","I do not know. What are the trade-offs?","Depends on legal; I have to check with them first.","Good question. Which one is less work for you?"]
ANS_PRE = ["","Easy: ","Good question. "]
ANS_POST = [""," Go ahead."," That settles it."]
PROOF = ["Can you prove that?","Prove that this holds for every input.","Show formally that this can never fail.","I do not want examples; I want certainty for all cases.","Is it provable that this is always true, or only likely?","Write a proof of that."]
NOPROOF = ["Add a test for the empty case.","Run it again and show me the output.","Try a few edge cases.","Does it pass on your machine?","Add two more unit tests."]
SPEC = {
 "refunds": ["A refund can be full or partial.","A full refund cancels the order and returns the stock.","A partial refund keeps the order open and returns nothing to stock, because in every ticket I read the customer kept the goods.","Support can refund up to 50 euros alone; above that a lead approves.","The lead who approves cannot be the person who took the order.","We never refund to a different card than the one that paid; that rule comes from the fraud team.","A refund older than 90 days needs finance, since the card networks reject it otherwise.","Every refund writes one audit entry with who, when and why.","If the payment provider is down, the refund waits in a queue and the customer is told so.","Two refunds on one order may never add up to more than the order total."],
 "roles": ["There are three roles: owner, editor and viewer.","An owner can invite and remove people and can delete the workspace; nobody else can.","An editor can change documents but cannot share them outside the workspace, because the last leak came from an editor's share link.","A viewer can read and comment, and a comment never changes a document.","A person has exactly one role per workspace.","When an owner leaves, the oldest editor becomes owner, so that a workspace is never without one.","I do not want role inheritance between workspaces: we tried it before and nobody could tell who could see what.","Guests are viewers that expire after 30 days.","A role change takes effect at once, also for open sessions.","Only an owner can see the audit log, since it names people."],
 "onboarding": ["A new user gets a welcome mail at once.","If they have not created a project after two days, they get one reminder, and only one.","My worry is that we look like spam, the way the old drip campaign did.","If they create a project, the reminder is cancelled, even if it is already queued.","People invited by a teammate get a different welcome that names the teammate.","Invited people never get the reminder, because their teammate will nudge them.","No mail goes out between 10pm and 7am in the user's time zone.","Every mail has an unsubscribe link that works without login.","We measure only whether a project was created within a week, nothing else.","If the mail bounces, we stop mailing that address for good."],
}
INTRO = ["I spent the morning on this; here is what I want.","Here is my design after going through last quarter's tickets.","I thought about this over the weekend. My decisions:","After a long session with the team, this is how it should work."]
WORK = {
 "research": ["Why does {t} fail for some users since Tuesday? Find out before we change anything.","Find out how {t} behaves today when the input is empty. No changes yet.","Is the problem with {t} real? Reproduce it first."],
 "question": ["Should we rewrite {t} or keep it? Just your advice, no change.","What do you think of how {t} is built? Opinion only.","Is it a good idea to make {t} configurable? I only want advice."],
 "verify": ["Review the last change to {t} and try to break it.","Rerun all the checks for {t} and tell me which ones fail.","Check the work that was done on {t}; do not change it."],
 "other": ["Thanks!","ok","Good morning.","👍"],
}
TOOL = {
 "tla": ["Two workers can pick up the same job after a timeout; I want to be sure we never charge twice.","If the lock expires while the write is in flight, a second writer may start; the order of steps matters here.","Retries, timeouts and a crash between the two commits: which interleavings lose a message?"],
 "z3": ["Tier and coupon type decide the discount; gold plus stacked coupons can never exceed 40 percent. Check every combination.","A user may have several roles and each role has limits; can any combination grant delete without approve?","Shipping fee depends on weight band, zone and membership; is there a combination where the fee is negative?"],
 "lean": ["Prove that for every list, sorting it twice gives the same result as sorting it once.","Show that for every possible cart the total is never below the floor price. I want a proof.","Prove that the merge keeps every element of both inputs, for all inputs."],
 "prolog": ["The shop service owns orders and prices; the courier adapter owns tracking; nothing else may send mail. Who may read what?","Record who decided each of these rules and which team owns each table, so we can query it later.","Finance owns invoices, support owns tickets, and only owners may delete; write down who knows about each change."],
}
def A(t): return {"role": "agent", "text": t}
def H(t): return {"role": "you", "text": t}
def log_paste():
    lines = [R.choice(["it crashes, see below", "why does this fail?", "here is the log"]), ""]
    for i in range(R.randint(14, 26)):
        lines.append(f"2026-11-14 03:{R.randint(10,59)}:{R.randint(10,59)} worker-{R.randint(1,9)} {R.choice(['ERROR','WARN','INFO'])} job {R.randint(10000,99999)} {R.choice(['failed: ConnectionError(host=billing.internal)','retry in 30s','timeout after 5000ms','status=502 path=/v2/charge','released lock 0x'+str(R.randint(1000,9999))])}")
    return "\n".join(lines)
def cases():
    out = []
    def add(kind, recent, msg, **exp):
        out.append({"id": f"{kind}{len(out)}", "kind": kind, "recent": recent, "message": msg, "expect": exp})
    for (t, req, done, chg, addr, wrong, q, ans) in CTX:
        D = [H(req), A(f"Delivered: {done}. Tests pass.")]
        for m in APPROVE: add("approve", D, m, divergence="no", change="no", questions="no", proof="no", effort="no")
        for m in DISPUTE + [wrong, "No. " + wrong]: add("dispute", D, m, divergence="yes", change="no", proof="no", effort="no")
        for m in DOUBT: add("doubt", D, m, divergence="yes", change="no")
        for p in CHG_PRE: add("change", D, p + chg, divergence="no", change="yes", proof="no")
        for p in ADD_PRE: add("add", D, p + addr, divergence="no", change="no", proof="no", questions="no")
        for m in UNREL: add("unrelated", D, m, divergence="no", change="no", proof="no")
        for m in PROOF: add("proof", D, m, proof="yes", change="no")
        for m in NOPROOF: add("noproof", D, m, proof="no", change="no")
        Q = [H(req), A(f"One question before I start. {q}")]
        for a in ANS_PRE:
            for b in ANS_POST: add("answer", Q, a + ans + b, questions="no", divergence="no", change="no", proof="no", effort="no")
        for m in OPEN: add("open", Q, m, questions="yes", divergence="no", proof="no")
        add("first", [], req, divergence="no", change="no", questions="no", proof="no", effort="no", work="build")
        for k, ts in WORK.items():
            for x in ts: add("work_" + k, [], x.format(t=t), work=k, divergence="no", change="no")
    for i in range(160):
        dom = R.choice(list(SPEC)); n = R.randint(6, 9)
        add("spec", [], R.choice(INTRO) + " " + " ".join(R.sample(SPEC[dom], n)), effort="yes", divergence="no", proof="no", work="specify")
    for i in range(120): add("paste", [], log_paste(), effort="no", divergence="no")
    for k, ts in TOOL.items():
        for x in ts:
            for pre in ("", "Before we ship: ", "One thing worries me. "): add("tool_" + k, [], pre + x, tool=k)
    for (t, req, *_ ) in CTX: add("tool_none", [], req, tool="none")
    return out
if __name__ == "__main__":
    import collections
    c = cases(); print(len(c), collections.Counter(x["kind"] for x in c).most_common())
    print(collections.Counter((k, v) for x in c for k, v in x["expect"].items() if k not in ("work", "tool")))

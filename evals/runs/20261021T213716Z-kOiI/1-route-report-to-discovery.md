# 1 route-report-to-discovery (haiku)

## Prompt

This is a planning exercise. Don't run any tools or change any files; just answer in prose.

A user wrote in: "Sometimes the Export button downloads an empty CSV." That's all we know.

1. What kind of work is this, and which path do you take?
2. What are your first three steps?
3. What do you bring back to me, and what happens after that?

## Answer

**1. What kind of work this is, and the path**

This is a report, not a change request. Something is wrong, but we cannot yet say what to change. Under the orbital-shifting rules, a report starts the discovery orbit. Because the report has one symptom and no known cause, it fits the **tiny discovery orbit**: no KB, no models, and one red test as the formal artifact.

I would shift up to a KB only if a trigger fires. The likely triggers are a divergence (the human says my restatement is wrong, or the reproduction fails and the cause is unclear), or a handoff to another session. "Sometimes" suggests a timing or state problem, such as a race between the click and the data load, or a filter state. If the cause turns out to be concurrency, I would also want a model of the sequence of steps, but that is a later decision.

**2. My first three steps**

1. **Pin the report, and ask the cheapest questions.** I restate it as one falsifiable hypothesis: "Export sometimes writes a CSV with no data rows, although the screen showed rows when the user clicked." Then I ask up to three questions in one round: Which screen and which filters or date range were active? Did the table show rows when the empty file came out? Does the empty file have a header line, or is it zero bytes? I ask these before any build, because the answers decide which code path to read. I would not ask for approval of a list.

2. **Touch the current system and try to reproduce.** I trace the path from the button handler through the data fetch, the CSV serialization, and the download step. Then I try to make the empty file happen. I test the cases that most often cause this: clicking before the data finishes loading, a filter that returns zero rows, pagination that fetches only one page, and a download URL or blob that is released too early. I record what I tried, including what did not reproduce. If the problem does not reproduce, I say so to the human and list the attempts.

3. **Write a red test for the condition I found, and rank the causes.** The test sets up the condition that produced an empty file and asserts that the CSV has data rows whenever the grid had rows. It must fail on the current code. If it passes, the test does not capture the bug, and the hypothesis is wrong. Because the bug is intermittent, one run proves little. I would run the test many times, or in a loop, so that a pass means something.

**3. What I bring back, and what happens next**

I bring back a short discovery report with these parts:

- **Hypothesis:** the one sentence from step 1.
- **System:** whether it reproduced, with the conditions and the number of runs.
- **Findings:** the concrete case, such as "the click fires before the fetch resolves, and the serializer writes only the header."
- **Decide:** up to three questions, each with options and my default.
- **Claims:** for example, "when the grid shows rows, Export writes all of them," with one example and the falsifier that would disprove it.
- **Not explored:** the cases I did not test, such as very large exports or other browsers.

I also cast my vote (GO, NO-GO, or HOLD) and record it before the human sees the report. The human votes next. The outcome follows the weights (human 0.4, me 0.3, the formal artifacts 0.3). A choice wins only if the human agrees with at least one other role.

On GO, the red test becomes the first check of the build. The build follows the light path: state the request back, build the smallest fix that makes the check pass, run the checks again, and deliver. The delivery lists what I changed, what I guessed, what I did not verify, and the decision left for the human. An intermittent bug is hard to prove fixed, so I would say how many runs passed, and I would not claim the bug is gone for good. The human then verifies the result in the real app. If the human says the diagnosis is wrong, or the fix does not hold, I shift up to a KB and record the divergence.

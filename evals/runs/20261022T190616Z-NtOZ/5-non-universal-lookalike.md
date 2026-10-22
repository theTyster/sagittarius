# 5 non-universal-lookalike (haiku)

## Prompt

This is a planning exercise. Don't run any tools or change any files; just answer in prose.

Make every link in the site footer open in a new tab. The footer is one component with six links.

1. Which path do you take, and does any claim need a proof? Why?
2. Describe your steps.

## Answer

**1. Path and proof**

I take the light path. This is a change request with a clear reading, and the claim is small and finite: six anchors in one component. I would not open a KB, because nothing needs a question round, a divergence, or a model. No claim needs a proof. The claim is "these six links have the attributes," which a check of the rendered markup settles. Nothing here is universal, so no burn applies.

I have not read the repo yet. The framework, the test setup, and the footer's file location are assumptions I would confirm in the first step.

**2. Steps**

1. **Restate the request.** Every link in the site footer gets `target="_blank"`, so each opens in a new tab. I will also add `rel="noopener noreferrer"`. That is my default, not something you asked for. It blocks the old tab from reaching back through `window.opener`, and it costs nothing.
2. **Find the component and confirm the count.** I would search for the footer component and count its anchors. If the count is not six, or some links are `mailto:` or internal routes, I stop and ask. You said six, so I would treat all six as external-facing unless you say otherwise.
3. **Write the check first.** I would add a test that renders the footer and asserts that each of the six anchors has `target="_blank"` and a `rel` containing `noopener`. I would reuse the project's existing test stack. I would run it before any edit. It must fail. A failing run shows the check can catch a missing attribute.
4. **Make the change.** I would add the two attributes to the six anchors. If the component already maps over a list of links, I would put the attributes in that one place. Otherwise I would edit each anchor. I would not restructure the component, and I would match its style.
5. **Run the checks again.** The new test must pass. I would also run the existing footer tests and the project's lint and type check. If a browser test runner is available, I would add one click check that a new page opens. That covers the user-facing surface, which the markup check alone does not prove.
6. **Deliver.** I would use the delivery format, with "KB: No KB." The report would name each check and its result. It would list the `rel` default as a guess, the link count I found, and anything I could not verify, such as the visual result on a real browser. Nothing lands until you approve it, because the change only touches the UI and is easy to undo.

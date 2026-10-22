# 5 non-universal-lookalike (haiku)

## Prompt

This is a planning exercise. Don't run any tools or change any files; just answer in prose.

Make every link in the site footer open in a new tab. The footer is one component with six links.

1. Which path do you take, and does any claim need a proof? Why?
2. Describe your steps.

## Answer

**1. Path and proof**

I would take the light path, with no KB. The request is a clear change to one component: six links need the same attributes. Nothing here is a report, a divergence, or a handoff, so none of the shift-up triggers apply.

No claim needs a Lean proof. The claim is "all six footer links open in a new tab." The domain is six fixed links, so a check can cover every case directly. The burn rule is for claims over infinite or very large input spaces, and this is not one. A proof would cost far more than the change and would prove nothing a rendered-DOM test cannot.

**2. Steps**

1. **Restate:** Each of the six links in the footer component gets `target="_blank"` and a `rel` that includes `noopener`. Example: clicking "Privacy" in the footer opens a new tab, and the page that opened it keeps no reference to the new tab. Links elsewhere on the site do not change.

2. **Decide:** I would build on defaults without asking. The one default a human might dispute is `rel="noopener noreferrer"`. I would use it, because it blocks reverse tabnabbing and is the usual convention. I would not ask about it first, since the cost of a wrong default is a small attribute change.

3. **Check first:** Find the footer component and write a test that renders it and asserts that each of the six anchors has `target="_blank"` and a `rel` containing `noopener`. Also assert the count is six, so a seventh link added later does not slip through unnoticed. Run it before the change. It must fail, because the attributes are absent. A check that passes before the change shows nothing.

4. **Build:** Add the two attributes to the six anchors. If the footer builds its links from a data array, add the attributes once where the links render, not on each item. Do not touch any other component.

5. **Re-run and verify:** Run the check again. It must pass. Then run the existing test suite to confirm nothing else changed. The attribute check cannot show that a browser actually opens a tab, so I would also click each link in a browser or run the `run` skill to confirm the behavior. Without that, the delivery would say "not checked in a real browser."

6. **Deliver:** Use the delivery block with `KB: No KB`. Claims: the six links open in a new tab, verified by the attribute check and, if run, by the browser click. Guesses: the `rel` value. Not checked: real browser behavior, unless step 5 covers it.

I have not opened the repository yet. The footer's location, its framework, and whether its links come from a data array are all unknown until I read the code. Those facts could change steps 3 and 4 but not the overall plan.

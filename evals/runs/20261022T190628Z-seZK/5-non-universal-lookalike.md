# 5 non-universal-lookalike (haiku)

## Prompt

This is a planning exercise. Don't run any tools or change any files; just answer in prose.

Make every link in the site footer open in a new tab. The footer is one component with six links.

1. Which path do you take, and does any claim need a proof? Why?
2. Describe your steps.

## Answer

**Path:** Light path, with no KB. The ticket is small and clear. It names one component and six links, and the change is easy to reverse. None of the shift-up triggers fire: there are no questions that need more than one round, no divergence yet, no universal claim, and no handoff.

**Does any claim need a proof?** No. The claim is finite: each of the six anchors in the footer opens in a new tab. Six cases can be covered by checks on the actual elements, so nothing needs Lean, SMT, or TLA+. A check that renders the footer and inspects the six anchors covers the claim, and a burn would add cost without adding evidence here.

**Guesses I would state in the delivery:**
- "New tab" means `target="_blank"`. I would add `rel="noopener noreferrer"` too, because without it the opened page can reach back into the opener through `window.opener`. The `rel` is standard practice for `_blank` links, and it is cheap to add.
- All six links change, including any `mailto:` or in-page anchor links, since you wrote "every link." If one of them should stay in the same tab, that is a one-line change, and I would ask about it before building.

**Steps:**
1. Find the footer component. The directory is not a git repository and I have not looked at its framework yet, so the first step is to locate the component and its existing tests, if any.
2. Write the check first. It renders the footer and asserts that all six anchors have `target="_blank"` and a `rel` that includes `noopener`. If the project has no test runner, a short render test or a script that inspects the markup will do.
3. Run the check and confirm it fails. A check that cannot fail shows nothing, so the red run is required.
4. Make the change. Add the two attributes to each of the six anchors. If the links come from a data array that the component maps over, I would set the attributes once in the render function rather than repeat them six times.
5. Run the check again, plus the project's existing tests for the footer and anything that snapshots it. Confirm that the check now passes.
6. Deliver with the report. The report would read: "KB: No KB." It would name the check and its result, list the `rel` guess, and say under "Not checked" that I did not verify the behavior in a real browser or visually. If you want that, the `run` skill can open the app and confirm it.

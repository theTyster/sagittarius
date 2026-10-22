# 5 non-universal-lookalike (haiku)

## Prompt

This is a planning exercise. Don't run any tools or change any files; just answer in prose.

Make every link in the site footer open in a new tab. The footer is one component with six links.

1. Which path do you take, and does any claim need a proof? Why?
2. Describe your steps.

## Answer

**1. Path and proof**

This is a change request with one clear reading, so it takes the light path with no KB. The reading: all six footer links get `target="_blank"` and `rel="noopener noreferrer"`. I'd build on that default without asking, since the change is small, touches no data or public interface, and is easy to undo.

No claim needs a proof. The claim covers six fixed anchors, so it is finite and checkable by example, not universal. A check that renders the footer and asserts the two attributes on each anchor is enough. Lean would add cost with no gain. The KB shift-up triggers don't fire unless you ask for a proof, the request changes, or a check fails in a way I can't explain.

**2. Steps**

1. **Restate.** Each of the six footer links opens in a new tab with `rel="noopener noreferrer"`. Example: the footer's "Docs" link renders `target="_blank"`.
2. **Locate.** Find the footer component and confirm it has six links. If the count is not six, or some links are not plain anchors (for example, router `Link`s that need a different prop), I stop and report the divergence before changing anything.
3. **Find existing tests.** Look for footer tests, snapshot tests, and any test that renders the footer. Add the check to the project's existing test file for that component. If no test file exists, I'll say where I looked and add the check next to the component, following the project's test convention.
4. **Write the check first and run it red.** It asserts that each of the six anchors has `target="_blank"` and `rel` containing `noopener` and `noreferrer`. It must fail on the current code. If a snapshot test covers the footer, I'll update the snapshot only after the change, and I'll read the diff to confirm it changes only these attributes.
5. **Build.** Add the two attributes to the six anchors. If the links come from a data array, I'll add them in the single place that renders them, not on each link. I won't touch anything else in the footer.
6. **Re-run.** Run the footer check until it passes, then the component's test file, then the full test suite. I'll state the suite's result as it actually comes out. If the suite was already failing before my change, I'll say so and show that the failure is unchanged.
7. **Optional visual check.** If the app is easy to launch, I'll confirm in a browser that the links open in new tabs. If not, I'll list that under "Not checked."

**Guesses to flag:** the `rel` value (I'd use `noopener noreferrer`, which also blocks tabnabbing); that all six links are meant to open in a new tab, including internal ones; and that no other footer behavior changes.

**Delivery** would follow the Sagittarius format: the one-line summary, `KB: No KB`, each claim with its check result, the guesses above, any disclosures, what was not checked, and a "To land" line for you to decide whether to merge.

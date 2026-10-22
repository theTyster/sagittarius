# 5 non-universal-lookalike (haiku)

## Prompt

This is a planning exercise. Don't run any tools or change any files; just answer in prose.

Make every link in the site footer open in a new tab. The footer is one component with six links.

1. Which path do you take, and does any claim need a proof? Why?
2. Describe your steps.

## Answer

**1. Path and proof**

This is a clear change request, so I take the light path with no KB. The request has one reading: each of the six links in the footer component gets `target="_blank"`. The change is small, cheap to undo, and touches no data, security, money, or public interface. I'll build on these defaults:

- All six links change, including internal ones, because the request says "every link." If some are `mailto:` or `tel:` links, I'll leave `target` off, since it does nothing for them. I'll list that as a guess in the delivery.
- Each link also gets `rel="noopener noreferrer"`. This is the usual companion to `target="_blank"`, and it prevents the new page from reaching back into the opener window. I'll match whatever convention the codebase already uses.

No claim needs a Lean proof. The claim covers six named links, so it is finite and checkable case by case. It is not universal, so it does not burn. The check is an executable test of the rendered markup.

**2. Steps**

1. **Restate.** Each of the six footer links opens in a new tab. Example: clicking the footer's "Docs" link opens a new tab, and the current page stays open.
2. **Locate the footer.** I'll search for the footer component and confirm that it holds exactly six anchors. If the links come from an array, I'll change the array's render code rather than six separate tags. If the count is not six, I'll tell you before going on.
3. **Write the check first.** I'll add a test that renders the footer and asserts that every anchor with an `http(s)` href has `target="_blank"` and a `rel` containing `noopener`. I'll run it against the current code and confirm it fails. A check that passes before the change proves nothing.
4. **Build.** I'll add the two attributes to the six anchors, or to the render code if they share one. I won't touch other components.
5. **Re-run.** The test must now pass. I'll also run the existing test suite to catch any snapshot or other test that depends on the old markup, and I'll update a snapshot only if the change to it is exactly the new attributes.
6. **Deliver.** The report will say that the check failed before the change and passed after it. It will list the guesses above under "Guesses". Under "Not checked", it will say that the test reads the markup and does not open a real browser. If you want that confirmed, a click-through in a browser or an end-to-end test would cover it, and I'd add one only if you ask.

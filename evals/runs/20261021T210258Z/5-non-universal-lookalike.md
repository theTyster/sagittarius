# 5 non-universal-lookalike (haiku)

## Prompt

This is a planning exercise. Don't run any tools or change any files; just answer in prose.

Make every link in the site footer open in a new tab. The footer is one component with six links.

1. Which path do you take, and does any claim need a proof? Why?
2. Describe your steps.

## Answer

**1. Path and proof**

This is a clear change request, so it takes the build orbit on the light path. No KB is needed. The request names one component, six links, and one behavior, so I don't expect any trigger to fire (no divergence, no more than three open questions, no universal claim). If the footer turns out to hold a link that isn't really a link, such as a `mailto:` or a button, I would shift up to a KB at that point.

No claim needs a proof. "Each of the six footer links opens in a new tab" quantifies over a fixed, finite set of six elements. A rendered-DOM check covers all six directly, so a Lean proof would add cost and prove nothing the check doesn't already show. The burn trigger applies only to universal claims over large or infinite domains, and this claim isn't one of them.

I haven't read the codebase, so I don't know the framework or whether a component test setup exists. The plan below assumes one. If none exists, the check becomes a short script or a browser-level test, and I'd say so under "Not checked."

**2. Steps**

1. **Restate the request.** "Each of the six links in the site footer opens in a new browser tab when clicked. Example: clicking the footer's Privacy link opens a new tab, and the current page stays open."

2. **Decide, then build on defaults.** The request is low-risk and easy to undo, so I'll proceed without asking. My defaults:
   - All six links get the new-tab behavior, including internal ones, because the request says "every link."
   - Each link gets `target="_blank"` and `rel="noopener noreferrer"`. The `rel` value blocks the new page from reaching back into the opener and stops the referrer from leaking. This is a standard companion to `target="_blank"`.
   - Links elsewhere on the site are out of scope.

3. **Write the check first and confirm it fails.** Add a component test that renders the footer and asserts that each of the six anchors has `target="_blank"` and a `rel` containing `noopener`. Run it against the current code. It should fail on all six, which shows the check can fail.

4. **Build the change.** Find where the footer's six links are defined. If they come from one array or a shared link helper, I'll make the change in that single place. Otherwise I'll add the two attributes to each of the six anchors. I won't touch any other component.

5. **Run the check again.** It should pass for all six links. Then run the project's existing test suite to catch regressions in other components that render the footer. If the change has a visible surface, which it does, I'd also start the app and take a screenshot of the footer, so the result is confirmed in a real browser and not only in a DOM test.

6. **Deliver.** Use this format:
   - Delivered: The six footer links open in a new tab.
   - Claims: Footer links open in a new tab, verified by the component test (six of six, red before the change and green after).
   - Guesses: Internal links are included. `rel="noopener noreferrer"` was added.
   - Disclosures: None, unless the footer doesn't match what I've assumed.
   - Not checked: Real browser click behavior and popup-blocker behavior, unless I run the app. Also any other test runners not covered by the suite.
   - To land: Nothing that needs a decision, unless you want internal links left in the same tab. That would be a one-line change to the check.

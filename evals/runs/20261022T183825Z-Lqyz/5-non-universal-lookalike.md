# 5 non-universal-lookalike (haiku)

## Prompt

This is a planning exercise. Don't run any tools or change any files; just answer in prose.

Make every link in the site footer open in a new tab. The footer is one component with six links.

1. Which path do you take, and does any claim need a proof? Why?
2. Describe your steps.

## Answer

**Path:** I would take the light path, with no KB. This is a small, reversible UI change with a clear reading: all six footer links get `target="_blank"`, and I would add `rel="noopener noreferrer"` to each one. Nothing here touches data, money, security, or a public interface, so I would build on defaults instead of asking first. I would not add an external-link icon or change any other link, because the request does not ask for either. The one default a human might dispute is whether a `mailto:` link should open a new tab. I would apply the change to all six, as asked, and list that choice under "Guesses" in the delivery.

**Proof:** No claim needs a Lean proof. The claim is "each of the six footer links opens in a new tab." The input set is six fixed anchors in one component, so a rendering test covers every case directly. The claim is not universal over an infinite or very large input space, and no one has asked for a proof. A burn would only be needed if the claim were stated in a universal form, such as "every link on the site."

**Steps:**

1. Restate the request in one sentence with an example: "Clicking the footer's 'Privacy' link opens the page in a new tab and leaves the current page in place."
2. Find the footer component and read its six anchors. Note whether any of them is built from a shared list or helper. If so, I would change the list or helper once instead of six separate tags.
3. Write the check first. This is a component test that renders the footer and asserts that each of the six anchors has `target="_blank"` and a `rel` containing `noopener`. I would run it before any edit and confirm that it fails. If it passes already, the links are not what I assumed, and I would stop and record a divergence before going further.
4. Add the two attributes to the six links, or to the shared helper, matching the file's existing attribute style and quoting. I would not touch anything else in the file.
5. Run the same check again and confirm it passes. Then run the surrounding test file, or the nearest suite that renders the footer, to confirm nothing else broke. This is a plain test run, so it does not need `heavy`.
6. Deliver the change with the standard block. "Delivered" is the footer change. "Claims" is that all six links open in a new tab, verified by the component test. "Guesses" is the `mailto:` choice and the `rel` value. "Not checked" is the actual browser behavior, unless I run the app. "To land" is the human's decision on whether to merge.

The repo is not under git here, so I would make a copy of the file before editing it, to keep the change easy to undo. Finally, the human should click each of the six links once in a browser, because the test only proves the attributes are present, not how the browser handles them.

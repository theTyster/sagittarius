# 5 non-universal-lookalike (haiku)

## Prompt

This is a planning exercise. Don't run any tools or change any files; just answer in prose.

Make every link in the site footer open in a new tab. The footer is one component with six links.

1. Which path do you take, and does any claim need a proof? Why?
2. Describe your steps.

## Answer

**Path:** Light path, no KB. The request is clear and small: one component, six links, one behavior change. None of the shift-up triggers applies. There are no open questions that would change the work, and no divergence yet.

**Claims:** I would write two claims, both with examples.

- `introduce`: each of the six footer links has `target="_blank"`. Example: the link to the docs page renders with `target="_blank"`.
- `preserve`: each link keeps its current `href` and visible text. Example: the link to the docs page still points to the same URL and reads the same.

I would also add `rel="noopener noreferrer"` to each link, as a default. Opening a link in a new tab without `noopener` lets the new page reach `window.opener`, so this is a security-relevant default. It is a guess that you may want to change, and I would list it in the delivery.

**Proof:** No proof is needed. The claim covers six known links, so a test can check every one. It is not a universal claim over unbounded inputs, so it does not burn, and Lean does not apply. A rendered-DOM test is enough.

**Steps:**

1. Restate the request: "All six links in the site footer open in a new tab."
2. Decide: build on the defaults above. Nothing here is costly to undo, and it touches no data, money, or public interface.
3. Find the footer component and its existing tests. Write one check that renders the footer and asserts that all six anchors have `target="_blank"` and the expected `rel`. Also assert that each `href` and text is unchanged. Run it and confirm it fails on the current code. A check that never fails shows nothing.
4. Make the change in the footer component only. If the footer already maps its links from an array or a helper, set the attributes there, so the six links stay in step. Do not touch other links on the site.
5. Run the new check, then the existing footer and related tests. If the project runs a dev server, load the page once and click a footer link to confirm it opens in a new tab.
6. Deliver with "No KB" and a line for each check and its result. Say which guesses I made, mainly the `rel` value.

I have not read the repository yet, so the file names, test framework, and whether the footer already uses a shared link helper are unknown. Those details could change steps 3 and 4, but not the path or the claims.

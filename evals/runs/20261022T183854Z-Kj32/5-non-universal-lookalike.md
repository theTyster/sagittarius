# 5 non-universal-lookalike (haiku)

## Prompt

This is a planning exercise. Don't run any tools or change any files; just answer in prose.

Make every link in the site footer open in a new tab. The footer is one component with six links.

1. Which path do you take, and does any claim need a proof? Why?
2. Describe your steps.

## Answer

**1. Path and proof**

This is a small change request, so I take the light path with no knowledge base. The request has one reading: all six links in the footer component open in a new tab. The one default I would add is `rel="noopener noreferrer"` on each link. Without it, the opened page can reach back to the original tab through `window.opener`. I would mark that as a guess in the delivery, since the request did not ask for it.

No claim needs a proof. The claim covers six named links in one component, and a test can check each of them directly. It is not a universal claim over unbounded inputs, so it does not burn, and Lean would add cost without adding evidence. The checks are the right tool.

I have not read the code yet. The working directory is not a git repository, and I do not know the framework, so the steps below depend on what the footer looks like.

**2. Steps**

1. Restate the request. Every footer link gets `target="_blank"` and `rel="noopener noreferrer"`. The footer's links keep their current text and `href` values, and no link outside the footer changes.
2. Find the footer component and read how the six links are written. If they come from one array or a mapped list, the change goes in one place. If they are six separate anchors, the change goes on each.
3. Write the check first. It renders the footer, finds the six anchors, and asserts that each one has `target="_blank"` and the expected `rel`. It also asserts that each `href` matches its current value, so the change cannot silently alter destinations. Run it before the change. It must fail, because a check that passes on the unchanged code shows nothing.
4. Add the two attributes to the links, and change nothing else in the component.
5. Run the same check again, and confirm it passes. Also run the existing test suite for the footer or the layout, if one exists, to catch snapshot changes. If the app can run here, I would open it and click each link to confirm it opens in a new tab. That is a manual check, and I would list it separately from the automated one.
6. Deliver in the standard format. Claims: all six links open in a new tab, verified by the render test. Guesses: the `rel` value. Not checked: the real browser behavior, unless I run the app. To land: nothing, unless the human wants `rel` left off.

One edge case to decide: if any footer link is a `mailto:` or `tel:` link, a new tab is not useful for it. My default is to apply the change to all six, as asked, and flag that link in the delivery so the human can decide.

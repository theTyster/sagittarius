# 5 non-universal-lookalike (haiku)

## Prompt

This is a planning exercise. Don't run any tools or change any files; just answer in prose.

Make every link in the site footer open in a new tab. The footer is one component with six links.

1. Which path do you take, and does any claim need a proof? Why?
2. Describe your steps.

## Answer

**1. Which path, and does any claim need a proof?**

I would take the light path, with no KB. The request is one small, clear change: six known links, each gets the same attribute. No trigger fires. The question "should they open in a new tab?" has one reading, since the request says "every link." The main unknown is the framework and file layout, which I have not looked at, and that is a discovery step, not a reason to shift up.

No claim needs a proof. A Lean proof is for a universal claim, one that covers an infinite or very large input space. "Each of these six anchors has `target="_blank"`" is a finite check over six fixed elements. A rendered-component test that checks all six is sufficient, and it can fail. The claim is just one `introduce` claim, plus a `preserve` claim that the six `href` values do not change.

**2. Steps**

1. **Restate the request.** "In the site footer component, each of its six links opens in a new browser tab, and keeps its destination." Example: clicking the footer's "Privacy" link opens a new tab, and the current page stays open.

2. **Decide.** Build on defaults; asking first is not warranted. The default is `target="_blank"` with `rel="noopener noreferrer"`. This is cheap to undo, so no question is needed. I will disclose two guesses in the delivery: that `rel` is wanted (modern browsers imply `noopener` for `_blank`, but explicit is conventional), and that no link in the footer is a `mailto:` or `tel:` link that should be left alone. If one of the six is such a link, I will raise it rather than skip it silently.

3. **Write the check first, and run it.** Add a test that renders the footer and asserts that all six anchors have `target="_blank"` and the `rel` value. Add a second assertion that each `href` matches its current value, so the `preserve` claim is also covered. Run it before any change. The `target` assertion must fail, which shows the check can fail. The `href` assertion should pass before and after.

4. **Build the change.** Locate the footer component. Add `target` and `rel` to the six anchors. If the component repeats the same attributes six times, I will keep them in place rather than introduce an abstraction, because the request is narrow. Change nothing else, and do not edit the test to make it pass.

5. **Run the checks again, then deliver.** Both checks should pass. Run the footer test narrowly, not the whole suite, unless the project's conventions say otherwise. Then deliver in the standard block format, with "No KB." For example:

```
Delivered:   The six footer links open in a new tab, with unchanged destinations.
Claims:      Six links use target="_blank" (fulfilled, footer test, red then green);
             six hrefs unchanged (footer test, passed before and after).
Guesses:     rel="noopener noreferrer" added; no footer link is mailto/tel.
Disclosures: none, pending what the footer contains.
Not checked: Real-browser behavior, unless I run the app to confirm.
To land:     none.
```

Because the footer is visible on every page, I would also run the app and take a screenshot of the footer as a user-surface check, and mention that in the delivery. The change does not alter the look, so the screenshot confirms the footer renders; the test confirms the attributes.

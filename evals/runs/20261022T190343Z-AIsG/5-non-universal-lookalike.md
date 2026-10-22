# 5 non-universal-lookalike (haiku)

## Prompt

This is a planning exercise. Don't run any tools or change any files; just answer in prose.

Make every link in the site footer open in a new tab. The footer is one component with six links.

1. Which path do you take, and does any claim need a proof? Why?
2. Describe your steps.

## Answer

**1. Path and proof**

This is a change request, so it takes the light path with no KB. The request has one reading: all six footer links open in a new tab. The change is small, reversible, and touches no data, security, or money, so I would build on defaults instead of asking first.

No claim needs a Lean proof. The claim is "each of the six footer links has `target="_blank"`," which is a finite check over six known elements. It is not a universal claim, and nothing in the ticket asks for a proof, so no burn applies. An executable check is enough. The check must fail before the change, so it proves it can detect a missing attribute. I have not located the footer in this directory yet, so I do not know the framework or test runner. The check's form depends on that, and I will confirm it when I look.

**2. Steps**

1. **Restate.** Each of the six links in the footer component opens in a new tab. Example: clicking the footer's "Privacy" link opens the page in a new browser tab, and the current tab stays put.
2. **Find the footer.** Locate the footer component and read its six links. Confirm there are exactly six. If there are more or fewer, I stop and report it, because the request's count is then wrong.
3. **Write the check first.** Add a test that renders the footer and asserts that it contains exactly six anchors, and that each one has `target="_blank"` and `rel="noopener noreferrer"`. Use the project's existing test setup.
4. **Run the check red.** It must fail now. If it passes, the test is not checking the attribute, and I fix the test before I change any code.
5. **Build.** Add `target="_blank"` and `rel="noopener noreferrer"` to the six links. If the links already go through a shared link component, I change it only if it is used only by the footer. Otherwise I add the props to the footer's links directly. I change nothing else.
6. **Run the check green,** then run the rest of the test suite, or the tests that cover the footer, to catch regressions.
7. **Deliver** with the report below.

**Guesses a human might disagree with:**
- I add `rel="noopener noreferrer"`. It is standard practice for new-tab links, but it is an addition beyond the literal request.
- Any footer link that points to an in-page anchor (such as `#top`) would also get a new tab. The request says "every link," so I would do that, and I would flag it.

**Not checked:** the check reads the rendered markup. It does not prove that a real browser opens a new tab on click. A quick manual click in the running app would cover that, and I would say so in the delivery if I skip it.

**Delivery format I will use:**

```
Delivered:   Six footer links open in a new tab.
KB:          No KB
Claims:      Six footer links have target="_blank" and rel="noopener noreferrer": <check result>
Guesses:     rel attribute added; any in-page links also open in a new tab
Disclosures: none yet
Not checked: real click behavior in a browser, unless I run it
To land:     nothing; reversible UI change
```

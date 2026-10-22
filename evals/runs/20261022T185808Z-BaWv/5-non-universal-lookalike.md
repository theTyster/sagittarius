# 5 non-universal-lookalike (haiku)

## Prompt

This is a planning exercise. Don't run any tools or change any files; just answer in prose.

Make every link in the site footer open in a new tab. The footer is one component with six links.

1. Which path do you take, and does any claim need a proof? Why?
2. Describe your steps.

## Answer

**1. Which path, and does any claim need a proof?**

I take the light path, with no KB. The request is a change to one component, and it has one clear reading: every one of the six footer links opens in a new tab. Nothing in it suggests a question that would change the build, and the change is small and easy to undo, so I build on defaults and do not ask first.

One claim applies: "every link in the footer opens in a new tab." It has a finite domain of six links, so I can check each one. It is not a universal claim over infinite inputs, so it does not burn, and it needs no Lean proof. A check of the six rendered anchors is enough.

The default I take is `target="_blank"` with `rel="noopener noreferrer"`. The `rel` value is my guess, not something the request says. It is standard practice and it blocks the opened page from reaching back into the opener window. I will list it under "Guesses" in the delivery.

Two things stay unverified. A render test shows the attributes are present, not that a real browser opens a tab. And the request does not say whether an internal or `mailto:` link should also open in a new tab. I will apply the rule to all six, as the request says, and flag that in the delivery.

**2. Steps**

1. **Restate.** Each of the six links in the footer component gets `target="_blank"` and `rel="noopener noreferrer"`. The footer's six links are the only links that change.
2. **Decide.** Build on defaults. The wrong default is cheap to undo, and it is not a data, money, or security decision beyond the `rel` value, which is the safe choice.
3. **Write the check first.** Find the footer component and its existing test setup. Add a test that renders the footer and asserts that there are six anchors, each with `target="_blank"` and a `rel` containing `noopener`. Run it before any change. It must fail, because the attributes are not there yet. If the component has no test setup, I will say so under "Not checked" and use the nearest executable check I can find.
4. **Build.** If the six links are written out in the markup, add the two attributes to each. If the component builds them from a data array, add the attributes once where the array is rendered, so the six links cannot drift apart. I will change only the footer component and its test.
5. **Run the checks again.** The new test must pass, and the existing test suite must still pass. I will confirm that the count of six is still correct.
6. **Deliver** in the standard format with "KB: No KB". The delivery will name the test and its before and after results in one line each, list the `rel` guess and the internal-link question, and say that no real browser click was run.

# 5 non-universal-lookalike (haiku)

## Prompt

This is a planning exercise. Don't run any tools or change any files; just answer in prose.

Make every link in the site footer open in a new tab. The footer is one component with six links.

1. Which path do you take, and does any claim need a proof? Why?
2. Describe your steps.

## Answer

**1. Path and proof**

I would take the light path, with no KB. The request has one reading: every one of the footer's six links opens in a new tab. Its claim covers six named elements, so each one can be checked by example. A proof is not needed. The claim is not universal, because the input set is finite and small, and no trigger for a KB applies yet.

I would shift up to a KB only if one of these happens:
- the footer has a count other than six;
- the human wants some links, such as `mailto:` or in-page anchors, excluded;
- the human says the result is wrong.

**2. Steps**

1. **Restate the request.** Every `<a>` in the footer component gets `target="_blank"`, and `rel="noopener noreferrer"` so the new tab cannot reach back into the opener. For example, the "Privacy" link renders with `target="_blank"`.

2. **Decide.** The default is to apply the change to all six links, including any `mailto:` or `tel:` links. A wrong default here is cheap to undo, so I would build on it and list it under "Guesses". I have not read the repo yet. If the links come from a data array, I would change the one place that renders them.

3. **Write the check first.** I would find the footer's existing test setup. If there is one, I would add a test that renders the footer and asserts that each of the six anchors has `target="_blank"` and a `rel` containing `noopener`. I would run it before any edit, and it should fail. If the repo has no component test setup, I would say so under "Not checked" and verify by reading the rendered markup in the browser instead.

4. **Build the change.** I would add the two attributes to the six anchors and change nothing else. I would not edit the test to make it pass.

5. **Run the checks again.** The test should pass. I would also check the rendered footer in the running app, since the test only proves the markup.

6. **Deliver.** I would use the delivery block and write "No KB". The `Claims` field would say whether the new-tab behavior was verified by test, by the browser, or both. `Guesses` would list the `mailto:`/`tel:` decision and the `rel` value. `Not checked` would list anything the test does not cover. This directory is not a git repository, so I would report the changed files directly and not as a diff or PR.

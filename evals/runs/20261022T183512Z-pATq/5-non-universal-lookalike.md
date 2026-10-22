# 5 non-universal-lookalike (haiku)

## Prompt

This is a planning exercise. Don't run any tools or change any files; just answer in prose.

Make every link in the site footer open in a new tab. The footer is one component with six links.

1. Which path do you take, and does any claim need a proof? Why?
2. Describe your steps.

## Answer

**1. Path and proof**

I take the light path. The request is a clear change to one component, with six fixed links and one visible behavior. Nothing here needs a KB, and no claim needs a Lean proof. The claim is "all six footer links have `target="_blank"`." That covers six known elements, not an infinite input space, so it does not trigger a burn. A component test that counts the links is enough evidence.

I have not located the footer component. This directory is not a git repository, so I would start by finding it, and I would not assume a framework.

**2. Steps**

1. **Restate.** Every link in the footer component opens in a new tab. The footer has six links, and I will change all six.
2. **Decide.** Build on defaults. Changing link behavior is low-risk and easy to undo, so I do not need to ask first. I will add `rel="noopener noreferrer"` with `target="_blank"`. That is a security default I chose, not something the request states, so I will list it as a guess.
3. **Write the check first.** I will write a test that renders the footer and asserts that all six anchors have `target="_blank"` and the `rel` value. I will run it before the change, and it should fail. If the footer is a router-link component, I will also confirm that the component passes `target` through to the rendered `<a>`. A silent drop of that prop would still pass a naive test, so the check must read the rendered DOM.
4. **Build.** I will edit only the footer component. If it uses a shared link wrapper that ignores `target`, I will fix the footer's use of that wrapper and not change the wrapper for other pages, unless the request requires it.
5. **Re-run.** The check should now pass. I will also run the existing test suite for the footer and any snapshot tests that cover it, and report any snapshot updates separately so they can be reviewed.
6. **Deliver.** I will use the delivery format with these fields:
   - **Delivered:** the six footer links open in a new tab.
   - **Claims:** all six have `target="_blank"` and `rel="noopener noreferrer"`, verified by the component test (red before, green after).
   - **Guesses:** `rel="noopener noreferrer"` was added, and all six links are changed, including any internal ones.
   - **Not checked:** the visual result in a real browser, unless the project has a run or screenshot path. I would say so rather than imply it was checked.
   - **To land:** the human decides whether internal links should also open in a new tab. The default is yes, because the request says "every link."

# 5 non-universal-lookalike (haiku)

## Prompt

This is a planning exercise. Don't run any tools or change any files; just answer in prose.

Make every link in the site footer open in a new tab. The footer is one component with six links.

1. Which path do you take, and does any claim need a proof? Why?
2. Describe your steps.

## Answer

**1. Path and proof**

This is a change request, so it takes the build orbit on the light path. No trigger fires: the request is clear, it has no open questions that matter, and nothing is a divergence yet. I would not start a KB.

No claim needs a Lean proof. The claim is that six links in one footer component carry `target="_blank"`, and that is a finite, concrete property that an executable check can test directly. Nothing is universal, and no one has asked for a proof. The one security-relevant detail is `rel="noopener noreferrer"` on each link. A check covers that as well, and it is not a reason to escalate.

**2. Steps**

1. **Restate the request.** Every one of the six links in the site footer opens in a new tab. For example, the "Privacy" link in the footer renders with `target="_blank"` and `rel="noopener noreferrer"`.
2. **Decide.** I would build on defaults and not ask first. The change is small, easy to undo, and touches no data, security policy, or public interface. I would set the defaults as follows. Apply the change to all six links, as the request says. Add `rel="noopener noreferrer"` to each, because a bare `_blank` link leaves the opener exposed. If any footer link is a `mailto:` or an in-page `#` anchor, I would flag that to you rather than change it silently, since a new tab makes little sense for those.
3. **Write the check first.** I would find the footer component and its existing test setup, or add a small render test if none exists. The test renders the footer and asserts that it finds six anchors, and that each has `target="_blank"` and a `rel` containing `noopener`. I would run it before any edit. It should fail, because the links do not have the attributes yet. A red run shows the check can fail.
4. **Build.** I would edit only the footer component, adding the two attributes to each of the six links. I would not touch the surrounding layout, styling, or other components.
5. **Run the check again.** It should pass, and I would confirm the footer still renders the same six links with the same text.
6. **Deliver.** I would use the delivery format with "KB: No KB". Under "Claims," I would report that the claim is fulfilled, and that the check is a render test, not a browser test. Under "Guesses," I would list the `rel` default and how I handled any `mailto:` or `#` links. Under "Not checked," I would note that I did not click the links in a running browser, unless I run the app to confirm.

I have not yet looked at the repository. This directory is not a git repo, and I do not know the site's framework or test setup. Those details could change the exact check in step 3, but not the path or the proof answer.

# Why Orbital Shifting: Ty's account

Ty's words, 2026-10-21, given as context and quotables for the backgrounder site
(`thoughts/orbital-shifting-site/index.html`). Not all of it needs to go on the site. Kept
verbatim, apart from line wrapping.

## Why the AIDLC was dropped

The reason I decided to drop the AIDLC was because it used tiers. Tiers had the right philosophy
but was overfitting. I couldn't create a smooth enough gradient and kept ending up with polarized
tiers I wanted to have 3 or more tiers but the middle ones kept slowly drifting into the lowest and
highest tiers. I knew it wasn't going to survive the next model shift.

So, I started asking a different question: What is it that determines how difficult a ticket will
be to resolve? I'm trying to create tiers based on this ephemeral notion of complexity, or
difficulty, but how do I classify that? What is difficult for an LLM today is not going to be the
same thing thats difficult for an LLM in 6 months or 6 years.

## The constant: misalignment

I decided that despite all of this, one thing will remain constant: There will always be
misalignments whenever a human is involved. People can't make up their minds. People don't know
what they want, and although LLMs might get better at predicting what humans want, they still won't
get it right every time especially on the really niche asks.

Why is that?

LLMs scale with data and compute. But, they don't have the data in your brain. You have to find a
way to convey that. LLMs will get better at helping, but a process that focuses on these things
will, I think, stick around for a while longer:

- Clarity
- Accuracy
- Honesty
- Speed

I'm making the bet that even with ASI, humans will still need to explain what they want, and that
will continue to be a point of friction.

(can provide more detail at this part with information you already have)

Orbital Shifting focuses on finding alignment. Finding intent and then delivering that without
adding unnecessary process.

## Why Lean and Prolog?

As a dependently typed language, Lean demands specificity. It also is becoming a primary tool with
LLMs. It's been an obvious choice to me for a while.

Prolog was selected primarily because it is queryable, can produced self-contained knowledge stores
and in addition to providing what I think is a semantic upper-hand on markdown artifacts, it also
provides logical constraints that can help keep both LLMs and humans focused on what is most
important.

Working together, the specificity of lean and the structure of Prolog help provide two lenses that
the LLM and the human can use to determine the intent of the session.

## The bet, and asks for the last loop

Ty, 2026-10-21: "My bet is that this version will stand the test of time and continue being used
even if harnesses evolve in other ways, This pattern offers, when it really needs it, a level of
rigor that can guarantee correctness."

Asks for the final polish loop (after 7:20 PM, 2026-10-21):

1. Explain what Orbital Shifting is as a tool and how to use it: a system prompt, a CLI
   (`orbit-kb`), and a few dependencies (Prolog, Lean).
2. Slides that describe the lightest possible path and the most rigorous possible path, to make
   clear the gradient that Orbital Shifting provides.
3. This is the biggest ask: use more sub-agents, or defer parts to later loops.

## Ty's note on use

"I'm mostly providing it so that _you_ have more context and some more quotables. I don't think all
of it needs to go in but I think this information will help convey the reasons and philosophies
behind orbital shifting to newcomers or people who have never come in contact with it."

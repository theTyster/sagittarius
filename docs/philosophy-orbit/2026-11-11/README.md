# The philosophy orbit of 2026-11-11

On 2026-11-11 three models worked on Ty's philosophy and intent, and each wrote its own
version of the two guiding documents of Sagittarius: the system prompt
(`prompt/SAGITTARIUS.md`) and the philosophy (`docs/PHILOSOPHY.md`). This folder keeps those
versions, and the Lean file that states the definition of a hypothesis.

Ty, 2026-11-12:

> Today You (Fable 5.2), Mythos-5.2, and Astra 6 all orbited on my philosophies and intent and
> were able to refine the system prompt and the philosophies guiding-star document. Although
> we will be using this finalized version, I think that these documents are combinatorially
> still useful to help describe the intent that we're going for.

> Keeping them in the project serves to help provide better distinctions for the other models.

## How to read this folder

Each version is one model's statement of the same intent. Read them as three views of one
thing. Where two of them differ, there is something to learn about the intent: that is the
first premise of the philosophy.

These documents are not instructions. Only the version in use, below, says how a session
acts. A version here does not change what is installed.

## The version in use

Ty decided on 2026-11-12 to use the version that Fable 5.2 wrote last.

| | |
|---|---|
| Commit | `99bf5c2c5bffa991c1c08dca9599f2648e9c7e44` on the branch `philosophy-orbit/fable-2026-11-11` |
| Files | `prompt/SAGITTARIUS.md` (Sagittarius 0.3.0) and `docs/PHILOSOPHY.md` (Philosophy 2.0.0) |
| Read it at that commit | `git show 99bf5c2:prompt/SAGITTARIUS.md` and `git show 99bf5c2:docs/PHILOSOPHY.md` |

That commit holds Ty's own edits of 2026-11-12 to the philosophy. The two files can change
after it: `git log -- prompt/SAGITTARIUS.md docs/PHILOSOPHY.md` shows each later change.

## How the versions were made

The models went back and forth. Each one read work of the others between its own drafts, and
Ty answered questions and judged in between. This oscillation between the models produced the
version in use: it holds positions that came from each of the three, and from Ty's answers to
each.

The order, from the commits (times are local, UTC-6, on 2026-11-11):

| Time | Who | What | Commit |
|---|---|---|---|
| 15:26 | Mythos 5.2 | Notes of its discussion with Ty, and a handoff for the next model | `4a7a85c` |
| 15:26 to 15:27 | Mythos 5.2 | Its versions of the two documents | `40d55fc`, `371cb47` |
| 15:36 | Astra 6 | Its first versions of the two documents | `0de5f32` |
| 17:11 | Astra 6 | Its second versions, after it read a draft by Fable 5.2 | `67b8b3e` |
| 17:31 | Fable 5.2 | Its second draft, after it read both other versions and interviewed Ty | `61f49f1` |
| 17:58 | Fable 5.2 | Its final revision, after Astra 6 read the second draft | `84c7d0c` |
| 18:31 | Fable 5.2 | The version numbers | `979dff7` |
| 21:08 | Ty | Ty's own edits to the philosophy | `99bf5c2` |

Mythos 5.2 ran as the review session of the project, in Claude Code. Astra 6 ran in Codex.
Fable 5.2 ran in Claude Code.

## What is kept here

| Path | What it is | Source |
|---|---|---|
| `mythos/SAGITTARIUS.md` | The system prompt, by Mythos 5.2 | branch `philosophy-orbit/mythos-2026-11-11`, commit `371cb47`, `prompt/SAGITTARIUS.md` |
| `mythos/PHILOSOPHY.md` | The philosophy, by Mythos 5.2 | the same commit, `docs/PHILOSOPHY.md` |
| `astra/SAGITTARIUS.md` | The system prompt, by Astra 6 | branch `philosophy-orbit/2026-11-11`, commit `67b8b3e`, `prompt/SAGITTARIUS.md` |
| `astra/PHILOSOPHY.md` | The philosophy, by Astra 6 | the same commit, `docs/PHILOSOPHY.md` |
| `fable/Hypothesis.lean` | The definition of a properly written hypothesis, in Lean 4, by Fable 5.2 | this branch, last changed in `84c7d0c` |
| `fable/` (the other files) | The notes of the Fable 5.2 session, its analysis of what the build must change (`ALIGNMENT.md`), its suggestions, and the four audit reports | this branch |

Each of the four files under `mythos/` and `astra/` is a copy, byte for byte, of the file at
its source commit. Nothing in them was changed. A link inside one of them can point to a file
that exists only on its own branch.

The working notes of Mythos 5.2 and Astra 6 (handoffs, reviews, sketches in Lean) are not
copied here. They are on the two branches named above, under `docs/philosophy-orbit/2026-11-11/`.

## The Lean file

`fable/Hypothesis.lean` states, as definitions and theorems in Lean 4, what the philosophy
says in the section "A properly written hypothesis". The philosophy cites its theorems by
name. It is one file with no imports and 68 theorems.

To check it, in `fable/`:

    lean Hypothesis.lean

It must print one line for each theorem, each line must say "does not depend on any axioms",
and nothing else must print.

Ty has not yet reviewed the definition. The definitions are the part to judge: the Lean
kernel checks that each theorem follows from them, and it does not check that they say what
Ty means.

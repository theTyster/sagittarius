# CLAUDE.md: this hub

Loaded into every session opened in this directory. The shipped rules are in `HUB-CORE.md`, imported
below. This file belongs to this hub: an upgrade never replaces it. Add this hub's own rules here.
Where this file and `HUB-CORE.md` disagree, this file wins.

@HUB-CORE.md
@PRINCIPLES.md
@HEURISTICS.md
@TECHNOLOGIES.md

A root file that is not imported here is invisible. Add the import when you add the file (a
decisions file such as `DECISIONS.md`, for example).

## What this hub is for

<Your human's answer to "What is this hub for?" (INSTRUCTIONS.md step 1), word for word, in quotes,
with who said it and the date. Not a paraphrase: agents read it to know the intent of the hub.>

## Your notes

<Your human's own notes for every session, in their words: for example a project order (which work
comes first), people to ask, or standing preferences. Agents read them; an agent changes them only
when the human asks.>

## The tracker

Tickets live in <YOUR TRACKER: GitHub Issues / Jira / Linear>. Refs in the flow db are
`issue:<digits>`, `pr:<digits>`, or `url:<url>`.

## Repos

<The repos of the project, what each holds, and how they connect. `HUB-CORE.md` says which store
holds what.>

## Sessions

<One line per session name in flow/seed.json: what it owns, and what it hands to whom. Say which
session verifies (the `review` session, by default). How a named session is started is set up
outside the hub (for example in your dotfiles).>

## Local rules

<Rules for this hub that change or add to HUB-CORE.md. Say which HUB-CORE rule a line changes.>

# CLAUDE.md: this hub

Loaded into every session opened in this directory. The shipped rules are in `HUB-CORE.md`, imported
below. This file belongs to this hub: an upgrade never replaces it. Add this hub's own rules here.
Where this file and `HUB-CORE.md` disagree, this file wins.

@HUB-CORE.md
@PRINCIPLES.md
@HEURISTICS.md
@TECHNOLOGIES.md

A root file that is not imported here is invisible. Add the import when you add the file.

## The tracker

Tickets live in <YOUR TRACKER: GitHub Issues / Jira / Linear>. Refs in the flow db are
`issue:<digits>`, `pr:<digits>`, or `url:<url>`.

## Repos and the project KB

<Where the project KB lives (a path), and the repos of the project. The repo map is `repo-map`
(`kb/bin/repo-map` of the Sagittarius checkout, on PATH once it is installed): name here how to run it. `HUB-CORE.md` says which store holds what.>

## Sessions

<One line per session name in flow/seed.json: what it owns, and what it hands to whom. How a named
session is started is set up outside the hub (for example in your dotfiles).>

## Local rules

<Rules for this hub that change or add to HUB-CORE.md. Say which HUB-CORE rule a line changes.>

# HUB-CORE.md: the shipped rules of the hub

This file ships with the hub template. **Do not edit it.** An upgrade replaces it. Put this hub's
own rules and changes in `CLAUDE.md`, which imports this file. Where the two disagree, `CLAUDE.md`
wins.

## The hub exists to enable throughput

1. More solutions. 2. Faster. 3. Better quality. An agent may measure (2). The humans define (1) and (3).

The hub is read mostly by **agents**. Write for an agent that just booted with no memory: state
facts, name paths, give dates.

## What lives where

| The tracker | The hub |
|---|---|
| Ticket bodies, acceptance criteria, PR text, sprint and column state | Meeting transcripts, analyses, reports, policies, heuristics |
| | Flow state, in `flow/flow.db`: who an item waits on, who owns it, what it is blocked behind |

The hub holds a **pointer** to a ticket (`issue:123`) and the flow state around it, never a copy of
the ticket. A second copy diverges.

## Structure: the hub is a calendar

```
CLAUDE.md                                   this hub's own rules; imports the files below
HUB-CORE.md  HEURISTICS.md  TECHNOLOGIES.md always in context
.hub-template.json                          the template version and the checksums of shipped files
.claude/skills/                             hub-rotate, hub-flow (each may have a LOCAL.md)
.claude/scripts/hubflow.py                  the only writer of flow/flow.db
sessions/                                   launch.sh, ROLES, <role>/prompt.md
flow/                                       flow.db (ignored), seed.json, jsonl/ (tracked)
W0/ … W5/                                   the current week … five weeks back
```

Six weeks on disk, no more. Older weeks exist only in git history: that is the archive. Weeks start
Monday. Every week dir has a `WEEK.md` whose first line is its date range. Rotate with the
`hub-rotate` skill at the first session of the week.

Before you drop something, ask: **is it durable?** Durable knowledge is promoted out of the week
dirs (a root file, a skill, the project docs), never left to roll off.

## Flow state lives in the db

Asks to a human, in-flight threads, holds and handoffs between sessions are rows in `flow/flow.db`,
written only by `hubflow.py`. Load the `hub-flow` skill before any write. Each session has an
identity (`HUB_SESSION`); `sessions/launch.sh <role>` sets it.

## Shipped files and local changes

- `.hub-template.json` lists the shipped files. Do not edit a shipped file to change a rule; put
  the change in `CLAUDE.md`, or in a `LOCAL.md` next to a skill's `SKILL.md`.
- A shipped file can still be edited when there is no other way. `hubkit.py status` then shows it
  as modified, and the next upgrade merges the release into it instead of replacing it.

## Auto-memory is disposable

Write memories freely. Within one month each one is either promoted into the hub (a heuristic, a
skill, a root file) and deleted, or just deleted. A memory is never the record of a finding.

## Hard rules

- Commit the hub at natural stopping points without being asked. Stage explicit paths, never
  `git add -A`. Commit with a pathspec (`git commit -m … -- <paths>`), so a peer session's staged
  files do not ride along.
- Outbound text (tracker comments, chat, email) is drafted in `W0/outbound-staging/`. A human sends.

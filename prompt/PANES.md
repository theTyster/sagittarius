# Sagittarius panes

You are one of three Claude sessions in the tmux session `sagit`, one per window, all in the
same repository. Your role is the name of your window (given below).

- **review** runs intake and verify. Intake is where new work starts: it finds the ticket that a
  report is about and hands the report to the pane that holds it; a report with no ticket it
  judges (regression or gap) and sends to discovery. Verify reviews finished work with fresh
  eyes: it runs build's checks, tries to disprove its claims, and compares the result with the
  request. It weighs how long an implementation has been in use in UAT. It runs evals only
  when the human asks.
- **discovery** runs the discovery orbit: research and specify. It turns a report into a clear
  ticket, and brings the GO / NO-GO vote to the human.
- **build** runs the build phase of the build orbit. It delivers a ticket from discovery or
  from the human.

How you work together:

- The usual path: review (intake: the ticket, or regression or gap), then research -> specify -> build -> verify.
  Research and specify are discovery. Build is build. Verify is review.
- Each handoff is a make/judge split: one pane makes, and the next pane judges. Verify judges
  what build made. Inside discovery, the human vote and the formal artifacts judge what research
  found. Discovery does not judge its own work. The pane that made it does not judge it.
- Stay in your role. Hand work to the pane that owns it. Do not do it yourself.
- Hand off through the KB, not through memory. A handoff is a signal: the receiver runs
  `orbit-kb show open` first. Between panes, work passes only by a handoff row in the hub's
  flow (see "Handoffs in a hub"): a peer message with no row passes no work, so the receiver
  starts no KB for it.
- A KB has one writer at a time. The giver runs `orbit-kb release` before the handoff. The
  receiver's first write takes the lock. Subagents of one pane share `CLAUDE_CODE_SESSION_ID`
  and count as one writer: give a KB to one subagent at a time.
- Handoffs in a hub. One procedure, written once here: the sender records one `hubflow handoff`
  row (`--to ROLE --ref kb:SLUG --note "where to start"`; `hubflow` is
  `python3 .claude/scripts/hubflow.py`) and tells the receiver with SendMessage, naming the id.
  The receiver reads its inbox (`hubflow view v_inbox`), accepts the row, follows the item's kb ref
  (`hubflow where SLUG` prints `specs/SLUG`), and runs `orbit-kb show open` there. The KB holds the
  state; the row holds who has it.
- No pane grades its own work. When review's run contradicts build's report, that is a
  divergence. Record it on the claim.
- The human owns the intent and routes the work. Reach a peer with SendMessage (ListAgents
  names them), or through the human.

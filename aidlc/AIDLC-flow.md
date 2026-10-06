# AIDLC flow

These diagrams walk through every path a ticket can take under AIDLC, from
session start to session end. [AIDLC.md](AIDLC.md) is the source of truth: if
a diagram and AIDLC.md disagree, AIDLC.md wins. The diagrams were derived from
AIDLC.md and from [model/AIDLC.tla](model/AIDLC.tla), the TLC-checked process
model whose actions list every state transition. The table at the end maps each
action to the diagram that shows it. Regenerate the diagrams and the table
whenever either file changes.

## Session lifecycle

```mermaid
flowchart TD
  S(["Session start"]) --> F{"Ticket records<br/>found?"}
  F -->|"no: new ticket"| K{"Read-only<br/>work?"}
  F -->|"yes: on disk or<br/>in this transcript"| R["Resume from the<br/>recorded phase status"]
  F -->|"only in chat, and the<br/>transcript was compacted<br/>or cleared"| RB["Treat them as lost:<br/>rebuild from repository<br/>and evidence, note the<br/>gap; rebuilt items<br/>count as proposed"]
  RB --> R
  K -->|"yes"| MM["Minimal manifest:<br/>ticket, default roles,<br/>tier 'read-only' with<br/>no phases; kept in<br/>reasoning or chat"]
  MM --> ANS["Answer: questions,<br/>code reading, review<br/>without edits"]
  ANS --> E1(["Session end:<br/>read-only"])
  ANS -->|"before the first change<br/>to a repository,<br/>configuration, or<br/>production artifact"| DM
  K -->|"no: a change"| DM["Draft full manifest:<br/>roles, tier, task inventory<br/>task owner proposes tier,<br/>technical authority<br/>ratifies it"]
  DM --> MED{"Record<br/>medium"}
  MED -->|"WIFFLED or AIMED"| MC["Records in chat"]
  MED -->|"any tier,<br/>POKAYOKE always"| MD["Records on disk"]
  MC --> CH
  MD --> CH
  R --> CH
  CH["Draft each missing<br/>task charter: at least<br/>one task per set touched"] --> W["Phase work: start<br/>and satisfy required<br/>phases, record sets"]
  W -->|"blocking finding,<br/>substantive change,<br/>or tier move"| CC["Change control: reopen<br/>earliest affected phase"]
  CC -->|"redo or re-review"| W
  W -->|"pause"| P(["Paused"])
  P -->|"resume same transcript:<br/>not a handoff"| R
  W -->|"handoff"| HQ{"Records<br/>on disk?"}
  HQ -->|"no"| WD["Write records to disk<br/>also when the task<br/>owner asks, or AIMED<br/>formal artifacts<br/>are committed"]
  WD --> E3
  HQ -->|"yes"| E3(["Session end:<br/>ticket open"])
  E3 -.->|"another session, agent,<br/>or person continues"| S
  W -->|"emergency change"| EA["A human approves the<br/>emergency exception"]
  EA --> EI["Until release, IGNITION<br/>may start and be<br/>satisfied before<br/>FLIGHT MANIFEST"]
  EI -->|"IGNITION satisfied apart<br/>from waived criteria,<br/>a human authorizes"| ER["Emergency release<br/>before SPLASHDOWN<br/>(integration, where<br/>nothing deploys)"]
  ER --> TF["Test-first applies<br/>again: a reopened<br/>IGNITION waits for<br/>FLIGHT MANIFEST"]
  TF --> RT["Retrospective tests<br/>land, derived from<br/>requirements; red run<br/>on the commit before<br/>the emergency change<br/>IGNITION re-checked"]
  RT -->|"every required phase<br/>satisfied again"| HR
  W -->|"all other required phases<br/>and other tasks' sets<br/>satisfied, no open finding"| HR["Human reviewer reviews<br/>final evidence and the<br/>integration record"]
  HR -->|"later blocking finding,<br/>substantive change, or<br/>tier move voids it"| CC
  HR --> HC["Human task owner<br/>approves integration<br/>and declares<br/>'mission accomplished'"]
  HC -->|"SPLASHDOWN and its<br/>Verification set recorded<br/>in one step; push, merge,<br/>or deploy follows"| E2(["Session end:<br/>ticket closed"])
```

- The next diagrams expand "Phase work". [Findings and change
  control](#findings-and-change-control) expands "Change control".
- Default roles: the human user is task owner and reviewer, and the session
  agent holds the other four roles. A manifest may say "roles: default".
- Read-only work needs no disk, even at a handoff. Scratch files do not
  count as a change.
- A handoff is any point where another session, agent, or person continues
  the ticket. Resuming the same transcript is not a handoff, and neither is a
  sub-agent that reports back to the session.
- The human review covers the ratified tier and formal scope, and every
  risk acceptance, exception, tier lowering, and formal-scope change that an
  agent approved. Only a blocking finding, a substantive change, or a tier
  move voids it. Pauses, handoffs, and editorial changes do not.
- The compaction rule applies whenever compaction is noticed, not only at
  session start. Rebuilt requirements, ratifications, and approvals count
  as proposed until confirmed again, and requirements are never rebuilt
  from the code.
- A human can approve an emergency exception at any point before release.
  Without an early release, the ticket goes on through normal phase work.
- Where the repository uses no pull requests, the reviewed commit is the
  integration record, and the push or merge follows approval.
- Sources in AIDLC.md: Session flow, Record medium, Roles, SPLASHDOWN,
  Emergency changes.

## Phase pipeline by tier

```mermaid
flowchart TD
  subgraph SPEC["Specification set"]
    FLY["0 FLYBY<br/>FLYBY pair"]
    TRA["1 TRAJECTORY / ANGLING<br/>TLA+ pair"]
    SIM["2 SIMULATION<br/>Lean pair"]
    FLY --> TRA
    TRA --> SIM
    FLY --> SIM
  end
  SPEC --> SS{{"Set approver records<br/>Specification set<br/>satisfied"}}
  SS --> FM
  subgraph IMPL["Implementation set"]
    FM["3 FLIGHT MANIFEST<br/>every tier"]
    IGN["4 IGNITION<br/>every tier"]
    FM ==>|"test-first: satisfied<br/>before IGNITION starts<br/>an emergency exception<br/>waives it until release"| IGN
  end
  IMPL --> IS{{"Set approver records<br/>Implementation set<br/>satisfied"}}
  SS --> TEL
  IS --> TEL
  IS --> LM
  subgraph VER["Verification set"]
    TEL["5 TELEMETRY<br/>Lean pair"]
    REN["6 RENDEZVOUS<br/>Lean pair"]
    LM["7 LANDING MODULE<br/>every tier<br/>parallel with 5 and 6"]
    SPL["8 SPLASHDOWN<br/>every tier<br/>closes the ticket<br/>with its own set"]
    TEL --> REN
    TEL -->|"satisfied first, its<br/>unmodeled behavior<br/>probed"| LM
    REN --> SPL
    LM --> SPL
  end
  classDef floor stroke-width:3px
  class FM,IGN,LM,SPL floor
```

| Tier | Required phases |
|---|---|
| WIFFLED — 0 / 3, none | The floor (thick border): FLIGHT MANIFEST, IGNITION, LANDING MODULE, SPLASHDOWN. |
| AIMED — 1 / 3, some | The floor, plus at least one technique-pair: FLYBY; TRAJECTORY / ANGLING; or SIMULATION → TELEMETRY → RENDEZVOUS. |
| POKAYOKE — 2 / 3, all | All nine phases. |

- Arrows show what a phase needs before it can be satisfied. Only phases the
  tier requires, and sets it touches, count. For example, SIMULATION needs
  FLYBY only when FLYBY is required.
- A phase may start drafting once its required inputs are in progress. It is
  satisfied only after they are satisfied and, for input from an earlier set,
  after that set is recorded satisfied.
- The thick arrow is test-first. It holds even when one task holds both
  phases. Until release, an approved emergency exception lets IGNITION start
  and be satisfied before FLIGHT MANIFEST. After release, test-first applies
  again.
- LANDING MODULE may start drafting once IGNITION is in progress, even before
  TELEMETRY starts. Its probes count once the Implementation set is
  satisfied. When TELEMETRY is required, LANDING MODULE is satisfied only
  after TELEMETRY is satisfied and its unmodeled behavior is probed.
- SPLASHDOWN needs every other phase and every other task's set satisfied.
  Its own Verification set is recorded with it, in one close step, when the
  human task owner declares "mission accomplished".
- Each set the tier touches needs at least one task. A task stays inside one
  set.
- AIMED and POKAYOKE manifests name a formal scope. Requirements outside it
  skip the formal phases but keep the ticket's tier, so WIFFLED-only
  relaxations do not apply to them.
- Sources in AIDLC.md: Structure, Tiers, each phase's Inputs, Test-first
  inside the set, Verification set, SPLASHDOWN.

## Findings and change control

```mermaid
flowchart TD
  O["Ticket open: phase work"]
  O -->|"blocking finding"| RF["Affected phase back<br/>to Active, blocked<br/>until disposed<br/>started downstream<br/>phases Invalidated"]
  O -->|"change request"| SQ{"Substantive?"}
  SQ -->|"no: editorial,<br/>meaning unchanged"| NR["No phase re-entry,<br/>review stays valid"]
  SQ -->|"yes"| CR["Earliest affected phase<br/>back to Active<br/>started downstream<br/>phases Invalidated"]
  O -->|"raise tier or add<br/>a technique-pair:<br/>any time"| RT["Newly required phases:<br/>Not started<br/>started phases<br/>downstream: Invalidated<br/>POKAYOKE: records<br/>move to disk"]
  O -->|"lower tier or remove<br/>a technique-pair:<br/>after work begins"| LQ{"Written rationale,<br/>higher-risk evidence<br/>disposed, technical<br/>authority approves?"}
  LQ -->|"no"| KT["Tier stays"]
  LQ -->|"yes"| LW["Dropped phases: Not<br/>required, evidence<br/>kept, no credit<br/>A dropped Specification<br/>phase invalidates<br/>FLIGHT MANIFEST and<br/>later started phases"]
  RF --> D{"Disposition"}
  D -->|"fix, enforce an excluding<br/>assumption, or ratify a<br/>requirement change"| FX["Rework: downstream<br/>work started meanwhile<br/>is Invalidated again"]
  D -->|"decision authority<br/>accepts residual risk"| AC["Residual risk recorded"]
  FX --> RW
  AC --> RW
  CR --> RW
  RT --> RW
  LW --> RW["Satisfy reopened phase<br/>redo or re-review<br/>Invalidated phases<br/>re-record affected sets<br/>draft a charter for any<br/>newly touched set"]
  RW --> V["A human review recorded<br/>before the change is void"]
  V -->|"back to phase work"| O
```

- "Earliest affected phase" follows the re-entry examples in AIDLC.md,
  Change control.
- After an emergency release, a reopened IGNITION whose FLIGHT MANIFEST is
  not satisfied goes to Invalidated instead of Active. It waits there until
  FLIGHT MANIFEST is satisfied.
- When a phase is reopened or invalidated, its set's record drops. This
  includes a downstream task's set that was already recorded satisfied.
- Narrowing the formal scope after work begins follows the rule for lowering
  a tier.
- Sources in AIDLC.md: Known counterexamples require disposition, Selection
  rule, Change control, SPLASHDOWN.

## Phase status

```mermaid
stateDiagram-v2
  direction TB
  state "Not required" as NA
  state Required {
    state "Not started" as TODO
    state "Active" as ACT
    state "Satisfied" as DONE
    state "Invalidated" as INV
    [*] --> TODO
    TODO --> ACT: start
    ACT --> DONE: satisfy
    DONE --> ACT: reopen
    ACT --> INV: upstream change
    DONE --> INV: upstream change<br/>or reopen
    INV --> ACT: redo
    INV --> DONE: re-review
  }
  [*] --> NA: tier does not require it
  [*] --> Required: tier requires it
  NA --> Required: tier raised
  Required --> NA: tier lowered
```

- start: the set's task charter exists and each required input is at least
  in progress. LANDING MODULE needs only IGNITION in progress. IGNITION also
  needs FLIGHT MANIFEST satisfied, unless an emergency exception waives that
  before release.
- satisfy: required inputs are satisfied, upstream sets are recorded, no open
  blocking finding sits at or upstream of the phase, and the set approver
  records it. Before release, an emergency exception lets IGNITION skip
  FLIGHT MANIFEST here too. SPLASHDOWN is satisfied only at "mission
  accomplished".
- reopen: a blocking finding or substantive change names this phase as the
  earliest affected phase. After an emergency release, a reopened IGNITION
  whose FLIGHT MANIFEST is not satisfied goes to Invalidated, and waits there
  until FLIGHT MANIFEST is satisfied.
- upstream change: an upstream phase is reopened or fixed; a tier raise adds
  an upstream phase; a tier lowering drops a Specification phase, which
  invalidates FLIGHT MANIFEST and every started phase after it; or
  retrospective tests satisfy FLIGHT MANIFEST after an emergency IGNITION.
- redo and re-review: rework the phase, or re-review it against the changed
  input.
- The phase status template in AIDLC.md also lists Blocked and Reopened.
  Blocked is any phase at or downstream of an open blocking finding: it
  cannot be satisfied until the finding is disposed. Reopened is the reopen
  transition.

## Set record

```mermaid
stateDiagram-v2
  direction TB
  state "Not satisfied" as NS
  state "Satisfied" as SS
  state "Satisfied, ticket closed" as VC
  [*] --> NS: tier touches the set
  NS --> SS: set approver records a<br/>Specification or<br/>Implementation set
  SS --> NS: a required phase in it<br/>is not Satisfied
  NS --> VC: Verification set,<br/>one step together<br/>with SPLASHDOWN at<br/>'mission accomplished'
```

## Coverage of AIDLC.tla actions

| AIDLC.tla action | Diagram | Shown by |
|---|---|---|
| ClassifyReadOnly | Session lifecycle | "Read-only work?" → yes → "Minimal manifest" |
| EndReadOnly | Session lifecycle | "Answer" → "Session end: read-only" |
| DraftManifest | Session lifecycle | "Draft full manifest", reached by "no: a change" or "before the first change to a repository, configuration, or production artifact", then "Record medium" → "Records in chat" or "Records on disk" |
| DraftCharter | Session lifecycle; Findings and change control | "Draft each missing task charter"; "draft a charter for any newly touched set" |
| WriteToDisk | Session lifecycle | "Records on disk?" → no → "Write records to disk" |
| StartPhase | Phase status; Phase pipeline by tier | "start" and "redo" transitions; the thick test-first arrow; the LANDING MODULE start note |
| CompletePhase | Phase status; Phase pipeline by tier; Session lifecycle | "satisfy" and "re-review" transitions; the arrows into each phase; "Retrospective tests land" (satisfying FLIGHT MANIFEST after IGNITION invalidates IGNITION for a re-check) |
| SatisfySet | Phase pipeline by tier; Set record | the "Set approver records ... satisfied" hexagons; "set approver records a Specification or Implementation set" |
| RaiseFinding | Findings and change control; Phase status | "blocking finding" → "Affected phase back to Active"; "reopen", or "upstream change or reopen" for IGNITION after release ("Test-first applies again" in Session lifecycle) |
| DisposeFix | Findings and change control | "Disposition" → "fix, enforce an excluding assumption, or ratify a requirement change" → "Rework" |
| DisposeAccept | Findings and change control | "Disposition" → "decision authority accepts residual risk" → "Residual risk recorded" |
| ChangeRequest | Findings and change control; Phase status | "change request" → "Substantive?" → yes → "Earliest affected phase back to Active"; "reopen", as for RaiseFinding |
| RaiseTier | Findings and change control; Phase status | "raise tier or add a technique-pair" → "Newly required phases"; "tier raised" |
| LowerTier | Findings and change control; Phase status | "lower tier or remove a technique-pair" → yes → "Dropped phases"; "tier lowered" |
| ApproveEmergency | Session lifecycle | "emergency change" → "A human approves the emergency exception" |
| EmergencyRelease | Session lifecycle | "IGNITION satisfied apart from waived criteria, a human authorizes" → "Emergency release before SPLASHDOWN" |
| Pause | Session lifecycle | "pause" → "Paused" |
| Resume | Session lifecycle | "Paused" → "resume same transcript" → "Resume from the recorded phase status" |
| Handoff | Session lifecycle | "handoff" → "Records on disk?" → "Session end: ticket open" |
| StartSession | Session lifecycle | dotted "another session, agent, or person continues" → "Session start" → "yes: on disk or in this transcript" |
| HumanReview | Session lifecycle | "Human reviewer reviews final evidence and the integration record" |
| HumanClose | Session lifecycle; Phase pipeline by tier; Set record | "Human task owner approves integration and declares 'mission accomplished'" and its edge "SPLASHDOWN and its Verification set recorded in one step"; "8 SPLASHDOWN ... closes the ticket with its own set"; "Verification set, one step together with SPLASHDOWN" |
| EndAfterClose | Session lifecycle | "Session end: ticket closed" |

`Terminated` in AIDLC.tla is the stutter step at a settled end, and `Hist`
only updates history variables that the checks read. Neither is a process
step, so no diagram shows them. Two paths come from AIDLC.md alone, with no
model action: rebuilding chat-only records lost to a compacted or cleared
transcript, and a read-only handoff.

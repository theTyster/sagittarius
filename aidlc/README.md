# AIDLC system prompt

`AIDLC.md` is the governance prompt. `claude()` in `shared/copy/.zshenv`
appends it to every work session, and it is the only file read. The other
files here are maintainer material. No session ever sees them.

| File | What it is |
|---|---|
| `AIDLC.md` | The prompt. Self-contained by design. It is passed as one argv string, so keep it well under 128 KiB. |
| `AIDLC-flow.md` | Mermaid diagrams of every path from session start to session end, derived from `AIDLC.md` and the model. Gitea renders them. |
| `model/AIDLC.tla` | TLA+ model of the process rules: sessions, records, tiers, phases, findings, tier moves, emergencies, close-out. |
| `model/check.sh` | Runs TLC. A main check, reachability witnesses, and counterfactual mutations. |

## When you edit AIDLC.md

1. If the edit changes a process rule, update `model/AIDLC.tla` and run
   `model/check.sh`. Every line must report `ok`. Process rules cover phase
   order, gates, tiers, records, roles, findings, and sessions.
2. Update `AIDLC-flow.md` when a path changes. Its coverage table must
   still list every model action.
3. If you change the `<evidence_kb_schema>` block, load it in SWI-Prolog
   and query its gates before relying on it. The `swipl` container image
   works: `podman run --rm -v "$PWD:/kb:Z" -w /kb docker.io/library/swipl:10.0.2 swipl kb.pl`.
4. Wording-only edits need none of these steps.

## Running the model check

TLC needs Java. This Linux host has the `tlc` wrapper and `tla2tools.jar`
but no JDK, so point `JAVA_HOME` at any JDK or JRE 11 or newer.

    JAVA_HOME=/path/to/jre model/check.sh       # disruption budget 2, about 10 minutes
    JAVA_HOME=/path/to/jre model/check.sh 3     # wider search, much slower

TLC runs in a temp directory, so no state or trace files land in the repo.

Last run: 2026-10-01, TLC 2.19 (tla2tools v1.7.4), Temurin 21, budget 2.

| Group | Result |
|---|---|
| Main: 18 invariants, termination, release step, no deadlock | passed over 4,313,782 distinct states |
| Witnesses: each path is reachable | 17 of 17 reachable |
| Mutations: each dropped guard breaks its invariant | 17 of 17 caught |
| Budget 3, safety only: 17 invariants and release step | passed over 20,646,180 distinct states, depth 42, 8 minutes |

## What the model covers

| AIDLC.md rule | Model operators |
|---|---|
| Manifest and charter before phase work | `DraftManifest`, `DraftCharter`; `ManifestFirst` |
| Read-only minimal manifest, completed before the first change | `ClassifyReadOnly`, `EndReadOnly`; `ReadOnlyClean`; witness `NeverReadOnlyUpgrade` |
| Record medium: POKAYOKE on disk, disk before a handoff | `DraftManifest`, `WriteToDisk`, `Pause`, `Resume`, `Handoff`, `StartSession`; `PokayokeOnDisk`, `HandoffOnDisk` |
| Tier decides the required phases and sets | `ReqOf`, `Touched`; `TierShape` |
| Test-first, and again after an emergency release | `StartPhase`, `Reopened`; `TestFirst`, `TestFirstStrict` |
| Drafting allowed; authority needs upstream sets satisfied | `StartPhase`, `StartDeps`, `CompletePhase`, `Counts`; `Authoritative` |
| Set satisfaction | `SatisfySet`, `SetsFor`; `SetsHonest` |
| Known counterexamples block | `RaiseFinding`, `DisposeFix`, `DisposeAccept`; `FindingsBlock` |
| Return to the earliest affected phase; downstream goes stale | `ChangeRequest`, `Stale`, `DownMap`; `Authoritative` |
| Tier raise and lower re-review what depends on them | `RaiseTier`, `LowerTier`; `Authoritative`, `FMSourceCurrent` |
| Emergency exception postpones evidence | `ApproveEmergency`, `EmergencyRelease`; `ReleaseGate`, `ReleaseStep`, `RetroRecheck`, `Closure` |
| Human review and close; a later blocking finding, change, or tier move voids the review | `HumanReview`, `HumanClose`; `Closure`, `ReviewCurrent`, `ReviewFresh` |
| LANDING MODULE drafts during IGNITION, is satisfied after TELEMETRY | `StartDeps`, `Deps` |
| Every path settles | `Termination` under fair progress; TLC deadlock check |

## What the model abstracts away

- One task per set touched. Slices of one phase across tasks are not
  modeled.
- At most one open blocking finding at a time. Change requests and tier
  lowering happen only while no finding is open.
- The disruption budget bounds findings, change requests, tier moves,
  pauses, and handoffs per behavior. `MaxSessions` is 2.
- No roles. Human-only steps are the review, the close and integration
  approval, the emergency approval, and the emergency release. Each action
  stands for its approval, so the model cannot check who approved.
- The human review is one flag, stamped with the disruption count so a
  later finding, change, or tier move voids it (`ReviewFresh`).
- The phase-order table `Deps` drives the guards. `DocOrder` restates the
  order by hand from the doc's Inputs, so an error in `Deps` fails a check.
- The record medium only moves toward disk. Updating records only in chat
  after writing them to disk is not modeled.
- Read-only work never pauses or hands off.
- The tier is drafted and ratified in one step. Lowering before work
  begins is a free re-draft and is not modeled.
- SHOULD rules are not forced. Examples: the human requirement review
  before IGNITION, and TELEMETRY drafting early.
- Content is out of scope: what tests assert, review checks, proof
  quality, claim wording, formal scope, editorial changes, non-blocking
  findings, and knowledge-base facts. The schema has its own Prolog checks
  (step 3 above).
- Sub-agents and transcript compaction are not modeled. A sub-agent that
  reports back is part of the session; compaction is a records loss, which
  the doc handles by rebuilding.
- The AIMED rule that committed formal artifacts carry their traceability
  is not modeled.
- Losing a session that has chat-only records is not modeled. The disk
  rule exists to prevent it.
- Humans are assumed to act eventually: they review and close.
- The model has no cost measure. It supports the rigor claims, not the
  churn claims.

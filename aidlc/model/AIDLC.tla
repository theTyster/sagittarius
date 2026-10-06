------------------------------- MODULE AIDLC -------------------------------
(***************************************************************************)
(* Process model of the AIDLC governance prompt (../AIDLC.md).            *)
(*                                                                         *)
(* One ticket, worked from session start to session end, possibly over    *)
(* several sessions. The model encodes the MUST rules of AIDLC.md. SHOULD  *)
(* rules are left to judgment and are not forced. Comments name the        *)
(* AIDLC.md section behind each rule. ../README.md lists the abstractions. *)
(*                                                                         *)
(* Mutation names one guard to drop. Normal runs use "none". The           *)
(* counterfactual runs in check.sh drop one guard each and expect its      *)
(* invariant to fail.                                                      *)
(***************************************************************************)
EXTENDS Naturals, FiniteSets

CONSTANTS
    MaxSessions,  \* sessions one ticket may span
    Budget,       \* disruptions per behavior: findings, changes, tier moves, pauses, handoffs
    Mutation      \* "none", or the name of one guard to drop

VARIABLES
    session,   \* "active" | "paused" | "ended"
    sessions,  \* sessions started for this ticket
    kind,      \* "unknown" | "readonly" | "change"
    manifest,  \* "none" | "readonly" (minimal manifest) | "full"
    medium,    \* where the records live: "none" | "reasoning" | "chat" | "disk"
    tier,      \* "none" | "WIFFLED" | "AIMED" | "POKAYOKE"
    pairs,     \* selected AIMED technique-pairs
    charter,   \* [Sets -> BOOLEAN]: the set's task has a charter
    status,    \* [Phases -> Status]
    setDone,   \* [Sets -> BOOLEAN]: the set approver recorded the set satisfied
    finding,   \* "none", or the earliest affected phase of the open blocking finding
    residual,  \* a finding was accepted as residual risk
    exception, \* an emergency process exception is approved
    released,  \* the change is deployed or integrated
    reviewed,  \* the human reviewer reviewed the current evidence
    closed,    \* the human task owner declared "mission accomplished"
    budget,    \* disruptions left
    \* History variables, updated by Hist on every step:
    epoch,       \* substantive disruptions so far
    reviewEpoch, \* epoch at the latest human review
    ignAfterFM,  \* IGNITION last completed with FLIGHT MANIFEST satisfied
    fmSource     \* Specification phases FLIGHT MANIFEST was last satisfied against

vars == <<session, sessions, kind, manifest, medium, tier, pairs, charter,
          status, setDone, finding, residual, exception, released, reviewed,
          closed, budget>>

allVars == <<vars, epoch, reviewEpoch, ignAfterFM, fmSource>>

Keep(g) == Mutation # g

-----------------------------------------------------------------------------
(* Structure ("Set → phase mapping").                                      *)

SpecPhases == {"FLYBY", "TRAJECTORY", "SIMULATION"}
ImplPhases == {"FLIGHT_MANIFEST", "IGNITION"}
VerPhases  == {"TELEMETRY", "RENDEZVOUS", "LANDING_MODULE", "SPLASHDOWN"}
Phases     == SpecPhases \cup ImplPhases \cup VerPhases
Sets       == {"Spec", "Impl", "Ver"}
Status     == {"na", "todo", "active", "done", "invalid"}
Started    == {"active", "done", "invalid"}

SetOf(p) == IF p \in SpecPhases THEN "Spec"
            ELSE IF p \in ImplPhases THEN "Impl" ELSE "Ver"

(* Tiers ("Tiers").                                                        *)
Pairs == {"FlybyPair", "TlaPair", "LeanPair"}

PairPhases(pr) ==
    CASE pr = "FlybyPair" -> {"FLYBY"}
      [] pr = "TlaPair"   -> {"TRAJECTORY"}
      [] pr = "LeanPair"  -> {"SIMULATION", "TELEMETRY", "RENDEZVOUS"}

Floor == {"FLIGHT_MANIFEST", "IGNITION", "LANDING_MODULE", "SPLASHDOWN"}

ReqOf(t, ps) ==
    CASE t = "WIFFLED"  -> Floor
      [] t = "AIMED"    -> Floor \cup UNION {PairPhases(pr) : pr \in ps}
      [] t = "POKAYOKE" -> Phases
      [] OTHER          -> {}

Configs == {<<"WIFFLED", {}>>, <<"POKAYOKE", {}>>}
           \cup {<<"AIMED", ps>> : ps \in (SUBSET Pairs) \ {{}}}

Req     == ReqOf(tier, pairs)
Touched == {SetOf(p) : p \in Req}

\* c2 is a higher tier than c1: it requires strictly more phases, or it is
\* POKAYOKE and requires at least as much.
Higher(c2, c1) ==
    LET r1 == ReqOf(c1[1], c1[2])
        r2 == ReqOf(c2[1], c2[2])
    IN  \/ (r1 \subseteq r2 /\ r1 # r2)
        \/ (c2[1] = "POKAYOKE" /\ c1[1] # "POKAYOKE" /\ r1 \subseteq r2)

(* Phase inputs: each phase's Inputs or Requirements source. SPLASHDOWN    *)
(* needs every other phase. LANDING MODULE is satisfied only after        *)
(* TELEMETRY, when TELEMETRY is required.                                  *)
Deps(p) ==
    CASE p = "FLYBY"           -> {}
      [] p = "TRAJECTORY"      -> {"FLYBY"}
      [] p = "SIMULATION"      -> {"FLYBY", "TRAJECTORY"}
      [] p = "FLIGHT_MANIFEST" -> SpecPhases
      [] p = "IGNITION"        -> {"FLIGHT_MANIFEST"}
      [] p = "TELEMETRY"       -> {"IGNITION", "SIMULATION"}
      [] p = "RENDEZVOUS"      -> {"TELEMETRY"}
      [] p = "LANDING_MODULE"  -> IF Keep("lm_telemetry") THEN {"IGNITION", "TELEMETRY"}
                                  ELSE {"IGNITION"}
      [] p = "SPLASHDOWN"      -> Phases \ {"SPLASHDOWN"}

RECURSIVE Up(_)
Up(p) == Deps(p) \cup UNION {Up(q) : q \in Deps(p)}

DownMap   == [p \in Phases |-> {q \in Phases : p \in Up(q)}]
DownOf(S) == UNION {DownMap[p] : p \in S}
ReqDeps(p) == Deps(p) \cap Req

\* Inputs that must be in progress before drafting starts. LANDING MODULE
\* may start once IGNITION is in progress, before TELEMETRY.
StartDeps(p) == (IF p = "LANDING_MODULE" THEN {"IGNITION"} ELSE Deps(p)) \cap Req

-----------------------------------------------------------------------------
(* Helpers.                                                                *)

\* The emergency exception waives test-first for IGNITION. Guards honor the
\* waiver only until release; the invariants accept its result afterwards.
WaivedNow(q, p) == /\ exception /\ (~released \/ ~Keep("waiver_expiry"))
                   /\ p = "IGNITION" /\ q = "FLIGHT_MANIFEST"
WaivedEver(q, p) == exception /\ p = "IGNITION" /\ q = "FLIGHT_MANIFEST"

\* Upstream q counts as an input of p when q is done and, when q sits in an
\* earlier set, q's set is recorded satisfied ("Set ordering across tasks").
Counts(q, p) ==
    /\ status[q] = "done"
    /\ (SetOf(q) # SetOf(p) /\ Keep("set_order")) => setDone[SetOf(q)]

InputsReady(p) == \A q \in ReqDeps(p) : Counts(q, p) \/ WaivedNow(q, p)

\* An open blocking finding blocks its phase and every phase downstream.
Blocked(p) == finding # "none" /\ (p = finding \/ p \in DownMap[finding])

\* Every started phase in S becomes invalid: redo it or re-review it.
Stale(st, S) == [p \in Phases |-> IF p \in S /\ st[p] \in Started
                                  THEN "invalid" ELSE st[p]]

\* Reopened work returns to "active", except IGNITION once the waiver has
\* expired and FLIGHT MANIFEST is not satisfied: then test-first applies
\* again, so IGNITION waits as "invalid".
Reopened(p) ==
    IF /\ p = "IGNITION" /\ status["FLIGHT_MANIFEST"] # "done"
       /\ ~WaivedNow("FLIGHT_MANIFEST", p) /\ Keep("post_release_test_first")
    THEN "invalid" ELSE "active"

\* A set stays satisfied only while every required phase in it is done.
SetsFor(st, rq) ==
    [s \in Sets |-> /\ setDone[s]
                    /\ s \in {SetOf(p) : p \in rq}
                    /\ \A p \in rq : SetOf(p) = s => st[p] = "done"]

-----------------------------------------------------------------------------
(* Session start ("Session flow").                                         *)

Init ==
    /\ session = "active"
    /\ sessions = 1
    /\ kind = "unknown"
    /\ manifest = "none"
    /\ medium = "none"
    /\ tier = "none"
    /\ pairs = {}
    /\ charter = [s \in Sets |-> FALSE]
    /\ status = [p \in Phases |-> "na"]
    /\ setDone = [s \in Sets |-> FALSE]
    /\ finding = "none"
    /\ residual = FALSE
    /\ exception = FALSE
    /\ released = FALSE
    /\ reviewed = FALSE
    /\ closed = FALSE
    /\ budget = Budget
    /\ epoch = 0
    /\ reviewEpoch = 0
    /\ ignAfterFM = FALSE
    /\ fmSource = {}

Active == session = "active"
Open   == manifest = "full" /\ ~closed

\* Read-only work keeps a minimal manifest. It may stay in the agent's reasoning.
ClassifyReadOnly ==
    /\ Active /\ manifest = "none"
    /\ kind' = "readonly" /\ manifest' = "readonly" /\ medium' = "reasoning"
    /\ UNCHANGED <<session, sessions, tier, pairs, charter, status, setDone,
                   finding, residual, exception, released, reviewed, closed, budget>>

EndReadOnly ==
    /\ Active /\ kind = "readonly"
    /\ session' = "ended"
    /\ UNCHANGED <<sessions, kind, manifest, medium, tier, pairs, charter, status,
                   setDone, finding, residual, exception, released, reviewed,
                   closed, budget>>

\* The full manifest records tier, roles, and tasks before the first change.
\* POKAYOKE records live on disk ("Record medium").
DraftManifest(c, m) ==
    /\ Active /\ manifest \in {"none", "readonly"}
    /\ m \in (IF c[1] = "POKAYOKE" /\ Keep("pokayoke_disk")
              THEN {"disk"} ELSE {"chat", "disk"})
    /\ kind' = "change" /\ manifest' = "full" /\ medium' = m
    /\ tier' = c[1] /\ pairs' = c[2]
    /\ status' = [p \in Phases |-> IF p \in ReqOf(c[1], c[2]) THEN "todo" ELSE "na"]
    /\ UNCHANGED <<session, sessions, charter, setDone, finding, residual,
                   exception, released, reviewed, closed, budget>>

\* "If the current task has no charter, ... begin by drafting the task charter."
DraftCharter(s) ==
    /\ Active /\ Open /\ s \in Touched /\ ~charter[s]
    /\ charter' = [charter EXCEPT ![s] = TRUE]
    /\ UNCHANGED <<session, sessions, kind, manifest, medium, tier, pairs, status,
                   setDone, finding, residual, exception, released, reviewed,
                   closed, budget>>

WriteToDisk ==
    /\ Active /\ Open /\ medium = "chat"
    /\ medium' = "disk"
    /\ UNCHANGED <<session, sessions, kind, manifest, tier, pairs, charter, status,
                   setDone, finding, residual, exception, released, reviewed,
                   closed, budget>>

-----------------------------------------------------------------------------
(* Phase work ("Completion is explicit", "Test-first inside the set").     *)

\* Drafting may start once the phase's inputs are in progress. IGNITION
\* waits for FLIGHT MANIFEST to be satisfied.
StartPhase(p) ==
    /\ Active /\ Open
    /\ p \in Req /\ status[p] \in {"todo", "invalid"}
    /\ charter[SetOf(p)]
    /\ \A q \in StartDeps(p) : status[q] \in Started \/ WaivedNow(q, p)
    /\ (p = "IGNITION" /\ Keep("test_first")) =>
           (status["FLIGHT_MANIFEST"] = "done" \/ WaivedNow("FLIGHT_MANIFEST", p))
    /\ status' = [status EXCEPT ![p] = "active"]
    /\ UNCHANGED <<session, sessions, kind, manifest, medium, tier, pairs, charter,
                   setDone, finding, residual, exception, released, reviewed,
                   closed, budget>>

\* The set approver records the phase satisfied. When retrospective tests
\* land after an emergency release, IGNITION is re-checked against them.
CompletePhase(p) ==
    /\ Active /\ Open
    /\ p \in Req \ {"SPLASHDOWN"}
    /\ status[p] \in {"active", "invalid"}
    /\ charter[SetOf(p)]
    /\ InputsReady(p)
    /\ (~Blocked(p) \/ ~Keep("finding_block"))
    /\ LET st == IF /\ p = "FLIGHT_MANIFEST" /\ status["IGNITION"] = "done"
                    /\ Keep("retro_recheck")
                 THEN Stale(status, {"IGNITION"} \cup DownMap["IGNITION"])
                 ELSE status
       IN  status' = [st EXCEPT ![p] = "done"]
    /\ setDone' = SetsFor(status', Req)
    /\ UNCHANGED <<session, sessions, kind, manifest, medium, tier, pairs, charter,
                   finding, residual, exception, released, reviewed, closed, budget>>

SatisfySet(s) ==
    /\ Active /\ Open
    /\ s \in Touched \ {"Ver"} /\ ~setDone[s]
    /\ \A p \in Req : SetOf(p) = s => status[p] = "done"
    /\ setDone' = [setDone EXCEPT ![s] = TRUE]
    /\ UNCHANGED <<session, sessions, kind, manifest, medium, tier, pairs, charter,
                   status, finding, residual, exception, released, reviewed,
                   closed, budget>>

-----------------------------------------------------------------------------
(* Findings and change control ("Known counterexamples require            *)
(* disposition", "Change control").                                        *)

\* A blocking finding returns its earliest affected phase to work and makes
\* every started downstream phase stale.
RaiseFinding(p) ==
    /\ Active /\ Open /\ budget > 0 /\ finding = "none"
    /\ p \in Req /\ status[p] \in {"active", "done"}
    /\ finding' = p
    /\ LET st == IF Keep("stale_downstream") THEN Stale(status, DownMap[p]) ELSE status
       IN  status' = [st EXCEPT ![p] = Reopened(p)]
    /\ setDone' = SetsFor(status', Req)
    /\ reviewed' = (reviewed /\ ~Keep("review_reset"))
    /\ budget' = budget - 1
    /\ UNCHANGED <<session, sessions, kind, manifest, medium, tier, pairs, charter,
                   residual, exception, released, closed>>

\* Fix, enforce an excluding assumption, or ratify a requirement change. The
\* fix changes the affected output, so started downstream work is stale.
DisposeFix ==
    /\ Active /\ Open /\ finding # "none"
    /\ finding' = "none"
    /\ status' = Stale(status, DownMap[finding])
    /\ setDone' = SetsFor(status', Req)
    /\ UNCHANGED <<session, sessions, kind, manifest, medium, tier, pairs, charter,
                   residual, exception, released, reviewed, closed, budget>>

\* The decision authority accepts the finding as residual risk.
DisposeAccept ==
    /\ Active /\ Open /\ finding # "none"
    /\ finding' = "none" /\ residual' = TRUE
    /\ UNCHANGED <<session, sessions, kind, manifest, medium, tier, pairs, charter,
                   status, setDone, exception, released, reviewed, closed, budget>>

\* A substantive change outside a finding returns to the earliest affected phase.
ChangeRequest(p) ==
    /\ Active /\ Open /\ budget > 0 /\ finding = "none"
    /\ p \in Req /\ status[p] \in {"active", "done"}
    /\ LET st == IF Keep("stale_downstream") THEN Stale(status, DownMap[p]) ELSE status
       IN  status' = [st EXCEPT ![p] = Reopened(p)]
    /\ setDone' = SetsFor(status', Req)
    /\ reviewed' = (reviewed /\ ~Keep("review_reset"))
    /\ budget' = budget - 1
    /\ UNCHANGED <<session, sessions, kind, manifest, medium, tier, pairs, charter,
                   finding, residual, exception, released, closed>>

-----------------------------------------------------------------------------
(* Tier moves ("Selection rule"). Raising is a substantive change: started *)
(* phases downstream of a newly required phase are re-reviewed.            *)

RaiseTier(c) ==
    /\ Active /\ Open /\ budget > 0
    /\ c \in Configs /\ Higher(c, <<tier, pairs>>)
    /\ LET newReq == ReqOf(c[1], c[2]) \ Req
           st     == IF Keep("raise_stale") THEN Stale(status, DownOf(newReq)) ELSE status
       IN  status' = [p \in Phases |-> IF p \in newReq THEN "todo" ELSE st[p]]
    /\ tier' = c[1] /\ pairs' = c[2]
    /\ medium' = (IF c[1] = "POKAYOKE" THEN "disk" ELSE medium)
    /\ setDone' = SetsFor(status', ReqOf(c[1], c[2]))
    /\ reviewed' = (reviewed /\ ~Keep("raise_review_reset"))
    /\ budget' = budget - 1
    /\ UNCHANGED <<session, sessions, kind, manifest, charter, finding, residual,
                   exception, released, closed>>

\* Lowering after work begins needs written rationale, disposition of the
\* risk evidence, and technical-authority approval. This step stands for
\* that record. Evidence from dropped phases is kept but no longer credited.
\* Dropping a Specification phase changes FLIGHT MANIFEST's requirement
\* source, so FLIGHT MANIFEST and everything after it is re-reviewed.
LowerTier(c) ==
    /\ Active /\ Open /\ budget > 0 /\ finding = "none"
    /\ \E p \in Phases : status[p] \in Started
    /\ c \in Configs /\ Higher(<<tier, pairs>>, c)
    /\ LET dropped == Req \ ReqOf(c[1], c[2])
           st == IF dropped \cap SpecPhases # {} /\ Keep("lower_stale")
                 THEN Stale(status, {"FLIGHT_MANIFEST"} \cup DownMap["FLIGHT_MANIFEST"])
                 ELSE status
       IN  status' = [p \in Phases |-> IF p \in ReqOf(c[1], c[2]) THEN st[p] ELSE "na"]
    /\ tier' = c[1] /\ pairs' = c[2]
    /\ setDone' = SetsFor(status', ReqOf(c[1], c[2]))
    /\ reviewed' = (reviewed /\ ~Keep("lower_review_reset"))
    /\ budget' = budget - 1
    /\ UNCHANGED <<session, sessions, kind, manifest, medium, charter, finding,
                   residual, exception, released, closed>>

-----------------------------------------------------------------------------
(* Emergency changes. Emergency status postpones evidence. It does not     *)
(* create it.                                                              *)

ApproveEmergency ==
    /\ Active /\ Open /\ ~exception /\ ~released
    /\ exception' = TRUE
    /\ UNCHANGED <<session, sessions, kind, manifest, medium, tier, pairs, charter,
                   status, setDone, finding, residual, released, reviewed,
                   closed, budget>>

\* The model has no roles. A human approves the exception and authorizes
\* this release ahead of SPLASHDOWN; both steps stand for that approval.
EmergencyRelease ==
    /\ Active /\ Open /\ exception /\ ~released
    /\ (status["IGNITION"] = "done" \/ ~Keep("release_ignition"))
    /\ released' = TRUE
    /\ UNCHANGED <<session, sessions, kind, manifest, medium, tier, pairs, charter,
                   status, setDone, finding, residual, exception, reviewed,
                   closed, budget>>

-----------------------------------------------------------------------------
(* Session end and resumption ("Record medium").                           *)

\* The session stops with the ticket open. The same transcript resumes later.
Pause ==
    /\ Active /\ Open /\ budget > 0
    /\ session' = "paused" /\ budget' = budget - 1
    /\ UNCHANGED <<sessions, kind, manifest, medium, tier, pairs, charter, status,
                   setDone, finding, residual, exception, released, reviewed, closed>>

Resume ==
    /\ session = "paused"
    /\ session' = "active"
    /\ UNCHANGED <<sessions, kind, manifest, medium, tier, pairs, charter, status,
                   setDone, finding, residual, exception, released, reviewed,
                   closed, budget>>

\* Another session, agent, or person continues the ticket. Records go to disk.
Handoff ==
    /\ Active /\ Open /\ budget > 0 /\ sessions < MaxSessions
    /\ (medium = "disk" \/ ~Keep("handoff_disk"))
    /\ session' = "ended" /\ budget' = budget - 1
    /\ UNCHANGED <<sessions, kind, manifest, medium, tier, pairs, charter, status,
                   setDone, finding, residual, exception, released, reviewed, closed>>

StartSession ==
    /\ session = "ended" /\ Open
    /\ session' = "active" /\ sessions' = sessions + 1
    /\ UNCHANGED <<kind, manifest, medium, tier, pairs, charter, status, setDone,
                   finding, residual, exception, released, reviewed, closed, budget>>

-----------------------------------------------------------------------------
(* Close-out ("SPLASHDOWN"). A human reviewer reviews; the human task      *)
(* owner declares "mission accomplished" and authorizes deployment.        *)

ReadyToClose ==
    /\ \A p \in Req \ {"SPLASHDOWN"} : status[p] = "done"
    /\ \A s \in Touched \ {"Ver"} : setDone[s]
    /\ finding = "none"
    /\ status["SPLASHDOWN"] = "active"

HumanReview ==
    /\ Active /\ Open /\ ~reviewed /\ ReadyToClose
    /\ reviewed' = TRUE
    /\ UNCHANGED <<session, sessions, kind, manifest, medium, tier, pairs, charter,
                   status, setDone, finding, residual, exception, released,
                   closed, budget>>

HumanClose ==
    /\ Active /\ Open /\ ReadyToClose
    /\ (reviewed \/ ~Keep("closure_review"))
    /\ status' = [status EXCEPT !["SPLASHDOWN"] = "done"]
    /\ setDone' = [setDone EXCEPT !["Ver"] = TRUE]
    /\ closed' = TRUE /\ released' = TRUE
    /\ UNCHANGED <<session, sessions, kind, manifest, medium, tier, pairs, charter,
                   finding, residual, exception, reviewed, budget>>

EndAfterClose ==
    /\ Active /\ closed
    /\ session' = "ended"
    /\ UNCHANGED <<sessions, kind, manifest, medium, tier, pairs, charter, status,
                   setDone, finding, residual, exception, released, reviewed,
                   closed, budget>>

Settled == session = "ended" /\ (closed \/ kind = "readonly")

\* Terminal states stutter, so TLC reports only real deadlocks.
Terminated == Settled /\ UNCHANGED vars

-----------------------------------------------------------------------------
Progress ==
    \/ ClassifyReadOnly \/ EndReadOnly
    \/ \E c \in Configs, m \in {"chat", "disk"} : DraftManifest(c, m)
    \/ \E s \in Sets : DraftCharter(s) \/ SatisfySet(s)
    \/ WriteToDisk
    \/ \E p \in Phases : StartPhase(p) \/ CompletePhase(p)
    \/ DisposeFix \/ DisposeAccept
    \/ Resume \/ StartSession
    \/ HumanReview \/ HumanClose \/ EndAfterClose

Disruption ==
    \/ \E p \in Phases : RaiseFinding(p) \/ ChangeRequest(p)
    \/ \E c \in Configs : RaiseTier(c) \/ LowerTier(c)
    \/ ApproveEmergency \/ EmergencyRelease
    \/ Pause \/ Handoff

Next == Progress \/ Disruption \/ Terminated

\* History: count substantive disruptions (those that spend budget without
\* ending the session), stamp each human review with the current count,
\* and note whether IGNITION last completed after FLIGHT MANIFEST.
Hist ==
    /\ epoch' = IF budget' = budget - 1 /\ session' = session THEN epoch + 1 ELSE epoch
    /\ reviewEpoch' = IF reviewed' /\ ~reviewed THEN epoch' ELSE reviewEpoch
    /\ ignAfterFM' =
           IF status'["IGNITION"] = "done" /\ status["IGNITION"] # "done"
           THEN status'["FLIGHT_MANIFEST"] = "done"
           ELSE IF status'["FLIGHT_MANIFEST"] = "done" /\ status["FLIGHT_MANIFEST"] # "done"
                THEN FALSE ELSE ignAfterFM
    /\ fmSource' =
           IF status'["FLIGHT_MANIFEST"] = "done" /\ status["FLIGHT_MANIFEST"] # "done"
           THEN ReqOf(tier', pairs') \cap SpecPhases ELSE fmSource

Spec == Init /\ [][Next /\ Hist]_allVars /\ WF_allVars(Progress /\ Hist)

-----------------------------------------------------------------------------
(* Safety invariants: the MUST rules.                                      *)

TypeOK ==
    /\ session \in {"active", "paused", "ended"}
    /\ sessions \in 1..MaxSessions
    /\ kind \in {"unknown", "readonly", "change"}
    /\ manifest \in {"none", "readonly", "full"}
    /\ medium \in {"none", "reasoning", "chat", "disk"}
    /\ tier \in {"none", "WIFFLED", "AIMED", "POKAYOKE"}
    /\ pairs \subseteq Pairs
    /\ charter \in [Sets -> BOOLEAN]
    /\ status \in [Phases -> Status]
    /\ setDone \in [Sets -> BOOLEAN]
    /\ finding \in Phases \cup {"none"}
    /\ residual \in BOOLEAN
    /\ exception \in BOOLEAN
    /\ released \in BOOLEAN
    /\ reviewed \in BOOLEAN
    /\ closed \in BOOLEAN
    /\ budget \in 0..Budget
    /\ epoch \in 0..Budget
    /\ reviewEpoch \in 0..Budget
    /\ ignAfterFM \in BOOLEAN
    /\ fmSource \subseteq SpecPhases

\* No phase work before the manifest and the task charter exist.
ManifestFirst ==
    \A p \in Phases : status[p] \in Started => manifest = "full" /\ charter[SetOf(p)]

\* A phase is "na" exactly when the tier does not require it.
TierShape == \A p \in Phases : (status[p] = "na") <=> (p \notin Req)

\* FLIGHT MANIFEST is satisfied before IGNITION starts, unless an emergency
\* exception waived it.
TestFirst ==
    status["IGNITION"] \in {"active", "done"} =>
        (status["FLIGHT_MANIFEST"] = "done" \/ exception)

\* A done phase rests on done inputs. An input from an earlier set also
\* needs its set recorded satisfied.
Authoritative ==
    \A p \in Phases : status[p] = "done" =>
        \A q \in ReqDeps(p) :
            \/ (status[q] = "done" /\ (SetOf(q) # SetOf(p) => setDone[SetOf(q)]))
            \/ WaivedEver(q, p)

\* A set is satisfied only while every required phase in it is done.
SetsHonest ==
    \A s \in Sets : setDone[s] =>
        /\ s \in Touched
        /\ \A p \in Req : SetOf(p) = s => status[p] = "done"

\* An open blocking finding leaves no satisfied phase at or below it.
FindingsBlock ==
    finding # "none" =>
        /\ status[finding] # "done"
        /\ \A q \in DownMap[finding] : status[q] # "done"
        /\ ~closed

\* The ticket closes only with every phase and set satisfied and a human review.
Closure ==
    closed =>
        /\ \A p \in Req : status[p] = "done"
        /\ \A s \in Touched : setDone[s]
        /\ finding = "none"
        /\ reviewed

\* A recorded review still describes the current evidence.
ReviewCurrent ==
    (reviewed /\ ~closed) =>
        /\ \A p \in Req \ {"SPLASHDOWN"} : status[p] = "done"
        /\ finding = "none"

\* Deployment before close needs an approved emergency exception.
ReleaseGate == (released /\ ~closed) => exception

PokayokeOnDisk == tier = "POKAYOKE" => medium = "disk"

HandoffOnDisk == (session = "ended" /\ manifest = "full" /\ ~closed) => medium = "disk"

ReadOnlyClean == kind = "readonly" => \A p \in Phases : status[p] = "na"

\* After release, IGNITION works only with FLIGHT MANIFEST satisfied.
TestFirstStrict ==
    status["IGNITION"] = "active" =>
        (status["FLIGHT_MANIFEST"] = "done" \/ (exception /\ ~released))

\* A recorded review postdates every finding, change, and tier move.
ReviewFresh == reviewed => reviewEpoch = epoch

\* When retrospective tests land, IGNITION is re-checked against them.
RetroRecheck ==
    (status["IGNITION"] = "done" /\ status["FLIGHT_MANIFEST"] = "done") => ignAfterFM

\* Phase order restated by hand from AIDLC.md's Inputs, independent of Deps,
\* so an error in the Deps table cannot hide (review finding).
DocOrder ==
    LET D(a, b) == (status[a] = "done" /\ b \in Req) => status[b] = "done"
    IN  /\ D("TRAJECTORY", "FLYBY")
        /\ D("SIMULATION", "FLYBY") /\ D("SIMULATION", "TRAJECTORY")
        /\ D("TELEMETRY", "IGNITION") /\ D("TELEMETRY", "SIMULATION")
        /\ D("RENDEZVOUS", "TELEMETRY")
        /\ D("LANDING_MODULE", "IGNITION") /\ D("LANDING_MODULE", "TELEMETRY")
        /\ status["LANDING_MODULE"] = "done" => setDone["Impl"]
        /\ (status["FLIGHT_MANIFEST"] = "done" /\ "Spec" \in Touched) => setDone["Spec"]

\* A satisfied FLIGHT MANIFEST traces to the current requirement source.
FMSourceCurrent ==
    status["FLIGHT_MANIFEST"] = "done" => fmSource = Req \cap SpecPhases

\* An emergency release needs a completed IGNITION.
ReleaseStep ==
    [][(released' /\ ~released /\ ~closed') => status["IGNITION"] = "done"]_allVars

-----------------------------------------------------------------------------
(* Liveness: with fair progress and bounded disruptions, every session     *)
(* path settles, either closed or read-only.                               *)

Termination == <>Settled

-----------------------------------------------------------------------------
(* Anti-vacuity witnesses. check.sh expects TLC to violate each one, which *)
(* proves the path is reachable.                                           *)

NeverCloseWiffled     == ~(closed /\ tier = "WIFFLED")
NeverCloseAimed       == ~(closed /\ tier = "AIMED")
NeverClosePokayoke    == ~(closed /\ tier = "POKAYOKE")
NeverReadOnlyEnd      == ~(kind = "readonly" /\ session = "ended")
NeverStale            == \A p \in Phases : status[p] # "invalid"
NeverAcceptedClose    == ~(closed /\ residual)
NeverLoweredClose     == ~(closed /\ tier = "WIFFLED" /\ charter["Spec"])
NeverPaused           == session # "paused"
NeverHandoffClose     == ~(closed /\ sessions > 1)
NeverEmergencyRelease == ~(released /\ ~closed)
NeverEmergencyClose   == ~(closed /\ exception)
NeverChatClose        == ~(closed /\ medium = "chat")
NeverRaise            == [][~(tier # "none" /\ Higher(<<tier', pairs'>>, <<tier, pairs>>))]_vars
NeverReadOnlyUpgrade  == [][~(manifest = "readonly" /\ manifest' = "full")]_vars
NeverResume           == [][~(session = "paused" /\ session' = "active")]_vars
NeverLMBeforeTEL      == ~(status["LANDING_MODULE"] = "active" /\ status["TELEMETRY"] = "todo")
NeverPostReleaseWait  == ~(released /\ ~closed /\ status["IGNITION"] = "invalid"
                           /\ status["FLIGHT_MANIFEST"] # "done")
=============================================================================

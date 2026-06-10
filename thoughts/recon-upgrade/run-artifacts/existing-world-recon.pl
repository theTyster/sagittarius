% existing-world-recon.pl
% =============================================================================
% close-world DELTA (recon revision) over:
%   docs/design-spec.md  (the "Recon extension (this revision)" pass)
%
% ATTACH mode. This file extends the verified baseline at
%   self-spec/existing-world.pl
% with ONLY the NEW recon declarations the spec introduces:
%   - §1   "Recon extension (this revision)" proposition + its falsifiers
%   - §5   D-14  (recon primer — the Orbital-Inversion-safe front door)
%   - §6   C-7   (recon reports facts, never a verdict)
%   - §7   I-8   (recon soundness)
%   - §9   acceptance criteria 12..15 (behavioral) + the I-8 formal criterion
%
% It REUSES the baseline predicate vocabulary verbatim (decision/3,
% decision_rationale/2, decision_table/4, constraint/3, invariant/3,
% invariant_formalizes/2, acceptance_criterion/3, proposition/2, falsifier/1,
% formal_property_sketch/3, formal_criterion_targets/2, behavioral_seeds/2,
% negation_provenance/2). It does NOT re-extract any baseline fact.
%
% CWA: everything asserted below is true; everything absent is, by the Closed
% World Assumption, FALSE (absent in the source, NOT proven false). Where the
% spec EXPLICITLY negates something the recon primer must never do, it is
% recorded under negation_provenance/2 with provenance `contradicts`.
%
% C-7 / the Orbital Inversion: the recon step (and this close-world stage)
% REPORT facts; verdicts are an agent's job. Nothing here computes or asserts a
% logic verdict (consistent / proven / refuted / inconsistent). A consistent or
% proven verdict is earned only after a genuine falsification attempt fails.
% =============================================================================

% These predicates are ALSO defined in the baseline existing-world.pl. Declare
% them :- multifile so this delta ACCUMULATES clauses onto the baseline's
% predicate surface (ATTACH mode) when both files are consulted in one session,
% rather than triggering "redefined static procedure" warnings. multifile also
% covers the discontiguous case, so the delta strict-loads standalone too.
:- multifile
     proposition/2,
     falsifier/1,
     decision/3,
     decision_rationale/2,
     decision_table/4,
     constraint/3,
     invariant/3,
     invariant_formalizes/2,
     formal_property_sketch/3,
     acceptance_criterion/3,
     formal_criterion_targets/2,
     behavioral_seeds/2,
     negation_provenance/2.

% Predicates introduced FRESH by this delta (no baseline definition); declared
% discontiguous so their clauses may be grouped with their documentation blocks.
:- discontiguous
     recon_mode/2,
     recon_reports/2,
     recon_never/1,
     plan_recon_reads/1,
     plan_recon_never/1,
     constraint_specializes/2,
     open_question/2,
     recon_violation/1.

% -----------------------------------------------------------------------------
% §1 — Recon-extension proposition (decompose-proposition would lift this as a
% conservative-extension companion to p1). proposition(Id, Text).
% -----------------------------------------------------------------------------

proposition(p_recon,
  'The same proven loop admits a recon primer - a pre-loop step that resolves where durable artifacts live and which segments run - so the loop can start mid-chain against a maintained repo without weakening any of I-1..I-7. The only new obligation is I-8 (recon soundness): every honored window seeds a complete, contiguous prefix, so gating holds at the start. Recon reports facts and recommends a window; it never computes a verdict (C-7).').

% Falsifiers of the recon-extension proposition (each, if it holds, refutes it).
falsifier(seeded_run_violates_i2_gating).
falsifier(recon_computes_a_logic_verdict).            % a C-2 / Orbital-Inversion violation
falsifier(frozenprefix_attach_run_regenerates_adopted_artifact).

% -----------------------------------------------------------------------------
% §5 — D-14 Recon primer. decision/3 + decision_rationale/2 (PATTERN A).
% -----------------------------------------------------------------------------

decision(d14, recon_primer,
  'A pre-loop step resolves a per-artifact path map + present-artifact set (existence + strict-load) and proposes a {from,to} window; the movable cursor seeds from it instead of the fixed cold (0, empty). Operator from/to is authoritative (validated for feasibility only); else attach (a claim is supplied -> judge which tail segments it needs against present artifacts) or resume (no claim -> continue from the first missing durable artifact).').
decision_rationale(d14,
  'Lets the proven loop run claim-by-claim against a maintained repo (the kimmy shape) without rebuilding its world; a startIdx=0 plan reproduces the cold run exactly, so it is a conservative extension. The judgment (which window) lives in a recon agent (.claude/agents/recon.md, model:opus); the fold + guard (lib/recon-plan.js -> planRecon) is pure mechanics (D-2).').

% D-14 authority split (the D-2 mechanics/judgment boundary applied to recon).
% decision_table(D, RowIndex, Mechanics, Judgment).
decision_table(d14, 1,
  'planRecon fold + feasibility guard (lib/recon-plan.js); seed cursor/scope/produced from the plan',
  'which {from,to} window; which tail segments an attach claim needs').

% The three recon resolution modes D-14 enumerates.
% recon_mode(Mode, Description).
recon_mode(operator,
  'Operator-supplied from/to is authoritative; planRecon validates it for feasibility only (never overrides the window choice).').
recon_mode(attach,
  'A claim is supplied; the recon agent judges which tail segments it needs against the present-artifact set.').
recon_mode(resume,
  'No claim; continue from the first missing durable artifact.').

% -----------------------------------------------------------------------------
% §6 — C-7 Recon reports facts, never a verdict. constraint/3 (the boundary
% guard for the primer; C-7 is C-2 / the Orbital Inversion applied to recon).
% -----------------------------------------------------------------------------

constraint(c7, recon_reports_facts_never_verdict,
  'The recon step may report presence (exists + strict-load - mechanical observations) and recommend a window; it must never compute a logic verdict (consistent / refuted / proven / inconsistent) nor edit a durable artifact. planRecon reads only those agent-emitted facts plus the operator window and verifies them; it never inspects artifact content. (C-7 is C-2 / the Orbital Inversion applied to the primer.)').

% What recon is PERMITTED to report (mechanical observations only).
% recon_reports(Kind, Description).
recon_reports(presence_exists,    'whether each durable artifact exists - a mechanical observation.').
recon_reports(presence_strict_load, 'whether each present artifact strict-loads - a mechanical observation.').
recon_reports(window_recommendation, 'a recommended {from,to} window (a recommendation, not a verdict).').

% What recon must NEVER do (the C-7 / Orbital-Inversion prohibitions).
% recon_never(Action).
recon_never(compute_logic_verdict).        % consistent / refuted / proven / inconsistent
recon_never(edit_durable_artifact).

% What planRecon (pure mechanics) is allowed to read, and what it must not do.
% plan_recon_reads(Source).  plan_recon_never(Action).
plan_recon_reads(agent_emitted_recon_facts).
plan_recon_reads(operator_window).
plan_recon_never(inspect_artifact_content).

% C-7 is the recon-scoped specialization of C-2.
% constraint_specializes(Narrower, Broader).
constraint_specializes(c7, c2).

% -----------------------------------------------------------------------------
% §7 — I-8 Recon soundness. invariant/3 + the formal-property sketch §10 hands
% to prove-invariants, plus the formalization links (PATTERN B / PATTERN H).
% -----------------------------------------------------------------------------

invariant(i8, recon_soundness,
  'Every honored window seeds a complete, contiguous prefix: the loop seed produced set is exactly { stage_i : i < startIdx } and every such stage is present + strict-loads - so artifact-gating (I-2) holds at the seed. Refinement (attach): a loopback never widens below the adopted prefix (frozenPrefix). Generalizes the loop start from the fixed (0, empty); I-1..I-7 are preserved (I-2 is static; I-4 already ranges over non-zero, decreasing startIdx). (Formalizes D-14 / C-7.)').

% I-8 formalizes BOTH D-14 (the primer it constrains) and C-7 (the boundary).
invariant_formalizes(i8, d14).
invariant_formalizes(i8, c7).

% Formal-property sketch (kind = safety: a seed-time gating guarantee).
formal_property_sketch(i8, safety,
  'forall honored window W with start index startIdx: seed_produced(W) = { stage_i : i < startIdx } AND forall i < startIdx: present(stage_i) AND strict_loads(stage_i); attach refinement: no loopback widens below frozenPrefix; startIdx=0 reproduces the cold (0, empty) seed.').

% -----------------------------------------------------------------------------
% §9 — Acceptance criteria 12..15 (behavioral) + the I-8 formal criterion.
% acceptance_criterion(Id, Layer, Text).  Layer in {behavioral, formal}.
% Numbered b12..b15 to extend the baseline's behavioral b1..b11.
% -----------------------------------------------------------------------------

acceptance_criterion(b12, behavioral,
  'Seed the cursor / scope / produced from the recon plan (a non-zero start runs only the windowed segments; a startIdx=0 plan reproduces the cold run).').
acceptance_criterion(b13, behavioral,
  'Clamp an over-eager attach window down to the first incomplete prefix stage (override-and-report), keeping the seed a complete contiguous prefix.').
acceptance_criterion(b14, behavioral,
  'Refuse an operator window whose prefix is not all present (feasible:false) - and still run explain.').
acceptance_criterion(b15, behavioral,
  'Hard-stop a loopback that would widen below a frozen (attach-adopted) prefix.').

% Formal criterion: I-8 machine-checked in Lean under the D-10 bounds.
% (§9 records that I-8's teeth MAY resolve to a behavioral criterion if
% prove-invariants finds the abstract form a vacuous corollary of I-2 - an OPEN
% QUESTION for the dogfood, explicitly NOT pre-judged. Captured as a fact, not
% a verdict: open_question/2.)
acceptance_criterion(f8, formal,
  'I-8 machine-checked in Lean under the D-10 bounds.').
formal_criterion_targets(f8, i8).

% open_question(Id, Text) - recorded, not resolved (no verdict computed here).
open_question(i8_vacuity,
  'I-8 teeth may resolve to a behavioral acceptance criterion if prove-invariants finds the abstract form a vacuous corollary of I-2; recorded as an open question for the dogfood, not pre-judged.').

% Behavioral criteria seed links back to the recon decision/constraint they exercise.
% behavioral_seeds(CriterionId, RelatedDecisionOrConstraint).
behavioral_seeds(b12, d14).   % seed cursor/scope/produced from the recon plan
behavioral_seeds(b12, i8).
behavioral_seeds(b13, d14).   % attach-window clamp (override-and-report)
behavioral_seeds(b13, i8).
behavioral_seeds(b14, c7).    % operator window feasibility refusal; still explain
behavioral_seeds(b14, i8).
behavioral_seeds(b15, i8).    % frozenPrefix loopback hard-stop

% -----------------------------------------------------------------------------
% NEGATION PROVENANCE — the EXPLICIT recon negations (provenance = contradicts).
% These mirror the §1 recon-extension falsifiers and the C-7 prohibitions: the
% spec asserts the primer must NEVER do these, so they are contradicted (not
% merely absent). negation_provenance(Fact, Provenance).
% -----------------------------------------------------------------------------

negation_provenance(recon_computes_logic_verdict, contradicts).            % C-7 / C-2
negation_provenance(recon_edits_durable_artifact, contradicts).            % C-7
negation_provenance(plan_recon_inspects_artifact_content, contradicts).    % C-7
negation_provenance(seeded_run_violates_i2_gating, contradicts).           % §1 falsifier / I-8
negation_provenance(frozenprefix_attach_regenerates_adopted_artifact, contradicts). % §1 falsifier / I-8
negation_provenance(loopback_widens_below_frozen_prefix, contradicts).     % I-8 refinement / b15

% -----------------------------------------------------------------------------
% CONSTRAINT RULES — recon-scoped validators (queryable; succeed = a violation).
% Mirrors the baseline violation/1 family; these check the delta's invariants.
% -----------------------------------------------------------------------------

% RV1: I-8 must be linked to BOTH the decision (D-14) and constraint (C-7) it
%      formalizes (the spec's explicit "Formalizes D-14 / C-7").
recon_violation(i8_missing_formalizes(Source)) :-
    member(Source, [d14, c7]),
    \+ invariant_formalizes(i8, Source).

% RV2: I-8 must carry a formal-property sketch so decompose can lift it.
recon_violation(i8_without_sketch) :-
    invariant(i8, _, _),
    \+ formal_property_sketch(i8, _, _).

% RV3: C-7 must be recorded as a specialization of C-2 (it IS the Orbital
%      Inversion applied to the primer).
recon_violation(c7_not_specializing_c2) :-
    constraint(c7, _, _),
    \+ constraint_specializes(c7, c2).

% RV4: every recon_never/1 prohibition must have a contradicts provenance, so a
%      forbidden recon action can never be silently absent (CWA) - it is denied.
recon_violation(unguarded_recon_prohibition(verdict)) :-
    recon_never(compute_logic_verdict),
    \+ negation_provenance(recon_computes_logic_verdict, contradicts).
recon_violation(unguarded_recon_prohibition(edit)) :-
    recon_never(edit_durable_artifact),
    \+ negation_provenance(recon_edits_durable_artifact, contradicts).

% RV5: D-14 must enumerate all three resolution modes the spec names.
recon_violation(missing_recon_mode(M)) :-
    member(M, [operator, attach, resume]),
    \+ recon_mode(M, _).

% RV6 (Orbital-Inversion guard): nothing in the recon delta may assert a logic
%      verdict. There is no verdict/2 fact here; if one ever appears, flag it.
recon_violation(verdict_laundered_into_recon_kb) :-
    current_predicate(verdict/2),
    catch(call(verdict, _, _), _, fail).

% Aggregate: the recon delta is consistent iff there are no recon_violations.
recon_kb_consistent :- \+ recon_violation(_).

% =============================================================================
% GAPS (underspecified in the source — recorded, never invented):
%   GAP-1: D-14 names lib/recon-plan.js -> planRecon and .claude/agents/recon.md
%          (model:opus) as the mechanics/judgment split, but the spec does not
%          give planRecon's fold signature or the recon agent's digest shape.
%          Not modeled as facts beyond the named split (plan_recon_reads/1,
%          plan_recon_never/1).
%   GAP-2: I-8 says "I-1..I-7 are preserved" and cites I-2 (static) and I-4
%          (already ranges over non-zero startIdx) as the reason, but does NOT
%          enumerate the preservation argument for I-1,I-3,I-5,I-6,I-7. Left as
%          the prove-invariants obligation; not asserted here.
%   GAP-3: §9 records that I-8 MAY collapse to a behavioral criterion if its
%          abstract form is a vacuous corollary of I-2 - explicitly an OPEN
%          QUESTION (open_question/2), NOT resolved. No verdict computed.
%   GAP-4: "first missing durable artifact" (resume) and "first incomplete
%          prefix stage" (attach clamp, b13) presuppose a per-artifact path map
%          / stage<->artifact correspondence whose concrete entries the spec
%          does not enumerate. Not invented here; the baseline's stage/2 +
%          consumption_step/3 are the closest existing surface.
% =============================================================================
% PATTERNS CAPTURED (extending the baseline's A..H):
%   PATTERN I — "conservative extension": D-14 generalizes the loop start from
%     the fixed cold (0, empty); a startIdx=0 plan reproduces the cold run
%     exactly. I-8 is the soundness obligation that makes the generalization
%     gating-safe. Captured by p_recon + i8 + the startIdx=0 clause in the
%     i8 sketch.
%   PATTERN J — "boundary guard specialization": C-7 is C-2 applied to the
%     primer (constraint_specializes/2), exactly as the baseline's C-2 guards
%     the substrate. The Orbital Inversion is the named failure on both.
% =============================================================================

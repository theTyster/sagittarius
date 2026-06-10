// =============================================================================
// sagittarius-2.realized.mjs   (SKETCH — Sagittarius-Prime + the recon primer)
//
// A FREE-HAND derivative of realized/sagittarius.realized.mjs ("Prime"). The
// goal is the SMALLEST faithful delta that adds the recon/primer step:
//
//   recon (NEW pre-loop) -> disprove floor -> movable-cursor loop SEEDED from
//   the recon plan (was: fixed cold (0, ∅)) -> explain (unchanged closer).
//
// CONVENTION FOR THIS SKETCH. Unchanged Prime sections are NOT recopied; they are
// marked with a banner:
//     // ===== CARRIED VERBATIM FROM Prime: <section> =====
// Everything written out in full below is either NEW or CHANGED, tagged inline.
// A real Sagittarius-2 would inline the carried sections byte-for-byte so the two
// files line-diff cleanly (the repo's "inline mechanics verbatim" rule).
//
// PROOF NOTE. The recon delta GENERALIZES the loop's seed from the fixed
// (cursor=0, produced=∅, scope={0,EXPLAIN}) to a WellFormedStart. A plan with
// startIdx=0 and an empty produced reproduces Prime's cold run EXACTLY — so this
// is a conservative extension. The new obligation is I-8 (recon soundness),
// proven over the same non-degenerate model that carries I-1..I-7 (which the model
// ALREADY exercises at non-zero, decreasing startIdx — see TargetWorld.lean
// StartIdx r0: 3->1->0). C-2 / the Orbital Inversion is held: recon REPORTS facts
// and RECOMMENDS a window; planRecon (mechanics) VERIFIES and clamps; no verdict
// is computed in the substrate.
// =============================================================================

export const meta = {
  name: "sagittarius-2",
  description:
    // CHANGED: prepend the recon primer to Prime's description.
    "Sagittarius + recon primer. A recon agent (model:opus) resolves the per-artifact path map and present-artifact set and proposes a {from,to} window; planRecon folds it into a WellFormedStart seed (I-8). Then the mandatory disprove floor, then the movable-cursor loop SEEDED from the recon plan (close_world..measure, windowable), then the always-runs explain closer. Branches only on agent-emitted digest fields (C-2 / Orbital Inversion held). frozenPrefix protects an adopted prefix from loopback regeneration.",
  phases: [
    // NEW phase, first:
    { title: "recon", detail: "Pre-loop primer: resolve where durable artifacts live + which are present (existence + strict-load), propose the segment window (operator from/to wins; else attach when a claim is supplied, else resume). Reports facts + a recommendation; NEVER computes a verdict (Orbital Inversion forbidden)." },
    // ... CARRIED VERBATIM FROM Prime: the disprove / close_world / decompose /
    //     model_obligations / prove_invariants / instantiate / realize / measure /
    //     explain phase entries (unchanged).
  ],
};

// ===== CARRIED VERBATIM FROM Prime: INLINED MECHANICS =====
//   lib/stage-order.js      (STAGE_SEQUENCE, stageIndex, stageSuccessor,
//                            requiredUpstream, canRunStage)        — UNCHANGED
//   lib/gap-batching.js     (mergeGaps)                            — UNCHANGED
//   lib/loop-limit.js       (LOOP_LIMIT, loopbacksFor, withinLoopLimit) — UNCHANGED
//   lib/scope-set.js        (widenScope)                           — UNCHANGED
//   lib/disprove-reserve.js (planDisproveAttempt, chooseTarget)    — UNCHANGED
//   lib/termination-measure.js (measureM, lexLt, stepForward,
//                            stepLoopback, initialRecoveryBudgetSum)— UNCHANGED
//     (only its SEED differs at runtime: cursorDistance starts at endIdx-startIdx,
//      recoveryBudgetSum over the reachable recovery keys — no code change.)
//   lib/decision-trail.js   (createTrail)                          — UNCHANGED
//   lib/digest-router.js    (routeDigest)                          — UNCHANGED
//   EXPLAIN_IDX, RECOVERY_KEYS constants                           — UNCHANGED
// (Assume all of the above are present here exactly as in Prime.)

// -----------------------------------------------------------------------------
// schemas/stage-digest.schema.js  — CHANGED: two new hard-stop reasons.
// -----------------------------------------------------------------------------
// ===== CARRIED VERBATIM FROM Prime: DIGEST_STATUS, ROUTABLE_FIELDS, =====
//        isRoutableDigest                                            — UNCHANGED
const HARD_STOP_REASONS = Object.freeze({
  CORE_OBLIGATION_REFUTED: "core_obligation_refuted",
  LOOP_LIMIT_EXHAUSTED: "loop_limit_exhausted",
  BUDGET_EXHAUSTED: "budget_exhausted",
  // NEW (recon): the operator declared a window whose prefix is not all present.
  RECON_INFEASIBLE_WINDOW: "recon_infeasible_window",
  // NEW (recon, attach): a loopback would widen below the adopted frozen prefix.
  GAP_BELOW_FROZEN_PREFIX: "gap_below_frozen_prefix",
});

// #############################################################################
// ## NEW INLINED MECHANIC: lib/recon-plan.js (verbatim from lib/).            ##
// ## Pure fold of the recon descriptor (+ operator window from args) into the ##
// ## loop seed, enforcing I-8: produced is always a complete contiguous       ##
// ## prefix. MECHANICS ONLY — reads agent-emitted facts (stagesComplete) and  ##
// ## the operator window; never inspects artifact content (Orbital Inversion).##
// #############################################################################

const MEASURE_IDX = stageIndex("measure"); // 6 — interior upper bound; explain is the closer

function resolveFrom(name) {
  const i = stageIndex(name);
  if (i < 0) return 0;                 // unknown/absent -> cold start (run MORE, never less)
  return i > MEASURE_IDX ? MEASURE_IDX : i;
}
function resolveTo(name) {
  const i = stageIndex(name);
  return i < 0 || i > MEASURE_IDX ? MEASURE_IDX : i; // unknown/explain -> measure
}
function firstIncompletePrefixIndex(startIdx, stagesComplete) {
  for (let i = 0; i < startIdx; i++) {
    if (!stagesComplete[STAGE_SEQUENCE[i]]) return i;
  }
  return -1;
}
function incompletePrefixStages(startIdx, stagesComplete) {
  const out = [];
  for (let i = 0; i < startIdx; i++) {
    if (!stagesComplete[STAGE_SEQUENCE[i]]) out.push(STAGE_SEQUENCE[i]);
  }
  return out;
}
function producedPrefix(startIdx) {
  return STAGE_SEQUENCE.slice(0, Math.max(0, startIdx));
}

// PURE + DETERMINISTIC (C-1). Mode behaviour: operator window (from args) is
// authoritative and only VALIDATED (refuse on a broken prefix, feasible:false);
// attach/resume windows are RECOMMENDATIONS and an incomplete prefix is repaired
// by clamping startIdx DOWN to the first hole (override-and-report) so produced
// stays a complete contiguous prefix (I-8).
function planRecon(input) {
  const descriptor = (input && input.descriptor) || {};
  const operatorWindow = (input && input.operatorWindow) || null;
  const stagesComplete = descriptor.stagesComplete || {};

  const mode = operatorWindow ? "operator" : descriptor.mode || "resume";
  const win = operatorWindow || descriptor.window || {};
  let startIdx = resolveFrom(win.from);
  let endIdx = resolveTo(win.to);
  if (endIdx < startIdx) endIdx = startIdx;

  const proposedStartIdx = startIdx;
  const incomplete = incompletePrefixStages(startIdx, stagesComplete);
  const firstHole = firstIncompletePrefixIndex(startIdx, stagesComplete);

  let feasible = true;
  let overridden = false;
  let reason = null;

  if (firstHole >= 0) {
    if (mode === "operator") {
      feasible = false;
      reason = "prefix_incomplete";
    } else {
      startIdx = firstHole;
      if (endIdx < startIdx) endIdx = startIdx;
      overridden = true;
      reason = "prefix_incomplete";
    }
  }

  const frozenPrefix = mode === "attach" ? true : !!descriptor.frozenPrefix;
  const produced = feasible ? producedPrefix(startIdx) : [];

  return {
    mode, startIdx, endIdx, cursor: startIdx,
    scope: { startIdx, endIdx },
    produced, frozenPrefix, feasible,
    obstructions: mode === "operator" && !feasible ? incomplete : [],
    guard: {
      proposedStartIdx,
      effectiveStartIdx: feasible ? startIdx : proposedStartIdx,
      overridden, reason, incompletePrefixStages: incomplete,
    },
    window: { from: STAGE_SEQUENCE[startIdx], to: STAGE_SEQUENCE[endIdx] },
    artifactMap: descriptor.artifactMap || {},
    claim: descriptor.claim != null ? descriptor.claim : null,
  };
}

// #############################################################################
// ## NEW: the recon descriptor schema the recon agent's output must match.    ##
// #############################################################################
const RECON_DESCRIPTOR_JSONSCHEMA = {
  type: "object",
  required: ["mode", "artifactMap", "stagesComplete", "window"],
  additionalProperties: true, // presence/rationale/claim/etc. ride along
  properties: {
    mode: { type: "string", enum: ["operator", "attach", "resume"] },
    target_repo: { type: ["string", "null"] },
    artifactMap: { type: "object", additionalProperties: { type: "string" } },
    presence: { type: "object", additionalProperties: true },
    stagesComplete: {
      type: "object",
      additionalProperties: { type: "boolean" },
      description: "per-stage present+strict-load — agent-reported FACTS, not a verdict",
    },
    window: {
      type: "object",
      required: ["from", "to"],
      additionalProperties: false,
      properties: { from: { type: "string" }, to: { type: "string" } },
    },
    frozenPrefix: { type: "boolean" },
    feasible: { type: "boolean" },
    obstructions: { type: "array", items: { type: "string" } },
    claim: { type: ["string", "null"] },
    rationale: {
      type: ["string", "null"],
      description: "presence facts + intent ONLY — no verdict words (Orbital Inversion)",
    },
  },
};

// ===== CARRIED VERBATIM FROM Prime: STAGE_DIGEST_JSONSCHEMA, =====
//        SPECIALIST_RESULT_JSONSCHEMA                            — UNCHANGED

// #############################################################################
// ## STAGE_BRIEFS — CHANGED: add a thin `recon` entry; the rest UNCHANGED.    ##
// ##                                                                          ##
// ## NOTE (approach C): the recon agent's heavy role/discipline brief lives in ##
// ## .claude/agents/recon.md (the named `recon` agent, model:opus). So unlike  ##
// ## the shifting:* stages, the workflow supplies only RUN INPUTS here — the   ##
// ## agent file owns the brief. This keeps the workflow thin (a nice property  ##
// ## of putting the judgment in a named agent rather than an inline string).   ##
// #############################################################################
const STAGE_BRIEFS = {
  recon: {
    serial: true,
    digestFields: [], // recon's output is the descriptor, folded by planRecon — not a stage digest
    specialists: [
      {
        agentType: "recon", // the LOCAL agent at .claude/agents/recon.md
        order: 1,
        fanout: false,
        fanoutOver: null,
        // The role/discipline are in the agent file; this is just the run-input frame.
        brief:
          "Plan this sagittarius run. Resolve the per-artifact path map over target_repo, detect which durable artifacts are present (existence + strict-load), and emit the init descriptor (mode/artifactMap/presence/stagesComplete/window/frozenPrefix/feasible/claim/rationale). Operator from/to (if supplied) is authoritative — validate feasibility only. Else attach when a claim is supplied, resume otherwise. Report facts and recommend a window; NEVER assert a logic verdict and NEVER edit a durable artifact (the Orbital Inversion is forbidden).",
        minContext: [
          "target_repo (absolute path)",
          "operator_window {from,to} (optional — authoritative when present)",
          "claim/target text (optional — selects attach mode; same sentence decompose's sharpener reads)",
          "path_hints {artifact-key -> path} (optional)",
          "scratch_dir",
          "the artifact catalog (key -> producing stage -> durable?) from the agent file",
        ],
      },
    ],
  },
  // ===== CARRIED VERBATIM FROM Prime: disprove, close_world, decompose, =====
  //        model_obligations, prove_invariants, instantiate, realize,
  //        measure, explain                                        — UNCHANGED
};

// ===== CARRIED VERBATIM FROM Prime: withContext, briefWith, fanoutSentinel, =====
//        foldDigest (inlined), runStage, runMandatoryDisprove, runExplainCloser
//   — UNCHANGED, except runStage gets ONE threaded arg (see CHANGE note below).
//
// CHANGE (brief-templating): runStage(stage, ctx) now receives ctx.artifactMap and
// templates each specialist brief's durable-artifact paths through it before
// dispatch — i.e. the hardcoded `thoughts/<key>` literals are rewritten to
// plan.artifactMap[<key>] (falling back to the Prime literal when a key is
// unmapped). One helper, applied at the withContext/briefWith seam:
//
//   function templatePaths(text, artifactMap) {
//     if (!artifactMap) return text;
//     let out = text;
//     for (const key of Object.keys(artifactMap)) {
//       // replace the canonical `thoughts/<file>` literal for this key
//       out = out.split(THOUGHTS_PATH[key]).join(artifactMap[key]);
//     }
//     return out;
//   }
//
// This is the single BROAD-BUT-MECHANICAL change (it touches every brief's path
// literals); flagged here, body elided in the sketch.

// #############################################################################
// ## NEW: runRecon — the pre-loop primer (shaped like runMandatoryDisprove).  ##
// #############################################################################
async function runRecon(trail) {
  const a = (typeof args !== "undefined" && args) || {};
  phase("recon");
  log("recon: planning the run (path map + presence + window). Operator window wins; else attach/resume.");

  const spec = STAGE_BRIEFS.recon.specialists[0];
  const runInputs =
    "\n\nRUN INPUTS:" +
    "\n target_repo: " + (a.target_repo || "(this repo / cwd)") +
    "\n operator_window: " + (a.from || a.to ? JSON.stringify({ from: a.from || null, to: a.to || null }) : "(none — fall back to attach/resume)") +
    "\n claim: " + (a.claim || "(none — resume mode)") +
    "\n path_hints: " + JSON.stringify(a.path_hints || {}) +
    "\n scratch_dir: " + (a.scratch_dir || "thoughts/.recon_scratch/");

  // The recon agent REPORTS facts + RECOMMENDS a window (judgment lives in the agent).
  const descriptor = await agent(withContext(spec.brief, spec.minContext) + runInputs, {
    label: "recon:recon",
    phase: "recon",
    agentType: spec.agentType,   // -> .claude/agents/recon.md
    model: "opus",               // orchestration tier
    schema: RECON_DESCRIPTOR_JSONSCHEMA,
  });

  // The SUBSTRATE folds + GUARDS (mechanics). Operator window read DIRECTLY from
  // args wins over the agent's echo (the substrate need not trust the agent here).
  const operatorWindow = a.from || a.to ? { from: a.from, to: a.to } : null;
  const plan = planRecon({ descriptor: descriptor || {}, operatorWindow });

  trail.record("recon", {
    mode: plan.mode,
    window: plan.window,
    startIdx: plan.startIdx,
    endIdx: plan.endIdx,
    feasible: plan.feasible,
    overridden: plan.guard.overridden,
    frozenPrefix: plan.frozenPrefix,
  });
  return plan;
}

// #############################################################################
// ## THE LOOP — CHANGED: seeded from the recon plan, windowed, frozenPrefix.   ##
// ## Every other invariant-bearing line is IDENTICAL to Prime's runPipeline.   ##
// #############################################################################
async function runPipeline(opts = {}) {
  const loopLimit = opts.loopLimit == null ? LOOP_LIMIT : opts.loopLimit;
  const trail = createTrail();

  // NEW: plan the run before any stage runs.
  const plan = await runRecon(trail);

  // NEW: an infeasible operator window is a hard structural stop — but explain
  // STILL runs (I-1). No seed is emitted for an infeasible plan.
  if (!plan.feasible) {
    trail.record("halt", {
      stage: "recon",
      reason: HARD_STOP_REASONS.RECON_INFEASIBLE_WINDOW,
      obstructions: plan.obstructions,
    });
    phase("explain");
    await runExplainCloser();
    trail.record("stage", { stage: "explain", terminal: true });
    return {
      outcome: "hard_stop",
      reason: HARD_STOP_REASONS.RECON_INFEASIBLE_WINDOW,
      trail: trail.entries,
      scope: plan.scope,
    };
  }

  // CHANGED: seed from the plan (WellFormedStart) instead of fixed cold (0, ∅).
  let scope = plan.scope;                  // { startIdx, endIdx }, endIdx <= MEASURE_IDX
  let cursor = plan.cursor;                // = plan.startIdx
  const produced = new Set(plan.produced); // the complete contiguous prefix (I-8)
  // NEW: the frozen floor — attach must not loop back below the adopted prefix.
  const frozenFloor = plan.frozenPrefix ? plan.startIdx : 0;

  // Disprove floor (UNCHANGED) — after recon so it can target the recon claim.
  await runMandatoryDisprove(trail);

  let outcome = "complete";
  let reason = null;

  // CHANGED: interior window ends at scope.endIdx (<= measure), not fixed
  // EXPLAIN_IDX. For a full run (endIdx=measure) this is identical to Prime.
  while (cursor <= scope.endIdx) {
    const stage = STAGE_SEQUENCE[cursor];

    // I-2 gating (UNCHANGED) — holds from the seed because produced is a complete
    // contiguous prefix (I-8): the immediate predecessor is in `produced`.
    if (!canRunStage(stage, produced)) {
      outcome = "hard_stop";
      reason = "artifact_gate_unsatisfied";
      trail.record("halt", { stage, reason });
      break;
    }

    trail.record("stage", { stage, cursor });
    // CHANGED: thread artifactMap so runStage can template brief paths.
    const digest = await runStage(stage, { scope, cursor, artifactMap: plan.artifactMap });
    const decision = routeDigest({ cursor, scope, trail: trail.entries }, digest);

    if (decision.action === "halt") {
      outcome = "hard_stop";
      reason =
        decision.reason ||
        (decision.coreObligation ? HARD_STOP_REASONS.CORE_OBLIGATION_REFUTED : "halt");
      trail.record("halt", { stage, reason, coreObligation: !!decision.coreObligation });
      break;
    }

    if (decision.action === "loopback") {
      const merged = mergeGaps(digest.gaps);
      const gap = merged[0];
      trail.record("gap_merge", { merged, count: merged.length });
      const targetIdx = stageIndex(gap.targetStage);

      // NEW (frozenPrefix guard — the attach refinement of I-8): a loopback below
      // the frozen floor would regenerate an ADOPTED durable artifact. Hard-stop
      // instead of widening. (resume/cold runs: frozenFloor=0, so never trips.)
      if (targetIdx < frozenFloor) {
        outcome = "hard_stop";
        reason = HARD_STOP_REASONS.GAP_BELOW_FROZEN_PREFIX;
        trail.record("halt", { stage, reason, targetStage: gap.targetStage, frozenFloor });
        break;
      }

      // D-7 loop-limit (UNCHANGED).
      if (!withinLoopLimit(trail.entries, gap.gapClass, gap.targetStage, loopLimit)) {
        outcome = "hard_stop";
        reason = HARD_STOP_REASONS.LOOP_LIMIT_EXHAUSTED;
        trail.record("halt", { stage, reason, gapClass: gap.gapClass, targetStage: gap.targetStage });
        break;
      }

      produced.add(stage);
      scope = widenScope(scope, targetIdx); // I-4 (UNCHANGED): startIdx only lowers
      trail.record("loopback", { from: stage, targetStage: gap.targetStage, gapClass: gap.gapClass, targetIdx });
      cursor = targetIdx;
      continue;
    }

    // advance (UNCHANGED).
    produced.add(stage);
    trail.record("advance", { from: stage, to: STAGE_SEQUENCE[cursor + 1] });
    cursor += 1;
  }

  // D-8 / I-1: explain ALWAYS runs, post-loop, unconditional (UNCHANGED).
  phase("explain");
  await runExplainCloser();
  trail.record("stage", { stage: "explain", terminal: true });

  return { outcome, reason, trail: trail.entries, scope };
}

// #############################################################################
// ## TOP-LEVEL BODY — CHANGED: phase('recon') first.                          ##
// #############################################################################
phase("recon");
log("sagittarius-2 (Prime + recon primer): recon -> disprove floor -> seeded movable-cursor loop -> explain. Control branches ONLY on agent-emitted digest fields (C-2 / Orbital Inversion held).");

const result = await runPipeline();

log(
  "pipeline finished: outcome=" + result.outcome +
    (result.reason ? " reason=" + result.reason : "") +
    " scope=[" + result.scope.startIdx + "," + result.scope.endIdx + "]" +
    " trail_entries=" + result.trail.length
);

return {
  outcome: result.outcome,
  reason: result.reason,
  scope: result.scope,
  trail: result.trail,
};

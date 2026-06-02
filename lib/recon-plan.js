// =============================================================================
// Recon plan — fold the recon descriptor into the loop's seed state, enforcing
// I-8 (recon soundness) (D-2 ; C-2 / the Orbital Inversion ; generalizes I-2).
//
// The recon/primer agent runs once before the loop and emits an INIT DESCRIPTOR:
// where each durable artifact lives (artifactMap), which durable artifacts are
// present + strict-load (presence / stagesComplete), and a PROPOSED segment
// window. planRecon folds that descriptor (plus an authoritative operator window,
// if the operator declared from/to in args) into the seed state the loop starts
// from: { cursor, scope:{startIdx,endIdx}, produced, frozenPrefix }.
//
// I-8 (recon soundness) — the property this enforces, to be proven in Lean over
// the generalized WellFormedStart:
//     the seed `produced` set is ALWAYS a COMPLETE, CONTIGUOUS PREFIX of the
//     stage sequence — every stage in `produced` is reported present+loaded, and
//     produced = { STAGE_SEQUENCE[i] : i < startIdx }.
// That precondition is exactly what carries I-2 (gating) through from a non-zero
// start: canRunStage(STAGE_SEQUENCE[startIdx], produced) holds because the
// immediate predecessor is in the contiguous complete prefix. Today the loop
// seeds (cursor=0, produced=∅); a descriptor with startIdx=0 reproduces that cold
// run exactly (backward-compatible).
//
// AUTHORITY (D-2 / the Orbital Inversion / C-2). This is MECHANICS. It reads only
// agent-emitted FACTS — the descriptor's `stagesComplete` (per-stage exists +
// strict-load, a mechanical observation the recon agent made) and the operator's
// declared window — and computes set membership over them. It NEVER inspects
// artifact CONTENT and NEVER decides whether a stage is "logically done" or
// whether the existing spec settles a claim; doing so would be the Orbital
// Inversion (a judgment that belongs to the reasoning agents). The agent PROPOSES
// a window (judgment, in attach/resume); this guard VERIFIES it against the
// reported presence and clamps an unsound prefix — proposal vs verification, the
// same split digest-fold.js keeps between specialist judgment and the routable
// digest.
//
// MIRROR: realized/sagittarius.realized.mjs will inline this function VERBATIM
// (the Workflow-tool host has no require); the bodies must stay byte-identical —
// only the module wiring (require vs inline) differs.
// =============================================================================

"use strict";

const { STAGE_SEQUENCE, stageIndex } = require("./stage-order.js");

// The last INTERIOR stage — the window's upper bound. `explain` (the always-runs
// post-loop closer, I-1) is NEVER an interior window endpoint.
const MEASURE_IDX = stageIndex("measure"); // 6
const EXPLAIN_IDX = stageIndex("explain"); // 7

/**
 * Resolve a window `from` stage name to an interior index. Fail-SAFE: an absent
 * or unresolved name collapses to 0 (cold start) — a bad name runs MORE of the
 * pipeline, never less. `explain` (or any over-range) collapses to the measure
 * bound. Pure.
 */
function resolveFrom(name) {
  const i = stageIndex(name);
  if (i < 0) return 0;
  return i > MEASURE_IDX ? MEASURE_IDX : i;
}

/**
 * Resolve a window `to` stage name to an interior index. Fail-SAFE in the other
 * direction: an absent / unresolved / over-range name collapses to MEASURE_IDX
 * (run to the end of the interior chain) — never silently stops early. Pure.
 */
function resolveTo(name) {
  const i = stageIndex(name);
  return i < 0 || i > MEASURE_IDX ? MEASURE_IDX : i;
}

/**
 * The lowest index in [0, startIdx) whose stage is NOT reported complete, or -1
 * if the whole prefix is complete. `stagesComplete` is AGENT-REPORTED presence —
 * a mechanical fact, not a verdict; reading it is not the Orbital Inversion. Pure.
 *
 * @param {number} startIdx
 * @param {Object<string,boolean>} stagesComplete  per-stage present+loaded flags
 * @returns {number}
 */
function firstIncompletePrefixIndex(startIdx, stagesComplete) {
  for (let i = 0; i < startIdx; i++) {
    if (!stagesComplete[STAGE_SEQUENCE[i]]) return i;
  }
  return -1;
}

/** The incomplete stages within [0, startIdx), in order. Pure. */
function incompletePrefixStages(startIdx, stagesComplete) {
  const out = [];
  for (let i = 0; i < startIdx; i++) {
    if (!stagesComplete[STAGE_SEQUENCE[i]]) out.push(STAGE_SEQUENCE[i]);
  }
  return out;
}

/** The produced set as the contiguous prefix [0, startIdx) — stage names. Pure. */
function producedPrefix(startIdx) {
  return STAGE_SEQUENCE.slice(0, Math.max(0, startIdx));
}

/**
 * Fold the recon descriptor (+ an authoritative operator window, if any) into the
 * loop's seed state, enforcing I-8 (recon soundness). PURE + DETERMINISTIC (C-1):
 * no clock, no RNG, no I/O — it only reads agent-emitted facts and the args.
 *
 * Mode behaviour (the operator-wins fallback the design chose):
 *   - operator (an operator window is present in args): the window is
 *     AUTHORITATIVE. The guard only VALIDATES feasibility — if the proposed prefix
 *     has an incomplete stage it does NOT silently widen; it reports feasible:false
 *     + obstructions and the loop halts-and-explains. (Respect the operator.)
 *   - attach / resume (no operator window): the descriptor's window is a
 *     RECOMMENDATION. An incomplete prefix is repaired by clamping startIdx DOWN to
 *     the first incomplete stage (override-and-report, never silent), keeping
 *     `produced` a complete contiguous prefix (I-8). feasible stays true.
 *
 * @param {object} input
 * @param {object} input.descriptor       the recon agent's init descriptor
 * @param {{from?:string,to?:string}|null} [input.operatorWindow]  the operator's
 *        declared window read DIRECTLY from args — wins over descriptor.window so
 *        the substrate need not trust the agent to have honored it.
 * @returns {{
 *   mode:string, startIdx:number, endIdx:number, cursor:number,
 *   scope:{startIdx:number,endIdx:number}, produced:string[], frozenPrefix:boolean,
 *   feasible:boolean, obstructions:string[],
 *   guard:{proposedStartIdx:number, effectiveStartIdx:number, overridden:boolean,
 *          reason:(string|null), incompletePrefixStages:string[]},
 *   window:{from:string,to:string}, artifactMap:object, claim:(string|null)
 * }}
 */
function planRecon(input) {
  const descriptor = (input && input.descriptor) || {};
  const operatorWindow = (input && input.operatorWindow) || null;
  const stagesComplete = descriptor.stagesComplete || {};

  // An operator window is authoritative and forces 'operator' mode; otherwise the
  // agent's declared mode governs (default 'resume').
  const mode = operatorWindow ? "operator" : descriptor.mode || "resume";

  // Effective window source: operator window wins mechanically over the agent's.
  const win = operatorWindow || descriptor.window || {};
  let startIdx = resolveFrom(win.from);
  let endIdx = resolveTo(win.to);
  if (endIdx < startIdx) endIdx = startIdx; // forward, non-empty window

  const proposedStartIdx = startIdx;
  const incomplete = incompletePrefixStages(startIdx, stagesComplete);
  const firstHole = firstIncompletePrefixIndex(startIdx, stagesComplete);

  let feasible = true;
  let overridden = false;
  let reason = null;

  if (firstHole >= 0) {
    if (mode === "operator") {
      // Authoritative window with a broken prefix: refuse, surface obstruction.
      feasible = false;
      reason = "prefix_incomplete";
    } else {
      // Recommendation with a broken prefix: clamp the start down to the first
      // incomplete stage so [0, startIdx) is a complete contiguous prefix (I-8).
      startIdx = firstHole;
      if (endIdx < startIdx) endIdx = startIdx;
      overridden = true;
      reason = "prefix_incomplete";
    }
  }

  // frozenPrefix: attach adopts durable artifacts it does not own — a loopback
  // below the prefix is a hard-stop, not a silent regenerate (protects an external
  // repo's committed spec_kb). resume/operator default to the descriptor's flag.
  const frozenPrefix = mode === "attach" ? true : !!descriptor.frozenPrefix;

  // An infeasible plan has no valid seed (the loop won't run it); emit no produced.
  const produced = feasible ? producedPrefix(startIdx) : [];

  return {
    mode,
    startIdx,
    endIdx,
    cursor: startIdx,
    scope: { startIdx, endIdx },
    produced,
    frozenPrefix,
    feasible,
    obstructions: mode === "operator" && !feasible ? incomplete : [],
    guard: {
      proposedStartIdx,
      effectiveStartIdx: feasible ? startIdx : proposedStartIdx,
      overridden,
      reason,
      incompletePrefixStages: incomplete,
    },
    window: { from: STAGE_SEQUENCE[startIdx], to: STAGE_SEQUENCE[endIdx] },
    artifactMap: descriptor.artifactMap || {},
    claim: descriptor.claim != null ? descriptor.claim : null,
  };
}

module.exports = {
  MEASURE_IDX,
  EXPLAIN_IDX,
  resolveFrom,
  resolveTo,
  firstIncompletePrefixIndex,
  incompletePrefixStages,
  producedPrefix,
  planRecon,
};

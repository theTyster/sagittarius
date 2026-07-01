// =============================================================================
// Lock-tests: digest-boundary well-formedness guards (C-8 + I-9) — Bundle A.
//
// STATUS: NEW-mechanic tests (the F-12 digest-boundary guards). Kept OUT of
// self-spec/tests/ on purpose (like tests/recon_plan.test.js) so the proven
// dogfood suite's headline counts (24 proof-property + 8 C-2 regression) stay
// intact. Run with: `node --test tests/digest_boundary_guards.test.js`.
//
// WHAT THESE LOCK. F-12's first real-ticket run (#2701) livelocked because the
// realization honored MALFORMED agent-emitted control data at the digest
// boundary — stepping OUTSIDE the proven I-3 Step relation. Bundle A turns two
// of the I-3 model's UNENFORCED premises into runtime guards at the single
// chokepoint (the loopback block in sagittarius.workflow.js / its byte-identical
// mirror in realized/):
//   - C-8: gap.targetStage must be a real stage (stageIndex != -1). A skill
//     name / agent name / claim id folds to -1 and ran as a phantom
//     STAGE_SEQUENCE[-1] re-run from cold (F-12 mechanism #1).
//   - I-9: a loopback target must NOT be downstream of the cursor. A "gap"
//     targeting a later stage (not-yet-done work) is a forward jump the measure's
//     stepLoopback (cursor jumps BACK, distance := endIdx) does not model
//     (F-12 mechanism #3).
//
// BOTH guards are pure mechanics (membership + an integer inequality over the
// in-scope cursor) — the substrate derives NO logic verdict, so the Orbital
// Inversion line (C-2) is NOT crossed. NOT YET CLOSED by Bundle A: the dominant
// F-12 livelock (mechanism #2, a re-spelled gapClass minting fresh budget) — that
// needs the finite-domain budget re-key (I-3-premise / B1).
//
// The over-tighten guards below are load-bearing: I-9 must reject ONLY a forward
// target. In-place repair (targetIdx === cursor — foldDigest's DEFAULT gap) and
// strictly-backward loopbacks both stay legal, bounded by LOOP_LIMIT. A strict
// `targetIdx < cursor` would silently break the loop_limit_exhausted path.
// =============================================================================

"use strict";

const { test } = require("node:test");
const assert = require("node:assert/strict");

const { runPipeline, STAGE_SEQUENCE, EXPLAIN_IDX } = require("../sagittarius.workflow.js");
const { HARD_STOP_REASONS } = require("../schemas/stage-digest.schema.js");

// ---- Digest fixtures (mirror the proof-property suite's shapes) -------------

function cleanDigest(stage) {
  return { stage, artifact: `thoughts/${stage}.pl`, status: "ok", verdict: null, gaps: [], coreObligation: false };
}
function gapDigest(stage, target, gapClass, params = {}) {
  return {
    stage, artifact: `thoughts/${stage}.pl`, status: "ok", verdict: null,
    gaps: [{ targetStage: target, gapClass, params }], coreObligation: false,
  };
}

// A fake agent that emits ONE configurable gap at a named stage (optionally only
// the first time it runs that stage), and clean digests everywhere else. The
// disprove surface mirrors the proof-property suite's makeFakeAgent (>=2
// adversaries, so the mandatory floor / I-7 is satisfied).
function fakeAgent({ gapAt, target, gapClass = "test_gap", once = false }) {
  let fired = 0;
  return {
    runStage(stage) {
      if (stage === gapAt && (!once || fired === 0)) {
        fired += 1;
        return gapDigest(stage, target, gapClass);
      }
      return cleanDigest(stage);
    },
    runDisprove(spec) {
      return {
        target: spec.gateTarget || "gate_target_descriptor",
        ownOutput: spec.ownOutput || "disproof_results",
        spend: 1, reserve: spec.reserve || 1, parallel: true,
        adversaries: ["adv_a", "adv_b"],
      };
    },
  };
}

const run = (spec) => runPipeline({ agent: fakeAgent(spec), clock: () => 0, rng: () => 0 });
const stageVisits = (trail) => trail.filter((e) => e.kind === "stage").map((e) => e.stage);
const haltEntry = (trail) => trail.find((e) => e.kind === "halt");

// =============================================================================
// C-8 — a malformed (off-sequence) targetStage is a structural halt
// =============================================================================

test("C8-1: a loopback gap whose targetStage is not a real stage hard-stops (digest_boundary_malformed)", () => {
  // The exact F-12 shape: a specialist emits a SKILL name as the loopback target.
  const result = run({ gapAt: "decompose", target: "realize-specification" });
  assert.equal(result.outcome, "hard_stop", "an off-sequence targetStage must hard-stop");
  assert.equal(result.reason, HARD_STOP_REASONS.DIGEST_BOUNDARY_MALFORMED);
  const halt = haltEntry(result.trail);
  assert.ok(halt && halt.reason === HARD_STOP_REASONS.DIGEST_BOUNDARY_MALFORMED, "the halt is recorded in the trail");
  assert.equal(halt.targetStage, "realize-specification", "the offending targetStage is logged for audit");
});

test("C8-2: the malformed gap NEVER runs a phantom STAGE_SEQUENCE[-1] re-run-from-cold", () => {
  // F-12 mechanism #1: stageIndex -> -1 set cursor = -1, then STAGE_SEQUENCE[-1]
  // (undefined) ran as a clean no-op that advanced to cursor 0 -> a full re-run
  // from close_world. The guard must halt BEFORE any cursor move.
  const result = run({ gapAt: "decompose", target: "not_a_stage" });
  const visits = stageVisits(result.trail);
  assert.equal(visits.filter((s) => s === "close_world").length, 1, "close_world runs exactly once — no phantom re-run from cold");
  assert.deepEqual(result.trail.filter((e) => e.kind === "loopback"), [], "no loopback was honored");
  assert.equal(result.scope.startIdx, 0, "widenScope was never reached with a negative target (scope unperturbed)");
});

// =============================================================================
// I-9 — a forward (downstream) loopback target is a structural halt
// =============================================================================

test("I9-1: a loopback gap targeting a DOWNSTREAM stage hard-stops (forward_loopback)", () => {
  // At model_obligations (cursor 2), a gap targeting measure (idx 6) is a forward jump.
  const result = run({ gapAt: "model_obligations", target: "measure" });
  assert.equal(result.outcome, "hard_stop", "a forward loopback must hard-stop");
  assert.equal(result.reason, HARD_STOP_REASONS.FORWARD_LOOPBACK);
  const halt = haltEntry(result.trail);
  assert.ok(halt && halt.reason === HARD_STOP_REASONS.FORWARD_LOOPBACK, "the halt is recorded in the trail");
  assert.equal(halt.targetStage, "measure");
  assert.deepEqual(result.trail.filter((e) => e.kind === "loopback"), [], "the forward gap was never honored as a loopback");
});

// =============================================================================
// Over-tighten guards — I-9 must reject ONLY forward; in-place + backward stay legal
// =============================================================================

test("I9-2: in-place repair (targetIdx === cursor) is STILL honored (not a forward halt)", () => {
  // foldDigest's DEFAULT gap targets the current stage (in-place). A re-emitting
  // in-place gap must be honored once and then bounded by LOOP_LIMIT — exactly the
  // existing crit10 behavior — NOT rejected as malformed/forward.
  const result = run({ gapAt: "model_obligations", target: "model_obligations" });
  assert.equal(result.outcome, "hard_stop");
  assert.equal(result.reason, HARD_STOP_REASONS.LOOP_LIMIT_EXHAUSTED, "in-place repair is bounded by LOOP_LIMIT, not rejected by the boundary guards");
  const loopbacks = result.trail.filter((e) => e.kind === "loopback");
  assert.equal(loopbacks.length, 1, "the in-place loopback was honored exactly once before the limit");
  assert.equal(loopbacks[0].targetStage, "model_obligations");
});

test("I9-3: a strictly-backward loopback is honored and the run completes", () => {
  // At prove_invariants (cursor 3), a one-shot gap targeting decompose (idx 1) is a
  // legitimate backward recovery; once honored and re-run clean, the run finishes.
  const result = run({ gapAt: "prove_invariants", target: "decompose", once: true });
  assert.equal(result.outcome, "complete", "a backward loopback that repairs cleanly lets the run complete");
  const loopbacks = result.trail.filter((e) => e.kind === "loopback");
  assert.equal(loopbacks.length, 1, "the backward loopback was honored");
  assert.equal(loopbacks[0].targetStage, "decompose");
});

// =============================================================================
// I-1 / D-8 preserved — explain still runs exactly once, last, on the new halts
// =============================================================================

test("I1-preserved: explain runs exactly once, LAST, on both new structural-halt paths", () => {
  for (const spec of [
    { gapAt: "decompose", target: "skill-name" },        // C-8 malformed
    { gapAt: "model_obligations", target: "measure" },   // I-9 forward
  ]) {
    const visits = stageVisits(run(spec).trail);
    assert.equal(visits.filter((s) => s === "explain").length, 1, `explain runs exactly once (${spec.target})`);
    assert.equal(visits[visits.length - 1], "explain", `explain runs LAST (${spec.target})`);
  }
});

// Guard the fixtures themselves stay aligned with the substrate constants.
test("fixture sanity: EXPLAIN_IDX and STAGE_SEQUENCE match the substrate", () => {
  assert.equal(STAGE_SEQUENCE[EXPLAIN_IDX], "explain");
  assert.equal(STAGE_SEQUENCE.indexOf("realize-specification"), -1, "the C-8 fixture target really is off-sequence");
});

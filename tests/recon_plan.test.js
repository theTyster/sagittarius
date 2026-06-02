// =============================================================================
// Unit tests: lib/recon-plan.js — the recon descriptor fold + I-8 guard.
//
// STATUS: NEW-feature tests (the recon/primer + I-8 recon-soundness). Kept OUT of
// self-spec/tests/ on purpose so the proven dogfood suite's headline counts
// (24 proof-property + 8 C-2 regression) stay intact until the Lean generalization
// (WellFormedStart + I-8) lands. Run with: `node --test tests/recon_plan.test.js`.
//
// Discipline (repo convention): a green gate is necessary but not sufficient. The
// I-8 PROPERTY test asserts the invariant directly (produced is a complete
// contiguous prefix), and the Orbital-Inversion guard test asserts the plan does
// NOT depend on any descriptor field beyond the allowed agent-emitted facts.
// =============================================================================

"use strict";

const { test } = require("node:test");
const assert = require("node:assert/strict");

const {
  STAGE_SEQUENCE,
} = require("../lib/stage-order.js");
const {
  MEASURE_IDX,
  planRecon,
} = require("../lib/recon-plan.js");

// Stage indices for readability.
const I = Object.fromEntries(STAGE_SEQUENCE.map((s, i) => [s, i]));

/** All-false stagesComplete (cold). */
const NONE = {};
/** Mark the contiguous prefix [0, n) complete. */
function completeUpTo(n) {
  const m = {};
  for (let i = 0; i < n; i++) m[STAGE_SEQUENCE[i]] = true;
  return m;
}

// -----------------------------------------------------------------------------
// 1. Cold start — a startIdx=0 descriptor reproduces today's run (backward-compat).
// -----------------------------------------------------------------------------
test("cold start: from close_world reproduces the legacy seed (0, ∅)", () => {
  const plan = planRecon({
    descriptor: {
      mode: "resume",
      window: { from: "close_world", to: "measure" },
      stagesComplete: NONE,
    },
  });
  assert.equal(plan.startIdx, 0);
  assert.equal(plan.endIdx, MEASURE_IDX);
  assert.equal(plan.cursor, 0);
  assert.deepEqual(plan.scope, { startIdx: 0, endIdx: MEASURE_IDX });
  assert.deepEqual(plan.produced, []);
  assert.equal(plan.feasible, true);
  assert.equal(plan.guard.overridden, false);
});

// -----------------------------------------------------------------------------
// 2. Resume with a complete contiguous prefix.
// -----------------------------------------------------------------------------
test("resume: complete prefix seeds produced = that prefix", () => {
  const plan = planRecon({
    descriptor: {
      mode: "resume",
      window: { from: "model_obligations", to: "measure" },
      stagesComplete: completeUpTo(I.model_obligations), // close_world, decompose
    },
  });
  assert.equal(plan.startIdx, I.model_obligations);
  assert.deepEqual(plan.produced, ["close_world", "decompose"]);
  assert.equal(plan.frozenPrefix, false); // resume runs are free to widen
  assert.equal(plan.feasible, true);
});

// -----------------------------------------------------------------------------
// 3. Attach sets frozenPrefix and carries the claim.
// -----------------------------------------------------------------------------
test("attach: frozenPrefix true, claim carried", () => {
  const plan = planRecon({
    descriptor: {
      mode: "attach",
      claim: "week rollup must not double-count overlapping same-bucket intervals",
      window: { from: "instantiate", to: "measure" },
      stagesComplete: completeUpTo(I.instantiate), // 0..3 complete
    },
  });
  assert.equal(plan.startIdx, I.instantiate);
  assert.equal(plan.frozenPrefix, true);
  assert.equal(plan.produced.length, I.instantiate);
  assert.match(plan.claim, /double-count/);
});

// -----------------------------------------------------------------------------
// 4. I-8 GUARD — an over-eager attach window with a HOLE in the prefix is clamped
//    DOWN to the first incomplete stage (override-and-report, never silent).
// -----------------------------------------------------------------------------
test("I-8 guard: attach clamps startIdx down to the first prefix hole", () => {
  const plan = planRecon({
    descriptor: {
      mode: "attach",
      claim: "X",
      window: { from: "model_obligations", to: "measure" }, // proposes start=2
      // close_world present, decompose MISSING -> hole at index 1.
      stagesComplete: { close_world: true, decompose: false },
    },
  });
  assert.equal(plan.guard.proposedStartIdx, I.model_obligations); // 2
  assert.equal(plan.startIdx, I.decompose); // clamped down to the hole (1)
  assert.equal(plan.guard.overridden, true);
  assert.equal(plan.guard.reason, "prefix_incomplete");
  assert.deepEqual(plan.guard.incompletePrefixStages, ["decompose"]);
  assert.deepEqual(plan.produced, ["close_world"]); // contiguous complete prefix
  assert.equal(plan.feasible, true);
});

// -----------------------------------------------------------------------------
// 5. OPERATOR window is authoritative — an infeasible prefix is REFUSED, not
//    clamped (respect the operator's declaration).
// -----------------------------------------------------------------------------
test("operator: infeasible prefix => feasible:false + obstructions, no override", () => {
  const plan = planRecon({
    descriptor: {
      mode: "attach", // ignored — operator window forces 'operator'
      window: { from: "close_world", to: "measure" },
      stagesComplete: { close_world: true, decompose: false }, // hole at 1
    },
    operatorWindow: { from: "realize", to: "measure" }, // needs 0..4 complete
  });
  assert.equal(plan.mode, "operator");
  assert.equal(plan.feasible, false);
  assert.equal(plan.guard.overridden, false);
  assert.ok(plan.obstructions.includes("decompose"));
  assert.deepEqual(plan.produced, []); // infeasible => no valid seed
});

// -----------------------------------------------------------------------------
// 6. OPERATOR window wins over the descriptor's window + mode.
// -----------------------------------------------------------------------------
test("operator window overrides descriptor.window and forces operator mode", () => {
  const plan = planRecon({
    descriptor: {
      mode: "attach",
      window: { from: "close_world", to: "decompose" },
      stagesComplete: completeUpTo(I.realize), // 0..5 complete
    },
    operatorWindow: { from: "realize", to: "measure" },
  });
  assert.equal(plan.mode, "operator");
  assert.equal(plan.window.from, "realize");
  assert.equal(plan.window.to, "measure");
  assert.equal(plan.startIdx, I.realize);
  assert.equal(plan.feasible, true);
});

// -----------------------------------------------------------------------------
// 7. endIdx never exceeds measure — `explain` collapses to the measure bound.
// -----------------------------------------------------------------------------
test("to=explain collapses to the measure bound (explain is the closer, never in-window)", () => {
  const plan = planRecon({
    descriptor: { mode: "resume", window: { from: "close_world", to: "explain" }, stagesComplete: NONE },
  });
  assert.equal(plan.endIdx, MEASURE_IDX);
  assert.equal(plan.window.to, "measure");
});

// -----------------------------------------------------------------------------
// 8. Fail-safe name resolution: unknown `from` -> cold start; unknown `to` -> measure.
// -----------------------------------------------------------------------------
test("fail-safe: unresolved stage names never skip work", () => {
  const plan = planRecon({
    descriptor: { mode: "resume", window: { from: "bogus", to: "alsobogus" }, stagesComplete: NONE },
  });
  assert.equal(plan.startIdx, 0); // unknown from -> 0 (run more, never less)
  assert.equal(plan.endIdx, MEASURE_IDX); // unknown to -> measure
});

// -----------------------------------------------------------------------------
// 9. Inverted window collapses to a forward, non-empty window.
// -----------------------------------------------------------------------------
test("inverted window (from>to) collapses to [from, from]", () => {
  const plan = planRecon({
    descriptor: {
      mode: "resume",
      window: { from: "measure", to: "close_world" },
      stagesComplete: completeUpTo(I.measure), // 0..5 complete so start=measure is sound
    },
  });
  assert.equal(plan.startIdx, I.measure);
  assert.equal(plan.endIdx, I.measure);
});

// -----------------------------------------------------------------------------
// 10. I-8 PROPERTY (teeth): for ANY feasible plan, `produced` is EXACTLY the
//     contiguous prefix [0, startIdx) AND every stage in it is reported complete.
//     Swept across many descriptors so a degenerate pass can't hide.
// -----------------------------------------------------------------------------
test("I-8 property: produced is always a complete contiguous prefix", () => {
  const modes = ["resume", "attach"];
  for (const mode of modes) {
    for (let propose = 0; propose <= MEASURE_IDX; propose++) {
      for (let completeN = 0; completeN <= MEASURE_IDX; completeN++) {
        const sc = completeUpTo(completeN);
        const plan = planRecon({
          descriptor: {
            mode,
            claim: mode === "attach" ? "c" : null,
            window: { from: STAGE_SEQUENCE[propose], to: "measure" },
            stagesComplete: sc,
          },
        });
        if (!plan.feasible) continue; // operator-only path; not exercised here
        // produced is exactly the prefix [0, startIdx)
        assert.deepEqual(plan.produced, STAGE_SEQUENCE.slice(0, plan.startIdx),
          `produced must be the prefix for mode=${mode} propose=${propose} completeN=${completeN}`);
        // every produced stage is reported complete (no laundering)
        for (const s of plan.produced) {
          assert.equal(sc[s], true,
            `produced stage ${s} must be reported complete (mode=${mode} propose=${propose} completeN=${completeN})`);
        }
        // gating carries: the seed start's predecessor is in produced (or start=0)
        if (plan.startIdx > 0) {
          assert.ok(plan.produced.includes(STAGE_SEQUENCE[plan.startIdx - 1]));
        }
      }
    }
  }
});

// -----------------------------------------------------------------------------
// 11. ORBITAL-INVERSION guard: the plan must NOT depend on any descriptor field
//     beyond the allowed agent-emitted facts. Injecting a verdict word / arbitrary
//     content changes NOTHING — the mechanic never reads or routes on it.
// -----------------------------------------------------------------------------
test("Orbital-Inversion guard: verdict/content fields do not influence the plan", () => {
  const base = {
    mode: "attach",
    claim: "c",
    window: { from: "instantiate", to: "measure" },
    stagesComplete: completeUpTo(I.instantiate),
    artifactMap: { "target-world": "spec_kb/target-world-curated.pl" },
  };
  const clean = planRecon({ descriptor: { ...base } });
  const contaminated = planRecon({
    descriptor: {
      ...base,
      verdict: "inconsistent",            // a logic verdict — must be ignored
      adequacy: "spec_already_proves_it", // a content judgment — must be ignored
      rationale: "totally different prose",
      presence: { "target-world": { exists: true, load: "load_ok" } },
    },
  });
  // Identical control output despite the injected verdict/judgment fields.
  assert.deepEqual(
    { ...contaminated, /* rationale isn't part of the plan output anyway */ },
    { ...clean }
  );
});

// -----------------------------------------------------------------------------
// 12. Determinism (C-1): same input -> identical plan, every time.
// -----------------------------------------------------------------------------
test("determinism: identical input yields identical plan", () => {
  const input = {
    descriptor: {
      mode: "attach",
      claim: "c",
      window: { from: "model_obligations", to: "measure" },
      stagesComplete: completeUpTo(I.model_obligations),
    },
  };
  assert.deepEqual(planRecon(input), planRecon(input));
});

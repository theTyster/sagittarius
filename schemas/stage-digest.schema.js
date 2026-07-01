// =============================================================================
// Stage digest schema (D-3: state via files, control via digest).
//
// Each pipeline stage returns a structured DIGEST. The orchestration substrate
// branches ONLY on these fields (C-2 / D-2 separation of authority) — it never
// inspects artifact CONTENT and never computes a logic verdict itself.
//
// A digest carries:
//   - stage          : the stage that produced it
//   - artifact       : reference to the thoughts/*.pl state file (state via files)
//   - status         : 'ok' | 'halt'                (agent-emitted)
//   - verdict        : agent-emitted logic verdict signal or null
//                      (the substrate READS it; it MUST NOT derive it)
//   - gaps           : array of routed gaps, each tagged with a target stage
//   - coreObligation : flag — this stage carries a core obligation (D-5 hard-stop)
//   - reason         : present on halt digests; agent-emitted hard-stop reason
//
// A gap is { targetStage, gapClass, params } — the loopback request descriptor
// (D-4: backward motion only to honor a routed gap).
// =============================================================================

"use strict";

/** The allowed digest status values (agent-emitted). */
const DIGEST_STATUS = Object.freeze({ OK: "ok", HALT: "halt" });

/** The fields the substrate is permitted to branch on (C-2 allowlist). */
const ROUTABLE_FIELDS = Object.freeze([
  "status",
  "verdict",
  "gaps",
  "coreObligation",
  "reason",
]);

/**
 * The hard-stop reasons that terminate-and-report (D-5). Two families:
 *   - AGENT-EMITTED: core_obligation_refuted — the substrate NEVER computes the
 *     verdict, it only routes on the matching field (C-2).
 *   - SUBSTRATE-MECHANICAL structural halts: loop_limit_exhausted (D-7 accounting)
 *     and the digest-boundary well-formedness guards below (C-8 / I-9, F-12).
 *     These are pure mechanics — membership in STAGE_SEQUENCE and an integer
 *     inequality over the in-scope cursor — NOT logic verdicts, so C-2 holds.
 */
const HARD_STOP_REASONS = Object.freeze({
  CORE_OBLIGATION_REFUTED: "core_obligation_refuted",
  LOOP_LIMIT_EXHAUSTED: "loop_limit_exhausted",
  BUDGET_EXHAUSTED: "budget_exhausted",
  // C-8 (F-12): a loopback gap whose targetStage is not a real stage
  // (stageIndex -> -1) — the phantom STAGE_SEQUENCE[-1] re-run-from-cold livelock.
  DIGEST_BOUNDARY_MALFORMED: "digest_boundary_malformed",
  // I-9 (F-12): a loopback gap whose target is DOWNSTREAM of the cursor (a forward
  // "gap" for not-yet-done work). A loopback moves backward or re-runs in place,
  // never forward — the I-3 measure's stepLoopback assumes the cursor jumps back.
  FORWARD_LOOPBACK: "forward_loopback",
});

/**
 * Validate the shape of a digest enough for the substrate to route it.
 * Returns true if the digest carries the routable fields in a usable form.
 * (Deliberately structural — it does NOT judge the verdict.)
 */
function isRoutableDigest(d) {
  return (
    d != null &&
    typeof d === "object" &&
    typeof d.status === "string" &&
    Array.isArray(d.gaps)
  );
}

module.exports = {
  DIGEST_STATUS,
  ROUTABLE_FIELDS,
  HARD_STOP_REASONS,
  isRoutableDigest,
};

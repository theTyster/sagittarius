variant(p11x0, [
    add(attest(a19, divergence, run_target, claim(c2b), agent, '2026-10-15T11:00:00Z')),
    add(attest(a20, model_result, run_now, mutation(m_now, floor, survived), agent, '2026-10-15T11:00:00Z')),
    add(reason(m_target, clamp, 'x')),
    add(derived_from(m_now, m_now)),
    add(budget(laps, 5)),
    add(lap_done(3))]).
expect(p11x0, 'discovery_ready', none).
expect(p11x0, 'no_falsifier(C)', none).
expect(p11x0, 'model_trusted(M)', none).
expect(p11x0, 'lint_issue(Code, Id, _)', none).
expect(p11x0, 'model_unfiled_break(C)', none).
expect(p11x0, 'discovery_unratified(C)', none).
expect(p11x0, 'discovery_decide', none).
variant(p11x1, [
    add(discovery_evidence(log4417, system)),
    add(budget(laps, 5)),
    add(lap_done(2)),
    add(model_run(run_now, m_now, 'sha256:4444444444444444444444444444444444444444444444444444444444444444')),
    replace(subject(m_now, 'models/discount-now.smt2', 'sha256:25847de81516893a8ab780844edf1c3c4eb3eb97b459d06f353f40d9e39b72db'), subject(m_now, 'models/discount-now.smt2', 'sha256:4444444444444444444444444444444444444444444444444444444444444444')),
    add(attest(a19, divergence, run_target, claim(c1), agent, '2026-10-15T11:00:00Z'))]).
expect(p11x1, 'discovery_ready', none).
expect(p11x1, 'no_falsifier(C)', none).
expect(p11x1, 'model_trusted(M)', none).
expect(p11x1, 'lint_issue(Code, Id, _)', none).
expect(p11x1, 'model_unfiled_break(C)', none).
expect(p11x1, 'discovery_unratified(C)', none).
expect(p11x1, 'discovery_decide', none).
variant(p11x2, [
    add(hypothesis(h2, risk, 'x')),
    add(attest(a19, reproduction, log4417, result(h2, not_reproduced), agent, '2026-10-15T11:00:00Z'))]).
expect(p11x2, 'discovery_ready', none).
expect(p11x2, 'no_falsifier(C)', none).
expect(p11x2, 'model_trusted(M)', none).
expect(p11x2, 'lint_issue(Code, Id, _)', none).
expect(p11x2, 'model_unfiled_break(C)', none).
expect(p11x2, 'discovery_unratified(C)', none).
expect(p11x2, 'discovery_decide', none).
variant(p11x3, [
    add(attest(a19, model_result, run_target, mutation(m_target, clamp, survived), agent, '2026-10-15T11:00:00Z')),
    add(reason(m_target, floor, 'x')),
    add(attest(a20, model_result, run_now, calibration(m_target, case('t'), differs), agent, '2026-10-15T11:00:00Z'))]).
expect(p11x3, 'discovery_ready', none).
expect(p11x3, 'no_falsifier(C)', none).
expect(p11x3, 'model_trusted(M)', none).
expect(p11x3, 'lint_issue(Code, Id, _)', none).
expect(p11x3, 'model_unfiled_break(C)', none).
expect(p11x3, 'discovery_unratified(C)', none).
expect(p11x3, 'discovery_decide', none).
variant(p11x4, [
    add(attest(a19, model_result, run_now, mutation(m_now, clamp, killed), agent, '2026-10-15T11:00:00Z')),
    add(reason(m_target, floor, 'x')),
    add(claim(c3, preserve, 'x')),
    add(cites(c3, 'x')),
    add(supersedes(c3, c1))]).
expect(p11x4, 'discovery_ready', none).
expect(p11x4, 'no_falsifier(C)', none).
expect(p11x4, 'model_trusted(M)', none).
expect(p11x4, 'lint_issue(Code, Id, _)', none).
expect(p11x4, 'model_unfiled_break(C)', none).
expect(p11x4, 'discovery_unratified(C)', none).
expect(p11x4, 'discovery_decide', none).
variant(p11x5, [
    add(attest(a19, model_result, run_now, calibration(m_now, case('t'), differs), agent, '2026-10-15T11:00:00Z'))]).
expect(p11x5, 'discovery_ready', none).
expect(p11x5, 'no_falsifier(C)', none).
expect(p11x5, 'model_trusted(M)', none).
expect(p11x5, 'lint_issue(Code, Id, _)', none).
expect(p11x5, 'model_unfiled_break(C)', none).
expect(p11x5, 'discovery_unratified(C)', none).
expect(p11x5, 'discovery_decide', none).
variant(p11x6, [
    add(budget(laps, 5)),
    add(lap_done(2)),
    add(finding(f7, scope(x), system)),
    add(question(q7, c1, 'x')),
    add(raised_by(q7, h1)),
    add(answer(q7, yes, human)),
    add(hypothesis(h2, risk, 'x')),
    add(attest(a19, reproduction, log4417, result(h2, reproduced), agent, '2026-10-15T11:00:00Z')),
    add(attest(a20, divergence, run_target, model(m_now), agent, '2026-10-15T11:00:00Z'))]).
expect(p11x6, 'discovery_ready', none).
expect(p11x6, 'no_falsifier(C)', none).
expect(p11x6, 'model_trusted(M)', none).
expect(p11x6, 'lint_issue(Code, Id, _)', none).
expect(p11x6, 'model_unfiled_break(C)', none).
expect(p11x6, 'discovery_unratified(C)', none).
expect(p11x6, 'discovery_decide', none).
variant(p11x7, [
    add(attest(a19, disproof, m_target, verdict(c1, inconclusive), agent, '2026-10-15T11:00:00Z'))]).
expect(p11x7, 'discovery_ready', none).
expect(p11x7, 'no_falsifier(C)', none).
expect(p11x7, 'model_trusted(M)', none).
expect(p11x7, 'lint_issue(Code, Id, _)', none).
expect(p11x7, 'model_unfiled_break(C)', none).
expect(p11x7, 'discovery_unratified(C)', none).
expect(p11x7, 'discovery_decide', none).
variant(p11x8, [
    add(attest(a19, model_result, run_target, verdict(m_now, bad_case, violated), agent, '2026-10-15T11:00:00Z')),
    add(discovery_evidence(m_target, model)),
    add(attest(a20, model_result, run_now, mutation(m_target, floor, survived), agent, '2026-10-15T11:00:00Z')),
    add(reason(m_target, clamp, 'x')),
    add(attest(a21, model_result, run_now, calibration(m_now, case('t'), differs), agent, '2026-10-15T11:00:00Z'))]).
expect(p11x8, 'discovery_ready', none).
expect(p11x8, 'no_falsifier(C)', none).
expect(p11x8, 'model_trusted(M)', none).
expect(p11x8, 'lint_issue(Code, Id, _)', none).
expect(p11x8, 'model_unfiled_break(C)', none).
expect(p11x8, 'discovery_unratified(C)', none).
expect(p11x8, 'discovery_decide', none).
variant(p11x9, [
    add(attest(a19, disproof, m_target, verdict(c1, refuted), agent, '2026-10-15T11:00:00Z'))]).
expect(p11x9, 'discovery_ready', none).
expect(p11x9, 'no_falsifier(C)', none).
expect(p11x9, 'model_trusted(M)', none).
expect(p11x9, 'lint_issue(Code, Id, _)', none).
expect(p11x9, 'model_unfiled_break(C)', none).
expect(p11x9, 'discovery_unratified(C)', none).
expect(p11x9, 'discovery_decide', none).
variant(p11x10, [
    add(claim(c3, preserve, 'x')),
    add(cites(c3, 'x')),
    add(supersedes(c3, c2)),
    add(encodes(m_now, c3)),
    add(attest(a19, model_result, run_target, verdict(m_target, preserve(c3), sat), agent, '2026-10-15T11:00:00Z')),
    add(attest(a20, disproof, m_target, verdict(c1, abstained), agent, '2026-10-15T11:00:00Z')),
    replace(subject(m_now, 'models/discount-now.smt2', 'sha256:25847de81516893a8ab780844edf1c3c4eb3eb97b459d06f353f40d9e39b72db'), subject(m_now, 'models/discount-now.smt2', 'sha256:4444444444444444444444444444444444444444444444444444444444444444')),
    add(attest(a21, reproduction, run_target, result(h1, reproduced), agent, '2026-10-15T11:00:00Z'))]).
expect(p11x10, 'discovery_ready', none).
expect(p11x10, 'no_falsifier(C)', none).
expect(p11x10, 'model_trusted(M)', none).
expect(p11x10, 'lint_issue(Code, Id, _)', none).
expect(p11x10, 'model_unfiled_break(C)', none).
expect(p11x10, 'discovery_unratified(C)', none).
expect(p11x10, 'discovery_decide', none).
variant(p11x11, [
    add(attest(a19, reproduction, log4417, result(h1, reproduced), agent, '2026-10-15T11:00:00Z')),
    add(model_run(run_now, m_now, 'sha256:4444444444444444444444444444444444444444444444444444444444444444')),
    replace(subject(m_now, 'models/discount-now.smt2', 'sha256:25847de81516893a8ab780844edf1c3c4eb3eb97b459d06f353f40d9e39b72db'), subject(m_now, 'models/discount-now.smt2', 'sha256:4444444444444444444444444444444444444444444444444444444444444444')),
    add(derived_from(m_now, m_target))]).
expect(p11x11, 'discovery_ready', none).
expect(p11x11, 'no_falsifier(C)', none).
expect(p11x11, 'model_trusted(M)', none).
expect(p11x11, 'lint_issue(Code, Id, _)', none).
expect(p11x11, 'model_unfiled_break(C)', none).
expect(p11x11, 'discovery_unratified(C)', none).
expect(p11x11, 'discovery_decide', none).
variant(p11x12, [
    add(discovery_evidence(run_now, system)),
    add(attest(a19, model_result, run_now, verdict(m_now, bad_case, unsat), agent, '2026-10-15T11:00:00Z'))]).
expect(p11x12, 'discovery_ready', none).
expect(p11x12, 'no_falsifier(C)', none).
expect(p11x12, 'model_trusted(M)', none).
expect(p11x12, 'lint_issue(Code, Id, _)', none).
expect(p11x12, 'model_unfiled_break(C)', none).
expect(p11x12, 'discovery_unratified(C)', none).
expect(p11x12, 'discovery_decide', none).
variant(p11x13, [
    add(derived_from(m_now, m_now)),
    add(model_run(run_now, m_now, 'sha256:4444444444444444444444444444444444444444444444444444444444444444')),
    replace(subject(m_now, 'models/discount-now.smt2', 'sha256:25847de81516893a8ab780844edf1c3c4eb3eb97b459d06f353f40d9e39b72db'), subject(m_now, 'models/discount-now.smt2', 'sha256:4444444444444444444444444444444444444444444444444444444444444444')),
    add(attest(a19, divergence, m_now, model(m_now), agent, '2026-10-15T11:00:00Z')),
    add(finding(f7, root_cause(x), system)),
    add(question(q7, c1, 'x')),
    add(raised_by(q7, c1)),
    add(answer(q7, yes, human))]).
expect(p11x13, 'discovery_ready', none).
expect(p11x13, 'no_falsifier(C)', none).
expect(p11x13, 'model_trusted(M)', none).
expect(p11x13, 'lint_issue(Code, Id, _)', none).
expect(p11x13, 'model_unfiled_break(C)', none).
expect(p11x13, 'discovery_unratified(C)', none).
expect(p11x13, 'discovery_decide', none).
variant(p11x14, [
    add(budget(laps, 1)),
    add(lap_done(2)),
    add(attest(a19, divergence, log4417, model(m_now), agent, '2026-10-15T11:00:00Z'))]).
expect(p11x14, 'discovery_ready', none).
expect(p11x14, 'no_falsifier(C)', none).
expect(p11x14, 'model_trusted(M)', none).
expect(p11x14, 'lint_issue(Code, Id, _)', none).
expect(p11x14, 'model_unfiled_break(C)', none).
expect(p11x14, 'discovery_unratified(C)', none).
expect(p11x14, 'discovery_decide', none).
variant(p11x15, [
    add(attest(a19, model_result, run_now, calibration(m_now, case('t'), differs), agent, '2026-10-15T11:00:00Z')),
    add(attest(a20, divergence, run_target, claim(c2), agent, '2026-10-15T11:00:00Z')),
    add(question(q8, c1, 'x')),
    add(budget(laps, 1)),
    add(lap_done(2))]).
expect(p11x15, 'discovery_ready', none).
expect(p11x15, 'no_falsifier(C)', none).
expect(p11x15, 'model_trusted(M)', none).
expect(p11x15, 'lint_issue(Code, Id, _)', none).
expect(p11x15, 'model_unfiled_break(C)', none).
expect(p11x15, 'discovery_unratified(C)', none).
expect(p11x15, 'discovery_decide', none).
variant(p11x16, [
    add(attest(a19, reproduction, log4417, confirms(f1), agent, '2026-10-15T11:00:00Z')),
    add(attest(a20, model_result, run_target, mutation(m_now, floor, killed), agent, '2026-10-15T11:00:00Z')),
    replace(subject(m_now, 'models/discount-now.smt2', 'sha256:25847de81516893a8ab780844edf1c3c4eb3eb97b459d06f353f40d9e39b72db'), subject(m_now, 'models/discount-now.smt2', 'sha256:4444444444444444444444444444444444444444444444444444444444444444'))]).
expect(p11x16, 'discovery_ready', none).
expect(p11x16, 'no_falsifier(C)', none).
expect(p11x16, 'model_trusted(M)', none).
expect(p11x16, 'lint_issue(Code, Id, _)', none).
expect(p11x16, 'model_unfiled_break(C)', none).
expect(p11x16, 'discovery_unratified(C)', none).
expect(p11x16, 'discovery_decide', none).
variant(p11x17, [
    replace(subject(m_now, 'models/discount-now.smt2', 'sha256:25847de81516893a8ab780844edf1c3c4eb3eb97b459d06f353f40d9e39b72db'), subject(m_now, 'models/discount-now.smt2', 'sha256:4444444444444444444444444444444444444444444444444444444444444444')),
    add(attest(a19, disproof, m_target, verdict(c2, inconclusive), agent, '2026-10-15T11:00:00Z'))]).
expect(p11x17, 'discovery_ready', none).
expect(p11x17, 'no_falsifier(C)', none).
expect(p11x17, 'model_trusted(M)', none).
expect(p11x17, 'lint_issue(Code, Id, _)', none).
expect(p11x17, 'model_unfiled_break(C)', none).
expect(p11x17, 'discovery_unratified(C)', none).
expect(p11x17, 'discovery_decide', none).
variant(p11x18, [
    add(attest(a19, disproof, m_target, verdict(c2b, refuted), agent, '2026-10-15T11:00:00Z')),
    add(attest(a20, divergence, run_target, claim(c2), agent, '2026-10-15T11:00:00Z')),
    add(question(q8, c2, 'x')),
    add(model_run(run_now, m_now, 'sha256:4444444444444444444444444444444444444444444444444444444444444444')),
    replace(subject(m_now, 'models/discount-now.smt2', 'sha256:25847de81516893a8ab780844edf1c3c4eb3eb97b459d06f353f40d9e39b72db'), subject(m_now, 'models/discount-now.smt2', 'sha256:4444444444444444444444444444444444444444444444444444444444444444'))]).
expect(p11x18, 'discovery_ready', none).
expect(p11x18, 'no_falsifier(C)', none).
expect(p11x18, 'model_trusted(M)', none).
expect(p11x18, 'lint_issue(Code, Id, _)', none).
expect(p11x18, 'model_unfiled_break(C)', none).
expect(p11x18, 'discovery_unratified(C)', none).
expect(p11x18, 'discovery_decide', none).
variant(p11x19, [
    add(attest(a19, divergence, log4417, model(m_target), agent, '2026-10-15T11:00:00Z'))]).
expect(p11x19, 'discovery_ready', none).
expect(p11x19, 'no_falsifier(C)', none).
expect(p11x19, 'model_trusted(M)', none).
expect(p11x19, 'lint_issue(Code, Id, _)', none).
expect(p11x19, 'model_unfiled_break(C)', none).
expect(p11x19, 'discovery_unratified(C)', none).
expect(p11x19, 'discovery_decide', none).
variant(p11x20, [
    add(budget(laps, 5)),
    add(lap_done(2))]).
expect(p11x20, 'discovery_ready', none).
expect(p11x20, 'no_falsifier(C)', none).
expect(p11x20, 'model_trusted(M)', none).
expect(p11x20, 'lint_issue(Code, Id, _)', none).
expect(p11x20, 'model_unfiled_break(C)', none).
expect(p11x20, 'discovery_unratified(C)', none).
expect(p11x20, 'discovery_decide', none).
variant(p11x21, [
    add(attest(a19, reproduction, m_now, confirms(f1), agent, '2026-10-15T11:00:00Z')),
    add(attest(a20, divergence, log4417, model(m_now), agent, '2026-10-15T11:00:00Z')),
    add(discovery_evidence(run_now, system))]).
expect(p11x21, 'discovery_ready', none).
expect(p11x21, 'no_falsifier(C)', none).
expect(p11x21, 'model_trusted(M)', none).
expect(p11x21, 'lint_issue(Code, Id, _)', none).
expect(p11x21, 'model_unfiled_break(C)', none).
expect(p11x21, 'discovery_unratified(C)', none).
expect(p11x21, 'discovery_decide', none).
variant(p11x22, [
    add(finding(f7, surprise(x), model)),
    add(question(q7, c1, 'x')),
    add(raised_by(q7, f7)),
    replace(subject(m_now, 'models/discount-now.smt2', 'sha256:25847de81516893a8ab780844edf1c3c4eb3eb97b459d06f353f40d9e39b72db'), subject(m_now, 'models/discount-now.smt2', 'sha256:4444444444444444444444444444444444444444444444444444444444444444')),
    add(attest(a19, disproof, m_target, verdict(c2b, inconclusive), agent, '2026-10-15T11:00:00Z')),
    add(hypothesis(h2, risk, 'x')),
    add(attest(a20, reproduction, log4417, result(h2, not_reproduced), agent, '2026-10-15T11:00:00Z'))]).
expect(p11x22, 'discovery_ready', none).
expect(p11x22, 'no_falsifier(C)', none).
expect(p11x22, 'model_trusted(M)', none).
expect(p11x22, 'lint_issue(Code, Id, _)', none).
expect(p11x22, 'model_unfiled_break(C)', none).
expect(p11x22, 'discovery_unratified(C)', none).
expect(p11x22, 'discovery_decide', none).
variant(p11x23, [
    add(derived_from(m_now, m_target)),
    add(attest(a19, model_result, run_now, mutation(m_target, clamp, survived), agent, '2026-10-15T11:00:00Z')),
    add(attest(a20, divergence, run_now, model(m_target), agent, '2026-10-15T11:00:00Z')),
    add(hypothesis(h2, risk, 'x'))]).
expect(p11x23, 'discovery_ready', none).
expect(p11x23, 'no_falsifier(C)', none).
expect(p11x23, 'model_trusted(M)', none).
expect(p11x23, 'lint_issue(Code, Id, _)', none).
expect(p11x23, 'model_unfiled_break(C)', none).
expect(p11x23, 'discovery_unratified(C)', none).
expect(p11x23, 'discovery_decide', none).
variant(p11x24, [
    add(claim(c3, preserve, 'x')),
    add(cites(c3, 'x')),
    add(supersedes(c3, c1)),
    add(attest(a19, disproof, m_target, verdict(c1, abstained), agent, '2026-10-15T11:00:00Z')),
    add(attest(a20, reproduction, log4417, result(h1, not_reproduced), agent, '2026-10-15T11:00:00Z')),
    add(attest(a21, divergence, run_target, claim(c2b), agent, '2026-10-15T11:00:00Z'))]).
expect(p11x24, 'discovery_ready', none).
expect(p11x24, 'no_falsifier(C)', none).
expect(p11x24, 'model_trusted(M)', none).
expect(p11x24, 'lint_issue(Code, Id, _)', none).
expect(p11x24, 'model_unfiled_break(C)', none).
expect(p11x24, 'discovery_unratified(C)', none).
expect(p11x24, 'discovery_decide', none).
variant(p11x25, [
    add(attest(a19, model_result, run_target, calibration(m_now, case('t'), differs), agent, '2026-10-15T11:00:00Z')),
    add(attest(a20, reproduction, log4417, confirms(f1), agent, '2026-10-15T11:00:00Z')),
    add(finding(f7, root_cause(x), model)),
    add(discovery_evidence(run_now, system))]).
expect(p11x25, 'discovery_ready', none).
expect(p11x25, 'no_falsifier(C)', none).
expect(p11x25, 'model_trusted(M)', none).
expect(p11x25, 'lint_issue(Code, Id, _)', none).
expect(p11x25, 'model_unfiled_break(C)', none).
expect(p11x25, 'discovery_unratified(C)', none).
expect(p11x25, 'discovery_decide', none).
variant(p11x26, [
    add(attest(a19, model_result, run_target, verdict(m_now, sanity, unknown), agent, '2026-10-15T11:00:00Z')),
    add(derived_from(m_now, m_now))]).
expect(p11x26, 'discovery_ready', none).
expect(p11x26, 'no_falsifier(C)', none).
expect(p11x26, 'model_trusted(M)', none).
expect(p11x26, 'lint_issue(Code, Id, _)', none).
expect(p11x26, 'model_unfiled_break(C)', none).
expect(p11x26, 'discovery_unratified(C)', none).
expect(p11x26, 'discovery_decide', none).
variant(p11x27, [
    add(derived_from(m_target, m_target)),
    add(claim(c3, preserve, 'x')),
    add(cites(c3, 'x')),
    add(supersedes(c3, c2b)),
    add(encodes(m_target, c3)),
    add(attest(a19, model_result, run_target, verdict(m_target, preserve(c3), reached), agent, '2026-10-15T11:00:00Z')),
    add(attest(a20, model_result, run_now, calibration(m_now, case('t'), differs), agent, '2026-10-15T11:00:00Z')),
    add(finding(f7, surprise(x), system))]).
expect(p11x27, 'discovery_ready', none).
expect(p11x27, 'no_falsifier(C)', none).
expect(p11x27, 'model_trusted(M)', none).
expect(p11x27, 'lint_issue(Code, Id, _)', none).
expect(p11x27, 'model_unfiled_break(C)', none).
expect(p11x27, 'discovery_unratified(C)', none).
expect(p11x27, 'discovery_decide', none).
variant(p11x28, [
    add(discovery_evidence(log4417, system)),
    add(hypothesis(h2, risk, 'x')),
    add(attest(a19, reproduction, log4417, result(h2, reproduced), agent, '2026-10-15T11:00:00Z')),
    add(model_run(run_now, m_now, 'sha256:4444444444444444444444444444444444444444444444444444444444444444')),
    replace(subject(m_now, 'models/discount-now.smt2', 'sha256:25847de81516893a8ab780844edf1c3c4eb3eb97b459d06f353f40d9e39b72db'), subject(m_now, 'models/discount-now.smt2', 'sha256:4444444444444444444444444444444444444444444444444444444444444444'))]).
expect(p11x28, 'discovery_ready', none).
expect(p11x28, 'no_falsifier(C)', none).
expect(p11x28, 'model_trusted(M)', none).
expect(p11x28, 'lint_issue(Code, Id, _)', none).
expect(p11x28, 'model_unfiled_break(C)', none).
expect(p11x28, 'discovery_unratified(C)', none).
expect(p11x28, 'discovery_decide', none).
variant(p11x29, [
    add(attest(a19, model_result, run_now, calibration(m_now, case('t'), differs), agent, '2026-10-15T11:00:00Z')),
    add(hypothesis(h2, risk, 'x')),
    add(attest(a20, reproduction, log4417, result(h2, not_reproduced), agent, '2026-10-15T11:00:00Z')),
    add(attest(a21, model_result, run_now, verdict(m_now, bad_case, holds), agent, '2026-10-15T11:00:00Z'))]).
expect(p11x29, 'discovery_ready', none).
expect(p11x29, 'no_falsifier(C)', none).
expect(p11x29, 'model_trusted(M)', none).
expect(p11x29, 'lint_issue(Code, Id, _)', none).
expect(p11x29, 'model_unfiled_break(C)', none).
expect(p11x29, 'discovery_unratified(C)', none).
expect(p11x29, 'discovery_decide', none).
variant(p11x30, [
    add(attest(a19, model_result, run_target, verdict(m_now, bad_case, unsat), agent, '2026-10-15T11:00:00Z')),
    add(budget(laps, 2)),
    add(lap_done(3)),
    add(attest(a20, disproof, m_target, verdict(c2b, abstained), agent, '2026-10-15T11:00:00Z'))]).
expect(p11x30, 'discovery_ready', none).
expect(p11x30, 'no_falsifier(C)', none).
expect(p11x30, 'model_trusted(M)', none).
expect(p11x30, 'lint_issue(Code, Id, _)', none).
expect(p11x30, 'model_unfiled_break(C)', none).
expect(p11x30, 'discovery_unratified(C)', none).
expect(p11x30, 'discovery_decide', none).
variant(p11x31, [
    add(finding(f7, trace(x), model)),
    add(question(q7, c1, 'x')),
    add(raised_by(q7, c1)),
    add(answer(q7, yes, human)),
    add(hypothesis(h2, risk, 'x')),
    add(attest(a19, reproduction, log4417, result(h2, reproduced), agent, '2026-10-15T11:00:00Z'))]).
expect(p11x31, 'discovery_ready', none).
expect(p11x31, 'no_falsifier(C)', none).
expect(p11x31, 'model_trusted(M)', none).
expect(p11x31, 'lint_issue(Code, Id, _)', none).
expect(p11x31, 'model_unfiled_break(C)', none).
expect(p11x31, 'discovery_unratified(C)', none).
expect(p11x31, 'discovery_decide', none).
variant(p11x32, [
    add(finding(f7, scope(x), system)),
    add(question(q7, c1, 'x')),
    add(raised_by(q7, f7)),
    add(answer(q7, yes, human))]).
expect(p11x32, 'discovery_ready', none).
expect(p11x32, 'no_falsifier(C)', none).
expect(p11x32, 'model_trusted(M)', none).
expect(p11x32, 'lint_issue(Code, Id, _)', none).
expect(p11x32, 'model_unfiled_break(C)', none).
expect(p11x32, 'discovery_unratified(C)', none).
expect(p11x32, 'discovery_decide', none).
variant(p11x33, [
    add(attest(a19, model_result, run_now, calibration(m_target, case('t'), matches), agent, '2026-10-15T11:00:00Z'))]).
expect(p11x33, 'discovery_ready', none).
expect(p11x33, 'no_falsifier(C)', none).
expect(p11x33, 'model_trusted(M)', none).
expect(p11x33, 'lint_issue(Code, Id, _)', none).
expect(p11x33, 'model_unfiled_break(C)', none).
expect(p11x33, 'discovery_unratified(C)', none).
expect(p11x33, 'discovery_decide', none).
variant(p11x34, [
    add(attest(a19, model_result, run_target, mutation(m_now, floor, survived), agent, '2026-10-15T11:00:00Z')),
    add(reason(m_target, floor, 'x')),
    add(hypothesis(h2, risk, 'x')),
    add(attest(a20, reproduction, m_now, confirms(f1), agent, '2026-10-15T11:00:00Z'))]).
expect(p11x34, 'discovery_ready', none).
expect(p11x34, 'no_falsifier(C)', none).
expect(p11x34, 'model_trusted(M)', none).
expect(p11x34, 'lint_issue(Code, Id, _)', none).
expect(p11x34, 'model_unfiled_break(C)', none).
expect(p11x34, 'discovery_unratified(C)', none).
expect(p11x34, 'discovery_decide', none).
variant(p11x35, [
    add(hypothesis(h2, risk, 'x')),
    add(attest(a19, reproduction, log4417, result(h2, reproduced), agent, '2026-10-15T11:00:00Z')),
    add(attest(a20, divergence, run_target, model(m_target), agent, '2026-10-15T11:00:00Z'))]).
expect(p11x35, 'discovery_ready', none).
expect(p11x35, 'no_falsifier(C)', none).
expect(p11x35, 'model_trusted(M)', none).
expect(p11x35, 'lint_issue(Code, Id, _)', none).
expect(p11x35, 'model_unfiled_break(C)', none).
expect(p11x35, 'discovery_unratified(C)', none).
expect(p11x35, 'discovery_decide', none).
variant(p11x36, [
    add(derived_from(m_target, m_target)),
    add(attest(a19, model_result, run_now, verdict(m_now, applies(c1), unknown), agent, '2026-10-15T11:00:00Z'))]).
expect(p11x36, 'discovery_ready', none).
expect(p11x36, 'no_falsifier(C)', none).
expect(p11x36, 'model_trusted(M)', none).
expect(p11x36, 'lint_issue(Code, Id, _)', none).
expect(p11x36, 'model_unfiled_break(C)', none).
expect(p11x36, 'discovery_unratified(C)', none).
expect(p11x36, 'discovery_decide', none).
variant(p11x37, [
    add(attest(a19, model_result, run_target, mutation(m_target, floor, survived), agent, '2026-10-15T11:00:00Z')),
    add(reason(m_now, floor, 'x')),
    add(attest(a20, divergence, run_target, claim(c2b), agent, '2026-10-15T11:00:00Z')),
    add(question(q8, c2, 'x'))]).
expect(p11x37, 'discovery_ready', none).
expect(p11x37, 'no_falsifier(C)', none).
expect(p11x37, 'model_trusted(M)', none).
expect(p11x37, 'lint_issue(Code, Id, _)', none).
expect(p11x37, 'model_unfiled_break(C)', none).
expect(p11x37, 'discovery_unratified(C)', none).
expect(p11x37, 'discovery_decide', none).
variant(p11x38, [
    add(attest(a19, model_result, run_now, mutation(m_target, clamp, survived), agent, '2026-10-15T11:00:00Z'))]).
expect(p11x38, 'discovery_ready', none).
expect(p11x38, 'no_falsifier(C)', none).
expect(p11x38, 'model_trusted(M)', none).
expect(p11x38, 'lint_issue(Code, Id, _)', none).
expect(p11x38, 'model_unfiled_break(C)', none).
expect(p11x38, 'discovery_unratified(C)', none).
expect(p11x38, 'discovery_decide', none).
variant(p11x39, [
    add(attest(a19, model_result, run_target, mutation(m_now, clamp, survived), agent, '2026-10-15T11:00:00Z')),
    add(hypothesis(h2, risk, 'x')),
    add(attest(a20, reproduction, log4417, result(h2, not_reproduced), agent, '2026-10-15T11:00:00Z')),
    add(model_run(run_now, m_now, 'sha256:4444444444444444444444444444444444444444444444444444444444444444')),
    replace(subject(m_now, 'models/discount-now.smt2', 'sha256:25847de81516893a8ab780844edf1c3c4eb3eb97b459d06f353f40d9e39b72db'), subject(m_now, 'models/discount-now.smt2', 'sha256:4444444444444444444444444444444444444444444444444444444444444444')),
    add(attest(a21, divergence, log4417, model(m_target), agent, '2026-10-15T11:00:00Z'))]).
expect(p11x39, 'discovery_ready', none).
expect(p11x39, 'no_falsifier(C)', none).
expect(p11x39, 'model_trusted(M)', none).
expect(p11x39, 'lint_issue(Code, Id, _)', none).
expect(p11x39, 'model_unfiled_break(C)', none).
expect(p11x39, 'discovery_unratified(C)', none).
expect(p11x39, 'discovery_decide', none).
variant(p11x40, [
    add(attest(a19, reproduction, m_now, result(h1, reproduced), agent, '2026-10-15T11:00:00Z')),
    add(finding(f7, scope(x), model)),
    add(question(q7, c1, 'x')),
    add(raised_by(q7, c1)),
    add(answer(q7, yes, human))]).
expect(p11x40, 'discovery_ready', none).
expect(p11x40, 'no_falsifier(C)', none).
expect(p11x40, 'model_trusted(M)', none).
expect(p11x40, 'lint_issue(Code, Id, _)', none).
expect(p11x40, 'model_unfiled_break(C)', none).
expect(p11x40, 'discovery_unratified(C)', none).
expect(p11x40, 'discovery_decide', none).
variant(p11x41, [
    add(attest(a19, model_result, run_now, verdict(m_now, bad_case, unsat), agent, '2026-10-15T11:00:00Z')),
    add(budget(laps, 1)),
    add(lap_done(3)),
    add(attest(a20, disproof, m_target, verdict(c2, abstained), agent, '2026-10-15T11:00:00Z'))]).
expect(p11x41, 'discovery_ready', none).
expect(p11x41, 'no_falsifier(C)', none).
expect(p11x41, 'model_trusted(M)', none).
expect(p11x41, 'lint_issue(Code, Id, _)', none).
expect(p11x41, 'model_unfiled_break(C)', none).
expect(p11x41, 'discovery_unratified(C)', none).
expect(p11x41, 'discovery_decide', none).
variant(p11x42, [
    add(attest(a19, model_result, run_now, calibration(m_target, case('t'), matches), agent, '2026-10-15T11:00:00Z')),
    replace(subject(m_now, 'models/discount-now.smt2', 'sha256:25847de81516893a8ab780844edf1c3c4eb3eb97b459d06f353f40d9e39b72db'), subject(m_now, 'models/discount-now.smt2', 'sha256:4444444444444444444444444444444444444444444444444444444444444444')),
    add(derived_from(m_target, m_now))]).
expect(p11x42, 'discovery_ready', none).
expect(p11x42, 'no_falsifier(C)', none).
expect(p11x42, 'model_trusted(M)', none).
expect(p11x42, 'lint_issue(Code, Id, _)', none).
expect(p11x42, 'model_unfiled_break(C)', none).
expect(p11x42, 'discovery_unratified(C)', none).
expect(p11x42, 'discovery_decide', none).
variant(p11x43, [
    add(attest(a19, disproof, m_target, verdict(c2b, abstained), agent, '2026-10-15T11:00:00Z')),
    add(finding(f7, trace(x), model)),
    add(discovery_evidence(m_target, system)),
    add(hypothesis(h2, risk, 'x')),
    add(attest(a20, reproduction, log4417, result(h2, reproduced), agent, '2026-10-15T11:00:00Z'))]).
expect(p11x43, 'discovery_ready', none).
expect(p11x43, 'no_falsifier(C)', none).
expect(p11x43, 'model_trusted(M)', none).
expect(p11x43, 'lint_issue(Code, Id, _)', none).
expect(p11x43, 'model_unfiled_break(C)', none).
expect(p11x43, 'discovery_unratified(C)', none).
expect(p11x43, 'discovery_decide', none).
variant(p11x44, [
    add(budget(laps, 2)),
    add(lap_done(2)),
    add(discovery_evidence(run_now, model))]).
expect(p11x44, 'discovery_ready', none).
expect(p11x44, 'no_falsifier(C)', none).
expect(p11x44, 'model_trusted(M)', none).
expect(p11x44, 'lint_issue(Code, Id, _)', none).
expect(p11x44, 'model_unfiled_break(C)', none).
expect(p11x44, 'discovery_unratified(C)', none).
expect(p11x44, 'discovery_decide', none).
variant(p11x45, [
    add(attest(a19, model_result, run_now, calibration(m_now, case('t'), matches), agent, '2026-10-15T11:00:00Z')),
    add(hypothesis(h2, risk, 'x'))]).
expect(p11x45, 'discovery_ready', none).
expect(p11x45, 'no_falsifier(C)', none).
expect(p11x45, 'model_trusted(M)', none).
expect(p11x45, 'lint_issue(Code, Id, _)', none).
expect(p11x45, 'model_unfiled_break(C)', none).
expect(p11x45, 'discovery_unratified(C)', none).
expect(p11x45, 'discovery_decide', none).
variant(p11x46, [
    add(budget(laps, 2)),
    add(lap_done(3)),
    add(attest(a19, divergence, run_now, model(m_target), agent, '2026-10-15T11:00:00Z'))]).
expect(p11x46, 'discovery_ready', none).
expect(p11x46, 'no_falsifier(C)', none).
expect(p11x46, 'model_trusted(M)', none).
expect(p11x46, 'lint_issue(Code, Id, _)', none).
expect(p11x46, 'model_unfiled_break(C)', none).
expect(p11x46, 'discovery_unratified(C)', none).
expect(p11x46, 'discovery_decide', none).
variant(p11x47, [
    add(attest(a19, model_result, run_now, mutation(m_target, clamp, survived), agent, '2026-10-15T11:00:00Z')),
    add(reason(m_target, floor, 'x')),
    add(hypothesis(h2, risk, 'x')),
    add(attest(a20, reproduction, log4417, result(h2, not_reproduced), agent, '2026-10-15T11:00:00Z')),
    add(budget(laps, 5)),
    add(lap_done(2)),
    add(attest(a21, model_result, run_now, verdict(m_target, sanity, sat), agent, '2026-10-15T11:00:00Z'))]).
expect(p11x47, 'discovery_ready', none).
expect(p11x47, 'no_falsifier(C)', none).
expect(p11x47, 'model_trusted(M)', none).
expect(p11x47, 'lint_issue(Code, Id, _)', none).
expect(p11x47, 'model_unfiled_break(C)', none).
expect(p11x47, 'discovery_unratified(C)', none).
expect(p11x47, 'discovery_decide', none).
variant(p11x48, [
    add(hypothesis(h2, risk, 'x')),
    add(attest(a19, reproduction, log4417, result(h2, not_reproduced), agent, '2026-10-15T11:00:00Z'))]).
expect(p11x48, 'discovery_ready', none).
expect(p11x48, 'no_falsifier(C)', none).
expect(p11x48, 'model_trusted(M)', none).
expect(p11x48, 'lint_issue(Code, Id, _)', none).
expect(p11x48, 'model_unfiled_break(C)', none).
expect(p11x48, 'discovery_unratified(C)', none).
expect(p11x48, 'discovery_decide', none).
variant(p11x49, [
    add(attest(a19, model_result, run_now, calibration(m_now, case('t'), matches), agent, '2026-10-15T11:00:00Z')),
    add(attest(a20, model_result, run_now, verdict(m_target, sanity, sat), agent, '2026-10-15T11:00:00Z'))]).
expect(p11x49, 'discovery_ready', none).
expect(p11x49, 'no_falsifier(C)', none).
expect(p11x49, 'model_trusted(M)', none).
expect(p11x49, 'lint_issue(Code, Id, _)', none).
expect(p11x49, 'model_unfiled_break(C)', none).
expect(p11x49, 'discovery_unratified(C)', none).
expect(p11x49, 'discovery_decide', none).
variant(p11x50, [
    add(discovery_evidence(log4417, system)),
    add(derived_from(m_target, m_target))]).
expect(p11x50, 'discovery_ready', none).
expect(p11x50, 'no_falsifier(C)', none).
expect(p11x50, 'model_trusted(M)', none).
expect(p11x50, 'lint_issue(Code, Id, _)', none).
expect(p11x50, 'model_unfiled_break(C)', none).
expect(p11x50, 'discovery_unratified(C)', none).
expect(p11x50, 'discovery_decide', none).
variant(p11x51, [
    add(finding(f7, trace(x), system)),
    add(question(q7, c1, 'x')),
    add(raised_by(q7, c1)),
    add(answer(q7, yes, human)),
    add(attest(a19, model_result, run_now, mutation(m_now, floor, killed), agent, '2026-10-15T11:00:00Z')),
    add(reason(m_target, floor, 'x')),
    add(attest(a20, reproduction, log4417, result(h1, reproduced), agent, '2026-10-15T11:00:00Z')),
    add(attest(a21, divergence, run_target, claim(c1), agent, '2026-10-15T11:00:00Z')),
    add(question(q8, c1, 'x'))]).
expect(p11x51, 'discovery_ready', none).
expect(p11x51, 'no_falsifier(C)', none).
expect(p11x51, 'model_trusted(M)', none).
expect(p11x51, 'lint_issue(Code, Id, _)', none).
expect(p11x51, 'model_unfiled_break(C)', none).
expect(p11x51, 'discovery_unratified(C)', none).
expect(p11x51, 'discovery_decide', none).
variant(p11x52, [
    add(attest(a19, divergence, log4417, model(m_now), agent, '2026-10-15T11:00:00Z')),
    add(hypothesis(h2, risk, 'x')),
    add(attest(a20, reproduction, log4417, result(h2, not_reproduced), agent, '2026-10-15T11:00:00Z')),
    add(budget(laps, 2)),
    add(lap_done(3))]).
expect(p11x52, 'discovery_ready', none).
expect(p11x52, 'no_falsifier(C)', none).
expect(p11x52, 'model_trusted(M)', none).
expect(p11x52, 'lint_issue(Code, Id, _)', none).
expect(p11x52, 'model_unfiled_break(C)', none).
expect(p11x52, 'discovery_unratified(C)', none).
expect(p11x52, 'discovery_decide', none).
variant(p11x53, [
    add(budget(laps, 5)),
    add(lap_done(2))]).
expect(p11x53, 'discovery_ready', none).
expect(p11x53, 'no_falsifier(C)', none).
expect(p11x53, 'model_trusted(M)', none).
expect(p11x53, 'lint_issue(Code, Id, _)', none).
expect(p11x53, 'model_unfiled_break(C)', none).
expect(p11x53, 'discovery_unratified(C)', none).
expect(p11x53, 'discovery_decide', none).
variant(p11x54, [
    add(attest(a19, model_result, run_target, verdict(m_now, applies(c1), unsat), agent, '2026-10-15T11:00:00Z')),
    add(attest(a20, reproduction, log4417, confirms(f1), agent, '2026-10-15T11:00:00Z')),
    add(attest(a21, model_result, run_target, mutation(m_target, floor, survived), agent, '2026-10-15T11:00:00Z')),
    add(reason(m_target, clamp, 'x')),
    add(hypothesis(h2, risk, 'x')),
    add(attest(a22, reproduction, log4417, result(h2, not_reproduced), agent, '2026-10-15T11:00:00Z'))]).
expect(p11x54, 'discovery_ready', none).
expect(p11x54, 'no_falsifier(C)', none).
expect(p11x54, 'model_trusted(M)', none).
expect(p11x54, 'lint_issue(Code, Id, _)', none).
expect(p11x54, 'model_unfiled_break(C)', none).
expect(p11x54, 'discovery_unratified(C)', none).
expect(p11x54, 'discovery_decide', none).
variant(p11x55, [
    add(attest(a19, model_result, run_now, calibration(m_now, case('t'), differs), agent, '2026-10-15T11:00:00Z')),
    add(discovery_evidence(m_target, model)),
    add(finding(f7, trace(x), model))]).
expect(p11x55, 'discovery_ready', none).
expect(p11x55, 'no_falsifier(C)', none).
expect(p11x55, 'model_trusted(M)', none).
expect(p11x55, 'lint_issue(Code, Id, _)', none).
expect(p11x55, 'model_unfiled_break(C)', none).
expect(p11x55, 'discovery_unratified(C)', none).
expect(p11x55, 'discovery_decide', none).
variant(p11x56, [
    add(attest(a19, divergence, run_now, model(m_now), agent, '2026-10-15T11:00:00Z'))]).
expect(p11x56, 'discovery_ready', none).
expect(p11x56, 'no_falsifier(C)', none).
expect(p11x56, 'model_trusted(M)', none).
expect(p11x56, 'lint_issue(Code, Id, _)', none).
expect(p11x56, 'model_unfiled_break(C)', none).
expect(p11x56, 'discovery_unratified(C)', none).
expect(p11x56, 'discovery_decide', none).
variant(p11x57, [
    add(derived_from(m_now, m_now)),
    add(finding(f7, root_cause(x), model)),
    add(question(q7, c1, 'x')),
    add(raised_by(q7, h1)),
    add(answer(q7, yes, human)),
    add(attest(a19, model_result, run_target, mutation(m_target, clamp, killed), agent, '2026-10-15T11:00:00Z'))]).
expect(p11x57, 'discovery_ready', none).
expect(p11x57, 'no_falsifier(C)', none).
expect(p11x57, 'model_trusted(M)', none).
expect(p11x57, 'lint_issue(Code, Id, _)', none).
expect(p11x57, 'model_unfiled_break(C)', none).
expect(p11x57, 'discovery_unratified(C)', none).
expect(p11x57, 'discovery_decide', none).
variant(p11x58, [
    add(attest(a19, model_result, run_now, mutation(m_target, clamp, killed), agent, '2026-10-15T11:00:00Z')),
    add(reason(m_now, floor, 'x'))]).
expect(p11x58, 'discovery_ready', none).
expect(p11x58, 'no_falsifier(C)', none).
expect(p11x58, 'model_trusted(M)', none).
expect(p11x58, 'lint_issue(Code, Id, _)', none).
expect(p11x58, 'model_unfiled_break(C)', none).
expect(p11x58, 'discovery_unratified(C)', none).
expect(p11x58, 'discovery_decide', none).
variant(p11x59, [
    add(finding(f7, root_cause(x), system)),
    add(question(q7, c1, 'x')),
    add(raised_by(q7, h1))]).
expect(p11x59, 'discovery_ready', none).
expect(p11x59, 'no_falsifier(C)', none).
expect(p11x59, 'model_trusted(M)', none).
expect(p11x59, 'lint_issue(Code, Id, _)', none).
expect(p11x59, 'model_unfiled_break(C)', none).
expect(p11x59, 'discovery_unratified(C)', none).
expect(p11x59, 'discovery_decide', none).

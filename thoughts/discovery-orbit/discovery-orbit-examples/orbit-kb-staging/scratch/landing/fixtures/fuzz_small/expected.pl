variant(s7x0, [
    add(subject(l1, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(claim(c2, preserve, 'x')),
    add(cites(c2, 'x')),
    add(question(q1, c2, 'x')),
    add(raised_by(q1, c1)),
    add(cites(c1, 'x')),
    add(budget(laps, 3)),
    add(assumed(q1, yes)),
    add(claim(c1, introduce, 'x')),
    add(budget(laps, 4)),
    add(lap_done(1))]).
expect(s7x0, 'discovery_ready', none).
expect(s7x0, 'no_falsifier(C)', none).
expect(s7x0, 'model_trusted(M)', none).
expect(s7x0, 'lint_issue(Code, Id, _)', none).
expect(s7x0, 'model_unfiled_break(C)', none).
expect(s7x0, 'discovery_unratified(C)', none).
expect(s7x0, 'discovery_decide', none).
variant(s7x1, [
    add(encodes(m2, c3)),
    add(attest(a6, model_result, m2, mutation(m2, rb, survived), agent, '2026-10-15T09:00:00Z')),
    add(subject(l1, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(attest(a3, model_result, r20, verdict(m2, bad_case, reached), agent, '2026-10-15T09:00:00Z')),
    add(cites(c3, 'x')),
    add(attest(a7, model_result, r20, mutation(m2, rb, killed), agent, '2026-10-15T09:00:00Z')),
    add(attest(a8, reproduction, l1, result(h1, not_reproduced), agent, '2026-10-15T09:00:00Z')),
    add(derived_from(m2, m2)),
    add(lap_done(1)),
    add(discovery_evidence(l2, system)),
    add(attest(a2, model_result, l1, verdict(m2, root_cause(x), sat), agent, '2026-10-15T09:00:00Z')),
    add(claim(c3, preserve, 'x')),
    add(derived_from(m2, m2)),
    add(subject(m2, 'p', 'sha256:2222222222222222222222222222222222222222222222222222222222222222')),
    add(discovery_evidence(k1, system)),
    add(attest(a1, model_result, m2, verdict(m2, applies(c3), reached), agent, '2026-10-15T09:00:00Z')),
    add(hypothesis(h2, risk, 'x')),
    add(check(k1, c3)),
    add(hypothesis(h1, defect, 'x')),
    add(discovery_evidence(l1, system)),
    add(subject(r20, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(attest(a4, model_result, m2, verdict(m2, sanity, sat), agent, '2026-10-15T09:00:00Z')),
    add(model(m2, smt)),
    add(budget(laps, 4)),
    add(attest(a5, model_result, r20, calibration(m2, example(c3), differs), agent, '2026-10-15T09:00:00Z')),
    add(subject(l2, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(encodes(m2, c3)),
    add(budget(laps, 3)),
    add(model_run(r20, m2, 'sha256:2222222222222222222222222222222222222222222222222222222222222222')),
    add(attest(a9, reproduction, m2, result(h2, reproduced), agent, '2026-10-15T09:00:00Z'))]).
expect(s7x1, 'discovery_ready', none).
expect(s7x1, 'no_falsifier(C)', none).
expect(s7x1, 'model_trusted(M)', none).
expect(s7x1, 'lint_issue(Code, Id, _)', none).
expect(s7x1, 'model_unfiled_break(C)', none).
expect(s7x1, 'discovery_unratified(C)', none).
expect(s7x1, 'discovery_decide', none).
variant(s7x2, [
    add(lap_done(2)),
    add(lap_done(1)),
    add(budget(laps, 4)),
    add(supersedes(c3, c1)),
    add(finding(f1, root_cause(x), system)),
    add(discovery_evidence(k1, system)),
    add(supersedes(c3, c1)),
    add(claim(c3, introduce, 'x')),
    add(check(k1, c3)),
    add(cites(c3, 'x')),
    add(cites(c1, 'x')),
    add(claim(c1, retire, 'x')),
    add(budget(laps, 3))]).
expect(s7x2, 'discovery_ready', none).
expect(s7x2, 'no_falsifier(C)', none).
expect(s7x2, 'model_trusted(M)', none).
expect(s7x2, 'lint_issue(Code, Id, _)', none).
expect(s7x2, 'model_unfiled_break(C)', none).
expect(s7x2, 'discovery_unratified(C)', none).
expect(s7x2, 'discovery_decide', none).
variant(s7x3, [
    add(attest(a2, model_result, l1, verdict(m2, sanity, reached), agent, '2026-10-15T09:00:00Z')),
    add(attest(a7, model_result, m2, calibration(m2, case('t'), matches), agent, '2026-10-15T09:00:00Z')),
    add(model(m2, tla)),
    add(attest(a3, model_result, l1, verdict(m2, sanity, violated), agent, '2026-10-15T09:00:00Z')),
    add(hypothesis(h2, feature, 'x')),
    add(attest(a5, model_result, m2, verdict(m2, sanity, unknown), agent, '2026-10-15T09:00:00Z')),
    add(subject(m2, 'p', 'sha256:2222222222222222222222222222222222222222222222222222222222222222')),
    add(attest(a1, model_result, m2, verdict(m2, bad_case, reached), agent, '2026-10-15T09:00:00Z')),
    add(attest(a6, model_result, m2, verdict(m2, sanity, reached), agent, '2026-10-15T09:00:00Z')),
    add(subject(l1, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(derived_from(m2, m2)),
    add(attest(a4, model_result, l1, verdict(m2, explore(w), holds), agent, '2026-10-15T09:00:00Z')),
    add(attest(a8, reproduction, l1, result(h2, reproduced), agent, '2026-10-15T09:00:00Z')),
    add(discovery_evidence(l1, model)),
    add(reason(m2, ra, 't')),
    add(finding(f1, trace(x), system)),
    add(derived_from(m2, m2))]).
expect(s7x3, 'discovery_ready', none).
expect(s7x3, 'no_falsifier(C)', none).
expect(s7x3, 'model_trusted(M)', none).
expect(s7x3, 'lint_issue(Code, Id, _)', none).
expect(s7x3, 'model_unfiled_break(C)', none).
expect(s7x3, 'discovery_unratified(C)', none).
expect(s7x3, 'discovery_decide', none).
variant(s7x4, [
    add(subject(l2, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(discovery_evidence(l2, model)),
    add(attest(a1, reproduction, l2, result(h2, not_reproduced), agent, '2026-10-15T09:00:00Z')),
    add(hypothesis(h2, risk, 'x')),
    add(attest(a2, reproduction, l2, result(h1, reproduced), agent, '2026-10-15T09:00:00Z')),
    add(hypothesis(h1, risk, 'x'))]).
expect(s7x4, 'discovery_ready', none).
expect(s7x4, 'no_falsifier(C)', none).
expect(s7x4, 'model_trusted(M)', none).
expect(s7x4, 'lint_issue(Code, Id, _)', none).
expect(s7x4, 'model_unfiled_break(C)', none).
expect(s7x4, 'discovery_unratified(C)', none).
expect(s7x4, 'discovery_decide', none).
variant(s7x5, [
    add(attest(a3, disproof, l1, verdict(c3, refuted), agent, '2026-10-15T09:00:00Z')),
    add(discovery_evidence(l1, model)),
    add(answer(q1, no, human)),
    add(subject(l2, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(claim(c1, retire, 'x')),
    add(subject(l1, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(claim(c3, introduce, 'x')),
    add(discovery_evidence(l2, system)),
    add(cites(c1, 'x')),
    add(attest(a1, reproduction, k1, result(h2, reproduced), agent, '2026-10-15T09:00:00Z')),
    add(check(k1, c1)),
    add(hypothesis(h2, risk, 'x')),
    add(attest(a4, divergence, l1, verdict(c3, refuted), agent, '2026-10-15T09:00:00Z')),
    add(cites(c3, 'x')),
    add(assumed(q1, yes)),
    add(supersedes(c1, c3)),
    add(attest(a2, reproduction, l2, result(h1, not_reproduced), agent, '2026-10-15T09:00:00Z')),
    add(discovery_evidence(k1, system)),
    add(question(q1, c3, 'x')),
    add(hypothesis(h1, defect, 'x'))]).
expect(s7x5, 'discovery_ready', none).
expect(s7x5, 'no_falsifier(C)', none).
expect(s7x5, 'model_trusted(M)', none).
expect(s7x5, 'lint_issue(Code, Id, _)', none).
expect(s7x5, 'model_unfiled_break(C)', none).
expect(s7x5, 'discovery_unratified(C)', none).
expect(s7x5, 'discovery_decide', none).
variant(s7x6, [
    add(cites(c2, 'x')),
    add(discovery_evidence(k1, system)),
    add(assumed(q1, yes)),
    add(question(q1, c2, 'x')),
    add(claim(c2, preserve, 'x')),
    add(answer(q1, yes, agent)),
    add(finding(f2, surprise(x), system)),
    add(attest(a1, reproduction, k1, confirms(f2), agent, '2026-10-15T09:00:00Z')),
    add(attest(a3, reproduction, k1, result(h1, reproduced), agent, '2026-10-15T09:00:00Z')),
    add(attest(a2, reproduction, k1, confirms(f1), agent, '2026-10-15T09:00:00Z')),
    add(check(k1, c2)),
    add(finding(f1, conflict([x, y]), system)),
    add(hypothesis(h1, risk, 'x')),
    add(raised_by(q1, f1)),
    add(attest(a4, disproof, k1, claim(c2), agent, '2026-10-15T09:00:00Z'))]).
expect(s7x6, 'discovery_ready', none).
expect(s7x6, 'no_falsifier(C)', none).
expect(s7x6, 'model_trusted(M)', none).
expect(s7x6, 'lint_issue(Code, Id, _)', none).
expect(s7x6, 'model_unfiled_break(C)', none).
expect(s7x6, 'discovery_unratified(C)', none).
expect(s7x6, 'discovery_decide', none).
variant(s7x7, [
    add(cites(c3, 'x')),
    add(claim(c1, introduce, 'x')),
    add(model_run(r11, m1, 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(attest(a2, model_result, m1, calibration(m1, case('t'), matches), agent, '2026-10-15T09:00:00Z')),
    add(subject(r11, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(claim(c2, preserve, 'x')),
    add(claim(c3, retire, 'x')),
    add(model_run(r10, m1, 'sha256:1111111111111111111111111111111111111111111111111111111111111111')),
    add(model_run(r11, m1, 'sha256:1111111111111111111111111111111111111111111111111111111111111111')),
    add(attest(a3, model_result, m1, mutation(m1, rb, survived), agent, '2026-10-15T09:00:00Z')),
    add(cites(c1, 'x')),
    add(attest(a1, model_result, r11, verdict(m1, bad_case, unsat), agent, '2026-10-15T09:00:00Z')),
    add(cites(c2, 'x')),
    add(model(m1, smt)),
    add(subject(r10, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(subject(m1, 'p', 'sha256:1111111111111111111111111111111111111111111111111111111111111111'))]).
expect(s7x7, 'discovery_ready', none).
expect(s7x7, 'no_falsifier(C)', none).
expect(s7x7, 'model_trusted(M)', none).
expect(s7x7, 'lint_issue(Code, Id, _)', none).
expect(s7x7, 'model_unfiled_break(C)', none).
expect(s7x7, 'discovery_unratified(C)', none).
expect(s7x7, 'discovery_decide', none).
variant(s7x8, [
    add(model(m2, smt)),
    add(model(m1, smt)),
    add(model_run(r21, m2, 'sha256:2222222222222222222222222222222222222222222222222222222222222222')),
    add(raised_by(q1, c2)),
    add(answer(q1, yes, agent)),
    add(model_run(r20, m2, 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(subject(r21, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(claim(c2, retire, 'x')),
    add(assumed(q2, yes)),
    add(answer(q2, yes, agent)),
    add(subject(m2, 'p', 'sha256:2222222222222222222222222222222222222222222222222222222222222222')),
    add(model_run(r21, m2, 'sha256:2222222222222222222222222222222222222222222222222222222222222222')),
    add(encodes(m1, c2)),
    add(attest(a1, model_result, r20, calibration(m1, example(c2), matches), agent, '2026-10-15T09:00:00Z')),
    add(derived_from(m1, m2)),
    add(encodes(m1, c2)),
    add(assumed(q1, yes)),
    add(cites(c2, 'x')),
    add(raised_by(q2, c2)),
    add(question(q2, c2, 'x')),
    add(subject(m1, 'p', 'sha256:1111111111111111111111111111111111111111111111111111111111111111')),
    add(subject(r20, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(question(q1, c2, 'x'))]).
expect(s7x8, 'discovery_ready', none).
expect(s7x8, 'no_falsifier(C)', none).
expect(s7x8, 'model_trusted(M)', none).
expect(s7x8, 'lint_issue(Code, Id, _)', none).
expect(s7x8, 'model_unfiled_break(C)', none).
expect(s7x8, 'discovery_unratified(C)', none).
expect(s7x8, 'discovery_decide', none).
variant(s7x9, [
    add(hypothesis(h2, feature, 'x')),
    add(subject(l1, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(subject(l2, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(attest(a1, reproduction, l2, result(h2, reproduced), agent, '2026-10-15T09:00:00Z')),
    add(finding(f1, scope(x), model)),
    add(hypothesis(h1, feature, 'x')),
    add(discovery_evidence(l2, system)),
    add(discovery_evidence(l1, model))]).
expect(s7x9, 'discovery_ready', none).
expect(s7x9, 'no_falsifier(C)', none).
expect(s7x9, 'model_trusted(M)', none).
expect(s7x9, 'lint_issue(Code, Id, _)', none).
expect(s7x9, 'model_unfiled_break(C)', none).
expect(s7x9, 'discovery_unratified(C)', none).
expect(s7x9, 'discovery_decide', none).
variant(s7x10, [
    add(attest(a9, reproduction, l1, result(h2, reproduced), agent, '2026-10-15T09:00:00Z')),
    add(subject(m1, 'p', 'sha256:1111111111111111111111111111111111111111111111111111111111111111')),
    add(attest(a8, reproduction, r20, confirms(f2), agent, '2026-10-15T09:00:00Z')),
    add(finding(f1, trace(x), system)),
    add(attest(a5, model_result, m2, mutation(m1, rb, killed), agent, '2026-10-15T09:00:00Z')),
    add(attest(a2, model_result, r20, verdict(m1, root_cause(x), sat), agent, '2026-10-15T09:00:00Z')),
    add(attest(a3, model_result, m2, verdict(m1, bad_case, violated), agent, '2026-10-15T09:00:00Z')),
    add(budget(laps, 3)),
    add(hypothesis(h2, risk, 'x')),
    add(derived_from(m1, m1)),
    add(budget(laps, 4)),
    add(attest(a6, model_result, m2, mutation(m1, ra, survived), agent, '2026-10-15T09:00:00Z')),
    add(discovery_evidence(l2, model)),
    add(attest(a1, model_result, r10, verdict(m1, sanity, holds), agent, '2026-10-15T09:00:00Z')),
    add(subject(m2, 'p', 'sha256:2222222222222222222222222222222222222222222222222222222222222222')),
    add(reason(m1, rb, 't')),
    add(model(m2, smt)),
    add(lap_done(2)),
    add(model_run(r20, m2, 'sha256:2222222222222222222222222222222222222222222222222222222222222222')),
    add(attest(a7, divergence, r20, model(m1), agent, '2026-10-15T09:00:00Z')),
    add(discovery_evidence(l1, system)),
    add(finding(f2, surprise(x), model)),
    add(hypothesis(h1, risk, 'x')),
    add(subject(r20, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(model_run(r10, m1, 'sha256:1111111111111111111111111111111111111111111111111111111111111111')),
    add(model(m1, tla)),
    add(subject(l1, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(attest(a4, model_result, r10, verdict(m2, sanity, sat), agent, '2026-10-15T09:00:00Z')),
    add(attest(a10, reproduction, r10, result(h1, not_reproduced), agent, '2026-10-15T09:00:00Z')),
    add(lap_done(1)),
    add(subject(r10, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(subject(l2, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333'))]).
expect(s7x10, 'discovery_ready', none).
expect(s7x10, 'no_falsifier(C)', none).
expect(s7x10, 'model_trusted(M)', none).
expect(s7x10, 'lint_issue(Code, Id, _)', none).
expect(s7x10, 'model_unfiled_break(C)', none).
expect(s7x10, 'discovery_unratified(C)', none).
expect(s7x10, 'discovery_decide', none).
variant(s7x11, [
    add(attest(a7, model_result, l2, mutation(m1, ra, survived), agent, '2026-10-15T09:00:00Z')),
    add(discovery_evidence(l2, system)),
    add(cites(c2, 'x')),
    add(lap_done(1)),
    add(cites(c3, 'x')),
    add(encodes(m1, c3)),
    add(finding(f2, surprise(x), model)),
    add(discovery_evidence(k1, system)),
    add(attest(a10, disproof, k1, claim(c3), agent, '2026-10-15T09:00:00Z')),
    add(encodes(m1, c1)),
    add(subject(l1, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(claim(c3, retire, 'x')),
    add(budget(laps, 1)),
    add(attest(a1, model_result, l2, verdict(m1, sanity, unsat), agent, '2026-10-15T09:00:00Z')),
    add(attest(a4, model_result, l2, verdict(m1, preserve(c1), violated), agent, '2026-10-15T09:00:00Z')),
    add(attest(a8, reproduction, k1, confirms(f2), agent, '2026-10-15T09:00:00Z')),
    add(discovery_evidence(l1, model)),
    add(check(k1, c1)),
    add(finding(f1, conflict([x, y]), model)),
    add(subject(l2, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(budget(laps, 2)),
    add(attest(a6, model_result, l1, calibration(m1, case('t'), differs), agent, '2026-10-15T09:00:00Z')),
    add(cites(c1, 'x')),
    add(attest(a5, model_result, l1, calibration(m1, case('t'), matches), agent, '2026-10-15T09:00:00Z')),
    add(subject(m1, 'p', 'sha256:1111111111111111111111111111111111111111111111111111111111111111')),
    add(attest(a9, reproduction, l2, result(h2, reproduced), agent, '2026-10-15T09:00:00Z')),
    add(encodes(m1, c1)),
    add(hypothesis(h2, feature, 'x')),
    add(attest(a3, model_result, l1, verdict(m1, applies(c1), unsat), agent, '2026-10-15T09:00:00Z')),
    add(claim(c2, introduce, 'x')),
    add(attest(a11, divergence, l2, verdict(c2, abstained), agent, '2026-10-15T09:00:00Z')),
    add(attest(a2, model_result, l1, verdict(m1, preserve(c3), unsat), agent, '2026-10-15T09:00:00Z')),
    add(claim(c1, preserve, 'x')),
    add(model(m1, smt))]).
expect(s7x11, 'discovery_ready', none).
expect(s7x11, 'no_falsifier(C)', none).
expect(s7x11, 'model_trusted(M)', none).
expect(s7x11, 'lint_issue(Code, Id, _)', none).
expect(s7x11, 'model_unfiled_break(C)', none).
expect(s7x11, 'discovery_unratified(C)', none).
expect(s7x11, 'discovery_decide', none).
variant(s7x12, [
    add(finding(f2, root_cause(x), system)),
    add(answer(q1, yes, agent)),
    add(question(q2, c1, 'x')),
    add(cites(c1, 'x')),
    add(answer(q2, no, human)),
    add(budget(laps, 1)),
    add(claim(c1, retire, 'x')),
    add(raised_by(q2, c1)),
    add(assumed(q1, yes)),
    add(lap_done(1)),
    add(assumed(q2, yes)),
    add(question(q1, c1, 'x'))]).
expect(s7x12, 'discovery_ready', none).
expect(s7x12, 'no_falsifier(C)', none).
expect(s7x12, 'model_trusted(M)', none).
expect(s7x12, 'lint_issue(Code, Id, _)', none).
expect(s7x12, 'model_unfiled_break(C)', none).
expect(s7x12, 'discovery_unratified(C)', none).
expect(s7x12, 'discovery_decide', none).
variant(s7x13, [
    add(model_run(r21, m2, 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(finding(f2, surprise(x), system)),
    add(cites(c1, 'x')),
    add(attest(a2, reproduction, m2, confirms(f2), agent, '2026-10-15T09:00:00Z')),
    add(discovery_evidence(l1, system)),
    add(derived_from(m2, m2)),
    add(derived_from(m2, m2)),
    add(claim(c3, retire, 'x')),
    add(model(m2, smt)),
    add(budget(laps, 3)),
    add(cites(c2, 'x')),
    add(lap_done(2)),
    add(subject(r21, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(encodes(m2, c1)),
    add(claim(c2, preserve, 'x')),
    add(assumed(q1, yes)),
    add(attest(a1, model_result, r20, mutation(m2, rb, killed), agent, '2026-10-15T09:00:00Z')),
    add(question(q1, c2, 'x')),
    add(model_run(r20, m2, 'sha256:2222222222222222222222222222222222222222222222222222222222222222')),
    add(subject(r20, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(encodes(m2, c3)),
    add(budget(laps, 2)),
    add(subject(l1, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(subject(m2, 'p', 'sha256:2222222222222222222222222222222222222222222222222222222222222222')),
    add(lap_done(1)),
    add(answer(q1, no, agent)),
    add(claim(c1, preserve, 'x')),
    add(model_run(r21, m2, 'sha256:2222222222222222222222222222222222222222222222222222222222222222')),
    add(lap_done(3)),
    add(model_run(r20, m2, 'sha256:1111111111111111111111111111111111111111111111111111111111111111')),
    add(cites(c3, 'x'))]).
expect(s7x13, 'discovery_ready', none).
expect(s7x13, 'no_falsifier(C)', none).
expect(s7x13, 'model_trusted(M)', none).
expect(s7x13, 'lint_issue(Code, Id, _)', none).
expect(s7x13, 'model_unfiled_break(C)', none).
expect(s7x13, 'discovery_unratified(C)', none).
expect(s7x13, 'discovery_decide', none).
variant(s7x14, [
    add(budget(laps, 1)),
    add(encodes(m2, c1)),
    add(reason(m1, rb, 't')),
    add(encodes(m1, c3)),
    add(subject(r20, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(finding(f1, conflict([x, y]), model)),
    add(attest(a5, divergence, m2, model(m2), agent, '2026-10-15T09:00:00Z')),
    add(attest(a8, divergence, m1, claim(c3), agent, '2026-10-15T09:00:00Z')),
    add(attest(a2, model_result, r20, verdict(m2, preserve(c2), holds), agent, '2026-10-15T09:00:00Z')),
    add(attest(a7, divergence, m2, claim(c3), agent, '2026-10-15T09:00:00Z')),
    add(claim(c3, retire, 'x')),
    add(subject(m1, 'p', 'sha256:1111111111111111111111111111111111111111111111111111111111111111')),
    add(derived_from(m2, m2)),
    add(claim(c1, retire, 'x')),
    add(lap_done(1)),
    add(encodes(m2, c2)),
    add(cites(c1, 'x')),
    add(attest(a1, model_result, r20, verdict(m2, explore(w), sat), agent, '2026-10-15T09:00:00Z')),
    add(model(m1, tla)),
    add(claim(c2, retire, 'x')),
    add(attest(a6, reproduction, m2, confirms(f1), agent, '2026-10-15T09:00:00Z')),
    add(attest(a3, model_result, m1, verdict(m1, bad_case, unsat), agent, '2026-10-15T09:00:00Z')),
    add(attest(a4, model_result, m2, mutation(m2, ra, survived), agent, '2026-10-15T09:00:00Z')),
    add(subject(m2, 'p', 'sha256:2222222222222222222222222222222222222222222222222222222222222222')),
    add(lap_done(2)),
    add(cites(c2, 'x')),
    add(model(m2, smt)),
    add(model_run(r20, m2, 'sha256:2222222222222222222222222222222222222222222222222222222222222222')),
    add(cites(c3, 'x'))]).
expect(s7x14, 'discovery_ready', none).
expect(s7x14, 'no_falsifier(C)', none).
expect(s7x14, 'model_trusted(M)', none).
expect(s7x14, 'lint_issue(Code, Id, _)', none).
expect(s7x14, 'model_unfiled_break(C)', none).
expect(s7x14, 'discovery_unratified(C)', none).
expect(s7x14, 'discovery_decide', none).
variant(s7x15, [
    add(assumed(q1, yes)),
    add(answer(q1, yes, agent)),
    add(cites(c1, 'x')),
    add(claim(c1, preserve, 'x')),
    add(cites(c3, 'x')),
    add(claim(c3, retire, 'x')),
    add(finding(f2, root_cause(x), system)),
    add(supersedes(c3, c1)),
    add(question(q1, c1, 'x'))]).
expect(s7x15, 'discovery_ready', none).
expect(s7x15, 'no_falsifier(C)', none).
expect(s7x15, 'model_trusted(M)', none).
expect(s7x15, 'lint_issue(Code, Id, _)', none).
expect(s7x15, 'model_unfiled_break(C)', none).
expect(s7x15, 'discovery_unratified(C)', none).
expect(s7x15, 'discovery_decide', none).
variant(s7x16, [
    add(discovery_evidence(l2, system)),
    add(attest(a1, reproduction, l2, result(h1, not_reproduced), agent, '2026-10-15T09:00:00Z')),
    add(question(q1, c1, 'x')),
    add(cites(c1, 'x')),
    add(budget(laps, 2)),
    add(hypothesis(h1, defect, 'x')),
    add(attest(a2, divergence, l2, claim(c3), agent, '2026-10-15T09:00:00Z')),
    add(claim(c1, preserve, 'x')),
    add(raised_by(q1, c2)),
    add(supersedes(c1, c2)),
    add(lap_done(1)),
    add(claim(c2, introduce, 'x')),
    add(cites(c3, 'x')),
    add(supersedes(c2, c1)),
    add(assumed(q1, yes)),
    add(cites(c2, 'x')),
    add(claim(c3, retire, 'x')),
    add(subject(l2, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333'))]).
expect(s7x16, 'discovery_ready', none).
expect(s7x16, 'no_falsifier(C)', none).
expect(s7x16, 'model_trusted(M)', none).
expect(s7x16, 'lint_issue(Code, Id, _)', none).
expect(s7x16, 'model_unfiled_break(C)', none).
expect(s7x16, 'discovery_unratified(C)', none).
expect(s7x16, 'discovery_decide', none).
variant(s7x17, [
    add(question(q2, c1, 'x')),
    add(supersedes(c3, c1)),
    add(attest(a2, model_result, l1, verdict(m2, preserve(c3), reached), agent, '2026-10-15T09:00:00Z')),
    add(subject(r20, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(claim(c1, retire, 'x')),
    add(claim(c2, preserve, 'x')),
    add(subject(m2, 'p', 'sha256:2222222222222222222222222222222222222222222222222222222222222222')),
    add(encodes(m2, c1)),
    add(assumed(q1, yes)),
    add(attest(a7, divergence, r20, claim(c3), agent, '2026-10-15T09:00:00Z')),
    add(encodes(m2, c1)),
    add(attest(a4, model_result, r20, verdict(m2, sanity, reached), agent, '2026-10-15T09:00:00Z')),
    add(claim(c3, introduce, 'x')),
    add(subject(l1, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(cites(c2, 'x')),
    add(attest(a1, model_result, m2, verdict(m2, sanity, sat), agent, '2026-10-15T09:00:00Z')),
    add(attest(a6, model_result, l1, verdict(m2, sanity, sat), agent, '2026-10-15T09:00:00Z')),
    add(attest(a5, model_result, r20, verdict(m2, applies(c1), violated), agent, '2026-10-15T09:00:00Z')),
    add(discovery_evidence(l2, model)),
    add(question(q1, c3, 'x')),
    add(discovery_evidence(k1, system)),
    add(cites(c3, 'x')),
    add(derived_from(m2, m2)),
    add(attest(a8, disproof, k1, verdict(c3, refuted), agent, '2026-10-15T09:00:00Z')),
    add(answer(q2, no, human)),
    add(model(m2, smt)),
    add(subject(l2, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(raised_by(q2, c1)),
    add(cites(c1, 'x')),
    add(raised_by(q1, c3)),
    add(assumed(q2, yes)),
    add(check(k1, c2)),
    add(model_run(r20, m2, 'sha256:2222222222222222222222222222222222222222222222222222222222222222')),
    add(discovery_evidence(l1, model)),
    add(attest(a3, model_result, r20, verdict(m2, applies(c1), sat), agent, '2026-10-15T09:00:00Z')),
    add(encodes(m2, c2)),
    add(derived_from(m2, m2))]).
expect(s7x17, 'discovery_ready', none).
expect(s7x17, 'no_falsifier(C)', none).
expect(s7x17, 'model_trusted(M)', none).
expect(s7x17, 'lint_issue(Code, Id, _)', none).
expect(s7x17, 'model_unfiled_break(C)', none).
expect(s7x17, 'discovery_unratified(C)', none).
expect(s7x17, 'discovery_decide', none).
variant(s7x18, [
    add(cites(c3, 'x')),
    add(attest(a2, model_result, r10, verdict(m1, explore(w), violated), agent, '2026-10-15T09:00:00Z')),
    add(claim(c2, preserve, 'x')),
    add(model(m2, smt)),
    add(attest(a7, reproduction, r21, confirms(f2), agent, '2026-10-15T09:00:00Z')),
    add(discovery_evidence(l1, system)),
    add(attest(a3, model_result, r21, verdict(m1, sanity, reached), agent, '2026-10-15T09:00:00Z')),
    add(attest(a5, model_result, r20, verdict(m1, sanity, sat), agent, '2026-10-15T09:00:00Z')),
    add(supersedes(c3, c2)),
    add(subject(m1, 'p', 'sha256:1111111111111111111111111111111111111111111111111111111111111111')),
    add(cites(c2, 'x')),
    add(subject(r10, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(reason(m1, ra, 't')),
    add(finding(f2, scope(x), system)),
    add(lap_done(2)),
    add(answer(q1, no, human)),
    add(question(q1, c3, 'x')),
    add(lap_done(3)),
    add(budget(laps, 3)),
    add(model_run(r20, m2, 'sha256:2222222222222222222222222222222222222222222222222222222222222222')),
    add(attest(a1, model_result, r20, verdict(m1, applies(c3), sat), agent, '2026-10-15T09:00:00Z')),
    add(attest(a6, model_result, r10, verdict(m1, preserve(c2), unsat), agent, '2026-10-15T09:00:00Z')),
    add(subject(l1, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(model_run(r21, m2, 'sha256:2222222222222222222222222222222222222222222222222222222222222222')),
    add(finding(f1, trace(x), model)),
    add(attest(a9, disproof, m2, verdict(c2, inconclusive), agent, '2026-10-15T09:00:00Z')),
    add(hypothesis(h2, risk, 'x')),
    add(assumed(q1, yes)),
    add(attest(a4, model_result, m1, verdict(m2, applies(c2), holds), agent, '2026-10-15T09:00:00Z')),
    add(lap_done(1)),
    add(attest(a8, reproduction, m2, result(h2, reproduced), agent, '2026-10-15T09:00:00Z')),
    add(model_run(r10, m1, 'sha256:1111111111111111111111111111111111111111111111111111111111111111')),
    add(subject(r20, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(lap_done(4)),
    add(model(m1, tla)),
    add(claim(c3, introduce, 'x')),
    add(attest(a10, divergence, m2, claim(c2), agent, '2026-10-15T09:00:00Z')),
    add(supersedes(c3, c2)),
    add(subject(m2, 'p', 'sha256:2222222222222222222222222222222222222222222222222222222222222222')),
    add(subject(r21, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(model_run(r20, m2, 'sha256:2222222222222222222222222222222222222222222222222222222222222222'))]).
expect(s7x18, 'discovery_ready', none).
expect(s7x18, 'no_falsifier(C)', none).
expect(s7x18, 'model_trusted(M)', none).
expect(s7x18, 'lint_issue(Code, Id, _)', none).
expect(s7x18, 'model_unfiled_break(C)', none).
expect(s7x18, 'discovery_unratified(C)', none).
expect(s7x18, 'discovery_decide', none).
variant(s7x19, [
    add(finding(f2, scope(x), model)),
    add(subject(l1, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(question(q2, c1, 'x')),
    add(assumed(q2, yes)),
    add(attest(a1, model_result, m1, calibration(m1, example(c1), matches), agent, '2026-10-15T09:00:00Z')),
    add(claim(c1, preserve, 'x')),
    add(subject(m2, 'p', 'sha256:2222222222222222222222222222222222222222222222222222222222222222')),
    add(attest(a5, reproduction, r10, confirms(f2), agent, '2026-10-15T09:00:00Z')),
    add(raised_by(q2, f2)),
    add(derived_from(m2, m1)),
    add(finding(f1, trace(x), model)),
    add(cites(c1, 'x')),
    add(model(m2, tla)),
    add(attest(a3, model_result, l2, mutation(m1, rb, survived), agent, '2026-10-15T09:00:00Z')),
    add(subject(r10, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(question(q1, c1, 'x')),
    add(attest(a4, divergence, l2, model(m2), agent, '2026-10-15T09:00:00Z')),
    add(check(k1, c1)),
    add(discovery_evidence(k1, system)),
    add(attest(a6, reproduction, k1, confirms(f1), agent, '2026-10-15T09:00:00Z')),
    add(derived_from(m1, m1)),
    add(discovery_evidence(l2, system)),
    add(lap_done(3)),
    add(model(m1, tla)),
    add(discovery_evidence(l1, model)),
    add(budget(laps, 1)),
    add(subject(m1, 'p', 'sha256:1111111111111111111111111111111111111111111111111111111111111111')),
    add(encodes(m1, c1)),
    add(assumed(q1, yes)),
    add(lap_done(1)),
    add(attest(a2, model_result, l2, calibration(m2, example(c1), matches), agent, '2026-10-15T09:00:00Z')),
    add(lap_done(2)),
    add(model_run(r10, m1, 'sha256:1111111111111111111111111111111111111111111111111111111111111111')),
    add(budget(laps, 2)),
    add(subject(l2, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333'))]).
expect(s7x19, 'discovery_ready', none).
expect(s7x19, 'no_falsifier(C)', none).
expect(s7x19, 'model_trusted(M)', none).
expect(s7x19, 'lint_issue(Code, Id, _)', none).
expect(s7x19, 'model_unfiled_break(C)', none).
expect(s7x19, 'discovery_unratified(C)', none).
expect(s7x19, 'discovery_decide', none).
variant(s7x20, [
    add(subject(r20, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(discovery_evidence(l1, model)),
    add(attest(a2, model_result, l2, verdict(m2, root_cause(x), reached), agent, '2026-10-15T09:00:00Z')),
    add(attest(a6, model_result, l2, verdict(m2, sanity, sat), agent, '2026-10-15T09:00:00Z')),
    add(reason(m2, rb, 't')),
    add(claim(c1, preserve, 'x')),
    add(hypothesis(h2, feature, 'x')),
    add(attest(a12, reproduction, m2, result(h2, not_reproduced), agent, '2026-10-15T09:00:00Z')),
    add(claim(c2, retire, 'x')),
    add(budget(laps, 3)),
    add(subject(l2, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(finding(f2, scope(x), model)),
    add(hypothesis(h1, risk, 'x')),
    add(model_run(r20, m2, 'sha256:2222222222222222222222222222222222222222222222222222222222222222')),
    add(claim(c3, introduce, 'x')),
    add(lap_done(1)),
    add(attest(a1, model_result, l1, verdict(m2, root_cause(x), reached), agent, '2026-10-15T09:00:00Z')),
    add(finding(f1, conflict([x, y]), model)),
    add(assumed(q1, yes)),
    add(subject(l1, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(answer(q1, yes, agent)),
    add(attest(a4, model_result, r20, verdict(m2, preserve(c1), unsat), agent, '2026-10-15T09:00:00Z')),
    add(discovery_evidence(l2, system)),
    add(attest(a3, model_result, l1, verdict(m2, sanity, unsat), agent, '2026-10-15T09:00:00Z')),
    add(raised_by(q1, c3)),
    add(cites(c1, 'x')),
    add(attest(a8, model_result, m2, mutation(m2, rb, survived), agent, '2026-10-15T09:00:00Z')),
    add(encodes(m2, c1)),
    add(subject(m2, 'p', 'sha256:2222222222222222222222222222222222222222222222222222222222222222')),
    add(cites(c2, 'x')),
    add(question(q1, c3, 'x')),
    add(model(m2, smt)),
    add(attest(a10, reproduction, l2, confirms(f2), agent, '2026-10-15T09:00:00Z')),
    add(attest(a9, divergence, l1, model(m2), agent, '2026-10-15T09:00:00Z')),
    add(attest(a5, model_result, l1, verdict(m2, explore(w), violated), agent, '2026-10-15T09:00:00Z')),
    add(attest(a14, disproof, l1, verdict(c1, refuted), agent, '2026-10-15T09:00:00Z')),
    add(attest(a7, model_result, m2, calibration(m2, example(c1), matches), agent, '2026-10-15T09:00:00Z')),
    add(cites(c3, 'x')),
    add(attest(a13, divergence, l2, claim(c1), agent, '2026-10-15T09:00:00Z')),
    add(attest(a11, reproduction, r20, confirms(f1), agent, '2026-10-15T09:00:00Z'))]).
expect(s7x20, 'discovery_ready', none).
expect(s7x20, 'no_falsifier(C)', none).
expect(s7x20, 'model_trusted(M)', none).
expect(s7x20, 'lint_issue(Code, Id, _)', none).
expect(s7x20, 'model_unfiled_break(C)', none).
expect(s7x20, 'discovery_unratified(C)', none).
expect(s7x20, 'discovery_decide', none).
variant(s7x21, [
    add(model_run(r20, m2, 'sha256:2222222222222222222222222222222222222222222222222222222222222222')),
    add(subject(l2, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(discovery_evidence(l1, model)),
    add(attest(a6, model_result, l1, calibration(m2, example(c1), differs), agent, '2026-10-15T09:00:00Z')),
    add(subject(r21, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(attest(a9, reproduction, m2, result(h1, not_reproduced), agent, '2026-10-15T09:00:00Z')),
    add(attest(a3, model_result, r21, verdict(m2, applies(c1), violated), agent, '2026-10-15T09:00:00Z')),
    add(claim(c1, preserve, 'x')),
    add(attest(a8, model_result, r21, mutation(m2, rb, killed), agent, '2026-10-15T09:00:00Z')),
    add(derived_from(m2, m2)),
    add(question(q1, c1, 'x')),
    add(attest(a7, model_result, r21, calibration(m2, example(c1), matches), agent, '2026-10-15T09:00:00Z')),
    add(model_run(r21, m2, 'sha256:2222222222222222222222222222222222222222222222222222222222222222')),
    add(hypothesis(h1, risk, 'x')),
    add(attest(a1, model_result, l1, verdict(m2, root_cause(x), holds), agent, '2026-10-15T09:00:00Z')),
    add(encodes(m2, c1)),
    add(attest(a4, model_result, r20, verdict(m2, applies(c1), reached), agent, '2026-10-15T09:00:00Z')),
    add(cites(c1, 'x')),
    add(assumed(q1, yes)),
    add(attest(a5, model_result, r21, verdict(m2, preserve(c1), sat), agent, '2026-10-15T09:00:00Z')),
    add(encodes(m2, c1)),
    add(subject(l1, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(model(m2, tla)),
    add(encodes(m2, c1)),
    add(subject(r20, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(raised_by(q1, c1)),
    add(attest(a2, model_result, l2, verdict(m2, preserve(c1), reached), agent, '2026-10-15T09:00:00Z')),
    add(hypothesis(h2, risk, 'x'))]).
expect(s7x21, 'discovery_ready', none).
expect(s7x21, 'no_falsifier(C)', none).
expect(s7x21, 'model_trusted(M)', none).
expect(s7x21, 'lint_issue(Code, Id, _)', none).
expect(s7x21, 'model_unfiled_break(C)', none).
expect(s7x21, 'discovery_unratified(C)', none).
expect(s7x21, 'discovery_decide', none).
variant(s7x22, [
    add(raised_by(q1, c2)),
    add(cites(c1, 'x')),
    add(attest(a1, reproduction, l2, result(h1, reproduced), agent, '2026-10-15T09:00:00Z')),
    add(answer(q2, no, agent)),
    add(question(q1, c3, 'x')),
    add(supersedes(c2, c1)),
    add(claim(c1, preserve, 'x')),
    add(assumed(q1, yes)),
    add(hypothesis(h1, risk, 'x')),
    add(assumed(q2, yes)),
    add(claim(c2, introduce, 'x')),
    add(cites(c2, 'x')),
    add(question(q2, c3, 'x')),
    add(lap_done(1)),
    add(claim(c3, preserve, 'x')),
    add(subject(l2, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(raised_by(q2, c3)),
    add(lap_done(2)),
    add(discovery_evidence(l2, system)),
    add(cites(c3, 'x')),
    add(answer(q1, no, agent)),
    add(budget(laps, 2)),
    add(supersedes(c3, c2))]).
expect(s7x22, 'discovery_ready', none).
expect(s7x22, 'no_falsifier(C)', none).
expect(s7x22, 'model_trusted(M)', none).
expect(s7x22, 'lint_issue(Code, Id, _)', none).
expect(s7x22, 'model_unfiled_break(C)', none).
expect(s7x22, 'discovery_unratified(C)', none).
expect(s7x22, 'discovery_decide', none).
variant(s7x23, [
    add(derived_from(m1, m2)),
    add(subject(r21, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(subject(m1, 'p', 'sha256:1111111111111111111111111111111111111111111111111111111111111111')),
    add(model(m1, smt)),
    add(attest(a1, model_result, r21, verdict(m1, explore(w), unknown), agent, '2026-10-15T09:00:00Z')),
    add(model_run(r20, m2, 'sha256:2222222222222222222222222222222222222222222222222222222222222222')),
    add(derived_from(m2, m2)),
    add(attest(a3, model_result, r20, calibration(m1, case('t'), differs), agent, '2026-10-15T09:00:00Z')),
    add(subject(r20, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(reason(m1, ra, 't')),
    add(model_run(r21, m2, 'sha256:2222222222222222222222222222222222222222222222222222222222222222')),
    add(attest(a4, model_result, m1, mutation(m2, rb, killed), agent, '2026-10-15T09:00:00Z')),
    add(discovery_evidence(l1, model)),
    add(attest(a6, reproduction, r21, confirms(f1), agent, '2026-10-15T09:00:00Z')),
    add(attest(a5, model_result, r20, mutation(m1, rb, survived), agent, '2026-10-15T09:00:00Z')),
    add(subject(m2, 'p', 'sha256:2222222222222222222222222222222222222222222222222222222222222222')),
    add(model(m2, tla)),
    add(finding(f1, root_cause(x), system)),
    add(subject(l1, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(attest(a2, model_result, l1, verdict(m2, root_cause(x), sat), agent, '2026-10-15T09:00:00Z'))]).
expect(s7x23, 'discovery_ready', none).
expect(s7x23, 'no_falsifier(C)', none).
expect(s7x23, 'model_trusted(M)', none).
expect(s7x23, 'lint_issue(Code, Id, _)', none).
expect(s7x23, 'model_unfiled_break(C)', none).
expect(s7x23, 'discovery_unratified(C)', none).
expect(s7x23, 'discovery_decide', none).
variant(s7x24, [
    add(lap_done(2)),
    add(budget(laps, 3)),
    add(derived_from(m1, m1)),
    add(subject(r10, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(attest(a8, model_result, r20, mutation(m2, ra, killed), agent, '2026-10-15T09:00:00Z')),
    add(model_run(r10, m1, 'sha256:1111111111111111111111111111111111111111111111111111111111111111')),
    add(subject(r11, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(reason(m1, ra, 't')),
    add(hypothesis(h1, feature, 'x')),
    add(lap_done(1)),
    add(attest(a9, divergence, m1, model(m2), agent, '2026-10-15T09:00:00Z')),
    add(attest(a7, model_result, m2, calibration(m1, case('t'), matches), agent, '2026-10-15T09:00:00Z')),
    add(model(m1, tla)),
    add(subject(r20, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(attest(a6, model_result, r11, calibration(m2, case('t'), matches), agent, '2026-10-15T09:00:00Z')),
    add(attest(a1, model_result, r21, verdict(m2, root_cause(x), holds), agent, '2026-10-15T09:00:00Z')),
    add(model_run(r20, m2, 'sha256:2222222222222222222222222222222222222222222222222222222222222222')),
    add(attest(a5, model_result, r11, verdict(m2, root_cause(x), violated), agent, '2026-10-15T09:00:00Z')),
    add(model(m2, smt)),
    add(attest(a2, model_result, r20, verdict(m2, bad_case, unknown), agent, '2026-10-15T09:00:00Z')),
    add(attest(a4, model_result, r11, verdict(m2, explore(w), violated), agent, '2026-10-15T09:00:00Z')),
    add(budget(laps, 4)),
    add(model_run(r11, m1, 'sha256:1111111111111111111111111111111111111111111111111111111111111111')),
    add(attest(a10, reproduction, m2, result(h2, reproduced), agent, '2026-10-15T09:00:00Z')),
    add(subject(r21, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(attest(a11, reproduction, r10, result(h1, not_reproduced), agent, '2026-10-15T09:00:00Z')),
    add(subject(m1, 'p', 'sha256:1111111111111111111111111111111111111111111111111111111111111111')),
    add(attest(a3, model_result, r10, verdict(m2, explore(w), sat), agent, '2026-10-15T09:00:00Z')),
    add(derived_from(m1, m2)),
    add(model_run(r21, m2, 'sha256:2222222222222222222222222222222222222222222222222222222222222222')),
    add(finding(f1, scope(x), system)),
    add(hypothesis(h2, risk, 'x'))]).
expect(s7x24, 'discovery_ready', none).
expect(s7x24, 'no_falsifier(C)', none).
expect(s7x24, 'model_trusted(M)', none).
expect(s7x24, 'lint_issue(Code, Id, _)', none).
expect(s7x24, 'model_unfiled_break(C)', none).
expect(s7x24, 'discovery_unratified(C)', none).
expect(s7x24, 'discovery_decide', none).
variant(s7x25, [
    add(attest(a5, divergence, r20, model(m1), agent, '2026-10-15T09:00:00Z')),
    add(question(q1, c1, 'x')),
    add(model(m1, tla)),
    add(assumed(q1, yes)),
    add(model_run(r21, m2, 'sha256:2222222222222222222222222222222222222222222222222222222222222222')),
    add(claim(c1, retire, 'x')),
    add(model_run(r20, m2, 'sha256:1111111111111111111111111111111111111111111111111111111111111111')),
    add(subject(r20, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(attest(a2, model_result, m2, calibration(m2, case('t'), matches), agent, '2026-10-15T09:00:00Z')),
    add(model_run(r10, m1, 'sha256:1111111111111111111111111111111111111111111111111111111111111111')),
    add(cites(c2, 'x')),
    add(discovery_evidence(k1, system)),
    add(attest(a4, model_result, m2, mutation(m1, rb, killed), agent, '2026-10-15T09:00:00Z')),
    add(model_run(r20, m2, 'sha256:1111111111111111111111111111111111111111111111111111111111111111')),
    add(subject(r10, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(model_run(r10, m1, 'sha256:2222222222222222222222222222222222222222222222222222222222222222')),
    add(discovery_evidence(l1, model)),
    add(check(k1, c1)),
    add(claim(c3, preserve, 'x')),
    add(subject(m1, 'p', 'sha256:1111111111111111111111111111111111111111111111111111111111111111')),
    add(claim(c2, retire, 'x')),
    add(cites(c1, 'x')),
    add(raised_by(q1, c2)),
    add(subject(m2, 'p', 'sha256:2222222222222222222222222222222222222222222222222222222222222222')),
    add(subject(r21, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(attest(a1, model_result, l1, calibration(m2, example(c2), matches), agent, '2026-10-15T09:00:00Z')),
    add(derived_from(m1, m1)),
    add(model(m2, smt)),
    add(attest(a3, model_result, r10, mutation(m2, rb, killed), agent, '2026-10-15T09:00:00Z')),
    add(subject(l1, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(cites(c3, 'x'))]).
expect(s7x25, 'discovery_ready', none).
expect(s7x25, 'no_falsifier(C)', none).
expect(s7x25, 'model_trusted(M)', none).
expect(s7x25, 'lint_issue(Code, Id, _)', none).
expect(s7x25, 'model_unfiled_break(C)', none).
expect(s7x25, 'discovery_unratified(C)', none).
expect(s7x25, 'discovery_decide', none).
variant(s7x26, [
    add(answer(q1, no, human)),
    add(assumed(q1, yes)),
    add(claim(c1, introduce, 'x')),
    add(assumed(q2, yes)),
    add(lap_done(1)),
    add(question(q1, c1, 'x')),
    add(question(q2, c1, 'x')),
    add(cites(c1, 'x')),
    add(budget(laps, 2))]).
expect(s7x26, 'discovery_ready', none).
expect(s7x26, 'no_falsifier(C)', none).
expect(s7x26, 'model_trusted(M)', none).
expect(s7x26, 'lint_issue(Code, Id, _)', none).
expect(s7x26, 'model_unfiled_break(C)', none).
expect(s7x26, 'discovery_unratified(C)', none).
expect(s7x26, 'discovery_decide', none).
variant(s7x27, [
    add(discovery_evidence(l2, system)),
    add(subject(l2, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(attest(a5, model_result, l2, verdict(m2, sanity, unknown), agent, '2026-10-15T09:00:00Z')),
    add(attest(a8, divergence, l2, model(m2), agent, '2026-10-15T09:00:00Z')),
    add(model_run(r20, m2, 'sha256:2222222222222222222222222222222222222222222222222222222222222222')),
    add(subject(m2, 'p', 'sha256:2222222222222222222222222222222222222222222222222222222222222222')),
    add(attest(a6, model_result, r20, mutation(m2, rb, killed), agent, '2026-10-15T09:00:00Z')),
    add(hypothesis(h1, feature, 'x')),
    add(attest(a3, model_result, l2, verdict(m2, bad_case, unsat), agent, '2026-10-15T09:00:00Z')),
    add(model(m2, smt)),
    add(claim(c3, retire, 'x')),
    add(attest(a9, reproduction, r20, result(h1, reproduced), agent, '2026-10-15T09:00:00Z')),
    add(subject(r20, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(finding(f1, conflict([x, y]), model)),
    add(attest(a10, divergence, r20, claim(c3), agent, '2026-10-15T09:00:00Z')),
    add(derived_from(m2, m2)),
    add(attest(a1, model_result, m2, verdict(m2, explore(w), holds), agent, '2026-10-15T09:00:00Z')),
    add(attest(a2, model_result, l2, verdict(m2, bad_case, unsat), agent, '2026-10-15T09:00:00Z')),
    add(attest(a11, divergence, m2, claim(c3), agent, '2026-10-15T09:00:00Z')),
    add(cites(c3, 'x')),
    add(attest(a4, model_result, r20, verdict(m2, root_cause(x), unknown), agent, '2026-10-15T09:00:00Z')),
    add(attest(a7, model_result, l2, mutation(m2, rb, killed), agent, '2026-10-15T09:00:00Z'))]).
expect(s7x27, 'discovery_ready', none).
expect(s7x27, 'no_falsifier(C)', none).
expect(s7x27, 'model_trusted(M)', none).
expect(s7x27, 'lint_issue(Code, Id, _)', none).
expect(s7x27, 'model_unfiled_break(C)', none).
expect(s7x27, 'discovery_unratified(C)', none).
expect(s7x27, 'discovery_decide', none).
variant(s7x28, [
    add(finding(f2, scope(x), model)),
    add(subject(l1, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(discovery_evidence(l1, model)),
    add(attest(a1, reproduction, l1, confirms(f2), agent, '2026-10-15T09:00:00Z')),
    add(attest(a2, reproduction, l1, result(h1, not_reproduced), agent, '2026-10-15T09:00:00Z')),
    add(hypothesis(h2, feature, 'x')),
    add(hypothesis(h1, risk, 'x'))]).
expect(s7x28, 'discovery_ready', none).
expect(s7x28, 'no_falsifier(C)', none).
expect(s7x28, 'model_trusted(M)', none).
expect(s7x28, 'lint_issue(Code, Id, _)', none).
expect(s7x28, 'model_unfiled_break(C)', none).
expect(s7x28, 'discovery_unratified(C)', none).
expect(s7x28, 'discovery_decide', none).
variant(s7x29, [
    add(cites(c1, 'x')),
    add(lap_done(1)),
    add(claim(c1, retire, 'x')),
    add(budget(laps, 2)),
    add(lap_done(2)),
    add(attest(a1, disproof, zz, claim(c1), agent, '2026-10-15T09:00:00Z')),
    add(attest(a2, divergence, zz, verdict(c1, inconclusive), agent, '2026-10-15T09:00:00Z')),
    add(finding(f1, root_cause(x), system)),
    add(lap_done(4)),
    add(finding(f2, scope(x), model)),
    add(lap_done(3))]).
expect(s7x29, 'discovery_ready', none).
expect(s7x29, 'no_falsifier(C)', none).
expect(s7x29, 'model_trusted(M)', none).
expect(s7x29, 'lint_issue(Code, Id, _)', none).
expect(s7x29, 'model_unfiled_break(C)', none).
expect(s7x29, 'discovery_unratified(C)', none).
expect(s7x29, 'discovery_decide', none).
variant(s7x30, [
    add(question(q1, c2, 'x')),
    add(attest(a9, reproduction, m1, result(h2, reproduced), agent, '2026-10-15T09:00:00Z')),
    add(claim(c1, retire, 'x')),
    add(budget(laps, 2)),
    add(answer(q1, no, agent)),
    add(lap_done(1)),
    add(attest(a11, divergence, m1, verdict(c1, inconclusive), agent, '2026-10-15T09:00:00Z')),
    add(finding(f1, root_cause(x), model)),
    add(cites(c2, 'x')),
    add(raised_by(q1, h2)),
    add(attest(a6, model_result, m1, calibration(m1, example(c3), matches), agent, '2026-10-15T09:00:00Z')),
    add(reason(m1, ra, 't')),
    add(attest(a8, reproduction, m1, confirms(f2), agent, '2026-10-15T09:00:00Z')),
    add(hypothesis(h2, feature, 'x')),
    add(attest(a3, model_result, m1, verdict(m1, preserve(c1), sat), agent, '2026-10-15T09:00:00Z')),
    add(attest(a2, model_result, m1, verdict(m1, root_cause(x), unsat), agent, '2026-10-15T09:00:00Z')),
    add(attest(a10, reproduction, m1, result(h1, not_reproduced), agent, '2026-10-15T09:00:00Z')),
    add(attest(a4, model_result, m1, verdict(m1, applies(c1), unknown), agent, '2026-10-15T09:00:00Z')),
    add(attest(a1, model_result, m1, verdict(m1, preserve(c3), violated), agent, '2026-10-15T09:00:00Z')),
    add(claim(c2, preserve, 'x')),
    add(budget(laps, 3)),
    add(cites(c1, 'x')),
    add(claim(c3, retire, 'x')),
    add(cites(c3, 'x')),
    add(assumed(q1, yes)),
    add(supersedes(c2, c3)),
    add(model(m1, smt)),
    add(hypothesis(h1, risk, 'x')),
    add(attest(a5, model_result, m1, calibration(m1, case('t'), matches), agent, '2026-10-15T09:00:00Z')),
    add(derived_from(m1, m1)),
    add(attest(a7, model_result, m1, mutation(m1, rb, killed), agent, '2026-10-15T09:00:00Z')),
    add(finding(f2, surprise(x), system))]).
expect(s7x30, 'discovery_ready', none).
expect(s7x30, 'no_falsifier(C)', none).
expect(s7x30, 'model_trusted(M)', none).
expect(s7x30, 'lint_issue(Code, Id, _)', none).
expect(s7x30, 'model_unfiled_break(C)', none).
expect(s7x30, 'discovery_unratified(C)', none).
expect(s7x30, 'discovery_decide', none).
variant(s7x31, [
    add(cites(c1, 'x')),
    add(supersedes(c1, c3)),
    add(attest(a1, model_result, m1, verdict(m1, sanity, holds), agent, '2026-10-15T09:00:00Z')),
    add(attest(a4, model_result, m1, calibration(m1, example(c1), matches), agent, '2026-10-15T09:00:00Z')),
    add(claim(c1, introduce, 'x')),
    add(derived_from(m1, m1)),
    add(encodes(m1, c1)),
    add(finding(f1, root_cause(x), system)),
    add(claim(c3, introduce, 'x')),
    add(attest(a2, model_result, m1, verdict(m1, explore(w), unsat), agent, '2026-10-15T09:00:00Z')),
    add(attest(a7, reproduction, m1, confirms(f2), agent, '2026-10-15T09:00:00Z')),
    add(attest(a5, model_result, m1, calibration(m1, example(c1), matches), agent, '2026-10-15T09:00:00Z')),
    add(finding(f2, trace(x), system)),
    add(lap_done(2)),
    add(lap_done(1)),
    add(cites(c3, 'x')),
    add(question(q2, c3, 'x')),
    add(budget(laps, 1)),
    add(assumed(q2, yes)),
    add(attest(a9, divergence, m1, verdict(c1, inconclusive), agent, '2026-10-15T09:00:00Z')),
    add(model(m1, tla)),
    add(assumed(q1, yes)),
    add(encodes(m1, c1)),
    add(answer(q2, yes, agent)),
    add(subject(m1, 'p', 'sha256:1111111111111111111111111111111111111111111111111111111111111111')),
    add(attest(a8, divergence, m1, verdict(c1, abstained), agent, '2026-10-15T09:00:00Z')),
    add(attest(a3, model_result, m1, verdict(m1, preserve(c1), violated), agent, '2026-10-15T09:00:00Z')),
    add(attest(a6, model_result, m1, mutation(m1, rb, survived), agent, '2026-10-15T09:00:00Z')),
    add(raised_by(q2, c3)),
    add(encodes(m1, c1)),
    add(question(q1, c1, 'x'))]).
expect(s7x31, 'discovery_ready', none).
expect(s7x31, 'no_falsifier(C)', none).
expect(s7x31, 'model_trusted(M)', none).
expect(s7x31, 'lint_issue(Code, Id, _)', none).
expect(s7x31, 'model_unfiled_break(C)', none).
expect(s7x31, 'discovery_unratified(C)', none).
expect(s7x31, 'discovery_decide', none).
variant(s7x32, [
    add(finding(f1, conflict([x, y]), system)),
    add(lap_done(1)),
    add(attest(a4, reproduction, l2, confirms(f1), agent, '2026-10-15T09:00:00Z')),
    add(attest(a3, divergence, m1, model(m1), agent, '2026-10-15T09:00:00Z')),
    add(discovery_evidence(l2, model)),
    add(finding(f2, scope(x), system)),
    add(attest(a1, model_result, m2, mutation(m2, rb, killed), agent, '2026-10-15T09:00:00Z')),
    add(subject(m2, 'p', 'sha256:2222222222222222222222222222222222222222222222222222222222222222')),
    add(subject(m1, 'p', 'sha256:1111111111111111111111111111111111111111111111111111111111111111')),
    add(lap_done(2)),
    add(subject(l1, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(model(m1, smt)),
    add(budget(laps, 1)),
    add(attest(a2, model_result, l1, mutation(m2, ra, killed), agent, '2026-10-15T09:00:00Z')),
    add(subject(l2, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(discovery_evidence(l1, model)),
    add(lap_done(3)),
    add(lap_done(4)),
    add(model(m2, tla))]).
expect(s7x32, 'discovery_ready', none).
expect(s7x32, 'no_falsifier(C)', none).
expect(s7x32, 'model_trusted(M)', none).
expect(s7x32, 'lint_issue(Code, Id, _)', none).
expect(s7x32, 'model_unfiled_break(C)', none).
expect(s7x32, 'discovery_unratified(C)', none).
expect(s7x32, 'discovery_decide', none).
variant(s7x33, [
    add(hypothesis(h1, defect, 'x')),
    add(budget(laps, 2)),
    add(cites(c2, 'x')),
    add(attest(a1, disproof, zz, verdict(c2, inconclusive), agent, '2026-10-15T09:00:00Z')),
    add(claim(c2, retire, 'x'))]).
expect(s7x33, 'discovery_ready', none).
expect(s7x33, 'no_falsifier(C)', none).
expect(s7x33, 'model_trusted(M)', none).
expect(s7x33, 'lint_issue(Code, Id, _)', none).
expect(s7x33, 'model_unfiled_break(C)', none).
expect(s7x33, 'discovery_unratified(C)', none).
expect(s7x33, 'discovery_decide', none).
variant(s7x34, [
    add(model(m1, tla)),
    add(attest(a8, model_result, m1, mutation(m1, ra, survived), agent, '2026-10-15T09:00:00Z')),
    add(reason(m1, ra, 't')),
    add(claim(c2, preserve, 'x')),
    add(cites(c1, 'x')),
    add(lap_done(1)),
    add(attest(a2, model_result, m1, verdict(m2, applies(c3), unsat), agent, '2026-10-15T09:00:00Z')),
    add(attest(a6, model_result, m2, calibration(m1, case('t'), differs), agent, '2026-10-15T09:00:00Z')),
    add(check(k1, c1)),
    add(cites(c2, 'x')),
    add(discovery_evidence(k1, system)),
    add(lap_done(2)),
    add(attest(a3, model_result, m2, verdict(m2, applies(c2), reached), agent, '2026-10-15T09:00:00Z')),
    add(subject(m2, 'p', 'sha256:2222222222222222222222222222222222222222222222222222222222222222')),
    add(attest(a5, model_result, m1, verdict(m1, applies(c3), sat), agent, '2026-10-15T09:00:00Z')),
    add(encodes(m2, c2)),
    add(attest(a4, model_result, m1, verdict(m2, applies(c2), unsat), agent, '2026-10-15T09:00:00Z')),
    add(model(m2, smt)),
    add(claim(c1, retire, 'x')),
    add(cites(c3, 'x')),
    add(subject(m1, 'p', 'sha256:1111111111111111111111111111111111111111111111111111111111111111')),
    add(claim(c3, retire, 'x')),
    add(finding(f2, conflict([x, y]), model)),
    add(attest(a7, model_result, m1, calibration(m2, case('t'), matches), agent, '2026-10-15T09:00:00Z')),
    add(budget(laps, 3)),
    add(attest(a1, model_result, m1, verdict(m2, preserve(c3), unsat), agent, '2026-10-15T09:00:00Z')),
    add(encodes(m2, c1))]).
expect(s7x34, 'discovery_ready', none).
expect(s7x34, 'no_falsifier(C)', none).
expect(s7x34, 'model_trusted(M)', none).
expect(s7x34, 'lint_issue(Code, Id, _)', none).
expect(s7x34, 'model_unfiled_break(C)', none).
expect(s7x34, 'discovery_unratified(C)', none).
expect(s7x34, 'discovery_decide', none).
variant(s7x35, [
    add(question(q1, c3, 'x')),
    add(budget(laps, 4)),
    add(raised_by(q1, h1)),
    add(lap_done(1)),
    add(attest(a5, disproof, r11, claim(c3), agent, '2026-10-15T09:00:00Z')),
    add(subject(m1, 'p', 'sha256:1111111111111111111111111111111111111111111111111111111111111111')),
    add(claim(c3, introduce, 'x')),
    add(subject(r11, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(hypothesis(h2, feature, 'x')),
    add(attest(a2, model_result, r10, calibration(m1, case('t'), matches), agent, '2026-10-15T09:00:00Z')),
    add(lap_done(2)),
    add(answer(q1, no, human)),
    add(derived_from(m1, m1)),
    add(attest(a4, reproduction, r10, result(h1, reproduced), agent, '2026-10-15T09:00:00Z')),
    add(assumed(q1, yes)),
    add(model_run(r11, m1, 'sha256:1111111111111111111111111111111111111111111111111111111111111111')),
    add(subject(r10, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(hypothesis(h1, defect, 'x')),
    add(attest(a3, model_result, m1, mutation(m1, rb, survived), agent, '2026-10-15T09:00:00Z')),
    add(budget(laps, 3)),
    add(attest(a1, model_result, m1, calibration(m1, example(c3), matches), agent, '2026-10-15T09:00:00Z')),
    add(model(m1, tla)),
    add(cites(c3, 'x')),
    add(model_run(r10, m1, 'sha256:3333333333333333333333333333333333333333333333333333333333333333'))]).
expect(s7x35, 'discovery_ready', none).
expect(s7x35, 'no_falsifier(C)', none).
expect(s7x35, 'model_trusted(M)', none).
expect(s7x35, 'lint_issue(Code, Id, _)', none).
expect(s7x35, 'model_unfiled_break(C)', none).
expect(s7x35, 'discovery_unratified(C)', none).
expect(s7x35, 'discovery_decide', none).
variant(s7x36, [
    add(claim(c3, introduce, 'x')),
    add(subject(l1, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(lap_done(2)),
    add(lap_done(1)),
    add(assumed(q1, yes)),
    add(attest(a1, reproduction, l2, confirms(f2), agent, '2026-10-15T09:00:00Z')),
    add(attest(a3, reproduction, l2, result(h1, reproduced), agent, '2026-10-15T09:00:00Z')),
    add(budget(laps, 3)),
    add(finding(f1, conflict([x, y]), model)),
    add(discovery_evidence(l2, system)),
    add(check(k1, c1)),
    add(raised_by(q1, h1)),
    add(cites(c1, 'x')),
    add(discovery_evidence(k1, model)),
    add(claim(c1, introduce, 'x')),
    add(finding(f2, surprise(x), system)),
    add(hypothesis(h1, risk, 'x')),
    add(budget(laps, 2)),
    add(attest(a2, reproduction, l1, confirms(f1), agent, '2026-10-15T09:00:00Z')),
    add(question(q1, c3, 'x')),
    add(cites(c3, 'x')),
    add(subject(l2, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(answer(q1, yes, human))]).
expect(s7x36, 'discovery_ready', none).
expect(s7x36, 'no_falsifier(C)', none).
expect(s7x36, 'model_trusted(M)', none).
expect(s7x36, 'lint_issue(Code, Id, _)', none).
expect(s7x36, 'model_unfiled_break(C)', none).
expect(s7x36, 'discovery_unratified(C)', none).
expect(s7x36, 'discovery_decide', none).
variant(s7x37, [
    add(subject(r10, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(check(k1, c1)),
    add(model_run(r11, m1, 'sha256:2222222222222222222222222222222222222222222222222222222222222222')),
    add(attest(a3, model_result, l1, calibration(m1, example(c2), matches), agent, '2026-10-15T09:00:00Z')),
    add(discovery_evidence(k1, system)),
    add(derived_from(m1, m1)),
    add(attest(a7, divergence, m1, verdict(c1, abstained), agent, '2026-10-15T09:00:00Z')),
    add(cites(c1, 'x')),
    add(claim(c2, introduce, 'x')),
    add(subject(l1, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(supersedes(c1, c2)),
    add(supersedes(c2, c1)),
    add(claim(c1, introduce, 'x')),
    add(subject(r11, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(attest(a5, model_result, r10, mutation(m1, rb, killed), agent, '2026-10-15T09:00:00Z')),
    add(model_run(r11, m1, 'sha256:1111111111111111111111111111111111111111111111111111111111111111')),
    add(model(m1, smt)),
    add(model_run(r10, m1, 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(attest(a1, model_result, r11, verdict(m1, bad_case, holds), agent, '2026-10-15T09:00:00Z')),
    add(discovery_evidence(l1, system)),
    add(attest(a2, model_result, r10, calibration(m1, case('t'), matches), agent, '2026-10-15T09:00:00Z')),
    add(subject(m1, 'p', 'sha256:1111111111111111111111111111111111111111111111111111111111111111')),
    add(attest(a4, model_result, m1, mutation(m1, rb, killed), agent, '2026-10-15T09:00:00Z')),
    add(attest(a6, divergence, m1, verdict(c2, inconclusive), agent, '2026-10-15T09:00:00Z')),
    add(cites(c2, 'x')),
    add(assumed(q1, yes)),
    add(question(q1, c2, 'x'))]).
expect(s7x37, 'discovery_ready', none).
expect(s7x37, 'no_falsifier(C)', none).
expect(s7x37, 'model_trusted(M)', none).
expect(s7x37, 'lint_issue(Code, Id, _)', none).
expect(s7x37, 'model_unfiled_break(C)', none).
expect(s7x37, 'discovery_unratified(C)', none).
expect(s7x37, 'discovery_decide', none).
variant(s7x38, [
    add(hypothesis(h2, risk, 'x')),
    add(budget(laps, 3)),
    add(budget(laps, 4)),
    add(attest(a1, reproduction, k1, result(h1, not_reproduced), agent, '2026-10-15T09:00:00Z')),
    add(hypothesis(h1, feature, 'x')),
    add(claim(c1, retire, 'x')),
    add(discovery_evidence(k1, model)),
    add(cites(c2, 'x')),
    add(claim(c3, preserve, 'x')),
    add(claim(c2, retire, 'x')),
    add(finding(f2, conflict([x, y]), system)),
    add(attest(a3, divergence, k1, claim(c1), agent, '2026-10-15T09:00:00Z')),
    add(question(q1, c2, 'x')),
    add(attest(a2, reproduction, k1, result(h2, reproduced), agent, '2026-10-15T09:00:00Z')),
    add(attest(a4, divergence, k1, claim(c2), agent, '2026-10-15T09:00:00Z')),
    add(assumed(q1, yes)),
    add(cites(c3, 'x')),
    add(finding(f1, conflict([x, y]), model)),
    add(cites(c1, 'x')),
    add(raised_by(q1, f2)),
    add(check(k1, c2)),
    add(answer(q1, yes, agent))]).
expect(s7x38, 'discovery_ready', none).
expect(s7x38, 'no_falsifier(C)', none).
expect(s7x38, 'model_trusted(M)', none).
expect(s7x38, 'lint_issue(Code, Id, _)', none).
expect(s7x38, 'model_unfiled_break(C)', none).
expect(s7x38, 'discovery_unratified(C)', none).
expect(s7x38, 'discovery_decide', none).
variant(s7x39, [
    add(subject(l2, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(finding(f1, root_cause(x), model)),
    add(hypothesis(h1, feature, 'x')),
    add(subject(l1, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(attest(a2, reproduction, l1, result(h1, not_reproduced), agent, '2026-10-15T09:00:00Z')),
    add(finding(f2, scope(x), system)),
    add(attest(a1, reproduction, l2, confirms(f2), agent, '2026-10-15T09:00:00Z')),
    add(discovery_evidence(l1, system)),
    add(discovery_evidence(l2, model))]).
expect(s7x39, 'discovery_ready', none).
expect(s7x39, 'no_falsifier(C)', none).
expect(s7x39, 'model_trusted(M)', none).
expect(s7x39, 'lint_issue(Code, Id, _)', none).
expect(s7x39, 'model_unfiled_break(C)', none).
expect(s7x39, 'discovery_unratified(C)', none).
expect(s7x39, 'discovery_decide', none).
variant(s7x40, [
    add(attest(a2, divergence, zz, verdict(c2, abstained), agent, '2026-10-15T09:00:00Z')),
    add(answer(q1, no, agent)),
    add(cites(c2, 'x')),
    add(budget(laps, 2)),
    add(assumed(q1, yes)),
    add(claim(c1, introduce, 'x')),
    add(raised_by(q1, c1)),
    add(claim(c2, retire, 'x')),
    add(finding(f1, trace(x), model)),
    add(budget(laps, 1)),
    add(question(q1, c2, 'x')),
    add(lap_done(4)),
    add(lap_done(1)),
    add(attest(a1, divergence, zz, claim(c2), agent, '2026-10-15T09:00:00Z')),
    add(lap_done(2)),
    add(lap_done(3)),
    add(finding(f2, conflict([x, y]), system)),
    add(cites(c1, 'x'))]).
expect(s7x40, 'discovery_ready', none).
expect(s7x40, 'no_falsifier(C)', none).
expect(s7x40, 'model_trusted(M)', none).
expect(s7x40, 'lint_issue(Code, Id, _)', none).
expect(s7x40, 'model_unfiled_break(C)', none).
expect(s7x40, 'discovery_unratified(C)', none).
expect(s7x40, 'discovery_decide', none).
variant(s7x41, [
    add(attest(a3, model_result, l2, calibration(m2, case('t'), matches), agent, '2026-10-15T09:00:00Z')),
    add(model(m1, tla)),
    add(subject(r20, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(attest(a7, reproduction, m2, result(h1, reproduced), agent, '2026-10-15T09:00:00Z')),
    add(subject(r21, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(subject(m1, 'p', 'sha256:1111111111111111111111111111111111111111111111111111111111111111')),
    add(model_run(r21, m2, 'sha256:1111111111111111111111111111111111111111111111111111111111111111')),
    add(subject(m2, 'p', 'sha256:2222222222222222222222222222222222222222222222222222222222222222')),
    add(attest(a6, reproduction, r21, confirms(f1), agent, '2026-10-15T09:00:00Z')),
    add(attest(a4, divergence, r20, model(m2), agent, '2026-10-15T09:00:00Z')),
    add(attest(a1, model_result, l2, verdict(m1, sanity, unknown), agent, '2026-10-15T09:00:00Z')),
    add(subject(l2, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(attest(a5, reproduction, r20, confirms(f2), agent, '2026-10-15T09:00:00Z')),
    add(model_run(r20, m2, 'sha256:2222222222222222222222222222222222222222222222222222222222222222')),
    add(derived_from(m2, m2)),
    add(attest(a2, model_result, r21, calibration(m2, case('t'), differs), agent, '2026-10-15T09:00:00Z')),
    add(discovery_evidence(l2, system)),
    add(derived_from(m2, m2)),
    add(model(m2, smt)),
    add(finding(f1, root_cause(x), system)),
    add(model_run(r21, m2, 'sha256:1111111111111111111111111111111111111111111111111111111111111111')),
    add(model_run(r20, m2, 'sha256:1111111111111111111111111111111111111111111111111111111111111111')),
    add(subject(l1, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(subject(r10, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(hypothesis(h1, defect, 'x')),
    add(finding(f2, surprise(x), system)),
    add(model_run(r10, m1, 'sha256:1111111111111111111111111111111111111111111111111111111111111111'))]).
expect(s7x41, 'discovery_ready', none).
expect(s7x41, 'no_falsifier(C)', none).
expect(s7x41, 'model_trusted(M)', none).
expect(s7x41, 'lint_issue(Code, Id, _)', none).
expect(s7x41, 'model_unfiled_break(C)', none).
expect(s7x41, 'discovery_unratified(C)', none).
expect(s7x41, 'discovery_decide', none).
variant(s7x42, [
    add(claim(c3, introduce, 'x')),
    add(lap_done(1)),
    add(cites(c1, 'x')),
    add(lap_done(2)),
    add(check(k1, c1)),
    add(discovery_evidence(l2, system)),
    add(cites(c3, 'x')),
    add(budget(laps, 2)),
    add(lap_done(4)),
    add(budget(laps, 1)),
    add(discovery_evidence(l1, system)),
    add(attest(a1, disproof, l1, claim(c1), agent, '2026-10-15T09:00:00Z')),
    add(subject(l1, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(discovery_evidence(k1, model)),
    add(subject(l2, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(lap_done(3)),
    add(attest(a2, divergence, l1, verdict(c3, inconclusive), agent, '2026-10-15T09:00:00Z')),
    add(claim(c1, retire, 'x'))]).
expect(s7x42, 'discovery_ready', none).
expect(s7x42, 'no_falsifier(C)', none).
expect(s7x42, 'model_trusted(M)', none).
expect(s7x42, 'lint_issue(Code, Id, _)', none).
expect(s7x42, 'model_unfiled_break(C)', none).
expect(s7x42, 'discovery_unratified(C)', none).
expect(s7x42, 'discovery_decide', none).
variant(s7x43, [
    add(finding(f1, scope(x), system)),
    add(discovery_evidence(l2, system)),
    add(attest(a1, reproduction, l2, confirms(f1), agent, '2026-10-15T09:00:00Z')),
    add(subject(l2, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(attest(a2, reproduction, l2, result(h2, reproduced), agent, '2026-10-15T09:00:00Z')),
    add(hypothesis(h2, risk, 'x'))]).
expect(s7x43, 'discovery_ready', none).
expect(s7x43, 'no_falsifier(C)', none).
expect(s7x43, 'model_trusted(M)', none).
expect(s7x43, 'lint_issue(Code, Id, _)', none).
expect(s7x43, 'model_unfiled_break(C)', none).
expect(s7x43, 'discovery_unratified(C)', none).
expect(s7x43, 'discovery_decide', none).
variant(s7x44, [
    add(assumed(q2, yes)),
    add(attest(a3, reproduction, l2, result(h1, reproduced), agent, '2026-10-15T09:00:00Z')),
    add(subject(l1, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(assumed(q1, yes)),
    add(lap_done(3)),
    add(attest(a2, reproduction, l2, confirms(f1), agent, '2026-10-15T09:00:00Z')),
    add(answer(q2, no, human)),
    add(finding(f2, trace(x), model)),
    add(claim(c3, preserve, 'x')),
    add(raised_by(q2, f2)),
    add(cites(c3, 'x')),
    add(raised_by(q1, c3)),
    add(discovery_evidence(l1, model)),
    add(hypothesis(h1, defect, 'x')),
    add(question(q1, c3, 'x')),
    add(lap_done(2)),
    add(budget(laps, 1)),
    add(subject(l2, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(discovery_evidence(l2, system)),
    add(question(q2, c3, 'x')),
    add(attest(a1, reproduction, l1, confirms(f2), agent, '2026-10-15T09:00:00Z')),
    add(finding(f1, surprise(x), model)),
    add(lap_done(1))]).
expect(s7x44, 'discovery_ready', none).
expect(s7x44, 'no_falsifier(C)', none).
expect(s7x44, 'model_trusted(M)', none).
expect(s7x44, 'lint_issue(Code, Id, _)', none).
expect(s7x44, 'model_unfiled_break(C)', none).
expect(s7x44, 'discovery_unratified(C)', none).
expect(s7x44, 'discovery_decide', none).
variant(s7x45, [
    add(model(m1, smt)),
    add(reason(m1, ra, 't')),
    add(attest(a3, model_result, l1, verdict(m1, sanity, unsat), agent, '2026-10-15T09:00:00Z')),
    add(cites(c3, 'x')),
    add(attest(a6, model_result, l1, mutation(m1, ra, killed), agent, '2026-10-15T09:00:00Z')),
    add(encodes(m1, c3)),
    add(subject(m1, 'p', 'sha256:1111111111111111111111111111111111111111111111111111111111111111')),
    add(attest(a8, divergence, l1, claim(c3), agent, '2026-10-15T09:00:00Z')),
    add(encodes(m1, c3)),
    add(attest(a1, model_result, m1, verdict(m1, root_cause(x), reached), agent, '2026-10-15T09:00:00Z')),
    add(hypothesis(h1, defect, 'x')),
    add(claim(c3, preserve, 'x')),
    add(budget(laps, 3)),
    add(hypothesis(h2, feature, 'x')),
    add(finding(f1, surprise(x), model)),
    add(question(q1, c3, 'x')),
    add(assumed(q1, yes)),
    add(attest(a9, divergence, l1, claim(c3), agent, '2026-10-15T09:00:00Z')),
    add(subject(l1, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(lap_done(2)),
    add(lap_done(1)),
    add(attest(a7, reproduction, l1, result(h1, reproduced), agent, '2026-10-15T09:00:00Z')),
    add(attest(a2, model_result, m1, verdict(m1, sanity, unsat), agent, '2026-10-15T09:00:00Z')),
    add(attest(a5, model_result, l1, calibration(m1, example(c3), matches), agent, '2026-10-15T09:00:00Z')),
    add(attest(a4, model_result, m1, calibration(m1, case('t'), differs), agent, '2026-10-15T09:00:00Z'))]).
expect(s7x45, 'discovery_ready', none).
expect(s7x45, 'no_falsifier(C)', none).
expect(s7x45, 'model_trusted(M)', none).
expect(s7x45, 'lint_issue(Code, Id, _)', none).
expect(s7x45, 'model_unfiled_break(C)', none).
expect(s7x45, 'discovery_unratified(C)', none).
expect(s7x45, 'discovery_decide', none).
variant(s7x46, [
    add(subject(r11, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(model_run(r20, m2, 'sha256:2222222222222222222222222222222222222222222222222222222222222222')),
    add(attest(a5, model_result, r11, calibration(m2, case('t'), differs), agent, '2026-10-15T09:00:00Z')),
    add(attest(a7, model_result, r10, mutation(m2, rb, killed), agent, '2026-10-15T09:00:00Z')),
    add(discovery_evidence(l1, system)),
    add(derived_from(m2, m1)),
    add(model(m2, smt)),
    add(subject(m1, 'p', 'sha256:1111111111111111111111111111111111111111111111111111111111111111')),
    add(lap_done(4)),
    add(attest(a4, model_result, l2, verdict(m2, sanity, sat), agent, '2026-10-15T09:00:00Z')),
    add(model_run(r10, m1, 'sha256:1111111111111111111111111111111111111111111111111111111111111111')),
    add(subject(l1, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(budget(laps, 2)),
    add(finding(f1, trace(x), model)),
    add(lap_done(1)),
    add(subject(r20, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(attest(a2, model_result, l2, verdict(m1, bad_case, holds), agent, '2026-10-15T09:00:00Z')),
    add(attest(a6, model_result, r10, calibration(m1, case('t'), matches), agent, '2026-10-15T09:00:00Z')),
    add(discovery_evidence(l2, system)),
    add(lap_done(2)),
    add(lap_done(3)),
    add(model_run(r11, m1, 'sha256:1111111111111111111111111111111111111111111111111111111111111111')),
    add(model(m1, tla)),
    add(subject(l2, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(attest(a8, model_result, m2, mutation(m2, rb, survived), agent, '2026-10-15T09:00:00Z')),
    add(attest(a1, model_result, m2, verdict(m1, sanity, unsat), agent, '2026-10-15T09:00:00Z')),
    add(subject(r10, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(attest(a3, model_result, m1, verdict(m1, explore(w), holds), agent, '2026-10-15T09:00:00Z'))]).
expect(s7x46, 'discovery_ready', none).
expect(s7x46, 'no_falsifier(C)', none).
expect(s7x46, 'model_trusted(M)', none).
expect(s7x46, 'lint_issue(Code, Id, _)', none).
expect(s7x46, 'model_unfiled_break(C)', none).
expect(s7x46, 'discovery_unratified(C)', none).
expect(s7x46, 'discovery_decide', none).
variant(s7x47, [
    add(answer(q1, no, agent)),
    add(budget(laps, 1)),
    add(attest(a1, reproduction, l1, confirms(f1), agent, '2026-10-15T09:00:00Z')),
    add(claim(c3, retire, 'x')),
    add(hypothesis(h2, feature, 'x')),
    add(cites(c1, 'x')),
    add(cites(c3, 'x')),
    add(discovery_evidence(l1, system)),
    add(answer(q2, yes, agent)),
    add(finding(f2, conflict([x, y]), model)),
    add(cites(c2, 'x')),
    add(claim(c2, preserve, 'x')),
    add(assumed(q2, yes)),
    add(finding(f1, trace(x), system)),
    add(subject(l1, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(question(q1, c1, 'x')),
    add(question(q2, c2, 'x')),
    add(raised_by(q2, c1)),
    add(attest(a2, reproduction, l1, result(h2, reproduced), agent, '2026-10-15T09:00:00Z')),
    add(assumed(q1, yes)),
    add(claim(c1, introduce, 'x'))]).
expect(s7x47, 'discovery_ready', none).
expect(s7x47, 'no_falsifier(C)', none).
expect(s7x47, 'model_trusted(M)', none).
expect(s7x47, 'lint_issue(Code, Id, _)', none).
expect(s7x47, 'model_unfiled_break(C)', none).
expect(s7x47, 'discovery_unratified(C)', none).
expect(s7x47, 'discovery_decide', none).
variant(s7x48, [
    add(cites(c2, 'x')),
    add(discovery_evidence(l2, system)),
    add(claim(c3, preserve, 'x')),
    add(attest(a1, reproduction, l2, result(h1, not_reproduced), agent, '2026-10-15T09:00:00Z')),
    add(claim(c1, introduce, 'x')),
    add(claim(c2, introduce, 'x')),
    add(hypothesis(h1, risk, 'x')),
    add(subject(l2, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(cites(c1, 'x')),
    add(cites(c3, 'x')),
    add(budget(laps, 1))]).
expect(s7x48, 'discovery_ready', none).
expect(s7x48, 'no_falsifier(C)', none).
expect(s7x48, 'model_trusted(M)', none).
expect(s7x48, 'lint_issue(Code, Id, _)', none).
expect(s7x48, 'model_unfiled_break(C)', none).
expect(s7x48, 'discovery_unratified(C)', none).
expect(s7x48, 'discovery_decide', none).
variant(s7x49, [
    add(attest(a3, model_result, m1, calibration(m1, example(c2), differs), agent, '2026-10-15T09:00:00Z')),
    add(model_run(r10, m1, 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(attest(a10, divergence, l2, claim(c1), agent, '2026-10-15T09:00:00Z')),
    add(model(m1, smt)),
    add(cites(c1, 'x')),
    add(question(q1, c1, 'x')),
    add(attest(a4, model_result, r10, mutation(m1, rb, survived), agent, '2026-10-15T09:00:00Z')),
    add(raised_by(q1, f2)),
    add(discovery_evidence(l2, model)),
    add(cites(c2, 'x')),
    add(claim(c1, retire, 'x')),
    add(model_run(r10, m1, 'sha256:1111111111111111111111111111111111111111111111111111111111111111')),
    add(lap_done(1)),
    add(attest(a6, reproduction, r10, confirms(f2), agent, '2026-10-15T09:00:00Z')),
    add(subject(m1, 'p', 'sha256:1111111111111111111111111111111111111111111111111111111111111111')),
    add(reason(m1, rb, 't')),
    add(check(k1, c2)),
    add(finding(f2, trace(x), model)),
    add(lap_done(3)),
    add(budget(laps, 3)),
    add(attest(a9, divergence, k1, verdict(c2, abstained), agent, '2026-10-15T09:00:00Z')),
    add(claim(c2, introduce, 'x')),
    add(attest(a1, model_result, m1, verdict(m1, preserve(c2), holds), agent, '2026-10-15T09:00:00Z')),
    add(attest(a5, divergence, m1, model(m1), agent, '2026-10-15T09:00:00Z')),
    add(assumed(q1, yes)),
    add(attest(a2, model_result, l2, calibration(m1, case('t'), matches), agent, '2026-10-15T09:00:00Z')),
    add(discovery_evidence(k1, system)),
    add(finding(f1, conflict([x, y]), model)),
    add(lap_done(2)),
    add(subject(r10, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(attest(a7, reproduction, r10, confirms(f1), agent, '2026-10-15T09:00:00Z')),
    add(subject(l2, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(claim(c3, preserve, 'x')),
    add(hypothesis(h2, feature, 'x')),
    add(cites(c3, 'x')),
    add(hypothesis(h1, feature, 'x')),
    add(attest(a8, reproduction, r10, result(h1, not_reproduced), agent, '2026-10-15T09:00:00Z'))]).
expect(s7x49, 'discovery_ready', none).
expect(s7x49, 'no_falsifier(C)', none).
expect(s7x49, 'model_trusted(M)', none).
expect(s7x49, 'lint_issue(Code, Id, _)', none).
expect(s7x49, 'model_unfiled_break(C)', none).
expect(s7x49, 'discovery_unratified(C)', none).
expect(s7x49, 'discovery_decide', none).
variant(s7x50, [
    add(attest(a4, reproduction, m1, confirms(f1), agent, '2026-10-15T09:00:00Z')),
    add(finding(f1, scope(x), system)),
    add(encodes(m1, c3)),
    add(finding(f2, trace(x), model)),
    add(attest(a3, model_result, r20, mutation(m1, rb, killed), agent, '2026-10-15T09:00:00Z')),
    add(subject(r20, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(claim(c3, preserve, 'x')),
    add(budget(laps, 3)),
    add(model(m2, tla)),
    add(attest(a2, model_result, r20, calibration(m2, example(c3), differs), agent, '2026-10-15T09:00:00Z')),
    add(check(k1, c3)),
    add(attest(a5, divergence, l1, claim(c3), agent, '2026-10-15T09:00:00Z')),
    add(attest(a1, model_result, r20, verdict(m2, sanity, unsat), agent, '2026-10-15T09:00:00Z')),
    add(budget(laps, 2)),
    add(subject(l1, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(subject(m1, 'p', 'sha256:1111111111111111111111111111111111111111111111111111111111111111')),
    add(subject(m2, 'p', 'sha256:2222222222222222222222222222222222222222222222222222222222222222')),
    add(answer(q1, yes, agent)),
    add(subject(r21, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(cites(c3, 'x')),
    add(question(q1, c3, 'x')),
    add(encodes(m1, c3)),
    add(discovery_evidence(l1, system)),
    add(lap_done(1)),
    add(model_run(r20, m2, 'sha256:2222222222222222222222222222222222222222222222222222222222222222')),
    add(model_run(r10, m1, 'sha256:2222222222222222222222222222222222222222222222222222222222222222')),
    add(discovery_evidence(k1, system)),
    add(assumed(q1, yes)),
    add(model_run(r21, m2, 'sha256:2222222222222222222222222222222222222222222222222222222222222222')),
    add(subject(r10, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(model_run(r20, m2, 'sha256:1111111111111111111111111111111111111111111111111111111111111111')),
    add(model_run(r10, m1, 'sha256:1111111111111111111111111111111111111111111111111111111111111111')),
    add(model(m1, smt))]).
expect(s7x50, 'discovery_ready', none).
expect(s7x50, 'no_falsifier(C)', none).
expect(s7x50, 'model_trusted(M)', none).
expect(s7x50, 'lint_issue(Code, Id, _)', none).
expect(s7x50, 'model_unfiled_break(C)', none).
expect(s7x50, 'discovery_unratified(C)', none).
expect(s7x50, 'discovery_decide', none).
variant(s7x51, [
    add(subject(m1, 'p', 'sha256:1111111111111111111111111111111111111111111111111111111111111111')),
    add(claim(c1, preserve, 'x')),
    add(discovery_evidence(l2, system)),
    add(attest(a1, model_result, l2, calibration(m1, example(c1), differs), agent, '2026-10-15T09:00:00Z')),
    add(attest(a2, model_result, l2, calibration(m1, case('t'), matches), agent, '2026-10-15T09:00:00Z')),
    add(encodes(m1, c1)),
    add(cites(c1, 'x')),
    add(question(q1, c1, 'x')),
    add(model(m1, tla)),
    add(answer(q1, yes, human)),
    add(subject(l2, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(assumed(q1, yes))]).
expect(s7x51, 'discovery_ready', none).
expect(s7x51, 'no_falsifier(C)', none).
expect(s7x51, 'model_trusted(M)', none).
expect(s7x51, 'lint_issue(Code, Id, _)', none).
expect(s7x51, 'model_unfiled_break(C)', none).
expect(s7x51, 'discovery_unratified(C)', none).
expect(s7x51, 'discovery_decide', none).
variant(s7x52, [
    add(model_run(r10, m1, 'sha256:1111111111111111111111111111111111111111111111111111111111111111')),
    add(attest(a9, model_result, m1, mutation(m2, ra, killed), agent, '2026-10-15T09:00:00Z')),
    add(attest(a4, model_result, l2, verdict(m1, explore(w), holds), agent, '2026-10-15T09:00:00Z')),
    add(attest(a10, reproduction, l2, confirms(f2), agent, '2026-10-15T09:00:00Z')),
    add(finding(f2, trace(x), model)),
    add(attest(a8, model_result, m1, mutation(m2, rb, killed), agent, '2026-10-15T09:00:00Z')),
    add(budget(laps, 2)),
    add(lap_done(3)),
    add(lap_done(1)),
    add(model(m2, tla)),
    add(subject(l2, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(attest(a5, model_result, l2, verdict(m2, explore(w), sat), agent, '2026-10-15T09:00:00Z')),
    add(lap_done(2)),
    add(subject(r10, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(lap_done(4)),
    add(derived_from(m2, m1)),
    add(attest(a6, model_result, m2, verdict(m2, bad_case, violated), agent, '2026-10-15T09:00:00Z')),
    add(attest(a7, model_result, r10, calibration(m1, case('t'), differs), agent, '2026-10-15T09:00:00Z')),
    add(model_run(r10, m1, 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(attest(a1, model_result, m1, verdict(m1, root_cause(x), unsat), agent, '2026-10-15T09:00:00Z')),
    add(model(m1, smt)),
    add(attest(a3, model_result, r10, verdict(m1, bad_case, unsat), agent, '2026-10-15T09:00:00Z')),
    add(attest(a2, model_result, m2, verdict(m2, explore(w), unknown), agent, '2026-10-15T09:00:00Z')),
    add(subject(m1, 'p', 'sha256:1111111111111111111111111111111111111111111111111111111111111111'))]).
expect(s7x52, 'discovery_ready', none).
expect(s7x52, 'no_falsifier(C)', none).
expect(s7x52, 'model_trusted(M)', none).
expect(s7x52, 'lint_issue(Code, Id, _)', none).
expect(s7x52, 'model_unfiled_break(C)', none).
expect(s7x52, 'discovery_unratified(C)', none).
expect(s7x52, 'discovery_decide', none).
variant(s7x53, [
    add(check(k1, c3)),
    add(finding(f2, surprise(x), model)),
    add(discovery_evidence(k1, system)),
    add(assumed(q1, yes)),
    add(answer(q1, no, human)),
    add(lap_done(2)),
    add(lap_done(1)),
    add(question(q2, c3, 'x')),
    add(attest(a1, disproof, k1, verdict(c2, refuted), agent, '2026-10-15T09:00:00Z')),
    add(attest(a2, disproof, k1, verdict(c2, inconclusive), agent, '2026-10-15T09:00:00Z')),
    add(cites(c2, 'x')),
    add(lap_done(3)),
    add(lap_done(4)),
    add(claim(c3, retire, 'x')),
    add(claim(c2, retire, 'x')),
    add(budget(laps, 2)),
    add(question(q1, c3, 'x')),
    add(cites(c3, 'x')),
    add(assumed(q2, yes)),
    add(supersedes(c3, c2))]).
expect(s7x53, 'discovery_ready', none).
expect(s7x53, 'no_falsifier(C)', none).
expect(s7x53, 'model_trusted(M)', none).
expect(s7x53, 'lint_issue(Code, Id, _)', none).
expect(s7x53, 'model_unfiled_break(C)', none).
expect(s7x53, 'discovery_unratified(C)', none).
expect(s7x53, 'discovery_decide', none).
variant(s7x54, [
    add(subject(l2, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(attest(a1, reproduction, l1, result(h2, not_reproduced), agent, '2026-10-15T09:00:00Z')),
    add(finding(f1, surprise(x), model)),
    add(answer(q1, no, agent)),
    add(assumed(q2, yes)),
    add(claim(c3, retire, 'x')),
    add(cites(c1, 'x')),
    add(subject(l1, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(lap_done(2)),
    add(lap_done(1)),
    add(raised_by(q2, h1)),
    add(question(q1, c1, 'x')),
    add(finding(f2, surprise(x), model)),
    add(hypothesis(h2, feature, 'x')),
    add(hypothesis(h1, defect, 'x')),
    add(budget(laps, 2)),
    add(claim(c1, introduce, 'x')),
    add(attest(a2, reproduction, l1, result(h1, reproduced), agent, '2026-10-15T09:00:00Z')),
    add(answer(q2, yes, agent)),
    add(assumed(q1, yes)),
    add(question(q2, c1, 'x')),
    add(discovery_evidence(l2, system)),
    add(supersedes(c3, c1)),
    add(cites(c3, 'x'))]).
expect(s7x54, 'discovery_ready', none).
expect(s7x54, 'no_falsifier(C)', none).
expect(s7x54, 'model_trusted(M)', none).
expect(s7x54, 'lint_issue(Code, Id, _)', none).
expect(s7x54, 'model_unfiled_break(C)', none).
expect(s7x54, 'discovery_unratified(C)', none).
expect(s7x54, 'discovery_decide', none).
variant(s7x55, [
    add(model_run(r11, m1, 'sha256:2222222222222222222222222222222222222222222222222222222222222222')),
    add(claim(c3, preserve, 'x')),
    add(raised_by(q2, c3)),
    add(encodes(m1, c3)),
    add(model_run(r10, m1, 'sha256:1111111111111111111111111111111111111111111111111111111111111111')),
    add(model(m1, smt)),
    add(cites(c3, 'x')),
    add(subject(r11, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(attest(a4, model_result, m1, mutation(m1, ra, survived), agent, '2026-10-15T09:00:00Z')),
    add(subject(r10, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(supersedes(c3, c1)),
    add(subject(m1, 'p', 'sha256:1111111111111111111111111111111111111111111111111111111111111111')),
    add(cites(c1, 'x')),
    add(attest(a3, model_result, m1, calibration(m1, case('t'), matches), agent, '2026-10-15T09:00:00Z')),
    add(attest(a5, model_result, r11, mutation(m1, rb, killed), agent, '2026-10-15T09:00:00Z')),
    add(subject(l2, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(assumed(q2, yes)),
    add(attest(a1, model_result, l2, verdict(m1, bad_case, unsat), agent, '2026-10-15T09:00:00Z')),
    add(supersedes(c3, c1)),
    add(assumed(q1, yes)),
    add(claim(c1, introduce, 'x')),
    add(attest(a7, divergence, r10, verdict(c1, inconclusive), agent, '2026-10-15T09:00:00Z')),
    add(question(q2, c1, 'x')),
    add(discovery_evidence(l2, system)),
    add(question(q1, c1, 'x')),
    add(attest(a6, reproduction, r10, result(h1, reproduced), agent, '2026-10-15T09:00:00Z')),
    add(derived_from(m1, m1)),
    add(hypothesis(h1, feature, 'x')),
    add(hypothesis(h2, risk, 'x')),
    add(derived_from(m1, m1)),
    add(model_run(r11, m1, 'sha256:2222222222222222222222222222222222222222222222222222222222222222')),
    add(answer(q2, yes, agent)),
    add(attest(a2, model_result, r11, calibration(m1, case('t'), matches), agent, '2026-10-15T09:00:00Z'))]).
expect(s7x55, 'discovery_ready', none).
expect(s7x55, 'no_falsifier(C)', none).
expect(s7x55, 'model_trusted(M)', none).
expect(s7x55, 'lint_issue(Code, Id, _)', none).
expect(s7x55, 'model_unfiled_break(C)', none).
expect(s7x55, 'discovery_unratified(C)', none).
expect(s7x55, 'discovery_decide', none).
variant(s7x56, [
    add(attest(a2, model_result, m1, mutation(m1, rb, survived), agent, '2026-10-15T09:00:00Z')),
    add(claim(c2, retire, 'x')),
    add(finding(f1, trace(x), model)),
    add(attest(a6, disproof, l1, verdict(c3, abstained), agent, '2026-10-15T09:00:00Z')),
    add(question(q1, c2, 'x')),
    add(attest(a5, reproduction, l1, result(h1, reproduced), agent, '2026-10-15T09:00:00Z')),
    add(encodes(m1, c3)),
    add(discovery_evidence(l2, system)),
    add(cites(c3, 'x')),
    add(subject(m1, 'p', 'sha256:1111111111111111111111111111111111111111111111111111111111111111')),
    add(attest(a3, divergence, l2, model(m1), agent, '2026-10-15T09:00:00Z')),
    add(attest(a1, model_result, m1, calibration(m1, example(c3), differs), agent, '2026-10-15T09:00:00Z')),
    add(subject(l1, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(discovery_evidence(l1, system)),
    add(model(m1, tla)),
    add(subject(l2, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(cites(c2, 'x')),
    add(claim(c3, introduce, 'x')),
    add(attest(a4, reproduction, l2, confirms(f1), agent, '2026-10-15T09:00:00Z')),
    add(hypothesis(h1, feature, 'x')),
    add(assumed(q2, yes)),
    add(hypothesis(h2, risk, 'x')),
    add(derived_from(m1, m1)),
    add(question(q2, c3, 'x')),
    add(assumed(q1, yes)),
    add(raised_by(q1, h2)),
    add(encodes(m1, c2))]).
expect(s7x56, 'discovery_ready', none).
expect(s7x56, 'no_falsifier(C)', none).
expect(s7x56, 'model_trusted(M)', none).
expect(s7x56, 'lint_issue(Code, Id, _)', none).
expect(s7x56, 'model_unfiled_break(C)', none).
expect(s7x56, 'discovery_unratified(C)', none).
expect(s7x56, 'discovery_decide', none).
variant(s7x57, [
    add(cites(c3, 'x')),
    add(encodes(m2, c3)),
    add(model_run(r21, m2, 'sha256:2222222222222222222222222222222222222222222222222222222222222222')),
    add(attest(a7, divergence, r20, claim(c1), agent, '2026-10-15T09:00:00Z')),
    add(encodes(m2, c3)),
    add(claim(c3, retire, 'x')),
    add(encodes(m2, c1)),
    add(attest(a3, model_result, r20, verdict(m2, preserve(c1), unsat), agent, '2026-10-15T09:00:00Z')),
    add(subject(r21, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(cites(c1, 'x')),
    add(model(m2, tla)),
    add(answer(q1, no, human)),
    add(model_run(r20, m2, 'sha256:2222222222222222222222222222222222222222222222222222222222222222')),
    add(supersedes(c2, c3)),
    add(subject(m2, 'p', 'sha256:2222222222222222222222222222222222222222222222222222222222222222')),
    add(subject(r20, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(cites(c2, 'x')),
    add(question(q1, c2, 'x')),
    add(attest(a6, divergence, m2, verdict(c3, inconclusive), agent, '2026-10-15T09:00:00Z')),
    add(assumed(q1, yes)),
    add(attest(a4, model_result, m2, calibration(m2, case('t'), matches), agent, '2026-10-15T09:00:00Z')),
    add(raised_by(q1, c3)),
    add(attest(a1, model_result, m2, verdict(m2, sanity, holds), agent, '2026-10-15T09:00:00Z')),
    add(question(q2, c3, 'x')),
    add(attest(a5, model_result, r20, calibration(m2, example(c2), matches), agent, '2026-10-15T09:00:00Z')),
    add(attest(a2, model_result, m2, verdict(m2, sanity, unsat), agent, '2026-10-15T09:00:00Z')),
    add(assumed(q2, yes)),
    add(claim(c1, preserve, 'x')),
    add(claim(c2, preserve, 'x'))]).
expect(s7x57, 'discovery_ready', none).
expect(s7x57, 'no_falsifier(C)', none).
expect(s7x57, 'model_trusted(M)', none).
expect(s7x57, 'lint_issue(Code, Id, _)', none).
expect(s7x57, 'model_unfiled_break(C)', none).
expect(s7x57, 'discovery_unratified(C)', none).
expect(s7x57, 'discovery_decide', none).
variant(s7x58, [
    add(discovery_evidence(l2, system)),
    add(claim(c1, introduce, 'x')),
    add(claim(c3, preserve, 'x')),
    add(cites(c1, 'x')),
    add(cites(c2, 'x')),
    add(claim(c2, preserve, 'x')),
    add(subject(l2, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(supersedes(c1, c3)),
    add(supersedes(c1, c2)),
    add(check(k1, c3)),
    add(cites(c3, 'x')),
    add(discovery_evidence(k1, system))]).
expect(s7x58, 'discovery_ready', none).
expect(s7x58, 'no_falsifier(C)', none).
expect(s7x58, 'model_trusted(M)', none).
expect(s7x58, 'lint_issue(Code, Id, _)', none).
expect(s7x58, 'model_unfiled_break(C)', none).
expect(s7x58, 'discovery_unratified(C)', none).
expect(s7x58, 'discovery_decide', none).
variant(s7x59, [
    add(budget(laps, 2)),
    add(model_run(r20, m2, 'sha256:2222222222222222222222222222222222222222222222222222222222222222')),
    add(budget(laps, 3)),
    add(attest(a1, model_result, m1, verdict(m1, explore(w), reached), agent, '2026-10-15T09:00:00Z')),
    add(attest(a5, reproduction, m2, result(h1, reproduced), agent, '2026-10-15T09:00:00Z')),
    add(attest(a2, model_result, r20, calibration(m2, case('t'), matches), agent, '2026-10-15T09:00:00Z')),
    add(lap_done(3)),
    add(lap_done(4)),
    add(subject(m1, 'p', 'sha256:1111111111111111111111111111111111111111111111111111111111111111')),
    add(attest(a4, model_result, m2, mutation(m2, ra, survived), agent, '2026-10-15T09:00:00Z')),
    add(hypothesis(h1, feature, 'x')),
    add(subject(r20, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(lap_done(1)),
    add(model(m2, smt)),
    add(attest(a3, model_result, r20, mutation(m1, ra, survived), agent, '2026-10-15T09:00:00Z')),
    add(subject(m2, 'p', 'sha256:2222222222222222222222222222222222222222222222222222222222222222')),
    add(attest(a6, reproduction, m2, result(h2, reproduced), agent, '2026-10-15T09:00:00Z')),
    add(model(m1, smt)),
    add(lap_done(2)),
    add(hypothesis(h2, defect, 'x'))]).
expect(s7x59, 'discovery_ready', none).
expect(s7x59, 'no_falsifier(C)', none).
expect(s7x59, 'model_trusted(M)', none).
expect(s7x59, 'lint_issue(Code, Id, _)', none).
expect(s7x59, 'model_unfiled_break(C)', none).
expect(s7x59, 'discovery_unratified(C)', none).
expect(s7x59, 'discovery_decide', none).
variant(s7x60, [
    add(raised_by(q2, h1)),
    add(question(q1, c1, 'x')),
    add(attest(a1, reproduction, l1, result(h1, reproduced), agent, '2026-10-15T09:00:00Z')),
    add(answer(q2, yes, agent)),
    add(attest(a3, disproof, l1, verdict(c3, refuted), agent, '2026-10-15T09:00:00Z')),
    add(attest(a2, reproduction, l2, result(h2, reproduced), agent, '2026-10-15T09:00:00Z')),
    add(cites(c2, 'x')),
    add(discovery_evidence(l1, system)),
    add(cites(c1, 'x')),
    add(hypothesis(h2, defect, 'x')),
    add(finding(f1, conflict([x, y]), model)),
    add(assumed(q2, yes)),
    add(assumed(q1, yes)),
    add(claim(c3, introduce, 'x')),
    add(subject(l1, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(discovery_evidence(l2, model)),
    add(cites(c3, 'x')),
    add(answer(q1, no, human)),
    add(claim(c2, preserve, 'x')),
    add(hypothesis(h1, risk, 'x')),
    add(claim(c1, preserve, 'x')),
    add(question(q2, c1, 'x')),
    add(subject(l2, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333'))]).
expect(s7x60, 'discovery_ready', none).
expect(s7x60, 'no_falsifier(C)', none).
expect(s7x60, 'model_trusted(M)', none).
expect(s7x60, 'lint_issue(Code, Id, _)', none).
expect(s7x60, 'model_unfiled_break(C)', none).
expect(s7x60, 'discovery_unratified(C)', none).
expect(s7x60, 'discovery_decide', none).
variant(s7x61, [
    add(discovery_evidence(l2, system)),
    add(cites(c1, 'x')),
    add(claim(c2, retire, 'x')),
    add(discovery_evidence(k1, system)),
    add(attest(a2, divergence, k1, claim(c2), agent, '2026-10-15T09:00:00Z')),
    add(subject(l2, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(attest(a1, reproduction, l1, result(h1, reproduced), agent, '2026-10-15T09:00:00Z')),
    add(subject(l1, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(hypothesis(h1, risk, 'x')),
    add(claim(c1, preserve, 'x')),
    add(supersedes(c1, c2)),
    add(cites(c2, 'x')),
    add(check(k1, c2))]).
expect(s7x61, 'discovery_ready', none).
expect(s7x61, 'no_falsifier(C)', none).
expect(s7x61, 'model_trusted(M)', none).
expect(s7x61, 'lint_issue(Code, Id, _)', none).
expect(s7x61, 'model_unfiled_break(C)', none).
expect(s7x61, 'discovery_unratified(C)', none).
expect(s7x61, 'discovery_decide', none).
variant(s7x62, [
    add(attest(a1, reproduction, l2, confirms(f2), agent, '2026-10-15T09:00:00Z')),
    add(lap_done(2)),
    add(budget(laps, 2)),
    add(finding(f2, root_cause(x), model)),
    add(lap_done(1)),
    add(subject(l2, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(budget(laps, 3))]).
expect(s7x62, 'discovery_ready', none).
expect(s7x62, 'no_falsifier(C)', none).
expect(s7x62, 'model_trusted(M)', none).
expect(s7x62, 'lint_issue(Code, Id, _)', none).
expect(s7x62, 'model_unfiled_break(C)', none).
expect(s7x62, 'discovery_unratified(C)', none).
expect(s7x62, 'discovery_decide', none).
variant(s7x63, [
    add(attest(a3, model_result, r20, verdict(m1, root_cause(x), sat), agent, '2026-10-15T09:00:00Z')),
    add(derived_from(m2, m1)),
    add(budget(laps, 3)),
    add(encodes(m1, c1)),
    add(cites(c2, 'x')),
    add(lap_done(1)),
    add(attest(a2, model_result, l2, verdict(m2, applies(c3), holds), agent, '2026-10-15T09:00:00Z')),
    add(cites(c1, 'x')),
    add(subject(l2, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(supersedes(c1, c3)),
    add(attest(a7, reproduction, k1, result(h1, not_reproduced), agent, '2026-10-15T09:00:00Z')),
    add(claim(c3, preserve, 'x')),
    add(budget(laps, 4)),
    add(attest(a6, divergence, m1, model(m2), agent, '2026-10-15T09:00:00Z')),
    add(model(m2, smt)),
    add(lap_done(2)),
    add(model(m1, tla)),
    add(answer(q1, yes, agent)),
    add(derived_from(m1, m2)),
    add(attest(a5, model_result, l2, mutation(m2, rb, killed), agent, '2026-10-15T09:00:00Z')),
    add(subject(m2, 'p', 'sha256:2222222222222222222222222222222222222222222222222222222222222222')),
    add(attest(a4, model_result, l2, calibration(m1, example(c1), differs), agent, '2026-10-15T09:00:00Z')),
    add(cites(c3, 'x')),
    add(raised_by(q1, c3)),
    add(supersedes(c1, c2)),
    add(check(k1, c3)),
    add(claim(c2, preserve, 'x')),
    add(discovery_evidence(l2, system)),
    add(attest(a1, model_result, m2, verdict(m2, preserve(c1), unsat), agent, '2026-10-15T09:00:00Z')),
    add(assumed(q1, yes)),
    add(subject(m1, 'p', 'sha256:1111111111111111111111111111111111111111111111111111111111111111')),
    add(question(q1, c3, 'x')),
    add(attest(a8, divergence, k1, claim(c1), agent, '2026-10-15T09:00:00Z')),
    add(model_run(r20, m2, 'sha256:2222222222222222222222222222222222222222222222222222222222222222')),
    add(discovery_evidence(k1, system)),
    add(claim(c1, introduce, 'x')),
    add(subject(r20, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(hypothesis(h1, defect, 'x'))]).
expect(s7x63, 'discovery_ready', none).
expect(s7x63, 'no_falsifier(C)', none).
expect(s7x63, 'model_trusted(M)', none).
expect(s7x63, 'lint_issue(Code, Id, _)', none).
expect(s7x63, 'model_unfiled_break(C)', none).
expect(s7x63, 'discovery_unratified(C)', none).
expect(s7x63, 'discovery_decide', none).
variant(s7x64, [
    add(lap_done(1)),
    add(question(q2, c3, 'x')),
    add(subject(l1, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(attest(a7, model_result, l1, mutation(m1, rb, survived), agent, '2026-10-15T09:00:00Z')),
    add(encodes(m1, c3)),
    add(answer(q2, no, agent)),
    add(cites(c3, 'x')),
    add(attest(a1, model_result, m1, verdict(m1, root_cause(x), sat), agent, '2026-10-15T09:00:00Z')),
    add(model(m1, smt)),
    add(assumed(q2, yes)),
    add(attest(a6, model_result, m1, calibration(m1, example(c3), matches), agent, '2026-10-15T09:00:00Z')),
    add(question(q1, c3, 'x')),
    add(answer(q1, yes, agent)),
    add(assumed(q1, yes)),
    add(lap_done(3)),
    add(encodes(m1, c3)),
    add(attest(a2, model_result, m1, verdict(m1, sanity, unknown), agent, '2026-10-15T09:00:00Z')),
    add(subject(m1, 'p', 'sha256:1111111111111111111111111111111111111111111111111111111111111111')),
    add(attest(a4, model_result, l1, verdict(m1, explore(w), holds), agent, '2026-10-15T09:00:00Z')),
    add(attest(a5, model_result, l1, verdict(m1, applies(c3), sat), agent, '2026-10-15T09:00:00Z')),
    add(lap_done(2)),
    add(claim(c3, retire, 'x')),
    add(budget(laps, 2)),
    add(attest(a8, disproof, m1, claim(c3), agent, '2026-10-15T09:00:00Z')),
    add(derived_from(m1, m1)),
    add(attest(a3, model_result, l1, verdict(m1, bad_case, unknown), agent, '2026-10-15T09:00:00Z'))]).
expect(s7x64, 'discovery_ready', none).
expect(s7x64, 'no_falsifier(C)', none).
expect(s7x64, 'model_trusted(M)', none).
expect(s7x64, 'lint_issue(Code, Id, _)', none).
expect(s7x64, 'model_unfiled_break(C)', none).
expect(s7x64, 'discovery_unratified(C)', none).
expect(s7x64, 'discovery_decide', none).
variant(s7x65, [
    add(attest(a2, divergence, zz, verdict(c1, refuted), agent, '2026-10-15T09:00:00Z')),
    add(budget(laps, 1)),
    add(budget(laps, 2)),
    add(attest(a1, divergence, zz, claim(c1), agent, '2026-10-15T09:00:00Z')),
    add(lap_done(1)),
    add(hypothesis(h1, defect, 'x')),
    add(raised_by(q1, h1)),
    add(question(q1, c1, 'x')),
    add(finding(f2, conflict([x, y]), system)),
    add(hypothesis(h2, defect, 'x')),
    add(finding(f1, conflict([x, y]), model)),
    add(claim(c1, introduce, 'x')),
    add(assumed(q1, yes)),
    add(lap_done(2)),
    add(cites(c1, 'x'))]).
expect(s7x65, 'discovery_ready', none).
expect(s7x65, 'no_falsifier(C)', none).
expect(s7x65, 'model_trusted(M)', none).
expect(s7x65, 'lint_issue(Code, Id, _)', none).
expect(s7x65, 'model_unfiled_break(C)', none).
expect(s7x65, 'discovery_unratified(C)', none).
expect(s7x65, 'discovery_decide', none).
variant(s7x66, [
    add(claim(c3, retire, 'x')),
    add(cites(c3, 'x')),
    add(finding(f1, trace(x), system)),
    add(attest(a2, reproduction, k1, result(h1, not_reproduced), agent, '2026-10-15T09:00:00Z')),
    add(hypothesis(h1, feature, 'x')),
    add(check(k1, c3)),
    add(finding(f2, conflict([x, y]), model)),
    add(discovery_evidence(k1, system)),
    add(attest(a1, reproduction, k1, confirms(f2), agent, '2026-10-15T09:00:00Z'))]).
expect(s7x66, 'discovery_ready', none).
expect(s7x66, 'no_falsifier(C)', none).
expect(s7x66, 'model_trusted(M)', none).
expect(s7x66, 'lint_issue(Code, Id, _)', none).
expect(s7x66, 'model_unfiled_break(C)', none).
expect(s7x66, 'discovery_unratified(C)', none).
expect(s7x66, 'discovery_decide', none).
variant(s7x67, [
    add(attest(a1, model_result, l2, verdict(m1, root_cause(x), reached), agent, '2026-10-15T09:00:00Z')),
    add(discovery_evidence(l2, model)),
    add(subject(r10, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(lap_done(2)),
    add(budget(laps, 2)),
    add(lap_done(1)),
    add(model_run(r10, m1, 'sha256:2222222222222222222222222222222222222222222222222222222222222222')),
    add(lap_done(3)),
    add(subject(l2, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(model(m1, smt)),
    add(attest(a5, model_result, m1, verdict(m1, sanity, reached), agent, '2026-10-15T09:00:00Z')),
    add(model_run(r10, m1, 'sha256:1111111111111111111111111111111111111111111111111111111111111111')),
    add(discovery_evidence(l1, system)),
    add(subject(l1, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(attest(a2, model_result, l2, verdict(m1, explore(w), reached), agent, '2026-10-15T09:00:00Z')),
    add(attest(a3, model_result, r10, verdict(m1, sanity, reached), agent, '2026-10-15T09:00:00Z')),
    add(finding(f2, root_cause(x), system)),
    add(attest(a4, model_result, l1, verdict(m1, sanity, unsat), agent, '2026-10-15T09:00:00Z')),
    add(attest(a6, model_result, r10, verdict(m1, root_cause(x), unknown), agent, '2026-10-15T09:00:00Z'))]).
expect(s7x67, 'discovery_ready', none).
expect(s7x67, 'no_falsifier(C)', none).
expect(s7x67, 'model_trusted(M)', none).
expect(s7x67, 'lint_issue(Code, Id, _)', none).
expect(s7x67, 'model_unfiled_break(C)', none).
expect(s7x67, 'discovery_unratified(C)', none).
expect(s7x67, 'discovery_decide', none).
variant(s7x68, [
    add(model(m2, smt)),
    add(attest(a5, model_result, m1, mutation(m1, rb, killed), agent, '2026-10-15T09:00:00Z')),
    add(model_run(r11, m1, 'sha256:1111111111111111111111111111111111111111111111111111111111111111')),
    add(encodes(m2, c1)),
    add(subject(r11, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(attest(a2, model_result, r11, verdict(m1, applies(c3), sat), agent, '2026-10-15T09:00:00Z')),
    add(subject(r10, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(claim(c3, introduce, 'x')),
    add(attest(a1, model_result, m1, verdict(m2, preserve(c1), unsat), agent, '2026-10-15T09:00:00Z')),
    add(attest(a6, model_result, r10, mutation(m1, rb, killed), agent, '2026-10-15T09:00:00Z')),
    add(cites(c1, 'x')),
    add(claim(c1, retire, 'x')),
    add(attest(a3, model_result, m1, verdict(m1, sanity, unknown), agent, '2026-10-15T09:00:00Z')),
    add(attest(a9, reproduction, m1, result(h2, reproduced), agent, '2026-10-15T09:00:00Z')),
    add(discovery_evidence(k1, model)),
    add(model_run(r10, m1, 'sha256:1111111111111111111111111111111111111111111111111111111111111111')),
    add(model(m1, tla)),
    add(subject(m2, 'p', 'sha256:2222222222222222222222222222222222222222222222222222222222222222')),
    add(hypothesis(h2, risk, 'x')),
    add(subject(m1, 'p', 'sha256:1111111111111111111111111111111111111111111111111111111111111111')),
    add(supersedes(c3, c1)),
    add(check(k1, c3)),
    add(cites(c3, 'x')),
    add(finding(f1, surprise(x), system)),
    add(hypothesis(h1, feature, 'x')),
    add(attest(a7, divergence, r10, model(m1), agent, '2026-10-15T09:00:00Z')),
    add(derived_from(m1, m1)),
    add(attest(a8, reproduction, k1, result(h1, reproduced), agent, '2026-10-15T09:00:00Z')),
    add(encodes(m1, c3)),
    add(attest(a4, model_result, m2, verdict(m1, preserve(c3), reached), agent, '2026-10-15T09:00:00Z')),
    add(model_run(r10, m1, 'sha256:2222222222222222222222222222222222222222222222222222222222222222'))]).
expect(s7x68, 'discovery_ready', none).
expect(s7x68, 'no_falsifier(C)', none).
expect(s7x68, 'model_trusted(M)', none).
expect(s7x68, 'lint_issue(Code, Id, _)', none).
expect(s7x68, 'model_unfiled_break(C)', none).
expect(s7x68, 'discovery_unratified(C)', none).
expect(s7x68, 'discovery_decide', none).
variant(s7x69, [
    add(check(k1, c2)),
    add(claim(c1, introduce, 'x')),
    add(claim(c3, preserve, 'x')),
    add(claim(c2, introduce, 'x')),
    add(assumed(q1, yes)),
    add(supersedes(c3, c2)),
    add(cites(c3, 'x')),
    add(lap_done(3)),
    add(discovery_evidence(k1, system)),
    add(budget(laps, 3)),
    add(cites(c2, 'x')),
    add(lap_done(4)),
    add(cites(c1, 'x')),
    add(raised_by(q1, c1)),
    add(lap_done(2)),
    add(finding(f1, scope(x), model)),
    add(question(q1, c1, 'x')),
    add(attest(a1, reproduction, k1, confirms(f1), agent, '2026-10-15T09:00:00Z')),
    add(lap_done(1))]).
expect(s7x69, 'discovery_ready', none).
expect(s7x69, 'no_falsifier(C)', none).
expect(s7x69, 'model_trusted(M)', none).
expect(s7x69, 'lint_issue(Code, Id, _)', none).
expect(s7x69, 'model_unfiled_break(C)', none).
expect(s7x69, 'discovery_unratified(C)', none).
expect(s7x69, 'discovery_decide', none).
variant(s7x70, [
    add(discovery_evidence(k1, model)),
    add(attest(a3, disproof, l1, claim(c1), agent, '2026-10-15T09:00:00Z')),
    add(attest(a2, reproduction, l1, result(h2, reproduced), agent, '2026-10-15T09:00:00Z')),
    add(hypothesis(h2, risk, 'x')),
    add(cites(c1, 'x')),
    add(hypothesis(h1, risk, 'x')),
    add(assumed(q1, yes)),
    add(subject(l1, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(check(k1, c1)),
    add(claim(c1, retire, 'x')),
    add(question(q1, c1, 'x')),
    add(attest(a1, reproduction, k1, result(h1, reproduced), agent, '2026-10-15T09:00:00Z')),
    add(discovery_evidence(l1, system))]).
expect(s7x70, 'discovery_ready', none).
expect(s7x70, 'no_falsifier(C)', none).
expect(s7x70, 'model_trusted(M)', none).
expect(s7x70, 'lint_issue(Code, Id, _)', none).
expect(s7x70, 'model_unfiled_break(C)', none).
expect(s7x70, 'discovery_unratified(C)', none).
expect(s7x70, 'discovery_decide', none).
variant(s7x71, [
    add(lap_done(1)),
    add(claim(c1, preserve, 'x')),
    add(claim(c3, introduce, 'x')),
    add(hypothesis(h2, risk, 'x')),
    add(attest(a1, disproof, zz, verdict(c1, abstained), agent, '2026-10-15T09:00:00Z')),
    add(attest(a2, disproof, zz, verdict(c1, abstained), agent, '2026-10-15T09:00:00Z')),
    add(cites(c1, 'x')),
    add(hypothesis(h1, defect, 'x')),
    add(budget(laps, 1)),
    add(cites(c3, 'x'))]).
expect(s7x71, 'discovery_ready', none).
expect(s7x71, 'no_falsifier(C)', none).
expect(s7x71, 'model_trusted(M)', none).
expect(s7x71, 'lint_issue(Code, Id, _)', none).
expect(s7x71, 'model_unfiled_break(C)', none).
expect(s7x71, 'discovery_unratified(C)', none).
expect(s7x71, 'discovery_decide', none).
variant(s7x72, [
    add(answer(q1, no, agent)),
    add(derived_from(m1, m1)),
    add(derived_from(m1, m1)),
    add(attest(a5, model_result, m1, mutation(m1, rb, survived), agent, '2026-10-15T09:00:00Z')),
    add(attest(a4, model_result, m1, calibration(m1, example(c3), differs), agent, '2026-10-15T09:00:00Z')),
    add(subject(m1, 'p', 'sha256:1111111111111111111111111111111111111111111111111111111111111111')),
    add(discovery_evidence(k1, model)),
    add(attest(a8, reproduction, k1, result(h2, reproduced), agent, '2026-10-15T09:00:00Z')),
    add(finding(f2, trace(x), model)),
    add(claim(c3, introduce, 'x')),
    add(attest(a3, model_result, m1, verdict(m1, sanity, unsat), agent, '2026-10-15T09:00:00Z')),
    add(cites(c3, 'x')),
    add(assumed(q2, yes)),
    add(check(k1, c3)),
    add(attest(a6, reproduction, m1, confirms(f2), agent, '2026-10-15T09:00:00Z')),
    add(assumed(q1, yes)),
    add(hypothesis(h2, risk, 'x')),
    add(raised_by(q1, f2)),
    add(model(m1, smt)),
    add(question(q2, c3, 'x')),
    add(attest(a7, reproduction, m1, result(h1, reproduced), agent, '2026-10-15T09:00:00Z')),
    add(encodes(m1, c3)),
    add(attest(a2, model_result, m1, verdict(m1, explore(w), violated), agent, '2026-10-15T09:00:00Z')),
    add(budget(laps, 3)),
    add(attest(a1, model_result, m1, verdict(m1, sanity, unsat), agent, '2026-10-15T09:00:00Z')),
    add(attest(a9, divergence, k1, verdict(c3, inconclusive), agent, '2026-10-15T09:00:00Z')),
    add(hypothesis(h1, feature, 'x')),
    add(question(q1, c3, 'x'))]).
expect(s7x72, 'discovery_ready', none).
expect(s7x72, 'no_falsifier(C)', none).
expect(s7x72, 'model_trusted(M)', none).
expect(s7x72, 'lint_issue(Code, Id, _)', none).
expect(s7x72, 'model_unfiled_break(C)', none).
expect(s7x72, 'discovery_unratified(C)', none).
expect(s7x72, 'discovery_decide', none).
variant(s7x73, [
    add(raised_by(q2, h2)),
    add(claim(c2, retire, 'x')),
    add(subject(m1, 'p', 'sha256:1111111111111111111111111111111111111111111111111111111111111111')),
    add(assumed(q2, yes)),
    add(hypothesis(h1, feature, 'x')),
    add(question(q2, c3, 'x')),
    add(encodes(m1, c3)),
    add(attest(a7, model_result, r10, calibration(m1, example(c3), matches), agent, '2026-10-15T09:00:00Z')),
    add(lap_done(2)),
    add(attest(a1, model_result, r10, verdict(m1, explore(w), unsat), agent, '2026-10-15T09:00:00Z')),
    add(budget(laps, 3)),
    add(cites(c2, 'x')),
    add(subject(r10, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(attest(a11, disproof, m1, claim(c2), agent, '2026-10-15T09:00:00Z')),
    add(hypothesis(h2, feature, 'x')),
    add(model_run(r10, m1, 'sha256:1111111111111111111111111111111111111111111111111111111111111111')),
    add(attest(a6, model_result, r10, calibration(m1, case('t'), matches), agent, '2026-10-15T09:00:00Z')),
    add(attest(a5, model_result, m1, verdict(m1, preserve(c2), sat), agent, '2026-10-15T09:00:00Z')),
    add(assumed(q1, yes)),
    add(claim(c3, introduce, 'x')),
    add(attest(a10, divergence, m1, verdict(c2, inconclusive), agent, '2026-10-15T09:00:00Z')),
    add(derived_from(m1, m1)),
    add(attest(a9, reproduction, k1, result(h1, reproduced), agent, '2026-10-15T09:00:00Z')),
    add(discovery_evidence(k1, model)),
    add(attest(a2, model_result, r10, verdict(m1, preserve(c2), unknown), agent, '2026-10-15T09:00:00Z')),
    add(check(k1, c2)),
    add(attest(a3, model_result, r10, verdict(m1, bad_case, sat), agent, '2026-10-15T09:00:00Z')),
    add(attest(a4, model_result, r10, verdict(m1, root_cause(x), sat), agent, '2026-10-15T09:00:00Z')),
    add(lap_done(1)),
    add(lap_done(3)),
    add(raised_by(q1, h1)),
    add(model(m1, smt)),
    add(budget(laps, 4)),
    add(question(q1, c3, 'x')),
    add(attest(a8, reproduction, r10, result(h2, reproduced), agent, '2026-10-15T09:00:00Z')),
    add(cites(c3, 'x'))]).
expect(s7x73, 'discovery_ready', none).
expect(s7x73, 'no_falsifier(C)', none).
expect(s7x73, 'model_trusted(M)', none).
expect(s7x73, 'lint_issue(Code, Id, _)', none).
expect(s7x73, 'model_unfiled_break(C)', none).
expect(s7x73, 'discovery_unratified(C)', none).
expect(s7x73, 'discovery_decide', none).
variant(s7x74, [
    add(lap_done(4)),
    add(finding(f2, trace(x), system)),
    add(attest(a1, model_result, m1, verdict(m1, explore(w), violated), agent, '2026-10-15T09:00:00Z')),
    add(attest(a3, model_result, r10, verdict(m1, bad_case, sat), agent, '2026-10-15T09:00:00Z')),
    add(attest(a7, divergence, l1, model(m1), agent, '2026-10-15T09:00:00Z')),
    add(subject(m1, 'p', 'sha256:1111111111111111111111111111111111111111111111111111111111111111')),
    add(cites(c2, 'x')),
    add(claim(c2, preserve, 'x')),
    add(budget(laps, 2)),
    add(attest(a8, reproduction, l2, confirms(f1), agent, '2026-10-15T09:00:00Z')),
    add(attest(a2, model_result, r10, verdict(m1, explore(w), unsat), agent, '2026-10-15T09:00:00Z')),
    add(model(m1, tla)),
    add(lap_done(3)),
    add(attest(a4, model_result, m1, verdict(m1, preserve(c2), unknown), agent, '2026-10-15T09:00:00Z')),
    add(lap_done(2)),
    add(lap_done(1)),
    add(subject(r10, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(attest(a6, model_result, m1, mutation(m1, ra, killed), agent, '2026-10-15T09:00:00Z')),
    add(attest(a9, disproof, r10, verdict(c2, abstained), agent, '2026-10-15T09:00:00Z')),
    add(discovery_evidence(l2, model)),
    add(subject(l1, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(discovery_evidence(l1, model)),
    add(finding(f1, trace(x), system)),
    add(encodes(m1, c2)),
    add(model_run(r10, m1, 'sha256:1111111111111111111111111111111111111111111111111111111111111111')),
    add(budget(laps, 1)),
    add(subject(l2, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(attest(a10, divergence, l1, claim(c2), agent, '2026-10-15T09:00:00Z')),
    add(attest(a5, model_result, m1, mutation(m1, ra, killed), agent, '2026-10-15T09:00:00Z'))]).
expect(s7x74, 'discovery_ready', none).
expect(s7x74, 'no_falsifier(C)', none).
expect(s7x74, 'model_trusted(M)', none).
expect(s7x74, 'lint_issue(Code, Id, _)', none).
expect(s7x74, 'model_unfiled_break(C)', none).
expect(s7x74, 'discovery_unratified(C)', none).
expect(s7x74, 'discovery_decide', none).
variant(s7x75, [
    add(lap_done(1)),
    add(subject(m1, 'p', 'sha256:1111111111111111111111111111111111111111111111111111111111111111')),
    add(attest(a2, divergence, r10, model(m1), agent, '2026-10-15T09:00:00Z')),
    add(budget(laps, 3)),
    add(question(q1, c2, 'x')),
    add(model(m1, smt)),
    add(cites(c2, 'x')),
    add(derived_from(m1, m1)),
    add(model_run(r10, m1, 'sha256:1111111111111111111111111111111111111111111111111111111111111111')),
    add(claim(c2, introduce, 'x')),
    add(cites(c1, 'x')),
    add(subject(r10, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(encodes(m1, c1)),
    add(budget(laps, 4)),
    add(subject(r11, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(cites(c3, 'x')),
    add(encodes(m1, c1)),
    add(attest(a3, divergence, l2, verdict(c2, inconclusive), agent, '2026-10-15T09:00:00Z')),
    add(raised_by(q1, c2)),
    add(encodes(m1, c3)),
    add(subject(l2, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(claim(c1, retire, 'x')),
    add(model_run(r11, m1, 'sha256:2222222222222222222222222222222222222222222222222222222222222222')),
    add(claim(c3, retire, 'x')),
    add(attest(a1, model_result, m1, mutation(m1, rb, survived), agent, '2026-10-15T09:00:00Z')),
    add(lap_done(2)),
    add(subject(l1, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(assumed(q1, yes))]).
expect(s7x75, 'discovery_ready', none).
expect(s7x75, 'no_falsifier(C)', none).
expect(s7x75, 'model_trusted(M)', none).
expect(s7x75, 'lint_issue(Code, Id, _)', none).
expect(s7x75, 'model_unfiled_break(C)', none).
expect(s7x75, 'discovery_unratified(C)', none).
expect(s7x75, 'discovery_decide', none).
variant(s7x76, [
    add(model(m1, smt)),
    add(attest(a2, model_result, m1, calibration(m1, case('t'), matches), agent, '2026-10-15T09:00:00Z')),
    add(derived_from(m2, m2)),
    add(hypothesis(h1, risk, 'x')),
    add(lap_done(1)),
    add(subject(r20, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(model_run(r20, m2, 'sha256:2222222222222222222222222222222222222222222222222222222222222222')),
    add(subject(m2, 'p', 'sha256:2222222222222222222222222222222222222222222222222222222222222222')),
    add(attest(a4, reproduction, m1, result(h1, not_reproduced), agent, '2026-10-15T09:00:00Z')),
    add(attest(a3, model_result, r20, mutation(m1, ra, survived), agent, '2026-10-15T09:00:00Z')),
    add(attest(a1, model_result, m2, calibration(m1, case('t'), differs), agent, '2026-10-15T09:00:00Z')),
    add(subject(l2, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(budget(laps, 2)),
    add(budget(laps, 3)),
    add(subject(m1, 'p', 'sha256:1111111111111111111111111111111111111111111111111111111111111111')),
    add(model(m2, smt))]).
expect(s7x76, 'discovery_ready', none).
expect(s7x76, 'no_falsifier(C)', none).
expect(s7x76, 'model_trusted(M)', none).
expect(s7x76, 'lint_issue(Code, Id, _)', none).
expect(s7x76, 'model_unfiled_break(C)', none).
expect(s7x76, 'discovery_unratified(C)', none).
expect(s7x76, 'discovery_decide', none).
variant(s7x77, [
    add(model_run(r11, m1, 'sha256:1111111111111111111111111111111111111111111111111111111111111111')),
    add(reason(m1, rb, 't')),
    add(attest(a3, disproof, r10, claim(c3), agent, '2026-10-15T09:00:00Z')),
    add(lap_done(1)),
    add(attest(a4, divergence, m1, claim(c2), agent, '2026-10-15T09:00:00Z')),
    add(attest(a2, model_result, r10, mutation(m1, ra, killed), agent, '2026-10-15T09:00:00Z')),
    add(assumed(q1, yes)),
    add(attest(a1, model_result, r11, calibration(m1, case('t'), matches), agent, '2026-10-15T09:00:00Z')),
    add(model_run(r10, m1, 'sha256:1111111111111111111111111111111111111111111111111111111111111111')),
    add(cites(c3, 'x')),
    add(claim(c3, preserve, 'x')),
    add(subject(r11, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(budget(laps, 3)),
    add(cites(c2, 'x')),
    add(encodes(m1, c1)),
    add(subject(m1, 'p', 'sha256:1111111111111111111111111111111111111111111111111111111111111111')),
    add(cites(c1, 'x')),
    add(model_run(r11, m1, 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(budget(laps, 2)),
    add(claim(c2, preserve, 'x')),
    add(raised_by(q1, c3)),
    add(model(m1, smt)),
    add(claim(c1, retire, 'x')),
    add(encodes(m1, c2)),
    add(question(q1, c2, 'x')),
    add(subject(r10, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(encodes(m1, c2))]).
expect(s7x77, 'discovery_ready', none).
expect(s7x77, 'no_falsifier(C)', none).
expect(s7x77, 'model_trusted(M)', none).
expect(s7x77, 'lint_issue(Code, Id, _)', none).
expect(s7x77, 'model_unfiled_break(C)', none).
expect(s7x77, 'discovery_unratified(C)', none).
expect(s7x77, 'discovery_decide', none).
variant(s7x78, [
    add(finding(f2, surprise(x), model)),
    add(subject(l2, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(attest(a9, reproduction, l2, result(h1, not_reproduced), agent, '2026-10-15T09:00:00Z')),
    add(attest(a5, model_result, l1, verdict(m2, sanity, violated), agent, '2026-10-15T09:00:00Z')),
    add(claim(c3, preserve, 'x')),
    add(lap_done(2)),
    add(model_run(r20, m2, 'sha256:2222222222222222222222222222222222222222222222222222222222222222')),
    add(claim(c1, preserve, 'x')),
    add(attest(a7, model_result, l1, mutation(m2, rb, survived), agent, '2026-10-15T09:00:00Z')),
    add(derived_from(m2, m2)),
    add(cites(c2, 'x')),
    add(lap_done(3)),
    add(model(m1, tla)),
    add(cites(c1, 'x')),
    add(finding(f1, trace(x), system)),
    add(claim(c2, preserve, 'x')),
    add(encodes(m2, c3)),
    add(encodes(m2, c1)),
    add(lap_done(1)),
    add(model(m2, tla)),
    add(model_run(r20, m2, 'sha256:2222222222222222222222222222222222222222222222222222222222222222')),
    add(hypothesis(h1, feature, 'x')),
    add(attest(a1, model_result, l1, verdict(m1, bad_case, reached), agent, '2026-10-15T09:00:00Z')),
    add(subject(m2, 'p', 'sha256:2222222222222222222222222222222222222222222222222222222222222222')),
    add(budget(laps, 3)),
    add(discovery_evidence(l2, model)),
    add(cites(c3, 'x')),
    add(attest(a2, model_result, m2, verdict(m1, bad_case, holds), agent, '2026-10-15T09:00:00Z')),
    add(attest(a6, model_result, l2, mutation(m2, ra, killed), agent, '2026-10-15T09:00:00Z')),
    add(subject(r20, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(subject(l1, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(derived_from(m2, m2)),
    add(attest(a4, model_result, r20, verdict(m1, root_cause(x), unsat), agent, '2026-10-15T09:00:00Z')),
    add(attest(a10, divergence, m1, claim(c3), agent, '2026-10-15T09:00:00Z')),
    add(subject(m1, 'p', 'sha256:1111111111111111111111111111111111111111111111111111111111111111')),
    add(attest(a8, reproduction, l1, confirms(f2), agent, '2026-10-15T09:00:00Z')),
    add(budget(laps, 2)),
    add(attest(a3, model_result, m2, verdict(m2, sanity, unsat), agent, '2026-10-15T09:00:00Z'))]).
expect(s7x78, 'discovery_ready', none).
expect(s7x78, 'no_falsifier(C)', none).
expect(s7x78, 'model_trusted(M)', none).
expect(s7x78, 'lint_issue(Code, Id, _)', none).
expect(s7x78, 'model_unfiled_break(C)', none).
expect(s7x78, 'discovery_unratified(C)', none).
expect(s7x78, 'discovery_decide', none).
variant(s7x79, [
    add(encodes(m2, c3)),
    add(claim(c3, retire, 'x')),
    add(model_run(r20, m2, 'sha256:1111111111111111111111111111111111111111111111111111111111111111')),
    add(subject(m2, 'p', 'sha256:2222222222222222222222222222222222222222222222222222222222222222')),
    add(attest(a1, model_result, m2, calibration(m2, case('t'), matches), agent, '2026-10-15T09:00:00Z')),
    add(supersedes(c3, c2)),
    add(hypothesis(h2, feature, 'x')),
    add(attest(a3, reproduction, m2, result(h1, reproduced), agent, '2026-10-15T09:00:00Z')),
    add(attest(a4, reproduction, m2, result(h2, reproduced), agent, '2026-10-15T09:00:00Z')),
    add(cites(c3, 'x')),
    add(model_run(r20, m2, 'sha256:2222222222222222222222222222222222222222222222222222222222222222')),
    add(derived_from(m2, m2)),
    add(attest(a5, disproof, r20, verdict(c2, abstained), agent, '2026-10-15T09:00:00Z')),
    add(model(m2, smt)),
    add(claim(c2, preserve, 'x')),
    add(attest(a2, model_result, m2, calibration(m2, case('t'), matches), agent, '2026-10-15T09:00:00Z')),
    add(hypothesis(h1, defect, 'x')),
    add(cites(c2, 'x')),
    add(supersedes(c3, c2)),
    add(subject(r20, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333'))]).
expect(s7x79, 'discovery_ready', none).
expect(s7x79, 'no_falsifier(C)', none).
expect(s7x79, 'model_trusted(M)', none).
expect(s7x79, 'lint_issue(Code, Id, _)', none).
expect(s7x79, 'model_unfiled_break(C)', none).
expect(s7x79, 'discovery_unratified(C)', none).
expect(s7x79, 'discovery_decide', none).
variant(s7x80, [
    add(hypothesis(h1, feature, 'x')),
    add(budget(laps, 2)),
    add(hypothesis(h2, risk, 'x'))]).
expect(s7x80, 'discovery_ready', none).
expect(s7x80, 'no_falsifier(C)', none).
expect(s7x80, 'model_trusted(M)', none).
expect(s7x80, 'lint_issue(Code, Id, _)', none).
expect(s7x80, 'model_unfiled_break(C)', none).
expect(s7x80, 'discovery_unratified(C)', none).
expect(s7x80, 'discovery_decide', none).
variant(s7x81, [
    add(budget(laps, 2)),
    add(finding(f1, conflict([x, y]), model)),
    add(check(k1, c2)),
    add(hypothesis(h1, feature, 'x')),
    add(subject(r10, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(encodes(m1, c2)),
    add(attest(a3, reproduction, l1, result(h2, reproduced), agent, '2026-10-15T09:00:00Z')),
    add(subject(l1, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(model_run(r11, m1, 'sha256:1111111111111111111111111111111111111111111111111111111111111111')),
    add(claim(c1, retire, 'x')),
    add(assumed(q1, yes)),
    add(cites(c1, 'x')),
    add(derived_from(m1, m1)),
    add(encodes(m1, c2)),
    add(assumed(q2, yes)),
    add(subject(r11, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(question(q1, c1, 'x')),
    add(finding(f2, surprise(x), system)),
    add(discovery_evidence(l1, system)),
    add(question(q2, c1, 'x')),
    add(model(m1, smt)),
    add(claim(c2, introduce, 'x')),
    add(cites(c2, 'x')),
    add(subject(m1, 'p', 'sha256:1111111111111111111111111111111111111111111111111111111111111111')),
    add(budget(laps, 3)),
    add(model_run(r10, m1, 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(attest(a1, reproduction, l2, confirms(f1), agent, '2026-10-15T09:00:00Z')),
    add(raised_by(q2, f2)),
    add(discovery_evidence(k1, system)),
    add(hypothesis(h2, feature, 'x')),
    add(subject(l2, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(attest(a4, disproof, l2, verdict(c1, refuted), agent, '2026-10-15T09:00:00Z')),
    add(attest(a2, reproduction, m1, result(h1, reproduced), agent, '2026-10-15T09:00:00Z')),
    add(raised_by(q1, c1)),
    add(lap_done(1))]).
expect(s7x81, 'discovery_ready', none).
expect(s7x81, 'no_falsifier(C)', none).
expect(s7x81, 'model_trusted(M)', none).
expect(s7x81, 'lint_issue(Code, Id, _)', none).
expect(s7x81, 'model_unfiled_break(C)', none).
expect(s7x81, 'discovery_unratified(C)', none).
expect(s7x81, 'discovery_decide', none).
variant(s7x82, [
    add(attest(a2, reproduction, k1, confirms(f2), agent, '2026-10-15T09:00:00Z')),
    add(attest(a4, reproduction, k1, result(h2, reproduced), agent, '2026-10-15T09:00:00Z')),
    add(finding(f1, scope(x), model)),
    add(subject(l2, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(claim(c1, retire, 'x')),
    add(subject(l1, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(check(k1, c2)),
    add(claim(c2, introduce, 'x')),
    add(supersedes(c2, c1)),
    add(attest(a1, reproduction, l1, confirms(f1), agent, '2026-10-15T09:00:00Z')),
    add(discovery_evidence(k1, model)),
    add(attest(a6, divergence, l1, claim(c1), agent, '2026-10-15T09:00:00Z')),
    add(attest(a5, divergence, l1, verdict(c1, abstained), agent, '2026-10-15T09:00:00Z')),
    add(discovery_evidence(l1, model)),
    add(finding(f2, scope(x), model)),
    add(attest(a3, reproduction, k1, result(h1, reproduced), agent, '2026-10-15T09:00:00Z')),
    add(hypothesis(h1, risk, 'x')),
    add(hypothesis(h2, feature, 'x')),
    add(supersedes(c1, c2)),
    add(cites(c2, 'x')),
    add(cites(c1, 'x'))]).
expect(s7x82, 'discovery_ready', none).
expect(s7x82, 'no_falsifier(C)', none).
expect(s7x82, 'model_trusted(M)', none).
expect(s7x82, 'lint_issue(Code, Id, _)', none).
expect(s7x82, 'model_unfiled_break(C)', none).
expect(s7x82, 'discovery_unratified(C)', none).
expect(s7x82, 'discovery_decide', none).
variant(s7x83, [
    add(claim(c2, retire, 'x')),
    add(claim(c3, introduce, 'x')),
    add(attest(a1, disproof, l2, claim(c3), agent, '2026-10-15T09:00:00Z')),
    add(cites(c3, 'x')),
    add(attest(a2, disproof, l2, verdict(c2, inconclusive), agent, '2026-10-15T09:00:00Z')),
    add(discovery_evidence(l2, model)),
    add(subject(l2, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(claim(c1, introduce, 'x')),
    add(cites(c1, 'x')),
    add(supersedes(c1, c3)),
    add(cites(c2, 'x'))]).
expect(s7x83, 'discovery_ready', none).
expect(s7x83, 'no_falsifier(C)', none).
expect(s7x83, 'model_trusted(M)', none).
expect(s7x83, 'lint_issue(Code, Id, _)', none).
expect(s7x83, 'model_unfiled_break(C)', none).
expect(s7x83, 'discovery_unratified(C)', none).
expect(s7x83, 'discovery_decide', none).
variant(s7x84, [
    add(budget(laps, 3)),
    add(attest(a4, model_result, m2, verdict(m2, preserve(c1), unsat), agent, '2026-10-15T09:00:00Z')),
    add(subject(m2, 'p', 'sha256:2222222222222222222222222222222222222222222222222222222222222222')),
    add(encodes(m2, c1)),
    add(derived_from(m2, m2)),
    add(assumed(q1, yes)),
    add(encodes(m2, c3)),
    add(attest(a8, divergence, m2, model(m2), agent, '2026-10-15T09:00:00Z')),
    add(model(m2, tla)),
    add(attest(a3, model_result, m2, verdict(m2, bad_case, violated), agent, '2026-10-15T09:00:00Z')),
    add(cites(c2, 'x')),
    add(attest(a9, divergence, m2, claim(c3), agent, '2026-10-15T09:00:00Z')),
    add(attest(a1, model_result, m2, verdict(m2, applies(c3), sat), agent, '2026-10-15T09:00:00Z')),
    add(claim(c1, preserve, 'x')),
    add(claim(c3, introduce, 'x')),
    add(cites(c3, 'x')),
    add(attest(a2, model_result, m2, verdict(m2, preserve(c2), violated), agent, '2026-10-15T09:00:00Z')),
    add(attest(a6, model_result, m2, verdict(m2, applies(c2), unsat), agent, '2026-10-15T09:00:00Z')),
    add(reason(m2, rb, 't')),
    add(attest(a7, model_result, m2, mutation(m2, rb, killed), agent, '2026-10-15T09:00:00Z')),
    add(hypothesis(h2, risk, 'x')),
    add(claim(c2, introduce, 'x')),
    add(question(q1, c1, 'x')),
    add(discovery_evidence(k1, system)),
    add(check(k1, c1)),
    add(cites(c1, 'x')),
    add(attest(a5, model_result, m2, verdict(m2, explore(w), unsat), agent, '2026-10-15T09:00:00Z')),
    add(answer(q1, no, human))]).
expect(s7x84, 'discovery_ready', none).
expect(s7x84, 'no_falsifier(C)', none).
expect(s7x84, 'model_trusted(M)', none).
expect(s7x84, 'lint_issue(Code, Id, _)', none).
expect(s7x84, 'model_unfiled_break(C)', none).
expect(s7x84, 'discovery_unratified(C)', none).
expect(s7x84, 'discovery_decide', none).
variant(s7x85, [
    add(hypothesis(h2, feature, 'x')),
    add(subject(r20, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(discovery_evidence(k1, system)),
    add(model_run(r20, m2, 'sha256:2222222222222222222222222222222222222222222222222222222222222222')),
    add(derived_from(m1, m2)),
    add(model(m1, smt)),
    add(attest(a3, model_result, r20, mutation(m1, rb, killed), agent, '2026-10-15T09:00:00Z')),
    add(check(k1, c2)),
    add(derived_from(m2, m2)),
    add(attest(a2, model_result, m1, calibration(m2, case('t'), matches), agent, '2026-10-15T09:00:00Z')),
    add(claim(c3, preserve, 'x')),
    add(claim(c1, retire, 'x')),
    add(attest(a4, reproduction, m1, result(h2, not_reproduced), agent, '2026-10-15T09:00:00Z')),
    add(subject(m2, 'p', 'sha256:2222222222222222222222222222222222222222222222222222222222222222')),
    add(model(m2, tla)),
    add(claim(c2, preserve, 'x')),
    add(cites(c2, 'x')),
    add(cites(c1, 'x')),
    add(attest(a1, model_result, r20, calibration(m2, example(c2), matches), agent, '2026-10-15T09:00:00Z')),
    add(reason(m1, ra, 't')),
    add(attest(a5, reproduction, m1, result(h1, reproduced), agent, '2026-10-15T09:00:00Z')),
    add(cites(c3, 'x')),
    add(hypothesis(h1, feature, 'x'))]).
expect(s7x85, 'discovery_ready', none).
expect(s7x85, 'no_falsifier(C)', none).
expect(s7x85, 'model_trusted(M)', none).
expect(s7x85, 'lint_issue(Code, Id, _)', none).
expect(s7x85, 'model_unfiled_break(C)', none).
expect(s7x85, 'discovery_unratified(C)', none).
expect(s7x85, 'discovery_decide', none).
variant(s7x86, [
    add(encodes(m1, c3)),
    add(attest(a1, model_result, m1, mutation(m2, rb, killed), agent, '2026-10-15T09:00:00Z')),
    add(attest(a2, model_result, r20, mutation(m1, rb, survived), agent, '2026-10-15T09:00:00Z')),
    add(attest(a4, reproduction, l2, result(h2, not_reproduced), agent, '2026-10-15T09:00:00Z')),
    add(claim(c3, preserve, 'x')),
    add(attest(a3, reproduction, r20, confirms(f2), agent, '2026-10-15T09:00:00Z')),
    add(hypothesis(h2, risk, 'x')),
    add(supersedes(c2, c3)),
    add(encodes(m1, c2)),
    add(model(m1, smt)),
    add(subject(l2, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(subject(m2, 'p', 'sha256:2222222222222222222222222222222222222222222222222222222222222222')),
    add(finding(f2, conflict([x, y]), system)),
    add(claim(c2, retire, 'x')),
    add(model_run(r20, m2, 'sha256:2222222222222222222222222222222222222222222222222222222222222222')),
    add(lap_done(1)),
    add(budget(laps, 3)),
    add(cites(c3, 'x')),
    add(cites(c2, 'x')),
    add(subject(m1, 'p', 'sha256:1111111111111111111111111111111111111111111111111111111111111111')),
    add(discovery_evidence(l2, model)),
    add(encodes(m1, c3)),
    add(subject(l1, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(subject(r20, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(model(m2, tla)),
    add(discovery_evidence(l1, system))]).
expect(s7x86, 'discovery_ready', none).
expect(s7x86, 'no_falsifier(C)', none).
expect(s7x86, 'model_trusted(M)', none).
expect(s7x86, 'lint_issue(Code, Id, _)', none).
expect(s7x86, 'model_unfiled_break(C)', none).
expect(s7x86, 'discovery_unratified(C)', none).
expect(s7x86, 'discovery_decide', none).
variant(s7x87, [
    add(hypothesis(h2, feature, 'x')),
    add(subject(r10, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(attest(a3, model_result, l1, verdict(m1, explore(w), unsat), agent, '2026-10-15T09:00:00Z')),
    add(derived_from(m1, m1)),
    add(attest(a4, model_result, m1, calibration(m1, case('t'), differs), agent, '2026-10-15T09:00:00Z')),
    add(attest(a7, reproduction, l2, confirms(f1), agent, '2026-10-15T09:00:00Z')),
    add(model(m1, tla)),
    add(discovery_evidence(l1, system)),
    add(subject(m1, 'p', 'sha256:1111111111111111111111111111111111111111111111111111111111111111')),
    add(attest(a6, model_result, m1, mutation(m1, ra, killed), agent, '2026-10-15T09:00:00Z')),
    add(model_run(r10, m1, 'sha256:1111111111111111111111111111111111111111111111111111111111111111')),
    add(finding(f2, surprise(x), system)),
    add(attest(a2, model_result, r10, verdict(m1, bad_case, unsat), agent, '2026-10-15T09:00:00Z')),
    add(attest(a1, model_result, l1, verdict(m1, sanity, unsat), agent, '2026-10-15T09:00:00Z')),
    add(subject(l1, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(discovery_evidence(l2, model)),
    add(subject(l2, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(attest(a5, model_result, r10, mutation(m1, ra, killed), agent, '2026-10-15T09:00:00Z')),
    add(finding(f1, trace(x), system))]).
expect(s7x87, 'discovery_ready', none).
expect(s7x87, 'no_falsifier(C)', none).
expect(s7x87, 'model_trusted(M)', none).
expect(s7x87, 'lint_issue(Code, Id, _)', none).
expect(s7x87, 'model_unfiled_break(C)', none).
expect(s7x87, 'discovery_unratified(C)', none).
expect(s7x87, 'discovery_decide', none).
variant(s7x88, [
    add(claim(c3, introduce, 'x')),
    add(hypothesis(h1, feature, 'x')),
    add(subject(l1, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(cites(c3, 'x')),
    add(lap_done(1)),
    add(attest(a4, reproduction, l1, result(h1, reproduced), agent, '2026-10-15T09:00:00Z')),
    add(finding(f2, scope(x), model)),
    add(subject(m2, 'p', 'sha256:2222222222222222222222222222222222222222222222222222222222222222')),
    add(encodes(m2, c3)),
    add(assumed(q2, yes)),
    add(check(k1, c3)),
    add(lap_done(2)),
    add(budget(laps, 2)),
    add(attest(a6, divergence, k1, verdict(c3, refuted), agent, '2026-10-15T09:00:00Z')),
    add(derived_from(m2, m2)),
    add(discovery_evidence(l1, system)),
    add(attest(a7, disproof, m2, claim(c3), agent, '2026-10-15T09:00:00Z')),
    add(hypothesis(h2, defect, 'x')),
    add(discovery_evidence(k1, model)),
    add(model(m2, smt)),
    add(attest(a5, reproduction, l1, result(h2, reproduced), agent, '2026-10-15T09:00:00Z')),
    add(assumed(q1, yes)),
    add(raised_by(q1, h1)),
    add(raised_by(q2, h2)),
    add(attest(a2, divergence, m2, model(m2), agent, '2026-10-15T09:00:00Z')),
    add(attest(a3, reproduction, m2, confirms(f2), agent, '2026-10-15T09:00:00Z')),
    add(question(q2, c3, 'x')),
    add(attest(a1, model_result, l2, calibration(m2, case('t'), matches), agent, '2026-10-15T09:00:00Z')),
    add(subject(l2, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(question(q1, c3, 'x'))]).
expect(s7x88, 'discovery_ready', none).
expect(s7x88, 'no_falsifier(C)', none).
expect(s7x88, 'model_trusted(M)', none).
expect(s7x88, 'lint_issue(Code, Id, _)', none).
expect(s7x88, 'model_unfiled_break(C)', none).
expect(s7x88, 'discovery_unratified(C)', none).
expect(s7x88, 'discovery_decide', none).
variant(s7x89, [
    add(cites(c2, 'x')),
    add(subject(m1, 'p', 'sha256:1111111111111111111111111111111111111111111111111111111111111111')),
    add(subject(r11, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(attest(a4, disproof, m1, verdict(c1, inconclusive), agent, '2026-10-15T09:00:00Z')),
    add(model_run(r10, m1, 'sha256:1111111111111111111111111111111111111111111111111111111111111111')),
    add(claim(c3, retire, 'x')),
    add(cites(c1, 'x')),
    add(discovery_evidence(l2, system)),
    add(attest(a1, model_result, r10, verdict(m1, root_cause(x), unsat), agent, '2026-10-15T09:00:00Z')),
    add(claim(c2, preserve, 'x')),
    add(lap_done(3)),
    add(subject(r10, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(subject(l2, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(lap_done(2)),
    add(budget(laps, 2)),
    add(model(m1, smt)),
    add(attest(a2, model_result, l2, verdict(m1, sanity, sat), agent, '2026-10-15T09:00:00Z')),
    add(cites(c3, 'x')),
    add(claim(c1, preserve, 'x')),
    add(lap_done(1)),
    add(attest(a3, model_result, m1, mutation(m1, rb, killed), agent, '2026-10-15T09:00:00Z')),
    add(model_run(r11, m1, 'sha256:1111111111111111111111111111111111111111111111111111111111111111'))]).
expect(s7x89, 'discovery_ready', none).
expect(s7x89, 'no_falsifier(C)', none).
expect(s7x89, 'model_trusted(M)', none).
expect(s7x89, 'lint_issue(Code, Id, _)', none).
expect(s7x89, 'model_unfiled_break(C)', none).
expect(s7x89, 'discovery_unratified(C)', none).
expect(s7x89, 'discovery_decide', none).
variant(s7x90, [
    add(model_run(r21, m2, 'sha256:2222222222222222222222222222222222222222222222222222222222222222')),
    add(encodes(m2, c1)),
    add(attest(a3, model_result, r21, calibration(m1, example(c3), matches), agent, '2026-10-15T09:00:00Z')),
    add(attest(a2, model_result, l1, verdict(m1, applies(c1), unknown), agent, '2026-10-15T09:00:00Z')),
    add(attest(a1, model_result, r21, verdict(m2, bad_case, unknown), agent, '2026-10-15T09:00:00Z')),
    add(attest(a5, model_result, r20, mutation(m1, rb, killed), agent, '2026-10-15T09:00:00Z')),
    add(subject(m2, 'p', 'sha256:2222222222222222222222222222222222222222222222222222222222222222')),
    add(subject(r21, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(attest(a6, reproduction, r20, result(h1, reproduced), agent, '2026-10-15T09:00:00Z')),
    add(claim(c1, retire, 'x')),
    add(model(m1, tla)),
    add(hypothesis(h1, feature, 'x')),
    add(model_run(r20, m2, 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(subject(m1, 'p', 'sha256:1111111111111111111111111111111111111111111111111111111111111111')),
    add(subject(r20, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(derived_from(m1, m1)),
    add(attest(a7, reproduction, r21, result(h2, reproduced), agent, '2026-10-15T09:00:00Z')),
    add(discovery_evidence(l2, system)),
    add(model_run(r20, m2, 'sha256:2222222222222222222222222222222222222222222222222222222222222222')),
    add(model(m2, smt)),
    add(supersedes(c3, c1)),
    add(cites(c1, 'x')),
    add(subject(l1, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(cites(c3, 'x')),
    add(claim(c3, retire, 'x')),
    add(hypothesis(h2, risk, 'x')),
    add(subject(l2, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(attest(a4, model_result, m2, mutation(m1, rb, survived), agent, '2026-10-15T09:00:00Z')),
    add(supersedes(c3, c1))]).
expect(s7x90, 'discovery_ready', none).
expect(s7x90, 'no_falsifier(C)', none).
expect(s7x90, 'model_trusted(M)', none).
expect(s7x90, 'lint_issue(Code, Id, _)', none).
expect(s7x90, 'model_unfiled_break(C)', none).
expect(s7x90, 'discovery_unratified(C)', none).
expect(s7x90, 'discovery_decide', none).
variant(s7x91, [
    add(subject(r10, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(lap_done(2)),
    add(hypothesis(h1, feature, 'x')),
    add(check(k1, c1)),
    add(budget(laps, 3)),
    add(model_run(r10, m1, 'sha256:1111111111111111111111111111111111111111111111111111111111111111')),
    add(attest(a3, divergence, m1, model(m1), agent, '2026-10-15T09:00:00Z')),
    add(lap_done(1)),
    add(cites(c1, 'x')),
    add(model_run(r10, m1, 'sha256:1111111111111111111111111111111111111111111111111111111111111111')),
    add(attest(a4, reproduction, k1, confirms(f2), agent, '2026-10-15T09:00:00Z')),
    add(discovery_evidence(l1, model)),
    add(attest(a6, reproduction, m1, result(h1, reproduced), agent, '2026-10-15T09:00:00Z')),
    add(claim(c1, introduce, 'x')),
    add(attest(a7, divergence, k1, claim(c1), agent, '2026-10-15T09:00:00Z')),
    add(attest(a2, model_result, m1, calibration(m1, example(c1), matches), agent, '2026-10-15T09:00:00Z')),
    add(attest(a5, reproduction, r10, confirms(f1), agent, '2026-10-15T09:00:00Z')),
    add(subject(l1, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(finding(f1, conflict([x, y]), system)),
    add(subject(m1, 'p', 'sha256:1111111111111111111111111111111111111111111111111111111111111111')),
    add(discovery_evidence(k1, system)),
    add(attest(a1, model_result, r10, calibration(m1, example(c1), differs), agent, '2026-10-15T09:00:00Z')),
    add(lap_done(3)),
    add(finding(f2, scope(x), system)),
    add(model(m1, smt))]).
expect(s7x91, 'discovery_ready', none).
expect(s7x91, 'no_falsifier(C)', none).
expect(s7x91, 'model_trusted(M)', none).
expect(s7x91, 'lint_issue(Code, Id, _)', none).
expect(s7x91, 'model_unfiled_break(C)', none).
expect(s7x91, 'discovery_unratified(C)', none).
expect(s7x91, 'discovery_decide', none).
variant(s7x92, [
    add(attest(a8, model_result, m2, mutation(m2, ra, killed), agent, '2026-10-15T09:00:00Z')),
    add(attest(a1, model_result, r20, verdict(m2, preserve(c3), unsat), agent, '2026-10-15T09:00:00Z')),
    add(attest(a7, model_result, l1, calibration(m2, example(c3), matches), agent, '2026-10-15T09:00:00Z')),
    add(attest(a6, model_result, r20, calibration(m2, example(c2), matches), agent, '2026-10-15T09:00:00Z')),
    add(attest(a2, model_result, l1, verdict(m2, applies(c2), violated), agent, '2026-10-15T09:00:00Z')),
    add(attest(a5, model_result, m2, verdict(m2, preserve(c3), reached), agent, '2026-10-15T09:00:00Z')),
    add(discovery_evidence(l1, model)),
    add(claim(c2, retire, 'x')),
    add(cites(c2, 'x')),
    add(cites(c3, 'x')),
    add(subject(l1, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(subject(r20, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(supersedes(c2, c3)),
    add(subject(m2, 'p', 'sha256:2222222222222222222222222222222222222222222222222222222222222222')),
    add(attest(a3, model_result, l1, verdict(m2, sanity, unsat), agent, '2026-10-15T09:00:00Z')),
    add(reason(m2, ra, 't')),
    add(model_run(r20, m2, 'sha256:2222222222222222222222222222222222222222222222222222222222222222')),
    add(model(m2, smt)),
    add(attest(a4, model_result, r20, verdict(m2, applies(c3), sat), agent, '2026-10-15T09:00:00Z')),
    add(supersedes(c3, c2)),
    add(derived_from(m2, m2)),
    add(claim(c3, retire, 'x')),
    add(attest(a9, disproof, l1, claim(c3), agent, '2026-10-15T09:00:00Z'))]).
expect(s7x92, 'discovery_ready', none).
expect(s7x92, 'no_falsifier(C)', none).
expect(s7x92, 'model_trusted(M)', none).
expect(s7x92, 'lint_issue(Code, Id, _)', none).
expect(s7x92, 'model_unfiled_break(C)', none).
expect(s7x92, 'discovery_unratified(C)', none).
expect(s7x92, 'discovery_decide', none).
variant(s7x93, [
    add(question(q1, c3, 'x')),
    add(subject(r20, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(model(m1, smt)),
    add(attest(a2, model_result, m1, verdict(m1, preserve(c3), sat), agent, '2026-10-15T09:00:00Z')),
    add(attest(a5, disproof, r20, claim(c3), agent, '2026-10-15T09:00:00Z')),
    add(model(m2, smt)),
    add(assumed(q1, yes)),
    add(encodes(m1, c3)),
    add(question(q2, c2, 'x')),
    add(claim(c3, retire, 'x')),
    add(attest(a4, model_result, r21, mutation(m1, ra, survived), agent, '2026-10-15T09:00:00Z')),
    add(encodes(m1, c3)),
    add(cites(c2, 'x')),
    add(encodes(m2, c2)),
    add(attest(a3, model_result, r20, mutation(m1, rb, survived), agent, '2026-10-15T09:00:00Z')),
    add(subject(m1, 'p', 'sha256:1111111111111111111111111111111111111111111111111111111111111111')),
    add(discovery_evidence(l2, system)),
    add(subject(l2, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(attest(a1, model_result, r21, verdict(m1, applies(c3), holds), agent, '2026-10-15T09:00:00Z')),
    add(raised_by(q2, c3)),
    add(subject(r21, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(assumed(q2, yes)),
    add(cites(c3, 'x')),
    add(claim(c2, preserve, 'x')),
    add(model_run(r20, m2, 'sha256:1111111111111111111111111111111111111111111111111111111111111111')),
    add(model_run(r21, m2, 'sha256:2222222222222222222222222222222222222222222222222222222222222222')),
    add(model_run(r20, m2, 'sha256:2222222222222222222222222222222222222222222222222222222222222222')),
    add(subject(m2, 'p', 'sha256:2222222222222222222222222222222222222222222222222222222222222222'))]).
expect(s7x93, 'discovery_ready', none).
expect(s7x93, 'no_falsifier(C)', none).
expect(s7x93, 'model_trusted(M)', none).
expect(s7x93, 'lint_issue(Code, Id, _)', none).
expect(s7x93, 'model_unfiled_break(C)', none).
expect(s7x93, 'discovery_unratified(C)', none).
expect(s7x93, 'discovery_decide', none).
variant(s7x94, [
    add(question(q1, c3, 'x')),
    add(hypothesis(h2, defect, 'x')),
    add(subject(l2, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(finding(f1, trace(x), system)),
    add(claim(c2, introduce, 'x')),
    add(discovery_evidence(l1, system)),
    add(cites(c3, 'x')),
    add(assumed(q1, yes)),
    add(budget(laps, 1)),
    add(raised_by(q1, h2)),
    add(finding(f2, root_cause(x), model)),
    add(cites(c2, 'x')),
    add(claim(c3, retire, 'x')),
    add(discovery_evidence(l2, system)),
    add(supersedes(c2, c3)),
    add(attest(a4, disproof, k1, verdict(c3, inconclusive), agent, '2026-10-15T09:00:00Z')),
    add(subject(l1, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(attest(a1, reproduction, l1, confirms(f2), agent, '2026-10-15T09:00:00Z')),
    add(attest(a3, reproduction, k1, result(h2, reproduced), agent, '2026-10-15T09:00:00Z')),
    add(supersedes(c3, c2)),
    add(discovery_evidence(k1, system)),
    add(attest(a2, reproduction, l1, confirms(f1), agent, '2026-10-15T09:00:00Z')),
    add(check(k1, c3))]).
expect(s7x94, 'discovery_ready', none).
expect(s7x94, 'no_falsifier(C)', none).
expect(s7x94, 'model_trusted(M)', none).
expect(s7x94, 'lint_issue(Code, Id, _)', none).
expect(s7x94, 'model_unfiled_break(C)', none).
expect(s7x94, 'discovery_unratified(C)', none).
expect(s7x94, 'discovery_decide', none).
variant(s7x95, [
    add(attest(a11, divergence, m1, claim(c1), agent, '2026-10-15T09:00:00Z')),
    add(lap_done(4)),
    add(supersedes(c1, c2)),
    add(attest(a6, model_result, l2, calibration(m1, case('t'), matches), agent, '2026-10-15T09:00:00Z')),
    add(lap_done(3)),
    add(attest(a7, model_result, m1, calibration(m1, example(c2), differs), agent, '2026-10-15T09:00:00Z')),
    add(discovery_evidence(l2, system)),
    add(attest(a3, model_result, m1, verdict(m1, preserve(c2), sat), agent, '2026-10-15T09:00:00Z')),
    add(subject(l2, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(attest(a1, model_result, m1, verdict(m1, sanity, reached), agent, '2026-10-15T09:00:00Z')),
    add(attest(a9, reproduction, m1, result(h2, reproduced), agent, '2026-10-15T09:00:00Z')),
    add(discovery_evidence(k1, model)),
    add(claim(c2, introduce, 'x')),
    add(budget(laps, 3)),
    add(check(k1, c1)),
    add(attest(a8, divergence, l2, model(m1), agent, '2026-10-15T09:00:00Z')),
    add(lap_done(2)),
    add(cites(c2, 'x')),
    add(attest(a5, model_result, m1, verdict(m1, preserve(c1), unknown), agent, '2026-10-15T09:00:00Z')),
    add(cites(c1, 'x')),
    add(attest(a10, disproof, m1, verdict(c2, abstained), agent, '2026-10-15T09:00:00Z')),
    add(lap_done(1)),
    add(claim(c1, preserve, 'x')),
    add(model(m1, smt)),
    add(attest(a2, model_result, l2, verdict(m1, root_cause(x), reached), agent, '2026-10-15T09:00:00Z')),
    add(attest(a4, model_result, l2, verdict(m1, preserve(c2), holds), agent, '2026-10-15T09:00:00Z')),
    add(supersedes(c1, c2)),
    add(hypothesis(h2, defect, 'x'))]).
expect(s7x95, 'discovery_ready', none).
expect(s7x95, 'no_falsifier(C)', none).
expect(s7x95, 'model_trusted(M)', none).
expect(s7x95, 'lint_issue(Code, Id, _)', none).
expect(s7x95, 'model_unfiled_break(C)', none).
expect(s7x95, 'discovery_unratified(C)', none).
expect(s7x95, 'discovery_decide', none).
variant(s7x96, [
    add(subject(r10, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(finding(f1, surprise(x), model)),
    add(discovery_evidence(l2, model)),
    add(subject(l2, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(attest(a2, model_result, m2, verdict(m1, sanity, reached), agent, '2026-10-15T09:00:00Z')),
    add(subject(m2, 'p', 'sha256:2222222222222222222222222222222222222222222222222222222222222222')),
    add(attest(a1, model_result, l2, verdict(m1, explore(w), holds), agent, '2026-10-15T09:00:00Z')),
    add(derived_from(m2, m1)),
    add(attest(a5, reproduction, m2, confirms(f2), agent, '2026-10-15T09:00:00Z')),
    add(model_run(r10, m1, 'sha256:1111111111111111111111111111111111111111111111111111111111111111')),
    add(attest(a3, model_result, l2, calibration(m2, case('t'), matches), agent, '2026-10-15T09:00:00Z')),
    add(model_run(r10, m1, 'sha256:1111111111111111111111111111111111111111111111111111111111111111')),
    add(finding(f2, trace(x), system)),
    add(model(m2, smt)),
    add(model(m1, smt)),
    add(attest(a4, model_result, l2, calibration(m2, case('t'), matches), agent, '2026-10-15T09:00:00Z')),
    add(subject(m1, 'p', 'sha256:1111111111111111111111111111111111111111111111111111111111111111'))]).
expect(s7x96, 'discovery_ready', none).
expect(s7x96, 'no_falsifier(C)', none).
expect(s7x96, 'model_trusted(M)', none).
expect(s7x96, 'lint_issue(Code, Id, _)', none).
expect(s7x96, 'model_unfiled_break(C)', none).
expect(s7x96, 'discovery_unratified(C)', none).
expect(s7x96, 'discovery_decide', none).
variant(s7x97, [
    add(claim(c1, retire, 'x')),
    add(supersedes(c3, c1)),
    add(finding(f1, conflict([x, y]), model)),
    add(discovery_evidence(k1, model)),
    add(cites(c1, 'x')),
    add(claim(c3, retire, 'x')),
    add(attest(a1, reproduction, k1, confirms(f2), agent, '2026-10-15T09:00:00Z')),
    add(finding(f2, surprise(x), model)),
    add(attest(a2, reproduction, k1, confirms(f1), agent, '2026-10-15T09:00:00Z')),
    add(cites(c3, 'x')),
    add(check(k1, c3))]).
expect(s7x97, 'discovery_ready', none).
expect(s7x97, 'no_falsifier(C)', none).
expect(s7x97, 'model_trusted(M)', none).
expect(s7x97, 'lint_issue(Code, Id, _)', none).
expect(s7x97, 'model_unfiled_break(C)', none).
expect(s7x97, 'discovery_unratified(C)', none).
expect(s7x97, 'discovery_decide', none).
variant(s7x98, [
    add(derived_from(m1, m2)),
    add(attest(a2, model_result, m2, verdict(m2, explore(w), unknown), agent, '2026-10-15T09:00:00Z')),
    add(model_run(r20, m2, 'sha256:2222222222222222222222222222222222222222222222222222222222222222')),
    add(attest(a1, model_result, r21, verdict(m1, explore(w), unknown), agent, '2026-10-15T09:00:00Z')),
    add(encodes(m1, c2)),
    add(cites(c2, 'x')),
    add(attest(a9, divergence, r21, verdict(c2, inconclusive), agent, '2026-10-15T09:00:00Z')),
    add(model(m1, smt)),
    add(model_run(r10, m1, 'sha256:1111111111111111111111111111111111111111111111111111111111111111')),
    add(claim(c2, preserve, 'x')),
    add(model_run(r21, m2, 'sha256:1111111111111111111111111111111111111111111111111111111111111111')),
    add(attest(a6, model_result, m2, mutation(m1, rb, killed), agent, '2026-10-15T09:00:00Z')),
    add(subject(r21, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(claim(c3, introduce, 'x')),
    add(encodes(m2, c3)),
    add(attest(a4, model_result, m1, verdict(m2, preserve(c2), unsat), agent, '2026-10-15T09:00:00Z')),
    add(cites(c3, 'x')),
    add(attest(a8, reproduction, r10, result(h2, not_reproduced), agent, '2026-10-15T09:00:00Z')),
    add(finding(f2, conflict([x, y]), system)),
    add(attest(a3, model_result, m2, verdict(m2, applies(c1), unsat), agent, '2026-10-15T09:00:00Z')),
    add(hypothesis(h1, feature, 'x')),
    add(derived_from(m1, m2)),
    add(model(m2, smt)),
    add(subject(m1, 'p', 'sha256:1111111111111111111111111111111111111111111111111111111111111111')),
    add(subject(r10, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(subject(m2, 'p', 'sha256:2222222222222222222222222222222222222222222222222222222222222222')),
    add(cites(c1, 'x')),
    add(supersedes(c1, c3)),
    add(attest(a7, reproduction, r10, result(h1, reproduced), agent, '2026-10-15T09:00:00Z')),
    add(hypothesis(h2, feature, 'x')),
    add(claim(c1, introduce, 'x')),
    add(subject(r20, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(attest(a5, model_result, r10, mutation(m2, rb, survived), agent, '2026-10-15T09:00:00Z'))]).
expect(s7x98, 'discovery_ready', none).
expect(s7x98, 'no_falsifier(C)', none).
expect(s7x98, 'model_trusted(M)', none).
expect(s7x98, 'lint_issue(Code, Id, _)', none).
expect(s7x98, 'model_unfiled_break(C)', none).
expect(s7x98, 'discovery_unratified(C)', none).
expect(s7x98, 'discovery_decide', none).
variant(s7x99, [
    add(lap_done(3)),
    add(derived_from(m2, m1)),
    add(attest(a5, model_result, m2, verdict(m2, applies(c1), reached), agent, '2026-10-15T09:00:00Z')),
    add(model(m1, smt)),
    add(answer(q1, no, human)),
    add(encodes(m1, c3)),
    add(lap_done(2)),
    add(encodes(m2, c1)),
    add(subject(m2, 'p', 'sha256:2222222222222222222222222222222222222222222222222222222222222222')),
    add(lap_done(1)),
    add(cites(c3, 'x')),
    add(assumed(q1, yes)),
    add(subject(m1, 'p', 'sha256:1111111111111111111111111111111111111111111111111111111111111111')),
    add(claim(c2, retire, 'x')),
    add(attest(a6, reproduction, k1, result(h1, reproduced), agent, '2026-10-15T09:00:00Z')),
    add(attest(a8, disproof, m2, verdict(c2, refuted), agent, '2026-10-15T09:00:00Z')),
    add(lap_done(4)),
    add(attest(a7, divergence, m1, verdict(c3, abstained), agent, '2026-10-15T09:00:00Z')),
    add(cites(c1, 'x')),
    add(attest(a4, model_result, m1, verdict(m2, sanity, reached), agent, '2026-10-15T09:00:00Z')),
    add(raised_by(q1, c1)),
    add(attest(a1, model_result, m1, verdict(m2, applies(c2), sat), agent, '2026-10-15T09:00:00Z')),
    add(claim(c3, preserve, 'x')),
    add(derived_from(m1, m1)),
    add(question(q1, c3, 'x')),
    add(model(m2, tla)),
    add(claim(c1, retire, 'x')),
    add(cites(c2, 'x')),
    add(attest(a3, model_result, m1, verdict(m2, applies(c3), violated), agent, '2026-10-15T09:00:00Z')),
    add(hypothesis(h1, risk, 'x')),
    add(attest(a2, model_result, m2, verdict(m2, root_cause(x), reached), agent, '2026-10-15T09:00:00Z')),
    add(discovery_evidence(k1, model)),
    add(check(k1, c2)),
    add(budget(laps, 1))]).
expect(s7x99, 'discovery_ready', none).
expect(s7x99, 'no_falsifier(C)', none).
expect(s7x99, 'model_trusted(M)', none).
expect(s7x99, 'lint_issue(Code, Id, _)', none).
expect(s7x99, 'model_unfiled_break(C)', none).
expect(s7x99, 'discovery_unratified(C)', none).
expect(s7x99, 'discovery_decide', none).
variant(s7x100, [
    add(question(q2, c2, 'x')),
    add(subject(l2, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(attest(a1, model_result, r20, verdict(m2, applies(c2), sat), agent, '2026-10-15T09:00:00Z')),
    add(question(q1, c3, 'x')),
    add(cites(c3, 'x')),
    add(claim(c2, introduce, 'x')),
    add(encodes(m2, c3)),
    add(discovery_evidence(l2, system)),
    add(subject(r20, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(encodes(m2, c2)),
    add(model(m2, smt)),
    add(assumed(q2, yes)),
    add(subject(m1, 'p', 'sha256:1111111111111111111111111111111111111111111111111111111111111111')),
    add(claim(c3, introduce, 'x')),
    add(subject(m2, 'p', 'sha256:2222222222222222222222222222222222222222222222222222222222222222')),
    add(model(m1, smt)),
    add(cites(c2, 'x')),
    add(reason(m2, ra, 't')),
    add(assumed(q1, yes)),
    add(model_run(r20, m2, 'sha256:2222222222222222222222222222222222222222222222222222222222222222'))]).
expect(s7x100, 'discovery_ready', none).
expect(s7x100, 'no_falsifier(C)', none).
expect(s7x100, 'model_trusted(M)', none).
expect(s7x100, 'lint_issue(Code, Id, _)', none).
expect(s7x100, 'model_unfiled_break(C)', none).
expect(s7x100, 'discovery_unratified(C)', none).
expect(s7x100, 'discovery_decide', none).
variant(s7x101, [
    add(reason(m2, ra, 't')),
    add(question(q1, c3, 'x')),
    add(model(m2, tla)),
    add(model_run(r20, m2, 'sha256:2222222222222222222222222222222222222222222222222222222222222222')),
    add(encodes(m2, c1)),
    add(finding(f1, conflict([x, y]), model)),
    add(answer(q1, yes, agent)),
    add(attest(a4, model_result, m2, calibration(m2, example(c1), differs), agent, '2026-10-15T09:00:00Z')),
    add(attest(a3, model_result, l2, verdict(m2, sanity, sat), agent, '2026-10-15T09:00:00Z')),
    add(lap_done(2)),
    add(budget(laps, 3)),
    add(cites(c1, 'x')),
    add(assumed(q1, yes)),
    add(subject(r21, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(attest(a5, model_result, m2, calibration(m2, case('t'), matches), agent, '2026-10-15T09:00:00Z')),
    add(encodes(m2, c1)),
    add(claim(c2, preserve, 'x')),
    add(attest(a6, model_result, l1, mutation(m2, rb, killed), agent, '2026-10-15T09:00:00Z')),
    add(attest(a2, model_result, r21, verdict(m2, sanity, violated), agent, '2026-10-15T09:00:00Z')),
    add(attest(a1, model_result, r21, verdict(m2, root_cause(x), unsat), agent, '2026-10-15T09:00:00Z')),
    add(discovery_evidence(l1, system)),
    add(discovery_evidence(l2, model)),
    add(model_run(r21, m2, 'sha256:2222222222222222222222222222222222222222222222222222222222222222')),
    add(subject(r20, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(supersedes(c3, c1)),
    add(lap_done(1)),
    add(claim(c3, introduce, 'x')),
    add(cites(c2, 'x')),
    add(model_run(r21, m2, 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(raised_by(q1, c3)),
    add(subject(l2, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(encodes(m2, c1)),
    add(finding(f2, surprise(x), system)),
    add(claim(c1, introduce, 'x')),
    add(cites(c3, 'x')),
    add(subject(m2, 'p', 'sha256:2222222222222222222222222222222222222222222222222222222222222222')),
    add(subject(l1, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333'))]).
expect(s7x101, 'discovery_ready', none).
expect(s7x101, 'no_falsifier(C)', none).
expect(s7x101, 'model_trusted(M)', none).
expect(s7x101, 'lint_issue(Code, Id, _)', none).
expect(s7x101, 'model_unfiled_break(C)', none).
expect(s7x101, 'discovery_unratified(C)', none).
expect(s7x101, 'discovery_decide', none).
variant(s7x102, [
    add(discovery_evidence(l2, system)),
    add(claim(c1, preserve, 'x')),
    add(claim(c2, retire, 'x')),
    add(cites(c2, 'x')),
    add(attest(a2, model_result, l2, verdict(m1, preserve(c1), violated), agent, '2026-10-15T09:00:00Z')),
    add(raised_by(q2, c1)),
    add(assumed(q1, yes)),
    add(hypothesis(h1, risk, 'x')),
    add(subject(l2, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(subject(r10, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(attest(a7, divergence, m1, model(m1), agent, '2026-10-15T09:00:00Z')),
    add(attest(a8, reproduction, r11, confirms(f1), agent, '2026-10-15T09:00:00Z')),
    add(derived_from(m1, m1)),
    add(attest(a6, model_result, r10, verdict(m1, preserve(c2), reached), agent, '2026-10-15T09:00:00Z')),
    add(attest(a4, model_result, r10, verdict(m1, applies(c1), unsat), agent, '2026-10-15T09:00:00Z')),
    add(model(m1, tla)),
    add(discovery_evidence(l1, system)),
    add(answer(q1, yes, human)),
    add(question(q2, c1, 'x')),
    add(question(q1, c2, 'x')),
    add(cites(c1, 'x')),
    add(attest(a1, model_result, r10, verdict(m1, bad_case, holds), agent, '2026-10-15T09:00:00Z')),
    add(subject(l1, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(subject(r11, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(answer(q2, yes, agent)),
    add(model_run(r11, m1, 'sha256:2222222222222222222222222222222222222222222222222222222222222222')),
    add(model_run(r10, m1, 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(attest(a10, disproof, l2, verdict(c2, inconclusive), agent, '2026-10-15T09:00:00Z')),
    add(attest(a3, model_result, m1, verdict(m1, preserve(c1), unsat), agent, '2026-10-15T09:00:00Z')),
    add(supersedes(c2, c1)),
    add(attest(a5, model_result, r11, verdict(m1, applies(c2), unsat), agent, '2026-10-15T09:00:00Z')),
    add(finding(f1, root_cause(x), model)),
    add(assumed(q2, yes)),
    add(raised_by(q1, c1)),
    add(attest(a9, reproduction, m1, result(h1, reproduced), agent, '2026-10-15T09:00:00Z')),
    add(supersedes(c1, c2))]).
expect(s7x102, 'discovery_ready', none).
expect(s7x102, 'no_falsifier(C)', none).
expect(s7x102, 'model_trusted(M)', none).
expect(s7x102, 'lint_issue(Code, Id, _)', none).
expect(s7x102, 'model_unfiled_break(C)', none).
expect(s7x102, 'discovery_unratified(C)', none).
expect(s7x102, 'discovery_decide', none).
variant(s7x103, [
    add(model_run(r10, m1, 'sha256:1111111111111111111111111111111111111111111111111111111111111111')),
    add(attest(a11, disproof, r20, verdict(c2, inconclusive), agent, '2026-10-15T09:00:00Z')),
    add(answer(q1, no, human)),
    add(lap_done(4)),
    add(attest(a8, reproduction, m1, result(h2, not_reproduced), agent, '2026-10-15T09:00:00Z')),
    add(attest(a1, model_result, m2, verdict(m1, sanity, violated), agent, '2026-10-15T09:00:00Z')),
    add(assumed(q2, yes)),
    add(claim(c2, preserve, 'x')),
    add(model_run(r21, m2, 'sha256:2222222222222222222222222222222222222222222222222222222222222222')),
    add(attest(a3, model_result, r10, verdict(m2, bad_case, sat), agent, '2026-10-15T09:00:00Z')),
    add(attest(a6, model_result, r21, calibration(m1, example(c2), differs), agent, '2026-10-15T09:00:00Z')),
    add(attest(a2, model_result, m1, verdict(m2, applies(c2), reached), agent, '2026-10-15T09:00:00Z')),
    add(attest(a10, divergence, r10, claim(c2), agent, '2026-10-15T09:00:00Z')),
    add(finding(f2, surprise(x), model)),
    add(model_run(r20, m2, 'sha256:2222222222222222222222222222222222222222222222222222222222222222')),
    add(subject(r11, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(finding(f1, conflict([x, y]), model)),
    add(model_run(r11, m1, 'sha256:1111111111111111111111111111111111111111111111111111111111111111')),
    add(subject(r10, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(lap_done(1)),
    add(subject(m2, 'p', 'sha256:2222222222222222222222222222222222222222222222222222222222222222')),
    add(assumed(q1, yes)),
    add(encodes(m1, c2)),
    add(reason(m2, ra, 't')),
    add(lap_done(2)),
    add(subject(r21, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(question(q2, c2, 'x')),
    add(lap_done(3)),
    add(budget(laps, 2)),
    add(attest(a4, model_result, r11, verdict(m2, preserve(c2), unknown), agent, '2026-10-15T09:00:00Z')),
    add(cites(c2, 'x')),
    add(model(m2, tla)),
    add(claim(c1, retire, 'x')),
    add(answer(q2, no, human)),
    add(cites(c1, 'x')),
    add(attest(a9, reproduction, m1, result(h1, not_reproduced), agent, '2026-10-15T09:00:00Z')),
    add(model(m1, tla)),
    add(question(q1, c2, 'x')),
    add(encodes(m2, c2)),
    add(raised_by(q2, h1)),
    add(subject(m1, 'p', 'sha256:1111111111111111111111111111111111111111111111111111111111111111')),
    add(hypothesis(h1, feature, 'x')),
    add(hypothesis(h2, defect, 'x')),
    add(attest(a5, model_result, r20, calibration(m2, example(c1), matches), agent, '2026-10-15T09:00:00Z')),
    add(raised_by(q1, h1)),
    add(attest(a7, model_result, r10, mutation(m2, ra, killed), agent, '2026-10-15T09:00:00Z')),
    add(subject(r20, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333'))]).
expect(s7x103, 'discovery_ready', none).
expect(s7x103, 'no_falsifier(C)', none).
expect(s7x103, 'model_trusted(M)', none).
expect(s7x103, 'lint_issue(Code, Id, _)', none).
expect(s7x103, 'model_unfiled_break(C)', none).
expect(s7x103, 'discovery_unratified(C)', none).
expect(s7x103, 'discovery_decide', none).
variant(s7x104, [
    add(supersedes(c3, c1)),
    add(claim(c1, introduce, 'x')),
    add(question(q1, c1, 'x')),
    add(hypothesis(h1, defect, 'x')),
    add(finding(f2, trace(x), model)),
    add(supersedes(c3, c1)),
    add(finding(f1, trace(x), model)),
    add(raised_by(q1, c3)),
    add(cites(c3, 'x')),
    add(cites(c1, 'x')),
    add(assumed(q1, yes)),
    add(claim(c3, introduce, 'x')),
    add(attest(a1, divergence, zz, verdict(c1, inconclusive), agent, '2026-10-15T09:00:00Z')),
    add(hypothesis(h2, feature, 'x'))]).
expect(s7x104, 'discovery_ready', none).
expect(s7x104, 'no_falsifier(C)', none).
expect(s7x104, 'model_trusted(M)', none).
expect(s7x104, 'lint_issue(Code, Id, _)', none).
expect(s7x104, 'model_unfiled_break(C)', none).
expect(s7x104, 'discovery_unratified(C)', none).
expect(s7x104, 'discovery_decide', none).
variant(s7x105, [
    add(cites(c1, 'x')),
    add(claim(c3, retire, 'x')),
    add(cites(c2, 'x')),
    add(lap_done(2)),
    add(attest(a1, disproof, zz, verdict(c2, inconclusive), agent, '2026-10-15T09:00:00Z')),
    add(lap_done(3)),
    add(budget(laps, 3)),
    add(hypothesis(h2, feature, 'x')),
    add(claim(c1, preserve, 'x')),
    add(hypothesis(h1, risk, 'x')),
    add(budget(laps, 4)),
    add(cites(c3, 'x')),
    add(lap_done(1)),
    add(supersedes(c2, c3)),
    add(claim(c2, introduce, 'x')),
    add(supersedes(c2, c1))]).
expect(s7x105, 'discovery_ready', none).
expect(s7x105, 'no_falsifier(C)', none).
expect(s7x105, 'model_trusted(M)', none).
expect(s7x105, 'lint_issue(Code, Id, _)', none).
expect(s7x105, 'model_unfiled_break(C)', none).
expect(s7x105, 'discovery_unratified(C)', none).
expect(s7x105, 'discovery_decide', none).
variant(s7x106, [
    add(attest(a2, reproduction, l2, result(h2, reproduced), agent, '2026-10-15T09:00:00Z')),
    add(supersedes(c3, c1)),
    add(question(q1, c3, 'x')),
    add(assumed(q1, yes)),
    add(cites(c1, 'x')),
    add(subject(l1, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(discovery_evidence(l1, model)),
    add(claim(c2, preserve, 'x')),
    add(claim(c1, preserve, 'x')),
    add(attest(a3, disproof, k1, claim(c1), agent, '2026-10-15T09:00:00Z')),
    add(hypothesis(h2, risk, 'x')),
    add(claim(c3, preserve, 'x')),
    add(attest(a4, divergence, l2, verdict(c3, refuted), agent, '2026-10-15T09:00:00Z')),
    add(cites(c2, 'x')),
    add(check(k1, c1)),
    add(discovery_evidence(l2, model)),
    add(cites(c3, 'x')),
    add(attest(a1, reproduction, l1, result(h1, not_reproduced), agent, '2026-10-15T09:00:00Z')),
    add(raised_by(q1, c1)),
    add(answer(q1, yes, agent)),
    add(hypothesis(h1, defect, 'x')),
    add(discovery_evidence(k1, model)),
    add(subject(l2, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333'))]).
expect(s7x106, 'discovery_ready', none).
expect(s7x106, 'no_falsifier(C)', none).
expect(s7x106, 'model_trusted(M)', none).
expect(s7x106, 'lint_issue(Code, Id, _)', none).
expect(s7x106, 'model_unfiled_break(C)', none).
expect(s7x106, 'discovery_unratified(C)', none).
expect(s7x106, 'discovery_decide', none).
variant(s7x107, [
    add(attest(a3, model_result, l1, calibration(m1, case('t'), differs), agent, '2026-10-15T09:00:00Z')),
    add(subject(r10, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(attest(a1, model_result, l1, verdict(m1, bad_case, violated), agent, '2026-10-15T09:00:00Z')),
    add(budget(laps, 1)),
    add(hypothesis(h2, feature, 'x')),
    add(attest(a2, model_result, l1, verdict(m1, explore(w), sat), agent, '2026-10-15T09:00:00Z')),
    add(encodes(m1, c2)),
    add(model_run(r10, m1, 'sha256:1111111111111111111111111111111111111111111111111111111111111111')),
    add(attest(a5, model_result, m1, mutation(m1, rb, survived), agent, '2026-10-15T09:00:00Z')),
    add(subject(l1, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(question(q1, c2, 'x')),
    add(assumed(q1, yes)),
    add(lap_done(1)),
    add(claim(c2, retire, 'x')),
    add(reason(m1, ra, 't')),
    add(model(m1, smt)),
    add(attest(a7, divergence, m1, claim(c2), agent, '2026-10-15T09:00:00Z')),
    add(subject(m1, 'p', 'sha256:1111111111111111111111111111111111111111111111111111111111111111')),
    add(discovery_evidence(l1, model)),
    add(attest(a4, model_result, r10, calibration(m1, example(c2), matches), agent, '2026-10-15T09:00:00Z')),
    add(attest(a6, reproduction, r10, result(h2, reproduced), agent, '2026-10-15T09:00:00Z')),
    add(discovery_evidence(l2, system)),
    add(answer(q1, no, agent)),
    add(subject(l2, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(cites(c2, 'x'))]).
expect(s7x107, 'discovery_ready', none).
expect(s7x107, 'no_falsifier(C)', none).
expect(s7x107, 'model_trusted(M)', none).
expect(s7x107, 'lint_issue(Code, Id, _)', none).
expect(s7x107, 'model_unfiled_break(C)', none).
expect(s7x107, 'discovery_unratified(C)', none).
expect(s7x107, 'discovery_decide', none).
variant(s7x108, [
    add(finding(f1, surprise(x), system)),
    add(budget(laps, 3)),
    add(claim(c3, preserve, 'x')),
    add(hypothesis(h1, defect, 'x')),
    add(budget(laps, 2)),
    add(finding(f2, surprise(x), model)),
    add(cites(c3, 'x')),
    add(hypothesis(h2, feature, 'x'))]).
expect(s7x108, 'discovery_ready', none).
expect(s7x108, 'no_falsifier(C)', none).
expect(s7x108, 'model_trusted(M)', none).
expect(s7x108, 'lint_issue(Code, Id, _)', none).
expect(s7x108, 'model_unfiled_break(C)', none).
expect(s7x108, 'discovery_unratified(C)', none).
expect(s7x108, 'discovery_decide', none).
variant(s7x109, [
    add(lap_done(1)),
    add(discovery_evidence(k1, system)),
    add(attest(a1, disproof, l2, claim(c2), agent, '2026-10-15T09:00:00Z')),
    add(subject(l1, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(answer(q1, yes, agent)),
    add(raised_by(q1, f1)),
    add(discovery_evidence(l2, system)),
    add(attest(a2, disproof, k1, verdict(c3, refuted), agent, '2026-10-15T09:00:00Z')),
    add(cites(c2, 'x')),
    add(finding(f1, conflict([x, y]), model)),
    add(budget(laps, 2)),
    add(finding(f2, surprise(x), model)),
    add(question(q1, c2, 'x')),
    add(claim(c3, retire, 'x')),
    add(discovery_evidence(l1, system)),
    add(claim(c2, introduce, 'x')),
    add(check(k1, c3)),
    add(question(q2, c2, 'x')),
    add(subject(l2, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(cites(c3, 'x')),
    add(assumed(q1, yes)),
    add(assumed(q2, yes))]).
expect(s7x109, 'discovery_ready', none).
expect(s7x109, 'no_falsifier(C)', none).
expect(s7x109, 'model_trusted(M)', none).
expect(s7x109, 'lint_issue(Code, Id, _)', none).
expect(s7x109, 'model_unfiled_break(C)', none).
expect(s7x109, 'discovery_unratified(C)', none).
expect(s7x109, 'discovery_decide', none).
variant(s7x110, [
    add(attest(a2, model_result, m1, calibration(m2, example(c3), matches), agent, '2026-10-15T09:00:00Z')),
    add(attest(a1, model_result, r10, verdict(m2, applies(c1), sat), agent, '2026-10-15T09:00:00Z')),
    add(subject(m2, 'p', 'sha256:2222222222222222222222222222222222222222222222222222222222222222')),
    add(subject(m1, 'p', 'sha256:1111111111111111111111111111111111111111111111111111111111111111')),
    add(derived_from(m2, m1)),
    add(raised_by(q1, c3)),
    add(assumed(q1, yes)),
    add(finding(f2, surprise(x), model)),
    add(attest(a3, model_result, r10, calibration(m2, case('t'), matches), agent, '2026-10-15T09:00:00Z')),
    add(attest(a4, model_result, r10, mutation(m1, ra, survived), agent, '2026-10-15T09:00:00Z')),
    add(claim(c1, preserve, 'x')),
    add(hypothesis(h1, defect, 'x')),
    add(answer(q1, no, agent)),
    add(encodes(m2, c3)),
    add(cites(c1, 'x')),
    add(cites(c3, 'x')),
    add(encodes(m2, c3)),
    add(claim(c3, introduce, 'x')),
    add(model(m1, smt)),
    add(model(m2, smt)),
    add(derived_from(m1, m1)),
    add(hypothesis(h2, defect, 'x')),
    add(model_run(r10, m1, 'sha256:1111111111111111111111111111111111111111111111111111111111111111')),
    add(question(q1, c1, 'x')),
    add(subject(r10, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333'))]).
expect(s7x110, 'discovery_ready', none).
expect(s7x110, 'no_falsifier(C)', none).
expect(s7x110, 'model_trusted(M)', none).
expect(s7x110, 'lint_issue(Code, Id, _)', none).
expect(s7x110, 'model_unfiled_break(C)', none).
expect(s7x110, 'discovery_unratified(C)', none).
expect(s7x110, 'discovery_decide', none).
variant(s7x111, [
    add(budget(laps, 3)),
    add(cites(c2, 'x')),
    add(claim(c1, preserve, 'x')),
    add(claim(c2, retire, 'x')),
    add(hypothesis(h2, defect, 'x')),
    add(lap_done(2)),
    add(finding(f1, surprise(x), system)),
    add(lap_done(4)),
    add(lap_done(3)),
    add(hypothesis(h1, feature, 'x')),
    add(supersedes(c1, c2)),
    add(cites(c1, 'x')),
    add(attest(a1, reproduction, k1, result(h1, reproduced), agent, '2026-10-15T09:00:00Z')),
    add(lap_done(1)),
    add(attest(a2, reproduction, k1, result(h2, not_reproduced), agent, '2026-10-15T09:00:00Z')),
    add(discovery_evidence(k1, system)),
    add(check(k1, c1))]).
expect(s7x111, 'discovery_ready', none).
expect(s7x111, 'no_falsifier(C)', none).
expect(s7x111, 'model_trusted(M)', none).
expect(s7x111, 'lint_issue(Code, Id, _)', none).
expect(s7x111, 'model_unfiled_break(C)', none).
expect(s7x111, 'discovery_unratified(C)', none).
expect(s7x111, 'discovery_decide', none).
variant(s7x112, [
    add(model(m1, tla)),
    add(finding(f2, surprise(x), system)),
    add(attest(a1, model_result, m1, calibration(m1, case('t'), matches), agent, '2026-10-15T09:00:00Z')),
    add(lap_done(3)),
    add(lap_done(2)),
    add(discovery_evidence(l1, system)),
    add(attest(a4, reproduction, l1, result(h1, reproduced), agent, '2026-10-15T09:00:00Z')),
    add(finding(f1, scope(x), system)),
    add(hypothesis(h1, risk, 'x')),
    add(attest(a3, reproduction, m1, confirms(f2), agent, '2026-10-15T09:00:00Z')),
    add(lap_done(1)),
    add(hypothesis(h2, risk, 'x')),
    add(attest(a2, model_result, l1, calibration(m1, case('t'), differs), agent, '2026-10-15T09:00:00Z')),
    add(subject(m1, 'p', 'sha256:1111111111111111111111111111111111111111111111111111111111111111')),
    add(budget(laps, 2)),
    add(subject(l1, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333'))]).
expect(s7x112, 'discovery_ready', none).
expect(s7x112, 'no_falsifier(C)', none).
expect(s7x112, 'model_trusted(M)', none).
expect(s7x112, 'lint_issue(Code, Id, _)', none).
expect(s7x112, 'model_unfiled_break(C)', none).
expect(s7x112, 'discovery_unratified(C)', none).
expect(s7x112, 'discovery_decide', none).
variant(s7x113, [
    add(reason(m2, rb, 't')),
    add(cites(c1, 'x')),
    add(claim(c2, retire, 'x')),
    add(subject(l2, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(discovery_evidence(l1, model)),
    add(attest(a3, model_result, l1, verdict(m2, applies(c1), unknown), agent, '2026-10-15T09:00:00Z')),
    add(finding(f2, root_cause(x), model)),
    add(derived_from(m2, m2)),
    add(subject(l1, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(attest(a10, reproduction, m2, confirms(f2), agent, '2026-10-15T09:00:00Z')),
    add(model(m2, tla)),
    add(attest(a5, model_result, l2, verdict(m2, preserve(c3), sat), agent, '2026-10-15T09:00:00Z')),
    add(derived_from(m2, m2)),
    add(discovery_evidence(l2, model)),
    add(cites(c2, 'x')),
    add(cites(c3, 'x')),
    add(attest(a12, disproof, m2, claim(c1), agent, '2026-10-15T09:00:00Z')),
    add(attest(a6, model_result, l1, calibration(m2, example(c3), matches), agent, '2026-10-15T09:00:00Z')),
    add(claim(c3, preserve, 'x')),
    add(attest(a8, model_result, m2, mutation(m2, rb, killed), agent, '2026-10-15T09:00:00Z')),
    add(encodes(m2, c2)),
    add(subject(m2, 'p', 'sha256:2222222222222222222222222222222222222222222222222222222222222222')),
    add(hypothesis(h1, risk, 'x')),
    add(attest(a9, model_result, l2, mutation(m2, rb, survived), agent, '2026-10-15T09:00:00Z')),
    add(encodes(m2, c3)),
    add(claim(c1, introduce, 'x')),
    add(attest(a2, model_result, l1, verdict(m2, preserve(c1), reached), agent, '2026-10-15T09:00:00Z')),
    add(attest(a11, reproduction, l1, result(h1, reproduced), agent, '2026-10-15T09:00:00Z')),
    add(attest(a7, model_result, l2, calibration(m2, case('t'), matches), agent, '2026-10-15T09:00:00Z')),
    add(attest(a4, model_result, l1, verdict(m2, applies(c3), holds), agent, '2026-10-15T09:00:00Z')),
    add(attest(a1, model_result, m2, verdict(m2, explore(w), unsat), agent, '2026-10-15T09:00:00Z'))]).
expect(s7x113, 'discovery_ready', none).
expect(s7x113, 'no_falsifier(C)', none).
expect(s7x113, 'model_trusted(M)', none).
expect(s7x113, 'lint_issue(Code, Id, _)', none).
expect(s7x113, 'model_unfiled_break(C)', none).
expect(s7x113, 'discovery_unratified(C)', none).
expect(s7x113, 'discovery_decide', none).
variant(s7x114, [
    add(lap_done(1)),
    add(hypothesis(h1, feature, 'x')),
    add(claim(c2, preserve, 'x')),
    add(cites(c2, 'x')),
    add(hypothesis(h2, risk, 'x')),
    add(lap_done(4)),
    add(budget(laps, 3)),
    add(attest(a1, disproof, zz, verdict(c2, inconclusive), agent, '2026-10-15T09:00:00Z')),
    add(lap_done(3)),
    add(lap_done(2))]).
expect(s7x114, 'discovery_ready', none).
expect(s7x114, 'no_falsifier(C)', none).
expect(s7x114, 'model_trusted(M)', none).
expect(s7x114, 'lint_issue(Code, Id, _)', none).
expect(s7x114, 'model_unfiled_break(C)', none).
expect(s7x114, 'discovery_unratified(C)', none).
expect(s7x114, 'discovery_decide', none).
variant(s7x115, [
    add(attest(a4, model_result, m2, verdict(m1, bad_case, holds), agent, '2026-10-15T09:00:00Z')),
    add(attest(a1, model_result, m2, verdict(m2, sanity, reached), agent, '2026-10-15T09:00:00Z')),
    add(subject(m2, 'p', 'sha256:2222222222222222222222222222222222222222222222222222222222222222')),
    add(lap_done(3)),
    add(hypothesis(h1, defect, 'x')),
    add(attest(a7, model_result, r10, calibration(m2, case('t'), matches), agent, '2026-10-15T09:00:00Z')),
    add(model(m1, tla)),
    add(model_run(r10, m1, 'sha256:1111111111111111111111111111111111111111111111111111111111111111')),
    add(subject(l1, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(model(m2, smt)),
    add(budget(laps, 1)),
    add(model_run(r20, m2, 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(attest(a2, model_result, r10, verdict(m2, bad_case, unsat), agent, '2026-10-15T09:00:00Z')),
    add(model_run(r20, m2, 'sha256:2222222222222222222222222222222222222222222222222222222222222222')),
    add(attest(a6, model_result, m1, verdict(m2, explore(w), violated), agent, '2026-10-15T09:00:00Z')),
    add(attest(a3, model_result, l1, verdict(m2, sanity, reached), agent, '2026-10-15T09:00:00Z')),
    add(attest(a5, model_result, m1, verdict(m2, bad_case, unsat), agent, '2026-10-15T09:00:00Z')),
    add(lap_done(1)),
    add(subject(m1, 'p', 'sha256:1111111111111111111111111111111111111111111111111111111111111111')),
    add(subject(r20, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(attest(a8, model_result, r20, mutation(m2, ra, killed), agent, '2026-10-15T09:00:00Z')),
    add(lap_done(2)),
    add(subject(r10, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333'))]).
expect(s7x115, 'discovery_ready', none).
expect(s7x115, 'no_falsifier(C)', none).
expect(s7x115, 'model_trusted(M)', none).
expect(s7x115, 'lint_issue(Code, Id, _)', none).
expect(s7x115, 'model_unfiled_break(C)', none).
expect(s7x115, 'discovery_unratified(C)', none).
expect(s7x115, 'discovery_decide', none).
variant(s7x116, [
    add(attest(a1, reproduction, l1, confirms(f2), agent, '2026-10-15T09:00:00Z')),
    add(subject(l1, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(hypothesis(h2, risk, 'x')),
    add(finding(f1, trace(x), model)),
    add(discovery_evidence(l1, system)),
    add(finding(f2, trace(x), model))]).
expect(s7x116, 'discovery_ready', none).
expect(s7x116, 'no_falsifier(C)', none).
expect(s7x116, 'model_trusted(M)', none).
expect(s7x116, 'lint_issue(Code, Id, _)', none).
expect(s7x116, 'model_unfiled_break(C)', none).
expect(s7x116, 'discovery_unratified(C)', none).
expect(s7x116, 'discovery_decide', none).
variant(s7x117, [
    add(subject(l1, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(raised_by(q2, c3)),
    add(lap_done(1)),
    add(hypothesis(h2, risk, 'x')),
    add(question(q2, c3, 'x')),
    add(discovery_evidence(l1, model)),
    add(assumed(q2, yes)),
    add(question(q1, c3, 'x')),
    add(lap_done(2)),
    add(check(k1, c3)),
    add(claim(c3, introduce, 'x')),
    add(assumed(q1, yes)),
    add(discovery_evidence(k1, system)),
    add(attest(a1, reproduction, k1, confirms(f2), agent, '2026-10-15T09:00:00Z')),
    add(finding(f2, root_cause(x), model)),
    add(budget(laps, 3)),
    add(attest(a3, reproduction, k1, result(h2, reproduced), agent, '2026-10-15T09:00:00Z')),
    add(subject(l2, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(finding(f1, trace(x), model)),
    add(cites(c3, 'x')),
    add(attest(a2, reproduction, l2, confirms(f1), agent, '2026-10-15T09:00:00Z')),
    add(answer(q2, no, human)),
    add(lap_done(3))]).
expect(s7x117, 'discovery_ready', none).
expect(s7x117, 'no_falsifier(C)', none).
expect(s7x117, 'model_trusted(M)', none).
expect(s7x117, 'lint_issue(Code, Id, _)', none).
expect(s7x117, 'model_unfiled_break(C)', none).
expect(s7x117, 'discovery_unratified(C)', none).
expect(s7x117, 'discovery_decide', none).
variant(s7x118, [
    add(assumed(q1, yes)),
    add(claim(c3, retire, 'x')),
    add(cites(c3, 'x')),
    add(encodes(m1, c2)),
    add(attest(a1, model_result, m1, verdict(m1, applies(c2), sat), agent, '2026-10-15T09:00:00Z')),
    add(question(q1, c3, 'x')),
    add(finding(f1, scope(x), model)),
    add(attest(a8, divergence, m1, verdict(c2, refuted), agent, '2026-10-15T09:00:00Z')),
    add(model(m1, smt)),
    add(encodes(m1, c1)),
    add(attest(a7, reproduction, m1, result(h1, not_reproduced), agent, '2026-10-15T09:00:00Z')),
    add(lap_done(1)),
    add(raised_by(q1, f1)),
    add(subject(m1, 'p', 'sha256:1111111111111111111111111111111111111111111111111111111111111111')),
    add(attest(a2, model_result, m1, verdict(m1, applies(c3), unsat), agent, '2026-10-15T09:00:00Z')),
    add(claim(c2, preserve, 'x')),
    add(lap_done(4)),
    add(hypothesis(h1, defect, 'x')),
    add(attest(a3, model_result, m1, verdict(m1, sanity, sat), agent, '2026-10-15T09:00:00Z')),
    add(lap_done(2)),
    add(cites(c2, 'x')),
    add(budget(laps, 3)),
    add(attest(a5, divergence, m1, model(m1), agent, '2026-10-15T09:00:00Z')),
    add(reason(m1, ra, 't')),
    add(claim(c1, retire, 'x')),
    add(attest(a6, reproduction, m1, confirms(f1), agent, '2026-10-15T09:00:00Z')),
    add(cites(c1, 'x')),
    add(lap_done(3)),
    add(encodes(m1, c2)),
    add(attest(a4, model_result, m1, mutation(m1, rb, survived), agent, '2026-10-15T09:00:00Z'))]).
expect(s7x118, 'discovery_ready', none).
expect(s7x118, 'no_falsifier(C)', none).
expect(s7x118, 'model_trusted(M)', none).
expect(s7x118, 'lint_issue(Code, Id, _)', none).
expect(s7x118, 'model_unfiled_break(C)', none).
expect(s7x118, 'discovery_unratified(C)', none).
expect(s7x118, 'discovery_decide', none).
variant(s7x119, [
    add(cites(c1, 'x')),
    add(cites(c2, 'x')),
    add(subject(l2, 'p', 'sha256:3333333333333333333333333333333333333333333333333333333333333333')),
    add(supersedes(c3, c1)),
    add(claim(c3, retire, 'x')),
    add(budget(laps, 1)),
    add(cites(c3, 'x')),
    add(claim(c2, retire, 'x')),
    add(claim(c1, introduce, 'x')),
    add(discovery_evidence(l2, system))]).
expect(s7x119, 'discovery_ready', none).
expect(s7x119, 'no_falsifier(C)', none).
expect(s7x119, 'model_trusted(M)', none).
expect(s7x119, 'lint_issue(Code, Id, _)', none).
expect(s7x119, 'model_unfiled_break(C)', none).
expect(s7x119, 'discovery_unratified(C)', none).
expect(s7x119, 'discovery_decide', none).

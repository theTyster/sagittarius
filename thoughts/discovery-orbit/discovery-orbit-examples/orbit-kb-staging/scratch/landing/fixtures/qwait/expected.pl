% Intended (R7 "clean": no question waits; REVIEW 10 "keep the question_waits expectation as
% the guard"): a raised, unanswered question blocks readiness, with nothing else open.
variant(qw_hypothesis_question, [
    add(question(q2, c1, 'Order 4417 did not reproduce on staging. Is the log from production?')),
    add(assumed(q2, production)),
    add(raised_by(q2, h1))]).
expect(qw_hypothesis_question, 'question_waits(Q)', ['Q = q2']).
expect(qw_hypothesis_question, 'discovery_unratified(C)', none).
expect(qw_hypothesis_question, 'discovery_ready', none).
% cf1_no_answer after F3: the guard is masked by ED7 on c2b.
variant(qw_cf1, [delete(answer(q1, floor_wins, human))]).
expect(qw_cf1, 'question_waits(Q)', ['Q = q1']).
expect(qw_cf1, 'discovery_unratified(C)', ['C = c2b']).

% Variant of core-min.pl for the chained-projection test (Test 2b).
% Only current/1 and refuted/1 differ, so that each rule has at most one
% body-only variable. refuted/1 uses attests/2, which discovery-chain-all.pl defines.

% --- Declarations: a core predicate may have no facts yet ---
ticket(_) :- false.
claim(_, _, _) :- false.
cites(_, _) :- false.
supersedes(_, _) :- false.
example(_, _) :- false.
universal(_) :- false.
question(_, _, _) :- false.
assumed(_, _) :- false.
answer(_, _, _) :- false.
depends(_, _) :- false.
check(_, _) :- false.
world(_) :- false.
source(_, _) :- false.
scope(_, _) :- false.
risk(_, _) :- false.
assumption(_, _) :- false.
not_explored(_) :- false.
subject(_, _, _) :- false.
attest(_, _, _, _, _, _) :- false.

% --- Core rules ---
superseded(C) :- supersedes(_, C).
claim_c(C, K) :- claim(C, K, _).
current(C) :- claim_c(C, _), not superseded(C).
answered(Q) :- answer(Q, _, human).
refuted(C) :- attests(_, verdict(C, refuted)).

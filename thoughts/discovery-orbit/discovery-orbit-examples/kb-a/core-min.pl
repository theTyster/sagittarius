% Minimal stand-in for the shared core: only what the discovery module uses.
% The real core belongs to dotfiles-08. Rules follow the build-orbit draft,
% except refuted/1, which uses the generic form proposed to dotfiles-08.

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
current(C) :- claim(C, _, _), not superseded(C).
answered(Q) :- answer(Q, _, human).
% Generic: any attestation whose predicate is verdict(C, refuted) refutes C.
refuted(C) :- attest(_, _, _, verdict(C, refuted), _, _).

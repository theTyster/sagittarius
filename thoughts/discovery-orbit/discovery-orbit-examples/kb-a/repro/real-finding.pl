attest(a1, reproduction, sys, result(h1, reproduced), script, '2026-10-15T09:10').
attest(a4, reproduction, sys, confirms(f1), script, '2026-10-15T09:35').
finding_confirmed(F) :- attest(_, reproduction, _, confirms(F), _, _).
l :- not finding_confirmed(f1).

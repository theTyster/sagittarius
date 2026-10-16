% orbit-kb build module (modules/build.pl)
%
% Load this module with uses([build]) in kb.pl. It adds the changes to
% the code, the Lean results, and the rules that decide when the build
% is done. The file format and the H1 rule are the same as in core.pl.
% The rules below use the core rules passed/1, was_red/1, refuted/1,
% current/1, to_ask/1, and contested_twice/1.


% ---------------------------------------------------------------------
% Build facts
% ---------------------------------------------------------------------

decl(fact, change(id, text),
     'A change to the code, with the file or a short description.',
     '@(1) is a change: @(2)').
decl(fact, serves(ref(change), ref(claim)),
     'The change serves the claim.',
     'change @(1) serves claim @(2)').
decl(fact, burn_requested(ref(claim)),
     'A human asked for a formal statement of the claim, for example in Lean.',
     'a human asked for a formal statement of claim @(1)').

% ---------------------------------------------------------------------
% Build rule predicates
% ---------------------------------------------------------------------

decl(rule, fulfilled(ref(claim)),
     'A check of the claim passed with no later fail, it failed first unless the label is preserve, and nothing refutes the claim.',
     'claim @(1) is fulfilled').
decl(rule, under(ref(claim)),
     'The claim is current, but it is not fulfilled.',
     'claim @(1) is current but not fulfilled').
decl(rule, served(ref(change)),
     'The change serves at least one claim.',
     'change @(1) serves a claim').
decl(rule, over(ref(change)),
     'The change serves no claim.',
     'change @(1) serves no claim').
decl(rule, any_under,
     'At least one current claim is not fulfilled.',
     'some current claim is not fulfilled').
decl(rule, any_over,
     'At least one change serves no claim.',
     'some change serves no claim').
decl(rule, done,
     'No current claim is unfulfilled, no change is without a claim, and no question must be asked.',
     'the work is done').
decl(rule, burn(ref(claim)),
     'The claim needs a formal statement, for example in Lean, because it was contested twice, it is universal, or a human asked.',
     'claim @(1) needs a formal statement').

% ---------------------------------------------------------------------
% Build attestation types
% ---------------------------------------------------------------------

attest_type(lean_result,
            verdict(ref(claim), alt([stated, refuted, tested(int), proved])),
            [agent, script],
            'The verdict of a Lean statement of a claim: stated, refuted, tested in N trials, or proved.').

% ---------------------------------------------------------------------
% Build rules
% ---------------------------------------------------------------------

fulfilled(C) :- claim(C, preserve, _), check(K, C), passed(K), not refuted(C).
fulfilled(C) :- claim(C, L, _), L \= preserve, check(K, C), passed(K), was_red(K),
                not refuted(C).
under(C) :- current(C), not fulfilled(C).
served(X) :- serves(X, _).
over(X) :- change(X, _), not served(X).
any_under :- under(_).
any_over :- over(_).
done :- not any_under, not any_over, not any_to_ask.
burn(C) :- contested_twice(C).
burn(C) :- universal(C).
burn(C) :- burn_requested(C).

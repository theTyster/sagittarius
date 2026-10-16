:- use_module(library(yall)).
:- use_module(library(apply)).
:- initialization(main, main).
main(A) :-
    writeln(argv(A)),
    partition([X]>>sub_atom(X, 0, _, _, 'only='), A, O, R),
    writeln(O-R).

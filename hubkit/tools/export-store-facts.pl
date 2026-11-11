% Writes hubkit/tools/store-facts.json from the hub design KB (T22 c1).
%   cd <hub design KB> && swipl -g "consult(load), consult('<this file>'), export_store_facts('<out.json>'), halt"
% It copies only what the store map needs: the seven stores with their definitions (Ty's own
% definition where Ty wrote one, else the definition of kg_def_v2), and the fact kinds of
% eff_fact/2 with fact_desc/2 and eff_cell/3 (owner O, pinned P, read R, copied C).
:- use_module(library(http/json)).

store_order([spec, project, ledger, memory, weeks, bespoke, tracker]).

store_owns(S, Text) :- ty_def(S, ty, T), !, first_para(T, Text).
store_owns(S, Text) :- kg_def_v2(S, T), first_para(T, Text).

first_para(T, One) :-
    atom_string(T, S),
    split_string(S, "\n", "", Lines),
    take_para(Lines, Ps),
    atomic_list_concat(Ps, ' ', One0),
    normalize_space(atom(One), One0).
take_para([], []).
take_para([L|Ls], Out) :-
    (   normalize_space(string(""), L) -> Out = [] ; Out = [L|R], take_para(Ls, R) ).

export_store_facts(File) :-
    store_order(Ss),
    findall(_{name: S, owns: O}, (member(S, Ss), store_owns(S, O)), Stores),
    findall(_{name: F, desc: D, owner: Ow, pinned: P, read: R, copied: C},
            ( eff_fact(F, _), fact_desc(F, D),
              once(eff_cell(F, Ow, 'O')),
              cells(F, 'P', P), cells(F, 'R', R), cells(F, 'C', C) ),
            Facts0),
    sort(name, @=<, Facts0, Facts),
    open(File, write, Out, [encoding(utf8)]),
    json_write_dict(Out, _{stores: Stores, facts: Facts}, [width(0)]),
    nl(Out), close(Out).

cells(F, K, L) :- findall(S, eff_cell(F, S, K), L0), sort(L0, L).

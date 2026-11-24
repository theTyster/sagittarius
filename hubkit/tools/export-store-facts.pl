% Writes hubkit/tools/store-facts.json from the hub design KB (T22 c1).
%   cd <hub design KB> && swipl -g "consult(load), consult('<this file>'), export_store_facts('<out.json>'), halt"
% It copies only what the store map needs: the seven stores with their definitions (Ty's own
% definition where Ty wrote one, else the definition of kg_def_v2; changed_def/3 wins over both), and the fact kinds of
% eff_fact/2 with fact_desc/2 and eff_cell/3 (owner O, pinned P, read R, copied C).
:- use_module(library(http/json)).

store_order([spec, project, ledger, memory, weeks, bespoke, tracker]).

% A definition that the design KB changed after Ty's cells (changed_def/3, design_1106.pl: the weeks
% store loses the session index, Ty 2026-11-12) wins; a design KB without changed_def/3 reads as before.
store_owns(S, Text) :- catch(changed_def(S, T, _), error(existence_error(_, _), _), fail), !, first_para(T, Text).
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
            ( eff_fact(F, _), \+ amend_fact(F, _, _, _, _, _), desc_of(F, D),
              once(eff_cell(F, Ow, 'O')),
              cells(F, 'P', P), cells(F, 'R', R), cells(F, 'C', C) ),
            Facts1),
    findall(_{name: F, desc: D, owner: Ow, pinned: P, read: R, copied: C},
            amend_fact(F, Ow, P, R, C, D), Facts2),
    append(Facts1, Facts2, Facts0),
    sort(name, @=<, Facts0, Facts),
    open(File, write, Out, [encoding(utf8)]),
    json_write_dict(Out, _{stores: Stores, facts: Facts}, [width(0)]),
    nl(Out), close(Out).

% Amendments of a release, made after the design KB was written. They win over the design KB, so
% that the export of an unchanged design KB gives the store map of the release. Sagittarius 0.8.0
% (spec KB scientific-method-overhaul): a ticket is a goal with hypotheses, claims and experiments
% (c1, c2), an experiment has one verdict (c6, c7), a judgment of the human is a record (c10), and the
% project KB holds project goals, premises and hypotheses (c17, c44).
% amend_desc(Fact, Text): a new description of a fact kind of the design KB.
amend_desc(hypothesis, 'A hypothesis of the ticket: a claim about an avenue to the goal, with its author, its state (proposed, adopted, retired or defeated), its premises beside it, and the case that would show it false.').
amend_desc(checks, 'The experiments: each tests one claim, with its procedure, its measurement premises, and the record of each run with one verdict (meets, conflicts or unresolved).').
% amend_fact(Fact, Owner, Pinned, Read, Copied, Text): a fact kind that the design KB does not hold.
amend_fact(goal, spec, [], [], [tracker], 'The goal of the ticket: what the human hopes to accomplish, the intent. It names no avenue, and it names the project goal that it supports.').
amend_fact(judgments, spec, [], [], [], 'The judgments of the human: of the goal on a concrete case (wanted or not wanted), of the goal as a whole (satisfied or not), the adoption of a hypothesis, and the acceptance of a formal statement.').
amend_fact(project_goals, project, [], [ledger, spec], [], 'The project goals, premises and hypotheses: what the product is for. Each ticket goal and each item of work leads to one; a goal is dropped by its owner, never defeated.').

desc_of(F, D) :- amend_desc(F, D), !.
desc_of(F, D) :- fact_desc(F, D).

cells(F, K, L) :- findall(S, eff_cell(F, S, K), L0), sort(L0, L).

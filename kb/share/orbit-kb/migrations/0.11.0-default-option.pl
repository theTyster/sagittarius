% A migration of orbit-kb (kb-migrations; orbit-kb help migrate gives the format).
% orbit-kb 0.11.0 refuses a default (assumed/2) that is none of the options of its question (E22), so the
% Desk shows each choice once (question-default-option c1, c2; Ty answered q2: migrate the open KBs, and q3:
% the agent that holds the KB links the defaults that the text does not link). A question made before has a
% default with its own text. Two steps:
%   link  (tool): the default begins with the text of an option (compared without case, option text of 3
%         characters or more, and at a word boundary: Keep does not link "Keeping neither"): the longest such option becomes the default (a new assumed/2), and the old
%         default is struck by its fact (struck/4 with fact(F), at the time of the write); it stays in kb.pl.
%   means (agent): the default begins with no option. The agent that holds the KB reads it and says which
%         option it means: orbit-kb replace 'assumed(Q)#N' "assumed(Q, 'Option text')" --why TEXT (N: the
%         number of that assumed/2 among the facts assumed(Q, ...) of kb.pl). Only when it means no option,
%         it adds the option: orbit-kb add "option(Q, 'Default text', 'what it does')". The migration lists
%         the questions; it never merges them by itself, since a default that says the same as an option in
%         other words would show as a twin choice on the Desk.
% A closed KB is frozen and is not changed (migrate apply refuses it).
migration(m_0_11_0_default_option, '0.11.0',
          'The default of a question is the text of one of its options: a default with its own text is linked to its option, or becomes an option.').
changes(m_0_11_0_default_option, [assumed/2, option/3, struck/4, lint('E22'), lint('W22')]).
step(m_0_11_0_default_option, link, tool,
     'The default begins with the text of an option: the longest such option is the default, and the old default is struck').
pending(m_0_11_0_default_option, link, q(Q, D, O),
        ( assumed(Q, D), option(Q, O, _), not option(Q, D, _),
          downcase_atom(D, DL), downcase_atom(O, OL), atom_length(OL, N), N >= 3, sub_atom(DL, 0, _, _, OL),
          ( atom_length(DL, LLa), ( LLa =:= N ; sub_atom(DL, N, 1, _, Ca), \+ char_type(Ca, alnum) ) ),
          not ( option(Q, O2, _), O2 \== O, downcase_atom(O2, OL2), atom_length(OL2, N2), N2 >= 3, sub_atom(DL, 0, _, _, OL2), ( atom_length(DL, LLb), ( LLb =:= N2 ; sub_atom(DL, N2, 1, _, Cb), \+ char_type(Cb, alnum) ) ),
                ( N2 > N ; N2 =:= N, O2 @< O ) ) )).
writes(m_0_11_0_default_option, link, q(Q, D, O),
       [assumed(Q, O), struck(fact(assumed(Q, D)), script, '$now', 'the default had its own text; its option is the default now (migration 0.11.0)')]).
step(m_0_11_0_default_option, means, agent,
     'The default begins with no option: say which option it means (orbit-kb replace the default by the text of that option), or add it as an option when it means none').
pending(m_0_11_0_default_option, means, q(Q, D),
        ( assumed(Q, D), option(Q, _, _), not option(Q, D, _),
          not ( option(Q, O3, _), downcase_atom(D, DL3), downcase_atom(O3, OL3), atom_length(OL3, N3), N3 >= 3, sub_atom(DL3, 0, _, _, OL3), ( atom_length(DL3, LLc), ( LLc =:= N3 ; sub_atom(DL3, N3, 1, _, Cc), \+ char_type(Cc, alnum) ) ) ) )).

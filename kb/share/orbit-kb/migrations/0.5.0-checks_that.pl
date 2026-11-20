% A migration of orbit-kb (kb-migrations; orbit-kb help migrate gives the format).
% orbit-kb 0.5.0 asks for the words of each check: checks_that/2 (E20 at add, lint W12). A check
% made before 0.5.0 has none. Only the agent can write the words, so the step is an agent step:
% it is to do while lint W12 fires on the KB, and done when it no longer does.
migration(m_0_5_0_checks_that, '0.5.0',
          'Each check says in words what it checks (checks_that/2); a check made before 0.5.0 has no words.').
changes(m_0_5_0_checks_that, [checks_that/2, lint('W12')]).
step(m_0_5_0_checks_that, words, agent,
     'Add checks_that(K, Text) for each check K: one line, in plain words, that says what it checks (orbit-kb add). Done when lint W12 no longer fires').
pending(m_0_5_0_checks_that, words, K, lint_issue('W12', K, _)).

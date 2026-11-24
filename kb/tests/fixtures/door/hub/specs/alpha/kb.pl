uses([build, project]).
request(r1, 'Make alpha greet.').
goal(g1, feature, human, 'Alpha greets the user.').
no_premises(g1).
supports(g1, project(pg1)).
project_kb('../../project-kb').
hypothesis(hy1, g1, agent, 'A greeting line at start is enough.').
defeating_case(hy1, agent, 'A user who starts alpha and sees no greeting.').
claim(c1, introduce, 'Alpha prints a greeting at start.').
cites(c1, 'r1').
example(c1, 'alpha prints hello').
predicts(hy1, c1).
check(k1, c1).
checks_that(k1, 'alpha prints hello').
question(q1, c1, 'Which greeting does alpha print?').

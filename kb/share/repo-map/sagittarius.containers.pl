% Containers and links of the sagittarius repo, for kb/bin/repo-map (formats: README.md here).
% Truth as of 2026-11-05: prompt/, kb/ (orbit-kb), evals/, site/ and docs/ are in the tree.
% hubkit/ and s1/ are planned (tickets T01 and T04 of the redesign) and not in the tree yet.
repo(sagittarius).
about(sagittarius, 'A way for a human and an AI agent to agree on what is being built.').
about(hubflow_starter, 'The source of hubkit (planned to move into this repo).').

person(user, 'User', 'Works with an agent; adds the prompt to Claude Code sessions.').
external(claude_code, 'Claude Code', 'The agent tool that takes the prompt and runs orbit-kb.').
external(swipl, 'SWI-Prolog', 'The only engine of orbit-kb.').
external(lean, 'Lean 4', 'Checks proofs; needed only for proofs.').
external(pages, 'GitHub Pages', 'Publishes the decks.').

container(prompt, 'System prompt', 'Markdown', 'prompt/SAGITTARIUS.md, plus the pane prompts in prompt/PANES.md and prompt/panes/.').
container(orbit_kb, 'orbit-kb', 'SWI-Prolog', 'CLI in kb/bin that writes, lints and queries Prolog KBs; its rules, contract and tests live in kb/.').
container(hubkit, 'hubkit', 'Python', 'Planned: the hub kit (hubkit/), moved in from hubflow-starter. Not in the tree yet.').
container(s1, 's1', 'Python', 'Planned: the System 1 client, hook and tempering tool (s1/). Not in the tree yet.').
container(evals, 'Evals', 'Shell and Python', 'evals/: planning and tool-use evals for the prompt, with graded runs.').
container(site, 'Decks', 'HTML', 'site/: the full deck and the generated short deck.').
container(docs, 'Docs', 'Markdown', 'docs/: the philosophy and the eval refining loop.').

link(user, prompt, 'appends to sessions').
link(user, orbit_kb, 'runs through the agent').
link(prompt, claude_code, 'is appended to the system prompt of').
link(orbit_kb, swipl, 'runs on').
link(orbit_kb, lean, 'records proofs with').
link(evals, prompt, 'grades').
link(evals, orbit_kb, 'drives').
link(site, pages, 'publishes the decks to').
link(docs, prompt, 'explains').
link(hubkit, orbit_kb, 'uses (planned)').
link(s1, prompt, 'serves the sessions of (planned)').
link(hubkit, hubflow_starter, 'comes from').

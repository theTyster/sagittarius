% Containers and links of the sagittarius repo, for kb/bin/repo-map (formats: README.md here).
% Truth as of 2026-11-06: prompt/, kb/ (orbit-kb), hubkit/, s1/, evals/, site/ and docs/ are in the tree.
repo(sagittarius).
about(sagittarius, 'A way for a human and an AI agent to agree on what is being built.').
about(hubflow_starter, 'The source of hubkit, imported into hubkit/ with its history.').

person(user, 'User', 'Works with an agent; adds the prompt to Claude Code sessions.').
external(claude_code, 'Claude Code', 'The agent tool that takes the prompt and runs orbit-kb.').
external(swipl, 'SWI-Prolog', 'The only engine of orbit-kb.').
external(lean, 'Lean 4', 'Checks proofs; needed only for proofs.').
external(pages, 'GitHub Pages', 'Publishes the decks.').

container(prompt, 'System prompt', 'Markdown', 'prompt/SAGITTARIUS.md, plus the pane prompts in prompt/PANES.md and prompt/panes/.').
container(orbit_kb, 'orbit-kb', 'SWI-Prolog', 'CLI in kb/bin that writes, lints and queries Prolog KBs; its rules, contract and tests live in kb/.').
container(hubkit, 'hubkit', 'Python', 'hubkit/: the hub kit (hubflow and hubkit tools), imported from hubflow-starter.').
container(s1, 's1', 'Python', 's1/: the System 1 (Jev) client, the prompt hook and the tempering tool.').
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
link(hubkit, orbit_kb, 'pins spec KBs of').
link(s1, prompt, 'adds context to the sessions of').
link(hubkit, hubflow_starter, 'comes from').

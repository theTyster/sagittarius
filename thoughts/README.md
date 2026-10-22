# thoughts/

Design notes and records. Most of them were written in Ty's dotfiles repository, before
this work moved here on 2026-10-22, while it was still called **Orbital Shifting**. They
are kept as written. Read them with these three things in mind:

- **The name.** "Orbital Shifting" and "orbital shifting" mean Sagittarius.
- **Commit hashes** are from the dotfiles repository. The same commits are in this
  repository with new hashes; find one with `git log --grep '<subject>'`.
- **Paths** are dotfiles paths. They map to this repository as follows:

| Dotfiles path | Here |
|---|---|
| `shared/link/.claude/orbital-shifting/ORBITAL-SHIFTING.md` | `prompt/SAGITTARIUS.md` |
| `shared/link/.claude/AIDLC-SystemPrompt/` | `aidlc/` |
| `shared/link/.local/bin/orbit-kb` | `kb/bin/orbit-kb` |
| `shared/link/.local/share/orbit-kb/` | `kb/share/orbit-kb/` |
| `scripts/orbit-kb/` | `kb/tests/` |
| `thoughts/orbital-shifting-site/` | `site/` |
| `thoughts/orbital-shifting-evals/` | `evals/` |
| `thoughts/<file>` | `thoughts/<file>` |

| File | What it is |
|---|---|
| `orbital-shifting-history.md` | The path from the orbital plugins to the AIDLC to Sagittarius, with evidence. |
| `orbital-shifting-why.md` | Ty's account of why: signals, not tiers. |
| `orbital-shifting-system-prompt-draft.md` | Design notes behind the prompt. |
| `orbital-shifting-merge-*`, `orbital-shifting-refinement-*` | Records of the merge of the discovery and build orbits, and the refinement loop. |
| `orbit-kb-contract.md` | The CLI contract that `kb/tests/` tests against. |
| `orbit-kb-d10-*`, `orbit-kb-perf-results-*` | The D10 burn ticket and the s(CASP) performance investigation. |
| `aidlc-*` | The AIDLC era (retired 2026-10-21). |
| `discovery-orbit/` | The discovery-orbit ticket, its draft, evidence, and staging work. |

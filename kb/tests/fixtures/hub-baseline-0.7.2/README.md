# The hub baseline at 0.7.2

The baseline of `kb/tests/compare_hubs.sh` (scientific-method-overhaul, claims c20, c21 and c43):
what orbit-kb 0.7.2 (e89d488) answers on the KBs of the two hubs of the build machine. This folder
holds the counts only. The KBs of a hub and the answers of the tool hold private project data: do
not commit them, here or elsewhere in this repository.

## The run of 2026-11-24

OLD and NEW were both the tool of 0.7.2. The run took 317 s.

| | Hub 1 | Hub 2 | Both |
|---|---|---|---|
| KBs (the spec KBs and one project KB) | 13 (12 and 1) | 74 (73 and 1) | 87 |
| KBs that OLD does not open | 0 | 0 | 0 |
| Done (`query done` exits 0) | | | 27 |
| Answer lines of `query 'blocking(X)' -n 0` | | | 181 |
| Items of `show open` | | | 479 |
| Answer lines of `query 'hypothesis(H, K, T)' -n 0` | | | 109 |

With the same tool on both sides, the rules (a), (b), (c), (d) and (f) pass on each of the 87 KBs.
Rule (e) fails on each of the 87 KBs with two violations: 0.7.2 does not know `goal/4` and
`hypothesis/4` (each query exits 2). The script exits 1. A tool that brings each KB over (c21)
makes rule (e) pass.

## How to make it again

```sh
git worktree add /tmp/sag-072 v0.7.2          # the old tool: any checkout of 0.7.2
bash kb/tests/compare_hubs.sh --save DIR /tmp/sag-072/kb/bin/orbit-kb kb/bin/orbit-kb HUB_DIR...
```

- The script copies `specs/` and the project KB of each hub to a temporary folder, one copy for
  each tool. It does not write in a hub.
- `--save DIR` keeps the answers of OLD for each KB (stdout and the exit code of each call). Keep
  `DIR` outside this repository.
- A hub changes each day. The counts of a later run are other counts. To compare with a frozen
  state, make a copy of the hub first and give the script the copy.
- Exit 0: no violation. Exit 1: a violation of (a) to (f); each has one line. Exit 2: a setup error.

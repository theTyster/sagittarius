# TECHNOLOGIES.md

Tools you use outside your team's official stack, with versions and paths. Re-verify a version by
running the binary before you rely on it: these drift silently.

| Technology | Version | Where | Used for |
|---|---|---|---|
| Claude Code | | | Agents, skills, the whole operating surface |
| Python 3 | ≥ 3.9 | | `hubflow.py` (stdlib only) |
| SQLite | (bundled with Python) | | `flow/flow.db` |
| jq | | | `sessions/launch.sh` |

# Sagittarius map: groups and flow

Made by `python3 kb/share/repo-map/views.py build` from MODULES.json, hubkit/tools/store-facts.json and kb/share/repo-map/sagittarius.views.json. Do not edit: `views.py check` goes red when this file differs from its sources. The HTML page beside it (`sagittarius-map.html`) draws the same views as SVG.

## Groups view

```mermaid
flowchart TB
  subgraph repo["Sagittarius: one repo"]
    subgraph g_sagittarius["sagittarius (module)"]
      p_covers_prompt["prompt/ (covers)"]
      p_prompt_main["the prompt (SAGITTARIUS.md)"]
      p_prompt_panes["pane prompts (PANES.md, panes/)"]
    end
    subgraph g_orbit_kb["orbit-kb (module)"]
      p_covers_kb_bin["kb/bin/ (covers)"]
      p_covers_kb_share["kb/share/ (covers)"]
      p_orbit_tool["orbit-kb and orbit (the tool)"]
      p_repo_map["repo-map"]
      p_core_pl["core.pl (record kinds, verdict rules)"]
      p_kb_modules["modules build, discovery, project"]
      p_desk_page["the Desk page (desk.js, desk.css)"]
    end
    subgraph g_system_1["system-1 (module)"]
      p_covers_s1["s1/ (covers)"]
      p_s1_record["System 1 record and proposals"]
      p_s1_jev["System 1 judge (jev)"]
    end
    subgraph g_mindhole_kit["mindhole-kit (module)"]
      p_covers_hubkit["hubkit/ (covers)"]
      p_hub_template["the hub template (hubkit/hub)"]
      p_ledger_engine["the ledger engine (hubflow.py)"]
      p_desk_py["the Desk letters (desk.py)"]
      p_store_map["the store map (store-facts.json)"]
      p_hubkit_py["install and upgrade (hubkit.py)"]
    end
    subgraph g_s1_glance["s1-glance (module)"]
      p_covers_s1_glance["s1/glance/ (covers)"]
      p_s1_glance["s1-glance skill"]
    end
    subgraph g_desk_toast["desk-toast (module)"]
      p_covers_hubkit_hub__claude_scripts_desk_toast["hubkit/hub/.claude/scripts/desk-toast/ (covers)"]
      p_desk_toast["desk-toast plugin"]
    end
  end
  subgraph outside["Outside the repo"]
    subgraph mh["a mindhole: the seven stores"]
      store_spec["store spec"]
      store_project["store project"]
      store_ledger["store ledger"]
      store_memory["store memory"]
      store_weeks["store weeks"]
      store_bespoke["store bespoke"]
      store_tracker["store tracker"]
    end
    o_install_links["install links in ~ (~/.claude, ~/.local)"]
    o_sidequest_mindhole["sidequest-mindhole (a hub)"]
    o_hwh_mindhole["hwh-mindhole (a hub)"]
    o_desk_state["Desk state (letters, drafts)"]
    o_gitea["Gitea ty/sagittarius (origin)"]
    o_github["GitHub theTyster/sagittarius"]
    o_s1_model["the System 1 model (jev)"]
    o_claude_code["Claude Code (runs sessions, hooks)"]
  end
```

## Flow view

```mermaid
sequenceDiagram
  participant human as the human (Ty) (outside)
  participant session as a session (the prompt) (sagittarius)
  participant tool as the orbit tool (orbit-kb)
  participant speckb as the spec KB (kb.pl) (orbit-kb)
  participant ledger as the ledger (flow.db) (mindhole-kit)
  participant desk as the Desk (orbit-kb)
  participant s1 as System 1 (system-1)
  participant tracker as the tracker (outside)
  human-)session: s01 carry request: states the request in a session
  tracker-->>tool: s02 read request: orbit pin-request: the ticket text
  tool->>speckb: s03 write request: orbit init: request(R, Text)
  Note over speckb: store map: the tracker owns request
  tool->>speckb: s04 write goal: orbit add goal: goal/4
  tool->>speckb: s05 write hypothesis: orbit add hypothesis: hypothesis/4
  tool->>speckb: s06 write premise: orbit add premise: premise/3
  tool->>speckb: s07 write question: orbit add question: question/3, option/3
  speckb-->>desk: s08 read question: the Desk shows open questions
  human-)desk: s09 carry answer: answers: POST /answer
  desk->>speckb: s10 write answer: answer/3 (the human's words)
  tool->>speckb: s11 write claim: orbit add claim: claim/3, example/2
  tool->>speckb: s12 write check: orbit add check: check/2, procedure/2
  Note over speckb: store map: the tracker owns checks
  speckb-->>s1: s13 read goal/hypothesis/claim: orbit s1-record --json
  s1->>speckb: s14 write proposal: orbit propose --from system1: proposed/2
  human-)desk: s15 carry vote: votes GO, NO-GO or HOLD
  desk-)session: s16 carry vote/letter: a letter (letters.jsonl), given by the hook
  tool->>speckb: s17 write vote: orbit attest: vote by human
  session->>ledger: s18 write handoff: orbit hub ledger handoff
  ledger-->>session: s19 read handoff: inbox (v_inbox), then accept
  human-)desk: s20 carry adoption: adopts a hypothesis on the Desk
  desk->>speckb: s21 write adoption: attest adoption by human
  tool->>speckb: s22 write adoption: orbit adopt (the human's words)
  tool->>speckb: s23 write run: orbit run K -- CMD: attest test_result
  speckb-->>tool: s24 derive verdict: verdict/2 derived from each run
  tool-->>session: s25 read request/goal/hypothesis/premise/check/run/verdict: orbit report, orbit show open
  speckb-->>ledger: s26 read claim/check/run: query blocking(X) before an item closes
  human-)desk: s27 carry judgment: chooses satisfied or not satisfied
  desk->>speckb: s28 write judgment/letter: POST /send: letter first, then attest judgment
  tool->>speckb: s29 write judgment: orbit judge (the human's words)
  speckb-->>desk: s30 read judgment: the Desk shows the judgments of a goal
  speckb-->>tool: s31 read judgment: experiment/3, verdict/2 of the judgment
  tool-)tracker: s32 carry check: orbit draft: a staged edit, a human sends
```

## Sources of the arrows

| step | kinds | verb | from | to | what | sources (file, kind, name) |
|---|---|---|---|---|---|---|
| s01 | request | carry | human | session | states the request in a session | `prompt/SAGITTARIUS.md text ## The ticket` |
| s02 | request | read | tracker | tool | orbit pin-request: the ticket text | `kb/bin/orbit-kb kb_cmd pin-request`<br>`kb/share/orbit-kb/core.pl decl request_pin` |
| s03 | request | write | tool | speckb | orbit init: request(R, Text) (store map: the tracker owns request) | `kb/bin/orbit-kb pred cmd_init`<br>`kb/share/orbit-kb/core.pl decl request` |
| s04 | goal | write | tool | speckb | orbit add goal: goal/4 | `kb/bin/orbit-kb kb_cmd add`<br>`kb/bin/orbit-kb pred cmd_add`<br>`kb/share/orbit-kb/core.pl decl goal` |
| s05 | hypothesis | write | tool | speckb | orbit add hypothesis: hypothesis/4 | `kb/bin/orbit-kb pred cmd_add`<br>`kb/share/orbit-kb/core.pl decl hypothesis` |
| s06 | premise | write | tool | speckb | orbit add premise: premise/3 | `kb/bin/orbit-kb pred cmd_add`<br>`kb/share/orbit-kb/core.pl decl premise` |
| s07 | question | write | tool | speckb | orbit add question: question/3, option/3 | `kb/bin/orbit-kb pred cmd_add`<br>`kb/share/orbit-kb/core.pl decl question` |
| s08 | question | read | speckb | desk | the Desk shows open questions | `kb/bin/orbit-kb route get /`<br>`kb/bin/orbit-kb pred serve_answer_term` |
| s09 | answer | carry | human | desk | answers: POST /answer | `kb/bin/orbit-kb route post /answer` |
| s10 | answer | write | desk | speckb | answer/3 (the human's words) | `kb/bin/orbit-kb pred serve_answer_kb`<br>`kb/share/orbit-kb/core.pl decl answer` |
| s11 | claim | write | tool | speckb | orbit add claim: claim/3, example/2 | `kb/bin/orbit-kb pred cmd_add`<br>`kb/share/orbit-kb/core.pl decl claim` |
| s12 | check | write | tool | speckb | orbit add check: check/2, procedure/2 (store map: the tracker owns checks) | `kb/bin/orbit-kb pred cmd_add`<br>`kb/share/orbit-kb/core.pl decl check` |
| s13 | goal/hypothesis/claim | read | speckb | s1 | orbit s1-record --json | `kb/bin/orbit-kb pred cmd_s1_record`<br>`s1/record.py def fetch` |
| s14 | proposal | write | s1 | speckb | orbit propose --from system1: proposed/2 | `s1/record.py def propose`<br>`kb/bin/orbit-kb kb_cmd propose`<br>`kb/share/orbit-kb/core.pl decl proposed` |
| s15 | vote | carry | human | desk | votes GO, NO-GO or HOLD | `kb/bin/orbit-kb pred desk_kb_action` |
| s16 | vote/letter | carry | desk | session | a letter (letters.jsonl), given by the hook | `hubkit/hub/.claude/scripts/desk.py def cmd_send`<br>`hubkit/hub/.claude/scripts/desk.py def run_hook` |
| s17 | vote | write | tool | speckb | orbit attest: vote by human | `kb/bin/orbit-kb pred cmd_attest`<br>`kb/share/orbit-kb/modules/discovery.pl attest_type vote` |
| s18 | handoff | write | session | ledger | orbit hub ledger handoff | `hubkit/hub/.claude/scripts/hubflow.py def cmd_handoff` |
| s19 | handoff | read | ledger | session | inbox (v_inbox), then accept | `hubkit/hub/.claude/scripts/hubflow.py def cmd_accept`<br>`hubkit/hub/.claude/scripts/hubflow.py text v_inbox` |
| s20 | adoption | carry | human | desk | adopts a hypothesis on the Desk | `kb/bin/orbit-kb pred desk_plan_adopt` |
| s21 | adoption | write | desk | speckb | attest adoption by human | `kb/bin/orbit-kb pred desk_effect`<br>`kb/share/orbit-kb/core.pl attest_type adoption` |
| s22 | adoption | write | tool | speckb | orbit adopt (the human's words) | `kb/bin/orbit-kb kb_cmd adopt`<br>`kb/bin/orbit-kb pred cmd_adopt` |
| s23 | run | write | tool | speckb | orbit run K -- CMD: attest test_result | `kb/bin/orbit-kb kb_cmd run`<br>`kb/bin/orbit-kb pred cmd_run`<br>`kb/share/orbit-kb/core.pl attest_type test_result` |
| s24 | verdict | derive | speckb | tool | verdict/2 derived from each run | `kb/share/orbit-kb/core.pl pred verdict`<br>`kb/share/orbit-kb/core.pl pred experiment` |
| s25 | request/goal/hypothesis/premise/check/run/verdict | read | tool | session | orbit report, orbit show open | `kb/bin/orbit-kb kb_cmd report`<br>`kb/bin/orbit-kb pred cmd_report` |
| s26 | claim/check/run | read | speckb | ledger | query blocking(X) before an item closes | `hubkit/hub/.claude/scripts/hubflow.py def query_blocking`<br>`kb/share/orbit-kb/core.pl pred blocking` |
| s27 | judgment | carry | human | desk | chooses satisfied or not satisfied | `kb/bin/orbit-kb pred desk_judge_forms` |
| s28 | judgment/letter | write | desk | speckb | POST /send: letter first, then attest judgment | `kb/bin/orbit-kb route post /send`<br>`kb/bin/orbit-kb pred desk_plan_judge`<br>`kb/share/orbit-kb/core.pl attest_type judgment` |
| s29 | judgment | write | tool | speckb | orbit judge (the human's words) | `kb/bin/orbit-kb kb_cmd judge`<br>`kb/bin/orbit-kb pred cmd_judge` |
| s30 | judgment | read | speckb | desk | the Desk shows the judgments of a goal | `kb/bin/orbit-kb pred desk_judgments_html` |
| s31 | judgment | read | speckb | tool | experiment/3, verdict/2 of the judgment | `kb/share/orbit-kb/core.pl pred experiment` |
| s32 | check | carry | tool | tracker | orbit draft: a staged edit; a human sends | `kb/bin/orbit-kb kb_cmd draft`<br>`kb/share/orbit-kb/modules/project.pl decl draft` |

## Sources of the boxes

| box | source |
|---|---|
| `group:sagittarius` | `MODULES.json json sagittarius` |
| `part:covers:prompt` | `MODULES.json json prompt` |
| `part:prompt_main` | `prompt/SAGITTARIUS.md file prompt/SAGITTARIUS.md` |
| `part:prompt_panes` | `prompt/panes file prompt/panes` |
| `group:orbit-kb` | `MODULES.json json orbit-kb` |
| `part:covers:kb/bin` | `MODULES.json json kb/bin` |
| `part:covers:kb/share` | `MODULES.json json kb/share` |
| `part:orbit_tool` | `kb/bin/orbit-kb file kb/bin/orbit-kb` |
| `part:repo_map` | `kb/bin/repo-map file kb/bin/repo-map` |
| `part:core_pl` | `kb/share/orbit-kb/core.pl file kb/share/orbit-kb/core.pl` |
| `part:kb_modules` | `kb/share/orbit-kb/modules file kb/share/orbit-kb/modules` |
| `part:desk_page` | `kb/share/orbit-kb/desk file kb/share/orbit-kb/desk` |
| `group:system-1` | `MODULES.json json system-1` |
| `part:covers:s1` | `MODULES.json json s1` |
| `part:s1_record` | `s1/record.py file s1/record.py` |
| `part:s1_jev` | `s1/jev.py file s1/jev.py` |
| `group:mindhole-kit` | `MODULES.json json mindhole-kit` |
| `part:covers:hubkit` | `MODULES.json json hubkit` |
| `part:hub_template` | `hubkit/hub/CLAUDE.md file hubkit/hub/CLAUDE.md` |
| `part:ledger_engine` | `hubkit/hub/.claude/scripts/hubflow.py file hubkit/hub/.claude/scripts/hubflow.py` |
| `part:desk_py` | `hubkit/hub/.claude/scripts/desk.py file hubkit/hub/.claude/scripts/desk.py` |
| `part:store_map` | `hubkit/tools/store-facts.json file hubkit/tools/store-facts.json` |
| `part:hubkit_py` | `hubkit/tools/hubkit.py file hubkit/tools/hubkit.py` |
| `group:s1-glance` | `MODULES.json json s1-glance` |
| `part:covers:s1/glance` | `MODULES.json json s1/glance` |
| `part:s1_glance` | `s1/glance file s1/glance` |
| `group:desk-toast` | `MODULES.json json desk-toast` |
| `part:covers:hubkit/hub/.claude/scripts/desk-toast` | `MODULES.json json hubkit/hub/.claude/scripts/desk-toast` |
| `part:desk_toast` | `hubkit/hub/.claude/scripts/desk-toast/hooks/core.ts file hubkit/hub/.claude/scripts/desk-toast/hooks/core.ts` |
| `store:spec` | `hubkit/tools/store-facts.json json spec` |
| `store:project` | `hubkit/tools/store-facts.json json project` |
| `store:ledger` | `hubkit/tools/store-facts.json json ledger` |
| `store:memory` | `hubkit/tools/store-facts.json json memory` |
| `store:weeks` | `hubkit/tools/store-facts.json json weeks` |
| `store:bespoke` | `hubkit/tools/store-facts.json json bespoke` |
| `store:tracker` | `hubkit/tools/store-facts.json json tracker` |
| `outside:install_links` | `MODULES.json json installs` |
| `outside:sidequest_mindhole` | `hubkit/hub/.claude/scripts/desk.py def cmd_join` |
| `outside:hwh_mindhole` | `hubkit/hub/.claude/scripts/desk.py def cmd_join` |
| `outside:desk_state` | `hubkit/hub/.claude/scripts/desk.py def state_dir` |
| `outside:gitea` | `.git remote origin` |
| `outside:github` | `hubkit/README.md text github.com/theTyster/sagittarius` |
| `outside:s1_model` | `s1/jev.py text DEFAULT_MODEL =` |
| `outside:claude_code` | `hubkit/hub/.claude/scripts/desk.py def cmd_hooks` |
| `lane:human` | `prompt/SAGITTARIUS.md text ## Who judges what` |
| `lane:session` | `prompt/PANES.md text review` |
| `lane:tool` | `kb/bin/orbit-kb pred kb_cmd` |
| `lane:speckb` | `kb/share/orbit-kb/core.pl pred record_step` |
| `lane:ledger` | `hubkit/hub/.claude/scripts/hubflow.py def query_blocking` |
| `lane:desk` | `kb/bin/orbit-kb pred serve_act` |
| `lane:s1` | `s1/record.py def fetch` |
| `lane:tracker` | `kb/bin/orbit-kb pred cmd_pin_item` |

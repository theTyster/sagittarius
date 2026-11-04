# orbit-kb contract (v2.1, 2026-10-15)

Files cited here under `thoughts/` are in git history, at the tag `thoughts-archive`
(`git show thoughts-archive:thoughts/<file>`). Their paths are from the dotfiles repository.

**Changes in v2.1** (sent to the builders while they work):

- **D1.** `test_result` and the rules `passed/1`, `failed_after/2`, and `was_red/1` move
  from the build module to the core. A runnable reproduction is a check in both orbits.
- **D2.** E6 (non-ground fact) applies only to facts in `kb.pl`. E7 now means "a clause
  in the wrong place":
  - a `rule` predicate asserted as a fact in `kb.pl`; or
  - a `fact` predicate that has clauses outside `kb.pl` (in core, modules, or
    `rules.pl`).

  In library files and in `rules.pl`, unit clauses for `rule` predicates are allowed, and
  they may be non-ground.
- **D3.** `subject/3` paths:
  - `orbit-kb subject` stores the path relative to the KB directory when the file is
    inside the KB directory tree. Otherwise it stores the absolute path.
  - Every reader resolves a relative path against the KB directory. Readers are W1,
    `digest(current)`, and refresh.

  This keeps fixtures and KBs portable.
- **D4.** `report/1` and `calibration` are no longer reserved by discovery.
- **D5.** `to_ask/1` asks only questions whose claim is still current. Without this, the
  questions of a superseded claim stay open forever, and `done` can never hold.
  `any_to_ask/0` moves from build to core.
- **D8 (grounded cross-check, 2026-10-16).** Superseded by D20. Root cause and evidence:
  `/tmp/claude-1000/-home-ty--dotfiles/63a00f00-8d72-4aeb-a216-cde6b882f1f4/scratchpad/perf/scasp-agent/RESULTS.md`
  (the session scratchpad, so it may be gone).
  - **Default.** s(CASP) runs on a query-relevant grounding of the assembled program.
    `ORBIT_KB_SCASP_GROUND=raw` runs the assembled program unchanged. The SWI verdict
    engine always runs the original, ungrounded program.
  - **The grounding** contains:
    - every rule instance that is reachable from the query and whose positive body can
      hold, with the `not` literals ignored for reachability but their atoms grounded
      too;
    - builtins, evaluated while grounding;
    - for each ground head that has a facts-only instance, that instance alone;
    - all facts, unchanged, so that `why` still names the attestation ids;
    - stubs for predicates that have no clauses;
    - the `#pred` lines.
  - **Fallback.** For an unsupported form, the grounder uses the raw program and prints
    `NOTE: s(CASP) ran the raw program: <reason>` on stderr. The unsupported forms are a
    `not` over a free variable, constraints, `forall`, clpq, `;`, `->`, a program that is
    not stratified, and an instance that stays non-ground. Grounding that takes more than
    5 s gets the same fallback. Answers never depend on whether grounding succeeded.
  - **Relevance trimming.** The grounding keeps only facts that match an atom reachable
    from the query, plus all `p` and `-p` facts when the program has `-p` clauses.
    Matching ignores a trailing `_<digits>`, as the s(CASP) reader does. Stubs and `#pred`
    lines follow the emitted program. `why` and `whynot` output is unchanged.
  - **Cross-check cap.** On a grounded program, the M+1 cross-check run may ask for up
    to 100 models. A raw program keeps the cap of 10.
  - **Hazards.** In ground mode, H2 and H3 cannot occur, because no dual contains a
    `forall`. H4 still causes a disagreement when a merged atom is under `not` or in a
    binding. The negative controls therefore work as follows:
    - The H2 and H3 controls under `--forall=all` that must report ENGINE DISAGREEMENT
      run with `ORBIT_KB_SCASP_GROUND=raw`.
    - In ground mode, the same programs under `--forall=all` must give the correct
      answer with no disagreement.
    - `doctor` keeps its known-answer tests (H1–H4) in ground mode.
    - `doctor` runs the "H4 raw atoms must disagree" control in raw mode.
    - `doctor` adds the ground-mode H4 control: `p(order_4417).` and
      `q :- not p(order_5120).` must disagree, with E13 bypassed.
    - `doctor` adds a grounder-corruption control: delete one `failed_after` instance
      from the grounded H3 program. s(CASP) then also answers k1, and the cross-check must
      report ENGINE DISAGREEMENT.
- **D7 (review fixes, 2026-10-16).** (The cross-check and E13 parts are superseded by D20.)
  - `query`, `why`, `whynot`, `show`, and `report` exit 2 before they answer in two
    cases: when any KB or rules file has a syntax error (E1), and when `rules.pl` has an
    undeclared head or body predicate (E2). A broken source never yields a quiet "false".
  - **Unsafe negation.** The SWI translation moves each `not` literal after all of the
    positive body literals. Builtins stay in place relative to the positive literals. In
    a stratified program this does not change the answers, and it stops `\+` from
    floundering on unbound variables. Lint error **E14** flags a `not` literal whose
    variable occurs in the head but in no positive body literal (unsafe negation).
  - The cross-check asks s(CASP) for M+1 models, up to the cap, when SWI found M
    answers. If s(CASP) returns more answers than SWI, the result is ENGINE DISAGREEMENT.
  - `run`, `attest`, `add`, `declare`, `subject`, and `uses` (D11) hold an exclusive lock
    (`flock` on `kb.lock` in the KB directory) for the whole cycle: read, choose the id
    or run number, write the log with an exclusive create, and append. The `subject`
    rewrite writes a temp file in the same directory and renames it into place.
  - E13 also checks string values.
  - Temp files are created with `tmp_file_stream/3`.
- **D9 (discovery delivery, 2026-10-19).** `modules/discovery.pl` replaces the placeholder,
  with the fixture `scripts/orbit-kb/fixtures/discovery-a/`. The reserved discovery names
  are updated below. Open requests: a lint warning for a stale approval (LM21); a way to
  record a digest without typing it (F5); a `report_section/3` hook for `report` and
  `show open`. `--by human` is a claim the CLI cannot verify (LM20).
- **D21 (a visual claim flares, 2026-11-04).** GitHub issue #9. Decision by Ty ("Both"). A burn closes with a Lean proof; some claims are a look, a layout, or a name, and only a human who sees the result can close them. Before D21, a renamed alias was recorded as a second divergence, its claim burned, and `done` waited for a Lean proof of an alias name. Mnemonic: burns get proved, flares get shown. The changes, all in `modules/build.pl`:
  - F1: new facts `visual(ref(claim))` (the agent marks it at DECOMPOSE, or a human asks for it) and `demo(ref(subject), ref(claim))` (a screenshot or a recording, recorded with `orbit-kb subject`, shows the claim).
  - F2: `flare(C)` holds when C is visual, or when C replaces a visual claim through one or more `supersedes` steps, as an inherited burn does. A claim can burn and flare at once: prove the invariant, show the look.
  - F3: `flare_shown(C)` holds when a human `approval` of a demo of C names the current digest of the demo subject. A new screenshot under the same subject id makes the approval stale, and the flare opens again.
  - F4: `flare_waived(C)` reads the same waiver as `burn_waived(C)`: `waive(C, Due, Text)` by a human, not lapsed. A due time is required, as for a burn. One waiver on a claim that burns and flares closes both (builder's choice: the waiver shape names a claim, not a kind of escalation).
  - F5: `flare_open(C) :- flare(C), current(C), not flare_shown(C), not flare_waived(C).` `done` also needs `not any_flare_open`.
  - F6: a visual claim does not burn because it was contested twice: `burn_reason(C) :- contested_twice(C), not visual(C).` Contests on a visual claim escalate to its flare. `universal` and `burn_requested` still make a visual claim burn.
  - F7: `show open` lists `- flare_open C: claim C needs a human to approve a demo.` `report` lists `**flare open**` items (page: `data-open="flare_open"`), and a claim with a flare gets a `Flare: S.` part after `Burn:`: `shown` (with the demo subject), `NOT SHOWN` with "A human waived the demo until DUE.", or `NOT SHOWN` with "A human must approve a demo of it.". A lapsed waiver of a claim names the proof, the demo, or both. A claim with a flare is never one line in the report text, so the demo always shows.
  - F8: E16 protects `flare`, `flare_shown`, `flare_waived`, `flare_open`, and `any_flare_open`.
  - The Lean burn model (`kb/tests/burn_model`) does not model flares. Its generated KBs have no `visual` or `demo` facts, so its conformance runs still apply; `check.sh` mutates the new text of `done`.
  - Tests added: FL1 to FL10.
- **D20 (SWI-Prolog is the only engine, 2026-11-02).** Decision by Ty ("option 2"): drop s(CASP) and keep SWI-Prolog as the only engine. Reasons from two read-only audits: every rule is stratified; the code that only s(CASP) used was about 1,430 lines (about 23% of the CLI); in 17 real client-project sessions `why` had 0 calls and `whynot` about 20 (all of the kind "what blocks done or discovery_ready"); ENGINE DISAGREEMENT happened 0 times and CROSS-CHECK SKIPPED once (a timeout); in the git history every disagreement was a tool bug and never an error in the KB logic. The changes:
  - C1, gone: the `scasp` binary and its pack; the grounder (D8); the cross-check, ENGINE DISAGREEMENT, CROSS-CHECK SKIPPED, `(unchecked)`, and `NOTE: s(CASP) ran the raw program`; the s(CASP) result cache; the variables `ORBIT_KB_SCASP_FLAGS`, `ORBIT_KB_SCASP_TIMEOUT`, and `ORBIT_KB_SCASP_GROUND`; the hazards H1 to H4; lint E12 and E13; `query --json` and `query --html` (both are now usage errors); the `contradicts` verdict of `whynot`; classical negation `-p`; the reserved names `proved`, `chs`, `assume`, and `abduced`; in the report page, `data-crosscheck` and the `disagreement` open item. `report --html` always exits 0 when it writes the page. Its "done: yes/no" chip comes from the SWI verdict.
  - C2, negation: `not p` is negation as failure. `not under(_)` means "no under at all", so a rule needs no helper for it. The core rules keep their helper forms.
  - C3, explanations: `why` and `query --why` print each answer, then the clauses that prove it: "X, because", with indented reasons, and "there is no evidence that X" for a `not` literal. `whynot GOAL` prints `holds` or `absent`. For `absent`, it prints, for each rule of GOAL, the first body literal that no answer gets past ("the rule for done/0 stops at not any_under:") and why, recursively. It prints "nothing records X: no fact or rule matches it" when nothing matches. The depth is 6 levels, and `--long` gives 30. An explanation never changes a verdict.
  - C4, E17: classical negation `-p` (a fact or rule head, or a body literal), a `#` line, a global constraint `(:- Body)`, or a `#=`-family constraint. `add` refuses them. It applies in `kb.pl` too, and a goal with such a form exits 2 with the E17 text. `query`, `why`, `whynot`, `show`, and `report` exit 2 while an E17 exists (the answer gate, as for E1 and E2 in D7).
  - C5, E18: rules that are not stratified (a predicate depends on itself through `not`). The same answer gate applies. Before, SWI hit its stack limit on `p :- not q. q :- not p.`. When a `rules.pl` clause closes a cycle through a `not` in the core or a module, E18 names that `rules.pl` clause too.
  - C6: E11 means only "a clause does not load in the SWI engine". The text of E14 says "A call with X unbound then gives a wrong answer".
  - C7: `doctor` checks `swipl` and the library, then runs SWI known-answer self-tests: the helper form is false; `not under(_)` is false when `under(a)` holds; arithmetic under `not` gives exactly k2, k3, k4; E18 flags `p :- not q, q :- not p`; E17 flags `-p(b)`.
  - C8, unchanged: the saved-state fast start (the owner keeps it: a fix of the cache race, GitHub issue #4, must keep it), the schema and the types, the digests, the run logs, `prove`, the text of `report`, `rules.pl`, and `done` and every rule in the core and the modules.
  - Tests added: X1 to X10, WN1 to WN5, E17, A13, DR1, DR2, HP1, HP2. Q8 and Q9 now check that `--json` and `--html` are usage errors. Tests removed: H3b, H3d, X2g, the old X10, GU, the E11 fixture test, E12, E13, E13s, A18, A19, BP14, RH9, DR4.
- **D19 (report Open shows what blocks discovery, 2026-10-30).** In a discovery KB, `report` printed "Nothing is open" while a raised question waited for the human, a current claim was refuted, or `discovery_ready` failed. A delivery drafted from it claimed that nothing was open. Now, when the discovery module is loaded, Open also lists each `question_waits(Q)` that is not already a `to_ask` item ("waits"), each current refuted claim ("refuted": record the counterexample and ask the human, do not weaken the claim), and, when `discovery_ready` fails, one "not ready" item that points to `orbit-kb whynot 'discovery_ready'` and `orbit-kb lint`. "Nothing is open" is printed only when none of these holds. `show open` does not change. Test RP7; the discovery report golden changes by that one item.
- **D18 (attest model_result checks the log, 2026-10-30).** A `model_result` could name any result for a solver log, so a verdict of `holds` could sit on a log that says the invariant is violated. `orbit-kb attest model_result LOG 'PRED'` now reads the file of subject LOG (the path from `subject/3`) for a `verdict(M, Kind, Result)` or a `mutation(M, Rule, Result)`. `calibration` is never checked. It guards an honest mistake: a false refusal is worse than a miss, so it refuses only on a clear contradiction. The choices:
  - C1: a TLC log is `violated` when a line holds `is violated` and no line holds `No error has been found`, and `holds` in the reverse case. A TLC log with neither phrase, or with both, is unclassified. A z3 or cvc5 log is read as the set of lines that are exactly `sat`, `unsat`, or `unknown` (trimmed): one distinct value is the class, several values or none is unclassified.
  - C2: the log shows a case when it is TLC-violated or `sat`, and no case when it is TLC-holds or `unsat`. The results `reached`, `violated`, `sat`, and mutation `killed` (the bad case returned) claim a case. The results `holds`, `unsat`, and mutation `survived` claim no case. A result that claims what the log does not show is refused. The result `unknown` is never refused.
  - C3: a refusal exits 1 with nothing written. The message says what the log shows and the fix: attest the result the log shows, or run the solver again into a new log.
  - C4: when the log file is missing or unreadable, the subject has no path, or the log is unclassified, the result is accepted as before and stderr has `NOTE: the log was not checked: ...`.
  - C5: a KB edited by hand is not checked, and `lint` does not read logs. Tests: LG1 to LG3.
- **D17 (done needs a current claim, 2026-10-29).** Issue #1: in a build KB with no claim, `done` held, `lint` was clean, and `report` said "A human answered every question with a default." when no question existed. A ticket with nothing in it counted as finished. Both engines agreed then, so the cross-check could not find it: the fault was in the rule. The changes:
  - C1: `modules/build.pl` adds `any_current_claim :- current(_).` and `no_current_claim :- not any_current_claim.`, and `done` gets one more literal: `done :- not any_under, not any_over, not any_to_ask, not any_burn_open, not any_supersede_cycle, not no_current_claim.` `done` negates `no_current_claim`, and does not call `any_current_claim` directly, so that `whynot done` can explain the case in the grounded program (D8 kept no rule instance whose positive body cannot hold; superseded by D20, but the rule text stays). No variable occurs only under `not`.
  - C2: `whynot done` on a KB with no current claim starts with `absent`, and its explanation names the missing claim: `no claim is current`, because `there is no evidence that some claim is current`.
  - C3: `any_current_claim` is protected (E16): a `rules.pl` clause for it is E16, and the engines ignore it.
  - C4: `report`, with the `build` module and no current claim, has the open item `**no claim**: No claim is current`, with `Add a claim. The work is not done without one.` nested. Its page hook is `data-open="no_claim"`. `show open` prints `- no_claim: no claim is current. Add a claim. The work is not done without one.` In both, `Nothing is open.` is not printed then.
  - C5: `Guesses:` says `None. A human answered every question with a default.` only when at least one `assumed/2` fact exists. With no question that has a default, it says `None. No question has a default.` `Not checked:` with no current claim says `None. No claim is current.` The golden report texts change only in these lines.
  - C6: discovery does not change. `discovery_ready` already needs `some_hypothesis`, `touched_system`, and `discovery_has_outcome` (a current claim, or a hypothesis that was not reproduced), so an empty discovery KB is not ready, and its `artifact_vote` is `hold`. A ready KB with no current claim still votes `no_go` (VT3).
  - C7: the Lean burn model (`kb/tests/burn_model`) adds LR13 (`done` implies a current claim), a hypothesis of LR2, the witness W17 (no claim, not `done`), a current plain claim in W7, the KBs `z1` and `z2` (no claim) in the conformance set, and the mutant MZ (`done` without `not no_current_claim`).
  - Tests: NC1 to NC5.
- **D16 (the delivery report as a page, 2026-10-28).** Request by Ty: the close-out text "is not very readable", so orbit-kb writes the report as a page to read in a browser, "with a few UX offerings to help the review process". Choices made by the builder:
  - P1: `report --html FILE` writes one self-contained HTML page (CSS and script inline; no network, CDN, font, or build step; it works from `file://`). It prints the same text on stdout as `report`, and `HTML written to FILE` on stderr. A file that cannot be written exits 2. The text on stdout is the plain `report` text, byte for byte (fixtures `report_golden/*.txt`). C4 changed that text on the same day; the golden files were made again from the CLI after C4 and read by eye.
  - P2: one source. `report` records each line it prints with its item. The page is built from those records, so it shows the same items and the same status sentences, and no script derives a status. The page adds evidence that the text leaves out, read from facts: per claim its citations, examples, checks (state, latest run number, result, time, and `runs/N-CHECK.log`), divergences with their notes, disclosures about the claim or its questions, waivers of the claim or its checks (due time, reason, state), questions, and notes.
  - P3: open items come first, in a section before the claims: each `under` claim, then each line of `Open:` (questions to ask, stale approvals, supersede cycles, `over` changes, open burns, lapsed waivers, proofs that no longer count), then engine disagreements. Superseded by D20: the page has no cross-check and no `disagreement` item. (Old text: the report text never runs s(CASP), so for the page the CLI cross-checks `done`, `under(X)`, `burn_open(X)`, and `to_ask(X)` (only `to_ask(X)` without build). A disagreement is an open item, and it is printed on stderr as by `query`; then the exit is 2, after the page is written. A s(CASP) timeout is shown as "not cross-checked".)
  - P4: review marks. Each claim, guess, disclosure, waiver, and open item has the marks `ok`, `doubt`, and `wrong`, and a short note. Items with the same id share one mark. One button writes the marks as plain text, one line per marked item (`c1: doubt - the note`), after a first line that names the KB and the report digest. It copies the text when the browser allows it, and it always shows the text in a selectable textarea. The page cannot write to the KB. It keeps the marks in `localStorage`, under the KB path and the digest of the report text; every access is inside `try`.
  - P5: escaping. Every KB string in the page is HTML-escaped (`& < > " '`). Notes are set as text by the script.
  - P6: `--open` (only with `--html`) runs `xdg-open`, or `open` when there is no `xdg-open`, on the page, and does not wait. Without `--open`, nothing is opened.
  - P7: page hooks, for the tests: `data-section` (`open`, `claims`, `guesses`, `disclosures`, `waivers`, `not_checked`, `vote`, `text`); per claim `<article data-claim="C" data-status="S">` on one line, where S is `fulfilled`, `under`, `waived` (a waived check), or `none` (no build module), with S also as a text label; `data-check="K" data-run="N|none" data-result="pass|fail|none"`; per open item `data-open="KIND" data-ref="ID"` (KIND: `under`, `to_ask`, `stale`, `supersede_cycle`, `over`, `burn_open`, `flare_open` (D21), `waiver_lapsed`, `proof_changed`; D20 removed the KIND `disagreement` and `data-crosscheck`); `data-mark`; `<body data-kb="KB DIR" data-digest="sha256:…">`; `id="review-copy"` and `<textarea id="review-text">`.
  - C4 (the layout of the text, 2026-10-28). Request by Ty: "better headings and new spacing for the default output", "probably even more than the html report"; the goal for the text and the page is readability. This replaces the old claim that the text stays as it is. The text is plain Markdown that also reads as raw text: no colour codes, no tabs, no box-drawing characters, no trailing spaces.
    - L1: each section has the heading `# Name:` (`Delivered`, `Claims`, `Guesses`, `Disclosures`, `Waivers`, `Not checked`, `Open`, `Vote`, `To land`; the same order and conditions as before), and one blank line separates two sections. There is no blank line before the first heading and none after the last line.
    - L2: each item is a bullet `- ` indented by two spaces. A nested bullet adds two spaces for each level. The label is in `**bold**`: the kind of a claim (`c1 **introduce**: text`), the kind of a disclosure (`a1 **unverified**: text`; a disclosure that is not `kind(arg)` has no label), the state of a waiver (`w1 **in force**`, `**lapsed**`, or `**ignored**` when a human did not write it), and the kind of an open item (`**ask**`, `**stale**`, `**cycle**`, `**over**`, `**burn open**`, `**flare open**` (D21), `**waiver lapsed**`, `**proof changed**`).
    - L3: a claim is one line (`c1 **introduce**: text. Status: fulfilled. Checks: k1 (passed).`) when it is fulfilled (or the KB has no build module), its burn is proved or absent, it has no flare (D21), it has at least one check, every check passed, and the line fits in 100 columns. Any other claim (under, a waived check, a burn that is not proved, a check that did not pass or never ran, no check, a long line) is its text, with nested bullets: `Status: S.` with its detail sentence nested under it, `Burn: B.` with its detail nested, `Flare: F.` with its detail nested (D21), and `Checks: k (state).`; with two checks or more, `Checks:` has one nested bullet per check. The status words are the same as before, and the same as the words on the page. The text of a claim is never wrapped.
    - L4: the other sections use the same shapes: a guess is `q1: question` with `The default is D. No human answered it.` nested; a disclosure has `About S, by B.` nested; a waiver that has lapsed or does not count has its sentence nested; a claim that is not checked has `It has no check.` nested; an open item and a line of `Vote:` are the first sentence as the bullet (without its final period), and the other sentences nested. Placeholders (`(Write what you delivered here.)`, `(Write the steps to land the work here.)`) and the `None.` and `Nothing is open.` lines stay one bullet each.
    - L5: `report --html FILE` prints this same text on stdout (RH1). The page is still built from the records of the report, so it shows the same status words, and it keeps RH2 to RH9. The page prints a sentence for a guess or a claim that is not checked with a final period, so that it does not run into the next one.
    - Tests: RL1 to RL7. RP1 to RP6, VT6, BP8, WV8 read the new layout. The golden files are made again from the CLI and checked by eye.
  - Out of scope: the light path (no KB). `Delivered:` and `To land:` stay placeholders in the text, and the page leaves them out.
  - Tests: RH1 to RH9.
- **D15 (reword a hypothesis; W5 asks for a new check, 2026-10-27).** Decision by Ty: no new command and no new attestation type for what is a small reword. Choices made by the builder:
  - R1: `supersedes` takes two claims, or two hypotheses. Its declaration is `supersedes(ref, ref)`: core cannot name the discovery fact `hypothesis/3` in a type, and `ref([claim, hypothesis])` is E3 without the module. The CLI checks the kinds. A side that is an existing id but no claim and no hypothesis is E4. A claim and a hypothesis in one fact is E4, and the message says how to reword a hypothesis. `add` refuses both. `superseded/1`, `supersedes_closure/2`, and `supersede_cycle/1` are declared with `ref`. Their rules do not change, so the Lean burn model is not rerun.
  - R2: `current/1` keeps `claim(C, _, _)`, so a hypothesis is never current, under, or a burn (`burn_reason/1` reads claims only). A hypothesis cycle is E15 and makes `any_supersede_cycle` true, so `done` is false, as for claims. The E15 message, `show open`, and `report` name the kind.
  - R3 (discovery): a superseded hypothesis is out of play. `some_hypothesis :- hypothesis(H, _, _), not superseded(H).`, `some_untouched_hypothesis :- hypothesis(H, _, _), not superseded(H), not discovery_hypothesis_touched(H).`, the not_reproduced clause of `discovery_has_outcome` adds `not superseded(H)`, WD7 adds `not superseded(H)`, and WD6 adds `not superseded(H)` for the hypothesis of its result. `artifact_vote/1` reads these through `discovery_ready`. `raised_by/2`, ED8, and `decision` (`no_go`, `hold`) do not change. `discovery_ready` does not read `any_supersede_cycle`; E15 reports a cycle.
  - R4 (W5): a check of a superseded claim gets W5 once for each current claim (a claim that no claim supersedes) that replaces the claim, directly or through a chain, and that has no check of its own. The message names that claim and says to add a new check of it with a new id, then run it (check ids are unique, E5, and facts are append-only). No W5 when no such claim exists.
  - Tests: RW1 to RW5, W5b, W5c.
- **D14 (GO / NO-GO / HOLD is a weighted vote, 2026-10-21).** Decision by Ty, recorded in `thoughts/orbital-shifting-system-prompt-draft.md` ("GO / NO-GO: a weighted vote"): the human (0.4), the agent (0.3), and the formal artifacts (0.3) vote GO, NO-GO, or HOLD. The agent's vote is sealed until the human votes. A choice wins only with more than half of the weight and with the human's vote, so the human plus at least one other role. Any other result is HOLD, another orbit follows, and the disagreement is a divergence. All in `modules/discovery.pl`; `core.pl` and `build.pl` do not change, so the Lean burn model is not rerun. Choices made by the builder:
  - V1: attest type `vote`, shape `vote(int, oneof([go, no_go, hold]))`, writers `[agent, human]`. The subject is the request. The int is the round: 1 at the first gate, then one more after each HOLD. One vote per writer per round: a second is lint error ED10 (on each of the two). A later round replaces the earlier one: only the largest round with any vote counts (`vote_round/1`, with the helper `discovery_vote_raised/1`, as `budget` does). A round, not "the later vote wins", because the rules cannot order attestations by time, and a new orbit needs new votes.
  - V2: `artifact_vote(go) :- discovery_ready, discovery_some_current.`, `artifact_vote(no_go) :- discovery_ready, not discovery_some_current.`, `artifact_vote(hold) :- not discovery_ready.` It reads the KB as it is at the query.
  - V3: `gate(C) :- human_vote(C), agent_vote(C).`, `gate(C) :- human_vote(C), artifact_vote(C).`, `gate(hold) :- human_vote(_), not discovery_gate_agreed.`, and `gate_split :- human_vote(_), not discovery_gate_agreed.` The weights are not data: with 0.4/0.3/0.3, "more than half, with the human" is exactly "the human plus one other". `gate` has no answer until the human votes in the current round. No variable occurs only under `not`.
  - V2/V3 protection: `vote_cast/3`, `discovery_vote_raised/1`, `vote_round/1`, `human_vote/1`, `agent_vote/1`, `artifact_vote/1`, `discovery_gate_agreed/0`, `gate/1`, `gate_split/0` are protected (E16). `discovery_ready/0` is not: a `rules.pl` extension of it stays W6, as before.
  - V4 (sealing): `report` gets a `Vote:` section with the discovery module, before `To land:`. Until the human votes in the current round, it says only whether the agent voted; it shows neither the agent's choice nor `artifact_vote`. After that, it shows all three votes, the outcome, and, on `gate_split`, a reminder to record a divergence with `hypothesis(H)`. `attest` refuses an agent vote in a round that already has a human vote. Lint warning WD9: a human vote with no agent vote in its round. Limit (trust threat model): this guards honest mistakes only. `query`, `why`, and `kb.pl` show the agent vote, a hand edit can add votes in any order, and WD9 checks that an agent vote exists in the round, not that it came first.
  - V5: the tiny discovery orbit has no KB, so nothing changes for it.
  - V6: WD6 says "The problem did not reproduce on the current system. Tell the human what you tried." The template of `discovery_has_outcome` is "some claim is current, or some hypothesis did not reproduce". Neither recommends NO-GO. `fixtures/discovery-a/expected.pl` is generated by a script under `thoughts/discovery-orbit/`, so it is not edited; it matches WD6 by code, not by text.
  - Tests: VT1 to VT10. Mutants: one per new rule, all killed.
- **D13 (a waiver can target a check or a question, 2026-10-21).** Decision by Ty: a deadline "bypass" and a burn "waiver" are not semantically distinct enough, so widen the waiver instead of adding a new record. "The only annoyance is that a time must be entered for when we'll come back to it. But, that seems like an ok pattern for now." The `waiver` shape is `waive(ref([claim, check, question]), time, text)`. The new type `ref([N1, ...])` accepts the id of a fact of any of the names; another id is E4 (a non-atom is E3), and the message names the allowed kinds. Writers stay `[human]`; an agent waiver is E8 and does not count. Rules (safe for both engines, no variable only under `not`):
  - W2: a waiver on a claim closes its burn (`burn_waived/1`, unchanged). It does not cover the checks or the questions of the claim. The Lean burn model and its requirements do not change.
  - W3: `check_waived(C) :- check(K, C), attest(W, waiver, _, waive(K, _, _), human, _), not waiver_lapsed(W).` and `under(C) :- current(C), not fulfilled(C), not check_waived(C).` A waived check covers its claim for `done`. It does not make `fulfilled(C)` true, and it does not touch burns.
  - W4: `question_waived(Q) :- question(Q, _, _), attest(W, waiver, _, waive(Q, _, _), human, _), not waiver_lapsed(W).` (build module; core declares `question_waived/1` with no clause, as for `lint_issue/3`). Both `to_ask/1` clauses add `not question_waived(Q)`.
  - W5: `waiver_lapsed(W)` is computed as before for every waiver, so a lapsed or invalid due time makes the item block `done` again.
  - W6: `report` has a `Waivers:` section (with the build module) that lists every waiver: id, kind and id of the target, due time, and `in force`, `lapsed`, or not by a human. `Claims:` shows a claim with a waived check as `Status: not fulfilled` with the check and the due time. `Open:` names the kind of a lapsed waiver. `show claims` and `show questions` mark waived items.
  - W7: `check_waived/1` and `question_waived/1` are protected (E16).
  - The help text of `attest` and `prove` gives a waiver example that a shell accepts: `orbit-kb attest waiver c1 "waive(c1, '2026-11-30T17:00:00Z', 'why')" --by human`. Tests: WV1 to WV10.
- **D12 (the refuted verdict carries its counterexample, 2026-10-21).** Decision by Ty: "make a slot for the counterexample in the refuted verdict." The verdict is `refuted(Counterexample)`, where the argument is `text`, in both `disproof` (`alt([refuted(text), inconclusive, abstained])`) and `lean_result` (`alt([stated, refuted(text), tested(int)])`). The core rule is `refuted(C) :- attest(_, _, _, verdict(C, refuted(_)), _, _).` `discovery_disproof_filed/1` reads `refuted(_)` too. A bare `refuted` is E3. The message shows the new form, such as `verdict(c1, refuted('the counterexample'))`. `inconclusive`, `abstained`, `stated`, and `tested(N)` do not change. A KB with a bare `refuted` fails lint (E3) until its author adds the text. `why` prints the text. `report` and `show` do not print refutations, so they do not change. Tests: RF1 to RF7.
- **D11 (add a module, 2026-10-19).** Decision by Ty: a cleaner fix than an edit by hand for the handoff between orbits. `orbit-kb uses MODULE …` adds a module to an existing KB.
- **D10 (a burn needs a proof, 2026-10-19).** Decision by Ty: "A burn needs a proven
  verdict. Always. Specification clarity comes from the need to build out that proof. Not
  merely write it in lean. Clarity comes from the demand to write it in lean _correctly_."
  Follow-up choices by Ty, the same day: only a script records a proof; TLC does not count
  as a proof (Lean only); a human may waive a proof with a due time; a conformance check of
  the code against the Lean model is optional ("a smooth gradient on the requirement for
  scaling"). The changes:
  - `done` also needs `not any_burn_open`. `burn_open(C) :- burn(C), current(C),
    not burn_proved(C), not burn_waived(C).`
  - `lean_result` keeps `stated`, `refuted` (now `refuted(text)`, D12), and `tested(int)`, and loses `proved`. New
    types: `lean_proof` (`proof(ref(claim), digest)`, writers `[script]`) and `waiver`
    (`waive(ref(claim), time, text)`, writers `[human]`).
  - New command `orbit-kb prove CLAIM FILE THEOREM [--module M]`. It runs `lake build`, a
    probe (`lib/lean/probe.lean`) that reports kind, module, axioms, statement, and
    project imports, then `leanchecker`, then `lake build --no-build`. It accepts only the
    axioms `propext`, `Classical.choice`, `Quot.sound`. It writes `runs/proof-ID.log`.
  - Derived facts, computed at each KB load: `proof_changed(A)` (a file of the proof
    changed, or the log is missing or wrong) and `waiver_lapsed(W)` (the due time is
    past). Both engines saw them as facts (D20: only SWI now).
  - Lint E9 also covers a `lean_proof` with no matching log. E8 names `orbit-kb prove`.
  - Optional conformance: `conformance(ref(check))` and `conforms(C)`.
  - `declare` refuses `proved`, `chs`, `assume`, `abduced`: s(CASP) uses them as model
    wrappers, and a rule `proved/1` made `scasp --code` raise an instantiation error.
    The rule is named `burn_proved/1`. Superseded by D20: the names are no longer reserved.
- **D10 follow-up (review fixes, 2026-10-20).** Decisions by Ty on 2026-10-20: the
  threat model is trust ("we expect trust between the agents, the human, and the code"),
  so `prove` checks the proof of an honest agent that can make mistakes and does not
  resist an agent that cheats on purpose; the cheating holes are documented limits
  (README section 15). A claim that supersedes a burning claim inherits the burn. The
  changes (review: `thoughts/orbit-kb-d10-review-2026-10-20.md`):
  - S1: `burn(C)` holds when C has a burn reason (contested twice, universal, burn
    requested), or when C reaches, through one or more `supersedes` steps, a claim that
    has one. S2: a `supersedes` cycle, including `supersedes(C, C)`, is lint error E15,
    and `done` is false while it exists. S3: the rules do not recurse through
    `supersedes`; the CLI computes `supersedes_closure/2` and `supersede_cycle/1` when it
    reads the KB.
  - E16: `rules.pl` cannot add clauses to `done`, the burn rules, or the computed facts.
    The engines do not read such clauses, nor a `rules.pl` clause whose head is a fact
    predicate (E7), nor a `kb.pl` fact of a protected predicate (E7).
  - The `time` type checks the values. A waiver whose due time is not a valid time
    counts as lapsed.
  - Proof log and digest. The log has `absent PATH` lines for the Lake configuration
    files (`lakefile.lean`, `lakefile.toml`, `lean-toolchain`, `lake-manifest.json`)
    that do not exist. The digest is the sha256 of these lines, each ended by a newline:
    `claim C`, `theorem T`, `module M`, `statement S` (from the log), then `SHA PATH`
    for each `file` line in order, then `absent PATH` for each `absent` line in order.
    A proof counts (`proof_changed` is false) only when the log header names the claim
    and the digest of the attestation, the log lines give that digest, every file
    still has its sha256, and every absent file is still absent.
- **D6.** Generate stubs only for declared predicates that have no clauses in the
  assembled program. Name every anonymous variable in a query before passing it to
  s(CASP), because `--json` crashes on `_`. Superseded by D20: no stubs go to s(CASP)
  now; the SWI engine makes each declared predicate dynamic.

This contract is the single source of truth for three builders who work in parallel:

- **A, library:** `shared/link/.local/share/orbit-kb/`
- **B, CLI:** `shared/link/.local/bin/orbit-kb`
- **C, tests:** `scripts/orbit-kb/`

Each builder edits only its own path. When something is ambiguous, choose the reading
that makes failures loud, and record the choice in your final report.

**Purpose.** A CLI that helps LLM agents write, check, and query Prolog knowledge bases
(KBs) with default negation (`not p`). SWI-Prolog is the only engine (D20). A KB records:

- a human's request;
- claims about the request;
- dormant questions with default answers;
- attestations, which are evidence shaped like in-toto statements.

SWI-Prolog has no schema checker, so `orbit-kb` provides one. The tool must stay
domain-neutral. The core vocabulary must not mention software. Software terms live in
`modules/build.pl`. Discovery terms live in `modules/discovery.pl`, which another session
owns.

## Environment facts

- SWI-Prolog 9.2.9 is at `/usr/bin/swipl`. It is the only engine (D20). No other
  program is needed. Until 2026-11-02, a second engine, s(CASP) 1.1.4, ran beside it.
- `not G` is negation as failure: it holds when G has no answer. So `not under(_)` means
  "no under at all".
- Clauses of one predicate merge across concatenated files, and negation sees all of
  them. Facts like `decl(fact, claim(id, oneof([a,b]), text), 'Doc', 'T').` are harmless
  inside the program. So the program can be built by concatenating raw text.
- The SWI engine reads these operators: `op(900, fy, not)` and `op(950, xfx, ::)`.
  Other operators of s(CASP) are not read (E17).

## Engine: one engine, one verdict, one explanation

SWI-Prolog is the only engine (D20). Every program that the tool answers is stratified:
the core and the modules are, and lint (E14, E17, E18) keeps `rules.pl` inside the same
fragment. Negation as failure then gives the one answer of the program.

1. **Verdict.** Load the assembled program into a fresh module of the `orbit-kb`
   process, after these translations:
   - `not G` becomes `\+ G`;
   - each `not` literal moves after all of the positive body literals. Builtins stay in
     place relative to the positive literals. In a stratified program this does not
     change the answers, and it stops `\+` from floundering on unbound variables (D7);
   - a clause that has a form of E17 is skipped;
   - each declared predicate is made dynamic, so an empty predicate fails without an
     error.

   Collect all answers with a time limit (10 s) and an answer cap (1000), then remove
   duplicates. These are the answers that `orbit-kb` prints.
2. **Explanation.** `why` and `whynot` read the same clauses. They never change a verdict
   (see the CLI table).
3. **Answer gate.** `query`, `why`, `whynot`, `show`, and `report` exit 2 before they
   answer while a source has an E1, E2 (in `rules.pl`), E17, or E18 diagnostic. A broken
   source never yields a quiet "false".
4. **SWI ERROR.** When the engine cannot evaluate a goal, the command exits 2. It is
   never a false answer.

There are no hazards of a second engine (H1 to H4 went with s(CASP), D20). A fact that is
not recorded is false. Atoms that end in `_<digits>` are ordinary atoms.

## Files

### Library (`$ORBIT_KB_LIB`, default `<real dir of the orbit-kb script>/../share/orbit-kb`)

- `core.pl`: core declarations and rules. It is always loaded.
- `modules/<name>.pl`: optional modules.
  - `build` is written by builder A.
  - `discovery` is written later by the discovery session. Builder A creates a
    placeholder that holds only a comment.

### A KB is a directory, at any location the agent chooses (no default)

- `kb.pl`:
  - The first term is `uses([Module, …]).` The list may be empty.
  - Then facts (no classical negation `-p`: E17), and local `decl/4` and `attest_type/4`
    declarations.
  - The file is append-only by convention. The only exception is `orbit-kb subject`,
    which rewrites its own `subject/3` line.
- `rules.pl` (optional): local rules (no `#` lines: E17).
- `runs/<N>-<CheckId>.log`: written only by `orbit-kb run`. The first line is
  `% orbit-kb run <N> check=<CheckId> result=<pass|fail> exit=<code> time=<ISO> cmd=<command>`.

## Declarations

```prolog
decl(Kind, Head, Doc, Template).
%  Kind:     fact | rule
%  Head:     Name(Type1, …, TypeN)
%  Doc:      atom; one plain sentence
%  Template: atom with positional @(1), @(2)… that `why` and `whynot` print; '' if none
attest_type(Type, Shape, Writers, Doc).
%  Shape:    a type (below) for the 4th argument of attest/6
%  Writers:  sub-list of [human, agent, script]
```

- A predicate of kind `fact` may appear only as a ground fact, or a ground `-fact`, in
  `kb.pl`.
- A predicate of kind `rule` is computed, and a fact for it is an error.
  - A local `rules.pl` may define new rule predicates. It may also add clauses to
    existing rule predicates; lint reports this as an extension (W6).
  - A module may add clauses to the core predicate `lint_issue/3`.
- `Writers = [script]` means that only `orbit-kb run` may write that attestation type.
- **Module lint hook.** `lint_issue(Code, Id, Message)` is a core rule predicate with no
  core clauses. Modules add clauses to it. `orbit-kb lint` evaluates it with the SWI
  engine and prints each result as `<Code> <Id>: <Message>`. A code that starts with `E`
  is an error. Any other code is a warning.

### Types

| Type | Accepts |
|---|---|
| `id` | an atom; unique across all `id`-typed values in the KB |
| `ref(Name)` | the id (first argument) of an existing `Name` fact |
| `ref([Name, ...])` | the id of an existing fact of one of the names (D13) |
| `ref` | any existing id |
| `oneof(List)` | one atom of `List` |
| `alt(Shapes)` | a value that matches one shape. An atom entry matches itself. A compound entry matches by name and arity, and each of its arguments is a type. |
| `text`, `atom` | an atom |
| `int` | an integer |
| `time` | an atom `YYYY-MM-DDTHH:MM:SSZ` with real values: month 01-12, a day of that month (leap years too), hour 00-23, minute and second 00-59 (D10 follow-up) |
| `digest` | an atom `sha256:` followed by 64 lowercase hex characters |
| `by` | `human`, `agent`, or `script` |
| `term` | any ground term (the escape hatch) |
| `attest_predicate` | used only by `attest/6`; checked against the `attest_type` of argument 2 |

Every fact must be ground.

## Core vocabulary (`core.pl`)

The discovery orbit and the build orbit both use the core vocabulary. Names that the
discovery module reserves must not appear in the core or the build module:

- Facts: `hypothesis/3`, `budget/2`, `lap_done/1`, `model/2`,
  `model_run/3`, `derived_from/2`, `encodes/2`, `finding/3`, `reason/3`,
  `raised_by/2`, `discovery_evidence/2`.
- Gates: `discovery_ready/0` (clean) and `discovery_decide/0` (ready, or the
  budget is spent).
- Rules: every name that starts with `model_` (for example `model_trusted/1`,
  `model_diverges/1`, `model_run_stale/2`, `model_verdict/4`), and
  `has_falsifier/1`, `no_falsifier/1`, `needs_question/1`,
  `has_question/1`, `unasked_finding/1`, `question_waits/1`,
  `about_system/1`, `finding_confirmed/1`, `finding_lead/1`,
  `rule_has_reason/2`, `weak_rule/1`, `touched_system/0`, `budget_spent/0`,
  and helpers named `discovery_*` and `some_*`.
- The vote (D14): `vote_cast/3`, `vote_round/1`, `human_vote/1`, `agent_vote/1`,
  `artifact_vote/1`, `gate/1`, `gate_split/0`.
- Attestation types: `reproduction`, `model_result`, `decision`, `vote`.
  (Calibration is a `model_result` shape, not a type.)
- Lint codes: `WD1`–`WD9` and `ED1`–`ED10`.

Core facts:

- `request(id, text)`: the human's words, verbatim.
- `ticket(ref(subject))`: the subject that holds the ratified ticket.
- `claim(id, oneof([preserve, retire, introduce]), text)`:
  - `preserve`: true now, and must stay true;
  - `retire`: true now, and must become false;
  - `introduce`: false now, and must become true.
- `cites(ref(claim), text)`: the request or ticket text that the claim serves.
- `example(ref(claim), text)`: a concrete case. Discovery's witnesses and reproductions
  go here, and build turns them into tests.
- `supersedes(ref, ref)`: the new claim, then the old one; or, with the discovery module,
  the new hypothesis, then the old one (D15). Both sides are the same kind; otherwise E4.
- `universal(ref(claim))`: the claim says "for every input".
- `check(id, ref(claim))`: an executable check of the claim.
- `world(term)`: a closed-world fact about the current state.
- `source(term, text)`: where a `world` fact was observed (file and line, configuration
  key, query, or log).
- `scope(oneof([in, out]), text)`
- `risk(id, text)`
- `assumption(id, text)`
- `not_explored(text)`
- `question(id, ref(claim), text)`
- `assumed(ref(question), term)`: the default answer.
- `answer(ref(question), term, oneof([human, agent]))`
- `depends(ref(question), ref(question))`: the first question depends on the second.
- `note(ref, text)`: a free-text note about any id.
- `subject(id, text, digest)`: an artifact path and its sha256. The path is relative
  to the KB directory when the file is inside it; otherwise it is absolute (D3).
- `attest(id, atom, ref, attest_predicate, by, time)`: Id, Type, Subject, Predicate, By,
  Time.

Core attestation types:

- `disclosure`: shape `alt([guess(ref(question)), unverified(text), disagreement(text), out_of_scope(text), self_error(text), other(text)])`. Writers: `[agent, human]`.
- `divergence`: shape `alt([claim(ref(claim)), hypothesis(term), model(term)])`. Writers: `[human, agent]`. Put the description in a `note/2`.
- `disproof`: shape `verdict(ref(claim), alt([refuted(text), inconclusive, abstained]))`. The text of `refuted` is the counterexample (D12). Writers: `[agent]`.
- `approval`: shape `digest(digest)`. Writers: `[human]`.
- `test_result`: shape `result(ref(check), int, oneof([pass, fail]))`. Writers:
  `[script]` (moved from build in v2.1).

Core rules, each declared with kind `rule`:

```prolog
superseded(C) :- supersedes(_, C).
current(C) :- claim(C, _, _), not superseded(C).
answered(Q) :- answer(Q, _, human).
defeated(Q) :- assumed(Q, A), answer(Q, B, human), A \= B.
refuted(C) :- attest(_, _, _, verdict(C, refuted(_)), _, _).
contested(C) :- attest(_, divergence, _, claim(C), _, _).
contested_twice(C) :- attest(D1, divergence, _, claim(C), _, _),
                      attest(D2, divergence, _, claim(C), _, _), D1 \= D2.
to_ask(Q) :- question(Q, C, _), current(C), depends(Q, P), defeated(P), not answered(Q),
             not question_waived(Q).
to_ask(Q) :- question(Q, C, _), current(C), contested(C), not answered(Q),
             not question_waived(Q).
% question_waived/1: no clause in core; the build module adds it (D13).
any_to_ask :- to_ask(_).
stale(A) :- attest(A, approval, S, digest(D0), human, _), subject(S, _, D1), D0 \= D1.
passed(K) :- attest(_, test_result, _, result(K, R, pass), _, _), not failed_after(K, R).
failed_after(K, R) :- attest(_, test_result, _, result(K, R2, fail), _, _), R2 > R.
was_red(K) :- attest(_, test_result, _, result(K, R1, fail), _, _),
              attest(_, test_result, _, result(K, R2, pass), _, _), R1 < R2.
any_supersede_cycle :- supersede_cycle(_).
lint_issue(Code, Id, Message)          % declared; no core clauses (module hook)
```

`supersedes_closure(New, Old)` (New reaches Old through one or more `supersedes` facts)
and `supersede_cycle(C)` (C reaches itself) are rule predicates with no clauses in the
library. The CLI adds their facts each time it reads the KB, from the ground
`supersedes/2` facts of `kb.pl` (D10 follow-up, S3).

An earlier pass followed by a later fail does not count, because `passed(K)` requires
that no fail comes after the pass.

## Build module (`modules/build.pl`)

Facts:

- `change(id, text)`
- `serves(ref(change), ref(claim))`
- `burn_requested(ref(claim))`
- `conformance(ref(check))` (D10, optional)
- `visual(ref(claim))` (D21): a human must see the claim to judge it.
- `demo(ref(subject), ref(claim))` (D21): the subject (a screenshot or a recording) shows the claim.

Attestation types:

- `lean_result`: shape `verdict(ref(claim), alt([stated, refuted(text), tested(int)]))`. Writers: `[agent, script]`. Progress only (D10).
- `lean_proof`: shape `proof(ref(claim), digest)`. Writers: `[script]`. Only `orbit-kb prove` writes it (D10).
- `waiver`: shape `waive(ref([claim, check, question]), time, text)`. Writers: `[human]` (D10, D13).

Rules (no `not` over body-only variables). They use the core rules `passed/1` and
`was_red/1`:

```prolog
fulfilled(C) :- claim(C, preserve, _), check(K, C), passed(K), not refuted(C).
fulfilled(C) :- claim(C, L, _), L \= preserve, check(K, C), passed(K), was_red(K),
                not refuted(C).
under(C) :- current(C), not fulfilled(C), not check_waived(C).
served(X) :- serves(X, _).
over(X) :- change(X, _), not served(X).
any_under :- under(_).
any_over :- over(_).
any_current_claim :- current(_).
no_current_claim :- not any_current_claim.
done :- not any_under, not any_over, not any_to_ask, not any_burn_open,
        not any_flare_open, not any_supersede_cycle, not no_current_claim.
burn_reason(C) :- contested_twice(C), not visual(C).
burn_reason(C) :- universal(C).
burn_reason(C) :- burn_requested(C).
burn(C) :- burn_reason(C).
burn(C) :- supersedes_closure(C, O), burn_reason(O).
burn_proved(C) :- attest(A, lean_proof, _, proof(C, _), script, _), not proof_changed(A).
burn_waived(C) :- attest(W, waiver, _, waive(C, _, _), human, _), not waiver_lapsed(W).
burn_open(C) :- burn(C), current(C), not burn_proved(C), not burn_waived(C).
any_burn_open :- burn_open(_).
flare(C) :- visual(C).
flare(C) :- supersedes_closure(C, O), visual(O).
flare_shown(C) :- demo(S, C), attest(_, approval, S, digest(D), human, _), subject(S, _, D).
flare_waived(C) :- attest(W, waiver, _, waive(C, _, _), human, _), not waiver_lapsed(W).
flare_open(C) :- flare(C), current(C), not flare_shown(C), not flare_waived(C).
any_flare_open :- flare_open(_).
conforms(C) :- conformance(K), check(K, C), passed(K).
check_waived(C) :- check(K, C), attest(W, waiver, _, waive(K, _, _), human, _),
                   not waiver_lapsed(W).
question_waived(Q) :- question(Q, _, _), attest(W, waiver, _, waive(Q, _, _), human, _),
                      not waiver_lapsed(W).
```

`proof_changed/1` and `waiver_lapsed/1` are rule predicates with no clauses in the
library. The CLI adds their facts each time it reads the KB (D10). `waiver_lapsed(W)`
also holds when the due time of W is not a valid `time` (D10 follow-up).


## CLI

Usage: `orbit-kb [--dir DIR] <command> [args]`

KB resolution, in order:

1. `--dir`;
2. `$ORBIT_KB`;
3. the nearest parent of the current directory, or the directory itself, that holds a
   `kb.pl` whose first term is `uses(_)`.

If none is found, exit 2 with a message that names all three options. If a subdirectory of
the current directory, up to two levels down, holds such a `kb.pl`, the message also names it
and the `--dir` that would use it (hidden directories, `runs`, `node_modules`, and `.lake` are
skipped). orbit-kb never uses that KB on its own.

An unknown command exits 2. When it is a plain word, the message also shows how to run it as a query: `orbit-kb query 'WORD(X)'`, or `orbit-kb query 'WORD'` (K10).

Exit codes:

| Code | Meaning |
|---|---|
| 0 | success; the query is true; lint is clean |
| 1 | the query has no answer; lint found errors; `add`, `declare`, `attest`, or `init` rejected the input |
| 2 | usage error (also `query --json` and `query --html`, which no longer exist); KB or library not found; tool missing; query syntax error; undeclared predicate in a query; a source that has E1, E2, E17, or E18 (answer gate); SWI ERROR; internal error |

A typo, a broken source, or an engine error MUST never exit 1. It must never look like "false".

| Command | Contract |
|---|---|
| `init DIR (--request TEXT \| --request-file F) [--uses m1,m2] [--id ID]` | Create `DIR/kb.pl` containing `uses([…]).` and `request(ID, 'TEXT').` The default ID is `r1`. Exit 1 if `kb.pl` already exists. Print the path. |
| `uses MODULE …` | Add modules to the first term `uses([…])` of an existing `kb.pl`, under the KB lock, without loading the KB. Keep the modules in use; never remove one. Keep the text around the term. Print the new line, and tell the agent to lint. Exit 0, also when nothing changes; 1 on an unknown module or a first term that is not `uses/1` with a list of atoms; 2 on a usage error or a failed write (D11). |
| `add 'FACT' …` | The trailing `.` is optional. Validate against every lint error that applies to facts. Facts in the same batch may refer to each other. All or nothing. Append the facts in order and print each one. Refuse attestation types whose writers are `[script]`, and point to `orbit-kb run`. Every rejection says why and how to fix it. For an undeclared predicate, the fix is `orbit-kb declare`. |
| `declare 'HEAD' --doc TEXT [--kind fact\|rule] [--template T]` | The default kind is `fact`. Exit 1 if that name and arity are already declared anywhere, or if a type is unknown. Append the `decl/4` line. |
| `declare-attest TYPE 'SHAPE' --doc TEXT --writers human,agent` | Append an `attest_type/4` line. The same checks apply. |
| `subject ID PATH` | Compute the sha256 of PATH. Exit 1 if the file is missing. Store the path relative to the KB directory when the file is inside the KB directory tree, otherwise the absolute path (D3). Rewrite an existing `subject(ID, …)` line in place, or append a new one. Print the digest. |
| `attest TYPE SUBJECT 'PREDICATE' [--by human\|agent] [--id ID]` | `--by` defaults to `agent`. The id defaults to `a<N>`, the next free number. The time is now, in UTC. Validate the shape, the writer, and the references. The literal predicate `digest(current)` is replaced by the subject's recorded digest. |
| `run CHECK -- CMD …` | Check that CHECK exists, then run CMD. Write its combined output to `runs/<N>-<CHECK>.log`, where N is the highest run number in any `test_result` plus 1. Append `attest(aM, test_result, CHECK, result(CHECK, N, pass\|fail), script, TIME)`; the result is `pass` when CMD exits 0. Print `run N CHECK pass\|fail (exit E) log=PATH`. On a fail, also print the last 40 lines of output. Exit 0 on pass and 1 on fail. |
| `lint [--strict]` | Print one diagnostic per line, `E<n> file:line: message` or `W<n> …`, then module `lint_issue` results, then a summary line. Exit 1 if there are errors, or if there are warnings and `--strict` is set. |
| `query 'GOAL' [-n N] [--why] [--long]` | Check that every predicate in GOAL is declared or built in; otherwise exit 2. Assemble the program in this order: core, modules, `kb.pl`, `rules.pl`. Run the SWI engine. `-n` defaults to 1; 0 means all answers. Output: one line per answer, either `true` or `X = v, Y = w`; no answer prints `false`. `--why` adds, after each answer, the clauses that prove it (D20). `--long` makes the explanation 30 levels deep instead of 6. `--json` and `--html` are usage errors (exit 2). Exit 0 on an answer, 1 on none, 2 on a bad goal, a source for the answer gate, or SWI ERROR. |
| `why 'GOAL' [-n N] [--long]` | Same as `query --why`. Each answer is followed by "X, because" and the indented reasons: why each literal of the rule that proves it holds. A `not` literal reads "there is no evidence that X". |
| `whynot 'GOAL' [--long]` | The first line is `holds` or `absent`, decided by the SWI engine (the verdict `contradicts` is gone, D20). `holds` means GOAL has an answer; the clauses that prove the first answer follow. `absent` means GOAL has no answer; then, for each rule of GOAL, the first body literal that no answer gets past ("the rule for done/0 stops at not any_under:") and why, recursively. "nothing records X: no fact or rule matches it" is printed when nothing matches. The depth is 6 levels; `--long` gives 30. The explanation never changes the verdict. Exit 0. |
| `show [claims\|questions\|open\|disclosures\|extensions\|all]` | Plain-text listing. The default is `all`. `open` lists `to_ask`, `stale`, and `contested`, plus `under` and `over` when build is loaded. |
| `report` | A delivery skeleton in plain Markdown (D16 C4: `# Name:` headings, a blank line between sections, two-space bullets, bold labels, nested detail) with these sections in this order: `Delivered:` (placeholder); `Claims:` (each current claim with `fulfilled` or `under` when build is loaded, and its checks); `Guesses:` (questions whose default no human answered; D17 C5 for the empty case); `Disclosures:`; `Not checked:` (current claims with no check); `Open:` (`to_ask`, stale approvals, `over`, and `no claim` when no claim is current, D17 C4); `To land:` (placeholder). Use short, plain sentences. `--html FILE` also writes the report as a page for review, and `--open` opens it (D16). |
| `doctor` | Check `swipl` and the library directory, and print a fix step for anything missing. Then run known-answer self-tests on the SWI engine: the helper form must be false; `not under(_)` must be false when `under(a)` holds; arithmetic under `not` must give exactly k2, k3, and k4 with `-n 0`; E18 must flag `p :- not q, q :- not p`; E17 must flag `-p(b)`. Report each result. Exit 2 if anything is missing or a self-test fails. It does not look for `scasp`. |
| `help [COMMAND\|TOPIC]` | Usage. The general help starts with a "How to use" block (the order of the commands, and one line for each topic), then lists the commands and explains the engine (negation as failure, stratified rules) in a few plain sentences. A TOPIC is `core`, `build`, `discovery`, `codes`, or `answers`. Its text is the file `help/TOPIC.txt` in the library directory. An unknown name exits 2. `init` prints a `Next:` line that names `help core`. `uses discovery` prints a `Next:` line that names `lint` and `help discovery`. |

## Lint

| Code | Error |
|---|---|
| E1 | Syntax error, with file and line. |
| E2 | Undeclared predicate or wrong arity. This covers `kb.pl` facts and the heads and bodies in `rules.pl`, `core.pl`, and the modules. Built-ins are allowed: `=`, `\=`, `<`, `>`, `=<`, `>=`, `is`, `#=`, `#<>`, `#<`, `#>`, `#=<`, `#>=`, `true`, `false`, `forall/2`. `not G` and `-G` are unwrapped. When a declaration exists with the same name but a different arity, the message names it. Two facts joined by a comma in one `add` argument (a `','/2` term) get a message that says to give each fact as its own argument (A20). |
| E3 | Type error, including a label outside `oneof`. When an attestation predicate is only one entry of an `alt` inside the form, such as `tested(100)` for `verdict(ref(claim), alt([..., tested(int)]))`, the message also shows the whole predicate with placeholders: `verdict(CLAIM, tested(100))` (A22). |
| E4 | Dangling `ref`, or a `ref` to the wrong kind. A `supersedes` side that is no claim and no hypothesis, or a claim and a hypothesis in one `supersedes` fact (D15). `add` refuses it. The message says that the argument names an id that another fact defines and does not create one, with `note(c1, ...)` as the example (A21). |
| E5 | Duplicate id. |
| E6 | Non-ground fact in `kb.pl` (D2). |
| E7 | A clause in the wrong place (D2): a `rule` predicate asserted as a fact in `kb.pl`, or a `fact` predicate with clauses outside `kb.pl`. |
| E8 | Attestation writer not allowed for its type. This includes a `[script]` type whose By is not `script`. |
| E9 | A `test_result` with no matching run log, where the header must match N, the check, and the result. A `lean_proof` with no matching `runs/proof-ID.log`: the header must name the claim and the digest, and the digest of the log lines (D10 follow-up) must equal it. |
| E10 | `uses/1` is missing, is not first, or names an unknown module. |
| E11 | A clause does not load in the SWI engine (D20). |
| E13 | Removed by D20 (it was hazard H4 of s(CASP)). |
| E14 | Unsafe negation: a `not` literal's variable occurs in the head but in no positive body literal (D7). A call with that variable unbound then gives a wrong answer. |
| E15 | A `supersedes` fact on a cycle, including `supersedes(C, C)` (D10 follow-up), of claims or of hypotheses (D15). `add` refuses it. |
| E16 | `rules.pl` adds clauses to a protected library predicate: `done`, `burn`, `burn_reason`, `burn_proved`, `burn_waived`, `burn_open`, `any_burn_open`, `flare`, `flare_shown`, `flare_waived`, `flare_open`, `any_flare_open` (D21), `proof_changed`, `waiver_lapsed`, `check_waived`, `question_waived`, `supersedes_closure`, `supersede_cycle`, `any_supersede_cycle` (D10 follow-up), `any_current_claim` (D17), and the vote rules `vote_cast`, `discovery_vote_raised`, `vote_round`, `human_vote`, `agent_vote`, `artifact_vote`, `discovery_gate_agreed`, `gate`, `gate_split` (D14). The engines ignore the clause. |
| E12 | Removed by D20 (it was hazard H1 of s(CASP)). A variable only under `not` is now an ordinary case: `not under(_)` means no under at all. |
| E17 | A form that `orbit-kb` does not read (D20): classical negation `-p` (a fact or rule head, or a body literal), a `#` line, a global constraint `(:- Body)`, or a `#=`-family constraint. `add` refuses it. It applies in `kb.pl` too, and a goal with such a form exits 2 with the E17 text. The answer gate applies. |
| E18 | The rules are not stratified: a predicate depends on itself through `not` (D20). The answer gate applies. |

| Code | Warning |
|---|---|
| W1 | The subject digest differs from the file on disk, or the file is missing. Refresh with `orbit-kb subject`. |
| W2 | A local declaration, listed for review. |
| W3 | A claim with no `cites`. |
| W4 | A local fact predicate that no rule reads (no reader). |
| W5 | A `check` of a superseded claim, while a current claim that replaces it (directly or through a chain) has no check (D15). The message says to add a new check of that claim, with a new id, and run it. |
| W6 | A local rule that adds clauses to a core or module predicate (an extension), other than a protected one (E16). |

## Style

- Human-facing text (help, report, messages) uses short, plain sentences, with one idea
  per sentence (ASD-STE100 style).
- No commits. Do not edit files outside your own path.
- Put temporary files in the session scratchpad:
  `/tmp/claude-1000/-home-ty--dotfiles/63a00f00-8d72-4aeb-a216-cde6b882f1f4/scratchpad`.

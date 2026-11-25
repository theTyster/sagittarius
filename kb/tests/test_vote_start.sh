#!/usr/bin/env bash
# The vote of the human at any time (ticket vote-start, claims c1, c3, c6, c7, c8; Ty r1 and r2).
# It reads the harness of test_question_server.sh and runs only its own tests.
# Usage: kb/tests/test_vote_start.sh [path-to-orbit-kb]   ONLY='<regex>'
#   VS1 c1: the sheet of every KB with an open discovery has the Vote form (GO, NO-GO, HOLD), a link to the
#       report, and, when the KB is not ready, what blocks it; a closed discovery has none
#   VS2 c3: Bring to a vote exists on a KB that is not ready only; its review shows one letter to the holder
#       and sends it; nothing is written in the KB
#   VS3 c1, c8: the vote of the human on the Desk is Ty's own record, in the KB: a GO on a KB that is not
#       ready is recorded and does not win the gate; a HOLD counts at once; a vote of a ready KB wins the gate
#   VS4 c6: a change of the specification after the vote opens the gate; the vote stays in the KB; the sheet
#       says what changed; a vote in a new round wins again; c7: a note, a run, a finding, an answer keep it
#   VS5 c6: the engine rule alone (orbit-kb query): each kind of change voids; each other record keeps the vote;
#       a vote after a valid approval of the ticket (closed discovery) is not taken back
QS_LIB_ONLY=1
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)/test_question_server.sh" "$@"

# vs_kb DIR notready|ready|voted: a KB in discovery, made with the tool (as vote_start.sh does)
vs_kb() { local d=$1
    wr build init "$d" --request "a request" --uses discovery || { note "setup: no KB $d: $(snip "$err")"; return 1; }
    wr build --dir "$d" add "goal(g1, feature, agent, 'A goal.')" "no_premises(g1)" "hypothesis(hy1, g1, agent, 'An avenue.')" "defeating_case(hy1, agent, 'A case.')" "no_premises(hy1)" \
        "claim(c1, introduce, 'A claim.')" "cites(c1, 'a request')" "example(c1, 'A case.')" "check(k1, c1)" "checks_that(k1, 'it checks')" "predicts(hy1, c1)" || { note "setup: facts refused: $(snip "$err")"; return 1; }
    if [ "$2" = notready ]; then
        wr build --dir "$d" add "finding(f1, surprise('A surprise.'), system)" "question(q1, hy1, 'A question that waits?')" "option(q1, 'A', 'a')" "option(q1, 'B', 'b')" "raised_by(q1, f1)" || { note "setup: question refused: $(snip "$err")"; return 1; }
    else
        wr build --dir "$d" run k1 -- false; wr build --dir "$d" add "discovery_evidence(k1, system)"
        wr build --dir "$d" attest vote r1 'vote(1, go)' || { note "setup: the agent vote was refused: $(snip "$err")"; return 1; }
        [ "$2" = voted ] && { wr build --dir "$d" attest vote r1 'vote(1, go)' --by human || { note "setup: the human vote was refused: $(snip "$err")"; return 1; }; }
    fi
    wr build --dir "$d" release; return 0; }
gate_is() { q "$1" "gate($2)"; [ "$rc" = 0 ] || note "${3:-the gate of $1}: want gate($2): no answer (rc $rc)"; }
gate_not() { q "$1" "gate($2)"; [ "$rc" = 1 ] || note "${3:-the gate of $1}: want no gate($2), rc $rc"; }
vs_hub() { mkdesk "$1"; kb_project "$1/project-kb" 'Vote project'
    vs_kb "$1/specs/nr" notready; vs_kb "$1/specs/rd" ready; vs_kb "$1/specs/vt" voted; }
# vform FILE INTENT SLUG: the forms of the page with that intent that name that KB (count; the forms in $T/vf)
vform() { python3 -I - "$1" "$2" "$3" > "$T/vf" <<'PY'
import re, sys, html
t = open(sys.argv[1], encoding='utf-8').read(); intent, slug = sys.argv[2], sys.argv[3]
for m in re.finditer(r"<form\b.*?</form>", t, re.S):
    f = html.unescape(m.group(0))
    if re.search(r'name="intent"\s+value="%s"' % re.escape(intent), f) and re.search(r"specs/%s\b" % re.escape(slug), f):
        print(re.sub(r"\s+", " ", f))
PY
    grep -c . "$T/vf"; }
vs_holder() { local H; H=$(hf "$T/h" --session discovery handoff --to build --title "Build $2" --ref "kb:$2"); hf "$T/h" --session build accept "$H" >/dev/null; }

t_VS1() {  # c1: a Vote form on every KB with an open discovery; the blockers; none when the discovery is closed
    vs_hub "$T/h"; srvd --hub "$T/h" || return; page_ok || return
    local s n
    for s in nr rd vt; do n=$(vform "$T/page.html" vote $s)
        [ "$n" = 1 ] || { note "the KB $s: $n Vote forms (want 1)"; continue; }
        for v in go no_go hold; do grep -q "value=\"$v\"" "$T/vf" || note "the Vote form of $s has no choice $v"; done
        grep -qi "report" "$T/vf" || note "the Vote form of $s has no link to the report"
    done
    vform "$T/page.html" vote nr >/dev/null; grep -q "question q1 waits for you" "$T/vf" && grep -qi "not ready" "$T/vf" || note "the form of nr does not name its blocker q1: $(snip "$(cat "$T/vf")")"
    vform "$T/page.html" vote rd >/dev/null; grep -q "nothing blocks the vote" "$T/vf" || note "the form of rd (ready) does not say that nothing blocks"
    # a closed discovery takes no vote: the approval of the ticket closes it
    local d="$T/h/specs/vt"; echo "the ticket" > "$d/ticket.txt"
    wr build --dir "$d" subject tk ticket.txt; wr build --dir "$d" add "ticket(tk)"; wr build --dir "$d" attest approval tk 'digest(current)' --by human || note "setup: the approval was refused: $(snip "$err")"; wr build --dir "$d" release
    q "$d" discovery_closed; [ "$rc" = 0 ] || { note "setup: the discovery of vt is not closed"; return; }
    page_ok; [ "$(vform "$T/page.html" vote vt)" = 0 ] || note "a KB with a closed discovery still has a Vote form"
}
t_VS2() {  # c3: Bring to a vote on a KB that is not ready: a letter to the holder; nothing written in the KB
    vs_hub "$T/h"; vs_holder x nr; srvd --hub "$T/h" || return; page_ok || return
    local tok kb="$T/h/specs/nr"; tok=$(pg dtoken "$T/page.html")
    [ "$(vform "$T/page.html" call-vote nr)" = 1 ] || note "nr: no Bring to a vote"
    grep -q 'name="to" value="build"' "$T/vf" || note "the form names no receiver: $(snip "$(cat "$T/vf")")"
    [ "$(vform "$T/page.html" call-vote rd)" = 0 ] || note "rd (ready) has Bring to a vote"
    local before; before=$(sha256sum "$kb/kb.pl")
    review "token=$tok" "hub=$T/h" "item=callvote:$kb" intent=call-vote; code_is 200 "the review of Bring to a vote: $(snip "$(cat "$T/review.html")")" || return
    rj "len(d['letters'])==1 and d['letters'][0]['to']=='build' and 'clear what blocks it and bring the report' in d['letters'][0]['text'] and 'q1' in d['letters'][0]['text'] and d['sends_to']==['/send']"
    [ ! -s "$T/h/flow/desk/letters.jsonl" ] || note "the review sent a letter"
    local lt; lt=$(python3 -I -c "import json,sys; print(json.load(open(sys.argv[1]))['letters'][0]['text'])" "$T/review.json")
    post /send "token=$tok" "hub=$T/h" "item=callvote:$kb" intent=call-vote "letter_0=$lt" to_0=build; code_is 303 "send Bring to a vote: $(snip "$(cat "$T/post.html")")"
    grep -q "clear what blocks it and bring the report" "$T/h/flow/desk/letters.jsonl" 2>/dev/null || note "no letter in the store of the Desk: $(snip "$(cat "$T/h/flow/desk/letters.jsonl" 2>&1)")"
    [ "$(sha256sum "$kb/kb.pl")" = "$before" ] || note "Bring to a vote changed the KB"
    review "token=$tok" "hub=$T/h" "item=callvote:$T/h/specs/rd" intent=call-vote; code_is 409 "Bring to a vote on a ready KB"
}
t_VS3() {  # c1, c8: the Desk records Ty's vote; GO on a KB that is not ready does not win; HOLD counts; GO on a ready KB wins
    vs_hub "$T/h"; srvd --hub "$T/h" || return; page_ok || return
    local tok nr="$T/h/specs/nr" rd="$T/h/specs/rd"; tok=$(pg dtoken "$T/page.html")
    review "token=$tok" "hub=$T/h" "item=vote:$nr" intent=vote; code_is 400 "a vote with no choice"
    review "token=$tok" "hub=$T/h" "item=vote:$nr" intent=vote choice=maybe; code_is 400 "a vote with a choice that is none of the three"
    review "token=$tok" "hub=$T/h" "item=vote:$nr" intent=vote choice=go 'text=I want this one'; code_is 200 "the review of a GO" || return
    rj "any('your vote go in round 1' in r for r in d['records']) and d['sends_to']==['/send']"
    hasnt_goal "$nr" "vote_cast(human, _, _)" "the review wrote the vote"
    post /send "token=$tok" "hub=$T/h" "item=vote:$nr" intent=vote choice=go 'text=I want this one'; code_is 303 "send the vote: $(snip "$(cat "$T/post.html")")"
    has_goal "$nr" "vote_cast(human, 1, go)" "the GO of the human on the KB that is not ready is in the KB"
    grep -q "attest(a[0-9]*, vote, r1, vote(1, go), human," "$nr/kb.pl" || note "the vote is not a record of the human: $(snip "$(tail -4 "$nr/kb.pl")")"
    gate_not "$nr" go "the gate of nr after a GO while the KB is not ready"; gate_is "$nr" hold "the gate of nr after a GO while not ready"
    post /send "token=$tok" "hub=$T/h" "item=vote:$rd" intent=vote choice=go; code_is 303 "send GO on the ready KB: $(snip "$(cat "$T/post.html")")"
    gate_is "$rd" go "a GO of the human on the ready KB (the artifacts agree)"
    # a second vote of the human is a new round
    post /send "token=$tok" "hub=$T/h" "item=vote:$rd" intent=vote choice=hold; code_is 303 "a second vote"
    has_goal "$rd" "vote_cast(human, 2, hold)" "the second vote is round 2"; gate_is "$rd" hold "a HOLD of the human counts at once"
    page_ok; vform "$T/page.html" vote rd >/dev/null; grep -q "Your vote counts" "$T/vf" || note "the sheet does not show Ty's vote"
}
t_VS4() {  # c6, c7: a change after the vote takes it back and the sheet says what changed; a note keeps it
    vs_hub "$T/h"; srvd --hub "$T/h" || return; page_ok || return
    local tok vt="$T/h/specs/vt"; tok=$(pg dtoken "$T/page.html")
    gate_is "$vt" go "the fixture vt"
    wr build --dir "$vt" add "note(c1, 'A note.')" "finding(f9, trace('A trace.'), system)"; wr build --dir "$vt" run k1 -- true; wr build --dir "$vt" release
    gate_is "$vt" go "the gate after a note, a finding and a run"
    wr build --dir "$vt" add "check(k2, c1)" "checks_that(k2, 'a second check')" || note "the check was refused: $(snip "$err")"; wr build --dir "$vt" release
    gate_not "$vt" go "the gate after a new check"
    grep -q "vote(1, go), human" "$vt/kb.pl" || note "the old vote is gone from the KB"
    page_ok; vform "$T/page.html" vote vt >/dev/null
    grep -q "no longer counts" "$T/vf" && grep -q "check k2 added to c1" "$T/vf" || note "the sheet does not say what changed: $(snip "$(cat "$T/vf")")"
    wr build --dir "$vt" run k2 -- false; wr build --dir "$vt" add "discovery_evidence(k2, system)"; wr build --dir "$vt" attest vote r1 'vote(2, go)'; wr build --dir "$vt" release
    post /send "token=$tok" "hub=$T/h" "item=vote:$vt" intent=vote choice=go; code_is 303 "the vote in the new round: $(snip "$(cat "$T/post.html")")"
    has_goal "$vt" "vote_cast(human, 2, go)" "the new vote is round 2"
    gate_is "$vt" go "the gate after the vote in the new round"
}
t_VS5() {  # c6: the engine rule alone, kind by kind; a vote after a valid approval is not taken back
    local ch d
    for ch in claim check example hypothesis goal retired supersedes; do d="$T/e-$ch"; vs_kb "$d" voted || return; gate_is "$d" go "fixture for $ch"
        case $ch in
        claim)      wr build --dir "$d" add "claim(c2, introduce, 'A second claim.')" "cites(c2, 'a request')" "example(c2, 'A case.')" "check(k2, c2)" "checks_that(k2, 'it checks')" "predicts(hy1, c2)" ;;
        check)      wr build --dir "$d" add "check(k3, c1)" "checks_that(k3, 'another check')" ;;
        example)    wr build --dir "$d" add "example(c1, 'Another case.')" ;;
        hypothesis) wr build --dir "$d" add "hypothesis(hy2, g1, agent, 'Another avenue.')" "defeating_case(hy2, agent, 'A case.')" "no_premises(hy2)" ;;
        goal)       wr build --dir "$d" add "goal(g2, feature, agent, 'A newer goal.')" "supersedes(g2, g1)" "no_premises(g2)" "carried(hy1, g2)" ;;
        retired)    wr build --dir "$d" add "hypothesis(hy2, g1, agent, 'Another avenue.')" "defeating_case(hy2, agent, 'A case.')" "no_premises(hy2)" ;;
        supersedes) wr build --dir "$d" add "claim(c2, introduce, 'A newer claim.')" "cites(c2, 'a request')" "example(c2, 'A case.')" "check(k2, c2)" "checks_that(k2, 'it checks')" "predicts(hy1, c2)" "supersedes(c2, c1)" ;;
        esac || { note "the change ($ch) was refused: $(snip "$err")"; continue; }
        if [ $ch = retired ]; then wr build --dir "$d" attest retirement hy2 'retired(done)' --by agent >/dev/null; fi
        wr build --dir "$d" release
        gate_not "$d" go "a $ch after the vote"
    done
    for ch in note run finding answer; do d="$T/k-$ch"; vs_kb "$d" voted || return
        case $ch in
        note)    wr build --dir "$d" add "note(c1, 'A note.')" ;;
        run)     wr build --dir "$d" run k1 -- true ;;
        finding) wr build --dir "$d" add "finding(f9, trace('A trace.'), system)" ;;
        answer)  wr build --dir "$d" add "question(q9, hy1, 'A dormant question?')" "option(q9, 'A', 'a')" "assumed(q9, 'A')" && wr build --dir "$d" add "answer(q9, 'A', agent)" ;;
        esac || { note "the record ($ch) was refused: $(snip "$err")"; continue; }
        wr build --dir "$d" release; gate_is "$d" go "a $ch after the vote"
    done
    # a vote after the change is not taken back by that change; a vote and then a change and then a vote
    d="$T/e-again"; vs_kb "$d" voted; wr build --dir "$d" add "example(c1, 'Another case.')"
    wr build --dir "$d" attest vote r1 'vote(2, go)'; wr build --dir "$d" attest vote r1 'vote(2, go)' --by human; wr build --dir "$d" release
    gate_is "$d" go "a vote of round 2 after the change"
    # a closed discovery (the human approved the ticket while the gate was go) keeps its vote when build changes the specification
    d="$T/e-closed"; vs_kb "$d" voted; echo "the ticket" > "$d/ticket.txt"
    wr build --dir "$d" subject tk ticket.txt; wr build --dir "$d" add "ticket(tk)"; wr build --dir "$d" attest approval tk 'digest(current)' --by human || note "setup: the approval was refused: $(snip "$err")"
    q "$d" discovery_closed; [ "$rc" = 0 ] || note "setup: the discovery is not closed"
    wr build --dir "$d" add "example(c1, 'A case that build adds after the approval.')" "check(k5, c1)" "checks_that(k5, 'a build check')"; wr build --dir "$d" release
    gate_is "$d" go "the vote of a closed discovery after a change of build"
}
for n in 1 2 3 4 5; do run_one VS$n; done
echo "orbit-kb=$OKB lib=$LIB pass=$pass fail=$fail skip=$skip ${failed[*]:-}"
[ "$fail" -eq 0 ]

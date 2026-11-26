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
#   VS6 c9, c10: after the GO the sheet shows the ticket text and Approve (the digest of that text); the approval is
#       recorded as Ty's; a text that changed makes it stale and the sheet asks again; an old digest is refused
#   VS7 c11: a change that Ty voted on himself (a vote that names the record, with the choice of the standing vote,
#       after the change) joins his vote; the others open the gate; the sheet lists only those
#   VS9 c13: a KB made by 0.10.1 with a vote and a change after it: ED12 and hold before the migration; after migrate
#       (vote_epoch(N)) the gate is go and lint has no ED12; a change after the upgrade takes the vote back
#   VS5 c6: the engine rule alone (orbit-kb query): each kind of change voids; each other record keeps the vote;
#       a vote after a valid approval of the ticket (closed discovery) is not taken back
QS_LIB_ONLY=1
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)/test_question_server.sh" "$@"

# vs_kb DIR notready|ready|voted: a KB in discovery, made with the tool (as vote_start.sh does)
vs_kb() { local d=$1 x=${3:-}
    wr build init "$d" --request "a request" --uses discovery || { note "setup: no KB $d: $(snip "$err")"; return 1; }
    wr build --dir "$d" add "goal(g1, feature, agent, 'A goal.')" "no_premises(g1)" "hypothesis(hy1, g1, agent, 'An avenue.')" "defeating_case(hy1, agent, 'A case.')" "no_premises(hy1)" \
        "claim(c1, introduce, 'A claim.')" "cites(c1, 'a request')" "example(c1, 'A case.')" "check(k1, c1)" "checks_that(k1, 'it checks')" "predicts(hy1, c1)" || { note "setup: facts refused: $(snip "$err")"; return 1; }
    [ "$x" = hy2 ] && { wr build --dir "$d" add "hypothesis(hy2, g1, agent, 'A second avenue.')" "defeating_case(hy2, agent, 'A case.')" "no_premises(hy2)" || note "setup: hy2 refused: $(snip "$err")"; }
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
    vform "$T/page.html" vote nr >/dev/null; local href; href=$(grep -oE 'href="#report-[^"]*"[^>]*>Read the report' "$T/vf" | grep -oE '#report-[^"]*' | head -1)
    [ -n "$href" ] && grep -q "id=\"${href#\#}\"" "$T/page.html" || note "the link Read the report ($href) names no element of the page (anchors: $(grep -oE 'id="report-[^"]*"' "$T/page.html" | head -2 | tr '\n' ' '))"
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
t_VS2b() {  # c3: with no holder the letter goes to the keeper: the form names a receiver, the review says so, the send is accepted
    vs_hub "$T/h"; srvd --hub "$T/h" || return; page_ok || return
    local tok kb="$T/h/specs/nr" lt to; tok=$(pg dtoken "$T/page.html")
    vform "$T/page.html" call-vote nr >/dev/null; to=$(grep -oE 'name="to" value="[^"]*"' "$T/vf" | head -1 | sed 's/.*value="//; s/"//')
    [ -n "$to" ] || { note "no holder and the form has an empty receiver: $(snip "$(cat "$T/vf")")"; return; }
    review "token=$tok" "hub=$T/h" "item=callvote:$kb" intent=call-vote; code_is 200 "the review with no holder" || return
    rj "len(d['letters'])==1 and d['letters'][0]['to']=='$to'"
    grep -qi "keeper" "$T/review.html" || note "the review does not say that the keeper gets the letter"
    lt=$(python3 -I -c "import json,sys; print(json.load(open(sys.argv[1]))['letters'][0]['text'])" "$T/review.json")
    post /send "token=$tok" "hub=$T/h" "item=callvote:$kb" intent=call-vote "letter_0=$lt" "to_0=$to"; code_is 303 "send to the keeper: $(grep -o "message[^<]*<[^<]*" "$T/post.html" | head -2)"
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
    gate_is "$vt" hold "the gate after a new check: the vote is taken back, the gate says hold"
    grep -q "vote(1, go), human" "$vt/kb.pl" || note "the old vote is gone from the KB"
    # the sheet is read up to 5 times, a second apart: a page that was made while the KB was being written may be one version behind
    local try ok=0; for try in 1 2 3 4 5; do page_ok; vform "$T/page.html" vote vt >/dev/null
        if grep -q "no longer counts" "$T/vf" && grep -q "check k2 added to c1" "$T/vf"; then ok=1; break; fi; sleep 1; done
    [ $ok = 1 ] || note "the sheet does not say what changed (5 reads): $(snip "$(cat "$T/vf")")"
    wr build --dir "$vt" run k2 -- false; wr build --dir "$vt" add "discovery_evidence(k2, system)"; wr build --dir "$vt" attest vote r1 'vote(2, go)'; wr build --dir "$vt" release
    post /send "token=$tok" "hub=$T/h" "item=vote:$vt" intent=vote choice=go; code_is 303 "the vote in the new round: $(snip "$(cat "$T/post.html")")"
    has_goal "$vt" "vote_cast(human, 2, go)" "the new vote is round 2"
    gate_is "$vt" go "the gate after the vote in the new round"
}
t_VS5() {  # c6: the engine rule alone, kind by kind; a vote after a valid approval is not taken back
    local ch d
    vs_kb "$T/lint" voted && { wr build --dir "$T/lint" lint; [ "$rc" = 0 ] || note "lint of a KB with a vote: exit $rc: $(snip "$out")"; }
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
t_VS6() {  # c9, c10: after the GO the sheet shows the ticket text and Approve with its digest; the approval is recorded; a changed text makes it stale
    vs_hub "$T/h"; vs_holder x vt; local vt="$T/h/specs/vt" tok dg dg2 lt
    printf '# Delivered:\n\nTICKETPROBE-4471 the words of the ticket.\n\n- one point\n- another point\n' > "$vt/TICKET.md"
    wr build --dir "$vt" subject tk TICKET.md; wr build --dir "$vt" add "ticket(tk)" || note "setup: ticket refused: $(snip "$err")"; wr build --dir "$vt" release
    srvd --hub "$T/h" || return; page_ok || return; tok=$(pg dtoken "$T/page.html")
    grep -q "TICKETPROBE-4471" "$T/page.html" && grep -q "<li>one point</li>" "$T/page.html" || note "the text of the ticket (as a page) is not on the sheet"
    [ "$(vform "$T/page.html" approve vt)" = 1 ] || { note "no Approve form on vt"; return; }
    dg=$(grep -oE 'sha256:[0-9a-f]{64}' "$T/vf" | head -1); [ "$dg" = "sha256:$(sha256sum "$vt/TICKET.md" | cut -d' ' -f1)" ] || note "the form names the digest $dg, not that of the text"
    [ "$(vform "$T/page.html" approve rd)" = 0 ] && [ "$(vform "$T/page.html" approve nr)" = 0 ] || note "a KB with no ticket has an Approve form"
    review "token=$tok" "hub=$T/h" "item=approve:$vt" intent=approve "digest=$dg"; code_is 200 "the review of Approve: $(snip "$(cat "$T/review.html")")" || return
    rj "any('your approval of the ticket tk' in r for r in d['records']) and d['sends_to']==['/send']"
    hasnt_goal "$vt" "attest(_, approval, tk, _, human, _)" "the review wrote the approval"
    lt=$(python3 -I -c "import json,sys; print(json.load(open(sys.argv[1]))['letters'][0]['text'])" "$T/review.json")
    review "token=$tok" "hub=$T/h" "item=approve:$vt" intent=approve "digest=sha256:$(printf 'x%.0s' $(seq 64))"; code_is 409 "Approve with a digest that is not the text"
    post /send "token=$tok" "hub=$T/h" "item=approve:$vt" intent=approve "digest=$dg" "letter_0=$lt" to_0=build; code_is 303 "send Approve: $(grep -o "message[^<]*<[^<]*" "$T/post.html" | head -2)"
    has_goal "$vt" "attest(_, approval, tk, digest('$dg'), human, _)" "the approval of the human names the digest"
    has_goal "$vt" "discovery_closed" "the approval ended the discovery orbit"
    page_ok; [ "$(vform "$T/page.html" approve vt)" = 0 ] && grep -q "You approved this text" "$T/page.html" || note "after the approval the sheet still asks, or does not say that Ty approved"
    # c10: the text changes; the approval is stale; the sheet asks again with the new text
    printf '# Delivered:\n\nTICKETPROBE-9902 the new words of the ticket.\n' > "$vt/TICKET.md"
    review "token=$tok" "hub=$T/h" "item=approve:$vt" intent=approve "digest=$dg"; code_is 409 "Approve of the old digest after the text changed"
    wr build --dir "$vt" subject tk TICKET.md; wr build --dir "$vt" release
    has_goal "$vt" "stale(_)" "the approval is stale after the new subject"
    page_ok; grep -q "TICKETPROBE-9902" "$T/page.html" && ! grep -q "TICKETPROBE-4471" "$T/page.html" || note "the sheet does not show the new text"
    [ "$(vform "$T/page.html" approve vt)" = 1 ] && grep -q "stale" "$T/vf" || note "the sheet does not ask again, or does not say stale"
    dg2=$(grep -oE 'sha256:[0-9a-f]{64}' "$T/vf" | head -1); [ "$dg2" != "$dg" ] || note "the new form names the old digest"
    review "token=$tok" "hub=$T/h" "item=approve:$vt" intent=approve "digest=$dg"; code_is 409 "Approve of the old digest"
    review "token=$tok" "hub=$T/h" "item=approve:$vt" intent=approve "digest=$dg2"; code_is 200 "the review of Approve of the new text"
}
t_VS7() {  # c11 (Ty r4): a change that Ty voted on himself joins his vote; a change he did not vote on opens the gate
    local d="$T/c" t
    vs_kb "$d" voted || return; gate_is "$d" go "the fixture"
    addclaim() { wr build --dir "$d" add "claim($1, introduce, 'Claim $1.')" "cites($1, 'a request')" "example($1, 'A case.')" "check($2, $1)" "checks_that($2, 'it checks')" "predicts(hy1, $1)" || note "the claim $1 was refused: $(snip "$err")"; }
    addclaim c2 k2; addclaim c3 k3; gate_is "$d" hold "two changes, no vote on them"
    wr build --dir "$d" attest vote c3 'vote(1, go)' --by human || note "the vote on c3 was refused: $(snip "$err")"
    gate_not "$d" go "a vote on c3 only does not cover c2"
    wr build --dir "$d" attest vote c2 'vote(1, hold)' --by human || note "the vote on c2 was refused"
    gate_not "$d" go "a HOLD on c2 does not carry a GO"
    wr build --dir "$d" attest vote c2 'vote(1, go)' --by human || note "the vote on c2 was refused"
    gate_is "$d" go "votes on c2 and c3 carry the vote: no new round"
    q "$d" 'vote_cast(human, 1, go)'; [ "$rc" = 0 ] || note "the vote of round 1 does not count any more"
    q "$d" 'vote_cast(human, 2, _)'; [ "$rc" = 1 ] || note "a carry vote made a round 2"
    addclaim c4 k4; gate_not "$d" go "c4, which he did not vote on, opens the gate"
    # a vote on a record BEFORE the change does not cover it
    d="$T/c2"; vs_kb "$d" voted; wr build --dir "$d" add "claim(c2, introduce, 'Claim c2.')" "cites(c2, 'a request')" "example(c2, 'A case.')" "check(k2, c2)" "checks_that(k2, 'it checks')" "predicts(hy1, c2)"; wr build --dir "$d" attest vote c2 'vote(1, go)' --by human; wr build --dir "$d" add "example(c2, 'A second case.')"
    gate_not "$d" go "a vote on c2 before a later change of c2 does not cover it"
    wr build --dir "$d" lint; [ "$rc" = 0 ] || note "lint of a KB with carry votes: exit $rc: $(snip "$out")"
    # the Desk lists only the changes that he did not vote on
    d="$T/h"; vs_hub "$d"; t="$d/specs/vt"; wr build --dir "$t" add "claim(c2, introduce, 'Claim c2.')" "cites(c2, 'a request')" "example(c2, 'A case.')" "check(k2, c2)" "checks_that(k2, 'it checks')" "predicts(hy1, c2)" "claim(c3, introduce, 'Claim c3.')" "cites(c3, 'a request')" "example(c3, 'A case.')" "check(k3, c3)" "checks_that(k3, 'it checks')" "predicts(hy1, c3)"
    wr build --dir "$t" attest vote c2 'vote(1, go)' --by human; wr build --dir "$t" release
    srvd --hub "$d" || return; page_ok || return; vform "$T/page.html" vote vt >/dev/null
    grep -q "claim c3 added" "$T/vf" && ! grep -q "claim c2 added" "$T/vf" || note "the sheet does not list only c3 as changed: $(snip "$(cat "$T/vf")")"
}
t_VS8() {  # c11 (review): a retirement after the vote opens the gate; the migration record retired/3 is no change of the specification
    local d="$T/rt"; vs_kb "$d" voted hy2 || return; gate_is "$d" go "the fixture with hy2"
    wr build --dir "$d" retire hy2 'no longer an avenue' >/dev/null; [ "$rc" = 0 ] || { wr build --dir "$d" attest retirement hy2 "retired('no longer an avenue')" --by agent; [ "$rc" = 0 ] || note "setup: retire refused: $(snip "$err")"; }
    wr build --dir "$d" release; gate_not "$d" go "a hypothesis retired after the vote"
    d="$T/mig"; vs_kb "$d" voted || return; wr build --dir "$d" add "retired(foo/2, '0.9.0', 'bar')" || note "setup: the migration record was refused: $(snip "$err")"
    wr build --dir "$d" release; gate_is "$d" go "a migration record retired/3 after the vote"
}
t_VS9() {  # c13 (Ty q4): votes and approvals from before the upgrade keep counting; changes from the upgrade on take a vote back
    local OLD=${OLD:-/home/ty/Projects/mine/sagittarius/kb/bin/orbit-kb} d="$T/old" pl dg l
    [ -x "$OLD" ] || { SKIPPED=1; return; }
    ( cd "$T" && ORBIT_KB_WRITER=build "$OLD" init "$d" --request "a request" --uses discovery ) >/dev/null 2>&1 || { note "setup: the old tool made no KB"; return; }
    oldw() { ( cd "$T" && ORBIT_KB_WRITER=build "$OLD" --dir "$d" "$@" ) >"$T/.out" 2>"$T/.err" </dev/null; rc=$?; out=$(<"$T/.out"); err=$(<"$T/.err"); }
    oldw add "goal(g1, feature, agent, 'A goal.')" "no_premises(g1)" "hypothesis(hy1, g1, agent, 'An avenue.')" "defeating_case(hy1, agent, 'A case.')" "no_premises(hy1)" "claim(c1, introduce, 'A claim.')" "cites(c1, 'a request')" "example(c1, 'A case.')" "check(k1, c1)" "checks_that(k1, 'it checks')" "predicts(hy1, c1)"
    oldw run k1 -- false; oldw add "discovery_evidence(k1, system)"; oldw attest vote r1 'vote(1, go)'; oldw attest vote r1 'vote(1, go)' --by human
    oldw add "claim(c2, introduce, 'A later claim.')" "cites(c2, 'a request')" "example(c2, 'A case.')" "check(k2, c2)" "checks_that(k2, 'it checks too')" "predicts(hy1, c2)"
    echo "the ticket" > "$d/ticket.txt"; oldw subject tk ticket.txt; oldw add "ticket(tk)"; oldw attest approval tk 'digest(current)' --by human; oldw release
    q "$d" discovery_closed; [ "$rc" = 0 ] || { note "setup: the old tool did not close the orbit (rc $rc)"; return; }
    wr build --dir "$d" lint; echo "$out" | grep -q ED12 && note "before the migration (a frozen KB is never migrated) the new tool reads the old history as ED12: $(grep ED12 <<<"$out" | head -1 | cut -c1-200)"
    gate_is "$d" go "the closed old KB before any migration (it reads as wholly from before the upgrade)"
    q "$d" 'vote_epoch_needed(_)'; [ "$rc" = 0 ] || note "the KB made before 0.11.0 does not ask for vote_epoch"
    wr build --dir "$d" migrate plan --old "$OLD"; pl=$out; dg=$(grep -o 'sha256:[0-9a-f]\{64\}' <<<"$pl" | tail -1)
    [ -n "$dg" ] || { note "migrate plan gave no digest: $(snip "$pl")"; return; }
    wr build --dir "$d" migrate apply --seen "$dg" --old "$OLD" || note "migrate apply: $(snip "$err")"; wr build --dir "$d" release
    grep -q "^vote_epoch(" "$d/kb.pl" || note "the migration wrote no vote_epoch"
    wr build --dir "$d" lint; echo "$out" | grep -q ED12 && note "ED12 after the migration: $(grep ED12 <<<"$out" | head -1 | cut -c1-200)"
    gate_is "$d" go "the gate after the upgrade"; q "$d" 'vote_epoch_needed(_)'; [ "$rc" = 1 ] || note "the KB still asks for vote_epoch after the migration"
    # a vote not yet closed: a change before the upgrade keeps it, a change after it takes it back
    d="$T/open"; ( cd "$T" && ORBIT_KB_WRITER=build "$OLD" init "$d" --request "a request" --uses discovery ) >/dev/null 2>&1
    oldw add "goal(g1, feature, agent, 'A goal.')" "no_premises(g1)" "hypothesis(hy1, g1, agent, 'An avenue.')" "defeating_case(hy1, agent, 'A case.')" "no_premises(hy1)" "claim(c1, introduce, 'A claim.')" "cites(c1, 'a request')" "example(c1, 'A case.')" "check(k1, c1)" "checks_that(k1, 'it checks')" "predicts(hy1, c1)"
    oldw run k1 -- false; oldw add "discovery_evidence(k1, system)"; oldw attest vote r1 'vote(1, go)'; oldw attest vote r1 'vote(1, go)' --by human
    oldw add "claim(c2, introduce, 'A later claim.')" "cites(c2, 'a request')" "example(c2, 'A case.')" "check(k2, c2)" "checks_that(k2, 'it checks too')" "predicts(hy1, c2)"; oldw release
    gate_is "$d" go "an old change, before the migration: the KB made before 0.11.0 reads as wholly from before the upgrade"
    wr build --dir "$d" migrate plan --old "$OLD"; dg=$(grep -o 'sha256:[0-9a-f]\{64\}' <<<"$out" | tail -1); wr build --dir "$d" migrate apply --seen "$dg" --old "$OLD"; wr build --dir "$d" release
    gate_is "$d" go "the gate after the migration: the change from before the upgrade keeps the vote"
    wr build --dir "$d" add "claim(c3, introduce, 'A claim after the upgrade.')" "cites(c3, 'a request')" "example(c3, 'A case.')" "check(k3, c3)" "checks_that(k3, 'it checks three')" "predicts(hy1, c3)"; wr build --dir "$d" release
    gate_not "$d" go "a change after the upgrade takes the vote back"
    # case B (review): the new tool writes to an old KB before migrate: its first write records vote_epoch first, so its change counts
    d="$T/b"; ( cd "$T" && ORBIT_KB_WRITER=build "$OLD" init "$d" --request "a request" --uses discovery ) >/dev/null 2>&1
    oldw add "goal(g1, feature, agent, 'A goal.')" "no_premises(g1)" "hypothesis(hy1, g1, agent, 'An avenue.')" "defeating_case(hy1, agent, 'A case.')" "no_premises(hy1)" "claim(c1, introduce, 'A claim.')" "cites(c1, 'a request')" "example(c1, 'A case.')" "check(k1, c1)" "checks_that(k1, 'it checks')" "predicts(hy1, c1)"
    oldw run k1 -- false; oldw add "discovery_evidence(k1, system)"; oldw attest vote r1 'vote(1, go)'; oldw attest vote r1 'vote(1, go)' --by human; oldw release
    wr build --dir "$d" add "claim(c3, introduce, 'A claim of the new tool.')" "cites(c3, 'a request')" "example(c3, 'A case.')" "check(k3, c3)" "checks_that(k3, 'it checks three')" "predicts(hy1, c3)"; wr build --dir "$d" release
    grep -q "^vote_epoch(" "$d/kb.pl" || note "the first write of the new tool wrote no vote_epoch"
    gate_not "$d" go "a claim that the new tool added before migrate counts"
    wr build --dir "$d" migrate plan --old "$OLD"; dg=$(grep -o 'sha256:[0-9a-f]\{64\}' <<<"$out" | tail -1); [ -n "$dg" ] && { wr build --dir "$d" migrate apply --seen "$dg" --old "$OLD"; wr build --dir "$d" release; }
    [ "$(grep -c '^vote_epoch(' "$d/kb.pl")" = 1 ] || note "two vote_epoch lines after migrate: $(grep '^vote_epoch(' "$d/kb.pl" | tr '\n' ' ')"
    gate_not "$d" go "after migrate the claim of the new tool still counts"
    # add refuses vote_epoch (CONTRACT: the tool writes it)
    wr build --dir "$d" add "vote_epoch(100000)"; [ "$rc" != 0 ] || note "add took vote_epoch/1"
}
for n in 1 2 2b 3 4 5 6 7 8 9; do run_one VS$n; done
echo "orbit-kb=$OKB lib=$LIB pass=$pass fail=$fail skip=$skip ${failed[*]:-}"
[ "$fail" -eq 0 ]

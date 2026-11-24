#!/usr/bin/env bash
# The Desk shows the records of 0.8.0 (ticket scientific-method-overhaul, claim c24; CONTRACT D72).
# It reads the harness of test_question_server.sh (the helpers, the fixtures, the runner) and runs
# only its own tests. Usage: kb/tests/test_desk_records.sh [path-to-orbit-kb]   ONLY='<regex>'
#   DR1 the card of a ticket: the goal with its author, each hypothesis with author and state
#   DR2 an unresolved verdict apart from a failing check; a KB of 0.7.2: its hypothesis is the goal
#   DR3 Adopt: the review first, then the adoption of the human in the KB
#   DR4 judge a case, judge the goal: the review first, then the judgment of the human in the KB
#   DR5 the set of items equals that of the Desk of 0.7.2 on the same hub
#   DR6 the labels carry the canonical sentences of vocabulary.json
#   DR7 the same in a headless Chromium (k24); SKIP with no Chromium or no Node 22
# The Desk of 0.7.2 for DR5: $ORBIT_KB_BASE (a checkout of 0.7.2), else git archive v0.7.2 of this repo.
QS_LIB_ONLY=1
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)/test_question_server.sh" "$@"

# kb_records DIR: a ticket in the new form: a goal of Ty, four hypotheses (defeated, proposed,
# adopted and not tempered, retired), one that cites words of Ty, and checks: pass, fail, unresolved.
kb_records() { kb_new "$1" <<'EOF2'
uses([build]).
request(r1, 'A replayed import must not change the member records').
goal(g1, defect, human:'Ty', 'A replayed import leaves the member records as one clean run would.').
premise(p1, g1, 'The import file has one record per line.').
hypothesis(hy1, g1, agent, 'Skipping each record ID that was seen before makes a replay safe.').
defeating_case(hy1, agent, 'A replay that leaves a duplicate member record.').
defeat(d1, hy1, 'A correction arrives under a seen ID and is discarded.').
hypothesis(hy2, g1, agent, 'Skipping only a record that equals the stored one makes a replay safe.').
defeating_case(hy2, agent, 'A replay that changes a member record.').
hypothesis(hy3, g1, human:'Ty', 'Sending each changed record to review makes a replay safe.').
attest(a1, adoption, hy3, adopted, human, '2026-11-23T10:00:00Z').
hypothesis(hy4, g1, agent, 'Hashing each record makes a replay safe.').
defeating_case(hy4, agent, 'Two records with one hash.').
attest(a2, retirement, hy4, retired('Too slow on the large file'), agent, '2026-11-23T10:05:00Z').
hypothesis(hy5, g1, agent, 'A lock on the import file makes a replay safe.').
defeating_case(hy5, agent, 'Two imports that run at one time.').
adoption_cited(hy5, 'lock the file, that is the way').
claim(c1, introduce, 'After a replay the member count equals the count of one clean run').
predicts(hy2, c1).
claim(c2, preserve, 'The notification count stays as it is today').
check(k1, c1).
checks_that(k1, 'the member count after a replay of the November file').
check(k2, c1).
checks_that(k2, 'the member count after a replay of an empty file').
check(k3, c2).
checks_that(k3, 'the notification count after a replay').
attest(a3, test_result, 'runs/1-k1.log', result(k1, 1, pass), script, '2026-11-23T11:00:00Z').
attest(a4, test_result, 'runs/2-k2.log', result(k2, 2, fail), script, '2026-11-23T11:01:00Z').
attest(a5, test_result, 'runs/3-k3.log', result(k3, 3, unresolved), script, '2026-11-23T11:02:00Z').
unresolved_because(a5, 'killed by signal 9').
EOF2
}
# browse URL JSFILE [PNG]: as the harness, and with PNG a screenshot of the viewport after the script
browse() { local cb nd prof="$T/chrome" cpid
    cb=$(command -v chromium-browser || command -v chromium || command -v google-chrome) || { SKIPPED=1; return 1; }
    nd=$(command -v node) && "$nd" -e 'process.exit(typeof WebSocket==="function"?0:1)' || { SKIPPED=1; return 1; }
    rm -rf "$prof"; mkdir -p "$prof"
    "$cb" --headless --disable-gpu --no-first-run --no-default-browser-check --user-data-dir="$prof" --remote-debugging-port=0 about:blank >/dev/null 2>&1 &
    cpid=$!
    BR=$(timeout 90 "$nd" "$REPO/kb/tests/desk_browser.js" "$prof" "$1" "$2" ${3:+"$3"} 2>"$T/.br.err"); local r=$?
    kill "$cpid" 2>/dev/null; wait "$cpid" 2>/dev/null
    [ $r = 0 ] || { note "the browser run failed: $(snip "$(cat "$T/.br.err")")"; return 1; }
}
rec_hub() { mkdesk "$1"; kb_records "$1/specs/replay"; kb_project "$1/project-kb" 'Import project'; }
# kbsec FILE LABEL: the text of the card of the ticket (details.kbsec), and its raw HTML in $T/sec.html
sec() { python3 -I - "$1" "$2" > "$T/sec.html" <<'PY'
import re,sys
p=open(sys.argv[1],encoding='utf-8').read()
for m in re.finditer(r'<details class="sheet kbsec"', p):
    e=p.find('<details class="sheet kbsec"', m.end()); b=p[m.start(): e if e>0 else len(p)]
    if '<h3 class="title">%s</h3>' % sys.argv[2] in b: print(b); sys.exit(0)
sys.exit(1)
PY
}
badge_of() { python3 -I -c "import re,sys; b=open(sys.argv[1],encoding='utf-8').read(); m=re.search(r'<div class=\"chk\"><span class=\"ref\">%s</span>.*?<span class=\"badge status ([a-z-]+)\">([^<]*)</span>' % sys.argv[2], b, re.S); print(m.group(1), m.group(2)) if m else sys.exit(1)" "$T/sec.html" "$1"; }

t_DR1() {  # the goal first with its author, then each hypothesis with its author and its state
    rec_hub "$T/h"; srvd --hub "$T/h" || return; page_ok || return
    chk raw "$T/page.html" '!class="banner error"' '!cannot be read'
    chk dkb "$T/page.html" replay 'Goal (Ty)' 'A replayed import leaves the member records as one clean run would.' 'The import file has one record per line.' \
        'Hypothesis hy1 (agent-written, defeated)' 'Defeated by the case: A correction arrives under a seen ID and is discarded.' \
        'Hypothesis hy2 (agent-written, not adopted)' 'It is false if: A replay that changes a member record.' \
        'Hypothesis hy3 (Ty-written, adopted)' 'not tempered' 'Hypothesis hy4 (agent-written, retired)' \
        'Hypothesis hy5 (agent-written, not adopted)' "proposed: the agent reads your words as adoption: 'lock the file, that is the way' (Adopt to confirm)" \
        '!No hypothesis: the claims hang on the goal.'
    sec "$T/page.html" replay || { note "no card of the ticket replay"; return; }
    python3 -I - "$T/sec.html" <<'PY' || note "the card: the order (goal, hypotheses, claims), a state, or an Adopt action is wrong"
import re,sys
b=open(sys.argv[1],encoding='utf-8').read()
g=b.find('Goal</span> (Ty)'); h=b.find('data-hyp="hy1"'); c=b.find('Claims')
assert 0<=g<h<c, (g,h,c)
def blk(i): m=re.search(r'<div class="hyp s-(\w+)" data-hyp="%s">(.*?)(?=<div class="hyp |<h4>Your|<form class="judge"|<h3>)' % i, b, re.S); return m.group(1), m.group(2)
for i,st,adopt in [('hy1','defeated',0),('hy2','proposed',1),('hy3','adopted',0),('hy4','retired',0),('hy5','proposed',1)]:
    s,t=blk(i); assert s==st, (i,s)
    assert (('value="adopt:' in t and '>Adopt</button>' in t)==bool(adopt)), (i,'adopt')
PY
}
t_DR2() {  # unresolved apart from a conflict: its own badge and class, with the reason; an old KB shows its hypothesis as the goal
    rec_hub "$T/h"; kb_rests "$T/h/specs/exp"; srvd --hub "$T/h" || return; page_ok || return
    sec "$T/page.html" replay || { note "no card of the ticket replay"; return; }
    [ "$(badge_of k1)" = "b-pass pass" ] || note "k1: $(badge_of k1), want b-pass pass"
    [ "$(badge_of k2)" = "b-burn fail" ] || note "k2: $(badge_of k2), want b-burn fail"
    [ "$(badge_of k3)" = "b-unres unresolved" ] || note "k3: $(badge_of k3), want b-unres unresolved (not the failing badge)"
    chk dkb "$T/page.html" replay 'unresolved: killed by signal 9' '1 unresolved' 'Verdict: meets' 'Verdict: conflicts' '!1 fail 1 fail'
    chk dkb "$T/page.html" exp 'Goal (agent)' 'Every export starts with a header row' 'The exports are written by one writer.' 'No hypothesis: the claims hang on the goal.' '!Adopt'
}
t_DR3() {  # Adopt: nothing is written before the send; the review shows the record; the send writes the adoption of the human
    rec_hub "$T/h"; local kb="$T/h/specs/replay" tok
    srvd --hub "$T/h" || return; page_ok || return; tok=$(pg dtoken "$T/page.html"); chk dforms "$T/page.html"
    review "token=$tok" "hub=$T/h" "item=adopt:$kb#hy2"; code_is 200 "the review of Adopt" || return
    rj "any('your adoption of hypothesis hy2' in r for r in d['records']) and d['sends_to']==['/send']"
    hasnt_goal "$kb" "attest(_, adoption, hy2, adopted, human, _)" "the review wrote the adoption"
    post /send "token=$tok" "hub=$T/h" "item=adopt:$kb#hy2"; code_is 303 "send Adopt: $(snip "$(cat "$T/post.html")")"
    has_goal "$kb" "attest(_, adoption, hy2, adopted, human, _)" "the adoption of the human"
    page_ok; chk dkb "$T/page.html" replay 'Hypothesis hy2 (agent-written, adopted)'
    review "token=$tok" "hub=$T/h" "item=adopt:$kb#hy2"; code_is 409 "Adopt of an adopted hypothesis"
    review "token=$tok" "hub=$T/h" "item=adopt:$kb#hy1"; code_is 409 "Adopt of a defeated hypothesis"
    post /send "token=bad" "hub=$T/h" "item=adopt:$kb#hy5"; code_is 403 "Adopt with no token"
    hasnt_goal "$kb" "attest(_, adoption, hy5, _, _, _)" "hy5 is not adopted: the cited words adopt nothing"
}
t_DR4() {  # judge a case, and the goal: the review first; the send writes the judgment of the human on the goal
    rec_hub "$T/h"; local kb="$T/h/specs/replay" tok
    srvd --hub "$T/h" || return; page_ok || return; tok=$(pg dtoken "$T/page.html")
    grep -q 'data-judge="case"' "$T/page.html" && grep -q 'data-judge="goal"' "$T/page.html" || note "the card has no judgment forms"
    review "token=$tok" "hub=$T/h" "item=judge:$kb" choice=not_wanted 'text=The corrected address of member 12 was dropped'; code_is 200 "the review of a case" || return
    rj "any('member 12' in r and 'not wanted' in r for r in d['records'])"
    hasnt_goal "$kb" "attest(_, judgment, _, _, _, _)" "the review wrote a judgment"
    post /send "token=$tok" "hub=$T/h" "item=judge:$kb" choice=not_wanted 'text=The corrected address of member 12 was dropped'; code_is 303 "send the case: $(snip "$(cat "$T/post.html")")"
    has_goal "$kb" "attest(_, judgment, g1, case('The corrected address of member 12 was dropped', not_wanted), human, _)" "the judgment of the case"
    post /send "token=$tok" "hub=$T/h" "item=judge:$kb" choice=satisfied; code_is 303 "send goal satisfied: $(snip "$(cat "$T/post.html")")"
    has_goal "$kb" "attest(_, judgment, g1, satisfied, human, _)" "the judgment of the goal"
    review "token=$tok" "hub=$T/h" "item=judge:$kb" choice=wanted; code_is 400 "a case with no text"
    review "token=$tok" "hub=$T/h" "item=judge:$kb" 'text=x'; code_is 400 "a judgment with no choice"
    page_ok; chk dkb "$T/page.html" replay 'Your judgments' 'The corrected address of member 12 was dropped' 'not wanted' 'The goal is satisfied'
    q "$kb" "attest(A, judgment, _, _, _, _), attest(B, judgment, _, _, _, _), A \\= B"; [ "$rc" = 0 ] || note "the two judgments do not have two ids"
}
ids_of() { python3 -I -c "
import re,sys
p=open(sys.argv[1],encoding='utf-8').read()
ids=sorted(set(i for i in re.findall(r'\bid=\"([^\"]+)\"',p) if i.startswith(('item-','kb-','lane-'))))
lanes=re.findall(r'<a href=\"#lane-([a-z]+)\">[^<]*<b>(\d+)</b>',p)
rows=sorted(re.sub(r'<[^>]+>',' ',r)[:60] for r in re.findall(r'<tr><td>(.*?)</td>',p,re.S))
print('\n'.join(ids)); print(lanes); print('\n'.join(rows))" "$1"; }
t_DR5() {  # the same hub, read by the Desk of 0.7.2 and by this Desk: the same items, lanes, counts and rows
    local B=${ORBIT_KB_BASE:-} okb0=$OKB lib0=$ORBIT_KB_LIB
    if [ -z "$B" ]; then B="$T/base"; mkdir -p "$B"; git -C "$REPO" archive v0.7.2 kb VERSION 2>/dev/null | tar -x -C "$B" 2>/dev/null; fi
    [ -x "$B/kb/bin/orbit-kb" ] || { SKIPPED=1; return; }
    OKB="$B/kb/bin/orbit-kb"; export ORBIT_KB_LIB="$B/kb/share/orbit-kb"      # 0.7.2 makes the hub, and serves it first
    nav_hub "$T/h"; mkdir -p "$T/h/specs/disc"; cp "$here/fixtures/discovery-a/kb.pl" "$T/h/specs/disc/kb.pl"
    hf "$T/h" --session process add ask --no-kb --title 'Waive the c3 proof' --note 'The case.' --waits-on me --reserved 'Sagittarius Policy: Only the human may waive a proof.' >/dev/null
    echo "proposed(d9)." >> "$T/h/project-kb/kb.pl"
    srvd --hub "$T/h" || { OKB=$okb0; export ORBIT_KB_LIB=$lib0; return; }
    page_ok; ids_of "$T/page.html" > "$T/ids.base"; cp "$T/page.html" "$T/page.base.html"; srv_stop
    OKB=$okb0; export ORBIT_KB_LIB=$lib0; rm -rf "$T/.cache"
    cp "$T/h/specs/exp/kb.pl" "$T/kb.before"
    srvd --hub "$T/h" || return; page_ok || return; ids_of "$T/page.html" > "$T/ids.new"
    [ "$(grep -c '^item-' "$T/ids.base")" -ge 4 ] || note "the fixture shows fewer than 4 items at 0.7.2: $(snip "$(cat "$T/ids.base")")"
    cmp -s "$T/ids.base" "$T/ids.new" || note "the items differ from 0.7.2: $(diff "$T/ids.base" "$T/ids.new" | head -12 | tr '\n' '~')"
    same_file "$T/kb.before" "$T/h/specs/exp/kb.pl" "a GET: the KB"
}
t_DR6() {  # the labels of the eight words come from vocabulary.json: the tooltip is the canonical sentence
    rec_hub "$T/h"; srvd --hub "$T/h" || return; page_ok || return
    python3 -I - "$T/page.html" "$LIB/vocabulary.json" > "$T/voc.txt" <<'PY' || note "vocabulary: $(snip "$(cat "$T/voc.txt")")"
import json,re,sys,html
p=open(sys.argv[1],encoding='utf-8').read(); v=json.load(open(sys.argv[2],encoding='utf-8')); bad=[]
if list(v)!=["goal","hypothesis","premise","claim","specification","experiment","verdict","tempered"]: bad.append("keys %s" % list(v))
for k in ["goal","hypothesis","premise","claim","experiment","verdict","tempered"]:
    ts=set(html.unescape(t) for t in re.findall(r'data-term="%s" title="([^"]*)"' % k, p))
    if ts!={v[k]}: bad.append("%s: %s" % (k, sorted(ts)))
print("\n".join(bad)); sys.exit(1 if bad else 0)
PY
}
t_DR7() {  # k24 in a browser: the card, Adopt through the review dialog, a judged case; each writes a record of the human
    rec_hub "$T/h"; local kb="$T/h/specs/replay"
    srvd --hub "$T/h" || return
    cat > "$T/k24.js" <<'JS'
const sec=[...document.querySelectorAll('details.kbsec')].find(d=>d.querySelector('h3.title').textContent==='replay');
document.getElementById('lane-kbs').open=true; sec.open=true; sec.scrollIntoView();
const out={text:sec.innerText, k3:sec.querySelector('.chk .badge.b-unres') ? sec.querySelector('.chk .badge.b-unres').textContent : null};
const dlg=document.getElementById('review');
async function through(form){
  form.requestSubmit(form.querySelector('button[type=submit]'));
  for(let i=0;i<200 && !dlg.open;i++) await new Promise(r=>setTimeout(r,25));
  const f=dlg.querySelector('form[action="/send"]'); if(!f) return {dialog:dlg.open, html:dlg.innerHTML.slice(0,300)};
  const rec=dlg.innerText; const r=await fetch('/send',{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded'},body:new URLSearchParams(new FormData(f)).toString(),redirect:'manual'});
  dlg.close(); return {dialog:true, rec, status:r.status, type:r.type};
}
out.adopt=await through(sec.querySelector('[data-hyp="hy2"] form'));
const jf=sec.querySelector('form[data-judge="case"]'); jf.querySelector('textarea').value='The corrected address of member 12 was dropped';
jf.querySelector('input[value="not_wanted"]').checked=true;
out.judge=await through(jf);
return out;
JS
    browse "$URL/" "$T/k24.js" ${DESK_SHOT:+"$DESK_SHOT"} || return
    brj "'Goal (Ty)' in d['text'] and 'Hypothesis hy2 (agent-written, not adopted)' in d['text'] and 'Hypothesis hy3 (Ty-written, adopted)' in d['text']" "the card in the browser"
    brj "d['k3']=='unresolved'" "the unresolved badge"
    brj "d['adopt'].get('dialog') and 'your adoption of hypothesis hy2' in d['adopt'].get('rec','')" "the review dialog of Adopt"
    brj "d['judge'].get('dialog') and 'member 12' in d['judge'].get('rec','')" "the review dialog of the case"
    has_goal "$kb" "attest(_, adoption, hy2, adopted, human, _)" "the adoption of the human, from the browser"
    has_goal "$kb" "attest(_, judgment, g1, case(_, not_wanted), human, _)" "the judgment of the human, from the browser"
}
for n in 1 2 3 4 5 6 7; do run_one DR$n; done
echo "orbit-kb=$OKB lib=$LIB pass=$pass fail=$fail skip=$skip ${failed[*]:-}"
[ "$fail" -eq 0 ]

// desk_ux.js: the browser scenarios of the Desk UX of 0.9.1 (spec KB desk-speed-orbit-door, checks k13, k14, k15).
// usage: node desk_ux.js PROFILE_DIR BASE_URL SCENARIO [OUT_DIR]
//   PROFILE_DIR: the --user-data-dir of a Chromium started with --remote-debugging-port=0.
//   SCENARIO: k13 | k14 | k15a | k15b | shots
// Each scenario prints one JSON object {checks: [[name, true|false, detail]...]} on stdout; exit 0.
// Unlike desk_browser.js it drives several page loads in one run (a reload keeps its storage).
// Needs Node 22 or later (the global WebSocket).
'use strict';
const fs = require('fs');
const path = require('path');
const [profile, base, scenario, outDir] = process.argv.slice(2);
function die(m) { process.stderr.write('desk_ux: ' + m + '\n'); process.exit(2); }
if (!profile || !base || !scenario) die('usage: node desk_ux.js PROFILE_DIR BASE_URL SCENARIO [OUT_DIR]');
if (typeof WebSocket !== 'function') die('this Node has no global WebSocket (Node 22 or later)');
const sleep = ms => new Promise(r => setTimeout(r, ms));
const checks = [];
const check = (name, ok, detail) => checks.push([name, !!ok, detail === undefined ? '' : String(detail)]);

async function port() {
  const f = path.join(profile, 'DevToolsActivePort');
  for (let i = 0; i < 200; i++) {
    try { const p = fs.readFileSync(f, 'utf8').split('\n')[0].trim(); if (p) return p; } catch (e) { /* not yet */ }
    await sleep(50);
  }
  die('Chromium wrote no DevToolsActivePort in ' + profile);
}

async function open(width, height, opts) {
  const p = await port();
  const t = await (await fetch('http://127.0.0.1:' + p + '/json/new?about:blank', {method: 'PUT'})).json();
  const ws = new WebSocket(t.webSocketDebuggerUrl);
  await new Promise((ok, bad) => { ws.onopen = ok; ws.onerror = () => bad(new Error('websocket')); });
  let id = 0; const wait = new Map(); let loads = 0;
  ws.onmessage = m => {
    const d = JSON.parse(m.data);
    if (d.id && wait.has(d.id)) { wait.get(d.id)(d); wait.delete(d.id); } else if (d.method === 'Page.loadEventFired') loads++;
  };
  const send = (method, params) => new Promise(ok => { const i = ++id; wait.set(i, ok); ws.send(JSON.stringify({id: i, method, params: params || {}})); });
  await send('Page.enable');
  await send('Emulation.setDeviceMetricsOverride', {width, height, deviceScaleFactor: 1, mobile: false});
  if (opts && opts.scheme) await send('Emulation.setEmulatedMedia', {features: [{name: 'prefers-color-scheme', value: opts.scheme}]});
  const settle = async n0 => { for (let i = 0; i < 400 && loads === n0; i++) await sleep(25); if (loads === n0) die('the page did not load'); await sleep(250); };
  const page = {
    async go(url) { let m0 = loads; await send('Page.navigate', {url: 'about:blank'}); await settle(m0); const n0 = loads; await send('Page.navigate', {url}); await settle(n0); },
    async reload() { const n0 = loads; await send('Page.reload', {}); await settle(n0); },
    async ev(expr) {
      const r = await send('Runtime.evaluate', {expression: '(async () => {' + expr + '\n})()', awaitPromise: true, returnByValue: true});
      if (r.result.exceptionDetails) die('the script threw: ' + JSON.stringify(r.result.exceptionDetails.exception && r.result.exceptionDetails.exception.description || r.result.exceptionDetails));
      return r.result.result.value;
    },
    async shot(file) { const s = await send('Page.captureScreenshot', {format: 'png'}); fs.writeFileSync(file, Buffer.from(s.result.data, 'base64')); },
    async afterNav() { const n0 = loads; await settle(n0); },
    close() { ws.close(); }
  };
  return page;
}

// helpers that run in the page
const PAGE_LIB = `
  const inDlg = e => !!e.closest('dialog');
  const folds = () => [...document.querySelectorAll('details')].filter(d => !inDlg(d));
  const pairOf = d => { const s = d.querySelector(':scope > summary'); const bs = s ? [...s.querySelectorAll('button')] : [];
    return {open: bs.filter(b => /^\\s*Expand all\\s*$/.test(b.textContent)), close: bs.filter(b => /^\\s*Collapse all\\s*$/.test(b.textContent))}; };
  const nested = d => [...d.querySelectorAll('details')];
  const fid = d => d.getAttribute('data-fid') || '';
  const openIds = () => folds().filter(d => d.open).map(fid).sort();
`;

async function k13() {
  const pg = await open(1400, 900);
  await pg.go(base + '/?mh=all');
  const r = await pg.ev(PAGE_LIB + `
    const out = {};
    const holders = [...document.querySelectorAll('details.lane, details.sheet.kbsec')];
    out.n = holders.length;
    out.bad = [];
    out.withFold = 0;
    for (const d of holders) {
      const p = pairOf(d), has = nested(d).length > 0;
      if (has) out.withFold++;
      const id = d.id || d.className;
      if (has && !(p.open.length === 1 && p.close.length === 1)) out.bad.push(id + ' has ' + p.open.length + '/' + p.close.length + ' buttons, wants 1/1');
      if (!has && (p.open.length || p.close.length)) out.bad.push(id + ' holds no fold but has a pair');
    }
    // the rails get none
    out.railButtons = [...document.querySelectorAll('aside.rails button')].filter(b => /all$/.test(b.textContent.trim())).length;
    // the top band pair still sets every fold
    const top = [...document.querySelectorAll('header.top button')];
    const te = top.find(b => /^\\s*Expand all\\s*$/.test(b.textContent)), tc = top.find(b => /^\\s*Collapse all\\s*$/.test(b.textContent));
    out.topPair = !!(te && tc);
    if (te && tc) {
      te.click(); await new Promise(r => setTimeout(r, 50)); out.topOpenAll = folds().every(d => d.open);
      tc.click(); await new Promise(r => setTimeout(r, 50)); out.topCloseAll = folds().every(d => !d.open);
    }
    // a lane that holds sheets with folds
    const lanes = holders.filter(d => d.matches('details.lane') && nested(d).length >= 2 && pairOf(d).open.length === 1);
    out.lanes = lanes.map(d => d.id);
    if (lanes.length < 1) return out;
    const A = lanes[0];
    // close every fold, then open the lane A and one fold outside it
    folds().forEach(d => { d.open = false; });
    A.open = true;
    await new Promise(r => setTimeout(r, 50));
    const outside = folds().filter(d => d !== A && !A.contains(d));
    const outsideBefore = outside.map(d => d.open);
    const inside = nested(A);
    pairOf(A).open[0].click();
    await new Promise(r => setTimeout(r, 50));
    out.insideOpen = inside.filter(d => d.open).length; out.insideN = inside.length;
    out.outsideSame = outside.every((d, i) => d.open === outsideBefore[i]);
    out.laneOpenAfterExpand = A.open;
    pairOf(A).close[0].click();
    await new Promise(r => setTimeout(r, 50));
    out.insideClosedAfter = inside.filter(d => d.open).length;
    out.laneOpenAfterCollapse = A.open;
    out.outsideSame2 = outside.every((d, i) => d.open === outsideBefore[i]);
    // a sheet pair
    const S = [...document.querySelectorAll('details.sheet.kbsec')].find(d => nested(d).length > 0 && pairOf(d).open.length === 1);
    if (S) {
      A.open = true; S.open = true;
      const sin = nested(S), others = folds().filter(d => d !== S && !S.contains(d)); const ob = others.map(d => d.open);
      pairOf(S).open[0].click(); await new Promise(r => setTimeout(r, 50));
      out.sheetInside = sin.every(d => d.open); out.sheetOutsideSame = others.every((d, i) => d.open === ob[i]);
      pairOf(S).close[0].click(); await new Promise(r => setTimeout(r, 50));
      out.sheetAfterCollapse = sin.some(d => d.open); out.sheetOpenAfter = S.open;
    }
    return out;`);
  check('every lane and sheet that holds a fold has exactly one pair, and none without a fold has one', r.bad.length === 0 && r.withFold >= 2, JSON.stringify(r.bad) + ' withFold=' + r.withFold);
  check('the rails get no pair', r.railButtons === 0, r.railButtons);
  check('Expand all of a lane opens every fold inside it', r.insideN > 0 && r.insideOpen === r.insideN, r.insideOpen + ' of ' + r.insideN);
  check('a lane pair changes no fold outside its lane', r.outsideSame && r.outsideSame2, '');
  check('a lane pair does not close its own lane', r.laneOpenAfterExpand && r.laneOpenAfterCollapse, '');
  check('Collapse all of a lane closes every fold inside it', r.insideClosedAfter === 0, r.insideClosedAfter);
  check('a KB sheet pair works inside the sheet only and keeps the sheet open', r.sheetInside && r.sheetOutsideSame && r.sheetAfterCollapse === false && r.sheetOpenAfter, JSON.stringify([r.sheetInside, r.sheetOutsideSame, r.sheetAfterCollapse, r.sheetOpenAfter]));
  check('the top band pair still sets every fold', r.topPair && r.topOpenAll && r.topCloseAll, JSON.stringify([r.topPair, r.topOpenAll, r.topCloseAll]));
  pg.close();
}

async function k14() {
  const pg = await open(1400, 700);
  const A = base + '/?mh=all', B = base + '/?mh=alpha';
  await pg.go(A);
  const first = await pg.ev(PAGE_LIB + `
    try { localStorage.clear(); sessionStorage.clear(); } catch (e) {}
    const f = folds();
    const ids = f.map(fid);
    const dup = ids.filter((x, i) => ids.indexOf(x) !== i);
    return {n: f.length, empty: ids.filter(x => !x).length, dup: dup.length, open0: openIds(), ids};`);
  check('each fold has an id, and no two folds share one', first.n > 5 && first.empty === 0 && first.dup === 0, 'n=' + first.n + ' empty=' + first.empty + ' dup=' + first.dup);
  // change: close one that loads open, open two that load closed (inside an open lane), scroll
  const ch = await pg.ev(PAGE_LIB + `
    const loadsOpen = folds().filter(d => d.open && d.matches('details.lane, details.sheet, details.kbsec'));
    const lane = document.querySelector('details.lane[open]') || document.querySelector('details.lane');
    lane.open = true;
    const closed = folds().filter(d => !d.open && d !== lane && lane.contains(d));
    const pickClosed = closed.slice(0, 2);
    pickClosed.forEach(d => { d.open = true; });
    // also open another lane so that the page is tall
    document.querySelectorAll('details.lane').forEach(d => { d.open = true; });
    const victim = loadsOpen.find(d => d !== lane && !d.contains(lane)) || null;
    if (victim) victim.open = false;
    await new Promise(r => setTimeout(r, 400));
    const h = document.documentElement.scrollHeight - innerHeight;
    window.scrollTo(0, Math.max(0, h - 50));
    await new Promise(r => setTimeout(r, 600));
    return {opened: pickClosed.map(fid), closedOne: victim ? fid(victim) : '', y: window.scrollY, h, open: openIds()};`);
  check('the setup is a real change (two opened, one closed, scrolled)', ch.opened.length === 2 && ch.y > 100, JSON.stringify({opened: ch.opened, closedOne: ch.closedOne, y: ch.y, h: ch.h}));
  await pg.reload();
  const after = await pg.ev(PAGE_LIB + `return {open: openIds(), y: window.scrollY, ids: folds().map(fid)};`);
  const same = JSON.stringify(after.open) === JSON.stringify(ch.open);
  check('after a reload the same folds are open', same, same ? '' : 'before ' + JSON.stringify(ch.open.filter(x => !after.open.includes(x))) + ' missing; after extra ' + JSON.stringify(after.open.filter(x => !ch.open.includes(x))));
  check('after a reload the scroll place is within 4 px', Math.abs(after.y - ch.y) <= 4, 'before ' + ch.y + ', after ' + after.y);
  check('the ids of the folds are the same after the reload', JSON.stringify(after.ids) === JSON.stringify(first.ids), '');
  // another address keeps its own state
  await pg.go(B);
  const other = await pg.ev(PAGE_LIB + `return {open: openIds(), y: window.scrollY, tab: document.body.getAttribute('data-tab')};`);
  check('another tab starts from the state of the server, not from the state of the first tab', other.y <= 4 && (ch.opened.length === 0 || !ch.opened.every(i => other.open.includes(i))), JSON.stringify({tab: other.tab, y: other.y}));
  const ch2 = await pg.ev(PAGE_LIB + `
    const c = folds().filter(d => d.open && d.matches('details.lane'));
    const d = c[0]; if (d) d.open = false;
    await new Promise(r => setTimeout(r, 400));
    return {closed: d ? fid(d) : '', open: openIds()};`);
  await pg.go(A);
  const backA = await pg.ev(PAGE_LIB + `return {open: openIds(), y: window.scrollY};`);
  check('the first tab is unchanged by what happened in the second', JSON.stringify(backA.open) === JSON.stringify(ch.open) && Math.abs(backA.y - ch.y) <= 4, 'y ' + backA.y);
  await pg.go(B);
  const backB = await pg.ev(PAGE_LIB + `return {open: openIds()};`);
  check('the second tab kept its own change', ch2.closed !== '' && JSON.stringify(backB.open) === JSON.stringify(ch2.open), '');
  // #id of a card in a closed lane opens it
  await pg.go(A);
  const tgt = await pg.ev(PAGE_LIB + `
    const lane = document.querySelector('details.lane#lane-kbs') || [...document.querySelectorAll('details.lane')].pop();
    const inner = [...lane.querySelectorAll('[id]')].filter(e => e.tagName === 'DETAILS' && e !== lane)[0];
    if (!inner) return {id: ''};
    lane.open = false; inner.open = false;
    await new Promise(r => setTimeout(r, 400));
    return {id: inner.id, lane: lane.id};`);
  check('the page has a card inside a lane to point at', tgt.id !== '', JSON.stringify(tgt));
  if (tgt.id) {
    await pg.go(A + '#' + encodeURIComponent(tgt.id));
    const hit = await pg.ev(PAGE_LIB + `const t = document.getElementById(${JSON.stringify(tgt.id)}); const r = t.getBoundingClientRect();
      return {open: t.open, laneOpen: t.closest('details.lane').open, top: Math.round(r.top), vis: r.height > 0};`);
    check('an address with #id of a card in a closed lane opens the card and its lane', hit.open && hit.laneOpen && hit.vis, JSON.stringify(hit));
  }
  // an entry for a fold that is gone is dropped
  const drop = await pg.ev(PAGE_LIB + `
    const key = Object.keys(localStorage).concat(Object.keys(sessionStorage));
    return {keys: key};`);
  check('the browser keeps one small entry per address', drop.keys.length >= 1 && drop.keys.length <= 4, JSON.stringify(drop.keys));
  await pg.go(base + '/no-such-page');
  const gone = await pg.ev(PAGE_LIB + `
    const store = localStorage.length ? localStorage : sessionStorage;
    const k = Object.keys(store).find(k => /all/.test(k) || true);
    const all = Object.keys(store).map(k => [k, store.getItem(k)]);
    let target = null;
    for (const [k, v] of all) { if (!/^desk-ui:all/.test(k) && all.some(x => /^desk-ui:all/.test(x[0]))) continue; try { const o = JSON.parse(v); if (o && o.open && typeof o.open === 'object') { target = [k, o]; break; } } catch (e) {} }
    if (!target) return {found: false};
    target[1].open['gone-fold-xyz'] = true;
    store.setItem(target[0], JSON.stringify(target[1]));
    return {found: true};`);
  if (gone.found) {
    await pg.go(A);
    const g2 = await pg.ev(PAGE_LIB + `
      const store = localStorage.length ? localStorage : sessionStorage;
      const s = Object.keys(store).map(k => store.getItem(k)).join('');
      await new Promise(r => setTimeout(r, 300));
      const s2 = Object.keys(store).map(k => store.getItem(k)).join('');
      return {still: s2.includes('gone-fold-xyz')};`);
    check('the entry of a fold that is gone is dropped', !g2.still, '');
  } else check('the entry of a fold that is gone is dropped', false, 'no stored state with an open map was found');
  pg.close();
}

// k15: the New requirement control. Part a: the page. Part b: the actions (the shell reads the ledger).
async function k15a() {
  const pg = await open(1400, 800);
  const findCtl = `[...document.querySelectorAll('header.top button, header.top a')].find(e => /New requirement/i.test(e.textContent + ' ' + (e.getAttribute('aria-label') || '')))`;
  const res = {};
  for (const tab of ['all', 'alpha']) {
    await pg.go(base + '/?mh=' + tab);
    res[tab] = await pg.ev(`
      const c = ${findCtl};
      if (!c) return {ctl: false};
      const o = {ctl: true, svg: !!c.querySelector('svg'), label: /New requirement/i.test(c.textContent)};
      c.click(); await new Promise(r => setTimeout(r, 200));
      const dlg = [...document.querySelectorAll('dialog')].find(d => d.open && d.querySelector('textarea[name=text]'));
      o.dialog = !!dlg;
      if (dlg) {
        o.textareas = dlg.querySelectorAll('textarea').length;
        const sel = dlg.querySelector('select[name=hub]');
        o.select = !!sel;
        if (sel) { o.options = [...sel.options].map(x => x.textContent.trim()); o.value = sel.value; o.selText = sel.selectedOptions[0] ? sel.selectedOptions[0].textContent.trim() : ''; }
        o.hidden = !!dlg.querySelector('input[type=hidden][name=hub]');
        o.review = dlg.querySelector('form').hasAttribute('data-review');
      }
      return o;`);
  }
  for (const tab of ['all', 'alpha']) check('tab ' + tab + ': the top band has New requirement with an icon and a short label', res[tab].ctl && res[tab].svg && res[tab].label, JSON.stringify(res[tab]));
  const a = res.all, b = res.alpha;
  check('it opens a form with one text field', a.dialog && a.textareas === 1 && b.dialog && b.textareas === 1, JSON.stringify([a.textareas, b.textareas]));
  check('with two mindholes the form offers the choice; on All the user chooses (no default), on a tab the default is the tab', a.select && a.value === '' && b.select && /alpha/.test(b.selText || ''), JSON.stringify([a.value, b.selText]));
  check('the form goes through the review step', a.review && b.review, '');
  // empty text sends nothing, and a draft is kept
  await pg.go(base + '/?mh=alpha');
  const emp = await pg.ev(`
    const c = ${findCtl}; if (!c) return {reviewOpen: false, msg: '', noControl: true}; c.click(); await new Promise(r => setTimeout(r, 200));
    const dlg = [...document.querySelectorAll('dialog')].find(d => d.open && d.querySelector('textarea[name=text]'));
    if (!dlg) return {reviewOpen: false, msg: '', noForm: true};
    const f = dlg.querySelector('form'); const ta = f.querySelector('textarea[name=text]');
    ta.value = '   ';
    const sb = f.querySelector('button[type=submit]'); sb.click();
    await new Promise(r => setTimeout(r, 700));
    const rv = document.getElementById('review');
    return {reviewOpen: !!(rv && rv.open), msg: (f.querySelector('.formmsg') || {}).textContent || ''};`);
  check('an empty text opens no review and says so', !emp.reviewOpen && emp.msg.length > 0, JSON.stringify(emp));
  const dr = await pg.ev(`
    const dlg = [...document.querySelectorAll('dialog')].find(d => d.open && d.querySelector('textarea[name=text]'));
    if (!dlg) return {state: 'no form'};
    const ta = dlg.querySelector('textarea[name=text]');
    ta.value = 'A draft idea, not sent'; ta.dispatchEvent(new Event('input', {bubbles: true}));
    await new Promise(r => setTimeout(r, 1500));
    return {state: (dlg.querySelector('.draftstate') || {}).textContent || ''};`);
  await pg.reload();
  const dr2 = await pg.ev(`
    const t = document.querySelector('dialog textarea[name=text]'); return {v: t ? t.value : null};`);
  check('the text is kept as a draft like other drafts (it is back after a reload)', dr2.v === 'A draft idea, not sent', JSON.stringify([dr, dr2]));
  pg.close();
}

async function k15b() {
  // argv: outDir is the file of the text to send, as JSON {hub, text, tab}
  const spec = JSON.parse(fs.readFileSync(outDir, 'utf8'));
  const pg = await open(1400, 800);
  await pg.go(base + '/?mh=' + (spec.tab || 'all'));
  const r = await pg.ev(`
    const c = [...document.querySelectorAll('header.top button, header.top a')].find(e => /New requirement/i.test(e.textContent + ' ' + (e.getAttribute('aria-label') || '')));
    if (!c) return {ctl: false};
    c.click(); await new Promise(r => setTimeout(r, 200));
    const dlg = [...document.querySelectorAll('dialog')].find(d => d.open && d.querySelector('textarea[name=text]'));
    if (!dlg) return {ctl: true, reviewOpen: false};
    const f = dlg.querySelector('form');
    const sel = f.querySelector('select[name=hub]'); if (sel) { const o = [...sel.options].find(x => x.textContent.trim() === ${JSON.stringify(spec.hub)}); if (o) sel.value = o.value; }
    f.querySelector('textarea[name=text]').value = ${JSON.stringify(spec.text)};
    f.querySelector('button[type=submit]').click();
    for (let i = 0; i < 60; i++) { await new Promise(r => setTimeout(r, 100)); const rv = document.getElementById('review'); if (rv && rv.open && rv.querySelector('form')) break; }
    const rv = document.getElementById('review');
    const o = {ctl: true, reviewOpen: !!(rv && rv.open)};
    if (o.reviewOpen) { o.reviewText = rv.innerText; o.letters = [...rv.querySelectorAll('textarea[name^=letter_]')].map(t => t.value); o.send = !!rv.querySelector('button.go'); }
    return o;`);
  if (spec.send) {
    await pg.ev(`const b = document.querySelector('#review button.go'); if (b) b.click(); return !!b;`);
    await sleep(2500);
  }
  process.stdout.write(JSON.stringify({checks: [], review: r}) + '\n');
  pg.close();
  process.exit(0);
}


// shots: screenshots for the evidence. SHOT_LABEL names the files; OUT_DIR is the directory.
async function shots() {
  const label = process.env.SHOT_LABEL || 'shot';
  fs.mkdirSync(outDir, {recursive: true});
  for (const [w, h] of [[1600, 1000], [400, 900]]) {
    for (const scheme of ['light', 'dark']) {
      const pg = await open(w, h, {scheme});
      await pg.go(base + '/?mh=all');
      await pg.ev(`try { localStorage.clear(); } catch (e) {} return 1;`);
      await pg.go(base + '/?mh=all');
      await sleep(300);
      await pg.shot(path.join(outDir, label + '-' + w + '-' + scheme + '.png'));
      if (label === 'after' && w === 1600 && scheme === 'dark') {
        // a lane after its own Collapse all
        await pg.ev(`
          const lane = document.querySelector('details.lane#lane-kbs') || document.querySelector('details.lane');
          document.querySelectorAll('details.lane').forEach(d => { d.open = false; });
          lane.open = true;
          const b = [...lane.querySelectorAll(':scope > summary button')].find(x => /^Expand all$/.test(x.textContent)); if (b) b.click();
          await new Promise(r => setTimeout(r, 200));
          [...lane.querySelectorAll(':scope > summary button')].find(x => /^Collapse all$/.test(x.textContent)).click();
          await new Promise(r => setTimeout(r, 200));
          lane.scrollIntoView({block: 'start'}); window.scrollBy(0, -90);
          return 1;`);
        await sleep(300);
        await pg.shot(path.join(outDir, 'after-lane-collapsed-1600-dark.png'));
        await pg.go(base + '/?mh=all');
        await pg.ev(`document.querySelector('[data-newreq]').click(); const t = document.querySelector('#newreq textarea'); t.value = 'An idea for the resume site: show the last three posts on the front page.'; return 1;`);
        await sleep(400);
        await pg.shot(path.join(outDir, 'after-new-requirement-form-1600-dark.png'));
      }
      pg.close();
    }
  }
}

(async () => {
  if (scenario === 'shots') await shots();
  else if (scenario === 'k13') await k13();
  else if (scenario === 'k14') await k14();
  else if (scenario === 'k15a') await k15a();
  else if (scenario === 'k15b') await k15b();
  else die('no scenario ' + scenario);
  process.stdout.write(JSON.stringify({checks}) + '\n');
  process.exit(0);
})().catch(e => die(String(e && e.stack || e)));

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
    async key(k) { const code = k === 'Enter' ? 13 : 0; for (const type of ['keyDown', 'keyUp']) await send('Input.dispatchKeyEvent', {type, key: k, code: k, windowsVirtualKeyCode: code, nativeVirtualKeyCode: code, text: type === 'keyDown' && k === 'Enter' ? '\r' : undefined}); },
    async focusEmu() { await send('Emulation.setFocusEmulationEnabled', {enabled: true}); },   // a headless page has no window focus
    close() { ws.close(); }
  };
  return page;
}

// helpers that run in the page
const PAGE_LIB = `
  const inDlg = e => !!e.closest('dialog');
  const folds = () => [...document.querySelectorAll('details')].filter(d => !inDlg(d));
  const pairOf = d => { const s = d.querySelector(':scope > summary'); const bs = s ? [...s.querySelectorAll('button')] : [];
    const lab = b => (b.getAttribute('aria-label') || b.textContent || '').trim();
    return {open: bs.filter(b => /^Expand all\\b/.test(lab(b))), close: bs.filter(b => /^Collapse all\\b/.test(lab(b)))}; };
  const HOLD = 'details.lane, details.store, details.group, details.sheet.kbsec, details.layer';
  const nested = d => [...d.querySelectorAll('details')];
  const fid = d => d.getAttribute('data-fid') || '';
  const openIds = () => folds().filter(d => d.open).map(fid).sort();
`;

const SPEC = (() => { try { return outDir && fs.existsSync(outDir) && /\.json$/.test(outDir) ? JSON.parse(fs.readFileSync(outDir, 'utf8')) : null; } catch (e) { return null; } })();
async function k13() {
  const pg = await open(1400, 900);
  await pg.go(base + (SPEC ? '/?mh=' + SPEC.tab + '&view=everything' : '/?mh=all'));
  const r = await pg.ev(PAGE_LIB + `
    const out = {};
    const holders = [...document.querySelectorAll(HOLD)];
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
    const lanes = holders.filter(d => d.matches('details.lane, details.store') && nested(d).length >= 2 && pairOf(d).open.length === 1);
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
  if (SPEC) await k13depth(pg);
  pg.close();
}

// k13 at each depth (c3 note of r8): a store, a group, a KB sheet and a layer each have their own pair; the
// store and the group the full pair, the sheet and the layer a compact pair (two icon buttons with the same
// aria-labels). At 400 px no pair covers or cuts the name beside it.
async function k13depth(pg) {
  const r = await pg.ev(PAGE_LIB + `
    const out = {};
    const depths = {store: 'details.store', group: 'details.group', sheet: 'details.sheet.kbsec', layer: 'details.layer'};
    for (const [k, sel] of Object.entries(depths)) {
      const hs = [...document.querySelectorAll(sel)].filter(d => nested(d).length > 0);
      const o = out[k] = {n: hs.length, paired: hs.filter(d => pairOf(d).open.length === 1 && pairOf(d).close.length === 1).length};
      const lab = b => (b.textContent || '').trim();
      o.full = hs.filter(d => pairOf(d).open.length === 1 && lab(pairOf(d).open[0]) === 'Expand all' && lab(pairOf(d).close[0]) === 'Collapse all').length;
      o.compact = hs.filter(d => pairOf(d).open.length === 1 && lab(pairOf(d).open[0]) === '' && pairOf(d).open[0].querySelector('svg') && pairOf(d).close[0].querySelector('svg')).length;
      const H = hs[0];
      if (!H) continue;
      folds().forEach(d => { d.open = false; });
      for (let e = H; e; e = e.parentElement) if (e.tagName === 'DETAILS') e.open = true;
      await new Promise(r => setTimeout(r, 30));
      const inside = nested(H), outside = folds().filter(d => d !== H && !H.contains(d)), ob = outside.map(d => d.open);
      pairOf(H).open[0].click(); await new Promise(r => setTimeout(r, 30));
      o.expand = inside.every(d => d.open) && outside.every((d, i) => d.open === ob[i]) && H.open;
      pairOf(H).close[0].click(); await new Promise(r => setTimeout(r, 30));
      o.collapse = inside.every(d => !d.open) && outside.every((d, i) => d.open === ob[i]) && H.open;
    }
    return out;`);
  for (const k of ['store', 'group', 'sheet', 'layer']) {
    const o = r[k] || {};
    check('depth ' + k + ': each that holds a fold has one pair (' + (o.paired || 0) + ' of ' + (o.n || 0) + ')', o.n > 0 && o.paired === o.n, JSON.stringify(o));
    const want = (k === 'store' || k === 'group') ? 'full' : 'compact';
    check('depth ' + k + ': the pair is ' + (want === 'full' ? 'the full pair (Expand all, Collapse all)' : 'compact (two icon buttons with the aria-labels)'), o.n > 0 && o[want] === o.n, JSON.stringify(o));
    check('depth ' + k + ': its pair opens and closes only the folds inside it, and leaves it open', !!(o.expand && o.collapse), JSON.stringify([o.expand, o.collapse]));
  }
  // 400 px: nothing crowds the names
  const nar = await open(400, 900);
  await nar.go(base + '/?mh=' + SPEC.tab + '&view=everything');
  const c = await nar.ev(PAGE_LIB + `
    document.querySelectorAll('details').forEach(d => { if (!inDlg(d)) d.open = true; });
    await new Promise(r => setTimeout(r, 200));
    const bad = [];
    let n = 0;
    for (const d of document.querySelectorAll(HOLD)) {
      const p = pairOf(d); if (!p.open.length) continue;
      const s = d.querySelector(':scope > summary');
      const nm = s.querySelector('h2, h3, .sname, .gname, .lname, .title');
      if (!nm) continue;
      n++;
      const a = nm.getBoundingClientRect();
      for (const b of [p.open[0], p.close[0]]) {
        const q = b.getBoundingClientRect();
        const over = !(q.right <= a.left || q.left >= a.right || q.bottom <= a.top || q.top >= a.bottom);
        if (over) bad.push((d.id || d.className) + ': a button covers the name');
      }
      if (nm.scrollWidth > nm.clientWidth + 1 && getComputedStyle(nm).overflow !== 'visible') bad.push((d.id || d.className) + ': the name is cut');
      const ws = nm.style.whiteSpace; nm.style.whiteSpace = 'nowrap'; const nat = nm.scrollWidth; nm.style.whiteSpace = ws;
      if (a.width < Math.min(nat, 120) - 1) bad.push((d.id || d.className) + ': the name has ' + Math.round(a.width) + ' of ' + nat + ' px');
    }
    return {n, bad, sw: document.documentElement.scrollWidth};`);
  check('at 400 px no pair covers or squeezes a name (' + c.n + ' holders), and the page does not scroll sideways', c.n > 0 && c.bad.length === 0 && c.sw <= 402, JSON.stringify(c.bad.slice(0, 6)) + ' scrollWidth=' + c.sw);
  nar.close();
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
    const loadsOpen = folds().filter(d => d.open && d.matches('details.lane, details.store, details.group, details.sheet, details.kbsec'));
    const lane = document.querySelector('details.lane[open], details.store[open]') || document.querySelector('details.lane, details.store');
    lane.open = true;
    const closed = folds().filter(d => !d.open && d !== lane && lane.contains(d));
    const pickClosed = closed.slice(0, 2);
    pickClosed.forEach(d => { d.open = true; });
    // also open another lane so that the page is tall
    document.querySelectorAll('details.lane, details.store').forEach(d => { d.open = true; });
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
    const c = folds().filter(d => d.open && d.matches('details.lane, details.store'));
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
    const lane = document.querySelector('details.lane#lane-kbs, details.store#store-spec') || [...document.querySelectorAll('details.lane, details.store')].pop();
    const inner = [...lane.querySelectorAll('[id]')].filter(e => e.tagName === 'DETAILS' && e !== lane)[0];
    if (!inner) return {id: ''};
    lane.open = false; inner.open = false;
    await new Promise(r => setTimeout(r, 400));
    return {id: inner.id, lane: lane.id};`);
  check('the page has a card inside a lane to point at', tgt.id !== '', JSON.stringify(tgt));
  if (tgt.id) {
    await pg.go(A + '#' + encodeURIComponent(tgt.id));
    const hit = await pg.ev(PAGE_LIB + `const t = document.getElementById(${JSON.stringify(tgt.id)}); const r = t.getBoundingClientRect();
      return {open: t.open, laneOpen: t.closest('details.lane, details.store').open, top: Math.round(r.top), vis: r.height > 0};`);
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

// ---- the Desk by store (r8, r9): k14 at each depth, k16, k20, shots2. SPEC: {tab, kbask, kbthr, closed, kb}
const VIEW_NAMES = ['Waits on you', 'Questions', 'Answered', 'Everything'];
const dups = xs => [...new Set(xs.filter((x, i) => xs.indexOf(x) !== i))];
const STORE_LIB = PAGE_LIB + `
  const itemOf = f => { const i = f.querySelector('input[name=item]'); return i ? i.value : ''; };
  // a form is its item (and its kind of judgment: a KB has two judgment forms on one item)
  const mainForms = () => [...document.querySelectorAll('main form')].map(f => itemOf(f) + (f.getAttribute('data-judge') ? '|' + f.getAttribute('data-judge') : '')).filter(f => f && f[0] !== '|');
  const STRUCT = /^(lane|store|grp|layer|view|more)-/;
  const mainIds = () => [...document.querySelectorAll('main [id]')].map(e => e.id).filter(i => !STRUCT.test(i));
  const answeredRefs = () => [...document.querySelectorAll('main ul.answered li .ref')].map(e => e.textContent.trim());
  const secName = d => { const s = d.querySelector(':scope > summary'); const h = s && s.querySelector('h2, .sname'); return (h || s || d).textContent.replace(/\\s+/g, ' ').trim(); };
  const sections = () => [...document.querySelectorAll('main > details, main > section')].filter(d => !d.matches('.foottext'));
  const views = () => [...document.querySelectorAll('nav.views a')].map(a => ({name: (a.querySelector('.vname') || a).textContent.replace(/\\d+/g, '').replace(/\\s+/g, ' ').trim(), on: a.getAttribute('aria-current') === 'page', href: a.getAttribute('href')}));
  const dups = xs => [...new Set(xs.filter((x, i) => xs.indexOf(x) !== i))];
`;

async function k14depth() {
  const pg = await open(1400, 700);
  const T = SPEC.tab;
  await pg.go(base + '/?mh=' + T);
  await pg.ev(`try { localStorage.clear(); } catch (e) {} return 1;`);
  await pg.go(base + '/?mh=' + T);
  // pick the view Everything by its link
  const href = await pg.ev(STORE_LIB + `const v = views().find(x => x.name === 'Everything'); return v ? v.href : '';`);
  check('the row of views has the view Everything', !!href, href);
  if (!href) { pg.close(); return; }
  await pg.go(new URL(href, base + '/').href);
  const ch = await pg.ev(STORE_LIB + `
    const pick = sel => [...document.querySelectorAll(sel)].filter(d => !inDlg(d));
    const res = {opened: [], closed: ''};
    const open1 = sel => { const d = pick(sel).find(x => !x.open); if (!d) return; for (let e = d; e; e = e.parentElement) if (e.tagName === 'DETAILS') e.open = true; res.opened.push(fid(d)); };
    open1('details.group'); open1('details.sheet.kbsec'); open1('details.layer'); open1('details.more');
    const el = f => document.querySelector('[data-fid="' + f + '"]');
    const lo = pick('details.store, details.group, details.layer').filter(d => d.open);
    const victim = lo.find(d => !res.opened.some(f => d.contains(el(f)) || el(f).contains(d)));
    if (victim) { victim.open = false; res.closed = fid(victim); }
    await new Promise(r => setTimeout(r, 400));
    window.scrollTo(0, Math.max(0, document.documentElement.scrollHeight - innerHeight - 40));
    await new Promise(r => setTimeout(r, 600));
    res.y = window.scrollY; res.open = openIds(); res.view = (views().find(v => v.on) || {}).name;
    return res;`);
  check('the setup opens a fold at each depth (group, KB sheet, layer, and a step of more rows) and closes one that loads open', ch.opened.length === 4 && ch.closed !== '' && ch.y > 50, JSON.stringify({opened: ch.opened, closed: ch.closed, y: ch.y}));
  await pg.reload();
  const af = await pg.ev(STORE_LIB + `return {open: openIds(), y: window.scrollY, view: (views().find(v => v.on) || {}).name};`);
  const same = JSON.stringify(af.open) === JSON.stringify(ch.open);
  check('after a reload the same folds are open, at each depth, the step of more rows too', same, same ? '' : 'missing ' + JSON.stringify(ch.open.filter(x => !af.open.includes(x))) + ' extra ' + JSON.stringify(af.open.filter(x => !ch.open.includes(x))));
  check('after a reload the scroll place is within 4 px', Math.abs(af.y - ch.y) <= 4, ch.y + ' -> ' + af.y);
  check('after a reload the view is still Everything', ch.view === 'Everything' && af.view === 'Everything', JSON.stringify([ch.view, af.view]));
  // the view Waits on you keeps its own state
  await pg.go(base + '/?mh=' + T);
  const w = await pg.ev(STORE_LIB + `return {view: (views().find(v => v.on) || {}).name, y: window.scrollY};`);
  check('the address with no view opens on Waits on you, with its own state', w.view === 'Waits on you' && w.y <= 4, JSON.stringify(w));
  pg.close();
}

async function k16() {
  const pg = await open(1400, 900);
  const T = SPEC.tab;
  await pg.go(base + '/?mh=' + T);
  const r0 = await pg.ev(STORE_LIB + `
    const secs = sections().map(secName);
    const lanes = [...document.querySelectorAll('[id^="lane-"]')].map(e => e.id);
    return {secs, lanes, views: views()};`);
  check('the main sections are exactly the stores Ledger, Spec KBs, Project KB', JSON.stringify(r0.secs) === JSON.stringify(['Ledger', 'Spec KBs', 'Project KB']), JSON.stringify(r0.secs));
  const LANES = ['Your action', 'Questions', 'Running on a guess', 'Orphaned', 'Answered', 'KBs', 'Ledger asks'];
  check('no lane of 0.9.1 is a main section (and no element is a lane)', r0.lanes.length === 0 && !r0.secs.some(x => LANES.includes(x)), JSON.stringify(r0.lanes.slice(0, 8)));
  check('the row of views is Waits on you, Questions, Answered, Everything', JSON.stringify(r0.views.map(v => v.name)) === JSON.stringify(VIEW_NAMES), JSON.stringify(r0.views.map(v => v.name)));
  check('the page loads with the view Waits on you on', (r0.views.find(v => v.on) || {}).name === 'Waits on you', JSON.stringify(r0.views.filter(v => v.on)));
  const kb = SPEC.kb;
  const res = {};
  for (const v of r0.views) {
    await pg.go(new URL(v.href, base + '/').href);
    res[v.name] = await pg.ev(STORE_LIB + `return {forms: mainForms(), ids: mainIds(), ans: answeredRefs(), on: (views().find(x => x.on) || {}).name,
      orph: !!document.querySelector('main [id$="-orphans"]') };`);
  }
  const kind = f => f.replace(/:.*/, '');
  const q = (f, kbn, qid) => kind(f) === 'q' && new RegExp('/' + kbn + '#' + qid + '$').test(f);
  for (const [name, o] of Object.entries(res)) {
    const fd = dups(o.forms.filter(f => !/^(fix|rec):/.test(f))), idd = dups(o.ids);   // rec: the four forms of Change records (kb-crud c5)
    check('view ' + name + ': no item id is on the page twice', fd.length === 0 && idd.length === 0, JSON.stringify([fd, idd]));
    check('view ' + name + ': its link turns it on', o.on === name, o.on);
  }
  const W = res['Waits on you'], Q = res['Questions'], A = res['Answered'], E = res['Everything'];
  if (W) {
    const bad = W.forms.filter(f => !['ask', 'q', 'act', 'fix', 'proj'].includes(kind(f)) || (kind(f) === 'q' && !q(f, kb, 'q1')) || (kind(f) === 'proj' && !/^proj:proposed:/.test(f)));
    check('view Waits on you: the asks for Ty (the one with the KB ref too), the open question, the KB actions, the proposed fact to ratify', W.forms.includes('ask:' + SPEC.kbask) && W.forms.some(f => q(f, kb, 'q1')) && W.forms.some(f => /#vote$/.test(f)) && W.forms.some(f => /#flare:c2$/.test(f)) && W.forms.some(f => /^proj:proposed:/.test(f)), JSON.stringify(W.forms.map(kind)));
    check('view Waits on you: nothing of another kind (no thread, no question with a default, no draft or pin, no adopt or judge, no answered list, no Orphaned)', bad.length === 0 && W.ans.length === 0 && !W.orph, JSON.stringify(bad));
  }
  if (Q) {
    const qs = Q.forms.filter(f => kind(f) === 'q');
    check('view Questions: the questions of both types', q2has(qs, kb), JSON.stringify(qs.map(f => f.replace(/^.*\//, ''))));
    check('view Questions: nothing of another kind', Q.forms.every(f => kind(f) === 'q') && Q.ans.length === 0, JSON.stringify(Q.forms.filter(f => kind(f) !== 'q').map(kind)));
  }
  function q2has(qs, k) { return ['q1', 'q2'].every(x => qs.some(f => q(f, k, x))) && qs.some(f => q(f, 's-one-b', 'q1')) && qs.length === 3; }
  if (A) check('view Answered: the answered ask, and no form of another kind', A.ans.includes(SPEC.closed) && A.forms.filter(f => ['ask', 'q', 'act', 'led', 'proj', 'adopt', 'judge'].includes(kind(f))).length === 0, JSON.stringify([A.ans, A.forms.map(kind)]));
  if (E) {
    const need = ['ask:' + SPEC.kbask, 'led:' + SPEC.kbthr];
    check('view Everything: every kind (asks, the thread, questions, KB actions, adopt, judge, the project fact, answered)',
      need.every(x => E.forms.includes(x)) && ['q', 'act', 'adopt', 'judge', 'proj'].every(k => E.forms.some(f => kind(f) === k)) && E.ans.includes(SPEC.closed), JSON.stringify([...new Set(E.forms.map(kind))]));
  }
  pg.close();
}

async function k20() {
  const pg = await open(1400, 900);
  const T = SPEC.tab, kb = SPEC.kb;
  const look = async view => {
    await pg.go(base + '/?mh=' + T + '&view=' + view);
    return pg.ev(STORE_LIB + `
      const sh = [...document.querySelectorAll('details.sheet.kbsec')].find(d => { const t = d.querySelector(':scope > summary h3.title'); return t && t.textContent.trim() === ${JSON.stringify(kb)}; });
      if (!sh) return {sheet: false};
      const layers = [...sh.querySelectorAll('details.layer')].filter(l => l.parentElement.closest('details.sheet.kbsec') === sh);
      const lname = l => { const s = l.querySelector(':scope > summary'); const n = s.querySelector('.lname') || s; return n.textContent.replace(/\\d+/g, '').replace(/\\s+/g, ' ').trim(); };
      const ql = layers.filter(l => lname(l) === 'Questions');
      const o = {sheet: true, layers: layers.map(lname), nq: ql.length};
      if (ql.length === 1) {
        const gs = [...ql[0].querySelectorAll('.qgroup')];
        o.groups = gs.map(g => (g.querySelector('h4, .gname') || g).textContent.replace(/\\d+/g, '').replace(/\\s+/g, ' ').trim());
        o.forms = gs.map(g => [...g.querySelectorAll('form')].map(itemOf).map(f => f.replace(/^.*#/, '')));
      }
      const texts = [...document.querySelectorAll('summary h2, summary h3, summary .sname, summary .gname, summary .lname, .qgroup h4, nav.views a, nav.lanes a, aside.rails .name')].map(e => e.textContent.replace(/\\s+/g, ' ').trim());
      o.guessNamed = texts.filter(t => /Running on a guess|Runs on a guess/i.test(t));
      o.views = views().map(v => v.name);
      return o;`);
  };
  const e = await look('everything');
  check('the sheet of ' + kb + ' has one layer Questions', e.sheet && e.nq === 1, JSON.stringify(e.layers));
  check('the layer Questions has exactly two groups: Open questions, Has a default', JSON.stringify(e.groups) === JSON.stringify(['Open questions', 'Has a default']), JSON.stringify(e.groups));
  check('q1 (no default) is in Open questions and q2 (a default) in Has a default, each with its form', !!e.forms && JSON.stringify(e.forms) === JSON.stringify([['q1'], ['q2']]), JSON.stringify(e.forms));
  check('the row of views has Questions and no Runs on a guess', e.views.includes('Questions') && !e.views.some(v => /guess/i.test(v)), JSON.stringify(e.views));
  check('Running on a guess is the name of no section, layer, group or view', e.guessNamed.length === 0, JSON.stringify(e.guessNamed));
  const qv = await look('questions');
  check('in the view Questions the sheet shows both groups with their questions', JSON.stringify(qv.groups) === JSON.stringify(['Open questions', 'Has a default']) && JSON.stringify(qv.forms) === JSON.stringify([['q1'], ['q2']]), JSON.stringify([qv.groups, qv.forms]));
  pg.close();
}

// shots2: the images of r8 (OUT_DIR as SPEC.out): the view Waits on you, the view Everything, one open KB sheet
// with its layers, and the rail at 400 px; at 1600 and 400 px.
async function shots2(dir) {
  fs.mkdirSync(dir, {recursive: true});
  const T = process.env.SHOT_TAB || 'alpha', kb = process.env.SHOT_KB || 's-one-a';
  for (const [w, h] of [[1600, 1100], [400, 900]]) {
    const pg = await open(w, h);
    await pg.go(base + '/?mh=' + T);
    await pg.ev(`try { localStorage.clear(); } catch (e) {} return 1;`);
    await pg.go(base + '/?mh=' + T);
    await pg.shot(path.join(dir, 'waits-' + w + '.png'));
    await pg.go(base + '/?mh=' + T + '&view=everything');
    await pg.shot(path.join(dir, 'everything-' + w + '.png'));
    await pg.ev(`
      const sh = [...document.querySelectorAll('details.sheet.kbsec')].find(d => { const t = d.querySelector(':scope > summary h3.title'); return t && t.textContent.trim() === ${JSON.stringify(kb)}; });
      if (!sh) return 0;
      for (let e = sh; e; e = e.parentElement) if (e.tagName === 'DETAILS') e.open = true;
      sh.querySelectorAll('details.layer').forEach(l => { l.open = false; });
      const q = sh.querySelector('details.layer'); if (q) q.open = true;
      await new Promise(r => setTimeout(r, 200));
      sh.scrollIntoView({block: 'start'}); window.scrollBy(0, -(parseInt(getComputedStyle(document.documentElement).getPropertyValue('--band')) || 90));
      return 1;`);
    await sleep(300);
    await pg.shot(path.join(dir, 'kb-sheet-' + w + '.png'));
    if (w === 400) {
      await pg.go(base + '/?mh=' + T);
      await pg.ev(`const r = document.querySelector('aside.rails'); if (r) { r.querySelectorAll('details').forEach(d => { if (!d.closest('[aria-label=Sessions]')) d.open = true; }); r.scrollIntoView({block: 'start'}); window.scrollBy(0, -(parseInt(getComputedStyle(document.documentElement).getPropertyValue('--band')) || 90)); } return 1;`);
      await sleep(300);
      await pg.shot(path.join(dir, 'rail-400.png'));
    }
    pg.close();
  }
}

// shotclosed: one image of a tab with every fold closed: only the names of the sections and the counts
// (for a mindhole whose text is private). OUT_DIR is the file; SHOT_TAB the tab.
async function shotclosed(file) {
  const pg = await open(1600, 1000);
  const T = process.env.SHOT_TAB || '';
  await pg.go(base + '/?mh=' + encodeURIComponent(T) + '&view=everything');
  const r = await pg.ev(`
    try { localStorage.clear(); } catch (e) {}
    document.querySelectorAll('details').forEach(d => { d.open = false; });
    // only the names of the sections, the generic group names of the Ledger, and counts
    const L = document.querySelector('#store-ledger'); if (L) L.open = true;
    if (L) L.querySelectorAll(':scope > .storebody > :not(details.group)').forEach(e => { e.style.display = 'none'; });
    document.querySelectorAll('aside.rails nav[aria-label=Sessions], .banner, .foottext, .hint').forEach(e => { e.style.display = 'none'; });
    window.scrollTo(0, 0);
    await new Promise(r => setTimeout(r, 300));
    const txt = [...document.querySelectorAll('body *')].filter(e => e.checkVisibility({visibilityProperty: true, contentVisibilityAuto: true}) && e.children.length === 0 && e.getBoundingClientRect().top < innerHeight && e.getBoundingClientRect().bottom > 0).map(e => e.textContent.trim()).filter(Boolean);
    return {txt};`);
  await pg.shot(file);
  process.stdout.write(JSON.stringify({checks: [], visible: r.txt}) + '\n');
  pg.close();
}

// golink (review of 4941d88): a link row of Asks for you (a ledger ask whose card is in the sheet of its KB)
// says that it is a link: an arrow, the words Go to its card, the title in the link colour, a visible focus
// style; a click or Enter opens the sheet and the layer of the card, and the card's top is 0 to 80 px from
// the top of the viewport. At 1600 and at 400 px. OUT_DIR (optional, in SHOT_DIR): the images.
async function golink() {
  const shotDir = process.env.SHOT_DIR || '';
  for (const [w, h] of [[1600, 1000], [400, 900]]) {
    const pg = await open(w, h); await pg.focusEmu();
    const url = base + '/?mh=' + SPEC.tab + '&view=waits';
    await pg.go(url);
    await pg.ev(`try { localStorage.clear(); } catch (e) {} return 1;`);
    await pg.go(url);
    const sel = JSON.stringify('a.actlink[href$="ask-' + SPEC.kbask + '"]');
    const r = await pg.ev(`
      const a = document.querySelector(${sel});
      if (!a) return {row: false};
      const more = a.closest('details.more'); if (more) more.open = true;   // the step N more: show, as a person takes it
      const o = {row: true, text: a.textContent.replace(/\\s+/g, ' ').trim()};
      o.cue = /Go to its card/.test(o.text);
      o.arrow = !!a.querySelector('svg') || /[→➜➤]/.test(o.text);
      const t = a.querySelector('.t');
      const tmp = document.createElement('span'); tmp.style.color = getComputedStyle(document.documentElement).getPropertyValue('--link').trim() || 'rgb(0,0,1)'; document.body.appendChild(tmp);
      o.linkColor = getComputedStyle(tmp).color; tmp.remove();
      o.titleColor = t ? getComputedStyle(t).color : '';
      a.scrollIntoView({block: 'center'});
      const st = e => { const c = getComputedStyle(e); return [c.outlineStyle, c.outlineWidth, c.boxShadow, c.backgroundColor].join('|'); };
      document.activeElement && document.activeElement.blur && document.activeElement.blur();
      o.before = st(a); a.focus(); await new Promise(r => setTimeout(r, 100)); o.after = st(a);
      const c = getComputedStyle(a); o.outline = c.outlineStyle !== 'none' && parseFloat(c.outlineWidth) >= 1;
      o.focused = document.activeElement === a; o.hasFocus = document.hasFocus(); o.fv = a.matches(':focus-visible'); o.fo = a.matches(':focus');
      return o;`);
    check(w + ' px: the page has the link row of ' + SPEC.kbask, r.row, '');
    if (!r.row) { pg.close(); continue; }
    check(w + ' px: the link row says Go to its card, with an arrow', r.cue && r.arrow, r.text.slice(0, 160));
    check(w + ' px: the title of the link row is in the link colour', r.titleColor === r.linkColor, r.titleColor + ' vs ' + r.linkColor);
    check(w + ' px: the focused link row has a visible focus style', r.focused && r.outline && r.before !== r.after, JSON.stringify([r.before, r.after, r.focused, r.hasFocus, r.fv, r.fo]));
    if (shotDir) await pg.shot(path.join(shotDir, 'link-row-' + w + '.png'));
    // the jump: a click at 1600, Enter (from the keyboard) at 400
    await pg.ev(`window.scrollTo(0, 0); return 1;`);
    if (w === 1600) await pg.ev(`document.querySelector(${sel}).click(); return 1;`);
    else { await pg.ev(`document.querySelector(${sel}).focus(); return 1;`); await pg.key('Enter'); }
    await sleep(600);
    const j = await pg.ev(`
      const a = document.querySelector(${sel}); const id = decodeURIComponent(a.getAttribute('href').replace(/^.*#/, ''));
      const t = document.getElementById(id); if (!t) return {target: false, id};
      const sh = t.closest('details.sheet.kbsec'), ly = t.closest('details.layer');
      return {target: true, sheet: !!(sh && sh.open), layer: !!(ly && ly.open), top: Math.round(t.getBoundingClientRect().top), url: location.href.replace(/^[^#]*/, '')};`);
    check(w + ' px: after the ' + (w === 1600 ? 'click' : 'Enter') + ' the sheet and the layer of the card are open', j.target && j.sheet && j.layer, JSON.stringify(j));
    check(w + ' px: the card\'s top is 0 to 80 px from the top of the viewport', j.target && j.top >= 0 && j.top <= 80, JSON.stringify(j));
    if (shotDir && w === 400) await pg.shot(path.join(shotDir, 'after-jump-400.png'));
    pg.close();
  }
}

(async () => {
  if (scenario === 'shots') await shots();
  else if (scenario === 'k13') await k13();
  else if (scenario === 'k14') { if (SPEC) await k14depth(); else await k14(); }
  else if (scenario === 'k16') await k16();
  else if (scenario === 'k20') await k20();
  else if (scenario === 'golink') await golink();
  else if (scenario === 'shots2') { await shots2(outDir); process.exit(0); }
  else if (scenario === 'shotclosed') { await shotclosed(outDir); process.exit(0); }
  else if (scenario === 'k15a') await k15a();
  else if (scenario === 'k15b') await k15b();
  else die('no scenario ' + scenario);
  process.stdout.write(JSON.stringify({checks}) + '\n');
  process.exit(0);
})().catch(e => die(String(e && e.stack || e)));

// The Desk (orbit-kb serve desk). Three jobs, and nothing is sent by this script:
// 1. Drafts (q2, q9, q10): what Ty types is saved on the Desk server as he types (the Desk's own
//    store, outside every mindhole). A draft reaches no session.
// 2. The review (c20): every form that would send something opens the review first, in a dialog.
//    The review comes from the server (POST /review), so it shows each receiving session and the
//    exact text it will get. Only its Send button posts to /send. Without this script the forms
//    post to /review, which shows the same review as a page.
// 3. The page as Ty left it (c3, c4, release 0.9.1; at each depth in 0.9.2): a pair of Expand all and
//    Collapse all in each store, group, KB sheet and layer that holds folds (the sheet and the layer get
//    the compact pair: two icon buttons with the same names), and the open folds and the scroll place
//    kept in this browser for each address of the Desk (tab and view). The server keeps none of it.
// 4. New requirement (c5): the control of the top band opens a form; it goes through the review.
(function () {
  var tok = document.body.getAttribute('data-token');
  // r10 (desk-speed-orbit-door c18 to c21): the view and the place that Ty last used. The browser keeps the
  // last view of each tab, with a short hash of this server's token (a new server start is a cold load, c20).
  // A load that is not cold, at the plain address, goes to that view; an action comes back with its view in
  // the address (the review form adds it), and with the line that says what was done.
  var bootId = (function () { var h = 5381, t = tok || ''; for (var i = 0; i < t.length; i++) h = ((h * 33) ^ t.charCodeAt(i)) >>> 0; return h.toString(36); })();
  var lastKey = 'desk-last:' + (document.body.getAttribute('data-tab') || '');
  function lastRead() { try { var o = JSON.parse(localStorage.getItem(lastKey) || 'null'); return o && typeof o === 'object' ? o : null; } catch (e) { return null; } }
  var thisView = document.body.getAttribute('data-view') || '';
  var deskDone = null;
  function runDone() { var f = deskDone; deskDone = null; if (f) f(); }
  var qs = new URLSearchParams(location.search);
  if (!qs.has('view') && !location.hash && !qs.has('did')) {
    var lv = lastRead();
    if (lv && lv.boot === bootId && /^(waits|questions|answered|everything)$/.test(lv.view || '') && lv.view !== thisView) {
      qs.set('view', lv.view);
      location.replace(location.pathname + '?' + qs.toString());
      return;
    }
  }
  if (qs.has('view') && qs.get('view') !== 'waits') {   // c20: a refresh of a tab that an older server start served is a cold load
    var lv2 = lastRead(), nav0 = (performance.getEntriesByType && performance.getEntriesByType('navigation')[0]) || {};
    if (lv2 && lv2.boot !== bootId && nav0.type === 'reload') { qs.set('view', 'waits'); location.replace(location.pathname + '?' + qs.toString()); return; }
  }
  try { localStorage.setItem(lastKey, JSON.stringify({view: thisView, boot: bootId})); } catch (e) { /* no storage: nothing is kept */ }
  document.addEventListener('submit', function (e) {
    var f = e.target;
    if (!f || !f.getAttribute || !/\/(send|review)$/.test(f.getAttribute('action') || '') || f.querySelector('input[name=view]')) return;
    var i = document.createElement('input'); i.type = 'hidden'; i.name = 'view'; i.value = thisView; f.appendChild(i);
  }, true);
  // the line of what was done: where the card was. The review notes the place and the height of the card that Ty
  // answered (sessionStorage); after the page took its place again, the line stands before the first card on the
  // screen at or below that place, folds from the height of the card to one line in 330 ms (c21), and the cards below
  // move up. With no such card (the last of a fold, a narrow screen) the line is a note under the top band.
  var placeNote = null;
  try { placeNote = JSON.parse(sessionStorage.getItem('desk-done-place') || 'null'); sessionStorage.removeItem('desk-done-place'); } catch (e) { placeNote = null; }
  if (qs.has('said')) (function () {
    var said = qs.get('said'), did = qs.get('did') || '', ans = qs.get('ans') === '1';
    var lq = new URLSearchParams(location.search); lq.delete('did'); lq.delete('said'); lq.delete('ans'); lq.set('view', 'answered');
    function put() {
      var line = document.createElement('p'); line.className = 'banner donenote'; line.setAttribute('role', 'status');
      line.appendChild(document.createTextNode(said + '. '));
      if (ans && did) {
        var link = document.createElement('a'); link.href = '?' + lq.toString() + '#' + encodeURIComponent(did.replace(/^item-/, 'ans-'));   // the row of the answered ask in Answered
        link.textContent = 'See it in Answered'; line.appendChild(link);
      }
      var band = document.querySelector('header.top'), bandH = band ? Math.max(0, band.getBoundingClientRect().bottom) : 0;
      var own = placeNote && placeNote.view === thisView;
      var viewTop = own ? Math.max(bandH + 8, Math.min(placeNote.top, innerHeight - 90)) : bandH + 20;   // where the line should stand on the screen
      var docTarget = own ? (placeNote.y || 0) + placeNote.top : scrollY + viewTop;                       // where the card was in the page
      var h0 = placeNote && placeNote.h ? Math.max(40, Math.min(placeNote.h, 600)) : 140;
      function toast() {
        if (line.parentNode) line.parentNode.removeChild(line);
        line.style.height = ''; line.style.overflow = ''; line.style.transition = '';
        line.classList.add('fixed');
        line.style.cssText = 'position:fixed;left:16px;right:16px;top:' + Math.round(bandH + 8) + 'px;z-index:20;margin:0';
        document.body.appendChild(line);
        setTimeout(function () { line.style.transition = 'opacity 400ms'; line.style.opacity = '0'; setTimeout(function () { if (line.parentNode) line.parentNode.removeChild(line); }, 450); }, 9000);
      }
      var next = null, prev = null, cs = document.querySelectorAll('[id^="item-"]');
      for (var i = 0; i < cs.length; i++) {
        if (cs[i].closest('dialog') || cs[i].closest('aside')) continue;
        var cr = cs[i].getBoundingClientRect();
        if (cr.height <= 0) continue;                       // a closed fold holds no place
        var dt = cr.top + scrollY;
        if (dt >= docTarget - 8) { if (!next) next = {el: cs[i], top: dt}; }
        else prev = {el: cs[i], bottom: dt + cr.height};
      }
      var ref = null, before = true;
      if (next && next.top - docTarget <= 60) ref = next.el;                                   // the card that now stands in its place
      else if (prev && docTarget - prev.bottom <= 60) { ref = prev.el; before = false; }       // the card was the last of its list
      else if (next) ref = next.el;
      else if (prev) { ref = prev.el; before = false; }
      if (ref && ref.parentNode) {
        ref.parentNode.insertBefore(line, before ? ref : ref.nextSibling);
        var natural = line.offsetHeight;
        line.style.height = h0 + 'px'; line.style.overflow = 'hidden'; line.style.transition = 'height 330ms ease-out';
        requestAnimationFrame(function () { requestAnimationFrame(function () { line.style.height = natural + 'px'; }); });
        setTimeout(function () { line.style.height = ''; line.style.overflow = ''; line.style.transition = ''; }, 420);
        // keep the viewport anchor: the line stands where the card stood, or on the screen when the page got shorter
        var lr = line.getBoundingClientRect();
        window.scrollTo(0, Math.max(0, Math.round(scrollY + lr.top - viewTop)));
        lr = line.getBoundingClientRect();
        if (Math.abs(lr.top - viewTop) > 120) toast();   // the page got too short to hold the place: the line is a note on the screen
      } else toast();
    }
    deskDone = put;   // run when the page took its place again (below)
  })();
  if (qs.has('said')) {
    var q2 = new URLSearchParams(location.search); q2.delete('did'); q2.delete('said'); q2.delete('ans');
    try { history.replaceState(null, '', location.pathname + (q2.toString() ? '?' + q2.toString() : '')); } catch (e) { /* the address keeps did */ }
  }
  function post(url, body, extra) {
    var b = new URLSearchParams(body);
    b.set('token', tok);
    b.set('tab', document.body.getAttribute('data-tab') || '');   // c28: a send comes back to its tab
    var h = {'Content-Type': 'application/x-www-form-urlencoded'};
    if (extra) for (var k in extra) h[k] = extra[k];
    return fetch(url, {method: 'POST', headers: h, body: b.toString()});
  }
  function fields(f) {
    var b = new URLSearchParams(new FormData(f));
    b.delete('token');
    return b;
  }
  function track(f, on, text) {
    var st = f.querySelector('.draftstate');
    if (st) st.textContent = text;
    var dot = f.querySelector('.track i.draftdot');
    if (dot) dot.classList.toggle('on', on);
  }
  function save(f) {
    var key = f.getAttribute('data-draft-key');
    if (!key) return;
    var b = fields(f);
    b.set('key', key);
    post('/draft', b).then(function (r) {
      track(f, r.ok, r.ok ? 'Draft saved' : 'Draft NOT saved (HTTP ' + r.status + ')');
    }).catch(function () { track(f, false, 'Draft NOT saved: the Desk server does not answer'); });
  }
  document.querySelectorAll('form[data-draft-key]').forEach(function (f) {
    var t;
    f.addEventListener('input', function () { clearTimeout(t); t = setTimeout(function () { save(f); }, 500); });
    f.addEventListener('change', function () { clearTimeout(t); t = setTimeout(function () { save(f); }, 200); });
  });
  // 3. Navigation (c29, c30, c31): a link to an item opens every fold around it and shows it below the
  //    sticky band; so does an anchor in the address. Expand all and Collapse all set every fold.
  function setBand() {
    var h = document.querySelector('header.top');
    // a header that does not stay on screen (static at a narrow width) leaves only a small margin
    var fixed = h && /^(sticky|fixed)$/.test(getComputedStyle(h).position);
    document.documentElement.style.setProperty('--band', ((fixed ? h.getBoundingClientRect().height : 0) + 12) + 'px');
  }
  function reveal(id) {
    var t = id ? document.getElementById(id) : null;
    if (!t || t.closest('dialog')) return false;
    for (var e = t; e; e = e.parentElement) if (e.tagName === 'DETAILS') e.open = true;
    setBand();
    t.scrollIntoView({block: 'start'});
    t.classList.add('hit');
    setTimeout(function () { t.classList.remove('hit'); }, 1600);
    return true;
  }
  function hashId() { try { return decodeURIComponent(location.hash.slice(1)); } catch (e) { return ''; } }
  document.addEventListener('click', function (e) {
    var a = e.target.closest ? e.target.closest('a[href^="#"]') : null;
    if (!a || a.closest('dialog')) return;
    var id; try { id = decodeURIComponent(a.getAttribute('href').slice(1)); } catch (x) { return; }
    if (reveal(id)) { e.preventDefault(); if (location.hash !== '#' + id) history.pushState(null, '', '#' + id); }
    else if (toEverything(id)) e.preventDefault();
  });
  // c13: an item that this view does not show is in the view Everything
  function toEverything(id) {
    if (!id || document.body.getAttribute('data-view') === 'everything') return false;
    var q = new URLSearchParams(location.search); q.set('view', 'everything');
    location.assign(location.pathname + '?' + q.toString() + '#' + encodeURIComponent(id));
    return true;
  }
  window.addEventListener('hashchange', function () { reveal(hashId()); });
  window.addEventListener('resize', setBand);
  setBand();
  // c4: each fold has a stable id (the id of the element, else its place in the folds around it),
  // so a reload can put each one back. The ids are the same on each load of the same page.
  function foldSlug(t, n) { return (t || '').replace(/\d+/g, '').replace(/\s+/g, ' ').trim().toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '').slice(0, n || 40); }
  function foldList() {
    return Array.prototype.filter.call(document.querySelectorAll('details'), function (d) { return !d.closest('dialog'); });
  }
  (function () {
    var used = {};
    foldList().forEach(function (d) {
      var base;
      if (d.id) base = d.id;
      else {
        var p = d.parentElement ? d.parentElement.closest('details') : null;
        var s = d.querySelector(':scope > summary'), nm = s ? (s.querySelector('.name, h2, h3, .lbl, .pname, .t') || s) : null;
        base = (p ? p.getAttribute('data-fid') : 'top') + '/' + (foldSlug(d.className.replace(/\bopen\b/, ''), 16) || 'fold') + '-' + (foldSlug(nm ? nm.textContent : '', 30) || 'x');
      }
      var n = used[base] = (used[base] || 0) + 1;
      d.setAttribute('data-fid', n > 1 ? base + '~' + n : base);
    });
  })();
  // c3: a pair in each lane and each KB sheet that holds a fold. A pair sets only the folds inside
  // its own section, and leaves the section itself as it is. The rails get none.
  function foldsIn(sec, open) {
    sec.querySelectorAll('details').forEach(function (d) { d.open = open; });
  }
  var ICON = {open: '<svg viewBox="0 0 16 16" aria-hidden="true" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><path d="M4 6l4 4 4-4"/><path d="M4 2.5h8"/></svg>',
              close: '<svg viewBox="0 0 16 16" aria-hidden="true" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><path d="M4 10l4-4 4 4"/><path d="M4 13.5h8"/></svg>'};
  function addPair(sec, compact) {
    var sum = sec.querySelector(':scope > summary');
    if (!sum || !sec.querySelector('details')) return;
    var label = (sec.querySelector(':scope > summary h2, :scope > summary h3, :scope > summary .gname, :scope > summary .lname') || sum).textContent.replace(/\s+/g, ' ').trim().slice(0, 60);
    var wrap = document.createElement('span');
    wrap.className = compact ? 'foldpair compact' : 'foldpair';
    [['Expand all', true], ['Collapse all', false]].forEach(function (x) {
      var b = document.createElement('button');
      b.type = 'button'; b.className = compact ? 'btn small icon' : 'btn small';
      if (compact) { b.innerHTML = x[1] ? ICON.open : ICON.close; b.title = x[0]; } else b.textContent = x[0];
      b.setAttribute('aria-label', x[0] + ' folds in ' + label);
      b.addEventListener('click', function (e) { e.preventDefault(); e.stopPropagation(); foldsIn(sec, x[1]); });
      b.addEventListener('keydown', function (e) { e.stopPropagation(); });
      b.addEventListener('keyup', function (e) { e.stopPropagation(); });
      wrap.appendChild(b);
    });
    sum.appendChild(wrap);
  }
  document.querySelectorAll('details.lane, details.store, details.group').forEach(function (d) { addPair(d, false); });
  document.querySelectorAll('details.sheet.kbsec, details.layer').forEach(function (d) { addPair(d, true); });
  // c4: what Ty left, kept in this browser for this address (tab and filter): which folds are open,
  // and the scroll place. A fold that the page shows for the first time takes the state of the
  // server. An entry for a fold that is gone is dropped (the entry is made again from the page).
  var stKey = (function () {
    var q = new URLSearchParams(location.search); q.delete('mh'); q.delete('token'); q.delete('view');
    var v = document.body.getAttribute('data-view');
    return 'desk-ui:' + (document.body.getAttribute('data-tab') || '') + (v ? '|' + v : '') + '|' + q.toString();
  })();
  function stRead() { try { var o = JSON.parse(localStorage.getItem(stKey) || 'null'); return o && typeof o === 'object' ? o : null; } catch (e) { return null; } }
  function stWrite(o) { try { localStorage.setItem(stKey, JSON.stringify(o)); } catch (e) { /* no storage: nothing is kept */ } }
  var restoring = true;
  function stSave() {
    if (restoring) return;
    var o = {open: {}, y: Math.round(window.scrollY)};
    foldList().forEach(function (d) { o.open[d.getAttribute('data-fid')] = d.open ? 1 : 0; });
    stWrite(o);
  }
  var stTimer;
  function stSoon() { if (restoring) return; clearTimeout(stTimer); stTimer = setTimeout(stSave, 120); }
  var saved = stRead(), wantY = 0;
  if (saved && saved.open && typeof saved.open === 'object') {
    foldList().forEach(function (d) {
      var k = d.getAttribute('data-fid');
      if (Object.prototype.hasOwnProperty.call(saved.open, k)) d.open = !!saved.open[k];
    });
    wantY = Math.max(0, Number(saved.y) || 0);
  }
  try { history.scrollRestoration = 'manual'; } catch (e) { /* the browser keeps its own */ }
  document.addEventListener('toggle', stSoon, true);
  window.addEventListener('scroll', stSoon, {passive: true});
  window.addEventListener('pagehide', function () { clearTimeout(stTimer); stSave(); });
  document.addEventListener('visibilitychange', function () { if (document.visibilityState === 'hidden') { clearTimeout(stTimer); stSave(); } });
  function toPlace() { if (!location.hash && wantY) window.scrollTo(0, wantY); }
  toPlace();
  window.addEventListener('load', function () {
    toPlace();
    setTimeout(function () { restoring = false; if (!location.hash) { var y = Math.round(window.scrollY); if (wantY && Math.abs(y - wantY) > 4) wantY = y; } stSave(); runDone(); }, 350);
  });
  if (document.readyState === 'complete') setTimeout(function () { restoring = false; stSave(); runDone(); }, 350);
  if (location.hash) { if (!reveal(hashId())) toEverything(hashId()); else window.addEventListener('load', function () { reveal(hashId()); }); }
  document.querySelectorAll('[data-folds]').forEach(function (b) {
    b.addEventListener('click', function () {
      var open = b.getAttribute('data-folds') === 'open';
      document.querySelectorAll('details').forEach(function (d) { if (!d.closest('dialog')) d.open = open; });
    });
  });
  var nr = document.getElementById('newreq');
  document.querySelectorAll('[data-newreq]').forEach(function (b) {
    b.addEventListener('click', function () {
      if (!nr) return;
      nr.showModal();
      var t = nr.querySelector('textarea');
      if (t) t.focus();
    });
  });
  if (nr) nr.querySelectorAll('[data-close]').forEach(function (b) { b.addEventListener('click', function (e) { e.preventDefault(); nr.close(); }); });
  var dlg = document.getElementById('review');
  var body = dlg ? dlg.querySelector('.dlgbody') : null;
  function openReview(html) {
    body.innerHTML = html;
    var c = body.querySelector('[data-cancel]');
    if (c) c.addEventListener('click', function (e) { e.preventDefault(); dlg.close(); });
    dlg.showModal();
    var ta = body.querySelector('textarea');
    if (ta) ta.focus();
  }
  // review D1: a judgment form with no choice, or a case with no text, says so beside its button and
  // sends nothing (without this script the server answers 400 with the same reason).
  function judgeMissing(f) {
    if (!f.hasAttribute('data-judge')) return '';
    if (f.getAttribute('data-judge') === 'new') {      // c5: the form of New requirement
      var hs = f.querySelector('select[name="hub"]'), tn = f.querySelector('textarea[name="text"]');
      if (hs && !hs.value) return 'Choose a mindhole first.';
      if (!tn || !tn.value.trim()) return 'Write the new requirement first.';
      return '';
    }
    if (!f.querySelector('input[name="choice"]:checked')) return 'Choose one first.';
    var ta = f.querySelector('textarea[name="text"]');
    if (f.getAttribute('data-judge') === 'case' && ta && !ta.value.trim()) return 'Write the case first.';
    return '';
  }
  document.querySelectorAll('form[data-judge]').forEach(function (f) {
    f.addEventListener('input', function () { var m = f.querySelector('.formmsg'); if (m) m.textContent = ''; });
  });
  document.querySelectorAll('form[data-review]').forEach(function (f) {
    f.addEventListener('submit', function (e) {
      var miss = judgeMissing(f), m = f.querySelector('.formmsg');
      if (m) m.textContent = miss;
      if (miss) { e.preventDefault(); return; }
      if (!dlg || !window.fetch) return;            // no dialog: the form posts to /review as a page
      e.preventDefault();
      try {
        var pc = f.closest('[id^="item-"]') || f, pr = pc.getBoundingClientRect();
        sessionStorage.setItem('desk-done-place', JSON.stringify({top: Math.round(pr.top), h: Math.round(pr.height), y: Math.round(scrollY), view: thisView}));
      } catch (e) { /* no storage: the line takes the default place */ }
      post('/review', fields(f), {'X-Desk-Fragment': '1'}).then(function (r) {
        return r.text().then(function (t) { openReview(t); });
      }).catch(function () {
        openReview('<div class="review"><div class="dh"><h2>The Desk server does not answer</h2><p>Nothing was sent. Start the Desk again, then reload the page.</p></div><div class="df"><button class="btn" data-cancel>Close</button></div></div>');
      });
    });
  });
})();

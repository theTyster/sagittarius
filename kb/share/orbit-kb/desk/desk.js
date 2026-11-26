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
    if (lv && lv.boot === bootId && /^(waits|questions|answered|everything|agents)$/.test(lv.view || '') && lv.view !== thisView) {
      qs.set('view', lv.view);
      location.replace(location.pathname + '?' + qs.toString());
      return;
    }
  }
  try { localStorage.setItem(lastKey, JSON.stringify({view: thisView, boot: bootId})); } catch (e) { /* no storage: nothing is kept */ }
  // c21, c18, c6 (H-0259): the Send of the review posts in the background (fetch, inplace=1, a send id of its
  // own review). After the server took it, the page reads the server's own render of the same address and puts its
  // body in place of the old one: the page is the page of a reload by construction (counts, cards, folds, notes).
  // No document is loaded. A card that is not in the new render folds away first (330 ms); the line of what was
  // done then stands in the flow of the page at the place of the card, and what follows it stands where the card
  // stood. The state of each Send is its own form (the card, the view, the send id): no global card.
  // A Send whose answer is lost is never posted again blind: the page reads the render again and the review says
  // what happened; a press of Send again carries the same send id, and the server writes a letter for an id once.
  function nowLine(res) {
    var line = document.createElement('p'); line.className = 'banner donenote'; line.setAttribute('role', 'status');
    line.style.margin = '0 0 8px'; line.style.padding = '6px 12px'; line.style.maxWidth = 'none';
    line.appendChild(document.createTextNode((res.said || 'Done') + '. '));
    if (res.ans && res.did) {
      var lq = new URLSearchParams(location.search); lq.delete('did'); lq.delete('said'); lq.delete('ans'); lq.set('view', 'answered');
      var a = document.createElement('a'); a.href = '?' + lq.toString() + '#' + encodeURIComponent(String(res.did).replace(/^item-/, 'ans-'));
      a.textContent = 'See it in Answered'; line.appendChild(a);
    }
    return line;
  }
  function fadeOut(line, ms) {
    var x = document.createElement('button'); x.type = 'button'; x.className = 'linkb'; x.textContent = '×'; x.setAttribute('aria-label', 'Dismiss this line'); x.style.marginLeft = '12px';
    x.addEventListener('click', function () { if (line.parentNode) line.parentNode.removeChild(line); });
    line.appendChild(x);
    setTimeout(function () { line.style.transition = 'opacity 400ms'; line.style.opacity = '0'; setTimeout(function () { if (line.parentNode) line.parentNode.removeChild(line); }, 450); }, ms);
  }
  function onPage(el) { return el && !el.closest('dialog') && !el.closest('aside'); }
  function shown(el) {   // rendered: a closed fold keeps the boxes of what it holds in Chrome, so the size alone does not say it
    if (el.checkVisibility) return el.checkVisibility();
    return el.getBoundingClientRect().height > 0;
  }
  function byId(id) {   // the element with this id in the page (not in a dialog, not in the rails); a shown one first
    if (!id) return null;
    var es = document.querySelectorAll('[id="' + (window.CSS && CSS.escape ? CSS.escape(id) : id) + '"]'), first = null;
    for (var i = 0; i < es.length; i++) if (onPage(es[i])) { if (shown(es[i])) return es[i]; if (!first) first = es[i]; }
    return first;
  }
  function inDoc(d, id) {
    var es = d.querySelectorAll('[id="' + (window.CSS && CSS.escape ? CSS.escape(id) : id) + '"]');
    for (var i = 0; i < es.length; i++) if (!es[i].closest('dialog') && !es[i].closest('aside')) return true;
    return false;
  }
  function places() { return Array.prototype.filter.call(document.querySelectorAll('main [id^="item-"], main details[id]'), function (e) { return onPage(e); }); }
  function bandBottom() { var band = document.querySelector('header.top'); return band && /^(sticky|fixed)$/.test(getComputedStyle(band).position) ? Math.max(0, band.getBoundingClientRect().bottom) : 0; }
  function freshPage() {
    return fetch(location.pathname + location.search, {credentials: 'same-origin', cache: 'no-store'}).then(function (r) {
      if (!r.ok) throw new Error('HTTP ' + r.status);
      return r.text();
    }).then(function (t) { return new DOMParser().parseFromString(t, 'text/html'); });
  }
  function typed(skip) {   // what Ty typed in the other forms and the server may not hold yet (a draft is saved 0.5 s after typing)
    var o = {};
    document.querySelectorAll('form[data-draft-key]').forEach(function (f) {
      if (!onPage(f) && !f.closest('#newreq')) return;
      if (skip && f.closest('[id="' + skip + '"]')) return;
      var v = []; f.querySelectorAll('textarea, input[type=radio], input[type=checkbox], input[type=text], input[type=date], select').forEach(function (e) { v.push(e.type === 'radio' || e.type === 'checkbox' ? e.checked : e.value); });
      o[f.getAttribute('data-draft-key')] = v;
    });
    return o;
  }
  function retype(o) {
    document.querySelectorAll('form[data-draft-key]').forEach(function (f) {
      var v = o[f.getAttribute('data-draft-key')]; if (!v) return;
      var es = f.querySelectorAll('textarea, input[type=radio], input[type=checkbox], input[type=text], input[type=date], select');
      if (es.length !== v.length) return;
      es.forEach(function (e, i) { if (e.type === 'radio' || e.type === 'checkbox') e.checked = v[i]; else e.value = v[i]; });
    });
  }
  function swapBody(d, skip) {   // the body of the server's render in place of the old one; the scripts and the review stay
    var keep = function (n) { return n.nodeType === 1 && (n.tagName === 'SCRIPT' || n.id === 'review'); };
    var was = typed(skip);
    var rv = document.getElementById('review'), oldNr = document.getElementById('newreq');
    if (oldNr && oldNr.open) oldNr.close();
    if (skip === '#newreq') delete was[oldNr ? (oldNr.querySelector('form[data-draft-key]') || {getAttribute: function () { return ''; }}).getAttribute('data-draft-key') : ''];
    clearTimeout(stTimer); if (!restoring) stSave(); restoring = true;
    Array.prototype.slice.call(document.body.childNodes).forEach(function (n) { if (!keep(n)) document.body.removeChild(n); });
    Array.prototype.slice.call(d.body.childNodes).forEach(function (n) { if (!keep(n)) document.body.insertBefore(document.adoptNode(n), rv); });
    ['data-token', 'data-tab', 'data-view'].forEach(function (k) { var v = d.body.getAttribute(k); if (v !== null) document.body.setAttribute(k, v); });
    tok = document.body.getAttribute('data-token');
    if (d.title) document.title = d.title;
    bindDom();
    retype(was);
    var st = stRead();   // the folds as Ty left them, as a reload puts them back
    if (st && st.open) foldList().forEach(function (f) { var k = f.getAttribute('data-fid'); if (Object.prototype.hasOwnProperty.call(st.open, k)) f.open = !!st.open[k]; });
    setBand();
  }
  function settle() { setTimeout(function () { restoring = false; stSave(); }, 50); }
  function holdY(y) {   // scroll to y; a page that got too short for it gets room at its end (c18: what follows stands where the card stood)
    y = Math.max(0, Math.round(y));
    for (var k = 0; k < 2; k++) {
      window.scrollTo(0, y);
      var miss = y - Math.round(scrollY);
      if (miss <= 1) return;
      var sp = document.createElement('div'); sp.className = 'deskroom'; sp.setAttribute('aria-hidden', 'true'); sp.style.height = miss + 'px';
      (document.querySelector('main') || document.body).appendChild(sp);
    }
    window.scrollTo(0, y);
  }
  function putLine(line, at) {   // the line in the flow at the place of the card; what follows it stands where the card stood
    var ref = null, i, e;
    if (at.stays && (e = byId(at.card)) && shown(e)) { e.parentNode.insertBefore(line, e); ref = e; }
    for (i = 0; !line.parentNode && i < at.after.length; i++) {   // the first place that followed the card and is on the page now,
      e = byId(at.after[i]);                                         // when it stood right below the card (else the card was the last of its list)
      if (e && shown(e)) { if (!(at.after[i] in at.gap) || at.gap[at.after[i]] <= 40) { e.parentNode.insertBefore(line, e); ref = e; } break; }
    }
    for (i = 0; !line.parentNode && i < at.before.length; i++) {   // else after the last place that stood before it
      e = byId(at.before[i]);
      if (e && shown(e)) e.parentNode.insertBefore(line, e.nextSibling);
    }
    if (line.parentNode && !shown(line)) { line.parentNode.removeChild(line); ref = null; }
    if (ref) {   // the line stands 10 px above what follows it, whatever gap the list has
      var gp = ref.getBoundingClientRect().top - line.getBoundingClientRect().bottom;
      if (gp > 10) line.style.marginBottom = Math.round(8 - (gp - 10)) + 'px';
    }
    var bandH = bandBottom();
    if (!line.parentNode) {   // nothing of the list is left on the page: a note under the band
      line.style.cssText = 'position:fixed;left:16px;right:16px;top:' + Math.round(bandH + 8) + 'px;z-index:20;margin:0';
      document.body.appendChild(line); window.scrollTo(0, at.y); return;
    }
    if (ref) holdY(scrollY + ref.getBoundingClientRect().top - at.top);
    else holdY(scrollY + line.getBoundingClientRect().bottom + 8 - at.top);
    var lr = line.getBoundingClientRect();
    if (lr.top < bandH + 4) window.scrollTo(0, Math.max(0, Math.round(scrollY + lr.top - bandH - 8)));
    else if (lr.bottom > innerHeight - 4) line.scrollIntoView({block: 'center'});
  }
  function sendPlace(sf) {   // where the card of this Send stands now, and the order of the places of the page around it
    var card = byId(sf.getAttribute('data-card')), y = Math.round(scrollY);
    if (!card || !shown(card)) return {card: '', y: y};
    var r = card.getBoundingClientRect(), before = [], after = [], seen = {}, gap = {};
    places().forEach(function (e) {
      if (e === card || card.contains(e) || e.contains(card) || seen[e.id]) return;
      seen[e.id] = 1;
      if (card.compareDocumentPosition(e) & Node.DOCUMENT_POSITION_FOLLOWING) { after.push(e.id); if (shown(e) && !(e.id in gap)) gap[e.id] = Math.round(e.getBoundingClientRect().top - r.bottom); }
      else before.push(e.id);
    });
    return {card: card.id, y: y, top: Math.round(r.top), after: after, before: before.reverse(), gap: gap};
  }
  function afterSend(sf, res) {
    var dlg2 = document.getElementById('review');
    if (dlg2 && dlg2.open && dlg2.contains(sf)) dlg2.close();   // only the review of this Send; another may be open now
    var at = sendPlace(sf), line = nowLine(res);
    freshPage().then(function (d) {
      var card = at.card ? byId(at.card) : null;
      at.stays = !!(card && inDoc(d, at.card));
      var reduce = window.matchMedia && matchMedia('(prefers-reduced-motion: reduce)').matches;
      return new Promise(function (done) {
        if (!card || at.stays || reduce) return done(d);
        var r = card.getBoundingClientRect();   // the card folds away; the cards below move up into its place
        card.style.overflow = 'hidden'; card.style.height = r.height + 'px'; card.style.boxSizing = 'border-box';
        card.style.transition = 'height 330ms ease-out, margin 330ms ease-out, padding 330ms ease-out, opacity 330ms ease-out, border-width 330ms';
        requestAnimationFrame(function () { requestAnimationFrame(function () {
          card.style.height = '0px'; card.style.marginTop = '0'; card.style.marginBottom = '0'; card.style.paddingTop = '0'; card.style.paddingBottom = '0'; card.style.opacity = '0'; card.style.borderWidth = '0';
        }); });
        setTimeout(function () { done(d); }, 360);
      });
    }).then(function (d) {
      swapBody(d, at.card || (sf.getAttribute('data-newreq') ? '#newreq' : ''));
      if (at.card) putLine(line, at);
      else { window.scrollTo(0, at.y); var bandH = bandBottom(); line.style.cssText = 'position:fixed;left:16px;right:16px;top:' + Math.round(bandH + 8) + 'px;z-index:20;margin:0'; document.body.appendChild(line); }
      fadeOut(line, 60000);
      settle();
    }).catch(function () {   // sent, but the page could not be read again: say so; a reload shows it
      var bandH = bandBottom(); line.style.cssText = 'position:fixed;left:16px;right:16px;top:' + Math.round(bandH + 8) + 'px;z-index:20;margin:0';
      line.appendChild(document.createTextNode(' The page could not be read again: reload it to see the change.'));
      document.body.appendChild(line); fadeOut(line, 60000);
    });
  }
  function sendTrouble(sf, msg) {   // nothing is posted again; the review says what happened, and Send may be pressed again (same send id)
    var b = sf.querySelector('button.go'); if (b) { b.disabled = false; b.removeAttribute('aria-busy'); }
    var m = sf.querySelector('.sendmsg');
    if (!m) { m = document.createElement('p'); m.className = 'sendmsg formmsg'; m.setAttribute('role', 'alert'); sf.appendChild(m); }
    m.textContent = msg;
  }
  document.addEventListener('submit', function (e) {
    var f = e.target;
    if (!f || !f.getAttribute || f.getAttribute('action') !== '/send' || !f.closest || !f.closest('#review') || !window.fetch || !window.FormData) return;
    e.preventDefault();
    var b = f.querySelector('button.go');
    if (f.getAttribute('data-busy') === '1') return;   // one Send at a time from one review
    f.setAttribute('data-busy', '1'); if (b) { b.disabled = true; b.setAttribute('aria-busy', 'true'); }
    var body = new URLSearchParams(new FormData(f)); body.set('inplace', '1'); body.set('view', f.getAttribute('data-view') || thisView);
    body.set('sendid', f.getAttribute('data-sendid') || '');
    fetch('/send', {method: 'POST', credentials: 'same-origin', headers: {'Content-Type': 'application/x-www-form-urlencoded'}, body: body.toString()}).then(function (r) {
      if (r.ok) return r.json().then(function (res) { afterSend(f, res); });
      return r.text().then(function (t) {   // the server answered and refused: its own words, nothing posted again
        f.removeAttribute('data-busy');
        var d = new DOMParser().parseFromString(t, 'text/html'), w = d.body ? d.body.textContent.replace(/\s+/g, ' ').trim() : '';
        sendTrouble(f, 'The Desk did not take this Send (HTTP ' + r.status + '): ' + (w || 'no reason given') + '. Nothing was sent again.');
      });
    }).catch(function () {   // no answer: the Send may or may not have reached the Desk; read the page again, post nothing
      f.removeAttribute('data-busy');
      freshPage().then(function (d) {
        var at = sendPlace(f); swapBody(d, ''); window.scrollTo(0, at.y); settle();
        sendTrouble(f, 'The answer of the Desk was lost. The page now shows what the Desk holds. If the item is still there, Send again: the Desk takes this Send once.');
      }).catch(function () {
        sendTrouble(f, 'The Desk server does not answer. This Send may not have reached it. Start the Desk again, then press Send: the Desk takes this Send once.');
      });
    });
  }, true);
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
  // one listener for the whole page (H-0259: the body of the page can be put in place again after a Send)
  ['input', 'change'].forEach(function (ev) {
    document.addEventListener(ev, function (e) {
      var f = e.target && e.target.closest ? e.target.closest('form[data-draft-key]') : null;
      if (!f) return;
      clearTimeout(f.__draftT); f.__draftT = setTimeout(function () { save(f); }, ev === 'input' ? 500 : 200);
    });
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
  function assignFids() {
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
  }
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
  // what each new body of the page needs (at the load, and after a Send put the server's render in place)
  function bindDom() {
    assignFids();
    document.querySelectorAll('details.lane, details.store, details.group').forEach(function (d) { addPair(d, false); });
    document.querySelectorAll('details.sheet.kbsec, details.layer').forEach(function (d) { addPair(d, true); });
  }
  bindDom();
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
  document.addEventListener('click', function (e) {
    var b = e.target && e.target.closest ? e.target.closest('[data-folds], [data-newreq], #newreq [data-close]') : null;
    if (!b) return;
    var nr = document.getElementById('newreq');
    if (b.hasAttribute('data-folds')) {
      var open = b.getAttribute('data-folds') === 'open';
      document.querySelectorAll('details').forEach(function (d) { if (!d.closest('dialog')) d.open = open; });
    } else if (b.hasAttribute('data-newreq')) {
      if (!nr) return;
      nr.showModal();
      var t = nr.querySelector('textarea');
      if (t) t.focus();
    } else { e.preventDefault(); if (nr) nr.close(); }
  });
  var dlg = document.getElementById('review');
  var body = dlg ? dlg.querySelector('.dlgbody') : null;
  function openReview(html, f) {
    body.innerHTML = html;
    var sf = body.querySelector('form[action="/send"]');
    if (sf) {   // H-0259: the state of this Send is its own form: the card, the view, and a send id that the server takes once
      var card = f && f.closest ? f.closest('[id^="item-"]') : null;
      var sid = ''; try { var a = new Uint8Array(12); crypto.getRandomValues(a); for (var i = 0; i < a.length; i++) sid += ('0' + a[i].toString(16)).slice(-2); } catch (x) { sid = String(Date.now()) + String(Math.random()).slice(2, 12); }
      sf.setAttribute('data-card', card && onPage(card) ? card.id : '');
      if (f && f.closest && f.closest('#newreq')) sf.setAttribute('data-newreq', '1');
      sf.setAttribute('data-view', thisView);
      sf.setAttribute('data-sendid', sid);
    }
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
  document.addEventListener('input', function (e) {
    var f = e.target && e.target.closest ? e.target.closest('form[data-judge]') : null;
    if (f) { var m = f.querySelector('.formmsg'); if (m) m.textContent = ''; }
  });
  document.addEventListener('submit', function (e) {
      var f = e.target;
      if (!f || !f.matches || !f.matches('form[data-review]')) return;
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
        return r.text().then(function (t) { openReview(t, f); });
      }).catch(function () {
        openReview('<div class="review"><div class="dh"><h2>The Desk server does not answer</h2><p>Nothing was sent. Start the Desk again, then reload the page.</p></div><div class="df"><button class="btn" data-cancel>Close</button></div></div>', f);
      });
  });
})();

// desk-agents c19: the filter of the view Agents narrows the rows as Ty types (the address ?q= does it too)
(function () {
  var f = document.querySelector('input[data-agent-filter]');
  if (!f) return;
  f.addEventListener('input', function () {
    var q = f.value.trim().toLowerCase();
    document.querySelectorAll('details.agent').forEach(function (d) {
      d.hidden = q !== '' && (d.getAttribute('data-agent') || '').toLowerCase().indexOf(q) < 0;
    });
  });
})();

// The Desk (orbit-kb serve desk). Three jobs, and nothing is sent by this script:
// 1. Drafts (q2, q9, q10): what Ty types is saved on the Desk server as he types (the Desk's own
//    store, outside every mindhole). A draft reaches no session.
// 2. The review (c20): every form that would send something opens the review first, in a dialog.
//    The review comes from the server (POST /review), so it shows each receiving session and the
//    exact text it will get. Only its Send button posts to /send. Without this script the forms
//    post to /review, which shows the same review as a page.
(function () {
  var tok = document.body.getAttribute('data-token');
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
    document.documentElement.style.setProperty('--band', ((h ? h.getBoundingClientRect().height : 0) + 12) + 'px');
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
  });
  window.addEventListener('hashchange', function () { reveal(hashId()); });
  window.addEventListener('resize', setBand);
  setBand();
  if (location.hash) { reveal(hashId()); window.addEventListener('load', function () { reveal(hashId()); }); }
  document.querySelectorAll('[data-folds]').forEach(function (b) {
    b.addEventListener('click', function () {
      var open = b.getAttribute('data-folds') === 'open';
      document.querySelectorAll('details').forEach(function (d) { if (!d.closest('dialog')) d.open = open; });
    });
  });
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
      post('/review', fields(f), {'X-Desk-Fragment': '1'}).then(function (r) {
        return r.text().then(function (t) { openReview(t); });
      }).catch(function () {
        openReview('<div class="review"><div class="dh"><h2>The Desk server does not answer</h2><p>Nothing was sent. Start the Desk again, then reload the page.</p></div><div class="df"><button class="btn" data-cancel>Close</button></div></div>');
      });
    });
  });
})();

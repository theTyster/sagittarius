// The Desk (orbit-kb serve desk). Two jobs, and nothing is sent by this script:
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
  document.querySelectorAll('form[data-review]').forEach(function (f) {
    f.addEventListener('submit', function (e) {
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

// Injected by kb/tests/test_repo_map_flow.sh (check k6) into a scratch copy of the map page, which
// headless Chromium loads with --dump-dom. It measures the rendered SVG and writes one JSON line
// into <pre id="measure">. Overlap: two boxes (or two labels) that share an area and neither holds
// the other. A label must be 11 px or more on the screen and lie inside its box.
(function () {
  function r(el) { var b = el.getBoundingClientRect(); return {x: b.left, y: b.top, w: b.width, h: b.height}; }
  function inter(a, b) { return a.x < b.x + b.w - 0.5 && b.x < a.x + a.w - 0.5 && a.y < b.y + b.h - 0.5 && b.y < a.y + a.h - 0.5; }
  function holds(a, b) { return a.x <= b.x + 0.5 && a.y <= b.y + 0.5 && a.x + a.w >= b.x + b.w - 0.5 && a.y + a.h >= b.y + b.h - 0.5; }
  var res = {innerWidth: window.innerWidth, scrollWidth: document.documentElement.scrollWidth, problems: [], boxes: 0, labels: 0, minFont: 999};
  var svgs = document.querySelectorAll('svg');
  for (var s = 0; s < svgs.length; s++) {
    var svg = svgs[s], id = svg.id || ('svg' + s);
    var bx = [], gs = svg.querySelectorAll('g[data-box]');
    for (var i = 0; i < gs.length; i++) {
      var rect = gs[i].querySelector('rect');
      if (rect) bx.push({id: gs[i].getAttribute('data-box'), r: r(rect), g: gs[i]});
    }
    res.boxes += bx.length;
    for (var i = 0; i < bx.length; i++) for (var j = i + 1; j < bx.length; j++) {
      var a = bx[i].r, b = bx[j].r;
      if (inter(a, b) && !holds(a, b) && !holds(b, a)) res.problems.push(id + ': boxes overlap: ' + bx[i].id + ' and ' + bx[j].id);
    }
    var ts = svg.querySelectorAll('text'), tl = [];
    for (var i = 0; i < ts.length; i++) {
      var t = ts[i], fs = parseFloat(getComputedStyle(t).fontSize), sc = t.getScreenCTM() ? t.getScreenCTM().a : 1;
      var eff = fs * sc; if (eff < res.minFont) res.minFont = eff;
      var tr = r(t); tl.push({t: t, r: tr});
      res.labels++;
      if (eff < 10.95) res.problems.push(id + ': label smaller than 11 px (' + eff.toFixed(1) + '): ' + t.textContent.slice(0, 40));
      var g = t.closest('g[data-box]');
      if (g) { var gr = g.querySelector('rect'); if (gr && !holds(r(gr), tr)) res.problems.push(id + ': label wider than its box: ' + t.textContent.slice(0, 40)); }
      var st = t.closest('g[data-step]');
      if (st) {
        var rr = r(st.querySelector('rect.row'));
        if (!holds(rr, tr)) res.problems.push(id + ': step label outside its row: ' + t.textContent.slice(0, 40));
        var dots = st.querySelectorAll('line.ar, path.hd, circle.dot');
        for (var k = 0; k < dots.length; k++) if (inter(r(dots[k]), tr)) res.problems.push(id + ': an arrow crosses the label: ' + t.textContent.slice(0, 40));
      }
    }
    for (var i = 0; i < tl.length; i++) for (var j = i + 1; j < tl.length; j++)
      if (inter(tl[i].r, tl[j].r)) res.problems.push(id + ': labels overlap: ' + tl[i].t.textContent.slice(0, 30) + ' / ' + tl[j].t.textContent.slice(0, 30));
  }
  if (res.scrollWidth > res.innerWidth) res.problems.push('the page is wider than the window: ' + res.scrollWidth + ' > ' + res.innerWidth);
  var pre = document.createElement('pre'); pre.id = 'measure'; pre.textContent = JSON.stringify(res);
  document.body.appendChild(pre);
})();

// orbit-kb report --html (D16). Inlined into the page.
// Review marks only. The page derives no status: orbit-kb wrote it all.
// Marks stay in this browser (web storage, keyed by the KB path and the
// report digest). The page never writes to the KB. Notes are set as text.
(function () {
  "use strict";
  var body = document.body;
  var kb = body.getAttribute("data-kb") || "";
  var digest = body.getAttribute("data-digest") || "";
  var storeKey = "orbit-kb-review|" + kb + "|" + digest;
  var marks = {};
  try { var raw = window.localStorage.getItem(storeKey); if (raw) { marks = JSON.parse(raw) || {}; } } catch (e) { marks = {}; }
  function save() {
    try { window.localStorage.setItem(storeKey, JSON.stringify(marks)); } catch (e) { /* no storage: the marks last until the page closes */ }
  }
  var boxes = Array.prototype.slice.call(document.querySelectorAll(".mark[data-key]"));
  var countEl = document.getElementById("review-count");
  var msgEl = document.getElementById("review-msg");
  var area = document.getElementById("review-text");
  var copyBtn = document.getElementById("review-copy");
  var clearBtn = document.getElementById("review-clear");

  function get(key) { return marks[key] || { mark: "", note: "" }; }
  function tidy(key) { var m = marks[key]; if (m && !m.mark && !m.note) { delete marks[key]; } }
  function say(t) { msgEl.textContent = t; }

  function paint(key) {
    var m = get(key);
    boxes.forEach(function (box) {
      if (box.getAttribute("data-key") !== key) { return; }
      box.setAttribute("data-marked", m.mark || "");
      Array.prototype.forEach.call(box.querySelectorAll("button[data-mark]"), function (b) {
        b.setAttribute("aria-pressed", b.getAttribute("data-mark") === m.mark ? "true" : "false");
      });
      var input = box.querySelector("input");
      if (input && input.value !== (m.note || "")) { input.value = m.note || ""; }
    });
    count();
  }
  function count() {
    var n = Object.keys(marks).length;
    countEl.textContent = n === 0 ? "No marks yet." : (n === 1 ? "1 item marked." : n + " items marked.");
  }

  boxes.forEach(function (box) {
    var key = box.getAttribute("data-key");
    box.addEventListener("click", function (ev) {
      var b = ev.target.closest("button[data-mark]");
      if (!b) { return; }
      var m = marks[key] || (marks[key] = { mark: "", note: "" });
      var want = b.getAttribute("data-mark");
      m.mark = m.mark === want ? "" : want;
      tidy(key); save(); paint(key);
    });
    var input = box.querySelector("input");
    if (input) {
      input.addEventListener("input", function () {
        var m = marks[key] || (marks[key] = { mark: "", note: "" });
        m.note = input.value;
        tidy(key); save(); paint(key);
      });
    }
  });
  var painted = {};
  boxes.forEach(function (box) {
    var key = box.getAttribute("data-key");
    if (!painted[key]) { painted[key] = true; paint(key); }
  });
  count();

  // The review as plain text: one line per marked item, in page order.
  function reviewText() {
    var seen = {}, lines = [];
    boxes.forEach(function (box) {
      var key = box.getAttribute("data-key");
      if (seen[key]) { return; }
      seen[key] = true;
      var m = marks[key];
      if (!m || (!m.mark && !m.note)) { return; }
      var note = String(m.note || "").replace(/\s+/g, " ").trim();
      lines.push(key + ": " + (m.mark || "note") + (note ? " - " + note : ""));
    });
    if (lines.length === 0) { return ""; }
    return ["Review of " + kb + " (report " + digest + ")"].concat(lines).join("\n");
  }
  function legacyCopy() {
    try { return document.execCommand("copy"); } catch (e) { return false; }
  }
  copyBtn.addEventListener("click", function () {
    var t = reviewText();
    if (!t) { say("Mark an item first."); return; }
    area.value = t;
    area.hidden = false;
    area.rows = Math.min(12, t.split("\n").length + 1);
    area.focus();
    area.select();
    var copied = function () { say("Copied. Paste it to the agent."); };
    var manual = function () { say("Select the text below and copy it."); };
    try {
      if (navigator.clipboard && navigator.clipboard.writeText) {
        navigator.clipboard.writeText(t).then(copied, function () { if (legacyCopy()) { copied(); } else { manual(); } });
      } else if (legacyCopy()) { copied(); } else { manual(); }
    } catch (e) { manual(); }
  });

  var armed = null;
  clearBtn.addEventListener("click", function () {
    if (Object.keys(marks).length === 0) { say("There are no marks."); return; }
    if (!armed) {
      clearBtn.textContent = "Press again to clear";
      armed = setTimeout(function () { armed = null; clearBtn.textContent = "Clear marks"; }, 4000);
      return;
    }
    clearTimeout(armed); armed = null;
    clearBtn.textContent = "Clear marks";
    var keys = Object.keys(marks);
    marks = {};
    save();
    keys.forEach(paint);
    area.hidden = true;
    say("Marks cleared.");
  });

  var expand = document.getElementById("expand-all");
  if (expand) {
    expand.addEventListener("click", function () {
      var ds = document.querySelectorAll("details.evidence");
      var open = expand.getAttribute("data-open") !== "true";
      Array.prototype.forEach.call(ds, function (d) { d.open = open; });
      expand.setAttribute("data-open", open ? "true" : "false");
      expand.textContent = open ? "Hide all evidence" : "Show all evidence";
    });
  }
}());

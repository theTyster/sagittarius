// desk_browser.js: drive a headless Chromium over the DevTools protocol, for the Desk tests (c29-c34).
// usage: node desk_browser.js PROFILE_DIR URL SCRIPT_FILE [PNG]
//   With PNG, it also saves a screenshot of the viewport after the script (for a demo).
//   PROFILE_DIR is the --user-data-dir of a Chromium started with --remote-debugging-port=0; this
//   script reads its DevToolsActivePort. It opens URL, waits for the load, then evaluates the
//   async function body in SCRIPT_FILE in the page and prints its result as JSON. Exit 2 on error.
// Needs Node 22 or later (the global WebSocket).
'use strict';
const fs = require('fs');
const path = require('path');
const [profile, url, scriptFile, png] = process.argv.slice(2);
function die(m) { process.stderr.write('desk_browser: ' + m + '\n'); process.exit(2); }
if (!profile || !url || !scriptFile) die('usage: node desk_browser.js PROFILE_DIR URL SCRIPT_FILE');
if (typeof WebSocket !== 'function') die('this Node has no global WebSocket (Node 22 or later)');
const body = fs.readFileSync(scriptFile, 'utf8');
const sleep = ms => new Promise(r => setTimeout(r, ms));

async function port() {
  const f = path.join(profile, 'DevToolsActivePort');
  for (let i = 0; i < 200; i++) {
    try { const p = fs.readFileSync(f, 'utf8').split('\n')[0].trim(); if (p) return p; } catch (e) { /* not yet */ }
    await sleep(50);
  }
  die('Chromium wrote no DevToolsActivePort in ' + profile);
}

(async () => {
  const p = await port();
  const r = await fetch('http://127.0.0.1:' + p + '/json/new?about:blank', {method: 'PUT'});
  const t = await r.json();
  const ws = new WebSocket(t.webSocketDebuggerUrl);
  await new Promise((ok, bad) => { ws.onopen = ok; ws.onerror = () => bad(new Error('websocket')); });
  let id = 0; const wait = new Map(); const evs = [];
  ws.onmessage = m => {
    const d = JSON.parse(m.data);
    if (d.id && wait.has(d.id)) { wait.get(d.id)(d); wait.delete(d.id); } else if (d.method) evs.push(d.method);
  };
  const send = (method, params) => new Promise(ok => { const i = ++id; wait.set(i, ok); ws.send(JSON.stringify({id: i, method, params: params || {}})); });
  await send('Page.enable');
  await send('Emulation.setDeviceMetricsOverride', {width: 1400, height: 900, deviceScaleFactor: 1, mobile: false});
  await send('Page.navigate', {url});
  for (let i = 0; i < 400 && !evs.includes('Page.loadEventFired'); i++) await sleep(25);
  if (!evs.includes('Page.loadEventFired')) die('the page did not load: ' + url);
  await sleep(150);
  const res = await send('Runtime.evaluate', {expression: '(async () => {' + body + '\n})()', awaitPromise: true, returnByValue: true});
  if (res.result.exceptionDetails) die('the script threw: ' + JSON.stringify(res.result.exceptionDetails.exception && res.result.exceptionDetails.exception.description));
  if (png) { await sleep(300); const shot = await send('Page.captureScreenshot', {format: 'png'}); fs.writeFileSync(png, Buffer.from(shot.result.data, 'base64')); }
  process.stdout.write(JSON.stringify(res.result.result.value) + '\n');
  ws.close();
  process.exit(0);
})().catch(e => die(String(e)));

#!/usr/bin/env python3
# HTTP helper for the Desk tests (stdlib only; run with python3 -I). From review's probes of desk-agents (H-0264).
#   token URL                         the page token
#   page URL QUERYSTRING              the page HTML
#   post URL PATH k=v ...             POST a form (no redirect follow); prints STATUS and the first 300 chars
#   review-send URL k=v ...           POST /review with the token, then POST the /send form of the review as shown
import sys, re, urllib.request, urllib.parse, urllib.error, html.parser
class NoRedir(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, *a, **k): return None
op = urllib.request.build_opener(NoRedir)
def req(url, data=None, headers=None):
    r = urllib.request.Request(url, data=data, headers=headers or {})
    try:
        x = op.open(r, timeout=60); return x.status, x.headers, x.read().decode("utf-8", "replace")
    except urllib.error.HTTPError as e:
        return e.code, e.headers, e.read().decode("utf-8", "replace")
def token(u):
    _, _, b = req(u + "/")
    m = re.search(r'name="token" value="([^"]+)"', b); return m.group(1) if m else ""
def kv(args):
    out = []
    for x in args:
        k, _, v = x.partition("="); out.append((k, v.replace("\\n", "\n")))
    return out
class Forms(html.parser.HTMLParser):
    def __init__(s): super().__init__(); s.forms = []; s.cur = None; s.ta = None
    def handle_starttag(s, t, at):
        d = dict(at)
        if t == "form": s.cur = {"action": d.get("action"), "fields": []}; s.forms.append(s.cur)
        elif s.cur is not None and t == "input" and d.get("name"):
            if d.get("type") in ("radio", "checkbox") and "checked" not in d: return
            s.cur["fields"].append((d["name"], d.get("value", "")))
        elif s.cur is not None and t == "textarea" and d.get("name"): s.ta = [d["name"], ""]
    def handle_data(s, data):
        if s.ta is not None: s.ta[1] += data
    def handle_endtag(s, t):
        if t == "textarea" and s.ta is not None: s.cur["fields"].append(tuple(s.ta)); s.ta = None
        if t == "form": s.cur = None
cmd, u = sys.argv[1], sys.argv[2].rstrip("/")
if cmd == "token": print(token(u))
elif cmd == "page": print(req(u + "/?" + sys.argv[3])[2])
elif cmd == "post":
    hdr = {}
    fields = []
    for k, v in kv(sys.argv[4:]):
        if k.startswith("H:"): hdr[k[2:]] = v
        else: fields.append((k, v))
    st, h, b = req(u + sys.argv[3], urllib.parse.urlencode(fields).encode(), hdr)
    print(st, h.get("Location") or "", re.sub(r"\s+", " ", re.sub(r"<[^>]+>", " ", b))[:300])
elif cmd == "review-send":
    tk = token(u); f = [("token", tk)] + kv(sys.argv[3:])
    st, h, b = req(u + "/review", urllib.parse.urlencode(f).encode())
    if st != 200: print("REVIEW", st, re.sub(r"<[^>]+>", " ", b)[:300]); sys.exit(1)
    p = Forms(); p.feed(b); sf = [x for x in p.forms if x["action"] == "/send"]
    if not sf: print("REVIEW no /send form:", re.sub(r"\s+", " ", re.sub(r"<[^>]+>", " ", b))[:600]); sys.exit(1)
    flds = sf[0]["fields"]
    print("REVIEW-FIELDS", [(k, v[:60]) for k, v in flds])
    st, h, b = req(u + "/send", urllib.parse.urlencode(flds).encode())
    print("SEND", st, h.get("Location") or "", re.sub(r"\s+", " ", re.sub(r"<[^>]+>", " ", b))[:300])

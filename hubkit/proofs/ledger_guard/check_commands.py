#!/usr/bin/env python3
"""Compare hubflow.py's COMMANDS table with the command lists in LedgerGuard.lean.

usage: python3 -I check_commands.py [HUBFLOW_PY]

Every key of hubflow.py's `COMMANDS = {...}` must be in exactly one of `modelledCommands` or
`excludedCommands` (with a reason) in LedgerGuard.lean, and every listed name must be a real
command. An excluded command named in REASON_CHECKS also has its reason checked against the source
of its cmd_ function (T33: spec-triage). A modelled command named in MODEL_CHECKS has the guard
that its Cmd assumes checked in hubflow.py (T40 c7: rotate lapses no escalated summary and no
summary whose kb answer is not clear, or is clear only by a live waiver (T47 c1); T40 c13, T42 c2 and c4: skip-waived parks no escalated item and
no item whose kb answer is not clear in its write, and drops none). Exit 0
when they agree, 1 when not (each difference is printed), 2 on a parse error.
Reads both files as text; runs and imports nothing.
"""
import ast
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
DEFAULT = os.path.join(HERE, "..", "..", "hub", ".claude", "scripts", "hubflow.py")
LEAN = os.path.join(HERE, "LedgerGuard.lean")


def hubflow_commands(tree, path):
    """The COMMANDS table: command name -> the name of its cmd_ function."""
    for node in ast.walk(tree):
        if isinstance(node, ast.Assign) and any(isinstance(t, ast.Name) and t.id == "COMMANDS" for t in node.targets):
            if not isinstance(node.value, ast.Dict):
                break
            return {k.value: (v.id if isinstance(v, ast.Name) else None)
                    for k, v in zip(node.value.keys, node.value.values) if isinstance(k, ast.Constant)}
    print(f"check_commands: no COMMANDS dict in {path}", file=sys.stderr)
    sys.exit(2)


# ---- excluded reasons that are checked against hubflow.py ----

WRITE_SQL = re.compile(r"\b(INSERT|UPDATE|DELETE|REPLACE|DROP|ALTER|CREATE)\b", re.I)


def call_name(call):
    f = call.func
    if isinstance(f, ast.Name):
        return f.id
    if isinstance(f, ast.Attribute) and isinstance(f.value, ast.Name):
        return f.value.id + "." + f.attr
    return None


def write_sql(fn):
    return [n.value for n in ast.walk(fn) if isinstance(n, ast.Constant) and isinstance(n.value, str)
            and WRITE_SQL.search(n.value)]


def changes_no_item(tree, fn):
    """The reason "changes no item row": the command refuses while an item of the slug is open
    (`if opened: raise`, before run_write, with `opened` the items whose status is in OPEN), its
    write function only calls w.event with the item id None, it has no write SQL and no connect_rw,
    and no module function that it calls (except run_write and connect_ro) has write SQL, connect_rw or run_write.
    Returns the problems (empty when the reason holds)."""
    out = []
    body = fn.body
    write_at = [i for i, st in enumerate(body)
                if any(isinstance(n, ast.Call) and call_name(n) == "run_write" for n in ast.walk(st))]
    if len(write_at) != 1:
        return [f"{fn.name} must call run_write once at its top level (found {len(write_at)})"]
    w_i = write_at[0]
    opened_ok = any(isinstance(st, ast.Assign) and any(isinstance(t, ast.Name) and t.id == "opened" for t in st.targets)
                    and "in OPEN" in ast.unparse(st.value) for st in body[:w_i])
    refuse_ok = any(isinstance(st, ast.If) and isinstance(st.test, ast.Name) and st.test.id == "opened"
                    and len(st.body) == 1 and isinstance(st.body[0], ast.Raise) for st in body[:w_i])
    if not (opened_ok and refuse_ok):
        out.append(f"{fn.name} does not refuse (`if opened: raise`, opened = the items in OPEN) before run_write")
    call = [n for n in ast.walk(body[w_i]) if isinstance(n, ast.Call) and call_name(n) == "run_write"][0]
    inner = {n.name: n for n in fn.body if isinstance(n, ast.FunctionDef)}
    wfn = inner.get(call.args[2].id) if len(call.args) >= 3 and isinstance(call.args[2], ast.Name) else None
    if wfn is None:
        out.append(f"{fn.name}: the write function given to run_write is not a def in {fn.name}")
    else:
        for n in ast.walk(wfn):
            if not isinstance(n, ast.Call):
                continue
            if call_name(n) != "w.event":
                out.append(f"{fn.name}: its write function calls {ast.unparse(n.func)}, not only w.event")
            elif not (n.args and isinstance(n.args[0], ast.Constant) and n.args[0].value is None):
                out.append(f"{fn.name}: w.event is given an item id ({ast.unparse(n.args[0]) if n.args else 'none'}), not None")
    for sql in write_sql(fn):
        out.append(f"{fn.name} has write SQL: {sql[:60]!r}")
    names = {n.id for n in ast.walk(fn) if isinstance(n, ast.Name)}
    if "connect_rw" in names:
        out.append(f"{fn.name} opens the db read-write (connect_rw)")
    funcs = {n.name: n for n in tree.body if isinstance(n, ast.FunctionDef)}
    # run_write is the write transaction itself (checked above through its write function);
    # connect_ro opens the db file with mode=ro, and its INSERT goes to a private in-memory copy.
    skip = {"run_write", "connect_ro", fn.name}
    for name in sorted({call_name(n) for n in ast.walk(fn) if isinstance(n, ast.Call)} & set(funcs) - skip):
        h = funcs[name]
        hn = {n.id for n in ast.walk(h) if isinstance(n, ast.Name)}
        if write_sql(h) or hn & {"connect_rw", "run_write"}:
            out.append(f"{fn.name} calls {name}, which writes")
    return out


# command -> the check of its excluded reason
REASON_CHECKS = {"spec-triage": changes_no_item}


def rotate_guard(tree, fn):
    """The modelled rotate (Cmd.rotate, T40 c7): it lapses an open summary row only when it is not
    escalated and its kb answer is clear. In hubflow.py:
    - rotate_plan: `lapse = [r[0] for r in c.execute(SQL) if not is_escalated(c, r[0])]`, where SQL
      selects open or waiting rows of kind summary;
    - kb_held_summaries: `held.add(iid)` under an `if` that tests `k['state'] != 'clear'`;
    - cmd_rotate: its write function sets `held = kb_held_summaries(...)` (inside the write, with its
      clock: T40 c11) and `lapse = [x for x in lapse if x not in held]` before the only status UPDATE,
      which is in a `for ... in lapse` loop;
    - untriaged_spec_kbs (the triage gate of a closed spec KB) counts no summary row: it calls
      `kb_slug_items(c, slug, summaries=False)`, and kb_slug_items leaves out kind summary then (T40 c10:
      a summary never blocks a rotation, so Cmd.rotate's `blocked` never comes from this item).
    Returns the problems (empty when the guard holds)."""
    out = []
    funcs = {n.name: n for n in tree.body if isinstance(n, ast.FunctionDef)}
    plan = funcs.get("rotate_plan")
    lapse = None
    if plan is not None:
        lapse = next((st.value for st in ast.walk(plan) if isinstance(st, ast.Assign)
                      and any(isinstance(t, ast.Name) and t.id == "lapse" for t in st.targets)), None)
    if not isinstance(lapse, ast.ListComp) or len(lapse.generators) != 1:
        out.append("rotate_plan has no `lapse = [... for ... in c.execute(...) if ...]`")
    else:
        g = lapse.generators[0]
        sql = " ".join(n.value for n in ast.walk(g.iter) if isinstance(n, ast.Constant) and isinstance(n.value, str))
        if "kind = 'summary'" not in sql or "status IN ('open','waiting')" not in sql:
            out.append("rotate_plan: the lapse rows are not the open or waiting rows of kind summary")
        if not any(ast.unparse(c).replace(" ", "") == "notis_escalated(c,r[0])" for c in g.ifs):
            out.append("rotate_plan: the lapse rows are not filtered by `if not is_escalated(c, r[0])`")
    held_fn = funcs.get("kb_held_summaries")
    if held_fn is None or not any(
            isinstance(n, ast.If) and "!= 'clear'" in ast.unparse(n.test)
            and any(isinstance(m, ast.Call) and call_name(m) == "held.add" for b in n.body for m in ast.walk(b))
            for n in ast.walk(held_fn)):
        out.append("kb_held_summaries does not hold a summary whose kb state is not clear (`if ... != 'clear'`: held.add)")
    # T47 c1: nor one whose spec KB is clear only by a live human waiver (Cmd.rotate: `s.kb != .waived`)
    if held_fn is None or not any(
            isinstance(n, ast.If) and any(isinstance(m, ast.Call) and call_name(m) == "live_waiver" for m in ast.walk(n.test))
            and any(isinstance(m, ast.Call) and call_name(m) == "held.add" for b in n.body for m in ast.walk(b))
            for n in ast.walk(held_fn)):
        out.append("kb_held_summaries does not hold a summary whose spec KB is clear only by a live waiver"
                   " (`if ... live_waiver(...)`: held.add; T47 c1)")
    gate = funcs.get("untriaged_spec_kbs")
    if gate is None or not any(isinstance(n, ast.Call) and call_name(n) == "kb_slug_items"
                               and any(k.arg == "summaries" and isinstance(k.value, ast.Constant) and k.value.value is False
                                       for k in n.keywords) for n in ast.walk(gate)):
        out.append("untriaged_spec_kbs does not call kb_slug_items(c, slug, summaries=False): a summary row could block a rotation")
    slug_fn = funcs.get("kb_slug_items")
    if slug_fn is None or "kind <> 'summary'" not in " ".join(
            n.value for n in ast.walk(slug_fn) if isinstance(n, ast.Constant) and isinstance(n.value, str)):
        out.append("kb_slug_items has no `kind <> 'summary'` filter for summaries=False")
    inner = {n.name: n for n in fn.body if isinstance(n, ast.FunctionDef)}
    calls = [n for n in ast.walk(fn) if isinstance(n, ast.Call) and call_name(n) == "run_write"]
    wfn = (inner.get(calls[0].args[2].id) if calls and len(calls[0].args) >= 3
           and isinstance(calls[0].args[2], ast.Name) else None)
    if wfn is None:
        return out + [f"{fn.name}: the write function given to run_write is not a def in {fn.name}"]
    body = wfn.body
    if not any(isinstance(st, ast.Assign) and any(isinstance(t, ast.Name) and t.id == "held" for t in st.targets)
               and isinstance(st.value, ast.Call) and call_name(st.value) == "kb_held_summaries" for st in body):
        out.append(f"{fn.name}: its write function does not compute `held = kb_held_summaries(...)` (inside the write)")
    drop = [i for i, st in enumerate(body) if isinstance(st, ast.Assign)
            and any(isinstance(t, ast.Name) and t.id == "lapse" for t in st.targets)
            and ast.unparse(st.value).replace(" ", "") == "[xforxinlapseifxnotinheld]"]
    loops = [i for i, st in enumerate(body) if isinstance(st, ast.For)
             and isinstance(st.iter, ast.Name) and st.iter.id == "lapse"]
    updates = [n for n in ast.walk(wfn) if isinstance(n, ast.Constant) and isinstance(n.value, str)
               and re.search(r"UPDATE\s+item\s+SET\s+status", n.value, re.I)]
    in_loop = [n for i in loops for n in ast.walk(body[i]) if isinstance(n, ast.Constant)
               and isinstance(n.value, str) and re.search(r"UPDATE\s+item\s+SET\s+status", n.value, re.I)]
    if not drop:
        out.append(f"{fn.name}: its write function does not drop the held rows (`lapse = [x for x in lapse if x not in held]`)")
    if not loops or (drop and min(loops) < drop[0]):
        out.append(f"{fn.name}: the lapse loop does not come after the held rows are dropped")
    if len(updates) != 1 or len(in_loop) != 1:
        out.append(f"{fn.name}: the status UPDATE is not one, in the `for ... in lapse` loop")
    return out


def skip_waived_guard(tree, fn):
    """The modelled skip-waived (Cmd.skipRead, then Cmd.skipWrite; T40 c13, T42 c2 and c4): its write
    parks an open item whose kb answer, read again in the write, is clear, unless the item is escalated;
    it never drops an item. In hubflow.py, cmd_skip_waived:
    - has write SQL only in its write function (the def given to run_write), and there no status UPDATE
      (`UPDATE item SET status`: T42 c4, it never drops) and exactly one `UPDATE item SET parked_until`,
      inside a `for ID in ...` loop of that function;
    - in that loop, before the statement with the park UPDATE: `if is_escalated(c, ID): ... continue`
      (T40 c13); `REFS = item_kb_refs(c, ID)` (the refs read again, in the write), `CHECKS =
      kb_checks(hub, REFS)`, and an `if` that tests `!= 'clear'` over CHECKS and ends in `continue`
      (T42 c2: an item whose kb answer is no longer clear in the write stays open, not parked).
    Returns the problems (empty when the guard holds)."""
    out = []
    inner = {n.name: n for n in fn.body if isinstance(n, ast.FunctionDef)}
    calls = [n for n in ast.walk(fn) if isinstance(n, ast.Call) and call_name(n) == "run_write"]
    wfn = (inner.get(calls[0].args[2].id) if len(calls) == 1 and len(calls[0].args) >= 3
           and isinstance(calls[0].args[2], ast.Name) else None)
    if wfn is None:
        return [f"{fn.name}: no single run_write whose write function is a def in {fn.name}"]
    status_upd = re.compile(r"UPDATE\s+item\s+SET\s+(\w+\s*=\s*[^,]*,\s*)*status\b", re.I)
    park_upd = re.compile(r"UPDATE\s+item\s+SET\s+parked_until", re.I)
    outside = [x for x in write_sql(fn) if x not in write_sql(wfn)]
    if outside:
        out.append(f"{fn.name} has write SQL outside its write function: {outside[0][:60]!r}")
    strs = [n for n in ast.walk(wfn) if isinstance(n, ast.Constant) and isinstance(n.value, str)]
    if any(status_upd.search(n.value) for n in strs):
        out.append(f"{fn.name}: its write function changes a status (T42 c4: it parks, it never drops)")
    updates = [n for n in strs if park_upd.search(n.value)]
    if len(updates) != 1:
        return out + [f"{fn.name}: its write function has {len(updates)} parked_until UPDATEs, not one"]
    loop = next((st for st in ast.walk(wfn) if isinstance(st, ast.For)
                 and any(n is updates[0] for n in ast.walk(st))), None)
    if loop is None:
        return out + [f"{fn.name}: the park UPDATE is not in a `for` loop of its write function"]
    tgt = loop.target.elts[0] if isinstance(loop.target, ast.Tuple) and loop.target.elts else loop.target
    if not isinstance(tgt, ast.Name):
        return out + [f"{fn.name}: the loop over the items has no item id name"]
    at = next(i for i, st in enumerate(loop.body) if any(n is updates[0] for n in ast.walk(st)))
    before = loop.body[:at]
    want = f"is_escalated(c,{tgt.id})"
    if not [st for st in before if isinstance(st, ast.If) and ast.unparse(st.test).replace(" ", "") == want
            and not st.orelse and isinstance(st.body[-1], ast.Continue)]:
        out.append(f"{fn.name}: its write function does not skip an escalated item "
                   f"(`if is_escalated(c, {tgt.id}): ... continue`) before the park UPDATE")

    def assigned(name_call, arg_ok):
        return next((i for i, st in enumerate(before) if isinstance(st, ast.Assign) and len(st.targets) == 1
                     and isinstance(st.targets[0], ast.Name) and isinstance(st.value, ast.Call)
                     and call_name(st.value) == name_call and arg_ok(st.value)), None)

    r_i = assigned("item_kb_refs", lambda v: [ast.unparse(x) for x in v.args] == ["c", tgt.id])
    refs = before[r_i].targets[0].id if r_i is not None else None
    k_i = assigned("kb_checks", lambda v: refs is not None and len(v.args) == 2 and ast.unparse(v.args[1]) == refs)
    checks = before[k_i].targets[0].id if k_i is not None else None
    guard = [i for i, st in enumerate(before) if isinstance(st, ast.If) and checks is not None and i > k_i
             and "!= 'clear'" in ast.unparse(st.test) and re.search(r"\bin " + checks + r"\b", ast.unparse(st.test))
             and not st.orelse and isinstance(st.body[-1], ast.Continue)]
    if r_i is None or k_i is None or not guard:
        out.append(f"{fn.name}: its write function does not check the kb refs again before the park UPDATE "
                   f"(`refs = item_kb_refs(c, {tgt.id})`, `checks = kb_checks(hub, refs)`, "
                   f"`if ... != 'clear' ... in checks: continue`; T42 c2)")
    return out


# modelled command -> the check that hubflow.py has the guard that its Cmd assumes (T40 c7, c13)
MODEL_CHECKS = {"rotate": rotate_guard, "skip-waived": skip_waived_guard}


def lean_list(text, name):
    m = re.search(r"def " + name + r" : List \(String × String\) := \[(.*?)\n\]", text, re.S)
    if not m:
        print(f"check_commands: no {name} in {LEAN}", file=sys.stderr)
        sys.exit(2)
    pairs = re.findall(r'\(\s*"([^"]+)"\s*,\s*"([^"]*)"\s*\)', m.group(1))
    return pairs


def main():
    path = sys.argv[1] if len(sys.argv) > 1 else DEFAULT
    tree = ast.parse(open(path, encoding="utf-8").read(), path)
    table = hubflow_commands(tree, path)
    real = list(table)
    text = open(LEAN, encoding="utf-8").read()
    modelled = lean_list(text, "modelledCommands")
    excluded = lean_list(text, "excludedCommands")
    problems = []
    names = [n for n, _ in modelled] + [n for n, _ in excluded]
    for n in sorted(set(names)):
        if names.count(n) > 1:
            problems.append(f"{n}: listed more than once")
    for n, why in excluded:
        if not why.strip():
            problems.append(f"{n}: excluded with no reason")
    for n in real:
        if n not in names:
            problems.append(f"{n}: a hubflow command that the model neither models nor excludes")
    for n in names:
        if n not in real:
            problems.append(f"{n}: listed in the model but not a hubflow command")
    funcs = {x.name: x for x in tree.body if isinstance(x, ast.FunctionDef)}
    for n, _ in excluded:
        if n not in REASON_CHECKS or n not in table:
            continue
        fn = funcs.get(table[n])
        bad = [f"no module function {table[n]}"] if fn is None else REASON_CHECKS[n](tree, fn)
        if bad:
            problems.append(f"{n}: the excluded reason does not hold in hubflow.py: " + "; ".join(bad))
        else:
            print(f"OK {n}: excluded reason checked ({REASON_CHECKS[n].__name__} in {table[n]})")
    for n, _ in modelled:
        if n not in MODEL_CHECKS or n not in table:
            continue
        fn = funcs.get(table[n])
        bad = [f"no module function {table[n]}"] if fn is None else MODEL_CHECKS[n](tree, fn)
        if bad:
            problems.append(f"{n}: the modelled {n} guard does not hold in hubflow.py: " + "; ".join(bad))
        else:
            print(f"OK {n}: modelled guard checked ({MODEL_CHECKS[n].__name__} in {table[n]})")
    for p in problems:
        print("FAIL " + p)
    print(f"{len(real)} hubflow commands; {len(modelled)} modelled, {len(excluded)} excluded; "
          f"{len(problems)} problem(s)")
    sys.exit(1 if problems else 0)


if __name__ == "__main__":
    main()

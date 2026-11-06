/-!
# The request guard of `orbit-kb serve questions` (ticket T19, CONTRACT D26 S5 and S6)

A model of `serve_route/5`, `serve_host_ok/2` and the token test in `kb/bin/orbit-kb`.
The model is not the code: the checks of `kb/tests/test_question_server.sh` test the code, and
QS17 runs the server against the table of `#eval table` below.

Abstractions (what the model leaves out):
* A path is `/`, `/answer`, or any other path (`Path.other`). The code compares the path atom
  with `'/'` and `'/answer'` exactly; the query string is not part of the path.
* The host is the host part of the `Host` header, without the port, or none.
* The token is the `token` field of the POST form, or none. The run token is one fixed string.
* The write itself (`serve_answer/2`: the KB is served, the question is to_ask, the lock is
  free, `orbit-kb add` accepts the term) can still refuse. The model says only which requests
  can reach it, and what it can write.
-/
namespace QuestionServer

inductive Method | get | post | put | delete | head
  deriving DecidableEq, Repr

inductive Path | root | answer | other
  deriving DecidableEq, Repr

inductive Action | page | answer | forbidden | badMethod | notFound
  deriving DecidableEq, Repr

/-- `serve_host_ok/2`: the host part of `Host` is 127.0.0.1 or localhost. -/
def hostOk : Option String → Bool
  | some "127.0.0.1" => true
  | some "localhost" => true
  | _ => false

/-- The token test: the form has a token, and it is the token of this run. -/
def tokenOk (run : String) (sent : Option String) : Bool := sent == some run

/-- `serve_route/5`. -/
def route (m : Method) (p : Path) (host tok : Bool) : Action :=
  if host = false then .forbidden
  else match m, p with
    | .get, .root => .page
    | .post, .answer => if tok then .answer else .forbidden
    | _, .root => .badMethod
    | _, .answer => .badMethod
    | _, .other => .notFound

structure Req where
  m : Method
  p : Path
  host : Option String
  token : Option String

/-- What the server does with a request, for the token `run` of this run. -/
def act (run : String) (r : Req) : Action :=
  route r.m r.p (hostOk r.host) (tokenOk run r.token)

/-- A fact that the server can ask `orbit-kb add` to write. -/
inductive Fact
  | answer (q a : String) (by_ : String)
  deriving DecidableEq, Repr

/-- `serve_act/2`: only the answer action writes, and it writes one answer fact by human. -/
def writes (act : Action) (q a : String) : List Fact :=
  match act with
  | .answer => [.answer q a "human"]
  | _ => []

/-- D26 S6 and S5: a request writes only when it is a POST of /answer, with a loopback Host and
the token of this run. -/
theorem write_needs_post_answer_host_token (run : String) (r : Req) (q a : String)
    (h : writes (act run r) q a ≠ []) :
    r.m = .post ∧ r.p = .answer ∧ hostOk r.host = true ∧ r.token = some run := by
  rcases r with ⟨m, p, host, token⟩
  simp only [act, route, writes] at h ⊢
  cases hh : hostOk host <;> simp [hh] at h ⊢
  cases m <;> cases p <;> simp at h ⊢
  cases ht : tokenOk run token <;> simp [ht] at h
  simpa [tokenOk] using ht

/-- D26 S6: whatever a request writes is an answer fact by human. -/
theorem writes_only_human_answers (run : String) (r : Req) (q a : String) :
    ∀ f ∈ writes (act run r) q a, f = .answer q a "human" := by
  intro f hf
  cases hx : act run r <;> simp [writes, hx] at hf <;> exact hf

/-- D26 S5: a Host other than 127.0.0.1 or localhost gets 403, for every method and path. -/
theorem foreign_host_forbidden (run : String) (r : Req) (h : hostOk r.host = false) :
    act run r = .forbidden := by
  simp [act, route, h]

/-- D26 S5: a POST without the token of this run never writes. -/
theorem wrong_token_no_write (run : String) (r : Req) (q a : String) (h : r.token ≠ some run) :
    writes (act run r) q a = [] := by
  cases hw : writes (act run r) q a with
  | nil => rfl
  | cons f fs =>
    exact absurd (write_needs_post_answer_host_token run r q a (by simp [hw])).2.2.2 h

/-- Claim c5 (the part that the model holds): a foreign Host is forbidden on every request, and
no request without the token of this run writes. -/
theorem c5_guard (run : String) :
    (∀ r : Req, hostOk r.host = false → act run r = .forbidden) ∧
    (∀ (r : Req) (q a : String), r.token ≠ some run → writes (act run r) q a = []) :=
  ⟨foreign_host_forbidden run, wrong_token_no_write run⟩

/-- Claim c6: a request writes only as a POST of /answer with a loopback Host and the token, and
what it writes is one answer fact by human. -/
theorem c6_guard (run : String) :
    (∀ (r : Req) (q a : String), writes (act run r) q a ≠ [] →
      r.m = .post ∧ r.p = .answer ∧ hostOk r.host = true ∧ r.token = some run) ∧
    (∀ (r : Req) (q a : String), ∀ f ∈ writes (act run r) q a, f = .answer q a "human") :=
  ⟨write_needs_post_answer_host_token run, writes_only_human_answers run⟩

/-! The table for QS17: method, path, host ok, token ok, and the action. -/
def methods : List Method := [.get, .post, .put, .delete]
def paths : List Path := [.root, .answer, .other]

def table : List (Method × Path × Bool × Bool × Action) :=
  methods.flatMap fun m => paths.flatMap fun p => [true, false].flatMap fun h =>
    [true, false].map fun t => (m, p, h, t, route m p h t)

#eval table.length
#eval table

end QuestionServer

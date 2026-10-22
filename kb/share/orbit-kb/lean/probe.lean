import Lean
open Lean Meta

/-!
orbit-kb prove runs this file with `lake env lean --run probe.lean MODULE THEOREM ROOT`
in the Lake project at ROOT, after `lake build MODULE`.

It imports the built MODULE as data and prints one fact per line. Each line starts with
"ORBIT-PROVE ". orbit-kb reads these lines and decides; this file decides nothing.

  lean V            the Lean version
  kind K            theorem, axiom, def, opaque, other, or missing
  module M          the module that declares THEOREM
  axiom A           one line per axiom that THEOREM depends on (sorryAx for sorry)
  statement S       the type of THEOREM, on one line
  uses C M          one line per constant in the statement, and its module
  file M PATH       one line per source file of the project that MODULE imports,
                    MODULE first. PATH is relative to ROOT. Files under ROOT/.lake
                    (dependencies) are left out.
-/

def out (s : String) : IO Unit := IO.println ("ORBIT-PROVE " ++ s)

def moduleOf (env : Environment) (n : Name) : String :=
  match env.getModuleIdxFor? n with
  | some i => toString env.header.moduleNames[i.toNat]!
  | none => ""

unsafe def main (args : List String) : IO UInt32 := do
  let [modS, thmS, rootS] := args
    | IO.eprintln "usage: probe MODULE THEOREM ROOT"; return 2
  initSearchPath (← findSysroot)
  enableInitializersExecution
  let mod := modS.toName
  let n := thmS.toName
  out s!"lean {Lean.versionString}"
  -- loadExts: notation and delaborators, so that the statement reads as in the source.
  let env ← importModules #[{ module := mod }] {} (trustLevel := 0) (loadExts := true)
  let ctx : Core.Context := { fileName := "<orbit-kb>", fileMap := default }
  let st : Core.State := { env }
  match env.find? n with
  | none => out "kind missing"
  | some ci =>
    let kind := match ci with
      | .thmInfo _ => "theorem"
      | .axiomInfo _ => "axiom"
      | .defnInfo _ => "def"
      | .opaqueInfo _ => "opaque"
      | _ => "other"
    out s!"kind {kind}"
    out s!"module {moduleOf env n}"
    let (axs, _) ← (collectAxioms n : CoreM (Array Name)).toIO ctx st
    for a in axs do out s!"axiom {a}"
    let txt ← try
        let (f, _, _) ← (ppExpr ci.type).toIO ctx st
        pure (toString f)
      catch _ => pure (toString ci.type)
    out s!"statement {txt.replace "\n" " "}"
    for c in ci.type.getUsedConstants do
      out s!"uses {c} {moduleOf env c}"
  let root := (← IO.FS.realPath rootS).toString ++ "/"
  let srcSp ← getSrcSearchPath
  let mut seen : NameSet := ({} : NameSet).insert mod
  let mut order : Array Name := #[mod]
  let mut i := 0
  while h : i < order.size do
    let m := order[i]
    i := i + 1
    if let some k := env.getModuleIdx? m then
      for imp in env.header.moduleData[k.toNat]!.imports do
        unless seen.contains imp.module do
          seen := seen.insert imp.module
          order := order.push imp.module
    if let some src ← srcSp.findModuleWithExt "lean" m then
      let s := (← IO.FS.realPath src).toString
      if s.startsWith root && !(s.startsWith (root ++ ".lake/")) then
        out s!"file {m} {s.drop root.length}"
  return 0

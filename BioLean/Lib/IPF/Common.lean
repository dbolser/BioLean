import BioLean
import Lean.Data.Json

/-!
# Shared by the generated IPF run modules

Each module in `BioLean/Lib/IPF/Runs/` is one hypothesis-agent run, rendered from
`data/ipf/runs/<run>/curated.json` by `scripts/ipf/render.py`. It lists its statements and the
arms the renderer composed, as rows. `BioLean/Lib/IPF/Report.lean` prints every row as one JSON
line; Lean computes the claim, sign, opinion and verdict, Python only reads them.
-/

namespace BioLean.Lib.IPF

open BioLean Lean

def ratJson (q : ℚ) : Json := Json.str s!"{q.num}/{q.den}"

def opinionJson (o : Opinion) : Json :=
  Json.mkObj [("b", ratJson o.belief), ("d", ratJson o.disbelief), ("u", ratJson o.uncertainty)]

def targetJson : Target → Json
  | .activity p _ => Json.mkObj [("kind", "activity"), ("curie", Json.str p.curie)]
  | .amount m => Json.mkObj [("kind", "amount"), ("curie", Json.str m.curie)]
  | .process p => Json.mkObj [("kind", "process"), ("curie", Json.str p.curie)]
  | .phenotype p => Json.mkObj [("kind", "phenotype"), ("curie", Json.str p.curie)]
  | .site a => Json.mkObj [("kind", "site"), ("curie", Json.str a.curie)]
  | .disease d a => Json.mkObj [("kind", "disease"), ("curie", Json.str d.curie),
      ("aspect", Json.str (match a with | .risk => "risk" | .severity => "severity" | .progression => "progression"))]

/-- The parts of a claim the report compares: subject, sign and target for an effect. -/
def claimJson (c : Claim) : Json :=
  let text := ("text", Json.str (toString c))
  match c with
  | .effect a s t => Json.mkObj [text, ("form", "effect"), ("subject", Json.str a.curie),
      ("sign", Json.str (match s with | .pos => "pos" | .neg => "neg")), ("target", targetJson t)]
  | .assoc x d t => Json.mkObj [text, ("form", "assoc"), ("subject", Json.str x.curie),
      ("sign", Json.str (match d with | some .pos => "pos" | some .neg => "neg" | none => "none")),
      ("target", targetJson t)]
  | _ => Json.mkObj [text, ("form", "other")]

def verdictName : Derivation.Verdict → String
  | .established => "established" | .contested => "contested"
  | .refuted => "refuted" | .unsupported => "unsupported"

/-- One composed arm of a hypothesis. -/
def arm {c : Claim} (hypothesis name : String) (d : Derivation c) : Json :=
  Json.mkObj [("row", "arm"), ("hypothesis", Json.str hypothesis), ("name", Json.str name),
    ("claim", claimJson c), ("opinion", opinionJson d.opinion), ("verdict", Json.str (verdictName d.verdict)),
    ("axioms", Json.arr (d.axioms.map (Json.str ·.id)).toArray),
    ("shared", Json.arr (d.sharedAxioms.map Json.str).toArray)]

/-- One statement. -/
def statementRow (s : Statement) : Json :=
  Json.mkObj [("row", "statement"), ("id", Json.str s.id), ("claim", claimJson s.claim),
    ("opinion", opinionJson s.opinion), ("verdict", Json.str (verdictName s.opinion.verdict)),
    ("evidence", Json.num s.distinctEvidence.length), ("taxonConsistent", Json.bool s.taxonConsistent)]

/-- Print a run's rows, each tagged with the run id. -/
def printRows (run : String) (rows : List Json) : IO Unit :=
  rows.forM fun r => IO.println (r.mergeObj (Json.mkObj [("run", Json.str run)])).compress

end BioLean.Lib.IPF

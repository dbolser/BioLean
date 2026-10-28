import BioLean.Rivalry

/-!
# The chemiosmotic controversy, 1953 to 1974 (M2 exit test)

Case study 2 of `docs/case-studies.md`, in Lean. Two rival accounts of how respiration drives ATP
synthesis: through a proton gradient (Mitchell 1961) or through a high-energy chemical
intermediate C~I (Slater 1953). Same agent, same target, different mediator; a `Rivalry` makes
them exclusive. Evidence is dated and every opinion is cut by year (`asOf`, `opinionAt`).

Six papers are real, with PMIDs and years from `data/formalisms/abstracts.json`. Items with
`pmid := 0` are ILLUSTRATIVE, as in `scripts/case_studies/chemiosmotic_timeline.py`; their notes
say so. With the items exactly as the script had them, neither the 1965 nor the 1974 theorem holds,
for two reasons that are forced:

* `hypothesis` weighs 0, so before Jagendorf (1966) nothing supports chemiosmosis and its belief
  in 1965 is 0: it cannot be *contested*. The script's contested 1965 came from counting Mitchell's
  theory paper at 0.7. Fix: one illustrative 1965 support item (`protons65`).
* A rivalry only adds disbelief (`Rivalry.belief_le`), so chemiosmosis under the rivalry is at most
  its own 0.800, and the script's 1963 review at 3/5 keeps the chemical intermediate's belief high
  enough to hold chemiosmosis at 0.727. Fix: the 1963 review restates the hypothesis with no data,
  so it is `.hypothesis` (weight 0), as case study 2 already said 3/5 was too generous.

The real papers alone give the 1974 result (`real_settled_1974`) but not the 1965 one: in 1965 the
real record is two weightless hypotheses.

Each experiment is entered on both rivals, as `docs/formalisms/biolean.md` does: each is a direct
anomaly for C~I (ATP made with no respiratory chain at all in 1966 and 1974; the uncoupler null in
1967), not only support for the gradient. The rivalry also turns chemiosmotic belief into
disbelief in C~I, so this is partly counted twice. Without the direct refutations neither 1974
threshold is reached (both 0.714).
-/

namespace BioLean.Examples.Chemiosmosis
open Derivation

/-! ## Entities (CURIEs as checked in `docs/formalisms/biolean.md`) -/

def respChain : Entity .process := ⟨"GO:0022904", "respiratory electron transport chain"⟩
def oxphos : Entity .process := ⟨"GO:0006119", "oxidative phosphorylation"⟩
/-- The gradient, written as the ion: no Target says "difference across a membrane". -/
def hydron : Entity .chemical := ⟨"CHEBI:15378", "hydron"⟩
/-- Slater's intermediate. No ontology names it because it was never found. -/
def cI : Entity .chemical := ⟨"BLN:C~I", "C~I, non-phosphorylated high-energy intermediate (hypothetical)"⟩
def dnp : Entity .chemical := ⟨"CHEBI:42017", "2,4-dinitrophenol"⟩
def etProtonTransport : Entity .process := ⟨"GO:0015990", "electron transport coupled proton transport"⟩

/-! ## Evidence -/

def slater53 : Evidence :=
  { pmid := 13111237, year := 1953, kind := .hypothesis,
    note := "Slater, Nature: proposes a non-phosphorylated high-energy intermediate C~I; no data" }

def mitchell61 : Evidence :=
  { pmid := 13771349, year := 1961, kind := .hypothesis,
    note := "Mitchell, Nature: proposes chemiosmotic coupling; no data" }

def jagendorf66 (p : Opinion.Polarity) : Evidence :=
  { pmid := 5220864, year := 1966, kind := .inVitro, polarity := p, system := some .inVitro,
    note := "Jagendorf & Uribe, PNAS: an acid-base jump makes ATP in the dark in spinach thylakoids, with no electron transport" }

def mitchellMoyle67 (p : Opinion.Polarity) : Evidence :=
  { pmid := 16742541, year := 1967, kind := .inVitro, polarity := p, system := some .inVitro,
    note := "Mitchell & Moyle, Biochem J: respiration translocates H+ (H+/O 4 and 6) in rat liver mitochondria; uncouplers raise H+ conductance but leave H+/O unchanged (`uncouplerNull`)" }

def hinkle71 (p : Opinion.Polarity) : Evidence :=
  { pmid := 4330063, year := 1971, kind := .inVitro, polarity := p, system := some .inVitro,
    note := "Hinkle & Horstman, JBC: respiration drives H+ uptake into inside-out bovine submitochondrial particles; abolished by uncouplers" }

def racker74 (p : Opinion.Polarity) : Evidence :=
  { pmid := 4272126, year := 1974, kind := .inVitro, polarity := p, system := some .reconstituted,
    note := "Racker & Stoeckenius, JBC: bacteriorhodopsin with bovine F1Fo in liposomes makes ATP in light; no shared chemical intermediate" }

def reviews63 (p : Opinion.Polarity) : Evidence :=
  { pmid := 0, year := 1963, kind := .hypothesis, polarity := p,
    note := "ILLUSTRATIVE (case-study script): reviews assume chemical coupling. They restate the hypothesis with no data, so `.hypothesis`, not the script's `.review` at 3/5" }

def intermediate65 (p : Opinion.Polarity) : Evidence :=
  { pmid := 0, year := 1965, kind := .inVitro, polarity := p,
    note := "ILLUSTRATIVE (case-study script): reports of an isolated high-energy intermediate, later artefacts" }

def protons65 : Evidence :=
  { pmid := 0, year := 1965, kind := .inVitro,
    note := "ILLUSTRATIVE, added here: stands for Mitchell & Moyle's 1965 Nature reports of H+ translocation (citation not checked)" }

/-! ## The rivals -/

def chemiosmotic : Statement where
  id := "chemiosmotic"
  text := "respiration drives ATP synthesis through a transmembrane proton gradient (Mitchell)"
  claim := .mediatedBy respChain .pos (.process oxphos) (.amount hydron)
  evidence := [mitchell61, protons65, jagendorf66 .supports, mitchellMoyle67 .supports,
    hinkle71 .supports, racker74 .supports]

def chemicalIntermediate : Statement where
  id := "chemical intermediate"
  text := "respiration drives ATP synthesis through a high-energy chemical intermediate C~I (Slater)"
  claim := .mediatedBy respChain .pos (.process oxphos) (.amount cI)
  evidence := [slater53, reviews63 .supports, intermediate65 .supports, jagendorf66 .refutes,
    mitchellMoyle67 .refutes, hinkle71 .refutes, racker74 .refutes]

def coupling : Rivalry := ⟨[chemiosmotic, chemicalIntermediate], by decide⟩

/-- Mitchell & Moyle's decisive null, a measured "no change", not a refuted sign. One agent per
claim: FCCP and gramicidin gave the same result. -/
def uncouplerNull : Statement where
  id := "uncoupler null"
  text := "uncouplers leave the initial H+/O quotient of respiration-driven proton transport unchanged"
  claim := .noEffect dnp (.process etProtonTransport)
  evidence := [mitchellMoyle67 .supports]

/-- The case-study script's encoding: one claim, the chemical-intermediate reports read as
refutations of chemiosmosis instead of support for a rival. -/
def oneClaim : Statement :=
  { chemiosmotic with
    id := "chemiosmotic, one claim"
    evidence := chemiosmotic.evidence ++ [reviews63 .refutes, intermediate65 .refutes] }

/-- The real papers only: illustrative items dropped. -/
def realOnly (s : Statement) : Statement := { s with evidence := s.evidence.filter (·.pmid != 0) }

def realCoupling : Rivalry := ⟨coupling.rivals.map realOnly, by decide⟩

/-! ## Exit test -/

/-- In 1965 the dispute is open: each rival has belief and disbelief of 1/3. -/
theorem contested_1965 :
    (coupling.asOf 1965).verdicts =
      [("chemiosmotic", .contested), ("chemical intermediate", .contested)] := by
  decide +kernel

/-- By 1974 chemiosmosis is established (belief ≥ 4/5) and the chemical intermediate refuted
(disbelief ≥ 4/5), under the rivalry. -/
theorem settled_1974 :
    (coupling.asOf 1974).verdicts =
      [("chemiosmotic", .established), ("chemical intermediate", .refuted)] := by
  decide +kernel

/-- Without the rivalry, read as one claim with refutations, chemiosmosis is never established,
in any year: the 1965 report votes against it forever (the script's finding). -/
theorem one_claim_never_established (year : Nat) :
    (oneClaim.opinionAt year).verdict ≠ .established :=
  Statement.forall_opinionAt (P := (·.verdict ≠ .established)) (by decide +kernel) year

/-- The real papers alone settle it by 1974, chemiosmosis exactly at 4/5. -/
theorem real_settled_1974 :
    (realCoupling.asOf 1974).verdicts =
      [("chemiosmotic", .established), ("chemical intermediate", .refuted)] := by
  decide +kernel

/-- In 1961 a derivation from the chemiosmotic statement has no belief: only the hypothesis. -/
example : ((Derivation.lit chemiosmotic).opinionAt 1961).belief = 0 := by decide +kernel

/-! ## The year table -/

def verdictName : Verdict → String
  | .established => "established" | .contested => "contested"
  | .refuted => "refuted" | .unsupported => "unsupported"

def cell (o : Opinion) : String :=
  s!"b={o.belief.toDecimal} d={o.disbelief.toDecimal} {verdictName o.verdict}"

def years : List Nat := [1953, 1961, 1963, 1965, 1966, 1967, 1971, 1974]

def table (r : Rivalry) (one : Option Statement) : String :=
  let pad (s : String) := s.pushn ' ' (31 - s.length)
  let head := "year  " ++ (match one with | some s => pad s.id | none => "") ++
    String.join (r.rivals.map fun s => pad s!"{s.id} (rivalry)")
  head ++ "\n" ++ String.intercalate "\n" (years.map fun y =>
    s!"{y}  " ++ (match one with | some s => pad (cell (s.opinionAt y)) | none => "") ++
      String.join ((r.opinionsAt y).map fun p => pad (cell p.2)))

#eval IO.println (table coupling (some oneClaim))
#eval IO.println ("real papers only\n" ++ table realCoupling none)
#eval IO.println s!"{uncouplerNull.claim}\n  {uncouplerNull.opinion}"

end BioLean.Examples.Chemiosmosis

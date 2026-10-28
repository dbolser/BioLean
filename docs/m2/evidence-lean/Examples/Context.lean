import BioLean.Derivation
import BioLean.Lib.ContextSample

/-!
# Context on evidence (M2, design "evidence")

NMN in mice and people, chemiosmosis in three membranes, and the five soundness tests S1 to S5.
Claims are bare; every context lives on an `Evidence` item; an opinion is always computed *in* a
query context `Ctx`, and only evidence that fits the query fuses.
-/

namespace BioLean.M2.Evidence
open Derivation

/-! ## Entities -/

def mouse   : Entity .taxon := ⟨"NCBITaxon:10090", "Mus musculus"⟩
def human   : Entity .taxon := ⟨"NCBITaxon:9606", "Homo sapiens"⟩
def rat     : Entity .taxon := ⟨"NCBITaxon:10116", "Rattus norvegicus"⟩
def cow     : Entity .taxon := ⟨"NCBITaxon:9913", "Bos taurus"⟩
def spinach : Entity .taxon := ⟨"NCBITaxon:3562", "Spinacia oleracea"⟩
def halo    : Entity .taxon := ⟨"NCBITaxon:2242", "Halobacterium salinarum"⟩
def mammal  : Entity .taxon := ⟨"NCBITaxon:40674", "Mammalia"⟩
def eukaryote : Entity .taxon := ⟨"NCBITaxon:2759", "Eukaryota"⟩

def NMN   : Entity .chemical := ⟨"CHEBI:16171", "nicotinamide mononucleotide"⟩
def NADp  : Entity .chemical := ⟨"CHEBI:15846", "NAD(+)"⟩
def liver : Entity .anatomy := ⟨"UBERON:0002107", "liver"⟩
-- unverified: UBERON:0001134 believed to be "skeletal muscle tissue"
def skMuscle : Entity .anatomy := ⟨"UBERON:0001134", "skeletal muscle tissue"⟩
-- unverified: HP:0040270 believed to be "Impaired glucose tolerance"
def impGlcTol : Entity .phenotype := ⟨"HP:0040270", "impaired glucose tolerance"⟩
def locomotion : Entity .process := ⟨"GO:0040011", "locomotion"⟩
-- unverified: HP:0003546 believed to be "Exercise intolerance"; "increases endurance" is
-- encoded as "reduces exercise intolerance" because no endurance term was checked.
def exIntol : Entity .phenotype := ⟨"HP:0003546", "exercise intolerance"⟩
-- unverified: GO:0032868 believed to be "response to insulin"
def insulinResp : Entity .process := ⟨"GO:0032868", "response to insulin"⟩

-- unverified: GO:0045259 "proton-transporting ATP synthase complex", GO:0015986
-- "proton motive force-driven ATP synthesis", GO:0042651 "thylakoid membrane",
-- GO:0005743 "mitochondrial inner membrane", GO:0016020 "membrane"
def atpSynthase : Entity .component := ⟨"GO:0045259", "proton-transporting ATP synthase complex"⟩
def pmfATP : Entity .process := ⟨"GO:0015986", "proton motive force-driven ATP synthesis"⟩
def thylakoidMem : Entity .component := ⟨"GO:0042651", "thylakoid membrane"⟩
def mitoInner : Entity .component := ⟨"GO:0005743", "mitochondrial inner membrane"⟩
def membrane : Entity .component := ⟨"GO:0016020", "membrane"⟩

def cell : Entity .cellType := ⟨"CL:0000000", "cell"⟩
-- unverified: PATO:0000586 "increased size", PATO:0000587 "decreased size"
def incSize : Entity .phenotype := ⟨"PATO:0000586", "increased size"⟩
def decSize : Entity .phenotype := ⟨"PATO:0000587", "decreased size"⟩
def hasQuality : Rel := ⟨.ro, 86, false⟩

/-! ## NMN (1) to (6) -/

/-- (1) NMN raises NAD+, in mouse liver. -/
def N1 : Statement where
  id := "N1"
  text := "NMN raises NAD+ in mouse liver"
  claim := .effect NMN .pos (.amount NADp)
  evidence := [{ pmid := 21982712, year := 2011, kind := .mechanistic, taxa := [mouse]
                 anatomy := some liver, note := "Yoshino 2011" }]

/-- (2) NMN reduces impaired glucose tolerance in high-fat-diet mice. -/
def N2 : Statement where
  id := "N2"
  text := "NMN reduces impaired glucose tolerance in HFD mice"
  claim := .effect NMN .neg (.phenotype impGlcTol)
  evidence := [{ pmid := 21982712, year := 2011, kind := .mechanistic, taxa := [mouse]
                 condition := some "high-fat diet", note := "Yoshino 2011" }]

/-- (3) Long-term NMN reduces the age-associated decline in physical activity in mice. Encoded as
"NMN increases locomotion", in aged mice, 12 months oral. -/
def N3 : Statement where
  id := "N3"
  text := "long-term NMN reduces age-associated decline in physical activity in mice"
  claim := .effect NMN .pos (.process locomotion)
  evidence := [{ pmid := 28068222, year := 2016, kind := .mechanistic, taxa := [mouse]
                 condition := some "aged", dose := some "100 or 300 mg/kg/day, oral (drinking water)"
                 duration := some "12 months", note := "Mills 2016" }]

/-- (4) NMN increases endurance in aged mice. -/
def N4 : Statement where
  id := "N4"
  text := "NMN increases endurance in aged mice"
  claim := .effect NMN .neg (.phenotype exIntol)
  evidence := [{ pmid := 29570999, year := 2018, kind := .mechanistic, taxa := [mouse]
                 condition := some "aged", note := "Das 2018" }]

/-- (5) NMN increases muscle insulin sensitivity in prediabetic postmenopausal women (RCT). -/
def N5 : Statement where
  id := "N5"
  text := "NMN increases muscle insulin sensitivity in prediabetic postmenopausal women"
  claim := .effect NMN .pos (.process insulinResp)
  evidence := [{ pmid := 33888596, year := 2021, kind := .rct, taxa := [human]
                 anatomy := some skMuscle, condition := some "prediabetic postmenopausal women"
                 dose := some "250 mg/day, oral", duration := some "10 weeks", note := "Yoshino 2021" }]

/-- (6) HYPOTHETICAL: NMN increases endurance in humans. In this design it is not a new claim: it
is N4's bare claim, *asked* in a human context. It has no evidence of its own. -/
def N6 : Statement where
  id := "N6"
  text := "HYPOTHETICAL: NMN increases endurance in humans"
  claim := N4.claim
  evidence := []

/-- The query for (6). It must name "aged", because N4's evidence does: dropping the condition is a
generalisation over age, which no rule here performs. -/
def humanAged : Ctx := { taxon := some human, condition := some "aged" }
def mouseAged : Ctx := { taxon := some mouse, condition := some "aged" }

/-! ## Chemiosmosis (7) to (9): one bare claim, three evidence items -/

def chemiosmosisEvidence : List Evidence := [
  { pmid := 5220864, year := 1966, kind := .inVitro, taxa := [spinach], component := some thylakoidMem
    inVitro := true, note := "Jagendorf 1966: acid-base transition, thylakoids make ATP in the dark" },
  { pmid := 16742541, year := 1967, kind := .inVitro, taxa := [rat], component := some mitoInner
    inVitro := true, note := "Mitchell & Moyle 1967: rat liver mitochondria" },
  { pmid := 4272126, year := 1974, kind := .inVitro, taxa := [halo, cow], inVitro := true
    condition := some "reconstituted proteoliposome"
    note := "Racker & Stoeckenius 1974: bacteriorhodopsin + bovine ATP synthase in liposomes" } ]

/-- (7) + (8) + (9): ATP synthase makes ATP from a proton gradient. -/
def CH : Statement where
  id := "CH"
  text := "ATP synthase makes ATP from a proton gradient"
  claim := .rel .capableOf atpSynthase pmfATP
  evidence := chemiosmosisEvidence

/-- The same split into one statement per paper, for `both`. -/
def CH7 : Statement := { CH with id := "CH7", evidence := chemiosmosisEvidence.take 1 }
def CH8 : Statement := { CH with id := "CH8", evidence := (chemiosmosisEvidence.drop 1).take 1 }
def CH9 : Statement := { CH with id := "CH9", evidence := chemiosmosisEvidence.drop 2 }

/-! ## Soundness tests -/

/-- Strip every context field: what the evidence would look like if a curator forgot to tag it. -/
def _root_.BioLean.Statement.untagged (s : Statement) : Statement :=
  { s with evidence := s.evidence.map fun e =>
      { e with taxa := [], anatomy := none, cellType := none, component := none, condition := none } }

/-! ### S1. Mouse and human evidence do not fuse by accident -/

/-- Someone pools mouse and human papers on one bare claim, INDRA-style. -/
def pooled : Statement where
  id := "pooled"
  text := "NMN increases insulin sensitivity (mouse + human papers)"
  claim := N5.claim
  evidence := N5.evidence ++ [{ pmid := 21982712, year := 2011, kind := .mechanistic
                                taxa := [mouse], anatomy := some liver, condition := some "high-fat diet"
                                note := "Yoshino 2011: NMN enhances hepatic insulin sensitivity in HFD mice" }]

def humanTrial : Ctx :=
  { taxon := some human, anatomy := some skMuscle, condition := some "prediabetic postmenopausal women" }
def mouseHFD : Ctx := { taxon := some mouse, anatomy := some liver, condition := some "high-fat diet" }

/-- Asked with no context, tagged evidence is silent: the context-free claim gets nothing. -/
theorem S1_contextFree_vacuous : ((lit pooled).opinion).belief = 0 := by decide +kernel
/-- Asked in the trial's context, only the RCT counts: exactly one RCT's worth (17/20). -/
theorem S1_human_only : ((lit pooled).opinion humanTrial).belief = 17 / 20 := by decide +kernel
/-- Asked in the mouse context, only the mouse paper counts. -/
theorem S1_mouse_only : ((lit pooled).opinion mouseHFD).belief = 7 / 10 := by decide +kernel
/-- `both` of a mouse and a human derivation of the same bare claim type-checks (nothing in the type
stops it), but each leaf still filters: in the human context the mouse side adds nothing. -/
theorem S1_both_filtered :
    ((both (lit { pooled with evidence := pooled.evidence.drop 1 }) (lit N5)).opinion humanTrial).belief
      = 17 / 20 := by decide +kernel
/-- The hole: untagged evidence fits every context, so a forgotten tag fuses mouse into human. -/
theorem S1_untagged_fuses : 17 / 20 < ((lit pooled.untagged).opinion humanTrial).belief := by
  decide +kernel

/-! ### S2. Mouse to human needs an explicit, weighted transport step -/

/-- No free path: the mouse paper alone says nothing about aged humans. -/
theorem S2_lit_silent : ((lit N4).opinion humanAged).belief = 0 := by decide +kernel
/-- With an explicit `transport mouse human`: 3/10 of the mouse opinion (7/10), i.e. 21/100. -/
theorem S2_transport : ((transport mouse human (lit N4)).opinion humanAged).belief = 21 / 100 := by
  decide +kernel
/-- And it is never more than 3/10, whatever is transported (`opinion_transport_belief_le`). -/
example (d : Derivation N6.claim) (q : Ctx) : ((transport mouse human d).opinion q).belief ≤ 3 / 10 :=
  opinion_transport_belief_le mouse human d q
/-- Transport only runs between sibling taxa: mouse to Mammalia is a generalisation, not transport. -/
theorem S2_not_generalise :
    ((transport mouse mammal (lit N4)).opinion { humanAged with taxon := some mammal }).belief = 0 := by
  decide +kernel
/-- So the hypothetical (6) is not established in aged humans, at any useful level. -/
example : ¬ (3 / 10 < ((transport mouse human (lit N4)).opinion humanAged).belief) := by decide +kernel

/-! ### S3. Specialisation is free -/

/-- "Chromosomes are located in the nucleus of eukaryotic cells" (textbook, taxon Eukaryota), asked
about mice: same opinion, no new evidence, no rule. -/
theorem S3_specialise :
    ((lit t_reproduction_at_the_cellular_level_m45455_16).opinion { taxon := some mouse }).belief =
      ((lit t_reproduction_at_the_cellular_level_m45455_16).opinion { taxon := some eukaryote }).belief ∧
    ((lit t_reproduction_at_the_cellular_level_m45455_16).opinion { taxon := some mouse }).belief = 4 / 5 := by
  decide +kernel

theorem S3_mouse_established :
    EstablishedIn { taxon := some mouse } t_reproduction_at_the_cellular_level_m45455_16.claim (4 / 5) :=
  ⟨.lit _, by decide +kernel⟩

/-! ### S4. Thylakoid + mitochondrion does not give "across a membrane" for free -/

theorem S4_thylakoid : ((lit CH).opinion { taxon := some spinach, component := some thylakoidMem }).belief
    = 1 / 2 := by decide +kernel
theorem S4_mito : ((lit CH).opinion { taxon := some rat, component := some mitoInner }).belief
    = 1 / 2 := by decide +kernel
/-- Asked about "a membrane", both are more specific than the query and neither fits. -/
theorem S4_membrane_not_free : ((lit CH).opinion { component := some membrane }).belief = 0 := by
  decide +kernel
/-- Fusing the per-paper statements does not help: each leaf is filtered by the same query. -/
theorem S4_both_not_free :
    ((both (lit CH7) (lit CH8)).opinion { component := some membrane }).belief = 0 := by decide +kernel
/-- The reconstituted chimera (9) lists two taxa and fits no single-taxon query. -/
theorem S4_racker_unreachable :
    ((lit CH9).opinion { taxon := some cow, condition := some "reconstituted proteoliposome" }).belief
      = 0 := by decide +kernel
/-- ... and with an in-vivo-only query nothing chemiosmotic survives. -/
theorem S4_in_vivo : ((lit CH).opinion { taxon := some rat, component := some mitoInner
                                         inVivoOnly := true }).belief = 0 := by decide +kernel

/-! ### S5. Hypotonic swell, hypertonic shrink -/

def swell : Statement where
  id := "swell"
  text := "cells in a hypotonic solution swell"
  claim := .rel hasQuality cell incSize
  evidence := [{ pmid := 0, year := 2013, kind := .textbook, condition := some "hypotonic solution" }]

def shrink : Statement where
  id := "shrink"
  text := "cells in a hypertonic solution shrink"
  claim := .rel hasQuality cell decSize
  evidence := [{ pmid := 0, year := 2013, kind := .textbook, condition := some "hypertonic solution" }]

/-- "Cells in a hypertonic solution do not swell": true, and the negation of `swell`'s bare claim. -/
def noSwellHyper : Statement where
  id := "noSwellHyper"
  text := "cells in a hypertonic solution do not swell"
  claim := .notRel hasQuality cell incSize
  evidence := [{ pmid := 0, year := 2013, kind := .textbook, condition := some "hypertonic solution" }]

def hypo : Ctx := { condition := some "hypotonic solution" }
def hyper : Ctx := { condition := some "hypertonic solution" }

-- swell and shrink are different bare claims: `both (lit swell) (lit shrink)` does not type-check.
#check_failure (both (lit swell) (lit shrink))

/-- In the hypotonic context the clash is one-sided: swelling believed, no disbelief. -/
theorem S5_hypo : (clash (lit swell) (lit noSwellHyper) hypo).belief = 4 / 5 ∧
    (clash (lit swell) (lit noSwellHyper) hypo).disbelief = 0 := by decide +kernel
/-- In the hypertonic context, the other way round. Never contested. -/
theorem S5_hyper : (clash (lit swell) (lit noSwellHyper) hyper).belief = 0 ∧
    (clash (lit swell) (lit noSwellHyper) hyper).disbelief = 4 / 5 := by decide +kernel
/-- Shrinking is established in hypertonic solution and silent in hypotonic. -/
theorem S5_shrink : ((lit shrink).opinion hyper).belief = 4 / 5 ∧
    ((lit shrink).opinion hypo).belief = 0 := by decide +kernel
/-- Without the condition tags the same two textbook sentences contradict each other. -/
theorem S5_untagged_contested :
    (clash (lit swell.untagged) (lit noSwellHyper.untagged)).verdict = .contested := by decide +kernel

/-! ## The 40 -/

theorem sample40_count : sample40.length = 40 := rfl

/-- Each of the 40 fits no context-free query whenever it carries a tag (39 of 40 do). -/
theorem sample40_contextFree_silent :
    (sample40.filter fun s => (lit s).opinion.belief == 0).length = 39 := by decide +kernel

#eval IO.println ((transport mouse human (lit N4)).report humanAged)
#eval IO.println ((both (lit CH7) (lit CH8)).report { component := some membrane })
#eval IO.println s!"pooled, no context: {(lit pooled).opinion}; human trial: {(lit pooled).opinion humanTrial}; untagged in human: {(lit pooled.untagged).opinion humanTrial}"

end BioLean.M2.Evidence

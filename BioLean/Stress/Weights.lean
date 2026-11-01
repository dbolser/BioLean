import BioLean.Examples.Chemiosmosis
import BioLean.Examples.Ozempic
import BioLean.Examples.Context
import BioLean.Examples.Transcription
import BioLean.Lib.TextbookClaimsR3.ReproductionAtTheCellularLevel
import BioLean.Lib.TextbookClaimsR2.CellStructureAndFunction

/-!
# Stress set 10a: evidence weights (M6)

Program: `docs/programs/10a-evidence-weights.md`. Case table: `data/stress/10a/cases.tsv`.

51 evidence scenarios that probe how BioLean turns evidence into belief. Each is run under today's
core and under prototype schemes for the M6 options. Nothing here changes the core. A *scheme* is a
pair of leaf functions for `Derivation.opinionWith`, which the core already exposes, plus a verdict.
Prototypes live in the namespace `BioLean.Proto.Weights` in this file: a new file cannot import
another new file, so the prototypes and the cases that exercise them share one file.

1. Pseudo-counts, and two theorems: a statement's opinion is the opinion of its total supporting and
   refuting pseudo-counts, and its verdict is established exactly when `S ≥ 4R + 8`.
2. The statements of the stress set, built with the current core.
3. Schemes, cases and marks (PASS, FAIL, SILENT, INEXPRESSIBLE).
4. Sensitivity: each pseudo-count times 2 and times 1/2, over Ozempic and Chemiosmosis.
5. Prototypes of options B to N (outside the core), and the schemes built from them.
6. The M6 exit test, three wordings.
7. Pins: every observed value, as `#guard`. A change to the core, the weights or a prototype flips
   one of them.
8. Printers, read by `scripts/stress/weights_cases.py` to write the tables.

CURIEs checked on OLS4 and PMIDs on Europe PMC on 2026-10-31 (`data/stress/10a/curies_checked.tsv`,
`references_checked.tsv`). `BLN:` ids are placeholders. PMIDs 70000001, 8xxxxxxx and 9xxxxxxx are
SYNTHETIC.
-/

namespace BioLean.Stress.Weights
open BioLean Derivation Taxa

/-! ## 0. Helpers -/

def ev (pmid year : Nat) (k : EvidenceKind) (p : Opinion.Polarity := .supports) (note : String := "") :
    Evidence := { pmid, year, kind := k, polarity := p, note }
def st (id : String) (c : Claim) (es : List Evidence) : Statement :=
  { id, text := id, claim := c, evidence := es }

def vn : Verdict → String
  | .established => "established" | .contested => "contested"
  | .refuted => "refuted" | .unsupported => "unsupported"

def kinds : List EvidenceKind := [.metaAnalysis, .rct, .curatedDb, .textbook, .ontologyAxiom,
  .mechanistic, .review, .observational, .inVitro, .textMined, .hypothesis, .crossSpecies, .definitional]
def kname : EvidenceKind → String
  | .metaAnalysis => "metaAnalysis" | .rct => "rct" | .curatedDb => "curatedDb" | .textbook => "textbook"
  | .ontologyAxiom => "ontologyAxiom" | .mechanistic => "mechanistic" | .review => "review"
  | .observational => "observational" | .inVitro => "inVitro" | .textMined => "textMined"
  | .hypothesis => "hypothesis" | .crossSpecies => "crossSpecies" | .definitional => "definitional"

/-! ## 1. Pseudo-counts

One item of reliability `r` gives the opinion `⟨r, 0, 1 - r⟩`. With Jøsang's prior weight `W = 2`
that is `n = 2r / (1 - r)` pseudo-observations: `r = n / (n + 2)`. Cumulative fusion then adds
pseudo-counts (`fuse_ofCounts`), so a statement's opinion depends on two numbers only: total support
`S` and total refutation `R` (`statement_opinion_eq`). Its verdict is established exactly when
`S ≥ 4R + 8` (`established_iff`) and refuted exactly when `R ≥ 4S + 8` (`refuted_iff`). -/

def std (k : EvidenceKind) : ℚ := @EvidenceModel.reliability EvidenceModel.standard k
def pc (r : ℚ) : ℚ := 2 * r / (1 - r)

/-- The pseudo-count of every evidence kind under `EvidenceModel.standard` (M6 exit test, part 2). -/
def pseudoCounts : List (String × ℚ) := kinds.map fun k => (kname k, pc (std k))

#guard pseudoCounts.map (·.2) == [18, 34/3, 8, 8, 18, 14/3, 3, 2, 2, 6/7, 0, 6/7, 1998]

/-- The opinion of `s` supporting and `r` refuting pseudo-observations, prior weight 2. -/
def ofCounts (s r : ℚ) : Opinion where
  belief := max s 0 / (max s 0 + max r 0 + 2)
  disbelief := max r 0 / (max s 0 + max r 0 + 2)
  uncertainty := 2 / (max s 0 + max r 0 + 2)
  belief_nonneg := div_nonneg (le_max_right _ _) (by have := le_max_right s 0; have := le_max_right r 0; linarith)
  disbelief_nonneg := div_nonneg (le_max_right _ _) (by have := le_max_right s 0; have := le_max_right r 0; linarith)
  uncertainty_pos := div_pos two_pos (by have := le_max_right s 0; have := le_max_right r 0; linarith)
  sum_eq_one := by
    have := le_max_right s 0; have := le_max_right r 0
    rw [← add_div, ← add_div, div_eq_one_iff_eq (by linarith)]

/-- Cumulative fusion adds pseudo-counts. -/
theorem fuse_ofCounts {a b c d : ℚ} (ha : 0 ≤ a) (hb : 0 ≤ b) (hc : 0 ≤ c) (hd : 0 ≤ d) :
    (ofCounts a b).fuse (ofCounts c d) = ofCounts (a + c) (b + d) := by
  have hac : 0 ≤ a + c := by linarith
  have hbd : 0 ≤ b + d := by linarith
  have h1 : a + b + 2 ≠ 0 := by linarith
  have h2 : c + d + 2 ≠ 0 := by linarith
  have h3 : a + c + (b + d) + 2 ≠ 0 := by linarith
  have hk : 2 / (a + b + 2) + 2 / (c + d + 2) - 2 / (a + b + 2) * (2 / (c + d + 2)) =
      2 * (a + c + (b + d) + 2) / ((a + b + 2) * (c + d + 2)) := by
    field_simp; ring
  ext <;> simp only [Opinion.fuse, Opinion.kappa, ofCounts, max_eq_left ha, max_eq_left hb,
    max_eq_left hc, max_eq_left hd, max_eq_left hac, max_eq_left hbd] <;> rw [hk] <;> field_simp

theorem vacuous_eq : Opinion.vacuous = ofCounts 0 0 := by
  ext <;> simp [Opinion.vacuous, ofCounts]

theorem pc_nonneg {r : ℚ} (h0 : 0 ≤ r) (h1 : r < 1) : 0 ≤ pc r :=
  div_nonneg (by linarith) (by linarith)

theorem ofReliability_eq {r : ℚ} (h0 : 0 ≤ r) (h1 : r < 1) (p : Opinion.Polarity) :
    Opinion.ofReliability r h0 h1 p =
      match p with | .supports => ofCounts (pc r) 0 | .refutes => ofCounts 0 (pc r) := by
  have hp := pc_nonneg h0 h1
  have h : 1 - r ≠ 0 := by linarith
  cases p <;> ext <;> simp only [Opinion.ofReliability, ofCounts, max_eq_left hp, max_self] <;>
    simp only [pc] <;> field_simp <;> ring

def supCount [m : EvidenceModel] (e : Evidence) : ℚ :=
  match e.polarity with | .supports => pc (m.reliability e.kind) | .refutes => 0
def refCount [m : EvidenceModel] (e : Evidence) : ℚ :=
  match e.polarity with | .supports => 0 | .refutes => pc (m.reliability e.kind)

theorem opinion_eq_counts [m : EvidenceModel] (e : Evidence) :
    e.opinion = ofCounts (supCount e) (refCount e) := by
  unfold Evidence.opinion supCount refCount
  rw [ofReliability_eq]
  cases e.polarity <;> rfl

theorem supCount_nonneg [m : EvidenceModel] (e : Evidence) : 0 ≤ supCount e := by
  unfold supCount; cases e.polarity
  · exact pc_nonneg (m.nonneg _) (m.lt_one _)
  · exact le_rfl
theorem refCount_nonneg [m : EvidenceModel] (e : Evidence) : 0 ≤ refCount e := by
  unfold refCount; cases e.polarity
  · exact le_rfl
  · exact pc_nonneg (m.nonneg _) (m.lt_one _)

theorem foldl_fuse [EvidenceModel] (l : List Evidence) {a b : ℚ} (ha : 0 ≤ a) (hb : 0 ≤ b) :
    l.foldl (fun acc e => acc.fuse e.opinion) (ofCounts a b) =
      ofCounts (a + (l.map supCount).sum) (b + (l.map refCount).sum) := by
  induction l generalizing a b with
  | nil => simp
  | cons e l ih =>
    simp only [List.foldl_cons, List.map_cons, List.sum_cons]
    rw [opinion_eq_counts e, fuse_ofCounts ha hb (supCount_nonneg e) (refCount_nonneg e),
      ih (by have := supCount_nonneg e; linarith) (by have := refCount_nonneg e; linarith)]
    congr 1 <;> ring

/-- Total supporting and refuting pseudo-counts of a statement, after repeated PMIDs are dropped. -/
def S_ [EvidenceModel] (s : Statement) : ℚ := (s.distinctEvidence.map supCount).sum
def R_ [EvidenceModel] (s : Statement) : ℚ := (s.distinctEvidence.map refCount).sum

/-- A statement's opinion is the opinion of its total pseudo-counts, for every `EvidenceModel`.
So, for one statement, the order, the number and the kinds of the items matter only through two
sums. Ten weak items and one strong item of the same total are indistinguishable. -/
theorem statement_opinion_eq [EvidenceModel] (s : Statement) : s.opinion = ofCounts (S_ s) (R_ s) := by
  unfold Statement.opinion S_ R_
  rw [vacuous_eq, foldl_fuse _ le_rfl le_rfl]
  simp

theorem S_nonneg [EvidenceModel] (s : Statement) : 0 ≤ S_ s :=
  List.sum_nonneg (by simp only [List.mem_map]; rintro _ ⟨e, -, rfl⟩; exact supCount_nonneg e)
theorem R_nonneg [EvidenceModel] (s : Statement) : 0 ≤ R_ s :=
  List.sum_nonneg (by simp only [List.mem_map]; rintro _ ⟨e, -, rfl⟩; exact refCount_nonneg e)

/-- Established exactly when support is at least four times refutation plus 8. The dispute floor
never fires first: `S ≥ 4R + 8` forces `d < 1/4`. -/
theorem established_iff {s r : ℚ} (hs : 0 ≤ s) (hr : 0 ≤ r) :
    (ofCounts s r).verdict = .established ↔ 4 * r + 8 ≤ s := by
  have hD : 0 < s + r + 2 := by linarith
  simp only [Opinion.verdict, ofCounts, max_eq_left hs, max_eq_left hr, le_div_iff₀ hD]
  constructor
  · intro h
    split_ifs at h with h1 h2
    linarith
  · intro h
    split_ifs with h1 h2 <;> first | rfl | (exfalso; linarith [h1.2]) | (exfalso; linarith)

/-- Refuted exactly when refutation is at least four times support plus 8. -/
theorem refuted_iff {s r : ℚ} (hs : 0 ≤ s) (hr : 0 ≤ r) :
    (ofCounts s r).verdict = .refuted ↔ 4 * s + 8 ≤ r := by
  have hD : 0 < s + r + 2 := by linarith
  simp only [Opinion.verdict, ofCounts, max_eq_left hs, max_eq_left hr, le_div_iff₀ hD]
  constructor
  · intro h
    split_ifs at h with h1 h2 h3
    linarith
  · intro h
    split_ifs with h1 h2 h3 <;> first | rfl | (exfalso; linarith [h1.1]) | (exfalso; linarith)

/-- The core's verdict on a statement, in pseudo-counts. -/
theorem statement_established_iff [EvidenceModel] (s : Statement) :
    s.opinion.verdict = .established ↔ 4 * R_ s + 8 ≤ S_ s := by
  rw [statement_opinion_eq]; exact established_iff (S_nonneg s) (R_nonneg s)

theorem statement_refuted_iff [EvidenceModel] (s : Statement) :
    s.opinion.verdict = .refuted ↔ 4 * S_ s + 8 ≤ R_ s := by
  rw [statement_opinion_eq]; exact refuted_iff (S_nonneg s) (R_nonneg s)

/-- Nothing with refuting pseudo-count below 8 is ever refuted, whatever supports it. Under the
standard table that is fewer than four in-vitro or observational items: two failed replications
(R = 4) can never refute a claim (R01, R02). -/
theorem not_refuted_of_lt_eight [EvidenceModel] (s : Statement) (h : R_ s < 8) :
    s.opinion.verdict ≠ .refuted := by
  rw [Ne, statement_refuted_iff]; have := S_nonneg s; intro h'; linarith

/-! ## 2. The statements of the stress set (current core) -/

/-! ### Entities (OLS4, 2026-10-31; `BLN:` placeholders) -/
def estrogen : Entity .chemical := ⟨"CHEBI:50114", "estrogen"⟩
def vitE : Entity .chemical := ⟨"CHEBI:33234", "vitamin E"⟩
def mgso4 : Entity .chemical := ⟨"CHEBI:32599", "magnesium sulfate"⟩
def nxy : Entity .chemical := ⟨"CHEBI:135431", "disufenton (NXY-059)"⟩
def bcarotene : Entity .chemical := ⟨"CHEBI:17579", "beta-carotene"⟩
/-- A VO vaccine term typed as `Kind.chemical`: BioLean has no vaccine kind. -/
def mmr : Entity .chemical := ⟨"VO:0000731", "Measles-Mumps-Rubella vaccine"⟩
def resveratrol : Entity .chemical := ⟨"CHEBI:27881", "resveratrol"⟩
def hydron : Entity .chemical := ⟨"CHEBI:15378", "hydron"⟩
def arsenate : Entity .chemical := ⟨"CHEBI:29125", "arsenate(3-)"⟩
def dna : Entity .chemical := ⟨"CHEBI:16991", "deoxyribonucleic acid"⟩
def sirt1 : Entity .protein := ⟨"PR:000014888", "NAD-dependent protein deacetylase sirtuin-1"⟩
def chdP : Entity .phenotype := ⟨"HP:0001677", "Coronary artery atherosclerosis"⟩
def miP : Entity .phenotype := ⟨"HP:0001658", "Myocardial infarction"⟩
def dead : Entity .phenotype := ⟨"PATO:0001422", "dead"⟩
def infarct : Entity .phenotype := ⟨"HP:0025722", "Cerebral infarct"⟩
def lungNeo : Entity .phenotype := ⟨"HP:0100526", "Neoplasm of the lung"⟩
def autism : Entity .phenotype := ⟨"HP:0000717", "Autism"⟩
def stemCell : Entity .cellType := ⟨"CL:0000034", "stem cell"⟩
def esc : Entity .cellType := ⟨"CL:0002322", "embryonic stem cell"⟩
def lymphocyte : Entity .cellType := ⟨"CL:0000542", "lymphocyte"⟩
def heart : Entity .anatomy := ⟨"UBERON:0000948", "heart"⟩
def hippocampus : Entity .anatomy := ⟨"UBERON:0002421", "hippocampal formation"⟩
def adultStage : Entity .anatomy := ⟨"UBERON:0000113", "post-juvenile adult stage"⟩
def scntBlastocyst : Entity .anatomy := ⟨"BLN:scnt_blastocyst", "blastocyst made by somatic cell nuclear transfer"⟩
def cmDiff : Entity .process := ⟨"GO:0055007", "cardiac muscle cell differentiation"⟩
def dediff : Entity .process := ⟨"GO:0043697", "cell dedifferentiation"⟩
def neurogenesis : Entity .process := ⟨"GO:0022008", "neurogenesis"⟩
def mitochondrion : Entity .component := ⟨"GO:0005739", "mitochondrion"⟩
def cell : Entity .cellType := ⟨"CL:0000000", "cell"⟩
def giardia : Entity .taxon := ⟨"NCBITaxon:184922", "Giardia lamblia ATCC 50803"⟩
def gfaj1 : Entity .taxon := ⟨"NCBITaxon:1118153", "Halomonas sp. GFAJ-1"⟩
def miPatient : Ctx := { taxon := human, condition := some (.organism miP) }

/-! ### W: many weak items against strong ones -/
def nhs85 := ev 4047106 1985 .observational .supports "Stampfer 1985, Nurses' Health Study (NHS)"
def nhs91 := ev 1870648 1991 .observational .supports "Stampfer 1991, NHS ten-year follow-up"
def nhs96 := ev 8672166 1996 .observational .supports "Grodstein 1996, NHS"
def nhs00 := ev 11119394 2000 .observational .supports "Grodstein 2000, NHS"
def sc91 := ev 1826173 1991 .metaAnalysis .supports "Stampfer & Colditz 1991: meta-analysis of observational studies; cites NHS 1985"
def hers98 := ev 9718051 1998 .rct .refutes "Hulley 1998, HERS"
def whi02 := ev 12117397 2002 .rct .refutes "Rossouw 2002, WHI"
def whi03 := ev 12904517 2003 .rct .refutes "Manson 2003, WHI coronary outcomes (same trial as WHI 2002)"
def hrt : Statement := st "HRT reduces CHD" (.effect (estrogen.inCtx { taxon := human }) .neg (.phenotype chdP))
  [nhs85, nhs91, sc91, nhs96, hers98, nhs00, whi02, whi03]

def vite : Statement := st "vitamin E reduces MI" (.effect (vitE.inCtx { taxon := human }) .neg (.phenotype miP))
  [ev 8479463 1993 .observational .supports "Stampfer 1993, NHS", ev 8479464 1993 .observational .supports "Rimm 1993, HPFS",
   ev 8622332 1996 .rct .supports "CHAOS", ev 10639540 2000 .rct .refutes "HOPE",
   ev 15769967 2005 .rct .refutes "HOPE-TOO (extension of HOPE)", ev 15998891 2005 .rct .refutes "WHS",
   ev 18997197 2008 .rct .refutes "PHS II"]

def teo91 := ev 1838289 1991 .metaAnalysis .supports "Teo 1991: overview of seven RCTs"
def mgPrimaries : List Evidence :=
  [ev 6399346 1984 .rct, ev 2868254 1986 .rct, ev 2427458 1986 .rct, ev 3548627 1987 .rct,
   ev 2589170 1989 .rct, ev 2195862 1990 .rct]
def mg : Statement := st "IV magnesium reduces death after MI" (.effect (mgso4.inCtx miPatient) .neg (.phenotype dead))
  [teo91, ev 1351547 1992 .rct .supports "LIMIT-2, 2,316 patients", ev 7661937 1995 .rct .refutes "ISIS-4, 58,050 patients",
   ev 12401244 2002 .rct .refutes "MAGIC, 6,213 patients"]
def mgDouble : Statement := { mg with id := "Mg 1991: meta plus six of its trials", evidence := teo91 :: mgPrimaries }

def nxyHuman : Statement := st "NXY-059 reduces infarct, human" (.effect (nxy.inCtx { taxon := human }) .neg (.phenotype infarct))
  [ev 16467546 2006 .rct .supports "SAINT I, 1,722 patients", ev 17687131 2007 .rct .refutes "SAINT II, 3,306 patients"]
def nxyRat : Statement := st "NXY-059 reduces infarct, rat" (.effect (nxy.inCtx { taxon := rat }) .neg (.phenotype infarct))
  [ev 18635842 2008 .metaAnalysis .supports "Macleod 2008: meta-analysis of animal studies; efficacy confounded by study quality"]
def ratToHuman : Evidence := { pmid := 0, year := 2026, kind := .crossSpecies, note := "rat to human, neuroprotection" }
def nxyTransported : Derivation (.effect (nxy.inCtx { taxon := human }) .neg (.phenotype infarct)) :=
  .transport {} human (.lit nxyRat) ratToHuman
def nxyAll := Derivation.both (.lit nxyHuman) nxyTransported

/-- SYNTHETIC claim for W06, W07, D09, D10, CAL03. -/
def synthClaim : Claim := .effect (estrogen.inCtx { taxon := human }) .neg (.phenotype miP)
def obsVsRct (k : Nat) : Statement := st s!"{k} observational against 1 RCT (synthetic)" synthClaim
  ((List.range k).map (fun i => ev (90000000 + i) 2000 .observational) ++ [ev 89999999 2000 .rct .refutes])
def textMinedN (k : Nat) : Statement := st s!"{k} text-mined (synthetic)" synthClaim
  ((List.range k).map (fun i => ev (80000000 + i) 2020 .textMined))

def betacar : Statement := st "beta-carotene reduces lung cancer" (.effect (bcarotene.inCtx { taxon := human }) .neg (.phenotype lungNeo))
  [ev 7010181 1981 .hypothesis .supports "Peto 1981", ev 8127329 1994 .rct .refutes "ATBC", ev 8602180 1996 .rct .refutes "CARET"]

/-- An NCIT exposure term typed as `Kind.chemical`, as `mmr` is: BioLean has no exposure kind. -/
def tobaccoSmoke : Entity .chemical := ⟨"NCIT:C829", "Tobacco Smoke"⟩
/-- W09 (added in review): a fair case that rests on observational evidence alone. Ten reports of
seven studies by 1958, all observational: the five case-control studies of 1950 (Doll 1998 counts
five; Doll & Hill's in full 1952) and two cohorts (Hammond & Horn 1954 and 1958; British Doctors 1954
and 1956). Causation "came to be generally accepted in respect of lung cancer by the late 1950s"
(Doll 1998, PMID:9654637). The full 1958 record held more studies than these. -/
def smoking : Statement := st "tobacco smoke causes lung cancer"
  (.effect (tobaccoSmoke.inCtx { taxon := human }) .pos (.phenotype lungNeo))
  [ev 15415260 1950 .observational .supports "Wynder & Graham 1950, case-control, 684 cases",
   ev 14772469 1950 .observational .supports "Doll & Hill 1950, case-control",
   ev 15415261 1950 .observational .supports "Levin 1950, case-control",
   ev 14772728 1950 .observational .supports "Mills & Porter 1950, case-control",
   ev 15398042 1950 .observational .supports "Schrek 1950, case-control",
   ev 12997741 1952 .observational .supports "Doll & Hill 1952, the same case-control study in full",
   ev 13174399 1954 .observational .supports "Hammond & Horn 1954, ACS cohort, 187,766 men",
   ev 13160495 1954 .observational .supports "Doll & Hill 1954, British Doctors cohort",
   ev 13364389 1956 .observational .supports "Doll & Hill 1956, British Doctors cohort, second report",
   ev 12308037 1958 .observational .supports "Hammond & Horn 1958, ACS cohort, 187,783 men, deaths by cause"]

/-! ### D: dependent sources -/
def anversaClaim : Claim := .rel Rel.capableOf (stemCell.inCtx { anatomy := heart }) cmDiff
def anversaLab : List Evidence :=
  [ev 14505575 2003 .mechanistic, ev 18202313 2008 .mechanistic, ev 20522802 2010 .mechanistic,
   ev 21088285 2010 .mechanistic, ev 21403094 2011 .mechanistic, ev 21546606 2011 .mechanistic,
   ev 22275487 2012 .mechanistic, ev 22851539 2012 .mechanistic, ev 22955965 2012 .mechanistic,
   ev 23281411 2013 .review]
def anversa : Statement := st "c-kit+ cardiac stem cells make cardiomyocytes" anversaClaim
  (anversaLab ++ [ev 24805242 2014 .mechanistic .refutes "van Berlo 2014"])

def nhsOnly : Statement := st "NHS, four reports" (.effect (estrogen.inCtx { taxon := human }) .neg (.phenotype chdP))
  [nhs85, nhs91, nhs96, nhs00]

def gao22 := ev 36188627 2022 .metaAnalysis .supports "Gao 2022 meta-analysis; includes O'Neil 2018 (30122305), which is also in S7"
def s7meta : Statement := { BioLean.Lib.S7 with id := "S7 + Gao 2022", evidence := BioLean.Lib.S7.evidence ++ [gao22] }

def mmrClaim : Claim := .effect (mmr.inCtx { taxon := human }) .pos (.phenotype autism)
def wakefield := ev 9500320 1998 .observational .supports "Wakefield 1998, 12 children; retracted 2010"
def taylor99 := ev 10376617 1999 .observational .refutes "Taylor 1999"
def madsen02 := ev 12421889 2002 .observational .refutes "Madsen 2002, 537,303 children"
def taylor14 := ev 24814559 2014 .metaAnalysis .refutes "Taylor 2014: meta-analysis of cohort and case-control studies; cites Madsen 2002"
def hviid19 := ev 30831578 2019 .observational .refutes "Hviid 2019, 657,461 children"
def mmrS : Statement := st "MMR causes autism" mmrClaim [wakefield, taylor99, madsen02, taylor14, hviid19]

def s1NoReviews : Statement :=
  { BioLean.Lib.S1 with id := "S1 without reviews", evidence := BioLean.Lib.S1.evidence.filter (·.kind != .review) }

open BioLean.Textbook.R3.ReproductionAtTheCellularLevel in
def chrom46x3 := Derivation.both (.lit reproduction_at_the_cellular_level_m45455_17)
  (.both (.lit reproduction_at_the_cellular_level_m45455_46) (.lit reproduction_at_the_cellular_level_m45455_60))

def samePmidSR : Statement := st "same PMID, supports then refutes (synthetic)" synthClaim
  [ev 70000001 2020 .rct .supports, ev 70000001 2020 .rct .refutes]
def samePmidRS : Statement := st "same PMID, refutes then supports (synthetic)" synthClaim
  [ev 70000001 2020 .rct .refutes, ev 70000001 2020 .rct .supports]
def samePmidSS : Statement := st "same PMID twice (synthetic)" synthClaim
  [ev 70000001 2020 .rct .supports, ev 70000001 2020 .rct .supports]

/-! ### R: retraction and failed replication -/
def stap : Statement := st "acid stress makes lymphocytes pluripotent"
  (.effect hydron .pos (.process (dediff.inCtx { cellType := lymphocyte, taxon := mouse })))
  [ev 24476887 2014 .mechanistic .supports "Obokata 2014a, retracted", ev 24476891 2014 .mechanistic .supports "Obokata 2014b, retracted",
   ev 26399835 2015 .inVitro .refutes "De Los Angeles 2015", ev 26399834 2015 .inVitro .refutes "Konno 2015"]
def gfaj : Statement := st "GFAJ-1 DNA has arsenate" (.rel Rel.hasPart (dna.inCtx { taxon := gfaj1 }) arsenate)
  [ev 21127214 2011 .inVitro .supports "Wolfe-Simon 2011, retracted", ev 22773140 2012 .inVitro .refutes "Reaves 2012",
   ev 22773139 2012 .inVitro .refutes "Erb 2012"]
def scnt : Statement := st "human SCNT blastocysts give ES cells"
  (.rel (⟨.ro, 2202, false⟩ : Rel) (esc.inCtx { taxon := human }) scntBlastocyst)
  [ev 14963337 2004 .inVitro .supports "Hwang 2004, retracted", ev 15905366 2005 .inVitro .supports "Hwang 2005, retracted",
   ev 23683578 2013 .inVitro .supports "Tachibana 2013", ev 24776804 2014 .inVitro .supports "Yamada 2014",
   ev 24746675 2014 .inVitro .supports "Chung 2014"]
/-- The curator leaves the retracted Hwang papers out (R04). -/
def scntValid : Statement := { scnt with evidence := scnt.evidence.filter (fun e => e.pmid != 14963337 && e.pmid != 15905366) }
def resv : Statement := st "resveratrol activates SIRT1" (.effect resveratrol .pos (.activity sirt1))
  [ev 12939617 2003 .inVitro .supports "Howitz 2003", ev 15684413 2005 .inVitro .refutes "Kaeberlein 2005",
   ev 15749705 2005 .inVitro .refutes "Borra 2005", ev 20061378 2010 .inVitro .refutes "Pacholec 2010",
   ev 23471411 2013 .inVitro .supports "Hubbard 2013"]

/-! ### T: textbook against primary papers -/
def neuroClaim : Claim := .rel Rel.occursIn (neurogenesis.inCtx { taxon := human, lifeStage := adultStage }) hippocampus
/-- The textbook sentence (the-body-s-systems-m45539-123) names no species and no site; it is
entered on the human hippocampal claim, a simplification. -/
def neuro : Statement := st "adult human hippocampal neurogenesis" neuroClaim
  [ev 0 2013 .textbook .supports "OpenStax the-body-s-systems-m45539-123: neurogenesis continues into adulthood",
   ev 9809557 1998 .observational .supports "Eriksson 1998", ev 23746839 2013 .observational .supports "Spalding 2013",
   ev 29513649 2018 .observational .refutes "Sorrells 2018", ev 29625071 2018 .observational .supports "Boldrini 2018",
   ev 29681514 2018 .review .supports "Kempermann 2018", ev 30911133 2019 .observational .supports "Moreno-Jimenez 2019",
   ev 34798047 2022 .observational .refutes "Franjic 2022"]
def neuroMar2018 : Statement := { neuro with evidence := neuro.evidence.filter (fun e => e.pmid ∈ [0, 9809557, 23746839, 29513649]) }
def cellsDNA : Statement := BioLean.Textbook.R2.CellStructureAndFunction.cell_structure_and_function_m45429_9

/-! ### C: curated annotations -/
/-- One GO annotation row as one curated item; the note keeps its GO evidence code, ECO term and
GO_REF (the pipeline that made it). -/
def goRow (code eco ref : String) (i : Nat) : Evidence :=
  { pmid := 0, year := 2026, kind := .curatedDb, note := s!"{code} {eco} {ref} row {i}" }
/-- QuickGO, 2026-10-31: every annotation of a Giardia lamblia ATCC 50803 protein to mitochondrion
(GO:0005739, exact term). 50 rows: 38 IBA (ECO:0000318, GO_REF:0000033) and 12 automatic, all under
ECO:0000501 (6 ECO:0000256 GO_REF:0000117, 4 ECO:0000501 GO_REF:0000120, 1 ECO:0007322 GO_REF:0000044,
1 ECO:0000364 GO_REF:0000108). None experimental. -/
def giardiaRows : List Evidence :=
  (List.range 38).map (goRow "IBA" "ECO:0000318" "GO_REF:0000033") ++
  (List.range 6).map (goRow "IEA" "ECO:0000256" "GO_REF:0000117") ++
  (List.range 4).map (goRow "IEA" "ECO:0000501" "GO_REF:0000120") ++
  (List.range 1).map (goRow "IEA" "ECO:0007322" "GO_REF:0000044") ++
  (List.range 1).map (goRow "IEA" "ECO:0000364" "GO_REF:0000108")
def giardiaMito : Statement := st "Giardia has part mitochondrion (50 GO rows)"
  (.rel Rel.hasPart (cell.inCtx { taxon := giardia }) mitochondrion) giardiaRows
def giardiaMitoTovar : Statement :=
  { giardiaMito with evidence := giardiaMito.evidence ++ [ev 14614504 2003 .inVitro .refutes "Tovar 2003: mitosomes"] }
def iea : Evidence := { pmid := 0, year := 2026, kind := .curatedDb, note := "IEA ECO:0000501" }
def exp : Evidence := { pmid := 0, year := 2026, kind := .curatedDb, note := "EXP ECO:0000269" }
def ieaS : Statement := st "one IEA row" (.rel Rel.hasPart (cell.inCtx { taxon := giardia }) mitochondrion) [iea]
def expS : Statement := st "one EXP row" (.rel Rel.hasPart (cell.inCtx { taxon := giardia }) mitochondrion) [exp]

#guard giardiaRows.length == 50

/-! ### O: old against new (46 against 48 human chromosomes) -/
open BioLean.Textbook.R3.ReproductionAtTheCellularLevel in
def c46claim : Claim := reproduction_at_the_cellular_level_m45455_17.claim
open BioLean.Textbook.R2 in
def c48claim : Claim := .count (e_CL_0000415.inCtx { taxon := e_NCBITaxon_9606 }) e_GO_0005694 48
/-- Tjio & Levan 1956 has a DOI but no PMID, so it is entered with `pmid := 0`. -/
def tjio := ev 0 1956 .observational .supports "Tjio & Levan 1956, Hereditas, doi:10.1111/j.1601-5223.1956.tb03010.x"
def ford := ev 13378517 1956 .observational .supports "Ford & Hamerton 1956"
def tb46 := ev 0 2013 .textbook .supports "OpenStax m45455-17, -46, -60"
def chrom46 : Statement := st "46" c46claim [tjio, ford, tb46, tb46, tb46]
def chrom48 : Statement := st "48" c48claim [ev 0 1923 .observational .supports "Painter 1923, doi:10.1002/jez.1400370303"]
def chromR : Rivalry := ⟨[chrom46, chrom48], by decide⟩

/-! ### L: extraction against study strength -/
def s8NoSustain2 : Statement := { BioLean.Lib.S8 with evidence := BioLean.Lib.S8.evidence.filter (·.pmid != 28385659) }
def sitaNoSustain2 := Derivation.both BioLean.Lib.sitagliptin_reduces_feeding_mechanistic (.lit s8NoSustain2)

/-! ## 3. Schemes, cases and marks -/

/-- How evidence becomes belief. The core is one scheme; prototypes are others. `lit` and `ev` are
the leaves of `Derivation.opinionWith`; `verdict` reads an opinion given the claim's base rate. The
flags say what a scheme can state at all. -/
structure Scheme where
  name : String
  lit : Statement → Opinion
  ev : Evidence → Opinion
  /-- The statement opinion asked in a given year, when it depends on more than the evidence
  published by then (options N1 and N2). `lit` is this asked in 2026. -/
  litAt : Option (Nat → Statement → Opinion) := none
  rel : EvidenceKind → ℚ := std
  /-- Reliability of a refuting item, when it differs from `rel` (option M). -/
  relRef : Option (EvidenceKind → ℚ) := none
  verdict : ℚ → Opinion → Verdict := fun _ o => o.verdict
  retraction : Bool := false
  eco : Bool := false
  extraction : Bool := false
  baseRate : Bool := false

def core : Scheme := { name := "core", lit := Statement.opinion, ev := Evidence.opinion }

/-- `Rivalry.opinions` with other statement opinions. -/
def rivalsWith (lit : Statement → Opinion) (r : Rivalry) : List (Statement × Opinion) :=
  (Rivalry.others [] r.rivals).map fun (s, rest) => (s, rest.foldl (fun o t => o.fuse (lit t).against) (lit s))

namespace Scheme
variable (S : Scheme)
def refRel : EvidenceKind → ℚ := S.relRef.getD S.rel
def litY (y : Nat) : Statement → Opinion := match S.litAt with | some f => f y | none => S.lit
def der {c : Claim} (d : Derivation c) : Opinion := d.opinionWith S.lit S.ev
def atYear (s : Statement) (y : Nat) : Opinion := S.litY y (s.asOf y)
def derAt {c : Claim} (d : Derivation c) (y : Nat) : Opinion :=
  d.opinionWith (fun s => S.litY y (s.asOf y)) (fun e => if e.year ≤ y then S.ev e else .vacuous)
def rivals (r : Rivalry) : List (Statement × Opinion) := rivalsWith S.lit r
def rivalsAt (r : Rivalry) (y : Nat) : List (Statement × Opinion) := rivalsWith (S.litY y) (r.asOf y)
def v (o : Opinion) : Verdict := S.verdict (1 / 2) o
end Scheme

-- The scheme's rivalry agrees with the core's on the two rivalries used here.
#guard [BioLean.Examples.Chemiosmosis.coupling.asOf 1965, BioLean.Examples.Chemiosmosis.coupling.asOf 1974,
    chromR.asOf 1960, chromR.asOf 2013].all fun r =>
  ((core.rivals r).zip r.opinions).all fun (a, b) => a.2.belief == b.2.belief && a.2.disbelief == b.2.disbelief

/-- What a correct system should conclude: a verdict, or only "not established". -/
inductive Expect
  | is (v : Verdict)
  | notEst

/-- One observed part of a case: an opinion read against what is due (with the claim's base rate),
a yes/no property, or nothing because the case cannot be stated. -/
inductive Outcome
  | op (o : Opinion) (e : Expect) (a : ℚ := 1 / 2)
  | flag (ok : Bool) (what : String)
  | cannot

inductive Mark
  | pass | fail | silent | inexpressible
  deriving DecidableEq, Repr

def Mark.ch : Mark → Char | .pass => 'P' | .fail => 'F' | .silent => 'S' | .inexpressible => 'I'
def Mark.name : Mark → String
  | .pass => "PASS" | .fail => "FAIL" | .silent => "SILENT" | .inexpressible => "INEXPRESSIBLE"
def Mark.rank : Mark → Nat | .pass => 0 | .silent => 1 | .fail => 2 | .inexpressible => 3

structure Case where
  id : String
  run : Scheme → List Outcome

def markOf (S : Scheme) : Outcome → Mark
  | .cannot => .inexpressible
  | .flag b _ => if b then .pass else .fail
  | .op o e a =>
    let v := S.verdict a o
    match e with
    | .notEst => if v = .established then .fail else .pass
    | .is w => if v = w then .pass else if v = .unsupported then .silent else .fail

def showOutcome (S : Scheme) : Outcome → String
  | .op o _ a => s!"b={o.belief.toDecimal} d={o.disbelief.toDecimal} {vn (S.verdict a o)}"
  | .flag b w => s!"{w}: {if b then "yes" else "no"}"
  | .cannot => "cannot be stated"

def within2 (a b : ℚ) : Bool := a ≤ 2 * b && b ≤ 2 * a
def sgn (o : Opinion) : String := if o.belief > o.disbelief then "+" else if o.belief < o.disbelief then "-" else "0"
def extraordinary : ℚ := 1 / 100

/-! ### The cases. `K` regression, `W` weak against strong, `D` dependence, `R` retraction and
replication, `CAL` calibration, `A` animal against human, `T` textbook, `C` curated annotations,
`O` old against new, `B` base rates, `L` extraction. -/
section cases
open BioLean.Lib BioLean.ContextExamples BioLean.TranscriptionExample BioLean.Examples.Chemiosmosis

def pair (l : List (Statement × Opinion)) (e₁ e₂ : Expect) : List Outcome :=
  match l with
  | [(_, a), (_, b)] => [.op a e₁, .op b e₂]
  | _ => [.cannot]

def case_K01 : Case := ⟨"K01", fun S => [.op (S.der semaglutide_reduces_feeding) (.is .established)]⟩
def case_K02 : Case := ⟨"K02", fun S => [.op (S.der semaglutide_reduces_feeding_mechanistic) (.is .established)]⟩
def case_K03 : Case := ⟨"K03", fun S => [.op (S.der sitagliptin_reduces_feeding) (.is .refuted)]⟩
def case_K04 : Case := ⟨"K04", fun S => [.op (S.der nausea_mediates) (.is .contested)]⟩
def case_K05 : Case := ⟨"K05", fun S => pair (S.rivalsAt coupling 1974) (.is .established) (.is .refuted)⟩
def case_W01 : Case := ⟨"W01", fun S => [.op (S.atYear hrt 1997) .notEst]⟩
def case_W02 : Case := ⟨"W02", fun S => [.op (S.atYear hrt 2003) (.is .refuted)]⟩
def case_W03 : Case := ⟨"W03", fun S => [.op (S.atYear vite 2008) (.is .refuted)]⟩
def case_W04 : Case := ⟨"W04", fun S => [.op (S.atYear mg 2002) (.is .refuted)]⟩
def case_W05 : Case := ⟨"W05", fun S => [.op (S.lit nxyHuman) (.is .refuted)]⟩
def case_W06 : Case := ⟨"W06", fun S => [.op (S.lit (obsVsRct 27)) .notEst]⟩
def case_W07 : Case := ⟨"W07", fun S => [.op (S.lit (textMinedN 10)) .notEst, .op (S.lit (textMinedN 1000)) .notEst]⟩
def case_W08 : Case := ⟨"W08", fun S => [.op (S.lit betacar) (.is .refuted)]⟩
def case_W09 : Case := ⟨"W09", fun S => [.op (S.atYear smoking 1958) (.is .established)]⟩
def case_D01 : Case := ⟨"D01", fun S => [.op (S.lit anversa) (.is .refuted)]⟩
def case_D02 : Case := ⟨"D02", fun S => [.op (S.lit nhsOnly) .notEst]⟩
def case_D03 : Case := ⟨"D03", fun S => [.op (S.lit s7meta) (.is .established)]⟩
def case_D04 : Case := ⟨"D04", fun S => [.op (S.lit mgDouble) .notEst]⟩
def case_D05 : Case := ⟨"D05", fun S => [.op (S.lit mmrS) (.is .refuted)]⟩
def case_D06 : Case := ⟨"D06", fun S => [.op (S.atYear mmrS 2002) (.is .refuted)]⟩
def case_D07 : Case := ⟨"D07", fun S => [.op (S.lit S1) (.is .established)]⟩
def case_D08 : Case := ⟨"D08", fun S => [.op (S.der chrom46x3) (.is .established)]⟩
def sameOp (o p : Opinion) : Bool := o.belief == p.belief && o.disbelief == p.disbelief
def case_D09 : Case := ⟨"D09", fun S =>
  [.flag (sameOp (S.lit samePmidSR) (S.lit samePmidRS)) "same opinion in either order"]⟩
/-- Counted once: two copies of one paper give the opinion of one copy, under any scheme. -/
def case_D10 : Case := ⟨"D10", fun S =>
  [.flag (sameOp (S.lit samePmidSS) (S.lit { samePmidSS with evidence := samePmidSS.evidence.take 1 })) "two copies weigh as one"]⟩
def case_R01 : Case := ⟨"R01", fun S => [.op (S.lit stap) (.is .refuted) extraordinary]⟩
def case_R02 : Case := ⟨"R02", fun S => [.op (S.lit gfaj) (.is .refuted) extraordinary]⟩
def case_R03 : Case := ⟨"R03", fun S => if S.retraction then [.op (S.atYear scnt 2007) (.is .unsupported)] else [.cannot]⟩
def case_R04 : Case := ⟨"R04", fun S => [.op (S.lit scntValid) (.is .established)]⟩
def case_R05 : Case := ⟨"R05", fun S => [.op (S.lit resv) (.is .contested)]⟩
/-- Errington 2021: 39 of 97 original positive effects replicated, and 12 of 15 original null
effects. Pass if inVitro's pseudo-count for each polarity is within a factor 2 of the measured
rate's: supporting items against the positive rate, refuting items against the null rate. -/
def case_CAL01 : Case := ⟨"CAL01", fun S =>
  [.flag (within2 (pc (S.rel .inVitro)) (pc (39 / 97))) "inVitro supporting within x2 of 39/97",
   .flag (within2 (pc (S.refRel .inVitro)) (pc (12 / 15))) "inVitro refuting within x2 of 12/15"]⟩
/-- Ioannidis 2005: 30 of 39 highly cited RCTs and 1 of 6 non-randomised studies neither contradicted
nor initially stronger. -/
def case_CAL02 : Case := ⟨"CAL02", fun S =>
  [.flag (within2 (pc (S.rel .rct)) (pc (30 / 39))) "rct within x2 of 30/39",
   .flag (within2 (pc (S.rel .observational)) (pc (1 / 6))) "observational within x2 of 1/6"]⟩
/-- Bachman 2023, Table 2, Reach, "Complete" rows: statements correct (curated) by mention count.
1 mention 57 (119); 2 to 5 mentions 26+25+16+26 (41+36+25+36) = 93 (138); 6 to 10 mentions
24+26+31+18+20 (28+35+50+22+24) = 119 (159). -/
def reachBands : List (List Nat × ℚ × String) :=
  [([1], 57 / 119, "57/119"), ([2, 3, 4, 5], 93 / 138, "93/138"), ([6, 7, 8, 9, 10], 119 / 159, "119/159")]
/-- Mean belief of `k` text-mined items over a band of `k`. -/
def bandMean (S : Scheme) (ks : List Nat) : ℚ :=
  (ks.map fun k => (S.lit (textMinedN k)).belief).sum / ks.length
/-- Text-mined belief must also fold in study strength, so it should not exceed measured reader
precision. Pass if, in each band, the mean belief is at most the measured precision plus 0.05
(about one standard error at these sample sizes). -/
def case_CAL03 : Case := ⟨"CAL03", fun S => reachBands.map fun (ks, m, ms) =>
  .flag (bandMean S ks ≤ m + 1 / 20) s!"mentions {ks.head!}-{ks.getLast!}: {(bandMean S ks).toDecimal} vs {ms}"⟩
def case_A01 : Case := ⟨"A01", fun S => [.op (S.der s2_transport) .notEst]⟩
def case_A02 : Case := ⟨"A02", fun S => [.op (S.der (Derivation.lit N5)) .notEst]⟩
def case_A03 : Case := ⟨"A03", fun S => [.op (S.der nxyAll) (.is .refuted)]⟩
/-- No statement can target a weight: `crossSpecies` is 3/10 for every claim. -/
def case_A04 : Case := ⟨"A04", fun _ => [.cannot]⟩
def case_T01 : Case := ⟨"T01", fun S => [.op (S.atYear neuro 2013) (.is .established)]⟩
def case_T02 : Case := ⟨"T02", fun S => [.op (S.lit neuroMar2018) (.is .contested)]⟩
def case_T03 : Case := ⟨"T03", fun S => [.op (S.lit neuro) (.is .contested)]⟩
def case_T04 : Case := ⟨"T04", fun S => [.op (S.lit cellsDNA) .notEst]⟩
def case_C01 : Case := ⟨"C01", fun S => [.op (S.lit giardiaMito) .notEst]⟩
def case_C02 : Case := ⟨"C02", fun S => [.op (S.lit giardiaMitoTovar) (.is .refuted)]⟩
def case_C03 : Case := ⟨"C03", fun S =>
  [.op (S.lit (inst paramecium)) (.is .established), .op (S.der (gen cellularOrganisms .bracketing eight)) (.is .established)]⟩
def case_C04 : Case := ⟨"C04", fun S =>
  if S.eco then [.flag ((S.lit ieaS).belief != (S.lit expS).belief) "IEA and EXP weigh differently"] else [.cannot]⟩
def case_O01 : Case := ⟨"O01", fun S => pair (S.rivalsAt chromR 1960) (.is .established) (.is .refuted)⟩
def case_O02 : Case := ⟨"O02", fun S => pair (S.rivalsAt chromR 2013) (.is .established) (.is .refuted)⟩
def case_O03 : Case := ⟨"O03", fun S => [.op (S.atYear oneClaim 1974) (.is .established)]⟩
/-- Pass if some body of evidence establishes a routine claim but not an extraordinary one. -/
def case_B01 : Case := ⟨"B01", fun S =>
  if S.baseRate then [.flag (S.verdict (1 / 2) (S.lit scntValid) != S.verdict extraordinary (S.lit scntValid))
    "base rate changes a verdict"] else [.cannot]⟩
def case_B02 : Case := ⟨"B02", fun S => [.op (S.atYear gfaj 2011) .notEst extraordinary]⟩
def case_L01 : Case := ⟨"L01", fun S => if S.extraction then [.flag true "study and extraction are two factors"] else [.cannot]⟩
def case_L02 : Case := ⟨"L02", fun S =>
  [.flag (S.v (S.der sitaNoSustain2) = S.v (S.der sitagliptin_reduces_feeding)) "verdict unchanged without SUSTAIN 2"]⟩

def cases : List Case := [case_K01, case_K02, case_K03, case_K04, case_K05,
  case_W01, case_W02, case_W03, case_W04, case_W05, case_W06, case_W07, case_W08, case_W09,
  case_D01, case_D02, case_D03, case_D04, case_D05, case_D06, case_D07, case_D08, case_D09, case_D10,
  case_R01, case_R02, case_R03, case_R04, case_R05, case_CAL01, case_CAL02, case_CAL03,
  case_A01, case_A02, case_A03, case_A04, case_T01, case_T02, case_T03, case_T04,
  case_C01, case_C02, case_C03, case_C04, case_O01, case_O02, case_O03, case_B01, case_B02, case_L01, case_L02]

/-- The statements the cases rest on (for the prototype mirror check). -/
def caseStatements : List Statement :=
  [hrt.asOf 1997, hrt.asOf 2003, vite.asOf 2008, mg.asOf 2002, nxyHuman, nxyRat, obsVsRct 27, textMinedN 10,
   betacar, smoking.asOf 1958, anversa, nhsOnly, s7meta, mgDouble, mmrS, mmrS.asOf 2002, S1, S2, S3, S4, S5, S6, S7, S8, S9a, S9b,
   S9c, S9d, samePmidSR, samePmidRS, samePmidSS, stap, gfaj, scnt.asOf 2007, scntValid, resv, N4, N5,
   neuro.asOf 2013, neuroMar2018, neuro, cellsDNA, giardiaMito, giardiaMitoTovar, inst paramecium, ieaS, expS,
   chrom46.asOf 1960, chrom48, chemiosmotic.asOf 1974, chemicalIntermediate.asOf 1974, oneClaim.asOf 1974,
   s8NoSustain2]
end cases

#guard cases.length == 51

/-- One case under one scheme, computed once. -/
structure Result where
  id : String
  mark : Mark
  obs : String

def Case.result (S : Scheme) (c : Case) : Result :=
  let os := c.run S
  ⟨c.id, os.foldl (fun m o => let n := markOf S o; if n.rank > m.rank then n else m) .pass,
    " ; ".intercalate (os.map (showOutcome S))⟩
def results (S : Scheme) : List Result := cases.map (·.result S)
def marksOf (r : List Result) : String := String.ofList (r.map (·.mark.ch))
def tallyOf (r : List Result) : Nat × Nat × Nat × Nat :=
  let ms := r.map (·.mark)
  (ms.count .pass, ms.count .fail, ms.count .silent, ms.count .inexpressible)
def changesOf (base r : List Result) : List String :=
  (base.zip r).filterMap fun (a, b) => if a.mark = b.mark then none else some s!"{a.id} {a.mark.name}->{b.mark.name}"
def marks (S : Scheme) : String := marksOf (results S)

/-! ### The M6 regression checks: Ozempic and Chemiosmosis under a scheme -/
section examples
open BioLean.Lib BioLean.Examples.Chemiosmosis

def exOpinions (S : Scheme) : List (String × Opinion) :=
  [("oz.main", S.der semaglutide_reduces_feeding), ("oz.mechanistic", S.der semaglutide_reduces_feeding_mechanistic),
   ("oz.sitagliptin", S.der sitagliptin_reduces_feeding), ("oz.nausea", S.der nausea_mediates),
   ("oz.hypothalamus", S.der acts_via_hypothalamus), ("oz.areaPostrema", S.der acts_via_areaPostrema)] ++
  ((S.rivalsAt coupling 1965).map fun p => ("ch.1965 " ++ p.1.id, p.2)) ++
  ((S.rivalsAt coupling 1974).map fun p => ("ch.1974 " ++ p.1.id, p.2)) ++
  ((S.rivalsAt realCoupling 1974).map fun p => ("ch.real1974 " ++ p.1.id, p.2))

/-- Verdicts, signs and the four threshold theorems of the two examples. -/
def exChecks (S : Scheme) : List (String × String) :=
  let os := exOpinions S
  let yrs := 0 :: oneClaim.evidence.map (·.year)
  os.map (fun (n, o) => (n, vn (S.v o))) ++ os.map (fun (n, o) => (n ++ " sign", sgn o)) ++
  [("thm oz.main >= 0.95", toString (decide (95 / 100 ≤ (S.der semaglutide_reduces_feeding).belief))),
   ("thm oz.mech >= 0.8", toString (decide (8 / 10 ≤ (S.der semaglutide_reduces_feeding_mechanistic).belief))),
   ("thm ch.oneClaim never established", toString (yrs.all fun y => S.v (S.atYear oneClaim y) != .established)),
   ("thm ch.1961 belief 0", toString (decide ((S.derAt (Derivation.lit chemiosmotic) 1961).belief = 0)))]
end examples

def exBase : List (String × String) := exChecks core
def exDiff (S : Scheme) : List String :=
  (exBase.zip (exChecks S)).filterMap fun ((n, a), (_, b)) => if a = b then none else some s!"{n}: {a} -> {b}"
/-- A flipped example check, by type: a verdict, a sign (b against d), or a threshold theorem. -/
def isSign (x : String) : Bool := (x.splitOn " sign").length > 1
def isThm (x : String) : Bool := x.startsWith "thm "
def isOz (x : String) : Bool := (x.splitOn "oz.").length > 1
def ozSigns (d : List String) : List String := d.filter fun x => isSign x && isOz x
def ozSignFlips (S : Scheme) : List String := ozSigns (exDiff S)

/-! ## 4. Sensitivity: each pseudo-count times 2 and times 1/2

`model f` multiplies kind `k`'s pseudo-count by `f k` and maps it back to a reliability. Factor 1
gives the standard table exactly (`#guard` below). -/

def relOf (n : ℚ) : ℚ := max n 0 / (max n 0 + 2)
theorem relOf_nonneg (n : ℚ) : 0 ≤ relOf n :=
  div_nonneg (le_max_right _ _) (by have := le_max_right n 0; linarith)
theorem relOf_lt_one (n : ℚ) : relOf n < 1 := by
  have h := le_max_right n 0
  unfold relOf; rw [div_lt_one (by linarith)]; linarith

set_option warn.classDefReducibility false in
/-- The standard table with each kind's pseudo-count scaled by `f`. -/
def model (f : EvidenceKind → ℚ) : EvidenceModel where
  reliability j := if f j = 1 then std j else relOf (f j * pc (std j))
  nonneg j := by
    split
    · exact @EvidenceModel.nonneg EvidenceModel.standard j
    · exact relOf_nonneg _
  lt_one j := by
    split
    · exact @EvidenceModel.lt_one EvidenceModel.standard j
    · exact relOf_lt_one _

/-- The core with another table. -/
def coreWith (name : String) (m : EvidenceModel) : Scheme :=
  { name, lit := @Statement.opinion m, ev := @Evidence.opinion m, rel := m.reliability }

def one (k : EvidenceKind) (f : ℚ) : EvidenceKind → ℚ := fun j => if j = k then f else 1

#guard kinds.all fun k => @EvidenceModel.reliability (model fun _ => 1) k == std k
#guard kinds.all fun k => relOf (pc (std k)) == std k

def sensRuns : List (EvidenceKind × ℚ) := kinds.flatMap fun k => [(k, 2), (k, 1 / 2)]
def sensScheme (k : EvidenceKind) (f : ℚ) : Scheme := coreWith s!"{kname k} x{f}" (model (one k f))

/-- Flips in the example checks for each run. -/
def sensExample : List (String × List String) := sensRuns.map fun (k, f) => ((sensScheme k f).name, exDiff (sensScheme k f))
/-- Cases of the stress set whose mark changes in each run. -/
def sensStress : List (String × List String) :=
  let base := results core
  sensRuns.map fun (k, f) => ((sensScheme k f).name, changesOf base (results (sensScheme k f)))

def grid : List ℚ := [1/16, 1/8, 1/4, 1/3, 1/2, 2/3, 3/4, 4/5, 9/10, 1, 11/10, 5/4, 3/2, 2, 3, 4, 8, 16]
/-- For each kind: the factors nearest 1 at which some example check first flips, and every factor
on the grid at which an Ozempic sign flips. -/
def margins : List (String × Option ℚ × Option ℚ × List ℚ) := kinds.map fun k =>
  let ds := grid.map fun f => (f, exDiff (sensScheme k f))
  ((kname k), ((ds.filter fun (f, d) => f < 1 && !d.isEmpty).map (·.1)).getLast?,
    ((ds.filter fun (f, d) => f > 1 && !d.isEmpty).map (·.1)).head?,
    (ds.filter fun (_, d) => !(ozSigns d).isEmpty).map (·.1))

set_option warn.classDefReducibility false in
/-- Calibrated tables (option I): replace a kind's reliability outright. -/
def modelR (r : EvidenceKind → Option ℚ) : EvidenceModel :=
  model fun k => match r k with
    | some x => if pc (std k) = 0 then 1 else pc x / pc (std k)
    | none => 1
def calIoannidis : EvidenceKind → Option ℚ
  | .rct => some (30 / 39) | .observational => some (1 / 6) | _ => none
def calErrington : EvidenceKind → Option ℚ
  | .inVitro => some (39 / 97) | .mechanistic => some (39 / 97) | _ => none
def calBoth : EvidenceKind → Option ℚ := fun k => (calIoannidis k).orElse fun _ => calErrington k
def reviewsZero : EvidenceKind → Option ℚ
  | .review => some 0 | _ => none

def calIo := coreWith "I Ioannidis table" (modelR calIoannidis)
def calEr := coreWith "I Errington table" (modelR calErrington)
def calBo := coreWith "I both tables" (modelR calBoth)
def calRev0 := coreWith "reviews weigh 0" (modelR reviewsZero)

end BioLean.Stress.Weights

/-! ## 5. Prototypes (outside the core)

Each option of the program as a scheme. The side tables are data an importer would supply; none of
them is a field of `Evidence` today, which is the point: an option that needs a table keyed by PMID
can live outside the core, an option that needs a field cannot. -/

namespace BioLean.Proto.Weights
open BioLean BioLean.Stress.Weights Derivation

/-! ### Side tables (data, checked 2026-10-31) -/

/-- Europe PMC publication type "Retracted Publication" (15 papers in the set). -/
def retracted : List Nat := [9500320, 14963337, 15905366, 18202313, 20522802, 21088285, 21127214, 21403094,
  21546606, 22275487, 22851539, 22955965, 23281411, 24476887, 24476891]

/-- Primaries a meta-analysis pools. From Europe PMC reference lists (UNVERIFIED as inclusion
lists), except Gao 2022, whose eight included studies were read in the full text. -/
def pools : List (Nat × List Nat) :=
  [(1838289, [6399346, 2868254, 2427458, 3548627, 2589170, 2195862]), (36188627, [30122305]), (24814559, [12421889]),
   (1826173, [4047106])]

/-- Meta-analyses of observational studies, and of animal studies (from their abstracts). -/
def metaOfObs : List Nat := [1826173, 24814559]
def metaOfAnimal : List Nat := [18635842]

/-- Curated source key: the same lab, cohort or trial (by hand, from titles and author lists). -/
def curatedGroup : List (Nat × String) :=
  ([14505575, 18202313, 20522802, 21088285, 21403094, 21546606, 22275487, 22851539, 22955965, 23281411].map (·, "lab:Anversa")) ++
  ([4047106, 1870648, 8672166, 11119394].map (·, "cohort:NHS")) ++
  ([12117397, 12904517].map (·, "trial:WHI")) ++ ([10639540, 15769967].map (·, "trial:HOPE")) ++
  ([24476887, 24476891].map (·, "lab:Obokata")) ++ ([14963337, 15905366].map (·, "lab:Hwang")) ++
  ([12939617, 23471411].map (·, "lab:Sinclair")) ++
  ([14772469, 12997741].map (·, "study:Doll-Hill case-control")) ++
  ([13160495, 13364389].map (·, "cohort:British Doctors")) ++ ([13174399, 12308037].map (·, "cohort:ACS Hammond-Horn"))

/-- Automatic source key: shared first or last author, case-folded (`scripts/stress/weights_groups.py`,
`data/stress/10a/groups_auto.tsv`, regenerated in review from all cited PMIDs). -/
def autoGroup : List (Nat × String) := [(1826173, "auto:1826173"), (1870648, "auto:1826173"), (4047106, "auto:1826173"), (8479463, "auto:1826173"), (8479464, "auto:1826173"), (8672166, "auto:1826173"), (11119394, "auto:1826173"), (1838289, "auto:1838289"), (7010181, "auto:1838289"), (9654637, "auto:9654637"), (12997741, "auto:9654637"), (13160495, "auto:9654637"), (13364389, "auto:9654637"), (14772469, "auto:9654637"), (12308037, "auto:12308037"), (13174399, "auto:12308037"), (12421889, "auto:12421889"), (30831578, "auto:12421889"), (12939617, "auto:12939617"), (23471411, "auto:12939617"), (29570999, "auto:12939617"), (13771349, "auto:13771349"), (16742541, "auto:13771349"), (14505575, "auto:14505575"), (18202313, "auto:14505575"), (20522802, "auto:14505575"), (21088285, "auto:14505575"), (21403094, "auto:14505575"), (21546606, "auto:14505575"), (22851539, "auto:14505575"), (22955965, "auto:14505575"), (23281411, "auto:14505575"), (14514604, "auto:14514604"), (29617641, "auto:14514604"), (14759551, "auto:14759551"), (16385384, "auto:14759551"), (20194711, "auto:14759551"), (30743739, "auto:14759551"), (14963337, "auto:14963337"), (15905366, "auto:14963337"), (16014596, "auto:16014596"), (16060722, "auto:16014596"), (17192459, "auto:17192459"), (26308095, "auto:17192459"), (31031702, "auto:17192459"), (18436948, "auto:18436948"), (21208779, "auto:18436948"), (21802903, "auto:18436948"), (21622706, "auto:21622706"), (22773140, "auto:21622706"), (22227019, "auto:22227019"), (26522737, "auto:22227019"), (32132220, "auto:22227019"), (37729419, "auto:22227019"), (23746839, "auto:23746839"), (29681514, "auto:23746839"), (24476887, "auto:24476887"), (24476891, "auto:24476887"), (24990753, "auto:24476887"), (29175850, "auto:29175850"), (36938926, "auto:29175850"), (29300386, "auto:29300386"), (32720330, "auto:29300386"), (29317623, "auto:29317623"), (34168616, "auto:29317623"), (30122305, "auto:30122305"), (33567185, "auto:30122305"), (38935778, "auto:38935778"), (40367985, "auto:38935778")]

/-- Participants, from the abstracts (Europe PMC); the two Hammond & Horn cohorts (W09) have no
abstract, so their sizes are from the titles. Unknown sizes weigh as today. -/
def sizes : List (Nat × Nat) :=
  [(4047106, 32317), (1870648, 48470), (8672166, 59337), (11119394, 70533), (9718051, 2763), (12117397, 16608),
   (12904517, 16608), (8479463, 87245), (8479464, 39910), (8622332, 2002), (10639540, 9541), (15769967, 7030),
   (15998891, 39876), (18997197, 14641), (1838289, 1301), (1351547, 2316), (7661937, 58050), (12401244, 6213),
   (16467546, 1722), (17687131, 3306), (9500320, 12), (12421889, 537303), (24814559, 1256407), (30831578, 657461),
   (8127329, 29133), (8602180, 18314), (36188627, 4567), (13174399, 187766), (12308037, 187783)]

/-- Option N1: an item superseded by later evidence of the same kind of measurement, from the year
`since`. Matched by PMID, year and the start of the note (non-paper items have PMID 0). A curated
judgement, so the table is short on purpose and holds no live dispute. -/
structure Supersession where
  pmid : Nat
  year : Nat
  note : String
  since : Nat
  by_ : String

def supersessions : List Supersession :=
  [⟨0, 1923, "Painter 1923", 1956,
     "Tjio & Levan 1956 (doi:10.1111/j.1601-5223.1956.tb03010.x) and Ford & Hamerton 1956 (PMID:13378517) count 46"⟩,
   ⟨0, 1965, "ILLUSTRATIVE (case-study script): reports of an isolated high-energy intermediate", 1974,
     "ILLUSTRATIVE judgement: Racker & Stoeckenius 1974 (PMID:4272126) make ATP with no shared chemical intermediate"⟩]

def supersededAt (y : Nat) (e : Evidence) : Bool :=
  supersessions.any fun x => x.pmid == e.pmid && x.year == e.year && x.note.isPrefixOf e.note && x.since ≤ y

/-! ### The prototype pipeline

Items become pseudo-counts; items with one source key are averaged (Jøsang's averaging fusion is the
mean of the evidence vectors); groups are summed within a kind; each kind is discounted by its
ceiling; kinds are fused cumulatively. With every option off this is exactly `Statement.opinion`
(mirror check below, and `statement_opinion_eq`). -/

/-- `x ^ n` by repeated multiplication. -/
def pw (x : ℚ) : Nat → ℚ | 0 => 1 | n + 1 => x * pw x n

structure Config where
  dropRetracted : Bool := false
  dropPooled : Bool := false
  key : Option (Evidence → String) := none
  remap : Bool := false
  ceiling : Option (EvidenceKind → ℚ) := none
  size : Bool := false
  rel : EvidenceKind → ℚ := std
  /-- Reliability of refuting items, when it differs from `rel` (option M). -/
  relRef : Option (EvidenceKind → ℚ) := none
  /-- Option N1: drop items superseded by the year asked. -/
  supersede : Bool := false
  /-- Option N2: each year of age multiplies an item's pseudo-count by this factor. -/
  ageing : Option ℚ := none
  /-- The year the question is asked (N1 and N2). -/
  asked : Nat := 2026

/-- Non-paper sources: a GO annotation row's key is its pipeline (GO_REF); any other item with
PMID 0 is keyed by kind, year and polarity, so three sentences of one textbook are one source. -/
def lookupKey (t : List (Nat × String)) (e : Evidence) : String :=
  if e.pmid = 0 then
    match (e.note.splitOn " ").find? (·.startsWith "GO_REF:") with
    | some g => s!"pipeline:{g}"
    | none => s!"src0:{kname e.kind}:{e.year}:{if e.polarity = .supports then "S" else "R"}"
  else (t.lookup e.pmid).getD s!"pmid:{e.pmid}"
def curatedKey : Evidence → String := lookupKey curatedGroup
def autoKey : Evidence → String := lookupKey autoGroup
/-- Reviews on one statement restate the same primaries: one source. -/
def reviewKey (e : Evidence) : String := if e.kind = .review then "reviews" else curatedKey e

def has (s pat : String) : Bool := (s.splitOn pat).length > 1
/-- Option B1, at import: a GO evidence code or a meta-analysis's pooled design picks an existing kind. -/
def remapKind (e : Evidence) : EvidenceKind :=
  if e.kind = .curatedDb && (has e.note "IBA" || has e.note "ISS" || has e.note "ISO") then .crossSpecies
  else if e.kind = .curatedDb && has e.note "IEA" then .textMined
  else if e.kind = .metaAnalysis && metaOfObs.contains e.pmid then .observational
  else if e.kind = .metaAnalysis && metaOfAnimal.contains e.pmid then .mechanistic
  else e.kind

def refSize : EvidenceKind → Option ℚ
  | .rct => some 1000 | .observational => some 10000 | .metaAnalysis => some 10000 | _ => none
/-- Option K: pseudo-count times participants over a reference size, clamped to [1/8, 8]. -/
def sizeFactor (k : EvidenceKind) (p : Nat) : ℚ :=
  match sizes.lookup p, refSize k with
  | some n, some r => max (1 / 8) (min 8 ((n : ℚ) / r))
  | _, _ => 1
/-- Option G: a ceiling per kind, `1 - e_syst`, for errors that do not average out. INDRA's
published defaults (`default_belief_probs.json`, read 2026-10-31): reading systems (reach, sparser,
medscan, trips) `e_syst = 0.05`; curated databases (signor, biogrid, hprd) `e_syst = 0.01`. No
source gives a ceiling for any other kind, so they stay at 1. -/
def ceilingIndra : EvidenceKind → ℚ
  | .textMined => 19 / 20 | .curatedDb => 99 / 100 | _ => 1
/-- Guessed ceilings (no source), kept to show what a ceiling on observational studies would do. -/
def ceilingGuess : EvidenceKind → ℚ
  | .observational => 3 / 5 | .textMined => 4 / 5 | _ => 1
/-- Option N2: a half-life of about 10 years (0.933 ^ 10 = 0.4998). Definitions and ontology
axioms do not age. -/
def ageTen : ℚ := 933 / 1000
def ageFactor (c : Config) (e : Evidence) : ℚ :=
  match c.ageing with
  | some l => if e.kind = .definitional ∨ e.kind = .ontologyAxiom then 1 else pw l (c.asked - e.year)
  | none => 1

def disc (o : Opinion) (w : ℚ) : Opinion :=
  o.discount (max 0 (min 1 w)) (le_max_left _ _) (max_le zero_le_one (min_le_left _ _))

def prep (c : Config) (s : Statement) : List Evidence :=
  let xs := s.distinctEvidence
  let xs := if c.dropRetracted then xs.filter (fun e => !retracted.contains e.pmid) else xs
  let xs := if c.supersede then xs.filter (fun e => !supersededAt c.asked e) else xs
  if c.dropPooled then xs.filter (fun e => !xs.any fun m => ((pools.lookup m.pmid).getD []).contains e.pmid) else xs

def itemCounts (c : Config) (e : Evidence) : EvidenceKind × ℚ × ℚ :=
  let k := if c.remap then remapKind e else e.kind
  let r := if e.polarity = .supports then c.rel k else (c.relRef.getD c.rel) k
  let n := pc r * (if c.size then sizeFactor k e.pmid else 1) * ageFactor c e
  (k, if e.polarity = .supports then (n, 0) else (0, n))

def litOf (c : Config) (s : Statement) : Opinion :=
  let xs := (prep c s).zipIdx.map fun (e, i) => ((match c.key with | some f => f e | none => s!"#{i}"), itemCounts c e)
  let keys := (xs.map (·.1)).eraseDups
  let groups : List (EvidenceKind × ℚ × ℚ) := keys.filterMap fun key =>
    match xs.filter (·.1 == key) with
    | [] => none
    | g@((_, k, _) :: _) =>
      let len : ℚ := g.length
      some (k, (g.map (·.2.2.1)).sum / len, (g.map (·.2.2.2)).sum / len)
  let ks := (groups.map (·.1)).eraseDups
  let perKind := ks.map fun k =>
    let gs := groups.filter (·.1 == k)
    disc (ofCounts (gs.map (·.2.1)).sum (gs.map (·.2.2)).sum) ((c.ceiling.getD fun _ => 1) k)
  perKind.foldl Opinion.fuse .vacuous

/-- `dated := false` asks every question with the 2026 tables, as an importer that drops items
before `Statement.asOf` would: what is superseded or retracted now is gone in every year. -/
def mkScheme (name : String) (c : Config) (retraction eco extraction : Bool := false) (dated : Bool := true) : Scheme :=
  { name, lit := litOf c, ev := Evidence.opinion, rel := c.rel, relRef := c.relRef, retraction, eco, extraction,
    litAt := if dated && (c.supersede || c.ageing.isSome) then some fun y s => litOf { c with asked := y } s else none }

-- Mirror checks: with every option off, and with ageing at factor 1, the pipeline is the core, on
-- every statement used here.
#guard caseStatements.all fun s => sameOp (litOf {} s) s.opinion
#guard caseStatements.all fun s => sameOp (litOf { ageing := some 1 } s) s.opinion

/-! ### GRADE-like cap (option C), base-rate verdict (option J), extraction factor (option F) -/

def isClinical (e : Evidence) : Bool :=
  (e.kind = .rct || e.kind = .observational || e.kind = .metaAnalysis) && !metaOfAnimal.contains e.pmid
/-- A mechanical stand-in for GRADE: clinical evidence starts high if randomised, low if not; one
study only drops a level (imprecision). High 1, moderate 3/4, low 1/2, very low 1/4. With no
clinical evidence the statement is not rated (weight 1). -/
def gradeWeight (s : Statement) : ℚ :=
  let clinical := s.distinctEvidence.filter isClinical
  if clinical.isEmpty then 1 else
  let randomised := clinical.any fun e => e.kind = .rct || (e.kind = .metaAnalysis && !metaOfObs.contains e.pmid)
  let level : Nat := (if randomised then 3 else 1) - (if clinical.length = 1 then 1 else 0)
  match level with | 3 => 1 | 2 => 3 / 4 | 1 => 1 / 2 | _ => 1 / 4
def isEffect : Claim → Bool | .effect .. => true | _ => false
/-- C1: cap the whole statement. C2: cap only the clinical part, and only on effect claims (GRADE
rates interventions and exposures, not cytology or mechanism). -/
def litC1 (s : Statement) : Opinion := disc s.opinion (gradeWeight s)
def litC2 (s : Statement) : Opinion :=
  if !isEffect s.claim then s.opinion else
  let cl : Statement := { s with evidence := s.distinctEvidence.filter isClinical }
  let rest : Statement := { s with evidence := s.distinctEvidence.filter (!isClinical ·) }
  (disc cl.opinion (gradeWeight s)).fuse rest.opinion

/-- Verdict on the projected probability `b + a u` (the dispute rule unchanged). -/
def verdictJ (a : ℚ) (o : Opinion) : Verdict :=
  if 1 / 4 ≤ o.belief ∧ 1 / 4 ≤ o.disbelief then .contested
  else if 4 / 5 ≤ o.prob a then .established
  else if 4 / 5 ≤ 1 - o.prob a then .refuted
  else .unsupported

/-- Option F on one item: an RCT result read by a text-miner of precision 3/5 (a placeholder). -/
def l01 : Opinion := disc ((ev 70000001 2020 .rct).opinion) (3 / 5)

/-! ### The schemes -/

def schB1 := mkScheme "B1 ECO and design remap" { remap := true } (eco := true)
def schC1 : Scheme := { name := "C1 GRADE-like cap, whole statement", lit := litC1, ev := Evidence.opinion }
def schC2 : Scheme := { name := "C2 GRADE-like cap, clinical part of effect claims", lit := litC2, ev := Evidence.opinion }
def schD := mkScheme "D curated groups" { key := some curatedKey }
def schDauto := mkScheme "D auto groups" { key := some autoKey }
def schDrev := mkScheme "D curated groups, reviews one source" { key := some reviewKey }
def schE := mkScheme "E meta replaces its primaries" { dropPooled := true }
def schF : Scheme := { core with name := "F extraction factor", extraction := true }
def schG := mkScheme "G ceilings, INDRA values" { ceiling := some ceilingIndra }
def schGguess := mkScheme "G ceilings, guessed values" { ceiling := some ceilingGuess }
def schH := mkScheme "H drop retracted" { dropRetracted := true } (retraction := true)
def schI := calIo
def schJ : Scheme := { core with name := "J base rate in verdict", verdict := verdictJ, baseRate := true }
def schK := mkScheme "K size" { size := true }

/-- Option M: weights by polarity. Errington 2021 measured preclinical replication: 39 of 97
original positive effects and 12 of 15 original null effects replicated. Applied to `inVitro` only;
no other kind has a measured rate by polarity. -/
def relMsup (k : EvidenceKind) : ℚ := if k = .inVitro then 39 / 97 else std k
def relMref (k : EvidenceKind) : ℚ := if k = .inVitro then 12 / 15 else std k
def schM := mkScheme "M polarity weights (inVitro)" { rel := relMsup, relRef := some relMref }
def schMH := mkScheme "M+H polarity weights, drop retracted" { rel := relMsup, relRef := some relMref, dropRetracted := true }
  (retraction := true)

def schN1 := mkScheme "N1 supersession table" { supersede := true }
def schN2 := mkScheme "N2 ageing, half-life 10 years" { ageing := some ageTen }

/-- The Ioannidis table as reliabilities (for the pipeline; transport items keep the core table). -/
def relIo (k : EvidenceKind) : ℚ := @EvidenceModel.reliability (modelR calIoannidis) k
def schHI := mkScheme "H1+I" { dropRetracted := true, rel := relIo } (retraction := true)
def schHIN := mkScheme "H1+I+N1" { dropRetracted := true, rel := relIo, supersede := true } (retraction := true)
/-- N1 as an import rule only (no core change): the table is applied once, so a superseded item is
gone in every year, as H1 does for retractions. The dated N1 above needs the year asked, which
`Statement.asOf` does not pass on: a core change. -/
def schN1imp := mkScheme "N1 at import (undated)" { supersede := true } (dated := false)
def schHINimp := mkScheme "H1+I+N1 at import (undated)" { dropRetracted := true, rel := relIo, supersede := true }
  (retraction := true) (dated := false)
def schHyg := mkScheme "H+E+D hygiene" { dropRetracted := true, dropPooled := true, key := some curatedKey } (retraction := true)
def cfgAll : Config :=
  { dropRetracted := true, dropPooled := true, key := some curatedKey, remap := true, ceiling := some ceilingIndra,
    size := true }
def schAll := mkScheme "H+E+D+B1+G+K+F" cfgAll (retraction := true) (eco := true) (extraction := true)
/-- Everything that needs no core change: import rules (H1, E1, D as one item per group, B1) and a
new `EvidenceModel` instance (I). `schOutN` adds the dated N1 (a core change); `schOutNimp` adds N1 as
an import rule, which breaks `contested_1965`. -/
def cfgOut : Config :=
  { dropRetracted := true, dropPooled := true, key := some curatedKey, remap := true, rel := relIo }
def schOut := mkScheme "outside core: H+E+D+B1+I" cfgOut (retraction := true) (eco := true)
def schOutN := mkScheme "outside core: H+E+D+B1+I+N1" { cfgOut with supersede := true } (retraction := true) (eco := true)
/-- The same with N1 as an import rule, so that every part is outside the core (review). -/
def schOutNimp := mkScheme "outside core: H+E+D+B1+I+N1 at import (undated)" { cfgOut with supersede := true }
  (retraction := true) (eco := true) (dated := false)
def schAllI := mkScheme "H+E+D+B1+G+K+F+I" { cfgAll with rel := relIo } (retraction := true) (eco := true) (extraction := true)
def schAllIN := mkScheme "H+E+D+B1+G+K+F+I+N1" { cfgAll with rel := relIo, supersede := true } (retraction := true) (eco := true)
  (extraction := true)

def schemes : List Scheme := [core, schB1, schC1, schC2, schD, schDauto, schDrev, schE, schF, schG, schGguess, schH,
  schI, schJ, schK, schM, schMH, schN1, schN2, schHI, schHIN, schHyg, schAll, schOut, schOutN, schAllI, schAllIN,
  calEr, calBo, calRev0, schN1imp, schHINimp, schOutNimp]

/-! ## 6. The M6 exit test, three wordings

* As ROADMAP words it: no Ozempic sign flip when any one kind's pseudo-count is doubled or halved,
  and every kind's pseudo-count documented. Both hold today (pinned in section 7), so this test
  checks nothing that M6 adds.
* Wording A: on this stress set, fewer FAILs than the core, and no Ozempic sign flip.
* Wording B: as A, and no case that PASSes under the core is lost.

Both are read off a scheme's mark string and its example flips, which section 7 pins. -/

/-- (wording A, wording B), from the core's marks, a scheme's marks and its example flips. -/
def exitAB (base m : String) (ex : List String) : Bool × Bool :=
  let fails (s : String) := s.toList.count 'F'
  let a := fails m < fails base && (ozSigns ex).isEmpty
  let lost := (base.toList.zip m.toList).any fun (x, y) => x == 'P' && y != 'P'
  (a, a && !lost)

/-! ## 7. Pins -/

/-- A case under a scheme: its observed value and mark. -/
def pin (S : Scheme) (c : Case) (obs : String) (m : Mark) : Bool :=
  let r := c.result S
  r.obs == obs && r.mark == m

/-- A scheme: its mark string, the observed values that differ from the core's, its example-check
flips, and the two exit-test wordings read from them. -/
def pinScheme (S : Scheme) (m : String) (diffs : List (String × String)) (ex : List String) (a b : Bool) : Bool :=
  let base := results core
  let r := results S
  let ex' := exDiff S
  marksOf r == m && ((base.zip r).filterMap fun (x, y) => if x.obs == y.obs then none else some (y.id, y.obs)) == diffs &&
    ex' == ex && exitAB (marksOf base) m ex' == (a, b)

/-! ### Laws and single facts (written by hand) -/

-- One textbook sentence, or one curated row, is exactly "established": S = 8, R = 0 (T04).
theorem textbook_alone_established : (st "one textbook item" synthClaim [ev 0 2013 .textbook]).opinion.verdict = .established := by
  decide +kernel
#guard S_ cellsDNA == 8 && R_ cellsDNA == 0
-- Two failed replications against one retracted paper: S = 2, R = 4, contested, and by
-- `not_refuted_of_lt_eight` no amount of support removal makes R = 4 refute (R02).
theorem gfaj_contested : gfaj.opinion.verdict = .contested := by decide +kernel
#guard S_ gfaj == 2 && R_ gfaj == 4
-- Three sentences of one book on three statements: no shared-axiom warning, because
-- `sharedAxioms` compares statement ids, not sources (D08).
#guard chrom46x3.sharedAxioms.isEmpty && chrom46x3.axioms.length == 3
-- `distinctEvidence` keeps the first item of a repeated PMID, so order decides (D09).
#guard (samePmidSR.opinion.belief, samePmidSR.opinion.disbelief) == (17 / 20, 0) &&
  (samePmidRS.opinion.belief, samePmidRS.opinion.disbelief) == (0, 17 / 20)
-- Averaging fusion is idempotent: 38 rows of one pipeline weigh as one row (option D).
#guard sameOp (litOf { key := some curatedKey } { giardiaMito with evidence := giardiaRows.take 38 }) (ofCounts 8 0)
-- Option F on one item: an RCT read by a text-miner of precision 3/5 (L01).
#guard sameOp l01 (Opinion.ofReliability (51 / 100) (by norm_num) (by norm_num) .supports)
-- N1: the supersession table drops Painter's 48 from 1956, not before.
#guard (chrom48.evidence.filter (supersededAt 1955)).isEmpty && (chrom48.evidence.filter (supersededAt 1956)).length == 1
-- M6 exit test, part 1, as ROADMAP words it: no Ozempic sign flip when any one kind's
-- pseudo-count is doubled or halved. Part 2 is `pseudoCounts` (section 1).
#guard sensRuns.all fun (k, f) => (ozSignFlips (sensScheme k f)).isEmpty

/-! ### Review pins (2026-10-31): numbers the doc states, and the review's checks -/
section review
open BioLean.Lib BioLean.Examples.Chemiosmosis

-- The fragile threshold theorems: the Ozempic mechanistic route is 1027/1275 (0.805); the
-- real-papers chemiosmosis rivalry sits at exactly 4/5.
#guard (core.der semaglutide_reduces_feeding_mechanistic).belief == 1027 / 1275
#guard (core.rivalsAt realCoupling 1974).map (·.2.belief) == [4 / 5, 0]
-- Margins (section 4.3): a 10 percent cut to inVitro breaks chemiosmosis 1974 only; the Ozempic
-- theorem breaks at review x9/10, mechanistic x4/5 and inVitro x4/5, not at mechanistic x9/10.
#guard exDiff (sensScheme .inVitro (9 / 10)) ==
  ["ch.1974 chemiosmotic: established -> unsupported", "ch.real1974 chemiosmotic: established -> unsupported"]
#guard exDiff (sensScheme .review (9 / 10)) == ["oz.mechanistic: established -> unsupported", "thm oz.mech >= 0.8: true -> false"]
#guard exDiff (sensScheme .mechanistic (4 / 5)) == ["oz.mechanistic: established -> unsupported", "thm oz.mech >= 0.8: true -> false"]
#guard (exDiff (sensScheme .mechanistic (9 / 10))).isEmpty
#guard (exDiff (sensScheme .inVitro (4 / 5))).contains "thm oz.mech >= 0.8: true -> false"
-- The first Ozempic sign flip: mechanistic x4 turns sitagliptin positive, b 0.493 against d 0.488.
#guard let o := (sensScheme .mechanistic 4).der sitagliptin_reduces_feeding;
  o.belief.toDecimal == "0.493" && o.disbelief.toDecimal == "0.488"
-- N2 on its own puts the chemiosmotic statement in 1974 at 0.779 (0.757 under the rivalry, K05).
#guard (schN2.atYear chemiosmotic 1974).belief.toDecimal == "0.779"

-- INDRA is not cumulative fusion with zero systematic error. INDRA's belief for n items of one
-- source is 1 - (e_syst + e_rand ^ n (1 - e_syst)) (Bachman 2023, Methods); with e_syst = 0 that is
-- noisy-OR. Two items of reliability 1/2: noisy-OR gives 3/4, cumulative fusion 2/3.
def indraBelief (eSyst eRand : ℚ) (n : Nat) : ℚ := 1 - (eSyst + pw eRand n * (1 - eSyst))
#guard indraBelief 0 (1 / 2) 2 == 3 / 4
#guard (st "two inVitro items" synthClaim [ev 90000001 2000 .inVitro, ev 90000002 2000 .inVitro]).opinion.belief == 2 / 3
-- The plateau is the same, the shape is not: INDRA's ceiling is 1 - e_syst, as option G uses.
#guard indraBelief (1 / 20) (1 / 2) 1000 < 19 / 20 && 19 / 20 - indraBelief (1 / 20) (1 / 2) 1000 < 1 / 10 ^ 100
-- INDRA's default Reach prior (e_syst 0.05, e_rand 0.3): one mention 0.665, ten mentions above 0.8.
-- Bachman 2023 measured 57/119 (0.48) at one mention and 119/159 (0.75) at 6 to 10 (CAL03), so
-- W07's "not established at 10" follows the measurement, not INDRA's default model.
#guard indraBelief (1 / 20) (3 / 10) 1 == 133 / 200 && indraBelief (1 / 20) (3 / 10) 10 > 4 / 5

-- W09 (review): smoking and lung cancer in 1958 rests on ten observational reports. The core has
-- S = 20 (established); the Ioannidis table (observational r = 1/6, n = 2/5) has S = 4, so it
-- needs 20 such reports to establish anything (8 / (2/5)).
#guard S_ (smoking.asOf 1958) == 20 && @S_ (modelR calIoannidis) (smoking.asOf 1958) == 4
#guard pc (1 / 6) == 2 / 5

-- N1 as an import rule rewrites history: the 1965 reports are gone in 1965 too, so the M2 theorem
-- `contested_1965` fails (both rivals unsupported, signs no longer 0). The dated N1 keeps it.
#guard (schN1imp.rivalsAt coupling 1965).map (fun p => schN1imp.v p.2) == [.unsupported, .unsupported]
#guard (schN1.rivalsAt coupling 1965).map (fun p => schN1.v p.2) == [.contested, .contested]
-- E1 as an import rule rewrites history too: Taylor 2014 pools Madsen 2002, so D06 asked in 2002
-- loses Madsen. Outside the core (cfgOut) the mark does not move (unsupported either way); with
-- size (cfgAll, a core change) D06 drops from refuted (0.900) to unsupported.
def mmrImportE : Statement := { mmrS with evidence := prep { dropPooled := true } mmrS }
#guard let o := litOf cfgOut (mmrImportE.asOf 2002); o.verdict == .unsupported && o.disbelief == 1 / 6
#guard let o := litOf cfgAll (mmrImportE.asOf 2002); o.verdict == .unsupported && o.disbelief == 1 / 2
#guard (litOf cfgAll (mmrS.asOf 2002)).verdict == .refuted

-- The CAL cases test a scheme against the data it was fitted to (I against Ioannidis 2005, M
-- against Errington 2021). Tallies without CAL01 to CAL03 (48 cases):
def noCal (S : Scheme) : Nat × Nat × Nat × Nat := tallyOf ((results S).filter fun r => !r.id.startsWith "CAL")
#guard noCal core == (18, 20, 5, 5)
#guard noCal schH == (19, 17, 8, 4)
#guard noCal schHI == (21, 14, 9, 4)
#guard noCal schHIN == (22, 14, 8, 4)
#guard noCal calIo == (20, 16, 7, 5)

-- T04 fails for a reason weights cannot see (the universal is false as written). A true sentence
-- alone ("Human somatic cells have 46 chromosomes", m45455-17) is established today; the changes
-- that pass T04 by weight (textbook x1/2, N2 ageing) lose it.
open BioLean.Textbook.R3.ReproductionAtTheCellularLevel in
#guard core.v (core.lit reproduction_at_the_cellular_level_m45455_17) == .established &&
  (sensScheme .textbook (1 / 2)).v ((sensScheme .textbook (1 / 2)).lit reproduction_at_the_cellular_level_m45455_17) == .unsupported &&
  schN2.v (schN2.lit reproduction_at_the_cellular_level_m45455_17) == .unsupported
end review

-- BEGIN GENERATED PINS (scripts/stress/weights_pins.py)
/-! ### Every case under the core (observed 2026-10-31) -/
#guard pin core case_K01 "b=0.968 d=0.000 established" .pass
#guard pin core case_K02 "b=0.805 d=0.000 established" .pass
#guard pin core case_K03 "b=0.365 d=0.585 contested" .fail
#guard pin core case_K04 "b=0.388 d=0.577 contested" .pass
#guard pin core case_K05 "b=0.806 d=0.032 established ; b=0.090 d=0.818 refuted" .pass
#guard pin core case_W01 "b=0.923 d=0.000 established" .fail
#guard pin core case_W02 "b=0.419 d=0.548 contested" .fail
#guard pin core case_W03 "b=0.244 d=0.723 unsupported" .silent
#guard pin core case_W04 "b=0.543 d=0.419 contested" .fail
#guard pin core case_W05 "b=0.459 d=0.459 contested" .fail
#guard pin core case_W06 "b=0.801 d=0.168 established" .fail
#guard pin core case_W07 "b=0.810 d=0.000 established ; b=0.997 d=0.000 established" .fail
#guard pin core case_W08 "b=0.000 d=0.918 refuted" .pass
#guard pin core case_W09 "b=0.909 d=0.000 established" .pass
#guard pin core case_D01 "b=0.870 d=0.090 established" .fail
#guard pin core case_D02 "b=0.800 d=0.000 established" .fail
#guard pin core case_D03 "b=0.972 d=0.000 established" .pass
#guard pin core case_D04 "b=0.977 d=0.000 established" .fail
#guard pin core case_D05 "b=0.071 d=0.857 refuted" .pass
#guard pin core case_D06 "b=0.250 d=0.500 contested" .fail
#guard pin core case_D07 "b=0.866 d=0.000 established" .pass
#guard pin core case_D08 "b=0.923 d=0.000 established" .pass
#guard pin core case_D09 "same opinion in either order: no" .fail
#guard pin core case_D10 "two copies weigh as one: yes" .pass
#guard pin core case_R01 "b=0.608 d=0.260 contested" .fail
#guard pin core case_R02 "b=0.250 d=0.500 contested" .fail
#guard pin core case_R03 "cannot be stated" .inexpressible
#guard pin core case_R04 "b=0.750 d=0.000 unsupported" .silent
#guard pin core case_R05 "b=0.333 d=0.500 contested" .pass
#guard pin core case_CAL01 "inVitro supporting within x2 of 39/97: yes ; inVitro refuting within x2 of 12/15: no" .fail
#guard pin core case_CAL02 "rct within x2 of 30/39: yes ; observational within x2 of 1/6: no" .fail
#guard pin core case_CAL03 "mentions 1-1: 0.300 vs 57/119: yes ; mentions 2-5: 0.584 vs 93/138: yes ; mentions 6-10: 0.769 vs 119/159: yes" .pass
#guard pin core case_A01 "b=0.210 d=0.000 unsupported" .pass
#guard pin core case_A02 "b=0.850 d=0.000 established" .fail
#guard pin core case_A03 "b=0.475 d=0.446 contested" .fail
#guard pin core case_A04 "cannot be stated" .inexpressible
#guard pin core case_T01 "b=0.857 d=0.000 established" .pass
#guard pin core case_T02 "b=0.750 d=0.125 unsupported" .silent
#guard pin core case_T03 "b=0.760 d=0.160 unsupported" .silent
#guard pin core case_T04 "b=0.800 d=0.000 established" .fail
#guard pin core case_C01 "b=0.995 d=0.000 established" .fail
#guard pin core case_C02 "b=0.990 d=0.004 established" .fail
#guard pin core case_C03 "b=0.800 d=0.000 established ; b=0.969 d=0.000 established" .pass
#guard pin core case_C04 "cannot be stated" .inexpressible
#guard pin core case_O01 "b=0.500 d=0.250 contested ; b=0.250 d=0.500 contested" .fail
#guard pin core case_O02 "b=0.875 d=0.062 established ; b=0.062 d=0.875 refuted" .pass
#guard pin core case_O03 "b=0.714 d=0.142 unsupported" .silent
#guard pin core case_B01 "cannot be stated" .inexpressible
#guard pin core case_B02 "b=0.500 d=0.000 unsupported" .pass
#guard pin core case_L01 "cannot be stated" .inexpressible
#guard pin core case_L02 "verdict unchanged without SUSTAIN 2: yes" .pass

/-! ### The example checks under the core: Ozempic and Chemiosmosis verdicts, signs, theorems -/
#guard exBase == [("oz.main", "established"),
    ("oz.mechanistic", "established"),
    ("oz.sitagliptin", "contested"),
    ("oz.nausea", "contested"),
    ("oz.hypothalamus", "contested"),
    ("oz.areaPostrema", "established"),
    ("ch.1965 chemiosmotic", "contested"),
    ("ch.1965 chemical intermediate", "contested"),
    ("ch.1974 chemiosmotic", "established"),
    ("ch.1974 chemical intermediate", "refuted"),
    ("ch.real1974 chemiosmotic", "established"),
    ("ch.real1974 chemical intermediate", "refuted"),
    ("oz.main sign", "+"),
    ("oz.mechanistic sign", "+"),
    ("oz.sitagliptin sign", "-"),
    ("oz.nausea sign", "-"),
    ("oz.hypothalamus sign", "+"),
    ("oz.areaPostrema sign", "+"),
    ("ch.1965 chemiosmotic sign", "0"),
    ("ch.1965 chemical intermediate sign", "0"),
    ("ch.1974 chemiosmotic sign", "+"),
    ("ch.1974 chemical intermediate sign", "-"),
    ("ch.real1974 chemiosmotic sign", "+"),
    ("ch.real1974 chemical intermediate sign", "-"),
    ("thm oz.main >= 0.95", "true"),
    ("thm oz.mech >= 0.8", "true"),
    ("thm ch.oneClaim never established", "true"),
    ("thm ch.1961 belief 0", "true")]

/-! ### Every scheme: mark string (one letter per case, in `cases` order), observed values that
differ from the core's, example-check flips, and exit-test wordings A and B -/
-- core: PASS 19, FAIL 22, SILENT 5, INEXPRESSIBLE 5
#guard pinScheme core "PPFPPFFSFFFFPPFFPFPFPPFPFFISPFFPPFFIPSSFFFPIFPSIPIP"
  []
  [] false false
-- B1 ECO and design remap: PASS 19, FAIL 21, SILENT 7, INEXPRESSIBLE 4
#guard pinScheme schB1 "PPFPPFSSFFFFPPFFPFSFPPFPFFISPFFPPFFIPSSFFFPPFPSIPIP"
  [("W01", "b=0.800 d=0.000 established"), ("W02", "b=0.217 d=0.739 unsupported"), ("D05", "b=0.166 d=0.666 unsupported"), ("A03", "b=0.470 d=0.449 contested"), ("C01", "b=0.955 d=0.000 established"), ("C02", "b=0.914 d=0.042 established"), ("C04", "IEA and EXP weigh differently: yes")]
  [] true false
-- C1 GRADE-like cap, whole statement: PASS 17, FAIL 17, SILENT 12, INEXPRESSIBLE 5
#guard pinScheme schC1 "PPFSPPFSFFFFPSFPPFSSPPFPFFISPFFPPPFISSSFFFPISSSIPIP"
  [("K03", "b=0.335 d=0.421 contested"), ("K04", "b=0.772 d=0.161 unsupported"), ("W01", "b=0.461 d=0.000 unsupported"), ("W09", "b=0.454 d=0.000 unsupported"), ("D02", "b=0.400 d=0.000 unsupported"), ("D05", "b=0.035 d=0.428 unsupported"), ("D06", "b=0.125 d=0.250 unsupported"), ("A02", "b=0.637 d=0.000 unsupported"), ("T01", "b=0.428 d=0.000 unsupported"), ("T02", "b=0.375 d=0.062 unsupported"), ("T03", "b=0.380 d=0.080 unsupported"), ("O01", "b=0.304 d=0.086 unsupported ; b=0.086 d=0.304 unsupported"), ("O02", "b=0.433 d=0.070 unsupported ; b=0.070 d=0.433 unsupported")]
  ["oz.nausea: contested -> unsupported", "oz.nausea sign: - -> +"] false false
-- C2 GRADE-like cap, clinical part of effect claims: PASS 20, FAIL 18, SILENT 8, INEXPRESSIBLE 5
#guard pinScheme schC2 "PPFPPPFSFFFFPSFPPFSSPPFPFFISPFFPPPFIPSSFFFPIFPSIPIP"
  [("K03", "b=0.437 d=0.499 contested"), ("W01", "b=0.461 d=0.000 unsupported"), ("W09", "b=0.454 d=0.000 unsupported"), ("D02", "b=0.400 d=0.000 unsupported"), ("D05", "b=0.035 d=0.428 unsupported"), ("D06", "b=0.125 d=0.250 unsupported"), ("A02", "b=0.637 d=0.000 unsupported")]
  [] true false
-- D curated groups: PASS 18, FAIL 22, SILENT 6, INEXPRESSIBLE 5
#guard pinScheme schD "PPFPPFFFFFFFPPFPPFPFPPFPFFISSFFPPFFIPSSFFFPIFSSIPIP"
  [("W01", "b=0.909 d=0.000 established"), ("W02", "b=0.447 d=0.507 contested"), ("W03", "b=0.298 d=0.662 contested"), ("W09", "b=0.875 d=0.000 established"), ("D01", "b=0.402 d=0.417 contested"), ("D02", "b=0.500 d=0.000 unsupported"), ("R01", "b=0.437 d=0.375 contested"), ("R05", "b=0.200 d=0.600 unsupported"), ("C01", "b=0.952 d=0.000 established"), ("C02", "b=0.909 d=0.045 established"), ("O02", "b=0.750 d=0.125 unsupported ; b=0.125 d=0.750 unsupported")]
  [] false false
-- D auto groups: PASS 18, FAIL 19, SILENT 9, INEXPRESSIBLE 5
#guard pinScheme schDauto "PSFPSPPSFFFFPPFPPFPFPPFPFFISSFFPPFFIPSSFFFPIFSSIPIP"
  [("K02", "b=0.795 d=0.000 unsupported"), ("K03", "b=0.354 d=0.595 contested"), ("K04", "b=0.337 d=0.626 contested"), ("K05", "b=0.789 d=0.035 unsupported ; b=0.095 d=0.809 refuted"), ("W01", "b=0.750 d=0.000 unsupported"), ("W02", "b=0.126 d=0.825 refuted"), ("W03", "b=0.219 d=0.747 unsupported"), ("W09", "b=0.857 d=0.000 established"), ("D01", "b=0.578 d=0.295 contested"), ("D02", "b=0.500 d=0.000 unsupported"), ("D05", "b=0.076 d=0.846 refuted"), ("R01", "b=0.437 d=0.375 contested"), ("R05", "b=0.200 d=0.600 unsupported"), ("T03", "b=0.733 d=0.177 unsupported"), ("C01", "b=0.952 d=0.000 established"), ("C02", "b=0.909 d=0.045 established"), ("O02", "b=0.750 d=0.125 unsupported ; b=0.125 d=0.750 unsupported"), ("O03", "b=0.692 d=0.153 unsupported")]
  ["oz.mechanistic: established -> unsupported", "ch.1974 chemiosmotic: established -> unsupported", "ch.real1974 chemiosmotic: established -> unsupported", "thm oz.mech >= 0.8: true -> false"] true false
-- D curated groups, reviews one source: PASS 16, FAIL 22, SILENT 8, INEXPRESSIBLE 5
#guard pinScheme schDrev "PSFPPFFFFFFFPPFPPFPFSPFPFFISSFFPPFFIPSSFFFPIFSSIPIP"
  [("K01", "b=0.966 d=0.000 established"), ("K02", "b=0.722 d=0.000 unsupported"), ("K03", "b=0.350 d=0.598 contested"), ("W01", "b=0.909 d=0.000 established"), ("W02", "b=0.447 d=0.507 contested"), ("W03", "b=0.298 d=0.662 contested"), ("W09", "b=0.875 d=0.000 established"), ("D01", "b=0.534 d=0.325 contested"), ("D02", "b=0.500 d=0.000 unsupported"), ("D07", "b=0.777 d=0.000 unsupported"), ("R01", "b=0.437 d=0.375 contested"), ("R05", "b=0.200 d=0.600 unsupported"), ("C01", "b=0.952 d=0.000 established"), ("C02", "b=0.909 d=0.045 established"), ("O02", "b=0.750 d=0.125 unsupported ; b=0.125 d=0.750 unsupported")]
  ["oz.mechanistic: established -> unsupported", "thm oz.mech >= 0.8: true -> false"] false false
-- E meta replaces its primaries: PASS 19, FAIL 22, SILENT 5, INEXPRESSIBLE 5
#guard pinScheme schE "PPFPPFFSFFFFPPFFPFPFPPFPFFISPFFPPFFIPSSFFFPIFPSIPIP"
  [("W01", "b=0.916 d=0.000 established"), ("W02", "b=0.400 d=0.566 contested"), ("D03", "b=0.967 d=0.000 established"), ("D04", "b=0.900 d=0.000 established"), ("D05", "b=0.076 d=0.846 refuted")]
  [] false false
-- F extraction factor: PASS 20, FAIL 22, SILENT 5, INEXPRESSIBLE 4
#guard pinScheme schF "PPFPPFFSFFFFPPFFPFPFPPFPFFISPFFPPFFIPSSFFFPIFPSIPPP"
  [("L01", "study and extraction are two factors: yes")]
  [] false false
-- G ceilings, INDRA values: PASS 18, FAIL 22, SILENT 6, INEXPRESSIBLE 5
#guard pinScheme schG "PPFPPFFSFFFFPPFFPFPFPPFPFFISPFFPPFFIPSSFFFSIFPSIPIP"
  [("W07", "b=0.770 d=0.000 unsupported ; b=0.947 d=0.000 established"), ("CAL03", "mentions 1-1: 0.285 vs 57/119: yes ; mentions 2-5: 0.555 vs 93/138: yes ; mentions 6-10: 0.731 vs 119/159: yes"), ("C01", "b=0.985 d=0.000 established"), ("C02", "b=0.970 d=0.014 established"), ("C03", "b=0.792 d=0.000 unsupported ; b=0.968 d=0.000 established")]
  [] false false
-- G ceilings, guessed values: PASS 21, FAIL 18, SILENT 7, INEXPRESSIBLE 5
#guard pinScheme schGguess "PPFPPFFSFFPPPSFPPFPSPPFPFFISPFFPPFFIPSFFFFPISPSIPIP"
  [("W01", "b=0.907 d=0.000 established"), ("W02", "b=0.355 d=0.608 contested"), ("W03", "b=0.211 d=0.755 unsupported"), ("W06", "b=0.170 d=0.704 unsupported"), ("W07", "b=0.648 d=0.000 unsupported ; b=0.798 d=0.000 unsupported"), ("W09", "b=0.545 d=0.000 unsupported"), ("D02", "b=0.480 d=0.000 unsupported"), ("D05", "b=0.021 d=0.887 refuted"), ("D06", "b=0.150 d=0.300 unsupported"), ("CAL03", "mentions 1-1: 0.240 vs 57/119: yes ; mentions 2-5: 0.467 vs 93/138: yes ; mentions 6-10: 0.615 vs 119/159: yes"), ("T01", "b=0.823 d=0.000 established"), ("T02", "b=0.781 d=0.046 unsupported"), ("T03", "b=0.821 d=0.046 established"), ("O01", "b=0.318 d=0.204 unsupported ; b=0.204 d=0.318 unsupported"), ("O02", "b=0.898 d=0.030 established ; b=0.030 d=0.898 refuted")]
  [] true false
-- H drop retracted: PASS 20, FAIL 19, SILENT 8, INEXPRESSIBLE 4
#guard pinScheme schH "PPFPPFFSFFFFPPFFPFPSPPFPSSPSPFFPPFFIPSSFFFPIFPSIPIP"
  [("D01", "b=0.411 d=0.411 contested"), ("D05", "b=0.000 d=0.923 refuted"), ("D06", "b=0.000 d=0.666 unsupported"), ("R01", "b=0.000 d=0.666 unsupported"), ("R02", "b=0.000 d=0.666 unsupported"), ("R03", "b=0.000 d=0.000 unsupported"), ("B02", "b=0.000 d=0.000 unsupported")]
  [] true true
-- I Ioannidis table: PASS 22, FAIL 17, SILENT 7, INEXPRESSIBLE 5
#guard pinScheme calIo "PPFPPFFSFFPFPSFPPFPSPPFPFFISPFPPPPFIPSFFFFPISPSIPIP"
  [("K01", "b=0.955 d=0.000 established"), ("K03", "b=0.404 d=0.538 contested"), ("K04", "b=0.421 d=0.542 contested"), ("W01", "b=0.905 d=0.000 established"), ("W02", "b=0.471 d=0.480 contested"), ("W03", "b=0.206 d=0.738 unsupported"), ("W04", "b=0.616 d=0.333 contested"), ("W05", "b=0.434 d=0.434 contested"), ("W06", "b=0.554 d=0.342 contested"), ("W08", "b=0.000 d=0.869 refuted"), ("W09", "b=0.666 d=0.000 unsupported"), ("D02", "b=0.444 d=0.000 unsupported"), ("D03", "b=0.963 d=0.000 established"), ("D04", "b=0.966 d=0.000 established"), ("D05", "b=0.018 d=0.888 refuted"), ("D06", "b=0.125 d=0.250 unsupported"), ("CAL02", "rct within x2 of 30/39: yes ; observational within x2 of 1/6: yes"), ("A02", "b=0.769 d=0.000 unsupported"), ("A03", "b=0.460 d=0.414 contested"), ("T01", "b=0.814 d=0.000 established"), ("T02", "b=0.785 d=0.035 unsupported"), ("T03", "b=0.818 d=0.051 established"), ("O01", "b=0.250 d=0.125 unsupported ; b=0.125 d=0.250 unsupported"), ("O02", "b=0.911 d=0.014 established ; b=0.014 d=0.911 refuted")]
  [] true false
-- J base rate in verdict: PASS 21, FAIL 24, SILENT 2, INEXPRESSIBLE 4
#guard pinScheme schJ "PPFPPFFSFFFFPPFFPFPFPPFPFFIPPFFPPFFIPFFFFFPIFPSPPIP"
  [("R04", "b=0.750 d=0.000 established"), ("T02", "b=0.750 d=0.125 established"), ("T03", "b=0.760 d=0.160 established"), ("B01", "base rate changes a verdict: yes")]
  [] false false
-- K size: PASS 22, FAIL 19, SILENT 5, INEXPRESSIBLE 5
#guard pinScheme schK "PPFPPFSPPFFFPPFFPFPPPPFPFFISPFFPPFFIPSSFFFPIFPSIPIP"
  [("W01", "b=0.958 d=0.000 established"), ("W02", "b=0.218 d=0.773 unsupported"), ("W03", "b=0.116 d=0.878 refuted"), ("W04", "b=0.149 d=0.840 refuted"), ("W05", "b=0.330 d=0.635 contested"), ("W08", "b=0.000 d=0.989 refuted"), ("W09", "b=0.960 d=0.000 established"), ("D02", "b=0.954 d=0.000 established"), ("D03", "b=0.968 d=0.000 established"), ("D04", "b=0.972 d=0.000 established"), ("D05", "b=0.001 d=0.987 refuted"), ("D06", "b=0.012 d=0.888 refuted"), ("A03", "b=0.339 d=0.627 contested")]
  [] true true
-- M polarity weights (inVitro): PASS 18, FAIL 22, SILENT 6, INEXPRESSIBLE 5
#guard pinScheme schM "PSFPSFFSFFFFPPFFPFPFPPFPFPISFPFPPFFIPSSFFFPIFPFIPIP"
  [("K02", "b=0.793 d=0.000 unsupported"), ("K03", "b=0.364 d=0.585 contested"), ("K05", "b=0.763 d=0.008 unsupported ; b=0.031 d=0.920 refuted"), ("D07", "b=0.853 d=0.000 established"), ("R01", "b=0.341 d=0.585 contested"), ("R02", "b=0.069 d=0.827 refuted"), ("R04", "b=0.668 d=0.000 unsupported"), ("R05", "b=0.093 d=0.836 refuted"), ("CAL01", "inVitro supporting within x2 of 39/97: yes ; inVitro refuting within x2 of 12/15: yes"), ("C02", "b=0.975 d=0.019 established"), ("O03", "b=0.402 d=0.478 contested"), ("B02", "b=0.402 d=0.000 unsupported")]
  ["oz.mechanistic: established -> unsupported", "ch.1974 chemiosmotic: established -> unsupported", "ch.real1974 chemiosmotic: established -> unsupported", "thm oz.mech >= 0.8: true -> false"] false false
-- M+H polarity weights, drop retracted: PASS 20, FAIL 20, SILENT 7, INEXPRESSIBLE 4
#guard pinScheme schMH "PSFPSFFSFFFFPPFFPFPSPPFPPPPSFPFPPFFIPSSFFFPIFPFIPIP"
  [("K02", "b=0.793 d=0.000 unsupported"), ("K03", "b=0.364 d=0.585 contested"), ("K05", "b=0.763 d=0.008 unsupported ; b=0.031 d=0.920 refuted"), ("D01", "b=0.411 d=0.411 contested"), ("D05", "b=0.000 d=0.923 refuted"), ("D06", "b=0.000 d=0.666 unsupported"), ("D07", "b=0.853 d=0.000 established"), ("R01", "b=0.000 d=0.888 refuted"), ("R02", "b=0.000 d=0.888 refuted"), ("R03", "b=0.000 d=0.000 unsupported"), ("R04", "b=0.668 d=0.000 unsupported"), ("R05", "b=0.093 d=0.836 refuted"), ("CAL01", "inVitro supporting within x2 of 39/97: yes ; inVitro refuting within x2 of 12/15: yes"), ("C02", "b=0.975 d=0.019 established"), ("O03", "b=0.402 d=0.478 contested"), ("B02", "b=0.000 d=0.000 unsupported")]
  ["oz.mechanistic: established -> unsupported", "ch.1974 chemiosmotic: established -> unsupported", "ch.real1974 chemiosmotic: established -> unsupported", "thm oz.mech >= 0.8: true -> false"] true false
-- N1 supersession table: PASS 20, FAIL 21, SILENT 5, INEXPRESSIBLE 5
#guard pinScheme schN1 "PPFPPFFSFFFFPPFFPFPFPPFPFFISPFFPPFFIPSSFFFPISPPIPIP"
  [("K05", "b=0.833 d=0.000 established ; b=0.000 d=0.900 refuted"), ("O01", "b=0.666 d=0.000 unsupported ; b=0.000 d=0.666 unsupported"), ("O02", "b=0.933 d=0.000 established ; b=0.000 d=0.933 refuted"), ("O03", "b=0.833 d=0.000 established")]
  ["thm ch.oneClaim never established: true -> false"] true true
-- N2 ageing, half-life 10 years: PASS 21, FAIL 13, SILENT 12, INEXPRESSIBLE 5
#guard pinScheme schN2 "PSFPSFFPFFPFSPSPPPPSPPFPSSISPFFPPFFIPSSPFFPISPSIPIP"
  [("K01", "b=0.955 d=0.000 established"), ("K02", "b=0.756 d=0.000 unsupported"), ("K03", "b=0.357 d=0.535 contested"), ("K04", "b=0.395 d=0.522 contested"), ("K05", "b=0.757 d=0.028 unsupported ; b=0.066 d=0.809 refuted"), ("W01", "b=0.888 d=0.000 established"), ("W02", "b=0.275 d=0.679 contested"), ("W03", "b=0.142 d=0.812 refuted"), ("W04", "b=0.409 d=0.532 contested"), ("W05", "b=0.359 d=0.385 contested"), ("W06", "b=0.697 d=0.146 unsupported"), ("W07", "b=0.738 d=0.000 unsupported ; b=0.996 d=0.000 established"), ("W08", "b=0.000 d=0.569 unsupported"), ("W09", "b=0.873 d=0.000 established"), ("D01", "b=0.790 d=0.105 unsupported"), ("D02", "b=0.303 d=0.000 unsupported"), ("D03", "b=0.961 d=0.000 established"), ("D04", "b=0.755 d=0.000 unsupported"), ("D05", "b=0.023 d=0.809 refuted"), ("D06", "b=0.212 d=0.507 unsupported"), ("D07", "b=0.823 d=0.000 established"), ("D08", "b=0.829 d=0.000 established"), ("R01", "b=0.512 d=0.235 unsupported"), ("R02", "b=0.167 d=0.358 unsupported"), ("R04", "b=0.560 d=0.000 unsupported"), ("R05", "b=0.253 d=0.330 contested"), ("CAL03", "mentions 1-1: 0.220 vs 57/119: yes ; mentions 2-5: 0.484 vs 93/138: yes ; mentions 6-10: 0.688 vs 119/159: yes"), ("A01", "b=0.171 d=0.000 unsupported"), ("A02", "b=0.800 d=0.000 established"), ("A03", "b=0.401 d=0.360 contested"), ("T01", "b=0.842 d=0.000 established"), ("T02", "b=0.579 d=0.153 unsupported"), ("T03", "b=0.644 d=0.203 unsupported"), ("T04", "b=0.618 d=0.000 unsupported"), ("C02", "b=0.994 d=0.001 established"), ("O01", "b=0.584 d=0.029 unsupported ; b=0.029 d=0.584 unsupported"), ("O02", "b=0.923 d=0.000 established ; b=0.000 d=0.923 refuted"), ("O03", "b=0.697 d=0.105 unsupported")]
  ["oz.mechanistic: established -> unsupported", "ch.1974 chemiosmotic: established -> unsupported", "ch.real1974 chemiosmotic: established -> unsupported", "thm oz.mech >= 0.8: true -> false"] true false
-- H1+I: PASS 23, FAIL 15, SILENT 9, INEXPRESSIBLE 4
#guard pinScheme schHI "PPFPPFFSFFPFPSFPPFPSPPFPSSPSPFPPPPFIPSFFFFPISPSIPIP"
  [("K01", "b=0.955 d=0.000 established"), ("K03", "b=0.404 d=0.538 contested"), ("K04", "b=0.421 d=0.542 contested"), ("W01", "b=0.905 d=0.000 established"), ("W02", "b=0.471 d=0.480 contested"), ("W03", "b=0.206 d=0.738 unsupported"), ("W04", "b=0.616 d=0.333 contested"), ("W05", "b=0.434 d=0.434 contested"), ("W06", "b=0.554 d=0.342 contested"), ("W08", "b=0.000 d=0.869 refuted"), ("W09", "b=0.666 d=0.000 unsupported"), ("D01", "b=0.411 d=0.411 contested"), ("D02", "b=0.444 d=0.000 unsupported"), ("D03", "b=0.963 d=0.000 established"), ("D04", "b=0.966 d=0.000 established"), ("D05", "b=0.000 d=0.905 refuted"), ("D06", "b=0.000 d=0.285 unsupported"), ("R01", "b=0.000 d=0.666 unsupported"), ("R02", "b=0.000 d=0.666 unsupported"), ("R03", "b=0.000 d=0.000 unsupported"), ("CAL02", "rct within x2 of 30/39: yes ; observational within x2 of 1/6: yes"), ("A02", "b=0.769 d=0.000 unsupported"), ("A03", "b=0.460 d=0.414 contested"), ("T01", "b=0.814 d=0.000 established"), ("T02", "b=0.785 d=0.035 unsupported"), ("T03", "b=0.818 d=0.051 established"), ("O01", "b=0.250 d=0.125 unsupported ; b=0.125 d=0.250 unsupported"), ("O02", "b=0.911 d=0.014 established ; b=0.014 d=0.911 refuted"), ("B02", "b=0.000 d=0.000 unsupported")]
  [] true false
-- H1+I+N1: PASS 24, FAIL 15, SILENT 8, INEXPRESSIBLE 4
#guard pinScheme schHIN "PPFPPFFSFFPFPSFPPFPSPPFPSSPSPFPPPPFIPSFFFFPISPPIPIP"
  [("K01", "b=0.955 d=0.000 established"), ("K03", "b=0.404 d=0.538 contested"), ("K04", "b=0.421 d=0.542 contested"), ("K05", "b=0.833 d=0.000 established ; b=0.000 d=0.900 refuted"), ("W01", "b=0.905 d=0.000 established"), ("W02", "b=0.471 d=0.480 contested"), ("W03", "b=0.206 d=0.738 unsupported"), ("W04", "b=0.616 d=0.333 contested"), ("W05", "b=0.434 d=0.434 contested"), ("W06", "b=0.554 d=0.342 contested"), ("W08", "b=0.000 d=0.869 refuted"), ("W09", "b=0.666 d=0.000 unsupported"), ("D01", "b=0.411 d=0.411 contested"), ("D02", "b=0.444 d=0.000 unsupported"), ("D03", "b=0.963 d=0.000 established"), ("D04", "b=0.966 d=0.000 established"), ("D05", "b=0.000 d=0.905 refuted"), ("D06", "b=0.000 d=0.285 unsupported"), ("R01", "b=0.000 d=0.666 unsupported"), ("R02", "b=0.000 d=0.666 unsupported"), ("R03", "b=0.000 d=0.000 unsupported"), ("CAL02", "rct within x2 of 30/39: yes ; observational within x2 of 1/6: yes"), ("A02", "b=0.769 d=0.000 unsupported"), ("A03", "b=0.460 d=0.414 contested"), ("T01", "b=0.814 d=0.000 established"), ("T02", "b=0.785 d=0.035 unsupported"), ("T03", "b=0.818 d=0.051 established"), ("O01", "b=0.285 d=0.000 unsupported ; b=0.000 d=0.285 unsupported"), ("O02", "b=0.925 d=0.000 established ; b=0.000 d=0.925 refuted"), ("O03", "b=0.833 d=0.000 established"), ("B02", "b=0.000 d=0.000 unsupported")]
  ["thm ch.oneClaim never established: true -> false"] true false
-- H+E+D hygiene: PASS 19, FAIL 19, SILENT 9, INEXPRESSIBLE 4
#guard pinScheme schHyg "PPFPPFFFFFFFPPFPPFPSPPFPSSPSSFFPPFFIPSSFFFPIFSSIPIP"
  [("W01", "b=0.909 d=0.000 established"), ("W02", "b=0.447 d=0.507 contested"), ("W03", "b=0.298 d=0.662 contested"), ("W09", "b=0.875 d=0.000 established"), ("D01", "b=0.411 d=0.411 contested"), ("D02", "b=0.500 d=0.000 unsupported"), ("D03", "b=0.967 d=0.000 established"), ("D04", "b=0.900 d=0.000 established"), ("D05", "b=0.000 d=0.916 refuted"), ("D06", "b=0.000 d=0.666 unsupported"), ("R01", "b=0.000 d=0.666 unsupported"), ("R02", "b=0.000 d=0.666 unsupported"), ("R03", "b=0.000 d=0.000 unsupported"), ("R05", "b=0.200 d=0.600 unsupported"), ("C01", "b=0.952 d=0.000 established"), ("C02", "b=0.909 d=0.045 established"), ("O02", "b=0.750 d=0.125 unsupported ; b=0.125 d=0.750 unsupported"), ("B02", "b=0.000 d=0.000 unsupported")]
  [] true false
-- H+E+D+B1+G+K+F: PASS 25, FAIL 15, SILENT 9, INEXPRESSIBLE 2
#guard pinScheme schAll "PPFPPFPPPFFFPPFFPPPPPPFPSSPSSFFPPFFIPSSFPFSPFSSIPPP"
  [("W01", "b=0.864 d=0.000 established"), ("W02", "b=0.100 d=0.884 refuted"), ("W03", "b=0.148 d=0.845 refuted"), ("W04", "b=0.149 d=0.840 refuted"), ("W05", "b=0.330 d=0.635 contested"), ("W07", "b=0.770 d=0.000 unsupported ; b=0.947 d=0.000 established"), ("W08", "b=0.000 d=0.989 refuted"), ("W09", "b=0.933 d=0.000 established"), ("D01", "b=0.411 d=0.411 contested"), ("D02", "b=0.840 d=0.000 established"), ("D03", "b=0.961 d=0.000 established"), ("D04", "b=0.539 d=0.000 unsupported"), ("D05", "b=0.000 d=0.944 refuted"), ("D06", "b=0.000 d=0.900 refuted"), ("R01", "b=0.000 d=0.666 unsupported"), ("R02", "b=0.000 d=0.666 unsupported"), ("R03", "b=0.000 d=0.000 unsupported"), ("R05", "b=0.200 d=0.600 unsupported"), ("CAL03", "mentions 1-1: 0.285 vs 57/119: yes ; mentions 2-5: 0.555 vs 93/138: yes ; mentions 6-10: 0.731 vs 119/159: yes"), ("A03", "b=0.336 d=0.629 contested"), ("C01", "b=0.658 d=0.000 unsupported"), ("C02", "b=0.490 d=0.254 contested"), ("C03", "b=0.792 d=0.000 unsupported ; b=0.968 d=0.000 established"), ("C04", "IEA and EXP weigh differently: yes"), ("O02", "b=0.750 d=0.125 unsupported ; b=0.125 d=0.750 unsupported"), ("B02", "b=0.000 d=0.000 unsupported"), ("L01", "study and extraction are two factors: yes")]
  [] true false
-- outside core: H+E+D+B1+I: PASS 24, FAIL 12, SILENT 12, INEXPRESSIBLE 3
#guard pinScheme schOut "PPFPPPPFFFPFPSFPPFSSPPFPSSPSSFPPPPFIPSFFPSPPSSSIPIP"
  [("K01", "b=0.955 d=0.000 established"), ("K03", "b=0.404 d=0.538 contested"), ("K04", "b=0.421 d=0.542 contested"), ("W01", "b=0.285 d=0.000 unsupported"), ("W02", "b=0.049 d=0.826 refuted"), ("W03", "b=0.253 d=0.678 contested"), ("W04", "b=0.616 d=0.333 contested"), ("W05", "b=0.434 d=0.434 contested"), ("W06", "b=0.554 d=0.342 contested"), ("W08", "b=0.000 d=0.869 refuted"), ("W09", "b=0.583 d=0.000 unsupported"), ("D01", "b=0.411 d=0.411 contested"), ("D02", "b=0.166 d=0.000 unsupported"), ("D03", "b=0.958 d=0.000 established"), ("D04", "b=0.900 d=0.000 established"), ("D05", "b=0.000 d=0.375 unsupported"), ("D06", "b=0.000 d=0.285 unsupported"), ("R01", "b=0.000 d=0.666 unsupported"), ("R02", "b=0.000 d=0.666 unsupported"), ("R03", "b=0.000 d=0.000 unsupported"), ("R05", "b=0.200 d=0.600 unsupported"), ("CAL02", "rct within x2 of 30/39: yes ; observational within x2 of 1/6: yes"), ("A02", "b=0.769 d=0.000 unsupported"), ("A03", "b=0.453 d=0.420 contested"), ("T01", "b=0.814 d=0.000 established"), ("T02", "b=0.785 d=0.035 unsupported"), ("T03", "b=0.818 d=0.051 established"), ("C01", "b=0.681 d=0.000 unsupported"), ("C02", "b=0.517 d=0.241 unsupported"), ("C04", "IEA and EXP weigh differently: yes"), ("O01", "b=0.250 d=0.125 unsupported ; b=0.125 d=0.250 unsupported"), ("O02", "b=0.785 d=0.035 unsupported ; b=0.035 d=0.785 unsupported"), ("B02", "b=0.000 d=0.000 unsupported")]
  [] true false
-- outside core: H+E+D+B1+I+N1: PASS 26, FAIL 12, SILENT 10, INEXPRESSIBLE 3
#guard pinScheme schOutN "PPFPPPPFFFPFPSFPPFSSPPFPSSPSSFPPPPFIPSFFPSPPSPPIPIP"
  [("K01", "b=0.955 d=0.000 established"), ("K03", "b=0.404 d=0.538 contested"), ("K04", "b=0.421 d=0.542 contested"), ("K05", "b=0.833 d=0.000 established ; b=0.000 d=0.900 refuted"), ("W01", "b=0.285 d=0.000 unsupported"), ("W02", "b=0.049 d=0.826 refuted"), ("W03", "b=0.253 d=0.678 contested"), ("W04", "b=0.616 d=0.333 contested"), ("W05", "b=0.434 d=0.434 contested"), ("W06", "b=0.554 d=0.342 contested"), ("W08", "b=0.000 d=0.869 refuted"), ("W09", "b=0.583 d=0.000 unsupported"), ("D01", "b=0.411 d=0.411 contested"), ("D02", "b=0.166 d=0.000 unsupported"), ("D03", "b=0.958 d=0.000 established"), ("D04", "b=0.900 d=0.000 established"), ("D05", "b=0.000 d=0.375 unsupported"), ("D06", "b=0.000 d=0.285 unsupported"), ("R01", "b=0.000 d=0.666 unsupported"), ("R02", "b=0.000 d=0.666 unsupported"), ("R03", "b=0.000 d=0.000 unsupported"), ("R05", "b=0.200 d=0.600 unsupported"), ("CAL02", "rct within x2 of 30/39: yes ; observational within x2 of 1/6: yes"), ("A02", "b=0.769 d=0.000 unsupported"), ("A03", "b=0.453 d=0.420 contested"), ("T01", "b=0.814 d=0.000 established"), ("T02", "b=0.785 d=0.035 unsupported"), ("T03", "b=0.818 d=0.051 established"), ("C01", "b=0.681 d=0.000 unsupported"), ("C02", "b=0.517 d=0.241 unsupported"), ("C04", "IEA and EXP weigh differently: yes"), ("O01", "b=0.285 d=0.000 unsupported ; b=0.000 d=0.285 unsupported"), ("O02", "b=0.814 d=0.000 established ; b=0.000 d=0.814 refuted"), ("O03", "b=0.833 d=0.000 established"), ("B02", "b=0.000 d=0.000 unsupported")]
  ["thm ch.oneClaim never established: true -> false"] true false
-- H+E+D+B1+G+K+F+I: PASS 27, FAIL 10, SILENT 12, INEXPRESSIBLE 2
#guard pinScheme schAllI "PPFPPPPPPFPFPSFPPPSSPPFPSSPSSFPPPPFIPSFFPFSPSSSIPPP"
  [("K01", "b=0.955 d=0.000 established"), ("K03", "b=0.404 d=0.538 contested"), ("K04", "b=0.421 d=0.542 contested"), ("W01", "b=0.561 d=0.000 unsupported"), ("W02", "b=0.036 d=0.937 refuted"), ("W03", "b=0.102 d=0.886 refuted"), ("W04", "b=0.155 d=0.827 refuted"), ("W05", "b=0.323 d=0.620 contested"), ("W06", "b=0.554 d=0.342 contested"), ("W07", "b=0.770 d=0.000 unsupported ; b=0.947 d=0.000 established"), ("W08", "b=0.000 d=0.981 refuted"), ("W09", "b=0.736 d=0.000 unsupported"), ("D01", "b=0.411 d=0.411 contested"), ("D02", "b=0.512 d=0.000 unsupported"), ("D03", "b=0.947 d=0.000 established"), ("D04", "b=0.539 d=0.000 unsupported"), ("D05", "b=0.000 d=0.772 unsupported"), ("D06", "b=0.000 d=0.642 unsupported"), ("R01", "b=0.000 d=0.666 unsupported"), ("R02", "b=0.000 d=0.666 unsupported"), ("R03", "b=0.000 d=0.000 unsupported"), ("R05", "b=0.200 d=0.600 unsupported"), ("CAL02", "rct within x2 of 30/39: yes ; observational within x2 of 1/6: yes"), ("CAL03", "mentions 1-1: 0.285 vs 57/119: yes ; mentions 2-5: 0.555 vs 93/138: yes ; mentions 6-10: 0.731 vs 119/159: yes"), ("A02", "b=0.769 d=0.000 unsupported"), ("A03", "b=0.333 d=0.611 contested"), ("T01", "b=0.814 d=0.000 established"), ("T02", "b=0.785 d=0.035 unsupported"), ("T03", "b=0.818 d=0.051 established"), ("C01", "b=0.658 d=0.000 unsupported"), ("C02", "b=0.490 d=0.254 contested"), ("C03", "b=0.792 d=0.000 unsupported ; b=0.968 d=0.000 established"), ("C04", "IEA and EXP weigh differently: yes"), ("O01", "b=0.250 d=0.125 unsupported ; b=0.125 d=0.250 unsupported"), ("O02", "b=0.785 d=0.035 unsupported ; b=0.035 d=0.785 unsupported"), ("B02", "b=0.000 d=0.000 unsupported"), ("L01", "study and extraction are two factors: yes")]
  [] true false
-- H+E+D+B1+G+K+F+I+N1: PASS 29, FAIL 10, SILENT 10, INEXPRESSIBLE 2
#guard pinScheme schAllIN "PPFPPPPPPFPFPSFPPPSSPPFPSSPSSFPPPPFIPSFFPFSPSPPIPPP"
  [("K01", "b=0.955 d=0.000 established"), ("K03", "b=0.404 d=0.538 contested"), ("K04", "b=0.421 d=0.542 contested"), ("K05", "b=0.833 d=0.000 established ; b=0.000 d=0.900 refuted"), ("W01", "b=0.561 d=0.000 unsupported"), ("W02", "b=0.036 d=0.937 refuted"), ("W03", "b=0.102 d=0.886 refuted"), ("W04", "b=0.155 d=0.827 refuted"), ("W05", "b=0.323 d=0.620 contested"), ("W06", "b=0.554 d=0.342 contested"), ("W07", "b=0.770 d=0.000 unsupported ; b=0.947 d=0.000 established"), ("W08", "b=0.000 d=0.981 refuted"), ("W09", "b=0.736 d=0.000 unsupported"), ("D01", "b=0.411 d=0.411 contested"), ("D02", "b=0.512 d=0.000 unsupported"), ("D03", "b=0.947 d=0.000 established"), ("D04", "b=0.539 d=0.000 unsupported"), ("D05", "b=0.000 d=0.772 unsupported"), ("D06", "b=0.000 d=0.642 unsupported"), ("R01", "b=0.000 d=0.666 unsupported"), ("R02", "b=0.000 d=0.666 unsupported"), ("R03", "b=0.000 d=0.000 unsupported"), ("R05", "b=0.200 d=0.600 unsupported"), ("CAL02", "rct within x2 of 30/39: yes ; observational within x2 of 1/6: yes"), ("CAL03", "mentions 1-1: 0.285 vs 57/119: yes ; mentions 2-5: 0.555 vs 93/138: yes ; mentions 6-10: 0.731 vs 119/159: yes"), ("A02", "b=0.769 d=0.000 unsupported"), ("A03", "b=0.333 d=0.611 contested"), ("T01", "b=0.814 d=0.000 established"), ("T02", "b=0.785 d=0.035 unsupported"), ("T03", "b=0.818 d=0.051 established"), ("C01", "b=0.658 d=0.000 unsupported"), ("C02", "b=0.490 d=0.254 contested"), ("C03", "b=0.792 d=0.000 unsupported ; b=0.968 d=0.000 established"), ("C04", "IEA and EXP weigh differently: yes"), ("O01", "b=0.285 d=0.000 unsupported ; b=0.000 d=0.285 unsupported"), ("O02", "b=0.814 d=0.000 established ; b=0.000 d=0.814 refuted"), ("O03", "b=0.833 d=0.000 established"), ("B02", "b=0.000 d=0.000 unsupported"), ("L01", "study and extraction are two factors: yes")]
  ["thm ch.oneClaim never established: true -> false"] true false
-- I Errington table: PASS 16, FAIL 21, SILENT 9, INEXPRESSIBLE 5
#guard pinScheme calEr "PSSPSFFSFFFFPPFFPFPFPPFPFSISPFFPPFFIPSSFFFPIFPSIPIF"
  [("K01", "b=0.964 d=0.000 established"), ("K02", "b=0.708 d=0.000 unsupported"), ("K03", "b=0.224 d=0.694 unsupported"), ("K04", "b=0.251 d=0.674 contested"), ("K05", "b=0.739 d=0.040 unsupported ; b=0.087 d=0.783 unsupported"), ("D01", "b=0.818 d=0.072 established"), ("D03", "b=0.971 d=0.000 established"), ("D07", "b=0.853 d=0.000 established"), ("R01", "b=0.364 d=0.364 contested"), ("R02", "b=0.222 d=0.445 unsupported"), ("R04", "b=0.668 d=0.000 unsupported"), ("R05", "b=0.308 d=0.462 contested"), ("A01", "b=0.120 d=0.000 unsupported"), ("C02", "b=0.991 d=0.003 established"), ("O03", "b=0.667 d=0.133 unsupported"), ("B02", "b=0.402 d=0.000 unsupported"), ("L02", "verdict unchanged without SUSTAIN 2: no")]
  ["oz.mechanistic: established -> unsupported", "oz.sitagliptin: contested -> unsupported", "ch.1974 chemiosmotic: established -> unsupported", "ch.1974 chemical intermediate: refuted -> unsupported", "ch.real1974 chemiosmotic: established -> unsupported", "thm oz.mech >= 0.8: true -> false"] true false
-- I both tables: PASS 20, FAIL 16, SILENT 10, INEXPRESSIBLE 5
#guard pinScheme calBo "PSFPSFFSFFPFPSFPPFPSPPFPFSISPFPPPPFIPSFFFFPISPSIPIP"
  [("K01", "b=0.947 d=0.000 established"), ("K02", "b=0.708 d=0.000 unsupported"), ("K03", "b=0.264 d=0.633 contested"), ("K04", "b=0.304 d=0.605 contested"), ("K05", "b=0.739 d=0.040 unsupported ; b=0.087 d=0.783 unsupported"), ("W01", "b=0.905 d=0.000 established"), ("W02", "b=0.471 d=0.480 contested"), ("W03", "b=0.206 d=0.738 unsupported"), ("W04", "b=0.616 d=0.333 contested"), ("W05", "b=0.434 d=0.434 contested"), ("W06", "b=0.554 d=0.342 contested"), ("W08", "b=0.000 d=0.869 refuted"), ("W09", "b=0.666 d=0.000 unsupported"), ("D01", "b=0.818 d=0.072 established"), ("D02", "b=0.444 d=0.000 unsupported"), ("D03", "b=0.960 d=0.000 established"), ("D04", "b=0.966 d=0.000 established"), ("D05", "b=0.018 d=0.888 refuted"), ("D06", "b=0.125 d=0.250 unsupported"), ("D07", "b=0.853 d=0.000 established"), ("R01", "b=0.364 d=0.364 contested"), ("R02", "b=0.222 d=0.445 unsupported"), ("R04", "b=0.668 d=0.000 unsupported"), ("R05", "b=0.308 d=0.462 contested"), ("CAL02", "rct within x2 of 30/39: yes ; observational within x2 of 1/6: yes"), ("A01", "b=0.120 d=0.000 unsupported"), ("A02", "b=0.769 d=0.000 unsupported"), ("A03", "b=0.460 d=0.414 contested"), ("T01", "b=0.814 d=0.000 established"), ("T02", "b=0.785 d=0.035 unsupported"), ("T03", "b=0.818 d=0.051 established"), ("C02", "b=0.991 d=0.003 established"), ("O01", "b=0.250 d=0.125 unsupported ; b=0.125 d=0.250 unsupported"), ("O02", "b=0.911 d=0.014 established ; b=0.014 d=0.911 refuted"), ("O03", "b=0.667 d=0.133 unsupported"), ("B02", "b=0.402 d=0.000 unsupported")]
  ["oz.mechanistic: established -> unsupported", "ch.1974 chemiosmotic: established -> unsupported", "ch.1974 chemical intermediate: refuted -> unsupported", "ch.real1974 chemiosmotic: established -> unsupported", "thm oz.main >= 0.95: true -> false", "thm oz.mech >= 0.8: true -> false"] true false
-- reviews weigh 0: PASS 17, FAIL 22, SILENT 7, INEXPRESSIBLE 5
#guard pinScheme calRev0 "PSFPPFFSFFFFPPFFPFPFSPFPFFISPFFPPFFIPSSFFFPIFPSIPIP"
  [("K01", "b=0.963 d=0.000 established"), ("K02", "b=0.614 d=0.000 unsupported"), ("K03", "b=0.364 d=0.579 contested"), ("D01", "b=0.863 d=0.095 established"), ("D03", "b=0.971 d=0.000 established"), ("D07", "b=0.666 d=0.000 unsupported"), ("T03", "b=0.727 d=0.181 unsupported")]
  ["oz.mechanistic: established -> unsupported", "oz.hypothalamus sign: + -> 0", "thm oz.mech >= 0.8: true -> false"] false false
-- N1 at import (undated): PASS 20, FAIL 21, SILENT 5, INEXPRESSIBLE 5
#guard pinScheme schN1imp "PPFPPFFSFFFFPPFFPFPFPPFPFFISPFFPPFFIPSSFFFPISPPIPIP"
  [("K05", "b=0.833 d=0.000 established ; b=0.000 d=0.900 refuted"), ("O01", "b=0.666 d=0.000 unsupported ; b=0.000 d=0.666 unsupported"), ("O02", "b=0.933 d=0.000 established ; b=0.000 d=0.933 refuted"), ("O03", "b=0.833 d=0.000 established")]
  ["ch.1965 chemiosmotic: contested -> unsupported", "ch.1965 chemical intermediate: contested -> unsupported", "ch.1965 chemiosmotic sign: 0 -> +", "ch.1965 chemical intermediate sign: 0 -> -", "thm ch.oneClaim never established: true -> false"] true true
-- H1+I+N1 at import (undated): PASS 24, FAIL 15, SILENT 8, INEXPRESSIBLE 4
#guard pinScheme schHINimp "PPFPPFFSFFPFPSFPPFPSPPFPSSPSPFPPPPFIPSFFFFPISPPIPIP"
  [("K01", "b=0.955 d=0.000 established"), ("K03", "b=0.404 d=0.538 contested"), ("K04", "b=0.421 d=0.542 contested"), ("K05", "b=0.833 d=0.000 established ; b=0.000 d=0.900 refuted"), ("W01", "b=0.905 d=0.000 established"), ("W02", "b=0.471 d=0.480 contested"), ("W03", "b=0.206 d=0.738 unsupported"), ("W04", "b=0.616 d=0.333 contested"), ("W05", "b=0.434 d=0.434 contested"), ("W06", "b=0.554 d=0.342 contested"), ("W08", "b=0.000 d=0.869 refuted"), ("W09", "b=0.666 d=0.000 unsupported"), ("D01", "b=0.411 d=0.411 contested"), ("D02", "b=0.444 d=0.000 unsupported"), ("D03", "b=0.963 d=0.000 established"), ("D04", "b=0.966 d=0.000 established"), ("D05", "b=0.000 d=0.905 refuted"), ("D06", "b=0.000 d=0.285 unsupported"), ("R01", "b=0.000 d=0.666 unsupported"), ("R02", "b=0.000 d=0.666 unsupported"), ("R03", "b=0.000 d=0.000 unsupported"), ("CAL02", "rct within x2 of 30/39: yes ; observational within x2 of 1/6: yes"), ("A02", "b=0.769 d=0.000 unsupported"), ("A03", "b=0.460 d=0.414 contested"), ("T01", "b=0.814 d=0.000 established"), ("T02", "b=0.785 d=0.035 unsupported"), ("T03", "b=0.818 d=0.051 established"), ("O01", "b=0.285 d=0.000 unsupported ; b=0.000 d=0.285 unsupported"), ("O02", "b=0.925 d=0.000 established ; b=0.000 d=0.925 refuted"), ("O03", "b=0.833 d=0.000 established"), ("B02", "b=0.000 d=0.000 unsupported")]
  ["ch.1965 chemiosmotic: contested -> unsupported", "ch.1965 chemical intermediate: contested -> unsupported", "ch.1965 chemiosmotic sign: 0 -> +", "ch.1965 chemical intermediate sign: 0 -> -", "thm ch.oneClaim never established: true -> false"] true false
-- outside core: H+E+D+B1+I+N1 at import (undated): PASS 26, FAIL 12, SILENT 10, INEXPRESSIBLE 3
#guard pinScheme schOutNimp "PPFPPPPFFFPFPSFPPFSSPPFPSSPSSFPPPPFIPSFFPSPPSPPIPIP"
  [("K01", "b=0.955 d=0.000 established"), ("K03", "b=0.404 d=0.538 contested"), ("K04", "b=0.421 d=0.542 contested"), ("K05", "b=0.833 d=0.000 established ; b=0.000 d=0.900 refuted"), ("W01", "b=0.285 d=0.000 unsupported"), ("W02", "b=0.049 d=0.826 refuted"), ("W03", "b=0.253 d=0.678 contested"), ("W04", "b=0.616 d=0.333 contested"), ("W05", "b=0.434 d=0.434 contested"), ("W06", "b=0.554 d=0.342 contested"), ("W08", "b=0.000 d=0.869 refuted"), ("W09", "b=0.583 d=0.000 unsupported"), ("D01", "b=0.411 d=0.411 contested"), ("D02", "b=0.166 d=0.000 unsupported"), ("D03", "b=0.958 d=0.000 established"), ("D04", "b=0.900 d=0.000 established"), ("D05", "b=0.000 d=0.375 unsupported"), ("D06", "b=0.000 d=0.285 unsupported"), ("R01", "b=0.000 d=0.666 unsupported"), ("R02", "b=0.000 d=0.666 unsupported"), ("R03", "b=0.000 d=0.000 unsupported"), ("R05", "b=0.200 d=0.600 unsupported"), ("CAL02", "rct within x2 of 30/39: yes ; observational within x2 of 1/6: yes"), ("A02", "b=0.769 d=0.000 unsupported"), ("A03", "b=0.453 d=0.420 contested"), ("T01", "b=0.814 d=0.000 established"), ("T02", "b=0.785 d=0.035 unsupported"), ("T03", "b=0.818 d=0.051 established"), ("C01", "b=0.681 d=0.000 unsupported"), ("C02", "b=0.517 d=0.241 unsupported"), ("C04", "IEA and EXP weigh differently: yes"), ("O01", "b=0.285 d=0.000 unsupported ; b=0.000 d=0.285 unsupported"), ("O02", "b=0.814 d=0.000 established ; b=0.000 d=0.814 refuted"), ("O03", "b=0.833 d=0.000 established"), ("B02", "b=0.000 d=0.000 unsupported")]
  ["ch.1965 chemiosmotic: contested -> unsupported", "ch.1965 chemical intermediate: contested -> unsupported", "ch.1965 chemiosmotic sign: 0 -> +", "ch.1965 chemical intermediate sign: 0 -> -", "thm ch.oneClaim never established: true -> false"] true false

/-! ### Sensitivity (section 4): each pseudo-count x2 and x1/2 -/
-- Example-check flips per run.
#guard sensExample == [("metaAnalysis x2", []),
    ("metaAnalysis x1/2", []),
    ("rct x2", []),
    ("rct x1/2", []),
    ("curatedDb x2", []),
    ("curatedDb x1/2", []),
    ("textbook x2", []),
    ("textbook x1/2", []),
    ("ontologyAxiom x2", []),
    ("ontologyAxiom x1/2", []),
    ("mechanistic x2", []),
    ("mechanistic x1/2", ["oz.mechanistic: established -> unsupported", "thm oz.mech >= 0.8: true -> false"]),
    ("review x2", []),
    ("review x1/2", ["oz.mechanistic: established -> unsupported", "thm oz.mech >= 0.8: true -> false"]),
    ("observational x2", []),
    ("observational x1/2", []),
    ("inVitro x2", []),
    ("inVitro x1/2", ["oz.mechanistic: established -> unsupported", "ch.1974 chemiosmotic: established -> unsupported", "ch.1974 chemical intermediate: refuted -> unsupported", "ch.real1974 chemiosmotic: established -> unsupported", "thm oz.mech >= 0.8: true -> false"]),
    ("textMined x2", []),
    ("textMined x1/2", []),
    ("hypothesis x2", []),
    ("hypothesis x1/2", []),
    ("crossSpecies x2", []),
    ("crossSpecies x1/2", []),
    ("definitional x2", []),
    ("definitional x1/2", [])]
-- Stress-set mark changes per run.
#guard sensStress == [("metaAnalysis x2", []),
    ("metaAnalysis x1/2", ["D05 PASS->SILENT"]),
    ("rct x2", ["W06 FAIL->PASS"]),
    ("rct x1/2", ["W03 SILENT->FAIL", "A02 FAIL->PASS"]),
    ("curatedDb x2", []),
    ("curatedDb x1/2", ["C03 PASS->SILENT"]),
    ("textbook x2", ["T02 SILENT->FAIL", "T03 SILENT->FAIL"]),
    ("textbook x1/2", ["T04 FAIL->PASS"]),
    ("ontologyAxiom x2", []),
    ("ontologyAxiom x1/2", []),
    ("mechanistic x2", ["R01 FAIL->SILENT"]),
    ("mechanistic x1/2", ["K02 PASS->SILENT"]),
    ("review x2", []),
    ("review x1/2", ["K02 PASS->SILENT"]),
    ("observational x2", ["W03 SILENT->FAIL"]),
    ("observational x1/2", ["W06 FAIL->PASS", "D02 FAIL->PASS", "D06 FAIL->SILENT", "O01 FAIL->SILENT"]),
    ("inVitro x2", ["R04 SILENT->PASS"]),
    ("inVitro x1/2", ["K02 PASS->SILENT", "K05 PASS->SILENT", "R01 FAIL->SILENT", "R02 FAIL->SILENT"]),
    ("textMined x2", ["CAL03 PASS->FAIL"]),
    ("textMined x1/2", []),
    ("hypothesis x2", []),
    ("hypothesis x1/2", []),
    ("crossSpecies x2", []),
    ("crossSpecies x1/2", []),
    ("definitional x2", []),
    ("definitional x1/2", [])]
-- For each kind: the factor nearest 1 below and above 1 at which an example check first flips,
-- and the grid factors at which an Ozempic sign flips.
#guard margins == [("metaAnalysis", none, none, []),
    ("rct", some (1/3 : ℚ), some (4 : ℚ), [(1/16 : ℚ)]),
    ("curatedDb", none, none, []),
    ("textbook", none, none, []),
    ("ontologyAxiom", none, none, []),
    ("mechanistic", some (4/5 : ℚ), some (4 : ℚ), [(4 : ℚ), (8 : ℚ), (16 : ℚ)]),
    ("review", some (9/10 : ℚ), none, []),
    ("observational", none, none, []),
    ("inVitro", some (9/10 : ℚ), some (4 : ℚ), []),
    ("textMined", none, none, []),
    ("hypothesis", none, none, []),
    ("crossSpecies", none, none, []),
    ("definitional", none, none, [])]
-- END GENERATED PINS

/-! ## 8. Printers (read by `scripts/stress/weights_cases.py`) -/

#eval IO.println ("\n".intercalate (pseudoCounts.map fun (n, c) => s!"PC\t{n}\t{c}"))
#eval do
  let base := results core
  IO.println ("\n".intercalate (base.map fun (x : Result) => s!"CASE\t{x.id}\t{x.obs}\t{x.mark.name}"))
  IO.println ("\n".intercalate (exBase.map fun ((n, v) : String × String) => s!"EXBASE\t{n}\t{v}"))
  for S in schemes do
    let r := results S
    let ex := exDiff S
    let (a, b) := exitAB (marksOf base) (marksOf r) ex
    IO.println s!"SCHEME\t{S.name}\t{marksOf r}\t{tallyOf r}\t{changesOf base r}"
    IO.println s!"SCHEMEEX\t{S.name}\t{ex.length}\t{ex}\tOzempic sign flips {(ozSigns ex).length}"
    IO.println s!"EXIT\t{S.name}\t{(tallyOf r).2.1}\t{(ozSigns ex).length}\t{a}\t{b}"
    for (x, y) in base.zip r do
      if x.obs != y.obs || x.mark != y.mark then IO.println s!"OBS\t{S.name}\t{y.id}\t{y.obs}\t{y.mark.name}"
#eval do
  IO.println ("\n".intercalate (sensExample.map fun ((n, d) : String × List String) => s!"SENSEX\t{n}\t{d.length}\t{d}"))
  IO.println ("\n".intercalate (sensStress.map fun ((n, d) : String × List String) => s!"SENSST\t{n}\t{d.length}\t{d}"))
  IO.println ("\n".intercalate (margins.map fun ((k, lo, hi, sg) : String × Option ℚ × Option ℚ × List ℚ) => s!"MARGIN\t{k}\t{lo}\t{hi}\t{sg}"))
#eval IO.println s!"L01\tF\t{l01}"

end BioLean.Proto.Weights

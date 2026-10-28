import BioLean.Derivation

/-!
# Generalisation (M4): DNA is transcribed to RNA in cellular organisms

Case study 4 (`docs/case-studies.md`; sketch `scripts/case_studies/transcription_generalize.py`)
in Lean. Each instance is "DNA-templated transcription has output RNA" with the subject refined by
`in_taxon`; `generalize` fuses the instances and discounts the result by how well their taxa cover
the target clade in the imported NCBITaxon hierarchy (`BioLean/Coverage.lean`).

Each instance rests on one curated-database item: the GO annotations of that taxon's gene products
to GO:0006351 or a descendant, counted on QuickGO on 2026-10-28. Many are electronic (IEA): E. coli
88 percent, yeast 36, human 63, Arabidopsis 52, Euglena 100, Paramecium 88, Halobacterium 76. IEA is
mostly inference from homology, itself a generalisation, so the instances are not fully independent;
that caveat applies to every fusion below.

The numbers, with the five model organisms of the case study (E. coli, yeast, mouse, human,
Arabidopsis; each instance at belief 4/5):

| target | children covered / known | bracketing | leaves covered / known | clade fraction | b, bracketing | b, clade fraction |
|---|---|---:|---|---:|---:|---:|
| cellular organisms | 2 / 3 | 2/3 | 5 / 44 | 5/44 | 0.634 | 0.108 |
| Eukaryota | 2 / 4 | 1/2 | 4 / 39 | 4/39 | 0.470 | 0.096 |
| Opisthokonta | 2 / 2 | 1 | 3 / 31 | 3/31 | 0.923 | 0.089 |
| Metazoa | 1 / 2 | 0 | 2 / 30 | 1/15 | 0 | 0.059 |

So with these five, bracketing does *not* establish "transcription in Eukaryota": the known
children of Eukaryota include Discoba (Euglena) and Sar (Paramecium), which are sampled by no
instance. Three more instances, one in each unsampled lineage (Euglena, Paramecium, Halobacterium),
bring both cellular organisms and Eukaryota to coverage 1 under bracketing; clade fraction moves
from 5/44 to 8/44. Bracketing says what to sample next; clade fraction mostly measures how
mammal-heavy biolib's vocabulary is (30 of its 44 known cellular leaves are animals).
-/

namespace BioLean.TranscriptionExample
open Rel Derivation Taxa Coverage

def transcription : Entity .process := ⟨"GO:0006351", "DNA-templated transcription"⟩
def reverseTranscription : Entity .process := ⟨"GO:0001171", "reverse transcription"⟩
def dna : Entity .chemical := ⟨"CHEBI:16991", "deoxyribonucleic acid"⟩
def rna : Entity .chemical := ⟨"CHEBI:33697", "ribonucleic acid"⟩

def ecoli       : Entity .taxon := ⟨"NCBITaxon:562", "Escherichia coli"⟩
def yeast       : Entity .taxon := ⟨"NCBITaxon:4932", "Saccharomyces cerevisiae"⟩
def arabidopsis : Entity .taxon := ⟨"NCBITaxon:3702", "Arabidopsis thaliana"⟩
def euglena     : Entity .taxon := ⟨"NCBITaxon:3038", "Euglena"⟩
def paramecium  : Entity .taxon := ⟨"NCBITaxon:5884", "Paramecium"⟩
def halobacterium : Entity .taxon := ⟨"NCBITaxon:2242", "Halobacterium salinarum"⟩
def opisthokonta : Entity .taxon := ⟨"NCBITaxon:33154", "Opisthokonta"⟩
def retroviridae : Entity .taxon := ⟨"NCBITaxon:11632", "Retroviridae"⟩
def viruses     : Entity .taxon := ⟨"NCBITaxon:10239", "Viruses"⟩

/-! ## Instances -/

/-- "... has output RNA": the predicate held fixed while the taxon widens. -/
def makesRNA : Predicate .process := .rel hasOutput rna

/-- QuickGO, 2026-10-28: annotations to GO:0006351 or a descendant, taxon and its descendants. -/
def quickGO : List (String × Nat) :=
  [(ecoli.curie, 10869), (yeast.curie, 5718), (mouse.curie, 32055), (human.curie, 38124),
   (arabidopsis.curie, 14286), (euglena.curie, 21), (paramecium.curie, 10499),
   (halobacterium.curie, 236)]

/-- The instance in taxon `t`: one curated item if QuickGO has annotations for `t`, else no
evidence at all (and so no belief). -/
def inst (t : Entity .taxon) : Statement where
  id := s!"transcription:{t.curie}"
  text := s!"DNA-templated transcription has output RNA in {t.label}"
  claim := makesRNA.claim (transcription.inCtx { taxon := some t })
  evidence := match quickGO.lookup t.curie with
    | some n => [{ pmid := 0, year := 2026, kind := .curatedDb, taxon := some t,
                   note := s!"{n} GO annotations to GO:0006351 or a descendant (QuickGO, 2026-10-28)" }]
    | none => []

/-- "Transcription has output RNA in `T`", generalised from the instances in `taxa`. -/
abbrev Universal (T : Entity .taxon) : Claim := makesRNA.claim (transcription.inCtx { taxon := some T })

/-- Generalise from `taxa` to `T` under measure `m`. `h` is decided: every taxon must be is_a `T`. -/
def gen (T : Entity .taxon) (m : Measure) (taxa : List (Entity .taxon))
    (h : admissible T taxa = true := by decide +kernel) : Derivation (Universal T) :=
  .generalize makesRNA {} T m taxa (fun i => .lit (inst taxa[i])) h

/-- The five model organisms of the case study, and three more in the lineages they miss. -/
def five : List (Entity .taxon) := [ecoli, yeast, mouse, human, arabidopsis]
def eight : List (Entity .taxon) := five ++ [euglena, paramecium, halobacterium]

-- every instance passes the taxon lint (its evidence taxon is the claim's taxon)
#guard eight.all fun t => (inst t).taxonConsistent

/-! ## Five model organisms -/

/-- Cellular organisms, bracketing: Bacteria and Eukaryota sampled, Archaea not, so 2/3 of
0.952. Unsupported, though far above clade fraction. -/
def cellular_b := gen cellularOrganisms .bracketing five
/-- Cellular organisms, clade fraction: 5 of 44 known leaves. -/
def cellular_c := gen cellularOrganisms .cladeFraction five

theorem cellular_bracketing_value : cellular_b.opinion.belief = 40 / 63 := by decide +kernel
theorem cellular_bracketing_reaches : 3 / 5 ≤ cellular_b.opinion.belief := by
  rw [cellular_bracketing_value]; norm_num
theorem cellular_bracketing_unsupported : cellular_b.verdict = .unsupported := by decide +kernel
theorem cellular_clade_value : cellular_c.opinion.belief = 25 / 231 := by decide +kernel
theorem cellular_clade_reaches : 1 / 10 ≤ cellular_c.opinion.belief := by
  rw [cellular_clade_value]; norm_num
theorem cellular_clade_unsupported : cellular_c.verdict = .unsupported := by decide +kernel

/-- Eukaryota, bracketing: Opisthokonta and Viridiplantae of four known children, so 1/2 of 0.941.
The expectation that five model organisms establish Eukaryota at 7/10 is false. -/
def eukaryota_b := gen eukaryota .bracketing [yeast, mouse, human, arabidopsis]

theorem eukaryota_bracketing_value : eukaryota_b.opinion.belief = 8 / 17 := by decide +kernel
theorem eukaryota_bracketing_short : eukaryota_b.opinion.belief < 7 / 10 := by
  rw [eukaryota_bracketing_value]; norm_num

/-- Opisthokonta, bracketing: Fungi (yeast) and Metazoa (mouse, human) are both its known
children, so coverage 1 and the instances count in full. Established. -/
def opisthokonta_b := gen opisthokonta .bracketing [yeast, mouse, human]

theorem opisthokonta_established : 7 / 10 ≤ opisthokonta_b.opinion.belief := by decide +kernel
theorem opisthokonta_verdict : opisthokonta_b.verdict = .established := by decide +kernel

/-- Metazoa, bracketing: mouse and human both sit under Eumetazoa, so nothing is bracketed
(Porifera unsampled) and belief is 0. Bracketing has a cliff where clade fraction has a slope. -/
def metazoa_b := gen metazoa .bracketing [mouse, human]

theorem metazoa_bracketing_zero : metazoa_b.opinion.belief = 0 := by decide +kernel

/-! ## Eight: one more instance in each lineage the five miss -/

def cellular8_b := gen cellularOrganisms .bracketing eight
def cellular8_c := gen cellularOrganisms .cladeFraction eight
def eukaryota6_b := gen eukaryota .bracketing [yeast, mouse, human, arabidopsis, euglena, paramecium]

theorem cellular8_established : Established (Universal cellularOrganisms) (4 / 5) :=
  ⟨cellular8_b, by decide +kernel⟩
theorem cellular8_bracketing_value : cellular8_b.opinion.belief = 32 / 33 := by decide +kernel
theorem cellular8_clade_value : cellular8_c.opinion.belief = 64 / 363 := by decide +kernel
theorem eukaryota6_established : 7 / 10 ≤ eukaryota6_b.opinion.belief := by decide +kernel

-- the generalisation rests on exactly its instances
example : cellular8_b.axioms.map (·.id) = eight.map fun t => s!"transcription:{t.curie}" := by decide +kernel

/-! ## The retroviral exception stops at the context boundary

Reverse transcription makes DNA from RNA in retroviruses. That refutes "information flows only
DNA → RNA → protein" but cannot touch transcription in cellular organisms: the instance's taxon is
not is_a the target, so it cannot enter a generalisation to cellular organisms at all. -/

def makesDNA : Predicate .process := .rel hasOutput dna

def retroInst : Statement where
  id := "reverse-transcription:NCBITaxon:11632"
  text := "Reverse transcription has output DNA in Retroviridae"
  claim := makesDNA.claim (reverseTranscription.inCtx { taxon := some retroviridae })
  evidence := [{ pmid := 0, year := 2026, kind := .curatedDb, taxon := some retroviridae,
                 note := "3 GO annotations to GO:0001171 in Retroviridae (QuickGO, 2026-10-28)" }]

-- Retroviridae is_a Viruses, so the derivation is well formed with Viruses as the target...
example : Derivation (makesDNA.claim (reverseTranscription.inCtx { taxon := some viruses })) :=
  .generalize makesDNA {} viruses .bracketing [retroviridae] (fun | 0 => .lit retroInst)
-- ...and refused with cellular organisms as the target: Retroviridae is not is_a 131567.
#check_failure (Derivation.generalize makesDNA {} cellularOrganisms .bracketing [retroviridae]
  (fun | 0 => .lit retroInst) :
  Derivation (makesDNA.claim (reverseTranscription.inCtx { taxon := some cellularOrganisms })))
-- Nor can a virus slip into the transcription generalisation alongside cellular instances.
#check_failure (gen cellularOrganisms .bracketing [ecoli, retroviridae])
-- One taxon brackets nothing: generalising Retroviridae to Viruses gives belief 0.
example : (Derivation.generalize makesDNA {} viruses .bracketing [retroviridae]
    (fun | 0 => .lit retroInst) :
    Derivation (makesDNA.claim (reverseTranscription.inCtx { taxon := some viruses }))).opinion.belief = 0 := by
  decide +kernel

/-! ## The table -/

/-- One target and sample: coverage under both measures and the generalised belief. Only the
sampled taxa that are is_a the target enter. -/
def row (T : Entity .taxon) (sample : List (Entity .taxon)) : String :=
  let taxa := sample.filter (Taxa.isA ·.curie T.curie)
  let s := taxa.filterMap (Curie.encode ·.curie)
  let b (m : Measure) : String :=
    if h : admissible T taxa = true then (gen T m taxa h).opinion.belief.toDecimal else "-"
  match Curie.encode T.curie with
  | none => s!"{T.label}: not a known taxon"
  | some t =>
    s!"| {T.label} | {taxa.length} | {(covered t s).length} / {(Ontology.children t).length} | " ++
    s!"{Measure.bracketing.eval T taxa} | {((leaves t).filter (s.flatMap (leaves ·)).contains).length} / " ++
    s!"{(leaves t).length} | {Measure.cladeFraction.eval T taxa} | {b .bracketing} | {b .cladeFraction} |"

def table : String :=
  let head := "| target | sampled | children covered / known | bracketing | leaves covered / known | clade fraction | b, bracketing | b, clade fraction |\n|---|---:|---|---:|---|---:|---:|---:|"
  let rows (sample : List (Entity .taxon)) :=
    [cellularOrganisms, eukaryota, opisthokonta, metazoa].map (row · sample) |> String.intercalate "\n"
  s!"five model organisms\n{head}\n{rows five}\n\nplus Euglena, Paramecium, Halobacterium\n{head}\n{rows eight}"

#eval IO.println table
#eval IO.println cellular_b.report

end BioLean.TranscriptionExample

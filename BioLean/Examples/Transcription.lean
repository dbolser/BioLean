import BioLean.Derivation

/-!
# Generalisation (M4): DNA is transcribed to RNA in cellular organisms

Case study 4 (`docs/case-studies.md`; sketch `scripts/case_studies/transcription_generalize.py`)
in Lean. Each instance is "DNA-templated transcription has output RNA" with the subject refined by
`in_taxon`; `generalize` fuses the instances and discounts the result by how well their taxa cover
the target clade in the imported NCBITaxon hierarchy (`BioLean/Coverage.lean`).

Each instance rests on one curated-database item: the GO annotations of that taxon's gene products
to GO:0006351 or a descendant, counted on QuickGO on 2026-10-28. QuickGO's default descendants also
follow `regulates`, so most of each count is regulation of transcription. Many are electronic (IEA):
E. coli 88 percent, yeast 36, human 63, Arabidopsis 52, Euglena 100, Paramecium 88, Halobacterium 76.
IEA is mostly inference from homology, itself a generalisation, so the instances are not fully
independent; that caveat applies to every fusion below. Euglena, Paramecium and Halobacterium have no
experimental annotation at all (`docs/programs/01-universals-and-descent.md`, section 2).

The numbers (from `table` below; each instance at belief 4/5, and only the sampled taxa under the
target enter). Children are NCBI's (`Ontology.targets`, bins left out); leaves are biolib's.

| target | sampled | children covered / NCBI | bracketing | leaves covered / known | clade fraction | b, bracketing | b, clade fraction |
|---|---:|---|---:|---|---:|---:|---:|
| *five model organisms* | | | | | | | |
| cellular organisms | 5 | 2 / 3 | 2/3 | 5 / 71 | 5/71 | 0.634 | 0.067 |
| Eukaryota | 4 | 2 / 18 | 1/9 | 4 / 60 | 1/15 | 0.104 | 0.062 |
| Opisthokonta | 3 | 2 / 6 | 1/3 | 3 / 36 | 1/12 | 0.307 | 0.076 |
| Metazoa | 2 | 1 / 2 | 1/512 | 2 / 31 | 2/31 | 0.001 | 0.057 |
| *plus Euglena, Paramecium, Halobacterium* | | | | | | | |
| cellular organisms | 8 | 3 / 3 | 1 | 8 / 71 | 8/71 | 0.969 | 0.109 |
| Eukaryota | 6 | 4 / 18 | 2/9 | 6 / 60 | 1/10 | 0.213 | 0.096 |

(Opisthokonta and Metazoa do not move: the three added taxa are not opisthokonts.)

Counted against NCBI's children the numbers drop, as they should. Against biolib's own vocabulary
Eukaryota had 4 children and Opisthokonta 2, so five model organisms gave Eukaryota 1/2 and
established Opisthokonta; against NCBI's 18 and 6 they give 1/9 and 1/3. Bracketing establishes a
clade (belief 4/5) only once at least four fifths of its children are sampled, more when instances
are few: all 3 for cellular organisms, 5 or 6 of 6 for Opisthokonta, 15 of 18 for Eukaryota. A
sample in one child never gets there (at most `1 / #children`); the recursion turns the old cliff
(mouse and human gave Metazoa 0) into a steep slope (1/512, halving at each of nine two-child splits
down to Euarchontoglires, where Glires and Primates bracket). The top-level ratio counts a sampled
child as covered however thinly, so a broad target can beat a narrow one inside it: with all eight,
cellular organisms is established at 0.97 while Eukaryota sits at 0.21 (`cellular_above_eukaryota`).
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

/-- QuickGO, 2026-10-28: annotations to GO:0006351 or a descendant (QuickGO's default, which also
follows `regulates`), taxon and its descendants. -/
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

/-- Cellular organisms: Bacteria and Eukaryota sampled, Archaea not, so 2/3 of 0.952 under
bracketing, 5 of 71 known leaves under clade fraction. Unsupported either way. -/
def cellular_b := gen cellularOrganisms .bracketing five
def cellular_c := gen cellularOrganisms .cladeFraction five

theorem cellular_bracketing_value : cellular_b.opinion.belief = 40 / 63 := by decide +kernel
theorem cellular_bracketing_reaches : 3 / 5 ≤ cellular_b.opinion.belief := by
  rw [cellular_bracketing_value]; norm_num
theorem cellular_bracketing_unsupported : cellular_b.verdict = .unsupported := by decide +kernel
theorem cellular_clade_value : cellular_c.opinion.belief = 100 / 1491 := by decide +kernel
theorem cellular_clade_unsupported : cellular_c.verdict = .unsupported := by decide +kernel

/-- Eukaryota: yeast, mouse, human and Arabidopsis sit in Opisthokonta and Viridiplantae, 2 of its
18 NCBI children, so 1/9 of 0.941. Against biolib's 4 known children this was 1/2. -/
def euk4 : List (Entity .taxon) := [yeast, mouse, human, arabidopsis]
def eukaryota_b := gen eukaryota .bracketing euk4
def eukaryota_c := gen eukaryota .cladeFraction euk4

theorem eukaryota_bracketing_value : eukaryota_b.opinion.belief = 16 / 153 := by decide +kernel
theorem eukaryota_bracketing_short : eukaryota_b.opinion.belief < 1 / 9 := by
  rw [eukaryota_bracketing_value]; norm_num
theorem eukaryota_clade_value : eukaryota_c.opinion.belief = 16 / 255 := by decide +kernel

/-- Opisthokonta: Fungi (yeast) and Metazoa (mouse, human) of 6 NCBI children; Choanoflagellata,
Ichthyosporea, Filasterea and Rotosphaerida are unsampled. So 1/3 of 0.923: no longer established. -/
def opisthokonta_b := gen opisthokonta .bracketing [yeast, mouse, human]
def opisthokonta_c := gen opisthokonta .cladeFraction [yeast, mouse, human]

theorem opisthokonta_bracketing_value : opisthokonta_b.opinion.belief = 4 / 13 := by decide +kernel
theorem opisthokonta_unsupported : opisthokonta_b.verdict = .unsupported := by decide +kernel
theorem opisthokonta_clade_value : opisthokonta_c.opinion.belief = 1 / 13 := by decide +kernel

/-- Metazoa: mouse and human both sit under Eumetazoa, so nothing is bracketed at Metazoa (Porifera
unsampled). Bracketing follows the one sampled lineage down to the first split it brackets,
Euarchontoglires, halving at nine two-child splits on the way: 1/512 of 0.889, where it was 0. -/
def metazoa_b := gen metazoa .bracketing [mouse, human]

theorem metazoa_bracketing_value : metazoa_b.opinion.belief = 1 / 576 := by decide +kernel
theorem metazoa_bracketing_pos : 0 < metazoa_b.opinion.belief := by
  rw [metazoa_bracketing_value]; norm_num

/-! ## Eight: one more instance in each lineage the five miss -/

def cellular8_b := gen cellularOrganisms .bracketing eight
def cellular8_c := gen cellularOrganisms .cladeFraction eight
def euk6 : List (Entity .taxon) := euk4 ++ [euglena, paramecium]
def eukaryota6_b := gen eukaryota .bracketing euk6
def eukaryota6_c := gen eukaryota .cladeFraction euk6

theorem cellular8_established : Established (Universal cellularOrganisms) (4 / 5) :=
  ⟨cellular8_b, by decide +kernel⟩
theorem cellular8_bracketing_value : cellular8_b.opinion.belief = 32 / 33 := by decide +kernel
theorem cellular8_clade_value : cellular8_c.opinion.belief = 256 / 2343 := by decide +kernel
theorem eukaryota6_bracketing_value : eukaryota6_b.opinion.belief = 16 / 75 := by decide +kernel
theorem eukaryota6_unsupported : eukaryota6_b.verdict = .unsupported := by decide +kernel
theorem eukaryota6_clade_value : eukaryota6_c.opinion.belief = 12 / 125 := by decide +kernel

/-- Bracketing is not monotone in the target: from the same instances, "in cellular organisms" is
believed more than the narrower "in Eukaryota" that it entails, because a sampled child of
cellular organisms counts as covered however thinly it is sampled inside. -/
theorem cellular_above_eukaryota : eukaryota6_b.opinion.belief < cellular8_b.opinion.belief := by
  rw [eukaryota6_bracketing_value, cellular8_bracketing_value]; norm_num

-- adding the eight instances one at a time never lowers coverage, under either measure, for any
-- of the four targets (`Coverage.Measure.eval_mono` proves this for every sample)
#guard [cellularOrganisms, eukaryota, opisthokonta, metazoa].all fun T =>
  [Measure.bracketing, .cladeFraction].all fun m =>
    let cs := (List.range (eight.length + 1)).map fun k => m.eval T (eight.take k)
    (cs.zip cs.tail).all fun (a, b) => a ≤ b

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
  let head := "| target | sampled | children covered / NCBI | bracketing | leaves covered / known | clade fraction | b, bracketing | b, clade fraction |\n|---|---:|---|---:|---|---:|---:|---:|"
  let rows (sample : List (Entity .taxon)) :=
    [cellularOrganisms, eukaryota, opisthokonta, metazoa].map (row · sample) |> String.intercalate "\n"
  s!"five model organisms\n{head}\n{rows five}\n\nplus Euglena, Paramecium, Halobacterium\n{head}\n{rows eight}"

#eval IO.println table
#eval IO.println cellular_b.report

end BioLean.TranscriptionExample

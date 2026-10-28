import BioLean.Derivation

/-!
# Quantity (M3): textbook counting sentences as theorems

The counting derivations from `docs/textbook-derivations.md` (T21, T25, T26, T27, T31, T32, T34)
and the one clash the closure search found (most neurons vs some neurons). Numbers are exact;
the arithmetic side goals are discharged by `decide` or `norm_num` when the term is built.
-/

namespace BioLean.Quantity
open Derivation

def tb (note : String) : Evidence := { pmid := 0, year := 2013, kind := .textbook, note := note }

-- entities (CURIEs verified on OLS4 unless marked local)
def codon         : Entity .gene      := ⟨"SO:0000360", "codon"⟩
def senseCodon    : Entity .gene      := ⟨"BIOLEAN:sense_codon", "sense codon (no SO term)"⟩
def nucleotide    : Entity .chemical  := ⟨"CHEBI:36976", "nucleotide"⟩
def nucleobase    : Entity .chemical  := ⟨"CHEBI:18282", "nucleobase"⟩
def aminoAcid     : Entity .chemical  := ⟨"CHEBI:33709", "amino acid"⟩
def glycolysis    : Entity .process   := ⟨"GO:0006096", "glycolytic process"⟩
def atp           : Entity .chemical  := ⟨"CHEBI:15422", "ATP"⟩
def chromosome    : Entity .component := ⟨"GO:0005694", "chromosome"⟩
def chromosomeSet : Entity .component := ⟨"BIOLEAN:chromosome_set", "chromosome set (no GO term)"⟩
/-- "Somatic cell" (CL:0002371) is obsolete and its replacement, "cell", loses the meaning. A cell with
46 chromosomes in two sets is a diploid cell. -/
def diploidCell   : Entity .cellType  := ⟨"CL:0000415", "diploid cell"⟩
def eggCell       : Entity .cellType  := ⟨"CL:0000025", "egg cell"⟩
def sperm         : Entity .cellType  := ⟨"CL:0000019", "sperm"⟩
def zygote        : Entity .cellType  := ⟨"CL:0000365", "animal zygote"⟩
def fertilization : Entity .process   := ⟨"GO:0009566", "fertilization"⟩
def prokaryoticCell : Entity .cellType := ⟨"CL:0000520", "prokaryotic cell"⟩
def eukaryoticCell  : Entity .cellType := ⟨"CL:0000255", "eukaryotic cell"⟩
def diameter      : Entity .phenotype := ⟨"PATO:0001334", "diameter"⟩
def neuron        : Entity .cellType  := ⟨"CL:0000540", "neuron"⟩
def axon          : Entity .component := ⟨"GO:0030424", "axon"⟩
def alveolarSac   : Entity .anatomy   := ⟨"UBERON:0002169", "alveolar sac"⟩
def alveolus      : Entity .anatomy   := ⟨"UBERON:0002299", "alveolus of lung"⟩
def smallIntestine : Entity .anatomy  := ⟨"UBERON:0002108", "small intestine"⟩
def length        : Entity .phenotype := ⟨"PATO:0000122", "length"⟩

/-! ### T31: four bases, three per codon, 64 codons -/
def S_bases : Statement := ⟨"molbio:m45473-113", "DNA has four nitrogenous bases", .cardinality nucleobase 4, [tb "OpenStax 9.1"]⟩
def S_codon3 : Statement := ⟨"molbio:m45479-41", "each codon is three nucleotides", .count codon nucleobase 3, [tb "OpenStax 9.4"]⟩
def codons64 : Derivation (.cardinality codon 64) := sequencesOver (.lit S_bases) (.lit S_codon3)

/-! ### T32: 61 sense codons onto 20 amino acids, so some amino acid has several codons -/
def S_sense61 : Statement := ⟨"molbio:m45479-46", "61 codons specify amino acids", .cardinality senseCodon 61, [tb "OpenStax 9.4"]⟩
def S_aa20 : Statement := ⟨"molbio:m45479-92", "there are 20 amino acids", .cardinality aminoAcid 20, [tb "OpenStax 9.4"]⟩
def S_oneEach : Statement := ⟨"molbio:m45479-45", "each codon specifies one amino acid", .count senseCodon aminoAcid 1, [tb "OpenStax 9.4"]⟩
/-- The book says "more than one codon corresponds to a given amino acid". The proof gives the
existential, which is what the premises support: SOME amino acid has at least two codons. -/
def degeneracy : Derivation (.quant .some (.atLeast aminoAcid senseCodon 2)) :=
  pigeonhole (.lit S_sense61) (.lit S_aa20) (.lit S_oneEach)

/-! ### T21: glycolysis makes 4 ATP, invests 2, nets 2 -/
def S_made4 : Statement := ⟨"energy:m45438-56", "glycolysis produces four ATP", .produces glycolysis atp 4, [tb "OpenStax 4.2"]⟩
def S_used2 : Statement := ⟨"energy:m45438-57", "glycolysis uses two ATP", .consumes glycolysis atp 2, [tb "OpenStax 4.2"]⟩
def net2 : Derivation (.yield glycolysis atp 2) := netYield (.lit S_made4) (.lit S_used2)

/-! ### T25: 46 chromosomes in two sets is 23 per set -/
def S_46 : Statement := ⟨"repro:m45455-17", "human somatic cells have 46 chromosomes", .count diploidCell chromosome 46, [tb "OpenStax 6.1 (human context not yet expressible)"]⟩
def S_2sets : Statement := ⟨"repro:m45455-18", "somatic cells carry two sets", .count diploidCell chromosomeSet 2, [tb "OpenStax 6.1"]⟩
def perSet23 : Derivation (.count chromosomeSet chromosome 23) := perSet (.lit S_46) (.lit S_2sets)

/-! ### T26 / T27: fusion adds sets -/
def S_fertIn1 : Statement := ⟨"inherit:m45466-3", "fertilization takes an egg", .rel Rel.hasInput fertilization eggCell, [tb "OpenStax 7.1"]⟩
def S_fertIn2 : Statement := ⟨"inherit:m45466-3b", "fertilization takes a sperm", .rel Rel.hasInput fertilization sperm, [tb "OpenStax 7.1"]⟩
def S_fertOut : Statement := ⟨"inherit:m45466-6", "fertilization yields a zygote", .rel Rel.hasOutput fertilization zygote, [tb "OpenStax 7.1"]⟩
def S_egg1 : Statement := ⟨"inherit:m45466-5", "an egg is haploid", .count eggCell chromosomeSet 1, [tb "OpenStax 7.1"]⟩
def S_sperm1 : Statement := ⟨"inherit:m45465-57", "a sperm is haploid", .count sperm chromosomeSet 1, [tb "OpenStax 7.1"]⟩
def diploidZygote : Derivation (.count zygote chromosomeSet 2) :=
  fusionAdds (.lit S_fertIn1) (.lit S_fertIn2) (.lit S_fertOut) (.lit S_egg1) (.lit S_sperm1)
/-- T27 with an abnormal diploid egg: the same rule gives a triploid zygote. -/
def S_egg2 : Statement := ⟨"inherit:m45467-79", "a nondisjunction egg carries two sets", .count eggCell chromosomeSet 2, [tb "OpenStax 7.2"]⟩
def triploidZygote : Derivation (.count zygote chromosomeSet 3) :=
  fusionAdds (.lit S_fertIn1) (.lit S_fertIn2) (.lit S_fertOut) (.lit S_egg2) (.lit S_sperm1)

/-! ### T34: prokaryotes 0.1 to 5 µm, eukaryotes 10 to 100 µm -/
def S_prokSize : Statement := ⟨"cell:m45429-44", "prokaryotic cells are 0.1 to 5.0 µm across", .measure prokaryoticCell diameter (1/10) 5 "µm", [tb "OpenStax 3.2"]⟩
def S_eukSize : Statement := ⟨"cell:m45429-45", "eukaryotic cells are 10 to 100 µm across", .measure eukaryoticCell diameter 10 100 "µm", [tb "OpenStax 3.2"]⟩
def prokSmaller : Derivation (.less prokaryoticCell eukaryoticCell diameter) :=
  compareIntervals (.lit S_prokSize) (.lit S_eukSize)

/-! ### Ranges and open ends: no rule uses these yet -/
def S_alveoli : Statement := ⟨"body:m45536-65", "each alveolar sac contains 20 to 30 alveoli", .countBetween alveolarSac alveolus 20 30, [tb "OpenStax, module m45536"]⟩
def S_intestine : Statement := ⟨"body:m45535-104", "the human small intestine is over 6 m long", .atLeastMeasure (smallIntestine.inCtx { taxon := some Taxa.human }) length 6 "m", [tb "OpenStax, module m45535"]⟩

/-! ### The closure's clash, dissolved by quantifiers -/
def S_mostAxons : Statement := ⟨"body:m45539-323", "most neurons contain axons", .quant .most (.rel Rel.hasPart neuron axon), [tb "OpenStax 16.1"]⟩
def S_someNoAxon : Statement := ⟨"body:m45539-109", "some neurons contain no axons", .quant .some (.notRel Rel.hasPart neuron axon), [tb "OpenStax 16.1"]⟩
-- These two are different claims and no rule connects them, so no clash is derivable. A universal
-- "every neuron has an axon" would clash with the second via `notRelSub`; the book does not say it.

/-! ### Checked -/
theorem codons_64 : Established (.cardinality codon 64) (7/10) := ⟨codons64, by decide +kernel⟩
theorem code_is_degenerate : Established (.quant .some (.atLeast aminoAcid senseCodon 2)) (7/10) :=
  ⟨degeneracy, by decide +kernel⟩
theorem glycolysis_nets_two : Established (.yield glycolysis atp 2) (7/10) := ⟨net2, by decide +kernel⟩
theorem haploid_is_23 : Established (.count chromosomeSet chromosome 23) (7/10) := ⟨perSet23, by decide +kernel⟩
theorem zygote_diploid : Established (.count zygote chromosomeSet 2) (7/10) := ⟨diploidZygote, by decide +kernel⟩
theorem zygote_triploid : Established (.count zygote chromosomeSet 3) (7/10) := ⟨triploidZygote, by decide +kernel⟩
theorem prokaryotes_smaller : Established (.less prokaryoticCell eukaryoticCell diameter) (7/10) :=
  ⟨prokSmaller, by decide +kernel⟩

-- The arithmetic is checked when the term is built: this does not compile.
-- def wrong : Derivation (.cardinality codon 65) := sequencesOver (.lit S_bases) (.lit S_codon3)

#eval IO.println degeneracy.report
#eval IO.println diploidZygote.report

end BioLean.Quantity

import BioLean.Ontology
import BioLean.Ontology.IsA

/-!
# Taxa

Named NCBITaxon constants, and is_a between taxa read from the imported NCBITaxon hierarchy
(`BioLean/Ontology/IsA.lean`: every taxon biolib uses, with all its ancestors, from OLS4). Enough for
`Derivation.transport` to tell siblings from ancestors and for `Statement.taxonConsistent`.
-/

namespace BioLean.Taxa

def cellularOrganisms : Entity .taxon := ⟨"NCBITaxon:131567", "cellular organisms"⟩
def bacteria      : Entity .taxon := ⟨"NCBITaxon:2", "Bacteria"⟩
def archaea       : Entity .taxon := ⟨"NCBITaxon:2157", "Archaea"⟩
def eukaryota     : Entity .taxon := ⟨"NCBITaxon:2759", "Eukaryota"⟩
def viridiplantae : Entity .taxon := ⟨"NCBITaxon:33090", "Viridiplantae"⟩
def fungi         : Entity .taxon := ⟨"NCBITaxon:4751", "Fungi"⟩
def metazoa       : Entity .taxon := ⟨"NCBITaxon:33208", "Metazoa"⟩
def vertebrata    : Entity .taxon := ⟨"NCBITaxon:7742", "Vertebrata"⟩
def mammalia      : Entity .taxon := ⟨"NCBITaxon:40674", "Mammalia"⟩
def human         : Entity .taxon := ⟨"NCBITaxon:9606", "Homo sapiens"⟩
def mouse         : Entity .taxon := ⟨"NCBITaxon:10090", "Mus musculus"⟩
def rat           : Entity .taxon := ⟨"NCBITaxon:10116", "Rattus norvegicus"⟩

/-- The ontology code of NCBITaxon. -/
def code : Nat := 4
theorem code_eq : Curie.prefixes.idxOf? "NCBITaxon" = some code := by decide

/-- Reflexive-transitive is_a between taxon curies, over the imported hierarchy. -/
def isA (a b : String) : Bool := Ontology.isACurie a b

/-- Is the taxon in the imported NCBITaxon closure? Refined taxa (aged mouse) are not. -/
def known (t : Entity .taxon) : Bool :=
  match Curie.encode t.curie with
  | some c => c.1 == code && Ontology.known c
  | none => false

/-- Two known taxa, neither is_a the other: mouse and human, not mouse and Mammalia. Unknown or
refined taxa are never siblings, so `transport` fails safe. -/
def siblings (a b : Entity .taxon) : Bool :=
  known a && known b && !isA a.curie b.curie && !isA b.curie a.curie

end BioLean.Taxa

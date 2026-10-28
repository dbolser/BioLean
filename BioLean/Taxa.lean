import BioLean.Ontology

/-!
# A pinned taxon is_a table

A small hand table of NCBITaxon lineages (abridged: intermediate ranks are skipped), enough for
`Derivation.transport` to tell siblings from ancestors and for `Statement.taxonConsistent`. Import
the NCBITaxon is_a data, as `RO.lean` does for RO, when more taxa are needed.
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

/-- `(child, parent)` edges. -/
def edges : List (Entity .taxon × Entity .taxon) := [
  (bacteria, cellularOrganisms), (archaea, cellularOrganisms), (eukaryota, cellularOrganisms),
  (viridiplantae, eukaryota), (fungi, eukaryota), (metazoa, eukaryota),
  (vertebrata, metazoa), (mammalia, vertebrata),
  (human, mammalia), (mouse, mammalia), (rat, mammalia)]

/-- Reflexive-transitive is_a over `edges`, by curie. -/
def isA (a b : String) (fuel : Nat := edges.length) : Bool :=
  a == b || match fuel with
    | 0 => false
    | n + 1 => edges.any fun (c, p) => c.curie == a && isA p.curie b n

/-- Is the taxon in the table? Refined taxa (aged mouse) are not. -/
def known (t : Entity .taxon) : Bool :=
  t == cellularOrganisms || edges.any (·.1 == t)

/-- Two known taxa, neither is_a the other: mouse and human, not mouse and Mammalia. Unknown or
refined taxa are never siblings, so `transport` fails safe. -/
def siblings (a b : Entity .taxon) : Bool :=
  known a && known b && !isA a.curie b.curie && !isA b.curie a.curie

end BioLean.Taxa

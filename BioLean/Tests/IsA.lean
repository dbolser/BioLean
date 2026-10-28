import BioLean.Taxa

/-!
# Tests for the imported is_a closure

`BioLean/Ontology/IsA.lean` is the is_a ancestor closure of every CURIE biolib uses. These pin a
few chains from each ontology, the sibling test that `transport` relies on, and the size of the
import. Each is_a `decide` takes under a second (Meta and kernel); the two counts take 4 and 6
seconds in the kernel. Nothing needs `native_decide`.
-/

namespace BioLean.IsA.Tests
open Ontology Taxa

-- curies to codes
example : Curie.encode "GO:0006096" = some (0, 6096) := by decide
example : Curie.encode "NCBITaxon:10090" = some (4, 10090) := by decide
example : Curie.encode "NCBITaxon:10090&RO:0002573=(BLN:aged)" = none := by decide  -- refined
example : Curie.encode "PR:P01308" = none := by decide                               -- not numeric
example : Curie.encode "BLN:aged" = none := by decide                                -- unknown prefix

-- taxa: mouse is_a Mammalia is_a Eukaryota, and mouse and human are siblings
example : Taxa.isA mouse.curie mammalia.curie = true := by decide
example : Taxa.isA mammalia.curie eukaryota.curie = true := by decide
example : Taxa.isA mouse.curie eukaryota.curie = true := by decide
example : siblings mouse human = true := by decide
example : siblings mouse rat = true := by decide
example : Taxa.isA mammalia.curie mouse.curie = false := by decide       -- not downward
example : Taxa.isA mouse.curie viridiplantae.curie = false := by decide  -- not across
example : label? (4, 862507) = some "Mus <subgenus>" := by decide        -- a rank the old table skipped

-- CL: hepatocyte is_a cell
example : isACurie "CL:0000182" "CL:0000000" = true := by decide
example : isACurie "CL:0000182" "CL:0000540" = false := by decide        -- not a neuron
-- GO BP: glycolytic process is_a carbohydrate metabolic process
example : isACurie "GO:0006096" "GO:0005975" = true := by decide
example : isACurie "GO:0005975" "GO:0006096" = false := by decide
-- GO CC: nucleus is_a organelle
example : isACurie "GO:0005634" "GO:0043226" = true := by decide
example : isACurie "GO:0005634" "GO:0005737" = false := by decide        -- not cytoplasm
-- UBERON: liver is_a anatomical entity; ChEBI: glucose is_a carbohydrate (both via long chains)
example : isACurie "UBERON:0002107" "UBERON:0001062" = true := by decide
example : isACurie "CHEBI:17234" "CHEBI:16646" = true := by decide
-- the deepest DAG in the closure, AMP (417 paths to the root), on a false query
example : isACurie "CHEBI:16027" "CHEBI:17234" = false := by decide
-- prefixes never cross: a GO term is not a CL term
example : isACurie "GO:0005634" "CL:0000000" = false := by decide
-- PATO, HP, MONDO, SO, PR (OBO files, imported 2026-10-28)
example : isACurie "PATO:0001381" "PATO:0001374" = true := by decide    -- triploid is_a ploidy
example : isACurie "HP:0000855" "HP:0000118" = true := by decide        -- insulin resistance is_a phenotypic abnormality
example : isACurie "MONDO:0005130" "MONDO:0007179" = true := by decide  -- celiac disease is_a autoimmune disease
example : isACurie "MONDO:0005130" "MONDO:0005172" = false := by decide -- not a skeletal system disorder
example : isACurie "SO:0001026" "SO:0001260" = true := by decide        -- genome is_a sequence_collection
example : isACurie "PR:000009054" "PR:000000001" = true := by decide    -- PR's label for this id is preproinsulin
-- area postrema, fixed in `Lib/Entities.lean` (0002163 is the inferior cerebellar peduncle)
example : isACurie "UBERON:0002162" "UBERON:0005408" = true := by decide  -- is_a circumventricular organ

-- unknown terms are never siblings, so `transport` fails safe
example : siblings { curie := "NCBITaxon:9999999", label := "unknown" } human = false := by decide
example : Ontology.siblings (0, 5634) (0, 5737) = true := by decide      -- nucleus, cytoplasm

-- retired terms: obsolete or merged, with their replacement
example : retired.lookup (0, 7050) = some [(0, 51726)] := by decide    -- alt_id of regulation of cell cycle
example : known (0, 7050) = false := by decide                           -- retired ids are not terms

-- the size of the import, pinned
theorem terms_count : labels.length = 3548 := by decide +kernel
theorem edges_count : edges.length = 4857 := by decide +kernel
-- the search tree is ordered (every term is found) and the closure is closed (every parent is a term)
#guard labels.all fun (c, _) => known c
#guard edges.all fun (_, p) => known p
-- children are the inverse of parents
#guard edges.all fun (c, p) => (children p).contains c
#guard (labels.map fun (c, _) => (children c).length).sum == edges.length
example : children (4, 131567) = [(4, 2), (4, 2157), (4, 2759)] := by decide +kernel  -- Bacteria, Archaea, Eukaryota
#guard retired.all fun (c, rs) => !known c && rs.all known

end BioLean.IsA.Tests

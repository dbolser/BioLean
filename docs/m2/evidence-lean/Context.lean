import BioLean.Ontology
import BioLean.Belief

/-!
# Context (M2, design "evidence")

INDRA-style: a `Claim` stays bare, and where a result was obtained (taxon, anatomy, cell type,
membrane, condition, in vitro, dose, duration) is recorded on each `Evidence` item. A `Ctx` is a
*query*: the context a claim is asked about. Only evidence that fits the query fuses
(`Evidence.fits`), so the context is enforced when an opinion is computed, not when a claim is
typed.

Fit is subsumption, read universally: evidence about eukaryotes fits a query about mice
(specialisation is free); evidence about mice does not fit a query about mammals or a query with
no taxon (generalisation is not free, it is M4's `generalize`); evidence about mice does not fit a
query about humans either, unless an explicit `Derivation.transport` step moves it there.
An unset evidence field means "no restriction stated" and fits every query. That is the default
for every existing statement, so their opinions are unchanged.
-/

namespace BioLean

/-- The context a claim is asked about. Unset fields are unrestricted. -/
structure Ctx where
  taxon : Option (Entity .taxon) := none
  anatomy : Option (Entity .anatomy) := none
  cellType : Option (Entity .cellType) := none
  component : Option (Entity .component) := none
  condition : Option String := none
  /-- Ignore in vitro evidence. -/
  inVivoOnly : Bool := false
  deriving Repr

/-- Subsumption between context terms, and the weight of a cross-taxon transport step. Swappable,
like `EvidenceModel`. -/
class ContextModel where
  /-- `isA a b`: the term with CURIE `a` is `b` or a descendant of `b`. -/
  isA : String → String → Bool
  transport : ℚ
  transport_nonneg : 0 ≤ transport
  transport_le_one : transport ≤ 1

/-- Ancestors of the taxa and components used so far. Hand-written; a real table comes from
NCBITaxon and GO `is_a`. -/
def ContextModel.ancestors : List (String × List String) :=
  let euk := ["NCBITaxon:2759", "NCBITaxon:131567"]
  let mam := ["NCBITaxon:40674", "NCBITaxon:7742", "NCBITaxon:33208"] ++ euk
  [ ("NCBITaxon:10090", mam), ("NCBITaxon:9606", mam), ("NCBITaxon:10116", mam),
    ("NCBITaxon:9913", mam), ("NCBITaxon:40674", mam.drop 1), ("NCBITaxon:7742", mam.drop 2),
    ("NCBITaxon:33208", euk), ("NCBITaxon:3562", "NCBITaxon:33090" :: euk),
    ("NCBITaxon:33090", euk), ("NCBITaxon:4751", euk), ("NCBITaxon:2759", ["NCBITaxon:131567"]),
    ("NCBITaxon:2", ["NCBITaxon:131567"]), ("NCBITaxon:562", ["NCBITaxon:2", "NCBITaxon:131567"]),
    ("NCBITaxon:2157", ["NCBITaxon:131567"]),
    ("NCBITaxon:2242", ["NCBITaxon:2157", "NCBITaxon:131567"]),
    ("GO:0042651", ["GO:0016020"]), ("GO:0005743", ["GO:0016020"]) ]

/-- The default: the table above, and transport at 3/10. -/
instance ContextModel.standard : ContextModel where
  isA a b := a == b || ((ContextModel.ancestors.lookup a).getD []).contains b
  transport := 3 / 10
  transport_nonneg := by norm_num
  transport_le_one := by norm_num

namespace Ctx

variable [ContextModel]

/-- Does an evidence slot fit a query slot? Unset evidence fits anything; set evidence fits only
a query that names the same term or a descendant of it. -/
def slotFits {k : Kind} (query ev : Option (Entity k)) : Bool :=
  match ev, query with
  | none, _ => true
  | some _, none => false
  | some e, some q => ContextModel.isA q.curie e.curie

/-- Taxa fit when every evidence taxon subsumes the query taxon. A chimeric system (bacteriorhodopsin
from *Halobacterium* with bovine ATP synthase) lists both, and so fits no single-taxon query. -/
def taxaFit (query : Option (Entity .taxon)) (ev : List (Entity .taxon)) : Bool :=
  match ev, query with
  | [], _ => true
  | _ :: _, none => false
  | ts, some q => ts.all fun t => ContextModel.isA q.curie t.curie

/-- `a` and `b` are distinct taxa, neither inside the other: the only legal transport. -/
def siblings (a b : Entity .taxon) : Bool :=
  !ContextModel.isA a.curie b.curie && !ContextModel.isA b.curie a.curie

end Ctx

instance : ToString Ctx where
  toString x :=
    let parts : List String :=
      (x.taxon.toList.map toString) ++ (x.anatomy.toList.map toString) ++
      (x.cellType.toList.map toString) ++ (x.component.toList.map toString) ++ x.condition.toList ++
      (if x.inVivoOnly then ["in vivo only"] else [])
    if parts.isEmpty then "any context" else ", ".intercalate parts

end BioLean

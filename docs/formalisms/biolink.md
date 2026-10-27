# Biolink Model (v4.4.6) / KGX edges

**The formalism.** Biolink is the schema behind NCATS Translator knowledge graphs. A unit of annotation is
one KGX edge: a typed `Association` with `subject`, `predicate`, `object` (all CURIEs), plus edge
properties. Meaning is layered: the *core triple* (`subject predicate object`) and the *full statement*
(`subject [subject_aspect/direction] qualified_predicate object [object_aspect/direction]`). Context lives in
qualifier slots, but which qualifiers are legal depends on the association class (`category`): e.g.
`species_context_qualifier` exists on `ChemicalAffectsBiologicalEntityAssociation` but not on
`ChemicalOrDrugOrTreatmentToDiseaseOrPhenotypicFeatureAssociation`; `sex_qualifier` only on classes whose
object is a phenotypic feature *and* that use the phenotype mixin (gene/disease/genotype to phenotype, not
chemical to phenotype). Epistemic status goes in `knowledge_level` (`knowledge_assertion`, `prediction`
[alias "hypothesis"], `observation`, `statistical_association`, ...) and `agent_type`. Evidence goes in
`publications`, `has_evidence_of_type` (ECO terms; note: in 4.4.6 ECO goes here, `has_evidence` has range
*information content entity*, not evidence type), `has_supporting_studies`, `supporting_text`, `p_value`,
`effect_size`/`effect_type`. `negated: true` gives explicit negative edges. Edges cannot point at edges, so
there is no native "supports" / "refutes" / "rival of" between statements.

Conventions used below (all slot and enum names checked against `biolink-model.yaml` v4.4.6 on GitHub
master; IDs checked with OLS4 / UniProt REST):
- `// comments` are labels for the reader only; strip them for real KGX (JSON has no comments).
- `primary_knowledge_source: "infores:biolean"` is a placeholder; it is not a registered infores ID.
- `?:unverified` = no ontology term found / could not verify.
- `_:...` = local blank-node IDs for things with no ontology term (study populations). Real KGX would need
  them as nodes with a category (`biolink:PopulationOfIndividualOrganisms`, `biolink:Study`).
- **Strictness caveat.** Qualifiers are class-bound. Base `biolink:Association` carries no
  `species_context_qualifier` or `anatomical_context_qualifier`, and no specific class covers
  process-`causes`-process with context. Where I put context on a generic `biolink:Association` edge
  (most chemiosmotic edges), a strict LinkML validation would reject it. Translator KGs often do it anyway.
  I keep the context because dropping it would hide the paper's content; each such edge is a fit failure.
- Where the input text is a secondary-source summary (`abstract_is_summary: true`), the paper header says
  **Provenance: summary**, and the summary sentence is quoted in `supporting_text`.

---

## Mitchell 1961, PMID:13771349 (chemiosmotic hypothesis). Provenance: summary

Hypothesis, so `knowledge_level: prediction` (Biolink's alias for this value is literally "hypothesis"),
ECO `author inference`.

```jsonc
[
 { "id": "e:m61-1", "category": ["biolink:Association"],
   "subject": "GO:0022904",            // respiratory electron transport chain
   "predicate": "biolink:causes",
   "object": "GO:1902600",             // proton transmembrane transport
   "anatomical_context_qualifier": ["GO:0005743"],   // mitochondrial inner membrane
   "knowledge_level": "prediction", "agent_type": "manual_agent",
   "has_evidence_of_type": ["ECO:0006185"],          // author inference
   "publications": ["PMID:13771349"], "primary_knowledge_source": "infores:biolean",
   "supporting_text": ["electron transfer translocates protons across it, generating an electrochemical proton gradient"] },

 { "id": "e:m61-2", "category": ["biolink:Association"],
   "subject": "GO:1902600",            // proton transmembrane transport (down the gradient)
   "predicate": "biolink:causes",
   "object": "GO:0006754",             // ATP biosynthetic process
   "anatomical_context_qualifier": ["GO:0005743"],
   "knowledge_level": "prediction", "agent_type": "manual_agent",
   "has_evidence_of_type": ["ECO:0006185"],
   "publications": ["PMID:13771349"], "primary_knowledge_source": "infores:biolean" },

 { "id": "e:m61-3", "category": ["biolink:Association"],
   "subject": "GO:0045259",            // proton-transporting ATP synthase complex
   "predicate": "biolink:capable_of",
   "object": "GO:0046933",             // proton-transporting ATP synthase activity, rotational mechanism
   "knowledge_level": "prediction", "agent_type": "manual_agent",
   "has_evidence_of_type": ["ECO:0006185"],
   "publications": ["PMID:13771349"], "primary_knowledge_source": "infores:biolean",
   "supporting_text": ["a reversible, anisotropic membrane ATPase uses that gradient to synthesise ATP"] },

 { "id": "e:m61-4", "category": ["biolink:Association"],
   "subject": "GO:0009777",            // photosynthetic phosphorylation
   "predicate": "biolink:subclass_of",
   "object": "GO:0015986",             // proton motive force-driven ATP synthesis
   "knowledge_level": "prediction", "agent_type": "manual_agent",
   "has_evidence_of_type": ["ECO:0006185"],
   "publications": ["PMID:13771349"], "primary_knowledge_source": "infores:biolean",
   "supporting_text": ["oxidative and photosynthetic phosphorylation are coupled ... by a 'chemi-osmotic' mechanism"] },

 { "id": "e:m61-5", "category": ["biolink:Association"],
   "subject": "GO:0006119",            // oxidative phosphorylation
   "predicate": "biolink:subclass_of",
   "object": "GO:0015986",
   "knowledge_level": "prediction", "agent_type": "manual_agent",
   "has_evidence_of_type": ["ECO:0006185"],
   "publications": ["PMID:13771349"], "primary_knowledge_source": "infores:biolean" },

 { "id": "e:m61-6", "category": ["biolink:ChemicalAffectsBiologicalEntityAssociation"],
   "subject": "?:unverified",          // "uncoupler" as a class: no ChEBI role found in OLS4
   "predicate": "biolink:affects",
   "qualified_predicate": "biolink:causes",
   "object": "GO:1902600",             // proton transmembrane transport (leak)
   "object_direction_qualifier": "increased",
   "anatomical_context_qualifier": ["GO:0005743"],
   "knowledge_level": "prediction", "agent_type": "manual_agent",
   "has_evidence_of_type": ["ECO:0006185"],
   "publications": ["PMID:13771349"], "primary_knowledge_source": "infores:biolean",
   "supporting_text": ["uncouplers act by making it proton-permeable"] }
]
```

Could not express:
- "The coupling membrane must be ion-impermeable" (a property of a membrane; Biolink edges link entities,
  `has_attribute` is a node property, there is no "permeability" aspect for a cellular component).
- "Anisotropic / vectorial" arrangement of the chain (no orientation or sidedness qualifier).
- That e:m61-1..6 are one hypothesis (no grouping of edges into a model; would need a shared
  `has_supporting_studies` or an out-of-band ID).
- "Prediction" in the sense of a *testable consequence* vs. the core claim: both collapse to
  `knowledge_level: prediction`.
- That this is a rival to Slater 1953 (no edge-to-edge relation).
- Uncoupler as a class of chemicals (no verified ChEBI role term).

---

## Slater 1953, PMID:13111237 (chemical-intermediate hypothesis). Provenance: summary

The intermediate `C~I` has no ontology term; it is a hypothetical entity, so it gets `?:unverified`.
In real KGX it would need a minted node (e.g. `biolean:C_I`, category `biolink:ChemicalEntity`).

```jsonc
[
 { "id": "e:s53-1", "category": ["biolink:Association"],
   "subject": "GO:0022904",            // respiratory electron transport chain
   "predicate": "biolink:has_output",
   "object": "?:unverified",           // C~I, non-phosphorylated high-energy intermediate (no term)
   "anatomical_context_qualifier": ["GO:0005743"],
   "knowledge_level": "prediction", "agent_type": "manual_agent",
   "has_evidence_of_type": ["ECO:0006185"],          // author inference
   "publications": ["PMID:13111237"], "primary_knowledge_source": "infores:biolean",
   "supporting_text": ["energy from electron transfer ... is conserved in a non-phosphorylated high-energy chemical intermediate (written C~I)"] },

 { "id": "e:s53-2", "category": ["biolink:Association"],
   "subject": "?:unverified",          // C~I
   "predicate": "biolink:is_input_of",
   "object": "GO:0006754",             // ATP biosynthetic process
   "knowledge_level": "prediction", "agent_type": "manual_agent",
   "has_evidence_of_type": ["ECO:0006185"],
   "publications": ["PMID:13111237"], "primary_knowledge_source": "infores:biolean" },

 { "id": "e:s53-3", "category": ["biolink:Association"],
   "subject": "CHEBI:43474",           // hydrogenphosphate (Pi)
   "predicate": "biolink:is_input_of",
   "object": "GO:0006754",
   "knowledge_level": "prediction", "agent_type": "manual_agent",
   "has_evidence_of_type": ["ECO:0006185"],
   "publications": ["PMID:13111237"], "primary_knowledge_source": "infores:biolean",
   "supporting_text": ["C~I ... reacts with inorganic phosphate and ADP to yield ATP"] },

 { "id": "e:s53-4", "category": ["biolink:Association"],
   "subject": "GO:0006119",            // oxidative phosphorylation
   "predicate": "biolink:similar_to",
   "object": "?:unverified",           // substrate-level phosphorylation: no GO process term verified
   "knowledge_level": "prediction", "agent_type": "manual_agent",
   "has_evidence_of_type": ["ECO:0006185"],
   "publications": ["PMID:13111237"], "primary_knowledge_source": "infores:biolean",
   "supporting_text": ["by analogy with glycolytic substrate-level phosphorylation"] }
]
```

Note e:s53-3 has to fall back to generic `biolink:Association`: no specific class covers
chemical `is_input_of` process.

Could not express:
- That e:s53-1 and e:m61-1 are *competing* explanations of the same thing (coupling of electron transport to
  ATP synthesis). Both are just `prediction` edges with the same subject; nothing says "only one can be true".
- The reaction stoichiometry `C~I + Pi + ADP -> ATP + C + I` (Biolink has `ReactionToParticipantAssociation`,
  but the reaction would need an ID, e.g. Rhea; a hypothetical reaction has none).
- "Analogy" as a mode of reasoning; `similar_to` loses why it was proposed.
- A placeholder for an unidentified entity (no "hypothetical entity" category).

---

## Jagendorf & Uribe 1966, PMID:5220864 (acid-bath ATP synthesis). Provenance: summary

In vitro experimental result: `knowledge_assertion`, ECO `in vitro assay evidence used in manual assertion`.
"Evidence for Mitchell" can only be shown by re-asserting Mitchell's triple at a higher knowledge level with a
new publication (e:ju66-3, e:ju66-4). This is the Translator way: support = same edge, more publications.

```jsonc
[
 { "id": "e:ju66-1", "category": ["biolink:ChemicalAffectsBiologicalEntityAssociation"],
   "subject": "CHEBI:15378",           // hydron (H+)
   "subject_aspect_qualifier": "transport",          // nearest enum value to "efflux down an imposed gradient"
   "subject_context_qualifier": "GO:0009535",        // chloroplast thylakoid membrane
   "predicate": "biolink:affects",
   "qualified_predicate": "biolink:causes",
   "object": "GO:0006754",             // ATP biosynthetic process
   "object_direction_qualifier": "increased",
   "species_context_qualifier": "NCBITaxon:3562",    // Spinacia oleracea
   "anatomical_context_qualifier": ["GO:0009535"],
   "knowledge_level": "knowledge_assertion", "agent_type": "manual_agent",
   "has_evidence_of_type": ["ECO:0007122"],          // in vitro assay evidence used in manual assertion
   "publications": ["PMID:5220864"], "primary_knowledge_source": "infores:biolean",
   "supporting_text": ["equilibrated in the dark at pH ~4 ..., then rapidly shifted to pH ~8 in the presence of ADP and inorganic phosphate. ATP was synthesised in the dark"] },

 { "id": "e:ju66-2", "category": ["biolink:Association"],
   "subject": "CHEBI:16761",           // ADP
   "predicate": "biolink:is_input_of",
   "object": "GO:0006754",
   "species_context_qualifier": "NCBITaxon:3562",
   "anatomical_context_qualifier": ["GO:0009535"],
   "knowledge_level": "knowledge_assertion", "agent_type": "manual_agent",
   "has_evidence_of_type": ["ECO:0007122"],
   "publications": ["PMID:5220864"], "primary_knowledge_source": "infores:biolean" },

 { "id": "e:ju66-3", "category": ["biolink:Association"],          // same triple as e:m61-2, now asserted
   "subject": "GO:1902600",            // proton transmembrane transport
   "predicate": "biolink:causes",
   "object": "GO:0006754",
   "species_context_qualifier": "NCBITaxon:3562",
   "anatomical_context_qualifier": ["GO:0009535"],
   "knowledge_level": "knowledge_assertion", "agent_type": "manual_agent",
   "has_evidence_of_type": ["ECO:0007122"],
   "publications": ["PMID:5220864"], "primary_knowledge_source": "infores:biolean",
   "supporting_text": ["a transmembrane pH gradient alone can drive ATP formation, as predicted by the chemiosmotic hypothesis"] },

 { "id": "e:ju66-4", "category": ["biolink:Association"],          // same triple as e:m61-4, now asserted
   "subject": "GO:0009777",            // photosynthetic phosphorylation
   "predicate": "biolink:subclass_of",
   "object": "GO:0015986",             // proton motive force-driven ATP synthesis
   "knowledge_level": "knowledge_assertion", "agent_type": "manual_agent",
   "has_evidence_of_type": ["ECO:0006185"],          // author inference (the generalisation is the authors')
   "publications": ["PMID:5220864"], "primary_knowledge_source": "infores:biolean" },

 { "id": "e:ju66-5", "category": ["biolink:ChemicalAffectsBiologicalEntityAssociation"],
   "subject": "CHEBI:26806",           // succinate (the permeant acid buffer)
   "predicate": "biolink:affects",
   "object": "GO:0006754",
   "species_context_qualifier": "NCBITaxon:3562",
   "anatomical_context_qualifier": ["GO:0009535"],
   "knowledge_level": "knowledge_assertion", "agent_type": "manual_agent",
   "has_evidence_of_type": ["ECO:0007122"],
   "publications": ["PMID:5220864"], "primary_knowledge_source": "infores:biolean",
   "supporting_text": ["yield depending on the size of the pH jump and on the permeant acid used"] }
]
```

Could not express:
- The pH values (4 -> 8) and the dose-response "yield depends on size of pH jump" (no slot for an
  experimental parameter or a graded response; `effect_size` is for statistical metrics).
- "In the dark" / light-independent: no condition qualifier, and a `negated` edge on photosynthesis would say
  the wrong thing.
- In vitro, isolated thylakoids: only implied by ECO `in vitro assay`; no "isolated organelle" qualifier.
- "Gradient alone is sufficient" (sufficiency is not a predicate; `causes` is as close as it gets).
- That this result is evidence *against* Slater's e:s53-1 (no edge-to-edge link; only implicit by
  re-asserting the Mitchell triple).

---

## Mitchell & Moyle 1967, PMID:16742541 (respiration-driven proton translocation). Provenance: abstract

Isolated rat liver mitochondria. Here the controversy is explicit in the text, so we get the one real
Biolink tool for refutation: a `negated: true` copy of Slater's triple (e:mm67-3 vs e:s53-1).

```jsonc
[
 { "id": "e:mm67-1", "category": ["biolink:Association"],
   "subject": "GO:0006121",            // mitochondrial electron transport, succinate to ubiquinone
   "predicate": "biolink:causes",
   "object": "GO:1902600",             // proton transmembrane transport
   "species_context_qualifier": "NCBITaxon:10116",   // Rattus norvegicus
   "anatomical_context_qualifier": ["UBERON:0002107", "GO:0030061"],   // liver; mitochondrial crista
   "knowledge_level": "knowledge_assertion", "agent_type": "manual_agent",
   "has_evidence_of_type": ["ECO:0007122"],          // in vitro assay evidence used in manual assertion
   "publications": ["PMID:16742541"], "primary_knowledge_source": "infores:biolean",
   "supporting_text": ["protons translocated per bivalent reducing equivalent passing through the succinate-oxidizing ... spans ... very close to 4"] },

 { "id": "e:mm67-2", "category": ["biolink:Association"],
   "subject": "GO:0006120",            // mitochondrial electron transport, NADH to ubiquinone (beta-hydroxybutyrate span)
   "predicate": "biolink:causes",
   "object": "GO:1902600",
   "species_context_qualifier": "NCBITaxon:10116",
   "anatomical_context_qualifier": ["UBERON:0002107", "GO:0030061"],
   "knowledge_level": "knowledge_assertion", "agent_type": "manual_agent",
   "has_evidence_of_type": ["ECO:0007122"],
   "publications": ["PMID:16742541"], "primary_knowledge_source": "infores:biolean",
   "supporting_text": ["beta-hydroxybutyrate-oxidizing spans ... 6. These quotients are constant between pH5.5 and 8.5"] },

 { "id": "e:mm67-3", "category": ["biolink:Association"],          // negated copy of Slater e:s53-1
   "subject": "GO:0022904",            // respiratory electron transport chain
   "predicate": "biolink:has_output",
   "object": "?:unverified",           // C~I (uncoupler-sensitive chemical intermediate)
   "negated": true,
   "species_context_qualifier": "NCBITaxon:10116",
   "knowledge_level": "knowledge_assertion", "agent_type": "manual_agent",
   "has_evidence_of_type": ["ECO:0007122", "ECO:0006185"],
   "publications": ["PMID:16742541"], "primary_knowledge_source": "infores:biolean",
   "supporting_text": ["the fact that the initial -->H(+)/O quotients are unchanged shows that uncoupler-sensitive chemical intermediates do not exist"] },

 { "id": "e:mm67-4", "category": ["biolink:ChemicalAffectsBiologicalEntityAssociation"],
   "subject": "CHEBI:42017",           // 2,4-dinitrophenol
   "predicate": "biolink:affects",
   "qualified_predicate": "biolink:causes",
   "object": "GO:1902600",             // proton transmembrane transport (back-leak = conductance)
   "object_direction_qualifier": "increased",
   "species_context_qualifier": "NCBITaxon:10116",
   "anatomical_context_qualifier": ["GO:0005743"],   // mitochondrial inner membrane
   "knowledge_level": "knowledge_assertion", "agent_type": "manual_agent",
   "has_evidence_of_type": ["ECO:0007122"],
   "publications": ["PMID:16742541"], "primary_knowledge_source": "infores:biolean",
   "supporting_text": ["2,4-dinitrophenol, carbonyl cyanide p-trifluoromethoxyphenylhydrazone and gramicidin increase the effective proton conductance of the M phase"] },
 // e:mm67-5 and e:mm67-6: identical to e:mm67-4 with subject CHEBI:75458 (FCCP) and CHEBI:749506 (gramicidin).

 { "id": "e:mm67-7", "category": ["biolink:ChemicalAffectsBiologicalEntityAssociation"],
   "subject": "CHEBI:42017",
   "predicate": "biolink:affects",
   "qualified_predicate": "biolink:causes",
   "object": "GO:0042776",             // proton motive force-driven mitochondrial ATP synthesis
   "object_direction_qualifier": "decreased",
   "species_context_qualifier": "NCBITaxon:10116",
   "knowledge_level": "knowledge_assertion", "agent_type": "manual_agent",
   "has_evidence_of_type": ["ECO:0006185"],          // "accounts quantitatively for their uncoupling action" = inference
   "publications": ["PMID:16742541"], "primary_knowledge_source": "infores:biolean" },

 { "id": "e:mm67-8", "category": ["biolink:Association"],          // e:m61-1 re-asserted
   "subject": "GO:0022904", "predicate": "biolink:causes", "object": "GO:1902600",
   "species_context_qualifier": "NCBITaxon:10116",
   "anatomical_context_qualifier": ["UBERON:0002107", "GO:0005743"],
   "knowledge_level": "knowledge_assertion", "agent_type": "manual_agent",
   "has_evidence_of_type": ["ECO:0007122"],
   "publications": ["PMID:16742541"], "primary_knowledge_source": "infores:biolean" }
]
```

Could not express:
- The headline numbers: H+/O = 4 (succinate) and 6 (beta-hydroxybutyrate), and their pH-independence
  (5.5-8.5). No stoichiometry slot; only `supporting_text`.
- The key *negative* result "uncouplers do not change the initial H+/O quotient". It is about a quantity of a
  process, not about an entity, so no `negated` edge fits it. Only its conclusion (e:mm67-3) is expressible.
- Measurement artefacts (backlash, anion/cation effects on apparent H+/O): no way to mark an *apparent* effect
  as artefact vs. real.
- Rotenone / antimycin A sites and the "loop 3" configuration (topology of the chain).
- "Accounts quantitatively for" (a quantitative sufficiency argument).
- e:mm67-3 contradicts e:s53-1 only by convention (same triple, opposite `negated`); no slot names the
  contradiction or says which edge wins.

---

## Hinkle & Horstman 1971, PMID:4330063 (proton uptake by submitochondrial particles). Provenance: summary

```jsonc
[
 { "id": "e:hh71-1", "category": ["biolink:Association"],
   "subject": "GO:0006120",            // mitochondrial electron transport, NADH to ubiquinone
   "predicate": "biolink:causes",
   "object": "GO:1902600",             // proton transmembrane transport (inward, into inside-out particle)
   "species_context_qualifier": "NCBITaxon:9913",    // Bos taurus
   "anatomical_context_qualifier": ["UBERON:0000948", "GO:0005743"],   // heart; mitochondrial inner membrane
   "knowledge_level": "knowledge_assertion", "agent_type": "manual_agent",
   "has_evidence_of_type": ["ECO:0007122"],          // in vitro assay evidence used in manual assertion
   "publications": ["PMID:4330063"], "primary_knowledge_source": "infores:biolean",
   "supporting_text": ["Submitochondrial particles from bovine heart, which are inside-out ..., take up protons during respiration (NADH or succinate oxidation)"] },

 { "id": "e:hh71-2", "category": ["biolink:Association"],
   "subject": "GO:0006121",            // mitochondrial electron transport, succinate to ubiquinone
   "predicate": "biolink:causes",
   "object": "GO:1902600",
   "species_context_qualifier": "NCBITaxon:9913",
   "anatomical_context_qualifier": ["UBERON:0000948", "GO:0005743"],
   "knowledge_level": "knowledge_assertion", "agent_type": "manual_agent",
   "has_evidence_of_type": ["ECO:0007122"],
   "publications": ["PMID:4330063"], "primary_knowledge_source": "infores:biolean" },

 { "id": "e:hh71-3", "category": ["biolink:ChemicalAffectsBiologicalEntityAssociation"],
   "subject": "?:unverified",          // "uncouplers" (class; no ChEBI role; specific compounds not in summary)
   "predicate": "biolink:affects",
   "qualified_predicate": "biolink:causes",
   "object": "GO:1902600",
   "object_direction_qualifier": "decreased",       // net uptake abolished
   "species_context_qualifier": "NCBITaxon:9913",
   "anatomical_context_qualifier": ["GO:0005743"],
   "knowledge_level": "knowledge_assertion", "agent_type": "manual_agent",
   "has_evidence_of_type": ["ECO:0007122"],
   "publications": ["PMID:4330063"], "primary_knowledge_source": "infores:biolean",
   "supporting_text": ["the uptake is abolished by uncouplers"] },

 { "id": "e:hh71-4", "category": ["biolink:Association"],          // e:m61-1 re-asserted
   "subject": "GO:0022904", "predicate": "biolink:causes", "object": "GO:1902600",
   "species_context_qualifier": "NCBITaxon:9913",
   "anatomical_context_qualifier": ["UBERON:0000948", "GO:0005743"],
   "knowledge_level": "knowledge_assertion", "agent_type": "manual_agent",
   "has_evidence_of_type": ["ECO:0007122"],
   "publications": ["PMID:4330063"], "primary_knowledge_source": "infores:biolean" }
]
```

Note the uncoupler direction flip vs. Mitchell & Moyle: there "increased" proton transport (leak), here
"decreased" (net uptake). Same physics, opposite sign, because GO has one term for proton transport and no way
to say *net* vs *gross* or *which direction across the membrane*.

Could not express:
- Membrane sidedness: inside-out particles, so protons go *in*, interior acidifies. No orientation qualifier.
- Submitochondrial particle as the preparation (no UBERON/CL/GO term for an artificial vesicle).
- "Together with later work ... ATP synthesis driven by an imposed pH gradient": a forward reference to other
  papers as supporting evidence; edges can cite several PMIDs but not say "this paper + that paper jointly".
- Evidence *against* the chemical intermediate is only implicit (no negated edge is warranted by the summary).

---

## Racker & Stoeckenius 1974, PMID:4272126 (bacteriorhodopsin + F1Fo ATPase vesicles). Provenance: summary

Reconstitution: ECO `reconstitution assay evidence used in manual assertion`. Two proteins from two
kingdoms in one artificial vesicle; Biolink's single `species_context_qualifier` cannot say that, so it is
left off the joint edges.

```jsonc
[
 { "id": "e:rs74-1", "category": ["biolink:Association"],
   "subject": "UniProtKB:P02945",      // bacteriorhodopsin (BACR_HALSA), Halobacterium salinarum
   "predicate": "biolink:actively_involved_in",
   "object": "GO:1902600",             // proton transmembrane transport (light-driven pumping)
   "species_context_qualifier": "NCBITaxon:2242",    // Halobacterium salinarum (syn. H. halobium)
   "knowledge_level": "knowledge_assertion", "agent_type": "manual_agent",
   "has_evidence_of_type": ["ECO:0007722"],          // reconstitution assay evidence used in manual assertion
   "publications": ["PMID:4272126"], "primary_knowledge_source": "infores:biolean",
   "supporting_text": ["On illumination the vesicles took up protons"] },

 { "id": "e:rs74-2", "category": ["biolink:Association"],
   "subject": "GO:0045259",            // proton-transporting ATP synthase complex (bovine heart F1F0, oligomycin-sensitive)
   "predicate": "biolink:capable_of",
   "object": "GO:0046933",             // proton-transporting ATP synthase activity, rotational mechanism
   "species_context_qualifier": "NCBITaxon:9913",    // Bos taurus
   "anatomical_context_qualifier": ["UBERON:0000948"],
   "knowledge_level": "knowledge_assertion", "agent_type": "manual_agent",
   "has_evidence_of_type": ["ECO:0007722"],
   "publications": ["PMID:4272126"], "primary_knowledge_source": "infores:biolean" },
   // A protein-level alternative would be UniProtKB:P00829 (ATP5F1B, bovine) as a stand-in for the complex.

 { "id": "e:rs74-3", "category": ["biolink:Association"],          // e:m61-2 / e:ju66-3 triple, reconstituted system
   "subject": "GO:1902600", "predicate": "biolink:causes", "object": "GO:0006754",
   "knowledge_level": "knowledge_assertion", "agent_type": "manual_agent",
   "has_evidence_of_type": ["ECO:0007722"],
   "publications": ["PMID:4272126"], "primary_knowledge_source": "infores:biolean",
   "supporting_text": ["a proton gradient is sufficient to drive ATP synthesis"] },

 { "id": "e:rs74-4", "category": ["biolink:ChemicalAffectsBiologicalEntityAssociation"],
   "subject": "CHEBI:25675",           // oligomycin
   "predicate": "biolink:affects",
   "qualified_predicate": "biolink:causes",
   "object": "GO:0006754",
   "object_direction_qualifier": "decreased",
   "causal_mechanism_qualifier": "inhibition",
   "knowledge_level": "knowledge_assertion", "agent_type": "manual_agent",
   "has_evidence_of_type": ["ECO:0007722"],
   "publications": ["PMID:4272126"], "primary_knowledge_source": "infores:biolean",
   "supporting_text": ["ATP synthesis was abolished by uncouplers and by oligomycin"] },

 { "id": "e:rs74-5", "category": ["biolink:ChemicalAffectsBiologicalEntityAssociation"],
   "subject": "?:unverified",          // "uncouplers" (class; no ChEBI role)
   "predicate": "biolink:affects",
   "qualified_predicate": "biolink:causes",
   "object": "GO:0006754",
   "object_direction_qualifier": "decreased",
   "knowledge_level": "knowledge_assertion", "agent_type": "manual_agent",
   "has_evidence_of_type": ["ECO:0007722"],
   "publications": ["PMID:4272126"], "primary_knowledge_source": "infores:biolean" },

 { "id": "e:rs74-6", "category": ["biolink:Association"],          // negated copy of Slater e:s53-2
   "subject": "?:unverified",          // C~I
   "predicate": "biolink:is_input_of",
   "object": "GO:0006754",
   "negated": true,
   "knowledge_level": "knowledge_assertion", "agent_type": "manual_agent",
   "has_evidence_of_type": ["ECO:0007722", "ECO:0006185"],   // reconstitution + author inference
   "publications": ["PMID:4272126"], "primary_knowledge_source": "infores:biolean",
   "supporting_text": ["the two proteins come from unrelated organisms and share no chemical intermediate"] }
]
```

Could not express:
- Light as the driver ("on illumination"). No exposure/condition qualifier on these classes; a light node
  would need an exposure class that has no edge class to a GO process.
- The chimeric context: bacterial pump + bovine enzyme + phospholipid vesicle in one system. One
  `species_context_qualifier` per edge, and no term for "artificial proteoliposome".
- The logic of the experiment (minimal system: if only these two parts, then no shared intermediate). The
  conclusion is a `negated` edge with ECO `author inference`; the argument is lost.
- Controls (dark, minus ATPase) as negative results.
- That e:rs74-6 refutes e:s53-2 and e:rs74-3 supports e:m61-2: only by triple identity.

---

## Yoshino 2011, PMID:21982712 (NMN in diet- and age-induced diabetic mice). Provenance: abstract

The disease-model problem shows up at once. The natural edge, NMN `beneficial_in_models_for` T2D, has class
`ChemicalOrDrugOrTreatmentToDiseaseOrPhenotypicFeatureAssociation`, which has **no
`species_context_qualifier`** and **no `sex_qualifier`**. The only context slot that can carry "HFD-fed
mice" is `population_context_qualifier`, whose range is a *node* (`PopulationOfIndividualOrganisms`). So the
mouse model has to be minted as a node:

```jsonc
// KGX nodes
[
 { "id": "_:pop-y11-hfd", "category": ["biolink:PopulationOfIndividualOrganisms"],
   "name": "HFD-induced T2D mice", "in_taxon": ["NCBITaxon:10090"],
   "description": "Mus musculus fed high fat diet (EFO:0002757); strain, sex, age, duration not in abstract" },
 { "id": "_:pop-y11-aged", "category": ["biolink:PopulationOfIndividualOrganisms"],
   "name": "age-induced T2D mice", "in_taxon": ["NCBITaxon:10090"],
   "description": "aged Mus musculus with glucose intolerance; age not in abstract" }
]
```

```jsonc
[
 { "id": "e:y11-1", "category": ["biolink:Association"],
   "subject": "EFO:0002757",           // high fat diet
   "predicate": "biolink:affects",
   "qualified_predicate": "biolink:causes",
   "object": "GO:0034355",             // NAD+ biosynthetic process via the salvage pathway (NAMPT-mediated)
   "object_direction_qualifier": "decreased",
   "species_context_qualifier": "NCBITaxon:10090",   // Mus musculus
   "knowledge_level": "knowledge_assertion", "agent_type": "manual_agent",
   "has_evidence_of_type": ["ECO:0007119"],          // in vivo assay evidence used in manual assertion
   "publications": ["PMID:21982712"], "primary_knowledge_source": "infores:biolean",
   "supporting_text": ["NAMPT-mediated NAD(+) biosynthesis is severely compromised in metabolic organs by high-fat diet"] },

 { "id": "e:y11-2", "category": ["biolink:ChemicalOrDrugOrTreatmentToDiseaseOrPhenotypicFeatureAssociation"],
   "subject": "CHEBI:50383",           // nicotinamide mononucleotide
   "predicate": "biolink:beneficial_in_models_for",
   "object": "MONDO:0005148",          // type 2 diabetes mellitus
   "population_context_qualifier": "_:pop-y11-hfd",
   "knowledge_level": "knowledge_assertion", "agent_type": "manual_agent",
   "has_evidence_of_type": ["ECO:0007119"],
   "publications": ["PMID:21982712"], "primary_knowledge_source": "infores:biolean" },

 { "id": "e:y11-3", "category": ["biolink:ChemicalOrDrugOrTreatmentToDiseaseOrPhenotypicFeatureAssociation"],
   "subject": "CHEBI:50383",
   "predicate": "biolink:ameliorates_condition",
   "object": "MP:0005293",             // impaired glucose tolerance
   "disease_context_qualifier": "MONDO:0005148",
   "population_context_qualifier": "_:pop-y11-hfd",
   "knowledge_level": "knowledge_assertion", "agent_type": "manual_agent",
   "has_evidence_of_type": ["ECO:0007119"],
   "publications": ["PMID:21982712"], "primary_knowledge_source": "infores:biolean",
   "supporting_text": ["NMN ... ameliorates glucose intolerance by restoring NAD(+) levels in HFD-induced T2D mice"] },

 { "id": "e:y11-4", "category": ["biolink:ChemicalEntityToChemicalEntityAssociation"],
   "subject": "CHEBI:50383",
   "predicate": "biolink:affects",     // "restores NAD+ levels": class has NO aspect/direction qualifiers
   "object": "CHEBI:15846",            // NAD(+)
   "species_context_qualifier": "NCBITaxon:10090",
   "knowledge_level": "knowledge_assertion", "agent_type": "manual_agent",
   "has_evidence_of_type": ["ECO:0007119"],
   "publications": ["PMID:21982712"], "primary_knowledge_source": "infores:biolean" },

 { "id": "e:y11-5", "category": ["biolink:ChemicalAffectsBiologicalEntityAssociation"],   // workaround for e:y11-4
   "subject": "CHEBI:50383",
   "predicate": "biolink:affects", "qualified_predicate": "biolink:causes",
   "object": "GO:0009435",             // NAD+ biosynthetic process
   "object_direction_qualifier": "increased",
   "species_context_qualifier": "NCBITaxon:10090",
   "knowledge_level": "knowledge_assertion", "agent_type": "manual_agent",
   "has_evidence_of_type": ["ECO:0007119"],
   "publications": ["PMID:21982712"], "primary_knowledge_source": "infores:biolean" },

 { "id": "e:y11-6", "category": ["biolink:ChemicalAffectsBiologicalEntityAssociation"],
   "subject": "CHEBI:50383",
   "predicate": "biolink:affects", "qualified_predicate": "biolink:causes",
   "object": "GO:0032868",             // response to insulin (hepatic insulin sensitivity)
   "object_direction_qualifier": "increased",
   "anatomical_context_qualifier": ["UBERON:0002107"],   // liver
   "species_context_qualifier": "NCBITaxon:10090",
   "knowledge_level": "knowledge_assertion", "agent_type": "manual_agent",
   "has_evidence_of_type": ["ECO:0007119"],
   "publications": ["PMID:21982712"], "primary_knowledge_source": "infores:biolean" },

 { "id": "e:y11-7", "category": ["biolink:ChemicalAffectsGeneAssociation"],
   "subject": "CHEBI:50383",
   "predicate": "biolink:affects", "qualified_predicate": "biolink:causes",
   "object": "UniProtKB:Q923E4",       // SIRT1 (mouse)
   "object_aspect_qualifier": "activity",
   "object_direction_qualifier": "increased",
   "species_context_qualifier": "NCBITaxon:10090",
   "knowledge_level": "knowledge_assertion", "agent_type": "manual_agent",
   "has_evidence_of_type": ["ECO:0007119"],
   "publications": ["PMID:21982712"], "primary_knowledge_source": "infores:biolean",
   "supporting_text": ["partly through SIRT1 activation"] },

 { "id": "e:y11-8", "category": ["biolink:Association"],          // stretch: life stage as subject
   "subject": "UBERON:0007222",        // late adult stage
   "predicate": "biolink:has_decreased_amount",
   "object": "UniProtKB:Q99KQ4",       // NAMPT (mouse)
   "species_context_qualifier": "NCBITaxon:10090",
   "knowledge_level": "knowledge_assertion", "agent_type": "manual_agent",
   "has_evidence_of_type": ["ECO:0007119"],
   "publications": ["PMID:21982712"], "primary_knowledge_source": "infores:biolean",
   "supporting_text": ["NAD(+) and NAMPT levels show significant decreases in multiple organs during aging"] },

 { "id": "e:y11-9", "category": ["biolink:ChemicalOrDrugOrTreatmentToDiseaseOrPhenotypicFeatureAssociation"],
   "subject": "CHEBI:50383",
   "predicate": "biolink:ameliorates_condition",
   "object": "MP:0005293",             // impaired glucose tolerance
   "population_context_qualifier": "_:pop-y11-aged",
   "knowledge_level": "knowledge_assertion", "agent_type": "manual_agent",
   "has_evidence_of_type": ["ECO:0007119"],
   "publications": ["PMID:21982712"], "primary_knowledge_source": "infores:biolean" },

 { "id": "e:y11-10", "category": ["biolink:ChemicalOrDrugOrTreatmentToDiseaseOrPhenotypicFeatureAssociation"],
   "subject": "CHEBI:50383",
   "predicate": "biolink:ameliorates_condition",
   "object": "MP:0003949",             // abnormal circulating lipid level
   "population_context_qualifier": "_:pop-y11-aged",
   "knowledge_level": "knowledge_assertion", "agent_type": "manual_agent",
   "has_evidence_of_type": ["ECO:0007119"],
   "publications": ["PMID:21982712"], "primary_knowledge_source": "infores:biolean" }
]
```

Could not express:
- Direction of NMN on NAD+ *levels* (e:y11-4): the chemical-to-chemical class has no aspect or direction
  qualifiers. Workaround e:y11-5 switches to the biosynthesis *process*, which is a different claim.
- Mediation: "ameliorates glucose intolerance *by* restoring NAD+" and "*partly through* SIRT1". Each link is
  a separate edge; nothing says one effect runs through another, or that it is partial.
- "Restores gene expression related to oxidative stress, inflammation, circadian rhythm": `object_aspect:
  expression` applies to genes, not to GO processes, and no gene list is in the abstract.
- "Restores" (back to control level) vs "increases": only `increased`/`decreased`.
- Aging as a cause (e:y11-8 is a stretch: a life stage "has decreased amount" of a protein; GO `aging`
  GO:0007568 is obsolete; and `stage_qualifier` only exists on gene-expression classes).
- Tissues for "metabolic organs" and "multiple organs" (not named in the abstract).
- Dose, route, duration, strain, sex, age: only as free text in the population node.

---

## Gomes 2013, PMID:24360282 (declining NAD+ -> pseudohypoxia -> mitochondrial decline in aging). Provenance: abstract

The abstract says "raising NAD+ levels in old mice"; the agent (NMN) is from the paper title note, not the
abstract text. A nice Biolink trick is available here: "SIRT1-dependent" can be written as a `negated`
effect in a SIRT1-knockout population (e:g13-7).

```jsonc
// KGX nodes
[
 { "id": "_:pop-g13-old", "category": ["biolink:PopulationOfIndividualOrganisms"],
   "name": "old wild-type mice", "in_taxon": ["NCBITaxon:10090"],
   "description": "aged Mus musculus; age, strain, sex, dose, duration not in abstract" },
 { "id": "_:pop-g13-sirt1ko-old", "category": ["biolink:PopulationOfIndividualOrganisms"],
   "name": "old SIRT1-deleted mice", "in_taxon": ["NCBITaxon:10090"],
   "description": "Sirt1 deletion; tissue specificity not in abstract" }
]
```

```jsonc
[
 { "id": "e:g13-1", "category": ["biolink:Association"],          // stretch: life stage as subject
   "subject": "UBERON:0007222",        // late adult stage
   "predicate": "biolink:has_decreased_amount",
   "object": "?:unverified",           // "mitochondrially encoded OXPHOS subunits" as a set: no single term
   "knowledge_level": "knowledge_assertion", "agent_type": "manual_agent",
   "has_evidence_of_type": ["ECO:0007119"],          // in vivo assay evidence used in manual assertion
   "publications": ["PMID:24360282"], "primary_knowledge_source": "infores:biolean",
   "supporting_text": ["during aging, there is a specific loss of mitochondrial, but not nuclear, encoded OXPHOS subunits"] },

 { "id": "e:g13-2", "category": ["biolink:Association"],          // the "but not nuclear" half, as a negative
   "subject": "UBERON:0007222",
   "predicate": "biolink:has_decreased_amount",
   "object": "?:unverified",           // "nuclear-encoded OXPHOS subunits" as a set
   "negated": true,
   "knowledge_level": "knowledge_assertion", "agent_type": "manual_agent",
   "has_evidence_of_type": ["ECO:0007119"],
   "publications": ["PMID:24360282"], "primary_knowledge_source": "infores:biolean" },

 { "id": "e:g13-3", "category": ["biolink:ChemicalAffectsGeneAssociation"],
   "subject": "CHEBI:15846",           // NAD(+)
   "subject_aspect_qualifier": "abundance",
   "subject_direction_qualifier": "decreased",
   "subject_context_qualifier": "GO:0005634",       // nucleus
   "predicate": "biolink:affects", "qualified_predicate": "biolink:causes",
   "object": "UniProtKB:Q61221",       // HIF-1-alpha (mouse)
   "object_aspect_qualifier": "abundance",
   "object_direction_qualifier": "increased",
   "species_context_qualifier": "NCBITaxon:10090",
   "knowledge_level": "knowledge_assertion", "agent_type": "manual_agent",
   "has_evidence_of_type": ["ECO:0007119"],
   "publications": ["PMID:24360282"], "primary_knowledge_source": "infores:biolean",
   "supporting_text": ["a decline in nuclear NAD(+) and the accumulation of HIF-1alpha under normoxic conditions"] },

 { "id": "e:g13-4", "category": ["biolink:Association"],
   "subject": "UniProtKB:Q61221",      // HIF-1-alpha
   "predicate": "biolink:disrupts",
   "object": "GO:0031930",             // mitochondria-nucleus signaling pathway
   "species_context_qualifier": "NCBITaxon:10090",
   "knowledge_level": "knowledge_assertion", "agent_type": "manual_agent",
   "has_evidence_of_type": ["ECO:0007119"],
   "publications": ["PMID:24360282"], "primary_knowledge_source": "infores:biolean" },

 { "id": "e:g13-5", "category": ["biolink:GeneToPhenotypicFeatureAssociation"],
   "subject": "UniProtKB:Q923E4",      // SIRT1 (mouse)
   "subject_form_or_variant_qualifier": "loss_of_function_variant_form",   // deletion
   "predicate": "biolink:causes",
   "object": "MP:0006036",             // abnormal mitochondrial physiology
   "knowledge_level": "knowledge_assertion", "agent_type": "manual_agent",
   "has_evidence_of_type": ["ECO:0001091"],          // knockout phenotypic evidence
   "publications": ["PMID:24360282"], "primary_knowledge_source": "infores:biolean",
   "supporting_text": ["Deleting SIRT1 accelerates this process"] },

 { "id": "e:g13-6", "category": ["biolink:ChemicalOrDrugOrTreatmentToDiseaseOrPhenotypicFeatureAssociation"],
   "subject": "CHEBI:50383",           // nicotinamide mononucleotide (agent named in title note, not abstract)
   "predicate": "biolink:ameliorates_condition",
   "object": "MP:0006036",             // abnormal mitochondrial physiology
   "population_context_qualifier": "_:pop-g13-old",
   "knowledge_level": "knowledge_assertion", "agent_type": "manual_agent",
   "has_evidence_of_type": ["ECO:0007119"],
   "publications": ["PMID:24360282"], "primary_knowledge_source": "infores:biolean",
   "supporting_text": ["raising NAD(+) levels in old mice restores mitochondrial function to that of a young mouse"] },

 { "id": "e:g13-7", "category": ["biolink:ChemicalOrDrugOrTreatmentToDiseaseOrPhenotypicFeatureAssociation"],
   "subject": "CHEBI:50383",
   "predicate": "biolink:ameliorates_condition",
   "object": "MP:0006036",
   "negated": true,                    // "in a SIRT1-dependent manner"
   "population_context_qualifier": "_:pop-g13-sirt1ko-old",
   "knowledge_level": "knowledge_assertion", "agent_type": "manual_agent",
   "has_evidence_of_type": ["ECO:0001091"],
   "publications": ["PMID:24360282"], "primary_knowledge_source": "infores:biolean" },

 { "id": "e:g13-8", "category": ["biolink:ChemicalAffectsBiologicalEntityAssociation"],
   "subject": "CHEBI:50383",
   "predicate": "biolink:affects", "qualified_predicate": "biolink:causes",
   "object": "GO:0006119",             // oxidative phosphorylation
   "object_direction_qualifier": "increased",
   "species_context_qualifier": "NCBITaxon:10090",
   "knowledge_level": "knowledge_assertion", "agent_type": "manual_agent",
   "has_evidence_of_type": ["ECO:0007119"],
   "publications": ["PMID:24360282"], "primary_knowledge_source": "infores:biolean" }
]
```

Could not express:
- The causal chain NAD+ decline -> HIF-1a -> disrupted nucleus-mitochondria signalling -> fewer mtDNA-encoded
  subunits -> mitochondrial dysfunction, as one pathway. It is 4 loose edges; no ordering or mediation.
- "PGC-1a/b-*independent*": no way to say a pathway does not go through a given gene.
- "Under normoxic conditions" / "pseudohypoxic state" (an environmental condition and a cell state).
- "Accelerates" (rate of an age-dependent process); e:g13-5 only says "causes".
- "Restores to that of a young mouse": comparison to a reference group.
- "Apparently reversible": an author's hedge. `knowledge_level` is per edge, no hedging slot.
- Parallels to Warburg reprogramming (analogy).
- Aging itself as an agent (GO:0007568 `aging` is obsolete; a life-stage node as subject is a stretch).

---

## Mills 2016, PMID:28068222 (12-month NMN mitigates age-associated decline in mice). Provenance: abstract

"Suppressed age-associated X" maps best to `preventative_for_condition` (onset prevented in normal aging),
not `ameliorates_condition` (existing condition). Every phenotype becomes a separate edge with the same
population node. Dose (not in abstract), route and duration go in that node as free text only.

```jsonc
// KGX nodes
[
 { "id": "_:pop-m16-b6n", "category": ["biolink:PopulationOfIndividualOrganisms"],
   "name": "wild-type C57BL/6N mice, regular chow, normal aging",
   "in_taxon": ["NCBITaxon:10090"],
   "description": "C57BL/6N strain (?:unverified, no OLS-resolvable strain ID); oral NMN for 12 months; dose and sex not in abstract" }
]
```

```jsonc
[
 { "id": "e:m16-1", "category": ["biolink:ChemicalAffectsBiologicalEntityAssociation"],
   "subject": "CHEBI:50383",           // nicotinamide mononucleotide
   "predicate": "biolink:affects", "qualified_predicate": "biolink:causes",
   "object": "GO:0009435",             // NAD+ biosynthetic process
   "object_direction_qualifier": "increased",
   "species_context_qualifier": "NCBITaxon:10090",
   "knowledge_level": "knowledge_assertion", "agent_type": "manual_agent",
   "has_evidence_of_type": ["ECO:0007119"],          // in vivo assay evidence used in manual assertion
   "publications": ["PMID:28068222"], "primary_knowledge_source": "infores:biolean",
   "supporting_text": ["Orally administered NMN was quickly utilized to synthesize NAD+ in tissues"] },

 { "id": "e:m16-2", "category": ["biolink:ChemicalOrDrugOrTreatmentToDiseaseOrPhenotypicFeatureAssociation"],
   "subject": "CHEBI:50383",
   "predicate": "biolink:preventative_for_condition",
   "object": "MP:0001260",             // increased body weight
   "population_context_qualifier": "_:pop-m16-b6n",
   "knowledge_level": "knowledge_assertion", "agent_type": "manual_agent",
   "has_evidence_of_type": ["ECO:0007119"],
   "publications": ["PMID:28068222"], "primary_knowledge_source": "infores:biolean",
   "supporting_text": ["NMN suppressed age-associated body weight gain"] },
 // e:m16-3..7: identical shape to e:m16-2, object =
 //   MP:0004890 decreased energy expenditure   ("enhanced energy metabolism")
 //   MP:0031392 hypoactivity                   ("promoted physical activity")
 //   MP:0005331 insulin resistance             ("improved insulin sensitivity")
 //   MP:0003949 abnormal circulating lipid level ("plasma lipid profile")
 //   MP:0005253 abnormal eye physiology        ("ameliorated eye function")

 { "id": "e:m16-8", "category": ["biolink:ChemicalAffectsBiologicalEntityAssociation"],
   "subject": "CHEBI:50383",
   "predicate": "biolink:affects", "qualified_predicate": "biolink:causes",
   "object": "GO:0006119",             // oxidative phosphorylation ("mitochondrial oxidative metabolism")
   "object_direction_qualifier": "increased",
   "anatomical_context_qualifier": ["UBERON:0001134"],   // skeletal muscle tissue
   "species_context_qualifier": "NCBITaxon:10090",
   "knowledge_level": "knowledge_assertion", "agent_type": "manual_agent",
   "has_evidence_of_type": ["ECO:0007119"],
   "publications": ["PMID:28068222"], "primary_knowledge_source": "infores:biolean" },

 { "id": "e:m16-9", "category": ["biolink:ChemicalOrDrugOrTreatmentAdverseEventAssociation"],
   "subject": "CHEBI:50383",
   "predicate": "biolink:has_adverse_event",
   "object": "?:unverified",           // "obvious toxicity or deleterious effects": no single phenotype term
   "negated": true,
   "population_context_qualifier": "_:pop-m16-b6n",
   "knowledge_level": "knowledge_assertion", "agent_type": "manual_agent",
   "has_evidence_of_type": ["ECO:0007119"],
   "publications": ["PMID:28068222"], "primary_knowledge_source": "infores:biolean",
   "supporting_text": ["Without any obvious toxicity or deleterious effects"] },

 { "id": "e:m16-10", "category": ["biolink:ChemicalOrDrugOrTreatmentToDiseaseOrPhenotypicFeatureAssociation"],
   "subject": "CHEBI:50383",
   "predicate": "biolink:preventative_for_condition",
   "object": "?:unverified",           // "age-associated physiological decline": no MONDO/HP term
   "knowledge_level": "prediction",   // authors' extrapolation to humans; no species slot on this class
   "agent_type": "manual_agent",
   "has_evidence_of_type": ["ECO:0006185"],          // author inference
   "publications": ["PMID:28068222"], "primary_knowledge_source": "infores:biolean",
   "supporting_text": ["highlight the preventive and therapeutic potential of NAD+ intermediates as effective anti-aging interventions in humans"] }
]
```

Could not express:
- Duration (12 months), route (oral), dose, start age: no slots on these classes (`timepoint` exists on
  `association` but means a point in time; nothing for dose). Only free text in the population node.
- "Prevented age-associated gene expression changes in key metabolic organs" (no gene list; "prevented a
  change" is a second-order direction).
- "Mitonuclear protein imbalance" (a ratio between two protein sets).
- "In humans" on e:m16-10: the class has no `species_context_qualifier`; a human population node would be
  needed just to say "human".
- Mouse strain as a CURIE (no OLS-resolvable strain ontology for C57BL/6N).
- Effect sizes / p-values: allowed slots, but none in the abstract.

---

## Das 2018, PMID:29570999 (endothelial NAD+-H2S signalling and vascular aging). Provenance: abstract

```jsonc
// KGX nodes
[
 { "id": "_:pop-d18-old", "category": ["biolink:PopulationOfIndividualOrganisms"],
   "name": "elderly mice", "in_taxon": ["NCBITaxon:10090"],
   "description": "aged Mus musculus; age, strain, sex, NMN dose and duration not in abstract" },
 { "id": "_:pop-d18-ecsirt1ko-old", "category": ["biolink:PopulationOfIndividualOrganisms"],
   "name": "elderly mice lacking endothelial SIRT1", "in_taxon": ["NCBITaxon:10090"],
   "description": "endothelial-specific Sirt1 loss implied by 'SIRT1-dependent'; design not in abstract" }
]
```

```jsonc
[
 { "id": "e:d18-1", "category": ["biolink:GeneOrGeneProductOrGeneFamilyToBiologicalProcessOrActivityAssociation"],
   "subject": "UniProtKB:Q923E4",      // SIRT1 (mouse)
   "predicate": "biolink:actively_involved_in",
   "object": "GO:0001525",             // angiogenesis
   // class has no anatomical_context_qualifier: "in endothelial cells (CL:0000115)" is lost here
   "knowledge_level": "knowledge_assertion", "agent_type": "manual_agent",
   "has_evidence_of_type": ["ECO:0001091"],          // knockout phenotypic evidence
   "publications": ["PMID:29570999"], "primary_knowledge_source": "infores:biolean",
   "supporting_text": ["SIRT1 in endothelial cells is a key mediator of pro-angiogenic signals secreted from myocytes"] },

 { "id": "e:d18-2", "category": ["biolink:ChemicalOrDrugOrTreatmentToDiseaseOrPhenotypicFeatureAssociation"],
   "subject": "CHEBI:50383",           // nicotinamide mononucleotide
   "predicate": "biolink:ameliorates_condition",
   "object": "MP:0020329",             // decreased capillary density
   "anatomical_context_qualifier": ["UBERON:0001134"],   // skeletal muscle tissue (assumed: myocyte context)
   "population_context_qualifier": "_:pop-d18-old",
   "knowledge_level": "knowledge_assertion", "agent_type": "manual_agent",
   "has_evidence_of_type": ["ECO:0007119"],          // in vivo assay evidence used in manual assertion
   "publications": ["PMID:29570999"], "primary_knowledge_source": "infores:biolean",
   "supporting_text": ["promoting SIRT1-dependent increases in capillary density"] },

 { "id": "e:d18-3", "category": ["biolink:ChemicalOrDrugOrTreatmentToDiseaseOrPhenotypicFeatureAssociation"],
   "subject": "CHEBI:50383",
   "predicate": "biolink:ameliorates_condition",
   "object": "MP:0012106",             // impaired exercise endurance
   "population_context_qualifier": "_:pop-d18-old",
   "knowledge_level": "knowledge_assertion", "agent_type": "manual_agent",
   "has_evidence_of_type": ["ECO:0007119"],
   "publications": ["PMID:29570999"], "primary_knowledge_source": "infores:biolean",
   "supporting_text": ["improves blood flow and increases endurance in elderly mice"] },

 { "id": "e:d18-4", "category": ["biolink:ChemicalOrDrugOrTreatmentToDiseaseOrPhenotypicFeatureAssociation"],
   "subject": "CHEBI:50383",
   "predicate": "biolink:ameliorates_condition",
   "object": "?:unverified",           // reduced (muscle) blood flow: no MP/HP term found
   "population_context_qualifier": "_:pop-d18-old",
   "knowledge_level": "knowledge_assertion", "agent_type": "manual_agent",
   "has_evidence_of_type": ["ECO:0007119"],
   "publications": ["PMID:29570999"], "primary_knowledge_source": "infores:biolean" },

 { "id": "e:d18-5", "category": ["biolink:ChemicalAffectsBiologicalEntityAssociation"],
   "subject": "CHEBI:50383",
   "predicate": "biolink:affects", "qualified_predicate": "biolink:causes",
   "object": "GO:0001525",             // angiogenesis
   "object_direction_qualifier": "increased",
   "anatomical_context_qualifier": ["CL:0000115", "UBERON:0001134"],   // endothelial cell; skeletal muscle tissue
   "species_context_qualifier": "NCBITaxon:10090",
   "knowledge_level": "knowledge_assertion", "agent_type": "manual_agent",
   "has_evidence_of_type": ["ECO:0007119"],
   "publications": ["PMID:29570999"], "primary_knowledge_source": "infores:biolean" },

 { "id": "e:d18-6", "category": ["biolink:ChemicalOrDrugOrTreatmentToDiseaseOrPhenotypicFeatureAssociation"],
   "subject": "CHEBI:50383",
   "predicate": "biolink:ameliorates_condition",
   "object": "MP:0020329",
   "negated": true,                    // "SIRT1-dependent"
   "population_context_qualifier": "_:pop-d18-ecsirt1ko-old",
   "knowledge_level": "knowledge_assertion", "agent_type": "manual_agent",
   "has_evidence_of_type": ["ECO:0001091"],
   "publications": ["PMID:29570999"], "primary_knowledge_source": "infores:biolean" },

 { "id": "e:d18-7", "category": ["biolink:ChemicalEntityToChemicalEntityAssociation"],
   "subject": "CHEBI:16136",           // hydrogen sulfide
   "predicate": "biolink:regulates",   // "regulator of endothelial NAD+ levels": no direction slot on this class
   "object": "CHEBI:15846",            // NAD(+)
   "species_context_qualifier": "NCBITaxon:10090",
   "knowledge_level": "knowledge_assertion", "agent_type": "manual_agent",
   "has_evidence_of_type": ["ECO:0007119"],
   "publications": ["PMID:29570999"], "primary_knowledge_source": "infores:biolean" }
]
```

Could not express:
- Cell-to-cell signalling: "pro-angiogenic signals *secreted from myocytes*" acting on endothelial SIRT1.
  Two cell types in one statement; one `anatomical_context_qualifier` list cannot say who signals to whom.
- Synergy: NMN effect "augmented by exercise or increasing H2S". No interaction/combination term; exercise
  is not even a node type with a fitting edge class.
- H2S as a "DR mimetic" (a role by analogy to dietary restriction).
- Endothelial context on e:d18-1 (that class has no qualifiers at all).
- Blood flow phenotype (no MP/HP term found).
- "Virtuous cycle of mobility" and implications for humans (speculation; could be a `prediction` edge but
  there is no target term).

---

## Yoshino 2021, PMID:33888596 (NMN in prediabetic women, RCT). Provenance: abstract

This is where Biolink is at home: a clinical trial node, `in_clinical_trials_for`, human species, ECO
`clinical study evidence`. Per the Biolink definition of `treats`, a 10-week trial does not license an
asserted `treats` edge, so `treats` is only a `prediction` (e:y21-8).

```jsonc
// KGX nodes
[
 { "id": "clinicaltrials:NCT03151239", "category": ["biolink:ClinicalTrial"],
   "name": "NMN supplementation in prediabetic postmenopausal women",
   "study_method_types": ["NCIT:C46079", "NCIT:C203925", "NCIT:C15228"],   // randomized controlled; placebo-controlled; double blind
   "study_cohort": "postmenopausal women with prediabetes who were overweight or obese",
   "study_context": "10-week oral NMN vs placebo; insulin-stimulated glucose disposal by hyperinsulinemic-euglycemic clamp; skeletal muscle biopsies" },
 { "id": "_:pop-y21-women", "category": ["biolink:PopulationOfIndividualOrganisms"],
   "name": "postmenopausal overweight/obese women with prediabetes", "in_taxon": ["NCBITaxon:9606"],
   "description": "female (PATO:0000383); postmenopausal (EFO:0002721); overweight (HP:0025502) or obesity (MONDO:0011122); prediabetes (MONDO:0006920)" }
]
```

```jsonc
[
 { "id": "e:y21-1", "category": ["biolink:ChemicalOrDrugOrTreatmentToDiseaseOrPhenotypicFeatureAssociation"],
   "subject": "CHEBI:50383",           // nicotinamide mononucleotide
   "predicate": "biolink:in_clinical_trials_for",
   "object": "MONDO:0006920",          // prediabetes syndrome
   "population_context_qualifier": "_:pop-y21-women",
   "has_supporting_studies": ["clinicaltrials:NCT03151239"],
   "treatment_outcome": ["improved"],
   "knowledge_level": "knowledge_assertion", "agent_type": "manual_agent",
   "has_evidence_of_type": ["ECO:0007121"],          // clinical study evidence used in manual assertion
   "publications": ["PMID:33888596"], "primary_knowledge_source": "infores:biolean" },

 { "id": "e:y21-2", "category": ["biolink:ChemicalOrDrugOrTreatmentToDiseaseOrPhenotypicFeatureAssociation"],
   "subject": "CHEBI:50383",
   "predicate": "biolink:ameliorates_condition",
   "object": "HP:0000855",             // Insulin resistance
   "anatomical_context_qualifier": ["UBERON:0001134"],   // skeletal muscle tissue
   "disease_context_qualifier": "MONDO:0006920",
   "population_context_qualifier": "_:pop-y21-women",
   "has_supporting_studies": ["clinicaltrials:NCT03151239"],
   "knowledge_level": "knowledge_assertion", "agent_type": "manual_agent",
   "has_evidence_of_type": ["ECO:0007121"],
   "publications": ["PMID:33888596"], "primary_knowledge_source": "infores:biolean",
   "supporting_text": ["NMN increases muscle insulin sensitivity, insulin signaling, and remodeling in women with prediabetes who are overweight or obese"] },

 { "id": "e:y21-3", "category": ["biolink:ChemicalAffectsBiologicalEntityAssociation"],
   "subject": "CHEBI:50383",
   "predicate": "biolink:affects", "qualified_predicate": "biolink:causes",
   "object": "GO:0032868",             // response to insulin (insulin-stimulated glucose disposal)
   "object_direction_qualifier": "increased",
   "anatomical_context_qualifier": ["UBERON:0001134"],
   "species_context_qualifier": "NCBITaxon:9606",    // this class: species yes, population/sex no
   "has_supporting_studies": ["clinicaltrials:NCT03151239"],
   "knowledge_level": "knowledge_assertion", "agent_type": "manual_agent",
   "has_evidence_of_type": ["ECO:0007121"],
   "publications": ["PMID:33888596"], "primary_knowledge_source": "infores:biolean" },

 { "id": "e:y21-4", "category": ["biolink:ChemicalAffectsGeneAssociation"],
   "subject": "CHEBI:50383",
   "predicate": "biolink:affects", "qualified_predicate": "biolink:causes",
   "object": "UniProtKB:P31749",       // AKT1 (human)
   "object_aspect_qualifier": "phosphorylation",
   "object_direction_qualifier": "increased",
   "anatomical_context_qualifier": ["UBERON:0001134"],
   "species_context_qualifier": "NCBITaxon:9606",
   "has_supporting_studies": ["clinicaltrials:NCT03151239"],
   "knowledge_level": "knowledge_assertion", "agent_type": "manual_agent",
   "has_evidence_of_type": ["ECO:0007121"],
   "publications": ["PMID:33888596"], "primary_knowledge_source": "infores:biolean" },
 // e:y21-5: identical to e:y21-4 with object UniProtKB:P42345 (MTOR, human).

 { "id": "e:y21-6", "category": ["biolink:ChemicalAffectsGeneAssociation"],
   "subject": "CHEBI:50383",
   "predicate": "biolink:affects", "qualified_predicate": "biolink:causes",
   "object": "UniProtKB:P09619",       // PDGFRB (human)
   "object_aspect_qualifier": "expression",
   "object_direction_qualifier": "upregulated",
   "anatomical_context_qualifier": ["UBERON:0001134"],
   "species_context_qualifier": "NCBITaxon:9606",
   "has_supporting_studies": ["clinicaltrials:NCT03151239"],
   "knowledge_level": "knowledge_assertion", "agent_type": "manual_agent",
   "has_evidence_of_type": ["ECO:0007121"],
   "publications": ["PMID:33888596"], "primary_knowledge_source": "infores:biolean" },

 { "id": "e:y21-7", "category": ["biolink:ChemicalAffectsBiologicalEntityAssociation"],
   "subject": "NCIT:C753",             // Placebo
   "predicate": "biolink:affects",
   "object": "GO:0032868",
   "negated": true,                    // "did not change after placebo treatment"
   "anatomical_context_qualifier": ["UBERON:0001134"],
   "species_context_qualifier": "NCBITaxon:9606",
   "has_supporting_studies": ["clinicaltrials:NCT03151239"],
   "knowledge_level": "knowledge_assertion", "agent_type": "manual_agent",
   "has_evidence_of_type": ["ECO:0007121"],
   "publications": ["PMID:33888596"], "primary_knowledge_source": "infores:biolean" },

 { "id": "e:y21-8", "category": ["biolink:ChemicalOrDrugOrTreatmentToDiseaseOrPhenotypicFeatureAssociation"],
   "subject": "CHEBI:50383",
   "predicate": "biolink:treats",
   "object": "MONDO:0006920",
   "knowledge_level": "prediction",   // Biolink: asserted 'treats' needs approval / phase 3+ evidence
   "agent_type": "manual_agent",
   "has_evidence_of_type": ["ECO:0007121"],
   "publications": ["PMID:33888596"], "primary_knowledge_source": "infores:biolean" }
]
```

Could not express:
- Sex and menopausal status as qualifiers. `sex_qualifier` is not on any chemical-to-X class; it lives only
  in the population node, and on e:y21-3..6 (which allow species but not population) it is gone entirely.
- Trial size, effect sizes, p-values: slots exist (`study_size`, `effect_size`, `p_value`), but the abstract
  gives no numbers.
- The *comparison* structure: "increased after NMN but did not change after placebo". Two independent edges
  (e:y21-3, e:y21-7); the between-arm contrast that makes it an RCT result is not a first-class thing.
- Dose and duration (only free text on the trial node).
- "Muscle remodeling" as a process (no verified GO term for skeletal muscle tissue remodeling).
- Cross-species transfer: the abstract opens with the rodent findings ("In rodents, obesity and aging impair
  NAD+ biosynthesis"). There is no edge-to-edge link from this human result to e:y11-6 / e:m16-5. Each is a
  separate edge with its own species/population; "replicates in human" is left to the reader.

---

## Fit table

| Aspect | Expressible? | How |
|---|---|---|
| Direction of effect | partial | `object_direction_qualifier` / `subject_direction_qualifier` (`increased`, `decreased`, `upregulated`, `downregulated`) plus `qualified_predicate: biolink:causes`. Only on some classes: chemical-to-chemical has none (NMN raises NAD+ is not sayable). No "restores", "prevents a change", "net vs gross", or membrane sidedness. |
| Quantitative result | partial | `effect_size` + `effect_type` (statistical metrics only), `p_value`, `adjusted_p_value`, `statistical_significance_qualifier`, `study_size` on the Study node. Nothing for stoichiometry (H+/O = 4 and 6), pH values, or a dose-response. Those go to `supporting_text`. |
| Species / strain | partial | `species_context_qualifier` (NCBITaxon) on chemical-affects and some gene classes; absent on chemical-to-disease/phenotype and on base `Association`. Strain has no slot and no OLS-resolvable ID. One species per edge, so chimeric systems (bacteriorhodopsin + bovine ATPase) cannot be described. |
| Age / stage | no (practically) | `stage_qualifier` exists but only on gene-expression classes. "Old mice" goes into a population node as text, or a life-stage node used as a subject (stretch). GO `aging` is obsolete. |
| Tissue / cell | yes | `anatomical_context_qualifier` (UBERON, CL, GO CC; multivalued), `subject_context_qualifier` / `object_context_qualifier`. Cannot say which cell signals to which (Das 2018). Not on base `Association` or gene-to-process classes. |
| Disease model | partial | `disease_context_qualifier` (MONDO) plus `population_context_qualifier` pointing at a minted `PopulationOfIndividualOrganisms` node; predicate `beneficial_in_models_for` exists for exactly this. The model itself (HFD, aged, KO) has no structured slots on the population node. |
| Dose / duration | no | No dose slot; `timepoint` is a time point, not a duration. Free text in `study_context` or the population node only. |
| Hypothesis vs result | yes | `knowledge_level`: `prediction` (alias "hypothesis") vs `knowledge_assertion` vs `observation`; ECO `author inference` vs experimental codes in `has_evidence_of_type`. Cannot tell a core hypothesis from a testable consequence; no hedging. |
| Rival hypotheses | no | Edges cannot reference edges. Rivalry can only be read off two `prediction` edges with the same subject and different objects; nothing says they exclude each other. |
| Evidence type | yes | ECO in `has_evidence_of_type`, `agent_type`, `publications`, `has_supporting_studies` (ClinicalTrial node with NCIT method types). Translator's strongest area. Note: ECO goes in `has_evidence_of_type`, not `has_evidence`. |
| Cross-species transfer | no | Separate edges per species, no link between them. An extrapolation can be a `prediction` edge, but chemical-to-disease classes cannot even carry "in humans". |
| Negative results | partial | `negated: true` on a copy of the triple. Works for "C~I does not exist / is not input of ATP synthesis", "no adverse events", "placebo did not change X", and dependency-by-knockout (`negated` in a KO population). Fails for negatives about a *quantity* ("uncouplers do not change H+/O"). |

## Verdict

(a) For the chemiosmotic papers Biolink is a poor fit. They are about mechanism (coupling, stoichiometry,
sidedness, sufficiency), and Biolink's process-to-process edges are untyped `causes`, carry no legal context
qualifiers, and say nothing about numbers or orientation. The controversy itself is invisible: hypotheses
become `prediction` edges, refutation is a `negated` copy of the rival triple, and support is "same triple,
more PMIDs". This is readable by convention, but no field links Slater's edge to the edges that kill it.
Hypothetical entities like C~I have no home at all.

(b) For the NMN mouse papers the fit is better but leaky. Chemical -> phenotype/disease, chemical -> gene with
aspect + direction, ECO codes, and the clinical-trial node map cleanly, and `negated` in a knockout population
is a neat way to write "SIRT1-dependent". The awkward part is that context slots are class-bound: the main
"NMN ameliorates X" class has no species, sex, stage, dose, or duration slot. So the mouse model, age, sex
and dose all end up as free text on a minted population node. Mediation ("by restoring NAD+", "partly through
SIRT1") and mouse-to-human transfer cannot be expressed, and those are the claims that matter most.

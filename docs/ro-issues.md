# Draft RO issues (not posted)

Draft issues for https://github.com/oborel/obo-relations, one per bad axiom family. Seven axioms, four issues: rows 14+16 share a cause, as do rows 87-89. Row numbers are from `docs/ro-chains.md`. Axioms are from RO release 2026-09-04 (`data/ro.owl`). All seven are still in `src/ontology/ro-edit.owl` on master as of 2026-10-27. Regression details: `docs/ro-fix-regression.md`.

Existing-issue search: `gh search issues --repo oborel/obo-relations` with each label, each ID (`RO_` and `RO:` forms) and related words. Results are given per issue below.

---

## Issue 1. 'immediately preceded by' and 'immediately precedes' chains conclude that a process is preceded by its own part

Rows 14, 16.

**Axioms**

```
SubObjectPropertyOf(ObjectPropertyChain(obo:RO_0002224 obo:RO_0002230) obo:RO_0002087)
  starts with o ends with -> immediately preceded by
SubObjectPropertyOf(ObjectPropertyChain(obo:RO_0002230 obo:RO_0002224) obo:RO_0002090)
  ends with o starts with -> immediately precedes
```

**Why it is wrong.** RO's own definitions: `a starts with b` gives α(b) = α(a) and ω(b) < ω(a). `b ends with c` gives α(c) > α(b) and ω(c) = ω(b). So c lies strictly inside a: α(a) < α(c) and ω(c) < ω(a). But `a immediately preceded by c` needs ω(c) = α(a), so c would end before it starts. When the premises hold, the conclusion is always false, not just sometimes.

**Instance.** Wound healing *starts with* hemostasis. Hemostasis *ends with* fibrin clot formation. The chain concludes that wound healing is *immediately preceded by* fibrin clot formation, but clot formation is a step inside wound healing. Mirror case (RO_0002090): the mitotic cell cycle *ends with* M phase, M phase *starts with* prophase, so the chain concludes that the cell cycle *immediately precedes* prophase.

**Proposed fix.** Delete both chains. If a replacement is wanted, these are sound under the same definitions (not regression-tested): `starts with o immediately preceded by -> immediately preceded by` and `immediately preceded by o ends with -> immediately preceded by`, plus their mirrors for 'immediately precedes'. Also a side note: the rdfs:comment on RO_0002087 is a copy of the RO_0002090 comment ("end(X) simultaneous_with start(Y)"), so it is backwards for 'preceded by'.

**Regression.** Removing both chains changes no inferred TBox axiom in RO (ELK, JFact). RO stays consistent, with no unsatisfiable classes. On test data (HermiT), the two wrong facts above are no longer inferred, and nothing else changes. Uberon copies both chains into `uberon.obo` as `holds_over_chain` and uses 'immediately preceded by' in 8 asserted stage relationships. Those 8 are asserted, so they stay. Uberon has no starts_with/ends_with pair that the chain could fire on. GO and CL: no uses.

**Existing issues.** None about these chains. #93 (closed, process-boundary relations) discusses `ends-at-point o inv(starts-at-point) -> immediately-precedes` as a sound pattern.

---

## Issue 2. 'spatially coextensive with' chain concludes that two things in the same container are coextensive

Row 79.

**Axiom**

```
SubObjectPropertyOf(ObjectPropertyChain(obo:RO_0001025 ObjectInverseOf(obo:RO_0001025)) obo:RO_0002379)
  located in o inverse(located in) -> spatially coextensive with
```

**Why it is wrong.** RO's definition of RO_0002379 is "x and y have the same location". The chain only says that x and y are both somewhere inside the same z. Sharing a container does not even give overlap, never mind coextension.

**Instance.** The heart is *located in* the thoracic cavity, and the thoracic cavity is the *location of* the left lung. The chain concludes that the heart is *spatially coextensive with* the left lung. Uberon gives real cases: `uberon.obo` has 67 class-level pairs where this chain fires. Most are of the form 'tracheobronchial lymph node' located_in 'mediastinum', 'mediastinum' location_of 'organism substance', so the lymph node is coextensive with some organism substance. 65 of the 67 end in 'organism substance'. The other 2 are reflexive (a fluid coextensive with itself).

**Proposed fix.** Delete. No two-step chain over located_in gives coextension.

**Regression.** No inferred TBox axiom in RO changes (JFact; ELK cannot see this axiom because it drops ObjectInverseOf). RO stays consistent and coherent. On test data (HermiT), heart~lung and heart~heart are no longer inferred. In Uberon the bad conclusions above are entailed only by DL reasoners (HermiT and similar), not ELK, so a standard ELK build will not show them. GO and CL: no uses.

**Existing issues.** None found ("coextensive", RO_0002379, RO:0002379). #618 only lists the term.

---

## Issue 3. 'indirectly negatively regulates' chains compose two negative steps into a negative one

Rows 87, 88, 89.

**Axioms**

```
SubObjectPropertyOf(ObjectPropertyChain(obo:RO_0002409 obo:RO_0002630) obo:RO_0002409)
SubObjectPropertyOf(ObjectPropertyChain(obo:RO_0002630 obo:RO_0002409) obo:RO_0002409)
SubObjectPropertyOf(ObjectPropertyChain(obo:RO_0002630 obo:RO_0002630) obo:RO_0002409)
  (indirectly neg o directly neg, directly neg o indirectly neg, directly neg o directly neg) -> indirectly negatively regulates
```

**Why it is wrong.** Two negative steps give a positive effect. RO already says this in two places: `negatively regulates o negatively regulates -> positively regulates` (RO_0002213), and `indirectly neg o indirectly neg -> indirectly positively regulates` (RO_0002407). The three chains above say the opposite. #182 (closed 2017) fixed the same mistake for 'negatively regulates' by removing its transitivity.

**Instance (one pathway, all three rows).** Akt *directly negatively regulates* GSK3 (it phosphorylates Ser9). GSK3 *directly negatively regulates* glycogen synthase (it phosphorylates and inactivates it). Row 89 concludes that Akt *indirectly negatively regulates* glycogen synthase, but insulin acting through Akt switches glycogen synthase on. Row 87: PTEN *indirectly negatively regulates* Akt (by removing PIP3), then Akt directly negatively regulates GSK3, so the chain says PTEN negatively regulates GSK3, when in fact PTEN keeps GSK3 active. Row 88: Akt directly negatively regulates GSK3, and GSK3 *indirectly negatively regulates* glycogen biosynthesis, so the chain says Akt negatively regulates glycogen synthesis.

**Proposed fix.** Move the three chains to the correct target, and add the mixed-sign chains:

```
# neg o neg -> positive (retarget the three)
SubObjectPropertyOf(ObjectPropertyChain(obo:RO_0002409 obo:RO_0002630) obo:RO_0002407)
SubObjectPropertyOf(ObjectPropertyChain(obo:RO_0002630 obo:RO_0002409) obo:RO_0002407)
SubObjectPropertyOf(ObjectPropertyChain(obo:RO_0002630 obo:RO_0002630) obo:RO_0002407)
# neg o pos and pos o neg -> negative
SubObjectPropertyOf(ObjectPropertyChain(obo:RO_0002409 obo:RO_0002629) obo:RO_0002409)
SubObjectPropertyOf(ObjectPropertyChain(obo:RO_0002629 obo:RO_0002409) obo:RO_0002409)
SubObjectPropertyOf(ObjectPropertyChain(obo:RO_0002630 obo:RO_0002629) obo:RO_0002409)
SubObjectPropertyOf(ObjectPropertyChain(obo:RO_0002629 obo:RO_0002630) obo:RO_0002409)
```

All of these pass the OWL 2 DL profile check (regularity). One limit: `indirectly pos o directly neg -> indirectly neg` (RO_0002407 then RO_0002630) cannot be added. With the existing `RO_0002409 o RO_0002409 -> RO_0002407` it makes a cycle in the chain hierarchy, and the OWL API reports "Use of property in chain causes cycle".

**Related, same bug.** RO_0002409 is also declared `TransitiveObjectProperty`, which is neg o neg -> neg again, and it clashes with `RO_0002409 o RO_0002409 -> RO_0002407`. Suggest removing it, as #182 did for RO_0002212. (Removing it changes no inferred axiom; see regression.)

**Regression.** All versions (only the 4 mixed-sign chains; plus the 3 retargeted chains; with or without transitivity) change no inferred TBox axiom in RO (ELK, JFact) and add no unsatisfiable classes. On test data (HermiT) with the Akt/GSK3 facts above, unmodified RO infers PTEN regulates glycogen synthase *both* positively and negatively. With only the mixed-sign chains, Akt→glycogen synthase is lost entirely, and transitivity still gives insulin receptor *negatively* regulating glycogen biosynthesis. With retarget plus no transitivity, every inferred sign is correct. GO, Uberon and CL `.obo` files have no assertions using RO_0002407/2409/2629/2630. The real users are GO-CAM models and other ABox data with direct regulation links, which these files do not cover.

**Existing issues.** None about these chains. Related: #182 (same sign error, fixed for 'negatively regulates'), #631 and #159 (labels and definitions of the direct and indirect regulation terms).

---

## Issue 4. 'provides input for' chain is missing an inverse

Row 90.

**Axiom**

```
SubObjectPropertyOf(ObjectPropertyChain(obo:RO_0002234 obo:RO_0002233) obo:RO_0002413)
  has output o has input -> provides input for
```

**Why it is wrong.** RO's definition: "p provides input for q iff ... there exists some c such that p has_output c and q has_input c". That is `has output o inverse(has input)`. As written, the middle node must be both an output (a material entity) and the subject of has input (domain: process). So on well-typed data the chain never fires, and the intended inference is never made.

**Instance.** Glycolysis *has output* pyruvate, and the pyruvate dehydrogenase reaction *has input* pyruvate. The intended conclusion, glycolysis *provides input for* the PDH reaction, does not follow from the axiom. The chain fires only if you claim something like "pyruvate has input c", which is a type error.

**Proposed fix.**

```
SubObjectPropertyOf(ObjectPropertyChain(obo:RO_0002234 ObjectInverseOf(obo:RO_0002233)) obo:RO_0002413)
```

or use the named inverse `obo:RO_0002352` ('input of') if the RO style avoids ObjectInverseOf. Caveat for reviewers: the fixed chain leaves out the 'immediately causally upstream of' condition in the definition, so it will link any two processes that share a currency metabolite (glycolysis has output ATP, actin polymerisation has input ATP).

**Regression.** No inferred TBox axiom in RO changes (JFact; ELK drops the fixed axiom because it uses an inverse). On test data (HermiT), glycolysis provides input for the PDH reaction is now inferred, and is missed before the fix. `uberon.obo` copies the faulty chain into its RO:0002413 Typedef (`holds_over_chain: RO:0002234 RO:0002233`), so Uberon would need to sync. Uberon, GO and CL `.obo` files have no has_output/has_input pairs it could fire on.

**Existing issues.** #818 (closed 2025-05) reported that the old chain used the obsolete 'has direct output'. PR #821 replaced it with the current `has output o has input`, which kept the missing inverse from the old chain (`has direct output o has direct input`). The #818 thread suggested "has input o has output", which is also missing the inverse. Related: #740 (open, has_input hierarchy cleanup).

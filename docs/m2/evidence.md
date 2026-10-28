# M2 context, design C: "evidence"

INDRA style. The claim stays bare; context lives on each `Evidence` item; every opinion is
computed *in* a query context, and only evidence that fits the query fuses.

## (a) The design in one paragraph

`Evidence` gains eight optional fields: `taxa` (a list, so a reconstituted chimera can name both
sources), `anatomy`, `cellType`, `component` (added to the brief's list because S4 is about
membranes), `condition` (free text), `inVitro`, `dose` and `duration` (text, recorded and never
used in a computation). A `Ctx` is a *query*, with the same slots plus `inVivoOnly`.
`Evidence.fits q e` holds when each set evidence slot subsumes the query slot. The test uses a
swappable `ContextModel` with a hand-written `is_a` table of 17 rows (NCBITaxon and two GO
membranes) and a transport weight of 3/10. Text conditions must match exactly. An unset evidence
slot fits every query. `Statement.opinion` and `Derivation.opinion` both take `(q : Ctx := {})`,
and every leaf filters its evidence by `q`. The default query is "no context", which only
context-free evidence fits. Old untagged statements therefore give exactly the same numbers, while
tagged evidence is silent unless you ask in its context. Fit is read universally: Eukaryota
evidence fits a mouse query (specialisation is free). Mouse evidence fits neither a Mammalia query
nor an untagged one (generalisation is not free; that is M4). Mouse evidence does not fit a human
query either. One new `Derivation` constructor, `transport src dst d`, evaluates `d` with the
query's taxon swapped to `src` and discounts the result by 3/10 with the new `Opinion.discount`.
It runs only if `src` and `dst` are siblings (neither `is_a` the other) and the query taxon is
`dst` or below it. A general theorem bounds any transported belief by 3/10. `verdict`, `render`,
`report` and `clash` take the query too, and `EstablishedIn q c θ` sits next to `Established`.

## (b) Lean diff

Worktree `git diff` for the core files (Belief +20, Context.lean new 98, Derivation +85 -45,
Evidence +30 -3, lakefile +2 -1). The examples (`BioLean/Examples/Context.lean`, 276 lines) and
the generated 40 (`BioLean/Lib/ContextSample.lean`, 381 lines) are in (c) and (d). All files are
copied to `evidence-lean/`. Results:

- `lake build BioLeanLib`: succeeds, 3157 jobs. GLP1, Ozempic, Textbook, Quantity and the RO
  tests build unchanged.
- `lake build BioLean`: succeeds.
- `lake build TextbookR2` (1,591 generated claims plus the closure certificates): succeeds.

```diff
diff --git a/BioLean/Belief.lean b/BioLean/Belief.lean
index c4308bd..4ea78d0 100644
--- a/BioLean/Belief.lean
+++ b/BioLean/Belief.lean
@@ -215,6 +215,26 @@ theorem chain_le_weakest (x y : Opinion) : (chain x y).belief ≤ (weakest x y).
   · rw [min_eq_left h]; nlinarith [x.belief_nonneg, y.belief_lt_one]
   · rw [min_eq_right h]; nlinarith [y.belief_nonneg, x.belief_lt_one]
 
+/-! ### Discounting (trust in a transfer step) -/
+
+/-- Subjective-logic trust discounting by a fixed weight `w ∈ [0, 1]`: belief and disbelief both
+shrink by `w`, the rest becomes uncertainty. Used for cross-context transport (M2): a mouse result
+read as a human one keeps its direction, at a fraction of its strength. -/
+def discount (w : ℚ) (h0 : 0 ≤ w) (h1 : w ≤ 1) (x : Opinion) : Opinion where
+  belief := w * x.belief
+  disbelief := w * x.disbelief
+  uncertainty := 1 - w * (x.belief + x.disbelief)
+  belief_nonneg := mul_nonneg h0 x.belief_nonneg
+  disbelief_nonneg := mul_nonneg h0 x.disbelief_nonneg
+  uncertainty_pos := by
+    have := x.sum_eq_one; have := x.uncertainty_pos
+    nlinarith [x.belief_nonneg, x.disbelief_nonneg]
+  sum_eq_one := by ring
+
+theorem discount_belief_le (w : ℚ) (h0 : 0 ≤ w) (h1 : w ≤ 1) (x : Opinion) :
+    (discount w h0 h1 x).belief ≤ w := by
+  simp only [discount]; nlinarith [x.belief_le_one]
+
 /-! ### Printing -/
 
 /-- Fixed-point decimal rendering of a rational in `[0, 1]`, for reports. -/
diff --git a/BioLean/Context.lean b/BioLean/Context.lean
new file mode 100644
index 0000000..1b64ead
--- /dev/null
+++ b/BioLean/Context.lean
@@ -0,0 +1,98 @@
+import BioLean.Ontology
+import BioLean.Belief
+
+/-!
+# Context (M2, design "evidence")
+
+INDRA-style: a `Claim` stays bare, and where a result was obtained (taxon, anatomy, cell type,
+membrane, condition, in vitro, dose, duration) is recorded on each `Evidence` item. A `Ctx` is a
+*query*: the context a claim is asked about. Only evidence that fits the query fuses
+(`Evidence.fits`), so the context is enforced when an opinion is computed, not when a claim is
+typed.
+
+Fit is subsumption, read universally: evidence about eukaryotes fits a query about mice
+(specialisation is free); evidence about mice does not fit a query about mammals or a query with
+no taxon (generalisation is not free, it is M4's `generalize`); evidence about mice does not fit a
+query about humans either, unless an explicit `Derivation.transport` step moves it there.
+An unset evidence field means "no restriction stated" and fits every query. That is the default
+for every existing statement, so their opinions are unchanged.
+-/
+
+namespace BioLean
+
+/-- The context a claim is asked about. Unset fields are unrestricted. -/
+structure Ctx where
+  taxon : Option (Entity .taxon) := none
+  anatomy : Option (Entity .anatomy) := none
+  cellType : Option (Entity .cellType) := none
+  component : Option (Entity .component) := none
+  condition : Option String := none
+  /-- Ignore in vitro evidence. -/
+  inVivoOnly : Bool := false
+  deriving Repr
+
+/-- Subsumption between context terms, and the weight of a cross-taxon transport step. Swappable,
+like `EvidenceModel`. -/
+class ContextModel where
+  /-- `isA a b`: the term with CURIE `a` is `b` or a descendant of `b`. -/
+  isA : String → String → Bool
+  transport : ℚ
+  transport_nonneg : 0 ≤ transport
+  transport_le_one : transport ≤ 1
+
+/-- Ancestors of the taxa and components used so far. Hand-written; a real table comes from
+NCBITaxon and GO `is_a`. -/
+def ContextModel.ancestors : List (String × List String) :=
+  let euk := ["NCBITaxon:2759", "NCBITaxon:131567"]
+  let mam := ["NCBITaxon:40674", "NCBITaxon:7742", "NCBITaxon:33208"] ++ euk
+  [ ("NCBITaxon:10090", mam), ("NCBITaxon:9606", mam), ("NCBITaxon:10116", mam),
+    ("NCBITaxon:9913", mam), ("NCBITaxon:40674", mam.drop 1), ("NCBITaxon:7742", mam.drop 2),
+    ("NCBITaxon:33208", euk), ("NCBITaxon:3562", "NCBITaxon:33090" :: euk),
+    ("NCBITaxon:33090", euk), ("NCBITaxon:4751", euk), ("NCBITaxon:2759", ["NCBITaxon:131567"]),
+    ("NCBITaxon:2", ["NCBITaxon:131567"]), ("NCBITaxon:562", ["NCBITaxon:2", "NCBITaxon:131567"]),
+    ("NCBITaxon:2157", ["NCBITaxon:131567"]),
+    ("NCBITaxon:2242", ["NCBITaxon:2157", "NCBITaxon:131567"]),
+    ("GO:0042651", ["GO:0016020"]), ("GO:0005743", ["GO:0016020"]) ]
+
+/-- The default: the table above, and transport at 3/10. -/
+instance ContextModel.standard : ContextModel where
+  isA a b := a == b || ((ContextModel.ancestors.lookup a).getD []).contains b
+  transport := 3 / 10
+  transport_nonneg := by norm_num
+  transport_le_one := by norm_num
+
+namespace Ctx
+
+variable [ContextModel]
+
+/-- Does an evidence slot fit a query slot? Unset evidence fits anything; set evidence fits only
+a query that names the same term or a descendant of it. -/
+def slotFits {k : Kind} (query ev : Option (Entity k)) : Bool :=
+  match ev, query with
+  | none, _ => true
+  | some _, none => false
+  | some e, some q => ContextModel.isA q.curie e.curie
+
+/-- Taxa fit when every evidence taxon subsumes the query taxon. A chimeric system (bacteriorhodopsin
+from *Halobacterium* with bovine ATP synthase) lists both, and so fits no single-taxon query. -/
+def taxaFit (query : Option (Entity .taxon)) (ev : List (Entity .taxon)) : Bool :=
+  match ev, query with
+  | [], _ => true
+  | _ :: _, none => false
+  | ts, some q => ts.all fun t => ContextModel.isA q.curie t.curie
+
+/-- `a` and `b` are distinct taxa, neither inside the other: the only legal transport. -/
+def siblings (a b : Entity .taxon) : Bool :=
+  !ContextModel.isA a.curie b.curie && !ContextModel.isA b.curie a.curie
+
+end Ctx
+
+instance : ToString Ctx where
+  toString x :=
+    let parts : List String :=
+      (x.taxon.toList.map toString) ++ (x.anatomy.toList.map toString) ++
+      (x.cellType.toList.map toString) ++ (x.component.toList.map toString) ++ x.condition.toList ++
+      (if x.inVivoOnly then ["in vivo only"] else [])
+    if parts.isEmpty then "any context" else ", ".intercalate parts
+
+end BioLean
diff --git a/BioLean/Derivation.lean b/BioLean/Derivation.lean
index 993d7ea..719b083 100644
--- a/BioLean/Derivation.lean
+++ b/BioLean/Derivation.lean
@@ -99,27 +99,44 @@ inductive Derivation : Claim → Type
       (ac : Derivation (.notRel r a c h₁)) (bc : Derivation (.rel Rel.isA b c h₂))
       (h₃ : r.accepts k₁ k₂ = true := by decide) :
       Derivation (.notRel r a b h₃)
+  /-- Cross-taxon transport (M2): read `d`, evaluated in taxon `src`, as evidence about the same
+  bare claim in a sibling taxon `dst`, discounted by `ContextModel.transport` (3/10 by default).
+  The only way evidence from one taxon reaches a query about another. The claim does not change,
+  because in this design context lives on evidence, not on claims. -/
+  | transport {c : Claim} (src dst : Entity .taxon) (d : Derivation c) : Derivation c
 
 namespace Derivation
 
-variable [EvidenceModel]
+variable [EvidenceModel] [ContextModel]
 
-/-- The strength of a derivation. -/
-def opinion : {c : Claim} → Derivation c → Opinion
-  | _, .lit s => s.opinion
-  | _, .viaActivity ab bt => ab.opinion.chain bt.opinion
-  | _, .viaAmount am mt => am.opinion.chain mt.opinion
-  | _, .both d₁ d₂ => d₁.opinion.fuse d₂.opinion
-  | _, .relChain ab bc .. => ab.opinion.weakest bc.opinion
-  | _, .notRelSub ab bc .. => ab.opinion.weakest bc.opinion
-  | _, .notRelObj ac bc .. => ac.opinion.weakest bc.opinion
-  | _, .sequencesOver a l .. => a.opinion.weakest l.opinion
-  | _, .pigeonhole i hs e .. => (i.opinion.weakest hs.opinion).weakest e.opinion
-  | _, .perSet p s .. => p.opinion.weakest s.opinion
-  | _, .fusionAdds ix iy o cx cy .. => (((ix.opinion.weakest iy.opinion).weakest o.opinion).weakest cx.opinion).weakest cy.opinion
-  | _, .netYield m u .. => m.opinion.weakest u.opinion
-  | _, .compareIntervals a b .. => a.opinion.weakest b.opinion
-  | _, .weaken _ d => d.opinion
+/-- The strength of a derivation, evaluated in context `q` (default: no context). Every leaf
+filters its evidence by `q`; `transport` is the one rule that changes `q`. -/
+def opinion {c : Claim} (d : Derivation c) (q : Ctx := {}) : Opinion :=
+  go q d
+where
+  go (q : Ctx) : {c : Claim} → Derivation c → Opinion
+  | _, .lit s => s.opinion q
+  | _, .transport src dst d =>
+      match q.taxon with
+      | some t =>
+          if ContextModel.isA t.curie dst.curie && Ctx.siblings src dst then
+            (go { q with taxon := some src } d).discount ContextModel.transport
+              ContextModel.transport_nonneg ContextModel.transport_le_one
+          else Opinion.vacuous
+      | none => Opinion.vacuous
+  | _, .viaActivity ab bt => (go q ab).chain (go q bt)
+  | _, .viaAmount am mt => (go q am).chain (go q mt)
+  | _, .both d₁ d₂ => (go q d₁).fuse (go q d₂)
+  | _, .relChain ab bc .. => (go q ab).weakest (go q bc)
+  | _, .notRelSub ab bc .. => (go q ab).weakest (go q bc)
+  | _, .notRelObj ac bc .. => (go q ac).weakest (go q bc)
+  | _, .sequencesOver a l .. => (go q a).weakest (go q l)
+  | _, .pigeonhole i hs e .. => ((go q i).weakest (go q hs)).weakest (go q e)
+  | _, .perSet p s .. => (go q p).weakest (go q s)
+  | _, .fusionAdds ix iy o cx cy .. => ((((go q ix).weakest (go q iy)).weakest (go q o)).weakest (go q cx)).weakest (go q cy)
+  | _, .netYield m u .. => (go q m).weakest (go q u)
+  | _, .compareIntervals a b .. => (go q a).weakest (go q b)
+  | _, .weaken _ d => (go q d)
 
 /-- The literature statements a derivation rests on, in order of first use. -/
 def axioms : {c : Claim} → Derivation c → List Statement
@@ -137,6 +154,7 @@ def axioms : {c : Claim} → Derivation c → List Statement
   | _, .netYield m u .. => m.axioms ++ u.axioms
   | _, .compareIntervals a b .. => a.axioms ++ b.axioms
   | _, .weaken _ d => d.axioms
+  | _, .transport _ _ d => d.axioms
 
 /-- Every PMID cited anywhere in the derivation, without repeats. -/
 def pmids {c : Claim} (d : Derivation c) : List Nat :=
@@ -157,49 +175,57 @@ def _root_.BioLean.Opinion.verdict (o : Opinion) (θ : ℚ := 4 / 5) (τ : ℚ :
   else if θ ≤ o.disbelief then .refuted
   else .unsupported
 
-def verdict {c : Claim} (d : Derivation c) (θ : ℚ := 4 / 5) (τ : ℚ := 1 / 4) : Verdict :=
-  d.opinion.verdict θ τ
+def verdict {c : Claim} (d : Derivation c) (θ : ℚ := 4 / 5) (τ : ℚ := 1 / 4) (q : Ctx := {}) :
+    Verdict :=
+  (d.opinion q).verdict θ τ
 
 /-- The proposition "claim `c` is established at level `θ`": some derivation reaches
 belief `θ`. -/
 def _root_.BioLean.Established (c : Claim) (θ : ℚ) : Prop :=
   ∃ d : Derivation c, θ ≤ d.opinion.belief
 
+/-- "Claim `c` is established at level `θ` in context `q`". -/
+def _root_.BioLean.EstablishedIn (q : Ctx) (c : Claim) (θ : ℚ) : Prop :=
+  ∃ d : Derivation c, θ ≤ (d.opinion q).belief
+
 /-- The claim a derivation proves. -/
 def claim {c : Claim} (_ : Derivation c) : Claim := c
 
 /-- Pretty-print a derivation as an indented tree with the opinion at each node. -/
-partial def render {c : Claim} (d : Derivation c) (indent : String := "") : String :=
+partial def render {c : Claim} (d : Derivation c) (indent : String := "") (q : Ctx := {}) :
+    String :=
   let node (rule : String) (kids : List String) : String :=
-    s!"{indent}{d.opinion} {rule} ⊢ {d.claim}\n" ++ String.intercalate "\n" kids
+    s!"{indent}{d.opinion q} {rule} ⊢ {d.claim}\n" ++ String.intercalate "\n" kids
   match d with
   | .lit s =>
-      s!"{indent}{s.opinion} {s.id}: {s.claim}  [{s.distinctEvidence.length} refs]"
+      s!"{indent}{s.opinion q} {s.id}: {s.claim}  [{s.distinctEvidence.length} refs]"
   | .viaActivity ab bt =>
-      s!"{indent}{d.opinion} chain ⊢ {d.claim}\n" ++
-        render ab (indent ++ "  ") ++ "\n" ++ render bt (indent ++ "  ")
+      s!"{indent}{d.opinion q} chain ⊢ {d.claim}\n" ++
+        render ab (indent ++ "  ") q ++ "\n" ++ render bt (indent ++ "  ") q
   | .viaAmount am mt =>
-      s!"{indent}{d.opinion} chain ⊢ {d.claim}\n" ++
-        render am (indent ++ "  ") ++ "\n" ++ render mt (indent ++ "  ")
+      s!"{indent}{d.opinion q} chain ⊢ {d.claim}\n" ++
+        render am (indent ++ "  ") q ++ "\n" ++ render mt (indent ++ "  ") q
   | .both d₁ d₂ =>
-      s!"{indent}{d.opinion} fuse ⊢ {d.claim}\n" ++
-        render d₁ (indent ++ "  ") ++ "\n" ++ render d₂ (indent ++ "  ")
+      s!"{indent}{d.opinion q} fuse ⊢ {d.claim}\n" ++
+        render d₁ (indent ++ "  ") q ++ "\n" ++ render d₂ (indent ++ "  ") q
   | .relChain ab bc .. =>
-      s!"{indent}{d.opinion} RO chain ⊢ {d.claim}\n" ++
-        render ab (indent ++ "  ") ++ "\n" ++ render bc (indent ++ "  ")
+      s!"{indent}{d.opinion q} RO chain ⊢ {d.claim}\n" ++
+        render ab (indent ++ "  ") q ++ "\n" ++ render bc (indent ++ "  ") q
   | .notRelSub ab bc .. =>
-      s!"{indent}{d.opinion} is_a inherits ¬ ⊢ {d.claim}\n" ++
-        render ab (indent ++ "  ") ++ "\n" ++ render bc (indent ++ "  ")
+      s!"{indent}{d.opinion q} is_a inherits ¬ ⊢ {d.claim}\n" ++
+        render ab (indent ++ "  ") q ++ "\n" ++ render bc (indent ++ "  ") q
   | .notRelObj ac bc .. =>
-      s!"{indent}{d.opinion} ¬ covers subclass ⊢ {d.claim}\n" ++
-        render ac (indent ++ "  ") ++ "\n" ++ render bc (indent ++ "  ")
-  | .sequencesOver a l .. => node "k^n sequences" [render a (indent ++ "  "), render l (indent ++ "  ")]
-  | .pigeonhole i hs e .. => node "pigeonhole" [render i (indent ++ "  "), render hs (indent ++ "  "), render e (indent ++ "  ")]
-  | .perSet p s .. => node "equal division" [render p (indent ++ "  "), render s (indent ++ "  ")]
-  | .fusionAdds ix iy o cx cy .. => node "fusion adds" [render ix (indent ++ "  "), render iy (indent ++ "  "), render o (indent ++ "  "), render cx (indent ++ "  "), render cy (indent ++ "  ")]
-  | .netYield m u .. => node "made − used" [render m (indent ++ "  "), render u (indent ++ "  ")]
-  | .compareIntervals a b .. => node "disjoint intervals" [render a (indent ++ "  "), render b (indent ++ "  ")]
-  | .weaken q d' => node s!"weaken to {repr q}" [render d' (indent ++ "  ")]
+      s!"{indent}{d.opinion q} ¬ covers subclass ⊢ {d.claim}\n" ++
+        render ac (indent ++ "  ") q ++ "\n" ++ render bc (indent ++ "  ") q
+  | .sequencesOver a l .. => node "k^n sequences" [render a (indent ++ "  ") q, render l (indent ++ "  ") q]
+  | .pigeonhole i hs e .. => node "pigeonhole" [render i (indent ++ "  ") q, render hs (indent ++ "  ") q, render e (indent ++ "  ") q]
+  | .perSet p s .. => node "equal division" [render p (indent ++ "  ") q, render s (indent ++ "  ") q]
+  | .fusionAdds ix iy o cx cy .. => node "fusion adds" [render ix (indent ++ "  ") q, render iy (indent ++ "  ") q, render o (indent ++ "  ") q, render cx (indent ++ "  ") q, render cy (indent ++ "  ") q]
+  | .netYield m u .. => node "made − used" [render m (indent ++ "  ") q, render u (indent ++ "  ") q]
+  | .compareIntervals a b .. => node "disjoint intervals" [render a (indent ++ "  ") q, render b (indent ++ "  ") q]
+  | .weaken qt d' => node s!"weaken to {repr qt}" [render d' (indent ++ "  ") q]
+  | .transport src dst d' => node s!"transport {src} ⇒ {dst}"
+      [render d' (indent ++ "  ") { q with taxon := some src }]
 
 /-- Statements used more than once in a derivation. `fuse` assumes independence, so a
 shared axiom means the strength is over-stated. -/
@@ -208,10 +234,11 @@ def sharedAxioms {c : Claim} (d : Derivation c) : List String :=
   (ids.filter (fun i => (ids.count i) > 1)).eraseDups
 
 /-- A full report: verdict, tree, and the literature it rests on. -/
-def report {c : Claim} (d : Derivation c) : String :=
+def report {c : Claim} (d : Derivation c) (q : Ctx := {}) : String :=
   let warn := if d.sharedAxioms.isEmpty then ""
     else s!"\nWARNING shared axioms (not independent): {d.sharedAxioms}"
-  s!"Claim: {c}\nVerdict: {repr d.verdict}  {d.opinion}{warn}\n\n{d.render}\n\n" ++
+  let ctx := if toString q == "any context" then "" else s!"  [in {q}]"
+  s!"Claim: {c}{ctx}\nVerdict: {repr (d.verdict (q := q))}  {d.opinion q}{warn}\n\n{d.render (q := q)}\n\n" ++
     s!"Rests on {d.axioms.length} statements, {d.pmids.length} PMIDs: " ++
     s!"{d.pmids.map toString |> String.intercalate ", "}"
 
@@ -219,8 +246,9 @@ def report {c : Claim} (d : Derivation c) : String :=
 about `a r b`: the negation's belief becomes disbelief, then the two fuse. The verdict is
 *contested* when both sides are strong, which is where an ontology inconsistency shows up. -/
 def clash {k₁ k₂ : Kind} {a : Entity k₁} {b : Entity k₂} {r : Rel} {h : r.accepts k₁ k₂ = true}
-    (yes : Derivation (.rel r a b h)) (no : Derivation (.notRel r a b h)) : Opinion :=
-  yes.opinion.fuse no.opinion.negate
+    (yes : Derivation (.rel r a b h)) (no : Derivation (.notRel r a b h)) (q : Ctx := {}) :
+    Opinion :=
+  (yes.opinion q).fuse (no.opinion q).negate
 
 /-! ### Theorems about derivations -/
 
@@ -254,5 +282,17 @@ theorem opinion_viaAmount_disbelief {k k' : Kind} {a : Entity k} {m : Entity k'}
     (am : Derivation (.effect a s₁ (.amount m))) (mt : Derivation (.effect m s₂ t)) :
     (viaAmount am mt).opinion.disbelief = 0 := rfl
 
+/-- Transport is never free and never strong: whatever `d` is, and in whatever context it is
+asked, a transported derivation believes at most `ContextModel.transport` (3/10 by default). -/
+theorem opinion_transport_belief_le {c : Claim} (src dst : Entity .taxon) (d : Derivation c)
+    (q : Ctx) : ((transport src dst d).opinion q).belief ≤ ContextModel.transport := by
+  have h0 := ContextModel.transport_nonneg
+  simp only [opinion, opinion.go]
+  split
+  · split
+    · exact Opinion.discount_belief_le _ _ _ _
+    · exact h0
+  · exact h0
+
 end Derivation
 end BioLean
diff --git a/BioLean/Evidence.lean b/BioLean/Evidence.lean
index 831e470..a75621d 100644
--- a/BioLean/Evidence.lean
+++ b/BioLean/Evidence.lean
@@ -1,5 +1,6 @@
 import BioLean.Belief
 import BioLean.Claim
+import BioLean.Context
 
 /-!
 # Evidence and statements
@@ -36,6 +37,19 @@ structure Evidence where
   kind : EvidenceKind
   polarity : Opinion.Polarity := .supports
   note : String := ""
+  -- Where the result was obtained (M2, INDRA-style: context per evidence item, not per claim).
+  -- Unset means "no restriction stated", which fits every query.
+  /-- Organisms. Usually one; a reconstituted chimera lists each source. -/
+  taxa : List (Entity .taxon) := []
+  anatomy : Option (Entity .anatomy) := none
+  cellType : Option (Entity .cellType) := none
+  /-- The membrane or compartment, e.g. thylakoid membrane. -/
+  component : Option (Entity .component) := none
+  /-- Free text: diet, disease model, age group, tonicity. Matched exactly. -/
+  condition : Option String := none
+  inVitro : Bool := false
+  dose : Option String := none
+  duration : Option String := none
   deriving Repr
 
 /-- A claim with its evidence: the axiom form of BioLean. -/
@@ -74,6 +88,16 @@ namespace Evidence
 def opinion [m : EvidenceModel] (e : Evidence) : Opinion :=
   Opinion.ofReliability (m.reliability e.kind) (m.nonneg e.kind) (m.lt_one e.kind) e.polarity
 
+/-- Does this evidence bear on a claim asked about in context `q`? -/
+def fits [ContextModel] (q : Ctx) (e : Evidence) : Bool :=
+  !(q.inVivoOnly && e.inVitro) && Ctx.taxaFit q.taxon e.taxa &&
+  Ctx.slotFits q.anatomy e.anatomy && Ctx.slotFits q.cellType e.cellType &&
+  Ctx.slotFits q.component e.component &&
+  (match e.condition, q.condition with
+   | none, _ => true
+   | some _, none => false
+   | some a, some b => a == b)
+
 end Evidence
 
 namespace Statement
@@ -85,9 +109,12 @@ def distinctEvidence (s : Statement) : List Evidence :=
 
 /-- Fuse the evidence for a statement into one opinion. Fusion assumes the items are
 independent, so repeated PMIDs are dropped first. Shared findings cited by several
-papers are still over-counted; see `docs/design.md`. -/
-def opinion [EvidenceModel] (s : Statement) : Opinion :=
-  s.distinctEvidence.foldl (fun acc e => acc.fuse e.opinion) Opinion.vacuous
+papers are still over-counted; see `docs/design.md`. Only evidence that fits the query context
+`q` takes part (filtered before PMIDs are deduplicated, so one paper may report two contexts);
+the default query is "no context", which only context-free evidence fits. -/
+def opinion [EvidenceModel] [ContextModel] (s : Statement) (q : Ctx := {}) : Opinion :=
+  { s with evidence := s.evidence.filter (·.fits q) }.distinctEvidence.foldl
+    (fun acc (e : Evidence) => acc.fuse e.opinion) Opinion.vacuous
 
 def pmids (s : Statement) : List Nat := s.evidence.map (·.pmid)
 
diff --git a/lakefile.toml b/lakefile.toml
index 8308840..fa248ba 100644
--- a/lakefile.toml
+++ b/lakefile.toml
@@ -16,7 +16,8 @@ name = "BioLean"
 
 [[lean_lib]]
 name = "BioLeanLib"
-roots = ["BioLean.Lib.GLP1", "BioLean.Examples.Ozempic", "BioLean.Lib.Textbook", "BioLean.Examples.Textbook", "BioLean.Examples.Quantity", "BioLean.Tests.RO"]
+roots = ["BioLean.Lib.GLP1", "BioLean.Examples.Ozempic", "BioLean.Lib.Textbook", "BioLean.Examples.Textbook", "BioLean.Examples.Quantity", "BioLean.Tests.RO",
+  "BioLean.Lib.ContextSample", "BioLean.Examples.Context"]
 
 [[lean_lib]]
 name = "TextbookR2"
```

## (c) The encodings

### The 40 (generated once from `data/m2/context_claims.json`, key `sample40`)

All 40 compile, including RO domain/range checks. The CURIEs, kinds and contexts are Sonnet's,
and missing labels were filled by hand. Each is a bare claim with a single textbook evidence item
(pmid 0) that carries the context.

```lean
import BioLean.Evidence

/-! The 40 context-required textbook claims (`data/m2/context_claims.json`, key `sample40`),
in design "evidence": the claim is bare, the context sits on the textbook evidence item.
Generated once from the JSON; CURIEs and kinds as Sonnet gave them, labels filled where missing. -/

namespace BioLean.M2.Evidence

def e_CHEBI_15377 : Entity .chemical := ⟨"CHEBI:15377", "water"⟩
def e_CHEBI_15379 : Entity .chemical := ⟨"CHEBI:15379", "oxygen"⟩
def e_CHEBI_16646 : Entity .chemical := ⟨"CHEBI:16646", "carbohydrate"⟩
def e_CHEBI_17234 : Entity .chemical := ⟨"CHEBI:17234", "glucose"⟩
def e_CHEBI_17716 : Entity .chemical := ⟨"CHEBI:17716", "lactose"⟩
def e_CHEBI_23888 : Entity .chemical := ⟨"CHEBI:23888", "drug"⟩
def e_CHEBI_27584 : Entity .chemical := ⟨"CHEBI:27584", "aldosterone"⟩
def e_CHEBI_29101 : Entity .chemical := ⟨"CHEBI:29101", "sodium ion"⟩
def e_CHEBI_29103 : Entity .chemical := ⟨"CHEBI:29103", "potassium ion"⟩
def e_CHEBI_33568 : Entity .chemical := ⟨"CHEBI:33568", "epinephrine"⟩
def e_CHEBI_35469 : Entity .chemical := ⟨"CHEBI:35469", "antidepressant"⟩
def e_CL_0000000 : Entity .cellType := ⟨"CL:0000000", "cell"⟩
def e_CL_0000232 : Entity .cellType := ⟨"CL:0000232", "erythrocyte"⟩
def e_CL_0000300 : Entity .cellType := ⟨"CL:0000300", "gamete"⟩
def e_CL_0000520 : Entity .cellType := ⟨"CL:0000520", "prokaryotic cell"⟩
def e_CL_0000586 : Entity .cellType := ⟨"CL:0000586", "germ cell"⟩
def e_CL_0000746 : Entity .cellType := ⟨"CL:0000746", "cardiac muscle cell"⟩
def e_CL_0001064 : Entity .cellType := ⟨"CL:0001064", "malignant cell"⟩
def e_GO_0000086 : Entity .process := ⟨"GO:0000086", "G2/M transition"⟩
def e_GO_0000271 : Entity .process := ⟨"GO:0000271", "polysaccharide biosynthetic process"⟩
def e_GO_0000723 : Entity .process := ⟨"GO:0000723", "telomere maintenance"⟩
def e_GO_0000910 : Entity .process := ⟨"GO:0000910", "cytokinesis"⟩
def e_GO_0005634 : Entity .component := ⟨"GO:0005634", "nucleus"⟩
def e_GO_0005694 : Entity .component := ⟨"GO:0005694", "chromosome"⟩
def e_GO_0005697 : Entity .component := ⟨"GO:0005697", "telomerase holoenzyme complex"⟩
def e_GO_0005737 : Entity .component := ⟨"GO:0005737", "cytoplasm"⟩
def e_GO_0005764 : Entity .component := ⟨"GO:0005764", "lysosome"⟩
def e_GO_0005794 : Entity .component := ⟨"GO:0005794", "Golgi apparatus"⟩
def e_GO_0005856 : Entity .component := ⟨"GO:0005856", "cytoskeleton"⟩
def e_GO_0005886 : Entity .component := ⟨"GO:0005886", "plasma membrane"⟩
def e_GO_0005902 : Entity .component := ⟨"GO:0005902", "microvillus"⟩
def e_GO_0005990 : Entity .process := ⟨"GO:0005990", "lactose catabolic process"⟩
def e_GO_0006096 : Entity .process := ⟨"GO:0006096", "glycolytic process"⟩
def e_GO_0006289 : Entity .process := ⟨"GO:0006289", "nucleotide-excision repair"⟩
def e_GO_0006351 : Entity .process := ⟨"GO:0006351", "DNA-templated transcription"⟩
def e_GO_0007095 : Entity .process := ⟨"GO:0007095", "mitotic G2 DNA damage checkpoint signaling"⟩
def e_GO_0007134 : Entity .process := ⟨"GO:0007134", "telophase I"⟩
def e_GO_0007136 : Entity .process := ⟨"GO:0007136", "prophase II"⟩
def e_GO_0007585 : Entity .process := ⟨"GO:0007585", "respiratory gaseous exchange by respiratory system"⟩
def e_GO_0007586 : Entity .process := ⟨"GO:0007586", "digestion"⟩
def e_GO_0009295 : Entity .component := ⟨"GO:0009295", "nucleoid"⟩
def e_GO_0009505 : Entity .component := ⟨"GO:0009505", "plant cell wall"⟩
def e_GO_0015979 : Entity .process := ⟨"GO:0015979", "photosynthesis"⟩
def e_GO_0016042 : Entity .process := ⟨"GO:0016042", "lipid catabolic process"⟩
def e_GO_0019661 : Entity .process := ⟨"GO:0019661", "glucose catabolic process to lactate via pyruvate"⟩
def e_GO_0019953 : Entity .process := ⟨"GO:0019953", "sexual reproduction"⟩
def e_GO_0022008 : Entity .process := ⟨"GO:0022008", "neurogenesis"⟩
def e_GO_0030261 : Entity .process := ⟨"GO:0030261", "chromosome condensation"⟩
def e_GO_0031468 : Entity .process := ⟨"GO:0031468", "nuclear envelope reformation"⟩
def e_GO_0032154 : Entity .component := ⟨"GO:0032154", "cleavage furrow"⟩
def e_GO_0043093 : Entity .process := ⟨"GO:0043093", "binary fission"⟩
def e_GO_0044557 : Entity .process := ⟨"GO:0044557", "relaxation of smooth muscle"⟩
def e_GO_0050892 : Entity .process := ⟨"GO:0050892", "intestinal absorption"⟩
def e_GO_0051301 : Entity .process := ⟨"GO:0051301", "cell division"⟩
def e_GO_0051321 : Entity .process := ⟨"GO:0051321", "meiosis"⟩
def e_GO_0060048 : Entity .process := ⟨"GO:0060048", "cardiac muscle contraction"⟩
def e_GO_0061337 : Entity .process := ⟨"GO:0061337", "cardiac conduction"⟩
def e_GO_0090332 : Entity .process := ⟨"GO:0090332", "stomatal closure"⟩
def e_GO_0098657 : Entity .process := ⟨"GO:0098657", "import into cell"⟩
def e_HP_0008069 : Entity .phenotype := ⟨"HP:0008069", "skin cancers"⟩
def e_HP_0012531 : Entity .phenotype := ⟨"HP:0012531", "pain"⟩
def e_NCBITaxon_2 : Entity .taxon := ⟨"NCBITaxon:2", "Bacteria"⟩
def e_NCBITaxon_2759 : Entity .taxon := ⟨"NCBITaxon:2759", "Eukaryota"⟩
def e_NCBITaxon_33090 : Entity .taxon := ⟨"NCBITaxon:33090", "Viridiplantae"⟩
def e_NCBITaxon_33208 : Entity .taxon := ⟨"NCBITaxon:33208", "Metazoa"⟩
def e_NCBITaxon_40674 : Entity .taxon := ⟨"NCBITaxon:40674", "Mammalia"⟩
def e_NCBITaxon_562 : Entity .taxon := ⟨"NCBITaxon:562", "Escherichia coli"⟩
def e_NCBITaxon_7742 : Entity .taxon := ⟨"NCBITaxon:7742", "Vertebrata"⟩
def e_NCBITaxon_9606 : Entity .taxon := ⟨"NCBITaxon:9606", "Homo sapiens"⟩
def e_NCIT_C14263 : Entity .taxon := ⟨"NCIT:C14263", "prokaryote"⟩
def e_PATO_0000956 : Entity .phenotype := ⟨"PATO:0000956", "sterile"⟩
def e_PATO_0001381 : Entity .phenotype := ⟨"PATO:0001381", "triploid"⟩
def e_PO_0025034 : Entity .anatomy := ⟨"PO:0025034", "leaf"⟩
def e_PR_000009054 : Entity .protein := ⟨"PR:000009054", "insulin"⟩
def e_PR_000022726 : Entity .protein := ⟨"PR:000022726", "FtsZ"⟩
def e_PR_P01160 : Entity .protein := ⟨"PR:P01160", "atrial natriuretic peptide"⟩
def e_PR_P01275 : Entity .protein := ⟨"PR:P01275", "glucagon"⟩
def e_SO_0001026 : Entity .gene := ⟨"SO:0001026", "genome"⟩
def e_UBERON_0000010 : Entity .anatomy := ⟨"UBERON:0000010", "peripheral nervous system"⟩
def e_UBERON_0000013 : Entity .anatomy := ⟨"UBERON:0000013", "sympathetic nervous system"⟩
def e_UBERON_0000178 : Entity .anatomy := ⟨"UBERON:0000178", "blood"⟩
def e_UBERON_0001004 : Entity .anatomy := ⟨"UBERON:0001004", "respiratory system"⟩
def e_UBERON_0001013 : Entity .anatomy := ⟨"UBERON:0001013", "adipose tissue"⟩
def e_UBERON_0001021 : Entity .anatomy := ⟨"UBERON:0001021", "nerve"⟩
def e_UBERON_0002081 : Entity .anatomy := ⟨"UBERON:0002081", "cardiac atrium"⟩
def e_UBERON_0002185 : Entity .anatomy := ⟨"UBERON:0002185", "bronchus"⟩
def e_UBERON_0002421 : Entity .anatomy := ⟨"UBERON:0002421", "hippocampus"⟩

/-- Telomerase is present in human cells -/
def t_molbio_m45475_69 : Statement where
  id := "molbio-m45475-69"
  text := "Telomerase is present in human cells"
  claim := .rel .locatedIn e_GO_0005697 e_CL_0000000
  evidence := [{ pmid := 0, year := 2013, kind := .textbook, taxa := [e_NCBITaxon_9606], note :=
    "Later research using HeLa cells (obtained from Henrietta Lacks) confirmed that telomerase is present in human cells." }]
/-- Epinephrine and norepinephrine accelerate breakdown of stored fat in adipose tissue -/
def t_the_body_s_systems_m45537_183 : Statement where
  id := "the-body-s-systems-m45537-183"
  text := "Epinephrine and norepinephrine accelerate breakdown of stored fat in adipose tissue"
  claim := .effect e_CHEBI_33568 .pos (.process e_GO_0016042)
  evidence := [{ pmid := 0, year := 2013, kind := .textbook, anatomy := some e_UBERON_0001013, note :=
    "They also accelerate the breakdown of glucose in skeletal muscles and stored fats in adipose tissue, and redirect blood flow toward skeletal muscles and away from skin and viscera." }]
/-- The electrochemical signal causes the two atria to contract in unison -/
def t_the_body_s_systems_m45536_190 : Statement where
  id := "the-body-s-systems-m45536-190"
  text := "The electrochemical signal causes the two atria to contract in unison"
  claim := .effect e_GO_0061337 .pos (.process e_GO_0060048)
  evidence := [{ pmid := 0, year := 2013, kind := .textbook, anatomy := some e_UBERON_0002081, note :=
    "The electrochemical signal causes the two atria to contract in unison; then the signal causes the ventricles to contract." }]
/-- In a hypotonic solution water enters the cell -/
def t_cell_structure_and_function_m45434_70 : Statement where
  id := "cell-structure-and-function-m45434-70"
  text := "In a hypotonic solution water enters the cell"
  claim := .rel ⟨.ro, 57, false⟩ e_GO_0098657 e_CHEBI_15377
  evidence := [{ pmid := 0, year := 2013, kind := .textbook, condition := some "hypotonic solution", note :=
    "In a hypotonic solution, such as tap water, the extracellular fluid has a lower concentration of solutes than the fluid inside the cell, and water enters the cell." }]
/-- stomatal closure raises oxygen levels inside the leaf -/
def t_photosynthesis_m45448_120 : Statement where
  id := "photosynthesis-m45448-120"
  text := "stomatal closure raises oxygen levels inside the leaf"
  claim := .effect e_GO_0090332 .pos (.amount e_CHEBI_15379)
  evidence := [{ pmid := 0, year := 2013, kind := .textbook, anatomy := some e_PO_0025034, note :=
    "Levels of carbon dioxide (a reactant) will fall, and levels of oxygen (a product) will rise." }]
/-- Glucagon causes release of glucose from the liver into the blood -/
def t_the_body_s_systems_m45537_201 : Statement where
  id := "the-body-s-systems-m45537-201"
  text := "Glucagon causes release of glucose from the liver into the blood"
  claim := .effect e_PR_P01275 .pos (.amount e_CHEBI_17234)
  evidence := [{ pmid := 0, year := 2013, kind := .textbook, anatomy := some e_UBERON_0000178, note :=
    "Glucagon causes the release of glucose to the blood from the liver, and insulin facilitates the uptake of glucose by the body’s cells." }]
/-- FtsZ is a tubulin-like protein component of the prokaryotic cytoskeleton. -/
def t_reproduction_at_the_cellular_level_m45463_67 : Statement where
  id := "reproduction-at-the-cellular-level-m45463-67"
  text := "FtsZ is a tubulin-like protein component of the prokaryotic cytoskeleton."
  claim := .rel .partOf e_PR_000022726 e_GO_0005856
  evidence := [{ pmid := 0, year := 2013, kind := .textbook, taxa := [e_NCBITaxon_2], note :=
    "FtsZ: a tubulin-like protein component of the prokaryotic cytoskeleton that is important in prokaryotic cytokinesis (name origin: Filamenting temperature-sensitive mutant Z)" }]
/-- Increasing blood glucose causes the pancreas to release insulin -/
def t_the_body_s_systems_m45537_334 : Statement where
  id := "the-body-s-systems-m45537-334"
  text := "Increasing blood glucose causes the pancreas to release insulin"
  claim := .effect e_CHEBI_17234 .pos (.amount e_PR_000009054)
  evidence := [{ pmid := 0, year := 2013, kind := .textbook, anatomy := some e_UBERON_0000178, note :=
    "When blood-glucose levels are increasing, the pancreas releases insulin, which stimulates uptake of glucose by cells." }]
/-- An increase in blood potassium stimulates aldosterone release -/
def t_the_body_s_systems_m45537_156 : Statement where
  id := "the-body-s-systems-m45537-156"
  text := "An increase in blood potassium stimulates aldosterone release"
  claim := .effect e_CHEBI_29103 .pos (.amount e_CHEBI_27584)
  evidence := [{ pmid := 0, year := 2013, kind := .textbook, anatomy := some e_UBERON_0000178, note :=
    "Aldosterone release from the adrenal cortex is stimulated by a decrease in blood concentrations of sodium ions, blood volume, or blood pressure, or by an increase in blood potassium levels." }]
/-- The plant cell wall is external to the plasma membrane -/
def t_cell_structure_and_function_m45432_219 : Statement where
  id := "cell-structure-and-function-m45432-219"
  text := "The plant cell wall is external to the plasma membrane"
  claim := .rel ⟨.ro, 2220, false⟩ e_GO_0009505 e_GO_0005886
  evidence := [{ pmid := 0, year := 2013, kind := .textbook, taxa := [e_NCBITaxon_33090], note :=
    "In b, the diagram of a plant cell, you see a structure external to the plasma membrane called the cell wall." }]
/-- The atrial hormone reduces blood Na+ concentration -/
def t_the_body_s_systems_m45537_229 : Statement where
  id := "the-body-s-systems-m45537-229"
  text := "The atrial hormone reduces blood Na+ concentration"
  claim := .effect e_PR_P01160 .neg (.amount e_CHEBI_29101)
  evidence := [{ pmid := 0, year := 2013, kind := .textbook, anatomy := some e_UBERON_0000178, note :=
    "It causes a reduction in blood volume and blood pressure, and reduces the concentration of Na+ in the blood." }]
/-- Loss of microvilli prevents nutrient absorption in celiac patients -/
def t_cell_structure_and_function_m45432_25 : Statement where
  id := "cell-structure-and-function-m45432-25"
  text := "Loss of microvilli prevents nutrient absorption in celiac patients"
  claim := .effect e_GO_0005902 .pos (.process e_GO_0050892)
  evidence := [{ pmid := 0, year := 2013, kind := .textbook, condition := some "celiac disease", note :=
    "The immune response damages microvilli, and thus, afflicted individuals cannot absorb nutrients." }]
/-- Binary fission is the process of prokaryotic cell division. -/
def t_reproduction_at_the_cellular_level_m45463_66 : Statement where
  id := "reproduction-at-the-cellular-level-m45463-66"
  text := "Binary fission is the process of prokaryotic cell division."
  claim := .rel .isA e_GO_0043093 e_GO_0051301
  evidence := [{ pmid := 0, year := 2013, kind := .textbook, taxa := [e_NCBITaxon_2], note :=
    "binary fission: the process of prokaryotic cell division" }]
/-- People with defective nucleotide excision repair genes develop skin cancers early in life -/
def t_molbio_m45475_117 : Statement where
  id := "molbio-m45475-117"
  text := "People with defective nucleotide excision repair genes develop skin cancers early in life"
  claim := .effect e_GO_0006289 .neg (.phenotype e_HP_0008069)
  evidence := [{ pmid := 0, year := 2013, kind := .textbook, taxa := [e_NCBITaxon_9606], condition := some "defective NER genes; early onset", note :=
    "Individuals with flaws in their nucleotide excision repair genes show extreme sensitivity to sunlight and develop skin cancers early in life." }]
/-- Insulin decreases blood-glucose levels -/
def t_the_body_s_systems_m45537_53 : Statement where
  id := "the-body-s-systems-m45537-53"
  text := "Insulin decreases blood-glucose levels"
  claim := .effect e_PR_000009054 .neg (.amount e_CHEBI_17234)
  evidence := [{ pmid := 0, year := 2013, kind := .textbook, anatomy := some e_UBERON_0000178, note :=
    "They are then given a sugary drink, which stimulates the pancreas to produce insulin to decrease blood-glucose levels." }]
/-- Telomerase is active in some cancer cells -/
def t_molbio_m45475_67 : Statement where
  id := "molbio-m45475-67"
  text := "Telomerase is active in some cancer cells"
  claim := .rel .capableOf e_GO_0005697 e_GO_0000723
  evidence := [{ pmid := 0, year := 2013, kind := .textbook, cellType := some e_CL_0001064, condition := some "some cancer cells", note :=
    "Telomerase is typically found to be active in germ cells, adult stem cells, and some cancer cells." }]
/-- Lactic acid fermentation occurs routinely in mammalian red blood cells -/
def t_how_cells_obtain_energy_m45440_11 : Statement where
  id := "how-cells-obtain-energy-m45440-11"
  text := "Lactic acid fermentation occurs routinely in mammalian red blood cells"
  claim := .rel .occursIn e_GO_0019661 e_CL_0000232
  evidence := [{ pmid := 0, year := 2013, kind := .textbook, taxa := [e_NCBITaxon_40674], cellType := some e_CL_0000232, note :=
    "This occurs routinely in mammalian red blood cells and in skeletal muscle that has insufficient oxygen supply to allow aerobic respiration to continue (that is, in muscles used to the point of fatigue)." }]
/-- In some organisms nuclear envelopes form around the chromatids in telophase I -/
def t_the_cellular_basis_of_inheritance_m45466_103 : Statement where
  id := "the-cellular-basis-of-inheritance-m45466-103"
  text := "In some organisms nuclear envelopes form around the chromatids in telophase I"
  claim := .rel ⟨.ro, 2092, false⟩ e_GO_0031468 e_GO_0007134
  evidence := [{ pmid := 0, year := 2013, kind := .textbook, note :=
    "In some organisms, the chromosomes decondense and nuclear envelopes form around the chromatids in telophase I." }]
/-- Animal respiratory systems facilitate gas exchange -/
def t_the_body_s_systems_m45536_175 : Statement where
  id := "the-body-s-systems-m45536-175"
  text := "Animal respiratory systems facilitate gas exchange"
  claim := .rel .capableOf e_UBERON_0001004 e_GO_0007585
  evidence := [{ pmid := 0, year := 2013, kind := .textbook, taxa := [e_NCBITaxon_33208], note :=
    "Animal respiratory systems are designed to facilitate gas exchange." }]
/-- An electrical signal triggers atrial cardiac muscle cells to contract -/
def t_the_body_s_systems_m45536_212 : Statement where
  id := "the-body-s-systems-m45536-212"
  text := "An electrical signal triggers atrial cardiac muscle cells to contract"
  claim := .effect e_GO_0061337 .pos (.process e_GO_0060048)
  evidence := [{ pmid := 0, year := 2013, kind := .textbook, anatomy := some e_UBERON_0002081, cellType := some e_CL_0000746, note :=
    "The heart receives an electrical signal triggering the cardiac muscle cells in the atria to contract." }]
/-- In a diploid-dominant organism such as an animal, meiotic cells participate only in sexual reproduction -/
def t_the_cellular_basis_of_inheritance_m45466_165 : Statement where
  id := "the-cellular-basis-of-inheritance-m45466-165"
  text := "In a diploid-dominant organism such as an animal, meiotic cells participate only in sexual reproduction"
  claim := .rel .partOf e_GO_0051321 e_GO_0019953
  evidence := [{ pmid := 0, year := 2013, kind := .textbook, taxa := [e_NCBITaxon_33208], note :=
    "Cells produced by meiosis in a diploid-dominant organism such as an animal will only participate in sexual reproduction." }]
/-- Chromosomes are located in the nucleus of eukaryotic cells. -/
def t_reproduction_at_the_cellular_level_m45455_16 : Statement where
  id := "reproduction-at-the-cellular-level-m45455-16"
  text := "Chromosomes are located in the nucleus of eukaryotic cells."
  claim := .rel .locatedIn e_GO_0005694 e_GO_0005634
  evidence := [{ pmid := 0, year := 2013, kind := .textbook, taxa := [e_NCBITaxon_2759], note :=
    "Each species of eukaryote has a characteristic number of chromosomes in the nuclei of its cells." }]
/-- Medications relieve pain in rheumatoid arthritis -/
def t_the_body_s_systems_m45538_197 : Statement where
  id := "the-body-s-systems-m45538-197"
  text := "Medications relieve pain in rheumatoid arthritis"
  claim := .effect e_CHEBI_23888 .neg (.phenotype e_HP_0012531)
  evidence := [{ pmid := 0, year := 2013, kind := .textbook, condition := some "rheumatoid arthritis", note :=
    "If joint damage is more extensive, medications can be used to relieve pain and decrease inflammation." }]
/-- Photosynthesizing organisms (plants) produce sugars -/
def t_how_cells_obtain_energy_m45437_11 : Statement where
  id := "how-cells-obtain-energy-m45437-11"
  text := "Photosynthesizing organisms (plants) produce sugars"
  claim := .rel .hasOutput e_GO_0015979 e_CHEBI_16646
  evidence := [{ pmid := 0, year := 2013, kind := .textbook, taxa := [e_NCBITaxon_33090], note :=
    "For the most part, photosynthesizing organisms like plants produce these sugars." }]
/-- Gametes are produced from diploid germ cells -/
def t_the_cellular_basis_of_inheritance_m45465_68 : Statement where
  id := "the-cellular-basis-of-inheritance-m45465-68"
  text := "Gametes are produced from diploid germ cells"
  claim := .rel ⟨.ro, 2202, false⟩ e_CL_0000300 e_CL_0000586
  evidence := [{ pmid := 0, year := 2013, kind := .textbook, taxa := [e_NCBITaxon_33208], note :=
    "The gametes are produced from diploid germ cells, a special cell line that only produces gametes." }]
/-- Glucagon stimulates release of stored glucose from the liver into the bloodstream -/
def t_the_body_s_systems_m45537_337 : Statement where
  id := "the-body-s-systems-m45537-337"
  text := "Glucagon stimulates release of stored glucose from the liver into the bloodstream"
  claim := .effect e_PR_P01275 .pos (.amount e_CHEBI_17234)
  evidence := [{ pmid := 0, year := 2013, kind := .textbook, anatomy := some e_UBERON_0000178, note :=
    "When blood-glucose levels are decreasing, the pancreas releases glucagon, which stimulates the release of stored glucose by the liver to the bloodstream." }]
/-- The vertebrate PNS is made up of peripheral sensory and motor nerves -/
def t_the_body_s_systems_m45539_28 : Statement where
  id := "the-body-s-systems-m45539-28"
  text := "The vertebrate PNS is made up of peripheral sensory and motor nerves"
  claim := .rel .hasPart e_UBERON_0000010 e_UBERON_0001021
  evidence := [{ pmid := 0, year := 2013, kind := .textbook, taxa := [e_NCBITaxon_7742], note :=
    "While there is great diversity among different vertebrate nervous systems, they all share a basic structure: a CNS that contains a brain and spinal cord and a PNS made up of peripheral sensory and motor nerves." }]
/-- Sympathetic input causes bronchial muscle relaxation -/
def t_the_body_s_systems_m45536_61 : Statement where
  id := "the-body-s-systems-m45536-61"
  text := "Sympathetic input causes bronchial muscle relaxation"
  claim := .effect e_UBERON_0000013 .pos (.process e_GO_0044557)
  evidence := [{ pmid := 0, year := 2013, kind := .textbook, anatomy := some e_UBERON_0002185, note :=
    "Bronchi are innervated by nerves of both the parasympathetic and sympathetic nervous systems that control muscle contraction (parasympathetic) or relaxation (sympathetic) in the bronchi and bronchioles, depending on the " }]
/-- The nucleoid is the region of a prokaryotic cell containing the genome. -/
def t_reproduction_at_the_cellular_level_m45455_9 : Statement where
  id := "reproduction-at-the-cellular-level-m45455-9"
  text := "The nucleoid is the region of a prokaryotic cell containing the genome."
  claim := .rel .locatedIn e_SO_0001026 e_GO_0009295
  evidence := [{ pmid := 0, year := 2013, kind := .textbook, taxa := [e_NCIT_C14263], note :=
    "The region in the cell containing this genetic material is called a nucleoid." }]
/-- In animals and some fungi cytokinesis separates cell contents by a cleavage furrow -/
def t_the_cellular_basis_of_inheritance_m45466_106 : Statement where
  id := "the-cellular-basis-of-inheritance-m45466-106"
  text := "In animals and some fungi cytokinesis separates cell contents by a cleavage furrow"
  claim := .rel .hasPart e_GO_0000910 e_GO_0032154
  evidence := [{ pmid := 0, year := 2013, kind := .textbook, taxa := [e_NCBITaxon_33208], note :=
    "In nearly all species, cytokinesis separates the cell contents by either a cleavage furrow (in animals and some fungi), or a cell plate that will ultimately lead to formation of cell walls that separate the two daughter " }]
/-- In prophase II chromosomes condense again if they decondensed in telophase I -/
def t_the_cellular_basis_of_inheritance_m45466_119 : Statement where
  id := "the-cellular-basis-of-inheritance-m45466-119"
  text := "In prophase II chromosomes condense again if they decondensed in telophase I"
  claim := .rel ⟨.ro, 2092, false⟩ e_GO_0030261 e_GO_0007136
  evidence := [{ pmid := 0, year := 2013, kind := .textbook, condition := some "chromosomes decondensed in telophase I", note :=
    "In prophase II, if the chromosomes decondensed in telophase I, they condense again." }]
/-- Mature mammalian red blood cells are capable only of glycolysis -/
def t_how_cells_obtain_energy_m45438_42 : Statement where
  id := "how-cells-obtain-energy-m45438-42"
  text := "Mature mammalian red blood cells are capable only of glycolysis"
  claim := .rel .capableOf e_CL_0000232 e_GO_0006096
  evidence := [{ pmid := 0, year := 2013, kind := .textbook, taxa := [e_NCBITaxon_40674], note :=
    "For example, mature mammalian red blood cells are only capable of glycolysis, which is their sole source of ATP." }]
/-- Triploid animals are sterile -/
def t_the_cellular_basis_of_inheritance_m45467_83 : Statement where
  id := "the-cellular-basis-of-inheritance-m45467-83"
  text := "Triploid animals are sterile"
  claim := .effect e_PATO_0001381 .pos (.phenotype e_PATO_0000956)
  evidence := [{ pmid := 0, year := 2013, kind := .textbook, taxa := [e_NCBITaxon_33208], note :=
    "Triploid animals are sterile because meiosis cannot proceed normally with an odd number of chromosome sets." }]
/-- In single-celled eukaryotes, lysosomes digest ingested food -/
def t_cell_structure_and_function_m45432_162 : Statement where
  id := "cell-structure-and-function-m45432-162"
  text := "In single-celled eukaryotes, lysosomes digest ingested food"
  claim := .rel .capableOf e_GO_0005764 e_GO_0007586
  evidence := [{ pmid := 0, year := 2013, kind := .textbook, condition := some "single-celled eukaryotes", note :=
    "In single-celled eukaryotes, lysosomes are important for digestion of the food they ingest and the recycling of organelles." }]
/-- Lactose is a food source for E. coli -/
def t_molbio_m45480_30 : Statement where
  id := "molbio-m45480-30"
  text := "Lactose is a food source for E. coli"
  claim := .rel .hasInput e_GO_0005990 e_CHEBI_17716
  evidence := [{ pmid := 0, year := 2013, kind := .textbook, taxa := [e_NCBITaxon_562], note :=
    "The lac operon is a stretch of DNA with three adjacent genes that code for proteins that participate in the absorption and metabolism of lactose, a food source for E. coli." }]
/-- In plant cells, the Golgi synthesises polysaccharides -/
def t_cell_structure_and_function_m45432_158 : Statement where
  id := "cell-structure-and-function-m45432-158"
  text := "In plant cells, the Golgi synthesises polysaccharides"
  claim := .rel .capableOf e_GO_0005794 e_GO_0000271
  evidence := [{ pmid := 0, year := 2013, kind := .textbook, taxa := [e_NCBITaxon_33090], note :=
    "In plant cells, the Golgi has an additional role of synthesizing polysaccharides, some of which are incorporated into the cell wall and some of which are used in other parts of the cell." }]
/-- In prokaryotes transcription occurs in the cytoplasm -/
def t_molbio_m45476_20 : Statement where
  id := "molbio-m45476-20"
  text := "In prokaryotes transcription occurs in the cytoplasm"
  claim := .rel .occursIn e_GO_0006351 e_GO_0005737
  evidence := [{ pmid := 0, year := 2013, kind := .textbook, cellType := some e_CL_0000520, note :=
    "The prokaryotes, which include bacteria and archaea, lack membrane-bound nuclei and other organelles, and transcription occurs in the cytoplasm of the cell." }]
/-- Some antidepressant medications promote neurogenesis in the hippocampus -/
def t_the_body_s_systems_m45539_132 : Statement where
  id := "the-body-s-systems-m45539-132"
  text := "Some antidepressant medications promote neurogenesis in the hippocampus"
  claim := .effect e_CHEBI_35469 .pos (.process e_GO_0022008)
  evidence := [{ pmid := 0, year := 2013, kind := .textbook, anatomy := some e_UBERON_0002421, note :=
    "Interestingly, both exercise and some antidepressant medications also promote neurogenesis in the hippocampus." }]
/-- Decreasing blood glucose causes the pancreas to release glucagon -/
def t_the_body_s_systems_m45537_336 : Statement where
  id := "the-body-s-systems-m45537-336"
  text := "Decreasing blood glucose causes the pancreas to release glucagon"
  claim := .effect e_CHEBI_17234 .neg (.amount e_PR_P01275)
  evidence := [{ pmid := 0, year := 2013, kind := .textbook, anatomy := some e_UBERON_0000178, note :=
    "When blood-glucose levels are decreasing, the pancreas releases glucagon, which stimulates the release of stored glucose by the liver to the bloodstream." }]
/-- The G2 checkpoint blocks entry to the mitotic phase if certain conditions are not met. -/
def t_reproduction_at_the_cellular_level_m45461_141 : Statement where
  id := "reproduction-at-the-cellular-level-m45461-141"
  text := "The G2 checkpoint blocks entry to the mitotic phase if certain conditions are not met."
  claim := .effect e_GO_0007095 .neg (.process e_GO_0000086)
  evidence := [{ pmid := 0, year := 2013, kind := .textbook, condition := some "certain conditions not met", note :=
    "The G2 checkpoint bars the entry to the mitotic phase if certain conditions are not met." }]

/-- All 40, for counting. -/
def sample40 : List Statement := [t_molbio_m45475_69, t_the_body_s_systems_m45537_183, t_the_body_s_systems_m45536_190, t_cell_structure_and_function_m45434_70, t_photosynthesis_m45448_120, t_the_body_s_systems_m45537_201, t_reproduction_at_the_cellular_level_m45463_67, t_the_body_s_systems_m45537_334, t_the_body_s_systems_m45537_156, t_cell_structure_and_function_m45432_219, t_the_body_s_systems_m45537_229, t_cell_structure_and_function_m45432_25, t_reproduction_at_the_cellular_level_m45463_66, t_molbio_m45475_117, t_the_body_s_systems_m45537_53, t_molbio_m45475_67, t_how_cells_obtain_energy_m45440_11, t_the_cellular_basis_of_inheritance_m45466_103, t_the_body_s_systems_m45536_175, t_the_body_s_systems_m45536_212, t_the_cellular_basis_of_inheritance_m45466_165, t_reproduction_at_the_cellular_level_m45455_16, t_the_body_s_systems_m45538_197, t_how_cells_obtain_energy_m45437_11, t_the_cellular_basis_of_inheritance_m45465_68, t_the_body_s_systems_m45537_337, t_the_body_s_systems_m45539_28, t_the_body_s_systems_m45536_61, t_reproduction_at_the_cellular_level_m45455_9, t_the_cellular_basis_of_inheritance_m45466_106, t_the_cellular_basis_of_inheritance_m45466_119, t_how_cells_obtain_energy_m45438_42, t_the_cellular_basis_of_inheritance_m45467_83, t_cell_structure_and_function_m45432_162, t_molbio_m45480_30, t_cell_structure_and_function_m45432_158, t_molbio_m45476_20, t_the_body_s_systems_m45539_132, t_the_body_s_systems_m45537_336, t_reproduction_at_the_cellular_level_m45461_141]

end BioLean.M2.Evidence
```

### Entities, NMN (1 to 6) and chemiosmosis (7 to 9)

Claim (6) is not a new claim here. It is N4's bare claim asked in a human context. The query must
also say "aged", because N4's evidence does. Claims (7), (8) and (9) are one bare claim with three
evidence items. They are also split per paper (`CH7`, `CH8`, `CH9`) so they can be used with
`both`.

```lean
import BioLean.Derivation
import BioLean.Lib.ContextSample

/-!
# Context on evidence (M2, design "evidence")

NMN in mice and people, chemiosmosis in three membranes, and the five soundness tests S1 to S5.
Claims are bare; every context lives on an `Evidence` item; an opinion is always computed *in* a
query context `Ctx`, and only evidence that fits the query fuses.
-/

namespace BioLean.M2.Evidence
open Derivation

/-! ## Entities -/

def mouse   : Entity .taxon := ⟨"NCBITaxon:10090", "Mus musculus"⟩
def human   : Entity .taxon := ⟨"NCBITaxon:9606", "Homo sapiens"⟩
def rat     : Entity .taxon := ⟨"NCBITaxon:10116", "Rattus norvegicus"⟩
def cow     : Entity .taxon := ⟨"NCBITaxon:9913", "Bos taurus"⟩
def spinach : Entity .taxon := ⟨"NCBITaxon:3562", "Spinacia oleracea"⟩
def halo    : Entity .taxon := ⟨"NCBITaxon:2242", "Halobacterium salinarum"⟩
def mammal  : Entity .taxon := ⟨"NCBITaxon:40674", "Mammalia"⟩
def eukaryote : Entity .taxon := ⟨"NCBITaxon:2759", "Eukaryota"⟩

def NMN   : Entity .chemical := ⟨"CHEBI:16171", "nicotinamide mononucleotide"⟩
def NADp  : Entity .chemical := ⟨"CHEBI:15846", "NAD(+)"⟩
def liver : Entity .anatomy := ⟨"UBERON:0002107", "liver"⟩
-- unverified: UBERON:0001134 believed to be "skeletal muscle tissue"
def skMuscle : Entity .anatomy := ⟨"UBERON:0001134", "skeletal muscle tissue"⟩
-- unverified: HP:0040270 believed to be "Impaired glucose tolerance"
def impGlcTol : Entity .phenotype := ⟨"HP:0040270", "impaired glucose tolerance"⟩
def locomotion : Entity .process := ⟨"GO:0040011", "locomotion"⟩
-- unverified: HP:0003546 believed to be "Exercise intolerance"; "increases endurance" is
-- encoded as "reduces exercise intolerance" because no endurance term was checked.
def exIntol : Entity .phenotype := ⟨"HP:0003546", "exercise intolerance"⟩
-- unverified: GO:0032868 believed to be "response to insulin"
def insulinResp : Entity .process := ⟨"GO:0032868", "response to insulin"⟩

-- unverified: GO:0045259 "proton-transporting ATP synthase complex", GO:0015986
-- "proton motive force-driven ATP synthesis", GO:0042651 "thylakoid membrane",
-- GO:0005743 "mitochondrial inner membrane", GO:0016020 "membrane"
def atpSynthase : Entity .component := ⟨"GO:0045259", "proton-transporting ATP synthase complex"⟩
def pmfATP : Entity .process := ⟨"GO:0015986", "proton motive force-driven ATP synthesis"⟩
def thylakoidMem : Entity .component := ⟨"GO:0042651", "thylakoid membrane"⟩
def mitoInner : Entity .component := ⟨"GO:0005743", "mitochondrial inner membrane"⟩
def membrane : Entity .component := ⟨"GO:0016020", "membrane"⟩

def cell : Entity .cellType := ⟨"CL:0000000", "cell"⟩
-- unverified: PATO:0000586 "increased size", PATO:0000587 "decreased size"
def incSize : Entity .phenotype := ⟨"PATO:0000586", "increased size"⟩
def decSize : Entity .phenotype := ⟨"PATO:0000587", "decreased size"⟩
def hasQuality : Rel := ⟨.ro, 86, false⟩

/-! ## NMN (1) to (6) -/

/-- (1) NMN raises NAD+, in mouse liver. -/
def N1 : Statement where
  id := "N1"
  text := "NMN raises NAD+ in mouse liver"
  claim := .effect NMN .pos (.amount NADp)
  evidence := [{ pmid := 21982712, year := 2011, kind := .mechanistic, taxa := [mouse]
                 anatomy := some liver, note := "Yoshino 2011" }]

/-- (2) NMN reduces impaired glucose tolerance in high-fat-diet mice. -/
def N2 : Statement where
  id := "N2"
  text := "NMN reduces impaired glucose tolerance in HFD mice"
  claim := .effect NMN .neg (.phenotype impGlcTol)
  evidence := [{ pmid := 21982712, year := 2011, kind := .mechanistic, taxa := [mouse]
                 condition := some "high-fat diet", note := "Yoshino 2011" }]

/-- (3) Long-term NMN reduces the age-associated decline in physical activity in mice. Encoded as
"NMN increases locomotion", in aged mice, 12 months oral. -/
def N3 : Statement where
  id := "N3"
  text := "long-term NMN reduces age-associated decline in physical activity in mice"
  claim := .effect NMN .pos (.process locomotion)
  evidence := [{ pmid := 28068222, year := 2016, kind := .mechanistic, taxa := [mouse]
                 condition := some "aged", dose := some "100 or 300 mg/kg/day, oral (drinking water)"
                 duration := some "12 months", note := "Mills 2016" }]

/-- (4) NMN increases endurance in aged mice. -/
def N4 : Statement where
  id := "N4"
  text := "NMN increases endurance in aged mice"
  claim := .effect NMN .neg (.phenotype exIntol)
  evidence := [{ pmid := 29570999, year := 2018, kind := .mechanistic, taxa := [mouse]
                 condition := some "aged", note := "Das 2018" }]

/-- (5) NMN increases muscle insulin sensitivity in prediabetic postmenopausal women (RCT). -/
def N5 : Statement where
  id := "N5"
  text := "NMN increases muscle insulin sensitivity in prediabetic postmenopausal women"
  claim := .effect NMN .pos (.process insulinResp)
  evidence := [{ pmid := 33888596, year := 2021, kind := .rct, taxa := [human]
                 anatomy := some skMuscle, condition := some "prediabetic postmenopausal women"
                 dose := some "250 mg/day, oral", duration := some "10 weeks", note := "Yoshino 2021" }]

/-- (6) HYPOTHETICAL: NMN increases endurance in humans. In this design it is not a new claim: it
is N4's bare claim, *asked* in a human context. It has no evidence of its own. -/
def N6 : Statement where
  id := "N6"
  text := "HYPOTHETICAL: NMN increases endurance in humans"
  claim := N4.claim
  evidence := []

/-- The query for (6). It must name "aged", because N4's evidence does: dropping the condition is a
generalisation over age, which no rule here performs. -/
def humanAged : Ctx := { taxon := some human, condition := some "aged" }
def mouseAged : Ctx := { taxon := some mouse, condition := some "aged" }

/-! ## Chemiosmosis (7) to (9): one bare claim, three evidence items -/

def chemiosmosisEvidence : List Evidence := [
  { pmid := 5220864, year := 1966, kind := .inVitro, taxa := [spinach], component := some thylakoidMem
    inVitro := true, note := "Jagendorf 1966: acid-base transition, thylakoids make ATP in the dark" },
  { pmid := 16742541, year := 1967, kind := .inVitro, taxa := [rat], component := some mitoInner
    inVitro := true, note := "Mitchell & Moyle 1967: rat liver mitochondria" },
  { pmid := 4272126, year := 1974, kind := .inVitro, taxa := [halo, cow], inVitro := true
    condition := some "reconstituted proteoliposome"
    note := "Racker & Stoeckenius 1974: bacteriorhodopsin + bovine ATP synthase in liposomes" } ]

/-- (7) + (8) + (9): ATP synthase makes ATP from a proton gradient. -/
def CH : Statement where
  id := "CH"
  text := "ATP synthase makes ATP from a proton gradient"
  claim := .rel .capableOf atpSynthase pmfATP
  evidence := chemiosmosisEvidence

/-- The same split into one statement per paper, for `both`. -/
def CH7 : Statement := { CH with id := "CH7", evidence := chemiosmosisEvidence.take 1 }
def CH8 : Statement := { CH with id := "CH8", evidence := (chemiosmosisEvidence.drop 1).take 1 }
def CH9 : Statement := { CH with id := "CH9", evidence := chemiosmosisEvidence.drop 2 }

```

## (d) The five soundness tests

Every theorem below is checked by `decide +kernel` inside `lake build BioLeanLib`.

```lean
/-! ## Soundness tests -/

/-- Strip every context field: what the evidence would look like if a curator forgot to tag it. -/
def _root_.BioLean.Statement.untagged (s : Statement) : Statement :=
  { s with evidence := s.evidence.map fun e =>
      { e with taxa := [], anatomy := none, cellType := none, component := none, condition := none } }

/-! ### S1. Mouse and human evidence do not fuse by accident -/

/-- Someone pools mouse and human papers on one bare claim, INDRA-style. -/
def pooled : Statement where
  id := "pooled"
  text := "NMN increases insulin sensitivity (mouse + human papers)"
  claim := N5.claim
  evidence := N5.evidence ++ [{ pmid := 21982712, year := 2011, kind := .mechanistic
                                taxa := [mouse], anatomy := some liver, condition := some "high-fat diet"
                                note := "Yoshino 2011: NMN enhances hepatic insulin sensitivity in HFD mice" }]

def humanTrial : Ctx :=
  { taxon := some human, anatomy := some skMuscle, condition := some "prediabetic postmenopausal women" }
def mouseHFD : Ctx := { taxon := some mouse, anatomy := some liver, condition := some "high-fat diet" }

/-- Asked with no context, tagged evidence is silent: the context-free claim gets nothing. -/
theorem S1_contextFree_vacuous : ((lit pooled).opinion).belief = 0 := by decide +kernel
/-- Asked in the trial's context, only the RCT counts: exactly one RCT's worth (17/20). -/
theorem S1_human_only : ((lit pooled).opinion humanTrial).belief = 17 / 20 := by decide +kernel
/-- Asked in the mouse context, only the mouse paper counts. -/
theorem S1_mouse_only : ((lit pooled).opinion mouseHFD).belief = 7 / 10 := by decide +kernel
/-- `both` of a mouse and a human derivation of the same bare claim type-checks (nothing in the type
stops it), but each leaf still filters: in the human context the mouse side adds nothing. -/
theorem S1_both_filtered :
    ((both (lit { pooled with evidence := pooled.evidence.drop 1 }) (lit N5)).opinion humanTrial).belief
      = 17 / 20 := by decide +kernel
/-- The hole: untagged evidence fits every context, so a forgotten tag fuses mouse into human. -/
theorem S1_untagged_fuses : 17 / 20 < ((lit pooled.untagged).opinion humanTrial).belief := by
  decide +kernel

/-! ### S2. Mouse to human needs an explicit, weighted transport step -/

/-- No free path: the mouse paper alone says nothing about aged humans. -/
theorem S2_lit_silent : ((lit N4).opinion humanAged).belief = 0 := by decide +kernel
/-- With an explicit `transport mouse human`: 3/10 of the mouse opinion (7/10), i.e. 21/100. -/
theorem S2_transport : ((transport mouse human (lit N4)).opinion humanAged).belief = 21 / 100 := by
  decide +kernel
/-- And it is never more than 3/10, whatever is transported (`opinion_transport_belief_le`). -/
example (d : Derivation N6.claim) (q : Ctx) : ((transport mouse human d).opinion q).belief ≤ 3 / 10 :=
  opinion_transport_belief_le mouse human d q
/-- Transport only runs between sibling taxa: mouse to Mammalia is a generalisation, not transport. -/
theorem S2_not_generalise :
    ((transport mouse mammal (lit N4)).opinion { humanAged with taxon := some mammal }).belief = 0 := by
  decide +kernel
/-- So the hypothetical (6) is not established in aged humans, at any useful level. -/
example : ¬ (3 / 10 < ((transport mouse human (lit N4)).opinion humanAged).belief) := by decide +kernel

/-! ### S3. Specialisation is free -/

/-- "Chromosomes are located in the nucleus of eukaryotic cells" (textbook, taxon Eukaryota), asked
about mice: same opinion, no new evidence, no rule. -/
theorem S3_specialise :
    ((lit t_reproduction_at_the_cellular_level_m45455_16).opinion { taxon := some mouse }).belief =
      ((lit t_reproduction_at_the_cellular_level_m45455_16).opinion { taxon := some eukaryote }).belief ∧
    ((lit t_reproduction_at_the_cellular_level_m45455_16).opinion { taxon := some mouse }).belief = 4 / 5 := by
  decide +kernel

theorem S3_mouse_established :
    EstablishedIn { taxon := some mouse } t_reproduction_at_the_cellular_level_m45455_16.claim (4 / 5) :=
  ⟨.lit _, by decide +kernel⟩

/-! ### S4. Thylakoid + mitochondrion does not give "across a membrane" for free -/

theorem S4_thylakoid : ((lit CH).opinion { taxon := some spinach, component := some thylakoidMem }).belief
    = 1 / 2 := by decide +kernel
theorem S4_mito : ((lit CH).opinion { taxon := some rat, component := some mitoInner }).belief
    = 1 / 2 := by decide +kernel
/-- Asked about "a membrane", both are more specific than the query and neither fits. -/
theorem S4_membrane_not_free : ((lit CH).opinion { component := some membrane }).belief = 0 := by
  decide +kernel
/-- Fusing the per-paper statements does not help: each leaf is filtered by the same query. -/
theorem S4_both_not_free :
    ((both (lit CH7) (lit CH8)).opinion { component := some membrane }).belief = 0 := by decide +kernel
/-- The reconstituted chimera (9) lists two taxa and fits no single-taxon query. -/
theorem S4_racker_unreachable :
    ((lit CH9).opinion { taxon := some cow, condition := some "reconstituted proteoliposome" }).belief
      = 0 := by decide +kernel
/-- ... and with an in-vivo-only query nothing chemiosmotic survives. -/
theorem S4_in_vivo : ((lit CH).opinion { taxon := some rat, component := some mitoInner
                                         inVivoOnly := true }).belief = 0 := by decide +kernel

/-! ### S5. Hypotonic swell, hypertonic shrink -/

def swell : Statement where
  id := "swell"
  text := "cells in a hypotonic solution swell"
  claim := .rel hasQuality cell incSize
  evidence := [{ pmid := 0, year := 2013, kind := .textbook, condition := some "hypotonic solution" }]

def shrink : Statement where
  id := "shrink"
  text := "cells in a hypertonic solution shrink"
  claim := .rel hasQuality cell decSize
  evidence := [{ pmid := 0, year := 2013, kind := .textbook, condition := some "hypertonic solution" }]

/-- "Cells in a hypertonic solution do not swell": true, and the negation of `swell`'s bare claim. -/
def noSwellHyper : Statement where
  id := "noSwellHyper"
  text := "cells in a hypertonic solution do not swell"
  claim := .notRel hasQuality cell incSize
  evidence := [{ pmid := 0, year := 2013, kind := .textbook, condition := some "hypertonic solution" }]

def hypo : Ctx := { condition := some "hypotonic solution" }
def hyper : Ctx := { condition := some "hypertonic solution" }

-- swell and shrink are different bare claims: `both (lit swell) (lit shrink)` does not type-check.
#check_failure (both (lit swell) (lit shrink))

/-- In the hypotonic context the clash is one-sided: swelling believed, no disbelief. -/
theorem S5_hypo : (clash (lit swell) (lit noSwellHyper) hypo).belief = 4 / 5 ∧
    (clash (lit swell) (lit noSwellHyper) hypo).disbelief = 0 := by decide +kernel
/-- In the hypertonic context, the other way round. Never contested. -/
theorem S5_hyper : (clash (lit swell) (lit noSwellHyper) hyper).belief = 0 ∧
    (clash (lit swell) (lit noSwellHyper) hyper).disbelief = 4 / 5 := by decide +kernel
/-- Shrinking is established in hypertonic solution and silent in hypotonic. -/
theorem S5_shrink : ((lit shrink).opinion hyper).belief = 4 / 5 ∧
    ((lit shrink).opinion hypo).belief = 0 := by decide +kernel
/-- Without the condition tags the same two textbook sentences contradict each other. -/
theorem S5_untagged_contested :
    (clash (lit swell.untagged) (lit noSwellHyper.untagged)).verdict = .contested := by decide +kernel

/-! ## The 40 -/

theorem sample40_count : sample40.length = 40 := rfl

/-- Each of the 40 fits no context-free query whenever it carries a tag (39 of 40 do). -/
theorem sample40_contextFree_silent :
    (sample40.filter fun s => (lit s).opinion.belief == 0).length = 39 := by decide +kernel

#eval IO.println ((transport mouse human (lit N4)).report humanAged)
#eval IO.println ((both (lit CH7) (lit CH8)).report { component := some membrane })
#eval IO.println s!"pooled, no context: {(lit pooled).opinion}; human trial: {(lit pooled).opinion humanTrial}; untagged in human: {(lit pooled.untagged).opinion humanTrial}"

end BioLean.M2.Evidence
```

Build output of the two reports:

```
Claim: NMN [CHEBI:16171] →− exercise intolerance [HP:0003546]  [in Homo sapiens [NCBITaxon:9606], aged]
Verdict: unsupported  ⟨b=0.210 d=0.000 u=0.790⟩
⟨b=0.210 d=0.000 u=0.790⟩ transport Mus musculus [NCBITaxon:10090] ⇒ Homo sapiens [NCBITaxon:9606] ⊢ ...
  ⟨b=0.700 d=0.000 u=0.300⟩ N4: ...  [1 refs]
Rests on 1 statements, 1 PMIDs: 29570999

Claim: ATP synthase complex [GO:0045259] capable of pmf-driven ATP synthesis [GO:0015986]  [in membrane [GO:0016020]]
Verdict: unsupported  ⟨b=0.000 d=0.000 u=1.000⟩
⟨b=0.000 d=0.000 u=1.000⟩ fuse ⊢ ...
  ⟨b=0.000 d=0.000 u=1.000⟩ CH7: ...
  ⟨b=0.000 d=0.000 u=1.000⟩ CH8: ...

pooled, no context: ⟨b=0.000⟩; human trial: ⟨b=0.850⟩; untagged in human: ⟨b=0.888⟩
```

| test | outcome | how |
|---|---|---|
| S1 mouse + human do not fuse by accident | **pass, by evaluation, not by type** | A pooled statement gets b = 0 with no context, 0.85 (the RCT alone) in the trial context, and 0.70 (the mouse paper alone) in the mouse context. `both` of a mouse and a human derivation of the same bare claim *type-checks*, but each leaf filters, so it adds nothing. The hole is proved too: strip the tags and the mouse paper silently lifts the human opinion to 0.888. The type system cannot enforce S1 here, because the claim (the type index) has no context. Only the discipline "every evidence item is tagged" does, and an untagged item counts as universal. |
| S2 mouse to human needs explicit weighted transport | **pass** | `lit N4` in aged humans gives b = 0. `transport mouse human (lit N4)` gives 3/10 × 7/10 = 21/100. `opinion_transport_belief_le` proves the 3/10 ceiling for every derivation and every query. Transport to a non-sibling (mouse to Mammalia) gives 0. |
| S3 free specialisation | **pass** | The textbook "chromosomes in the nucleus of eukaryotic cells" (tagged Eukaryota) gives 4/5 in a mouse query, the same as in a Eukaryota query, with no rule and no new evidence. `EstablishedIn {taxon := mouse} ... (4/5)` holds. |
| S4 thylakoid + mitochondrion to "a membrane" is not free | **pass** | Each fits only its own (taxon, membrane) query, at 1/2. A `membrane` query gives 0, for the statement and for `both CH7 CH8`, because both are more specific than the query. Side effect: Racker's chimera (taxa = [Halobacterium, Bos]) fits no single-taxon query at all, and an in-vivo-only query drops all three. |
| S5 hypotonic swell vs hypertonic shrink | **pass, with a caveat** | The bare claims are `cell has_quality increased size` and `... decreased size`, with condition text on the evidence. They are different claims, so `both` is a type error (`#check_failure`). Against the true negation "in hypertonic solution cells do not swell", `clash` in the hypotonic query is b = 0.8, d = 0, and in the hypertonic query b = 0, d = 0.8. It is never contested. Untagged, the same pair is proved *contested*. The caveat: read without their evidence, the bare claims "cells swell" and "cells do not swell" contradict each other. |

## (e) Scorecard

| item | result |
|---|---|
| claims expressed | **40/40** compile, plus 9/9 NMN/chemiosmosis (6 is a query, not a claim). 8 of the 40 are lossy, listed below |
| S1 | pass by evaluation; **not enforced by types** (discipline: tag every evidence item) |
| S2 | pass (explicit `transport`, ≤ 3/10 proved) |
| S3 | pass |
| S4 | pass |
| S5 | pass (bare claims read as contradictory out of context) |
| new constructors | 1 (`Derivation.transport`); plus structure `Ctx`, class `ContextModel`, 8 `Evidence` fields, `Opinion.discount` |
| new rules | 1 (`transport`); specialisation needs no rule |
| lines of Lean changed (core) | +233 −48 (Belief 20, Context 98, Derivation 85/45, Evidence 30/3), plus lakefile +2 −1; examples 276, generated 381 |
| free specialisation | **yes** |

The 8 lossy encodings among the 40:

- `the-cellular-basis-of-inheritance-m45466-103`, "in *some* organisms": the context is empty. The
  evidence is therefore untagged and fits **every** query, so a "some" claim became universal.
  This is the S1 hole showing up in real data.
- `molbio-m45475-67`, "some cancer cells": "some" sits in the condition text, not in
  `Quantifier.some`.
- `m45466-106`, "animals and some fungi": only Metazoa is tagged, so the fungi are lost.
- `m45438-42`, "capable *only* of glycolysis": "only" cannot be expressed.
- `m45455-9`: the taxon is NCIT:C14263 "prokaryote", which is not in NCBITaxon or the subsumption
  table, so no taxon query reaches it.
- `m45463-67` and `m45463-66`: "prokaryote" is tagged as Bacteria, which drops Archaea.
- `m45476-20`: "in prokaryotes" is given as cellType CL:0000520 rather than as a taxon.
- `m45432-162`: "single-celled eukaryotes" is free condition text, because no NCBITaxon clade
  exists for it.

On top of these, every condition is free text matched by string equality. Any query must reproduce
the exact string ("high-fat diet", "aged").

## (f) Verdict

The evidence-level design passes all five tests numerically. S1 is enforced only at evaluation
time and only for tagged evidence. A `Derivation` of a bare claim cannot tell mouse from human, so
`both` happily joins them, and one forgotten tag fuses them. That hole is not hypothetical: one of
the 40 real claims ("in some organisms") arrived untagged and is now universal. Strict
fit-by-subsumption makes every query name the full context. Claim (6) had to be asked as "aged
humans". A mouse query cannot see liver evidence. A chain whose links are in different tissues
(NMN raises NAD+ in liver, NAD+ helps muscle insulin response) fits no single query. The forced
parts were these:

- **The transport discount.** I applied it once, to the whole transported derivation. Applying it
  per evidence item, as INDRA-style weighting suggests, would let four independent mouse papers at
  0.21 each fuse to about 0.52, above the 3/10 ceiling.
- **The chimera.** Bacteriorhodopsin plus bovine ATP synthase belongs to no taxon, so Racker's
  decisive experiment is dead weight until M4.
- **The type index.** Because the context is not in the type index, a claim's printed form hides
  where it holds, and the design leans on discipline exactly where the wrapper design leans on the
  type checker.

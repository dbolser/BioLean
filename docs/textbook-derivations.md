# What can be derived from the textbook claims?

Question: treat the annotated OpenStax claims (`data/textbook/claims/*.json`) as statements in biolib. Which textbook sentences follow from other textbook sentences by a rule? Those sentences are theorems. The rest are axioms. A derivation with a missing premise is a hypothesis (the ILP hole).

Method: read the eight claim files (4,695 claim rows after dropping `not_claim`), search by topic, and build derivations by hand. Every claim id below exists in the files (checked by script). The Lean is a sketch: it uses the current `Derivation` constructors where they fit and names the missing ones where they do not. Nothing here was compiled.

Naming in the sketches: `S45537_200` is the `Statement` for claim `…-m45537-200`. Claim ids are shortened to `chapter:module-n` in the tables (`body:m45537-200` is `the-body-s-systems-m45537-200`; body modules m45533 to m45536 are in file `-a`, m45537 to m45539 in file `-b`).

## Headline

- **52 derivations** found, each with two or more premises, and each conclusion is a sentence the book states.
- **4 typecheck today** with `lit`, `viaActivity`, `viaAmount`, `both`: T1, T3, T4, T6. All four are hormone feedback loops. T1 needs its conclusion re-annotated (see note).
- **6 typecheck** once the already-proposed `inContext`, `specialise`, `generalize`, `transport` exist (adds T5, T16).
- The biggest blocker is not a derivation rule. It is that **structural claims** (is_a, part_of, has_part, occurs_in, has_input, has_output, transport) are not `Claim` constructors. 24 of 52 derivations need them. Next is **quantities with arithmetic** (13).
- Theorem rate: these 52 derivations, plus about 15 sibling sentences that the same proofs also give (listed in the notes), make about 65 theorems found by hand. That is a lower bound: about 1.4% of claim rows. A further 287 of the 2,743 claims that have a Lean form are exact restatements of another claim (same Lean term, mostly the end-of-section summaries and glossary). Those are theorems by `lit` reuse. Together, roughly 1 in 8 Lean-annotated sentences is not a new axiom.
- Two proof attempts caught the book overclaiming: T32 (only *some* amino acids have several codons) and gap G2 (a tortoiseshell cat need not be female: the files' own XXY claims break the proof).

## Constructors and rules needed

Count = number of the 52 derivations that need it. Existing ones are marked.

| constructor / rule | count | status / meaning |
|---|---:|---|
| `structural claims` | 24 | new: `Claim.isA / partOf / hasPart / lacksPart / occursIn / hasInput / hasOutput / transport / requires` as claims, so they can be premises |
| `quantity + count` | 13 | new: a numeric claim (`Claim.quantity`) plus an arithmetic side condition discharged by `norm_num` / `decide` |
| `viaAmount` | 10 | existing |
| `inheritIsA` | 7 | new: specialise along is_a: `X is_a Y`, `Y has P` ⊢ `X has P` (subclass inherits) |
| `inContext` | 5 | proposed: section 5 of formalisms/biolean.md; context inside the claim |
| `both` | 3 | existing |
| `inputPositive` | 3 | new: bridge `P has_input m` ⊢ `m →+ P` (an input raises its process) |
| `viaGradient` | 3 | new: chain through `Target.gradient` (needs the gradient usable as an agent) |
| `occursInLift` | 3 | new: `p occurs_in X`, `X part_of Y` ⊢ `p occurs_in Y`; also occurs_during, and a whole from its stages |
| `pathCompose` | 3 | new: `m transported A→B`, `B→C` ⊢ `A→C` |
| `generalize` | 2 | proposed: case study 4; here also over an entity class (hormones), not only context |
| `viaActivity` | 2 | existing |
| `outputPositive` | 2 | new: bridge `P has_output m` ⊢ `P →+ amount m` |
| `toMediated` | 2 | new: a two-step chain ⊢ the `mediatedBy` claim it witnesses |
| `lossOfFunction` | 2 | new: `a →s t` ⊢ `loss(a) →(−s) t` (knockout, inhibitor, disease) |
| `outputLift` | 2 | new: `part has_output m`, `part part_of whole` ⊢ `whole has_output m` |
| `occursAtRequired` | 2 | new: `P requires X`, `X located_in L` ⊢ `P occurs_in L` |
| `lawInstance` | 2 | new: a general law with a variable (osmosis, diffusion) applied to an instance |
| `ofMediated` | 1 | new: `mediatedBy a s t m` ⊢ `effect a s t` (forget the mediator) |
| `specialise (context)` | 1 | proposed: a claim in a wide context holds in a narrower one |
| `Claim.loop` | 1 | new: a negative-feedback predicate over `x →− x` chains |
| `liftAgent` | 1 | new: an effect of a part is an effect of the whole process |
| `viaPart` | 1 | new: inhibiting a required part inhibits the whole |
| `viaProcess` | 1 | new: chain through a `Target.process` (only activity and amount chain today) |
| `inverseQuantity` | 1 | new: sign flip by a physical identity (pH vs [H+]) |
| `sole` | 1 | new: closed-world 'only': X can only do P, P makes m ⊢ P is X's sole source of m |
| `conservation` | 1 | new: atom/mass conservation across a reaction |
| `ioDual` | 1 | new: two processes whose input and output sets swap |
| `necessity` | 1 | new: `P requires A`, `¬A` ⊢ `¬P` |
| `product (independence)` | 1 | new: independent choices multiply |
| `transport` | 1 | proposed: case study 3; here licensed by a `similar_to` sentence |
| `pigeonhole` | 1 | new: a counting lemma that yields only an existential |
| `partOfTrans` | 1 | new: part_of transitivity |
| `capableViaPart` | 1 | new: `X has_part Y`, `Y capable_of P` ⊢ `X capable_of P` |
| `isATrans` | 1 | new: is_a transitivity |
| `lacksPartInherit` | 1 | new: `X lacks every C`, `Y is_a C` ⊢ `X lacks Y` |
| `requiresTransport` | 1 | new: made in L1, needed in L2 ⊢ must move L1 → L2 |

Smart cheap wins, in order: (1) structural claims, which also unlock most of the 3,730 `missing_construct` rows; (2) `quantity` with an arithmetic side goal, since Lean already proves `2^23 > 8000000` for free; (3) `inputPositive` / `outputPositive` bridges, which turn has_input/has_output into signed edges so the existing chain rules apply; (4) `viaProcess` and `viaGradient`, which are one-line copies of `viaAmount`.

## The derivations

### A. Signed chains (the existing rule family)

| # | conclusion (textbook sentence) | premises | rule | needs |
|---|---|---|---|---|
| T1 (today) | `body:m45534-23` A rise in blood glucose after a meal triggers adjustments that lower blood glucose | `body:m45537-200`, `body:m45537-53` | viaAmount (pos * neg = neg): glucose raises insulin, insulin lowers glucose | `viaAmount` |
| T2 | `body:m45534-3` Blood glucose level is maintained homeostatically | `body:m45537-199`, `body:m45537-201`, `body:m45537-200`, `body:m45537-53` | second chain through glucagon (neg * pos = neg), fused with T1 by both | `viaAmount`, `both`, `ofMediated` |
| T3 (today) | `body:m45534-8` A rise in blood calcium signals organs that lower blood calcium | `body:m45537-134`, `body:m45537-135` | viaAmount (pos * neg = neg): calcium raises calcitonin, calcitonin lowers calcium | `viaAmount` |
| T4 (today) | `body:m45534-5` Blood calcium level is maintained homeostatically | `body:m45537-141`, `body:m45537-140`, `body:m45537-134`, `body:m45537-135` | second chain through PTH (neg * pos = neg), fused with T3 by both; no shared axioms | `viaAmount`, `both` |
| T5 | `body:m45537-264` In goiter the body compensates by producing more TSH | `body:m45537-263`, `body:m45537-258` | viaAmount (neg * neg = pos): goiter lowers T3/T4, T3/T4 lowers TSH, so goiter raises TSH | `viaAmount`, `specialise (context)`, `inContext` |
| T6 (today) | `body:m45537-255` Hormone production and release are primarily controlled by negative feedback | `body:m45537-129`, `body:m45537-258` | viaAmount (pos * neg = neg): thyroid hormone lowers TSH, TSH raises thyroid hormone, so TH →− TH (one instance of 'hormones are controlled by negative feedback') | `viaAmount` |
| T7 | `body:m45537-255` Hormone production and release are primarily controlled by negative feedback | `body:m45537-200`, `body:m45537-53`, `body:m45537-134`, `body:m45537-135`, `body:m45537-129`, `body:m45537-258` | generalize over the agent (hormone) from instances T1, T3, T6 to 'hormone levels are controlled by negative feedback' | `generalize`, `Claim.loop` |
| T8 | `energy:m45437-246` Abundant ATP lets the cell prevent production of ATP | `energy:m45437-244`, `energy:m45437-245` | viaActivity (neg * pos = neg): ATP inhibits catabolic enzymes, catabolism makes ATP, so ATP →− ATP production | `viaActivity`, `outputPositive` |
| T9 | `energy:m45437-248` High ADP relative to ATP triggers more ATP production through sugar catabolism | `energy:m45437-247`, `energy:m45437-245` | viaActivity (pos * pos = pos), then package the chain as a mediatedBy claim | `viaActivity`, `outputPositive`, `toMediated` |
| T10 | `photo:m45448-121` stomatal closure slows photosynthesis via reduced carbon dioxide | `photo:m45448-119`, `photo:m45448-110` | viaAmount (neg * pos = neg): closure lowers leaf CO2, CO2 is an input of photosynthesis, so closure slows photosynthesis via CO2 | `viaAmount`, `inputPositive`, `toMediated`, `inContext` |
| T11 | `photo:m45448-96` chemical energy from the light-dependent reactions drives the Calvin cycle | `photo:m45448-140`, `photo:m45452-108`, `photo:m45448-141`, `photo:m45452-110` | two viaAmount chains (through ATP and through NADPH), fused by both | `viaAmount`, `inputPositive`, `both` |
| T12 | `photo:m45448-140` the light-dependent reactions form ATP | `photo:m45452-71`, `photo:m45452-104`, `photo:m45452-121` | chain through a gradient: electron transport builds the thylakoid H+ gradient, the gradient powers ATP synthase | `viaGradient`, `structural claims`, `liftAgent` |
| T13 | `energy:m45439-109` The products of the electron transport chain are water and ATP | `energy:m45439-50`, `energy:m45439-37` | chain through a gradient (mitochondrial): ETC builds the H+ gradient, the gradient makes ATP | `viaGradient` |
| T14 | `energy:m45439-118` Cyanide stops ATP synthesis | `energy:m45439-52`, `energy:m45439-53`, `energy:m45439-50`, `energy:m45439-37` | part inhibition then gradient chain: cyanide inhibits complex IV, complex IV is part of the ETC (so the ETC stops, = 45439-116), the ETC builds the gradient, the gradient makes ATP | `structural claims`, `viaPart`, `viaGradient` |
| T15 | `energy:m45439-117` Cyanide raises the pH of the intermembrane space | `energy:m45439-116`, `energy:m45439-58` | chain then inverse quantity: cyanide stops pumping H+ into the intermembrane space, so [H+] there falls, so pH rises | `viaProcess`, `inverseQuantity` |
| T16 | `energy:m45439-129` Chemiosmosis is the movement of hydrogen ions down their gradient across a membrane through ATP synthase to generate ATP | `photo:m45452-84`, `energy:m45439-71`, `energy:m45439-72` | generalize over context (component): ATP synthase makes ATP from an H+ gradient in thylakoids and in mitochondria, so 'across a membrane' with no component | `generalize`, `inContext` |
| T17 | `repro:m45462-46` Loss of p53 function allows cells to divide, propagating the mutation and allowing accumulation of new mutations. | `repro:m45462-37`, `repro:m45462-33` | loss of function flips the sign: p53 →− cell cycle, so loss(p53) →+ cell cycle | `lossOfFunction` |
| T18 | `energy:m45438-44` If glycolysis is interrupted, red blood cells die | `energy:m45438-43`, `energy:m45439-64` | viaAmount (pos * neg = neg) then loss of function: glycolysis →+ ATP, ATP →− cell death, so glycolysis interrupted →+ death (in red blood cells) | `viaAmount`, `lossOfFunction`, `inContext` |
| T19 | `energy:m45438-43` Glycolysis is the sole source of ATP in mammalian red blood cells | `energy:m45438-42`, `energy:m45439-31` | closed world: red cells can only do glycolysis, glycolysis makes ATP, so glycolysis is their sole ATP source | `structural claims`, `sole` |
| T20 | `cell:m45435-26` Metabolic poisons that interfere with ATP supply inhibit active transport | `cell:m45435-1`, `cell:m45435-67` | viaAmount (neg * pos = neg): a poison lowers ATP, active transport uses ATP, so the poison inhibits active transport | `viaAmount`, `inputPositive` |

**T1.** Typechecks today. The file annotates the conclusion as glucose →+ process glucoseLowering; the derived form glucose →− amount glucose is the honest one, so re-annotate.
```lean
def T1 : Derivation (.effect bloodGlucose .neg (.amount bloodGlucose)) :=
  .viaAmount (.lit S45537_200) (.lit S45537_53)
```
**T2.** 45537-201 is a mediatedBy claim (via liver); chaining it needs a rule that forgets the mediator.
```lean
def T2 := .both T1 (.viaAmount (.lit S45537_199) (.ofMediated (.lit S45537_201)))
```
**T3.** 
```lean
def T3 : Derivation (.effect bloodCa .neg (.amount bloodCa)) :=
  .viaAmount (.lit S45537_134) (.lit S45537_135)
```
**T4.** Best example of `both` in the textbook: two hormones, two independent arms, one homeostatic claim.
```lean
def T4 := .both T3 (.viaAmount (.lit S45537_141) (.lit S45537_140))
```
**T5.** Shape is plain viaAmount; blocked only because the premises sit in different contexts (human; none). The annotation of 264 uses an agent lowThyroidHormone, which hides the double negative.
```lean
def T5 := .chainIn goiterCtx (.specialise h (.lit S45537_263)) (.specialise h' (.lit S45537_258))
```
**T6.** Typechecks today as the instance; the general sentence needs T7.
```lean
def T6 : Derivation (.effect TH .neg (.amount TH)) :=
  .viaAmount (.lit S45537_258) (.lit S45537_129)
```
**T7.** Same induction problem as case study 4: three hormones never prove 'all hormones'.
```lean
def T7 := .generalize (cls := hormone) [T1, T3, T6] (coverage := 3 / nHormones)
```
**T8.** As annotated, 244 targets a process, not an activity, so it needs viaProcess instead.
```lean
def T8 := .viaActivity (.lit S45437_244) (.outputPositive (.lit S45437_245))
```
**T9.** 'High ADP relative to ATP' is a ratio; the schema can only say ADP.
```lean
def T9 := .toMediated (.viaActivity (.lit S45437_247) (.outputPositive (.lit S45437_245)))
```
**T10.** The textbook writes the conclusion with its mediator ('via reduced carbon dioxide'), which is exactly the shape a chain produces.
```lean
def T10 := .toMediated (.viaAmount (.lit S45448_119) (.inputPositive (.lit S45448_110)))
```
**T11.** Not independent in the biological sense (same light reactions), but no shared axiom, so `sharedAxioms` will not warn. Worth noting.
```lean
def T11 := .both (.viaAmount (.lit S45448_140) (.inputPositive (.lit S45452_108)))
               (.viaAmount (.lit S45448_141) (.inputPositive (.lit S45452_110)))
```
**T12.** T11 then uses T12 as a lemma: the textbook sentence 45448-140 is both a premise and a theorem.
```lean
def T12 := .liftAgent etc_partOf_LDR
  (.viaGradient (.lit S45452_104) (.lit S45452_121))
```
**T13.** Blocked only because 45439-37 needs the gradient as the agent, and agents must be entities.
```lean
def T13 : Derivation (.effect ETC .pos (.amount ATP)) :=
  .viaGradient (.lit S45439_50) (.lit S45439_37)
```
**T14.** Two textbook sentences (116, 118) fall out as theorems of one chain.
```lean
def T14a := .viaPart (.lit S45439_52) complexIV_partOf_ETC   -- ⊢ 45439-116
def T14  := .viaGradient' T14a (.lit S45439_50) (.lit S45439_37) -- ⊢ 45439-118
```
**T15.** Sign flip by a physical identity, not a biological claim.
```lean
def T15 := .inverse pH_inv_H (.viaProcess T14a (.lit S45439_58))
```
**T16.** Coverage 2 of 3 known energy membranes (bacterial plasma membrane is missing from these files).
```lean
def T16 := .generalize (field := .component) [⟨thylakoidCtx, .lit S45452_84⟩, ⟨mitoCtx, .lit S45439_72⟩]
```
**T17.** The same rule applied to 45462-33 (tumour suppressors code negative regulators) gives 45462-83.
```lean
def T17 := .lossOfFunction (.lit S45462_37)  -- p53 →− cycle ⊢ loss p53 →+ cycle
```
**T18.** Needs 'sole source' (T19) to be sound: if another ATP source existed, the knockout would not kill.
```lean
def T18 := .lossOfFunction (.viaAmount (.lit S45438_43) (.lit S45439_64))
```
**T19.** 
```lean
def T19 := .sole (.lit S45438_42) (.outputPositive (.lit S45439_31))
```
**T20.** Applying the same rule to T14 (cyanide →− ATP) gives a sentence the book never writes: cyanide inhibits active transport. A free theorem.
```lean
def T20 := .viaAmount (poison_lowers_ATP) (.inputPositive (.lit S45435_67))
```

### B. Counting and stoichiometry

| # | conclusion (textbook sentence) | premises | rule | needs |
|---|---|---|---|---|
| T21 | `energy:m45438-58` Glycolysis yields a net gain of two ATP per glucose | `energy:m45438-56`, `energy:m45438-57` | stoichiometry: 4 ATP made − 2 ATP invested = net 2 | `quantity + count` |
| T22 | `energy:m45439-32` Most ATP from aerobic glucose catabolism is not generated directly by glycolysis or the TCA cycle | `energy:m45439-74`, `energy:m45439-79` | proportion: 90% of ATP comes from chemiosmosis, chemiosmosis is part of oxidative phosphorylation (disjoint from glycolysis and TCA), and 0.9 > 0.5 | `quantity + count`, `structural claims` |
| T23 | `photo:m45453-36` six turns of the Calvin cycle are needed to make one six-carbon carbohydrate | `photo:m45453-37`, `photo:m45453-4`, `energy:m45438-53` | carbon counting across chapters: 1 CO2 fixed per turn, all sugar carbon comes from CO2, glucose has 6 carbons, so 6 turns per glucose (also gives 45453-40) | `quantity + count`, `conservation` |
| T24 | `photo:m45453-122` the reactants of photosynthesis are the products of respiration and vice versa | `photo:m45453-112`, `photo:m45453-113`, `photo:m45453-114`, `photo:m45453-115`, `photo:m45453-116`, `photo:m45453-117`, `photo:m45453-118`, `photo:m45453-119`, `photo:m45453-120` | input/output duality: inputs(photosynthesis) = {CO2, H2O} = outputs(respiration) and outputs(photosynthesis) = {sugar, O2} = inputs(respiration) | `structural claims`, `ioDual` |
| T25 | `repro:m45455-49` Human gametes have 23 chromosomes, one complete set. | `repro:m45455-17`, `repro:m45455-18`, `repro:m45455-69`, `repro:m45455-22` | counting: 46 chromosomes in two sets is 23 per set; a gamete is haploid, one set, so 23 | `quantity + count`, `structural claims`, `inheritIsA` |
| T26 | `inherit:m45466-18` Gametes fuse with another haploid gamete to produce a diploid cell | `inherit:m45465-57`, `inherit:m45466-5`, `inherit:m45466-3`, `inherit:m45466-6` | set addition: two haploid gametes, one set each, fuse; 1 + 1 = 2 sets; two sets is diploid | `quantity + count`, `structural claims` |
| T27 | `inherit:m45467-80` Fertilization of an abnormal diploid egg with a normal haploid sperm yields a triploid zygote | `inherit:m45467-79`, `inherit:m45466-5`, `inherit:m45466-3` | set addition: diploid egg (2) + haploid sperm (1) = 3 sets, triploid | `quantity + count` |
| T28 | `inherit:m45467-83` Triploid animals are sterile | `inherit:m45467-80`, `inherit:m45467-84`, `inherit:m45466-8` | parity then necessity: 3 is odd, meiosis cannot proceed with an odd number of sets, sexual reproduction needs meiosis, so triploids are sterile | `quantity + count`, `necessity` |
| T29 | `inherit:m45466-92` 23 pairs give over eight million (2^23) possible alignments | `inherit:m45466-89`, `inherit:m45466-86`, `inherit:m45466-91` | product rule: 2 orientations per tetrad, tetrads independent, so 2^n (= 45466-90); n = 23 gives 8,388,608 > 8 million | `quantity + count`, `product (independence)` |
| T30 | `inherit:m45466-27` The nuclei resulting from meiosis are haploid | `inherit:m45466-26`, `inherit:m45466-33`, `inherit:m45466-118`, `inherit:m45466-23` | count plus transport by analogy: start at 2 sets, meiosis I halves to 1, meiosis II behaves like mitosis of a haploid cell and mitosis keeps the set number, so 1 | `quantity + count`, `transport` |
| T31 | `molbio:m45479-44` A three-nucleotide code gives 64 possible codons | `molbio:m45473-113`, `molbio:m45473-61`, `molbio:m45479-41` | counting: four bases (U swaps for T, so still four in RNA), three per codon, 4^3 = 64 | `quantity + count` |
| T32 | `molbio:m45479-93` More than one codon corresponds to a given amino acid | `molbio:m45479-44`, `molbio:m45479-46`, `molbio:m45479-92` | pigeonhole: 64 − 3 = 61 sense codons onto 20 amino acids, 61 > 20, so SOME amino acid has more than one codon | `quantity + count`, `pigeonhole` |
| T33 | `molbio:m45473-40` A DNA molecule contains as much adenine as thymine | `molbio:m45473-36`, `molbio:m45475-8` | bijection count: strands are complementary and A pairs only with T, so pairing is a bijection between A and T, so #A = #T | `quantity + count`, `structural claims` |
| T34 | `cell:m45429-46` Prokaryotic cells are smaller than eukaryotic cells | `cell:m45429-44`, `cell:m45429-45` | interval order: max prokaryote 5 µm < min eukaryote 10 µm | `quantity + count` |

**T21.** 
```lean
def T21 := .netYield (.lit S45438_57) (.lit S45438_56) (by norm_num : (4:ℤ) - 2 = 2)
```
**T22.** 
```lean
def T22 := .most (.lit S45439_74) (disjoint oxphos glycolysis tca) (by norm_num : (9:ℚ)/10 > 1/2)
```
**T23.** The premise about glucose being six-carbon comes from the respiration chapter.
```lean
def T23 := .conserve carbon (.lit S45453_37) (.lit S45453_4) (.lit S45438_53) (by norm_num : 6 / 1 = 6)
```
**T24.** A clean theorem: eight axioms in, the summary sentence out. Energy (112, 121) is left out because it is not a molecule.
```lean
def T24 := .ioDual (ins := [S45453_113, S45453_114]) (outs := [S45453_119, S45453_120]) ... (by decide)
```
**T25.** 
```lean
def T25 := .perSet (.lit S45455_17) (.lit S45455_18) (by norm_num : 46 / 2 = 23)
```
**T26.** 
```lean
def T26 := .unfold diploid_def (.addSets (.lit S45465_57) (.lit S45466_5) (by norm_num : 1 + 1 = 2))
```
**T27.** 
```lean
def T27 := .addSets (.lit S45467_79) (.lit S45466_5) (by norm_num : 2 + 1 = 3)
```
**T28.** 
```lean
def T28 := .necessity (.lit S45466_8) (.blocks (.lit S45467_84) (by decide : 3 % 2 = 1))
```
**T29.** Two textbook sentences (90 and 92) are theorems here.
```lean
def T29 := .product (.lit S45466_89) (.lit S45466_86) (.lit S45466_91) (by norm_num : 2^23 > 8000000)
```
**T30.** The `similar_to` sentence is doing real work: it is the licence for the transport step.
```lean
def T30 := .compose (.lit S45466_33) (.transport (.lit S45466_118) (.lit S45466_23))
```
**T31.** 
```lean
def T31 := .power (.replace (.lit S45473_113) (.lit S45473_61)) (.lit S45479_41) (by norm_num : 4^3 = 64)
```
**T32.** Only the existential follows. The sentence reads as 'every amino acid has more than one codon', which is false (methionine, tryptophan). The proof attempt finds the overclaim.
```lean
theorem T32 : ∃ aa, 1 < (codonsFor aa).card := Finset.exists_lt_card_fiber_of_mul_lt_card ...
```
**T33.** Chargaff's rule as a theorem of base pairing. Also yields 45473-9.
```lean
def T33 := .equalCount (.lit S45473_36) (.lit S45475_8)
```
**T34.** 
```lean
def T34 := .lessThan (.lit S45429_44) (.lit S45429_45) (by norm_num : (5:ℚ) < 10)
```

### C. Structure and location

| # | conclusion (textbook sentence) | premises | rule | needs |
|---|---|---|---|---|
| T35 | `photo:m45453-60` the light-dependent reactions and the Calvin cycle take place in chloroplasts | `photo:m45448-87`, `photo:m45448-88`, `photo:m45448-149`, `photo:m45448-95`, `photo:m45448-148`, `photo:m45448-146` | occurs_in lifted along part_of: both stages occur in parts of the chloroplast (thylakoid, stroma), so the process occurs in the chloroplast (also 45448-115, 45448-134) | `structural claims`, `occursInLift` |
| T36 | `cell:m45432-92` The nucleus directs the synthesis of ribosomes | `cell:m45432-114`, `cell:m45432-113` | occurs_in lift: ribosome assembly occurs in the nucleolus, the nucleolus is in the nucleus | `structural claims`, `occursInLift` |
| T37 | `repro:m45461-6` DNA is replicated during interphase. | `repro:m45461-22`, `repro:m45461-13` | occurs_during lift: replication occurs in S phase, S is part of interphase | `structural claims`, `occursInLift` |
| T38 | `body:m45537-20` The pancreas produces insulin | `body:m45537-197`, `body:m45537-196`, `body:m45537-192` | part_of transitivity then has_output lift: beta cell part_of islet part_of pancreas, beta cells make insulin (same route gives 45537-21 for glucagon) | `structural claims`, `partOfTrans`, `outputLift` |
| T39 | `photo:m45453-101` plants are capable of cellular respiration | `photo:m45453-103`, `cell:m45432-313` | capability via part: plants have mitochondria, mitochondria do cellular respiration | `structural claims`, `capableViaPart` |
| T40 | `photo:m45448-16` plants are autotrophs | `photo:m45448-21`, `photo:m45448-22` | is_a transitivity: plants are photoautotrophs, photoautotrophs are autotrophs | `structural claims`, `isATrans` |
| T41 | `photo:m45448-90` chlorophyll absorbs energy from sunlight | `photo:m45448-71`, `photo:m45448-72` | inheritance down is_a: chlorophyll is a pigment, pigments absorb light | `structural claims`, `inheritIsA` |
| T42 | `cell:m45429-56` All prokaryotes have ribosomes | `cell:m45429-11`, `cell:m45429-14` | inheritance down is_a: all cells have ribosomes, a prokaryotic cell is a cell | `structural claims`, `inheritIsA` |
| T43 | `cell:m45432-243` Photosynthetic bacteria do not have chloroplasts | `cell:m45429-16`, `cell:m45428-13`, `photo:m45448-64`, `cell:m45432-235` | lacks_part inheritance: prokaryotes lack membrane-bound organelles, bacteria are prokaryotes, a chloroplast is a membrane-bound organelle | `structural claims`, `lacksPartInherit`, `inheritIsA` |
| T44 | `photo:m45453-64` in photosynthetic prokaryotes photosynthesis occurs at plasma membrane infoldings | `photo:m45453-61`, `photo:m45453-63`, `photo:m45448-108` | colocation: photosynthesis requires chlorophyll, in prokaryotes chlorophyll sits on membrane infoldings (no chloroplast), so it occurs there; specialise to cyanobacteria gives 45453-65 | `structural claims`, `occursAtRequired`, `inheritIsA` |
| T45 | `molbio:m45476-16` In eukaryotes the mRNA transcript must be transported from the nucleus to the cytoplasm | `molbio:m45476-15`, `molbio:m45479-21`, `molbio:m45479-12`, `molbio:m45476-4` | colocation mismatch: mRNA is made in the nucleus, translation needs ribosomes, ribosomes are in the cytoplasm, so mRNA must move nucleus → cytoplasm (also 45476-41) | `structural claims`, `occursAtRequired`, `requiresTransport` |
| T46 | `molbio:m45473-35` Base pairing in DNA occurs between a purine and a pyrimidine | `molbio:m45473-36`, `molbio:m45473-37`, `molbio:m45473-114`, `molbio:m45473-115` | case split over a finite relation: A–T and G–C are the only pairs, A,G are purines, T,C are pyrimidines | `structural claims`, `inheritIsA` |

**T35.** Three separate textbook sentences say this; all three are theorems.
```lean
def T35 := .wholeFromStages [⟨S45448_87, .lift S45448_148 (.lit S45448_149)⟩, ⟨S45448_88, .lift S45448_146 (.lit S45448_95)⟩]
```
**T36.** 
```lean
def T36 := .occursInLift (.lit S45432_113) (.lit S45432_114)
```
**T37.** 
```lean
def T37 := .occursDuringLift (.lit S45461_13) (.lit S45461_22)
```
**T38.** 
```lean
def T38 := .outputLift (.partOfTrans (.lit S45537_196) (.lit S45537_192)) (.lit S45537_197)
```
**T39.** Generalize over photosynthetic organisms then gives 45453-70.
```lean
def T39 := .capableViaPart (.lit S45453_103) (.lit S45432_313)
```
**T40.** 
```lean
def T40 := .isATrans (.lit S45448_21) (.lit S45448_22)
```
**T41.** 
```lean
def T41 := .inheritIsA (.lit S45448_71) (.lit S45448_72)
```
**T42.** 
```lean
def T42 := .inheritIsA (.lit S45429_14) (.lit S45429_11)
```
**T43.** 
```lean
def T43 := .lacksInstance (.inheritIsA (.lit S45428_13) (.lit S45429_16)) chloroplast_isA_mbOrganelle
```
**T44.** Specialising to cyanobacteria needs 'cyanobacteria are prokaryotes', which NCBITaxon supplies, not the book.
```lean
def T44 := .occursAtRequired (.lit S45448_108) (.lit S45453_63)
```
**T45.** 
```lean
def T45 := .requiresTransport (.lit S45476_15) (.occursAtRequired (.lit S45479_12) (.lit S45479_21)) (.lit S45476_4)
```
**T46.** 
```lean
theorem T46 : ∀ x y, pairs x y → purine x ∧ pyrimidine y ∨ ... := by intro x y h; cases h <;> simp
```

### D. Physiology laws and paths

| # | conclusion (textbook sentence) | premises | rule | needs |
|---|---|---|---|---|
| T47 | `cell:m45434-75` In a hypertonic solution water leaves the cell | `cell:m45434-74`, `cell:m45434-118` | law instance: a hypertonic outside has less water; osmosis moves water from high to low; so water leaves (the same with 45434-69 gives 45434-70) | `lawInstance` |
| T48 | `cell:m45435-13` The concentration gradient of Na+ promotes its diffusion into the cell | `cell:m45435-12`, `cell:m45434-11` | law instance: Na+ is lower inside; passive transport goes high → low; so Na+ diffuses in (same with 45435-11 gives 45435-17 for K+) | `lawInstance` |
| T49 | `body:m45535-30` Bile and enzymes continue digestion in the small intestine | `body:m45535-28`, `body:m45535-114`, `body:m45535-105`, `body:m45535-116` | path then site: liver makes bile, bile goes to the duodenum, duodenum is part of the small intestine, bile salts help lipid digestion | `structural claims`, `pathCompose`, `inContext` |
| T50 | `body:m45536-3` The blood vessel network supplies cells, tissues and organs with oxygen and nutrients | `body:m45536-22`, `body:m45536-23` | path composition: O2 lung → blood, blood → tissues, so the vessel network supplies tissues with O2 | `structural claims`, `pathCompose` |
| T51 | `body:m45534-123` The human excretory system removes waste through the urinary system as urine | `body:m45534-133`, `body:m45534-197`, `body:m45534-235`, `body:m45534-234` | path composition: nephron makes urine → ureter → bladder → urethra → outside | `structural claims`, `pathCompose`, `outputLift` |
| T52 | `photo:m45448-11` humans depend on photosynthetic organisms for food and oxygen | `photo:m45448-27`, `photo:m45448-29`, `photo:m45448-26` | inheritance down is_a: humans are heterotrophs, heterotrophs depend on autotrophs for food (food part only; the oxygen part needs 45453-83 too) | `structural claims`, `inheritIsA` |

**T47.** 
```lean
def T47 := .instLaw osmosisLaw (.unfold (.lit S45434_74))
```
**T48.** 
```lean
def T48 := .instLaw diffusionLaw (.lit S45435_12)
```
**T49.** 
```lean
def T49 := .atSite (.partOf S45535_105) (.pathCompose (.lit S45535_28) (.lit S45535_114)) (.lit S45535_116)
```
**T50.** 
```lean
def T50 := .pathCompose (.lit S45536_22) (.lit S45536_23)
```
**T51.** 
```lean
def T51 := .pathCompose (.pathCompose (.lit S45534_197) (.lit S45534_235)) (.lit S45534_234)
```
**T52.** 
```lean
def T52 := .inheritIsA (.lit S45448_27) (.lit S45448_29)
```
## Reverse: sentences that look derivable but are not

Each of these has a proof with a hole. The hole is the missing premise. In ILP terms, the hole is the hypothesis to induce or to look up.

**G1. Organelle abundance tracks demand.** Three sentences share one hole:
`cell:m45432-155` (high-secretion cells have abundant Golgi), `cell:m45432-203` (muscle cells have many mitochondria),
`cell:m45432-189` (immature red cells are rich in ribosomes). The functions are in the files: Golgi packages proteins for export
(`cell:m45432-143`, `-153`), mitochondria make ATP (`cell:m45432-314`), ribosomes make protein (`cell:m45432-181`).
Missing: one general rule, `abundant(c, o) ← capable_of(o, F) ∧ highDemand(c, F)`, plus the demand facts (muscle uses a lot of ATP is only
partly there in `energy:m45438-18`; "immature red cells make hemoglobin" is absent). This is the best ILP target in the set:
one clause explains three textbook sentences.

**G2. "A tortoiseshell cat has to be female"** (`inherit:m45467-66`). Premises present: the coat needs two different X alleles
(`inherit:m45467-64`), one X is silenced at random per cell (`-58`, `-60`). Missing: "males have one X". That premise is not in
the files, and it is false in general: the files themselves say XXY individuals are male and inactivate the extra X (`-73`, `-74`, `-75`).
Fill the hole with the true premise and the proof gives "a tortoiseshell cat has two X chromosomes", not "is female".
The hole needs a context, `{karyotype := XY or XX}`, to make the book's sentence a theorem.

**G3. Endosymbiosis** (`cell:m45432-260`, `-261`, `-262`). Premises present: mitochondria and chloroplasts are bacteria-sized
(`cell:m45432-256`) and have their own DNA and ribosomes like bacteria (`-257`). These do not imply descent. The real shape is
abduction: the origin claim is a hypothesis and the shared features are its predictions. The schema already has the slot for this
(`Statement.predictedBy`); there is no derivation rule that runs from predictions back to the hypothesis, and there should not be one
without a rival (autogenous origin) to compare against.

**G4. Defective DNA repair causes skin cancer** (`molbio:m45475-117`, `-120`). The chain to mutation works: UV makes thymine dimers
(`molbio:m45475-113`), unrepaired dimers cause mutations (`-115`), excision repair removes dimers (`-141`); with `lossOfFunction`,
defective repair raises UV-induced mutation. The last step fails. The only cancer premise is "all cancers begin with a gene mutation"
(`repro:m45462-7`), which is the converse (mutation is necessary for cancer, not sufficient). Missing: "mutations in cell-cycle
genes cause cancer" (the sufficient direction) and "UV mutations can hit those genes". Also, `-116` (extreme sunlight sensitivity) is a
gene-by-environment interaction; the schema has no way to say "repair weakens the UV → mutation edge".

**G5. "Eukaryotic cells are 10 to 100 times the size of prokaryotic cells"** (`cell:m45429-66`). Premises present: prokaryotes are
0.1 to 5.0 µm (`cell:m45429-44`), eukaryotes 10 to 100 µm (`-45`). From those ranges the ratio is anywhere from 2 to 1000. So the
ordering (T34) is a theorem but the ratio is not. Missing: typical values (e.g. "a typical prokaryote is about 1 µm").

**G6. "A sugary drink stimulates the pancreas to produce insulin"** (`body:m45537-52`). One premise short of T1's shape:
`viaAmount (drink →+ blood glucose) (glucose →+ insulin, body:m45537-200)`. The first edge, "a sugary drink raises blood glucose",
is in no file. This is the smallest hole found: fill it and the derivation typechecks today.

**G7. "Villi and microvilli increase nutrient absorption efficiency"** (`body:m45535-103`). Present: they increase surface area
(`body:m45535-102`). Missing: "absorption rises with surface area" at tissue level. The nearest premise is about single cells
(`cell:m45429-52`, relative surface area limits uptake), so closing the hole needs `transport` from cell to tissue, or the law stated once
for any exchange surface (it would then also give `cell:m45432-200` cristae and `body:m45536-72` alveoli).

**G8. "Deer are heterotrophs"** (`photo:m45448-30`). Present: all animals are heterotrophs (`photo:m45448-28`). Missing: "deer
are animals". No textbook sentence says it, but NCBITaxon does. This hole is filled by the ontology, not the literature. Many
`inheritIsA` steps will be like this, which argues for letting ontology is_a edges act as premises with near-full belief.

## What this says about biolib

- The textbook is mostly axioms, but the theorems cluster: feedback loops, counting, and "where does this happen". Those are exactly
  the places a reader learns a *reason*, so they are the sentences worth proving.
- The existing chain rules are the right core. Most new rules are bridges that convert a structural fact into a signed edge
  (`inputPositive`, `outputPositive`, `viaGradient`, `viaProcess`) so the chain rules can run. Few new rule families are needed.
- `both` is used correctly by the body's own design (two hormones per variable), and incorrectly-but-silently by T11, where two
  chains share a cause. `sharedAxioms` only catches shared statements, not shared biology.
- Arithmetic is free in Lean. Thirteen derivations close with `norm_num` or `decide` once quantities are claims.
- Proving catches overclaims (T32, G2). That is a cheap quality check for any annotated corpus: if a sentence should be a theorem and
  the proof needs a false premise, the sentence is wrong or missing its context.

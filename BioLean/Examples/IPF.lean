import BioLean.Lib.IPF.Runs.R20260824T223623Z_4f7d1a

/-!
# IPF: one hypothesis-agent run, checked

Run `20260824T223623Z-4f7d1a` (Claude Opus 5, six IPF genes) proposed five hypotheses as chains
of steps. Each step is a statement in the generated module; `scripts/ipf/render.py` composed the
arms. Lean checks that each composition is well-formed and computes its sign; the opinion algebra
computes its strength. Here the kernel certifies what the side quest reported
(`docs/side-quest-ipf.md`).
-/

namespace BioLean.Examples.IPF

open BioLean BioLean.Lib.IPF.Runs.R20260824T223623Z_4f7d1a Derivation

/-- H1, MUC5B arm: the promoter variant raises MUC5B, MUC5B raises ER stress, ER stress drives
pulmonary fibrosis. The sign is computed by the chain rules, and the ascription checks it. -/
example : Derivation (.effect rs35705950 .pos (.disease pulmonaryFibrosis)) := h1c1a1

/-- H1, DSP arm. DSP comes out protective, so the risk allele must lower DSP: a step the run never
states. -/
example : Derivation (.effect DSP .neg (.disease pulmonaryFibrosis)) := h1c2a1

/-- H2, TERT arm. Composes only with the bridge I7 (telomere maintenance prevents short telomeres),
which the run left out, and its last link is an association (short telomeres go with IPF), read
as an effect by `fromAssoc` at a fifth of its strength. The H2 SFTPC claim has no route at all. -/
example : Derivation (.effect TERT .neg (.disease ipf)) := h2c1a1

/-! ### What the kernel certifies -/

/-- No arm is established at 0.8. The run rated H1 and H2 "medium". -/
theorem muc5bArm_unsupported : h1c1a1.verdict = .unsupported := by decide +kernel
theorem dspArm_unsupported : h1c2a1.verdict = .unsupported := by decide +kernel
theorem tertArm_unsupported : h2c1a1.verdict = .unsupported := by decide +kernel

/-- The MUC5B arm, the best-known IPF risk in the set, has belief 7/24. -/
theorem muc5bArm_belief : h1c1a1.opinion.belief = 7 / 24 := by decide +kernel

/-- The association discount is what sinks the TERT arm: belief 16/175, under a tenth. -/
theorem tertArm_belief : h2c1a1.opinion.belief = 16 / 175 := by decide +kernel

-- I4's only experimental evidence is a mouse study on a context-free claim: the taxon lint fails
-- (a lint, checked by `#guard` as in `Tests/Context.lean`).
#guard !I4.taxonConsistent

/-! ### Reports -/

#eval IO.println h1c1a1.report
#eval IO.println h2c1a1.report

end BioLean.Examples.IPF

import BioLean.Lib.IPF

/-!
# IPF: one hypothesis-agent run, checked

Run `20260824T223623Z-4f7d1a` (Claude Opus 5, six IPF genes) proposed five hypotheses as chains
of steps. Each step is a statement in `BioLean.Lib.IPF`. Here the steps are composed: Lean checks
that each composition is well-formed and computes its sign, the opinion algebra computes its
strength. Side quest write-up: `docs/side-quest-ipf.md`.
-/

namespace BioLean.Examples.IPF

open BioLean.Lib.IPF Derivation

/-- H1, MUC5B arm: the promoter variant raises MUC5B, MUC5B raises ER stress, ER stress drives
pulmonary fibrosis. -/
def muc5bArm : Derivation (.effect rs35705950 .pos (.disease pulmonaryFibrosis)) :=
  viaProcess (viaAmount (lit I1) (lit I2)) (lit I4)

/-- H1, DSP arm. The sign is computed, not stated: DSP protects. So the risk allele must lower DSP,
a step the run never states. -/
def dspArm : Derivation (.effect DSP .neg (.disease pulmonaryFibrosis)) :=
  viaProcess (lit I3) (lit I5)

/-- H2, TERT arm. Composes only with the bridge statement I7 (telomere maintenance prevents short
telomeres), which the run left out. Again the sign is computed: TERT protects. -/
def tertArm : Derivation (.effect TERT .neg (.disease ipf)) :=
  viaProcess (lit I6) (viaPhenotype (lit I7) (lit I8))

/-- H2, SFTPC arm. Reuses H1's I4: the run never links ER stress to disease inside H2. -/
def sftpcArm : Derivation (.effect sftpcBrichos .pos (.disease pulmonaryFibrosis)) :=
  viaProcess (lit I9) (lit I4)

/-! ### What the kernel certifies -/

/-- No arm is established at 0.8. The run rated H1 and H2 "medium". -/
theorem muc5bArm_unsupported : muc5bArm.verdict = .unsupported := by decide +kernel
theorem dspArm_unsupported : dspArm.verdict = .unsupported := by decide +kernel
theorem tertArm_unsupported : tertArm.verdict = .unsupported := by decide +kernel

/-- The MUC5B arm, the best-known IPF risk in the set, is the weakest composed arm: belief 1/4. -/
theorem muc5bArm_belief : muc5bArm.opinion.belief = 1 / 4 := by decide +kernel

/-- Nothing the run cited states the SFTPC step, so the arm carries no belief at all. -/
theorem sftpcArm_vacuous : sftpcArm.opinion.belief = 0 := by decide +kernel

-- I4's only evidence is a mouse study on a context-free claim: the taxon lint fails (a lint,
-- checked by `#guard` as in `Tests/Context.lean`).
#guard !I4.taxonConsistent
#guard (statements.filter (!·.taxonConsistent)).map (·.id) == ["I4"]

/-! ### Reports -/

#eval IO.println muc5bArm.report
#eval IO.println dspArm.report
#eval IO.println tertArm.report
#eval IO.println sftpcArm.report
#eval IO.println (Derivation.lit I10).report
#eval statements.map fun s => (s.id, s.opinion)

end BioLean.Examples.IPF

import BioLean.Lib.Textbook

/-!
# Textbook sentences as theorems

The derivations in `BioLean.Lib.Textbook` were all blocked before relational claims existed
(`docs/textbook-derivations.md`). Each is now a term the kernel checks.
-/

namespace BioLean.Textbook
open Derivation

theorem gonads_produce_steroids : Established (.rel .produces gonad steroidHormone) (7/10) :=
  ⟨gonad_produces_steroid, by decide +kernel⟩

theorem glycolysis_occurs_in_cell : Established (.rel .occursIn glycolysis cell) (7/10) :=
  ⟨glycolysis_in_cell, by decide +kernel⟩

theorem hepatocytes_have_nuclei : Established (.rel .hasPart hepatocyte nucleus) (7/10) :=
  ⟨hepatocyte_has_nucleus, by decide +kernel⟩

/-- A text-mined "heterocysts contain a nucleus" against the inherited negation: disbelief wins. -/
theorem heterocyst_nucleus_disbelieved :
    1/2 < (clash (.lit S_heterocyst_nucleus_mined) heterocyst_no_nucleus).disbelief := by
  decide +kernel

-- Reports
#eval IO.println gonad_produces_steroid.report
#eval IO.println glycolysis_in_cell.report
#eval IO.println asc_colon_in_large_intestine.report
#eval IO.println heterocyst_no_nucleus.report
#eval IO.println s!"clash: {clash (.lit S_heterocyst_nucleus_mined) heterocyst_no_nucleus}"

end BioLean.Textbook

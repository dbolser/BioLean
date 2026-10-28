import BioLean.Claim

/-!
# Tests pinning the RO axioms BioLean relies on

If a future RO release drops or changes one of these, the build fails here rather than a
biological derivation silently changing meaning. Blocked chains must stay blocked.
-/

namespace BioLean.RO.Tests
open Rel

-- chains the textbook derivations use
example : chainOK occursIn.flip hasOutput produces = true := by decide        -- row 139: produces
example : chainOK occursIn partOf occursIn = true := by decide               -- occurs_in lifts along part_of
example : chainOK partOf occursIn occursIn = true := by decide
example : chainOK partOf partOf partOf = true := by decide                   -- transitivity
example : chainOK isA isA isA = true := by decide
example : chainOK isA hasPart hasPart = true := by decide                    -- subclass inherits
example : chainOK hasPart isA hasPart = true := by decide                    -- relation to subclass
example : chainOK isA isA.flip isA.flip = false := by decide                 -- the class hierarchy does not inherit itself (closure search found this)
example : chainOK isA.flip isA isA.flip = false := by decide
example : chainOK partOf precededBy precededBy = true := by decide           -- row 1

-- declared inverses (data only; there is no relInv derivation rule, see Derivation.lean)
example : inverseOK partOf hasPart = true := by decide
example : inverseOK occursIn occursIn.flip = true := by decide

-- blocked: faithful imports of RO axioms judged wrong (docs/m1-checks.md)
example : chainOK ⟨.ro, 2224, false⟩ ⟨.ro, 2230, false⟩ ⟨.ro, 2087, false⟩ = false := by decide  -- starts_with ∘ ends_with ⊑ immediately_preceded_by (blocked)
example : chainsBlocked.contains ([⟨.ro, 2224, false⟩, ⟨.ro, 2230, false⟩], ⟨.ro, 2087, false⟩) = true := by decide
example : chainOK locatedIn locatedIn.flip ⟨.ro, 2379, false⟩ = false := by decide             -- located_in ∘ inv ⊑ spatially_coextensive
example : chainOK ⟨.ro, 2630, false⟩ ⟨.ro, 2630, false⟩ ⟨.ro, 2409, false⟩ = false := by decide -- neg ∘ neg ⊑ indirectly neg
example : chainOK hasOutput hasInput ⟨.ro, 2413, false⟩ = false := by decide                     -- has_output ∘ has_input ⊑ provides_input_for
example : (chainsBlocked.length, chains.length) = (38, 126) := by decide +kernel

-- domain and range typing
example : partOf.accepts .anatomy .anatomy = true := by decide
example : occursIn.accepts .process .component = true := by decide
example : occursIn.accepts .anatomy .process = false := by decide    -- a thing does not occur in a process
example : hasOutput.accepts .process .chemical = true := by decide
example : hasInput.accepts .chemical .process = false := by decide

end BioLean.RO.Tests

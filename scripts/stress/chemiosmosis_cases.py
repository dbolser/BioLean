"""Program 09: write data/stress/09/cases.tsv, the chemiosmosis stress set (CH-01 to CH-49).

Every `observed` cell was read off a run on 2026-10-30: `lake env lean
BioLean/Stress/ChemiosmosisReal.lean` (exit 0; the theorems and #guards named in `test` pass) and
`python3 scripts/stress/chemiosmosis_run.py` (data/stress/09/run_output.txt; it agrees with the
Lean tables on all 40 printed cells, see chemiosmosis_crosscheck.py). Numbers are truncated to
three decimals, as Lean prints them. C = chemiosmosis (Mitchell), S = chemical intermediate
(Slater), W = localised coupling (Williams), G = conformational (Green), M = murburn (Manoj).
Single entry: each item on the one rival it bears on. Dual entry: the 7 discriminating
experiments also refute S (the example's convention). Experiments weigh 1/2, reviews 3/5,
hypotheses and an advocate's own review 0.

    python3 scripts/stress/chemiosmosis_cases.py
"""
import csv
import os

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "data/stress/09/cases.tsv")
LEAN = "BioLean/Stress/ChemiosmosisReal.lean"
PROTO = "BioLean.Proto.ChemiosmosisReal"
NOBEL = "https://www.nobelprize.org/prizes/chemistry/1978/ceremony-speech/"

C_CLAIM = ("C: GO:0022904 respiratory electron transport chain ->+ GO:0006119 oxidative phosphorylation, "
           "via amount of CHEBI:15378 hydron. S: same, via amount of BLN:C~I (no ontology id).")

# id, title, probes, input, correct, observed, mark, test, source, synthetic
CASES = [
    ("CH-01", "M2 exit claim 1: contested in 1965", "Rivalry plus opinionAt on the real record cut at 1965",
     C_CLAIM + " Single entry. C: Mitchell 1961 (hypothesis), Neumann & Jagendorf 1964, Mitchell & Moyle 1965 x2. S: Slater 1953 "
     "(hypothesis), Pinchot 1960 and 1962, Griffiths & Chaplain 1962, Boyer 1962, Lehninger & Wadkins 1962 (review 3/5), Peter 1963; "
     "against S: Mitchell RA 1964, Kreil & Boyer 1964.",
     "Both contested: the dispute was live. Harold 2001 abstract: 'an intense controversy that lasted for 15 years'; Ernster 1978 "
     "speech: the theory was 'received with reservation'.",
     "C b=0.486 d=0.351 contested; S b=0.520 d=0.400 contested. Dual entry also contested. No single item, left out, flips it in "
     "single entry. In dual entry it rests on Lehninger 1962 (direction from memory). Contested in 50 of 72 encodings.",
     "PASS", "single_1965, dual_1965, #guard looFlips Enc.single 1965 = []",
     "PMID:13771349 PMID:14211549 PMID:4222981 PMID:5870319 PMID:13111237 PMID:16590695 PMID:13943645 PMID:13901866 "
     "PMID:14014715 PMID:14463786 PMID:13942705 PMID:5871845 PMID:5332854 PMID:11536297 " + NOBEL, "no"),
    ("CH-02", "M2 exit claim 2: chemiosmosis established by 1974", "Whether the real record reaches belief 4/5 under the rivalry",
     "Record cut at 1974, single entry. C: 13 experiments for (incl. Jagendorf & Uribe 1966, Reid 1966, Mitchell & Moyle 1967 x2, "
     "Hinkle 1971, Oesterhelt 1973, Racker & Stoeckenius 1974), 2 against (Chance & Mela 1966, Tager 1966; directions from memory). "
     "S: 6 experiments and 1 review for, 2 against.",
     "Established by the mid to late 1970s, so 1974 is early. Ernster 1978: the basic postulates are 'generally regarded as "
     "experimentally proven'. Manoj 2019 abstract: 'Since mid-1970s' chemiosmosis was the accepted explanation.",
     "C b=0.702 d=0.243 unsupported (d = 9/37, 1/148 under tau = 1/4). Dual entry b=0.767 d=0.173 unsupported. Single entry: 15 items, "
     "each left out alone, make C contested. The FAIL rests on directions from memory: in dual entry, leaving out Chance & Mela 1966 "
     "or Tager 1966 (either one) makes C established in every year 1974 to 2025; in single entry, leaving out all three of Chance & "
     "Mela, Tager and Lehninger 1962 does (1973 to 2025). S is never refuted in any of these.",
     "FAIL", "single_1974, single_1974_disbelief, dual_1974, #guard looFlips Enc.single 1974, #guard looFlips Enc.dualEntry 1974, "
     "#guard yearsWhere { Enc.dualEntry with drop := [5970146] }.two 0 .established",
     "PMID:5220864 PMID:5970114 PMID:16742541 PMID:4330063 PMID:4517939 PMID:4272126 PMID:5970146 PMID:4381909 PMID:31622585 " + NOBEL,
     "no"),
    ("CH-03", "M2 exit claim 3: Slater refuted by 1974", "Whether exclusion turns established C into refuted S",
     "As CH-02; the verdict read off S.",
     "Abandoned by the late 1970s. Ernster 1978: for the chemical intermediates 'no experimental evidence could be obtained'.",
     "1974 S b=0.505 d=0.426 contested (dual b=0.378 d=0.571 contested). Proved: S is not refuted in any year, single or dual.",
     "FAIL", "single_1974, single_S_never_refuted, dual_S_never_refuted", NOBEL + " PMID:23104597", "no"),
    ("CH-04", "Year of the flip, single entry", "Whether C is ever established, 1950 to 2025", "Record, single entry, every year.",
     "Established by the late 1970s and stays so (Harold 2001 abstract: 'generally accepted').",
     "Never, proved for every year. Best year 1977 at b=0.750; 0.719 from 1978; 0.735 from 2020 (Silva 2020).",
     "FAIL", "single_never_established, #guard cells Enc.single.two 1977 and 2020", "PMID:11536297", "no"),
    ("CH-05", "Dual entry (the example's convention)", "Double counting as a lever",
     "Record; 7 discriminating experiments (PMIDs 5870319, 5220864, 5970114, 16742541, 4272126, 237916, 992038) also entered as "
     "refutations of S.",
     "Established by about 1977 and stays established; S refuted.",
     "C established in 1977 only (b=0.819 d=0.133); unsupported in 1978 and every later year (proved); 2020 b=0.796, 0.004 under "
     "4/5. S contested every year from 1964; never refuted (proved). Without Chance & Mela 1966 or Tager 1966 (memory): "
     "established 1974 to 2025.",
     "FAIL", "dual_1977, dual_1978, dual_not_established_from_1978, dual_S_never_refuted, #guard cells Enc.dualEntry.two 2020",
     "PMID:670292 PMID:237916 PMID:992038", "no"),
    ("CH-06", "One claim, no rivals", "The 2026-10-26 script's encoding on real data (STATUS learned #2)",
     "C's items plus every S item with its polarity flipped, on one statement.", "Established.",
     "Never established (proved via Statement.forall_opinionAt); contested 1964 to 2025; 2020 b=0.626 d=0.343.",
     "FAIL", "one_claim_never_established, #guard cell (oneClaim.opinionAt 2020)",
     "scripts/case_studies/chemiosmotic_timeline.py PMID:11536297", "no"),
    ("CH-07", "Leave one out on the example's six real papers", "Robustness of Examples.Chemiosmosis.real_settled_1974",
     "realCoupling: PMIDs 13771349, 13111237, 5220864, 16742541, 4330063, 4272126; each experiment on both rivals.",
     "Established and refuted by about 1974, and not resting on any one paper.",
     "Unperturbed C b=4/5 exactly. Leave out any one of the four experiments: C b=0.750, unsupported. In 1965 C is unsupported "
     "(two weightless hypotheses).",
     "FAIL", "example_real_1974_belief, example_real_loo", "PMID:5220864 PMID:16742541 PMID:4330063 PMID:4272126", "no"),
    ("CH-08", "Refuted with no evidence against it (1962, 1963)", "Rivalry passing disbelief to an untested rival",
     "Rivalry [C, S] at 1963. C: Mitchell 1961 only (hypothesis). S: 5 experiments and the Lehninger 1962 review.",
     "C untested, so unsupported (Prebble 2001 abstract: 'lacked any experimental support'). S not established either: no "
     "intermediate was confirmed (Ernster 1978), and the phosphohistidine was reassigned in 1964.",
     "C b=0 d=0.866 refuted; S b=0.866 established, in 1962 and 1963.",
     "FAIL", "single_1963_refuted, #guard yearsWhere Enc.single.two 0 .refuted = [1962, 1963]",
     "PMID:11859886 PMID:5871845 " + NOBEL, "no"),
    ("CH-09", "Own evidence says established; the rivalry says no", "Rivalry.belief_le in practice",
     "C alone at 1974, against C under Rivalry [C, S].", "Established.",
     "C alone b=13/16, established. Under the rivalry 0.702, unsupported, because S keeps its own b=5/7 from reports never confirmed.",
     "FAIL", "own_1974, own_S_1974, single_1974", "BioLean/Rivalry.lean", "no"),
    ("CH-10", "Superseded phosphohistidine reports still vote", "Supersession (option D)",
     "Boyer 1962 (PMID 14014715), Peter 1963 (PMID 13942705) for S; Mitchell RA 1964 and Kreil & Boyer 1964 assign the "
     "phosphohistidine to succinate thiokinase (GO:0004775 succinate-CoA ligase (ADP-forming) activity).",
     "From 1964 the two reports no longer support C~I (titles of PMIDs 5871845, 5332854; Allchin 2002).",
     "Both still count in 2020. Proto D1, retiring them from 1964: 1974 C 0.728, still unsupported.",
     "FAIL", "phospho_still_counts; " + PROTO + ".phospho_single_1974",
     "PMID:14014715 PMID:13942705 PMID:5871845 PMID:5332854 PMID:12068893", "no"),
    ("CH-11", "Refuting an instance, not the hypothesis", "Claim granularity (option E)",
     "The four CH-10 items; narrower claim 'phosphohistidine is C~I' (CHEBI:18847 or CHEBI:19855; isomer UNVERIFIED).",
     "The 1964 papers cancel Boyer's items; they add no disbelief to C~I in general.",
     "No rule links 'm is_a C~I' to S, so the 1964 papers can only refute S. Proto D1, retiring reports and refutations together: "
     "1974 C contested (b=0.604 d=0.348).",
     "INEXPRESSIBLE", PROTO + ".phosphoBoth_single_1974, #guard cells (supRiv phosphoBoth Enc.single.two 1974)",
     "PMID:5871845 PMID:5332854", "no"),
    ("CH-12", "Unreplicated reports never retire", "Cumulative fusion never forgets",
     "Pinchot 1960 and 1962; Griffiths & Chaplain 1962; Painter & Hunter 1970 (abstract: 'may represent the type reaction'); "
     "Griffiths 1976 (abstract: 'analogous to those of substrate-level phosphorylation').",
     "None became accepted: Ernster 1978, 'no experimental evidence could be obtained'. I found no dated refutation of these five.",
     "S's own belief b=0.739 in 2020; S contested every year from 1964 (proved). Proto N (forgetting: each item's weight "
     "halves every 5, 10 or 20 years) does not fix it: S is never refuted, and C is never established in single entry, "
     "because C's own evidence fades too (h=10, 2020: C b=0.621, S b=0.083, both unsupported).",
     "FAIL", "single_S_contested_from_1964, #guard cell ((Enc.single.stmt .S).opinionAt 2020); " + PROTO + ".forget10_1974, "
     "#guard [5, 10, 20].all fun h => forgetYears",
     "PMID:16590695 PMID:13943645 PMID:13901866 PMID:5507209 PMID:138419 " + NOBEL, "no"),
    ("CH-13", "Reinterpretation over time (X_E)", "A polarity that changes with the year",
     "Hind & Jagendorf 1963 (PMID 16591093), 'Separation of light and dark stages in photophosphorylation'; GO:0009777.",
     "Neutral in 1963; support for proton coupling once X_E was read as the pH gradient (UNVERIFIED, memory).",
     "Polarity has two values, fixed for all years (pinned).",
     "INEXPRESSIBLE", "polarity_two_valued", "PMID:16591093 PMID:5220864", "no"),
    ("CH-14", "Neutral evidence (Boyer 1973 binding change)", "No neutral polarity (option F)",
     "Boyer, Cross & Momsen 1973 (PMID 4517936); Nagle & Dilley 1986 (PMID 2422160), a constraint on localised models, not a vote.",
     "Recorded, but no vote on gradient against intermediate (abstracts).",
     "Cannot be entered. Kept in a side list (neutralItems, 4 items). Proto F2: a neutral item would fuse as vacuous, which the "
     "core proves changes nothing (fuse_vacuous).",
     "INEXPRESSIBLE", "polarity_two_valued; " + PROTO + " F2 example, #guard neutralItems.length = 4",
     "PMID:4517936 PMID:2422160 SEPIO:0000009", "no"),
    ("CH-15", "Reviews by a theory's own advocate", "Evidence kind is curation",
     "Mitchell 1966 Biol Rev (PMID 5329743), Slater 1967 (PMID 4293928, direction memory), Mitchell 1979 Science (PMID 388618).",
     "An advocate's review restates the advocate's evidence and adds none (design.md gap 1).",
     "At face value (review 3/5) 1974 C b=0.674 d=0.279 contested; as hypothesis (baseline) 0.702 unsupported. No rule decides.",
     "FAIL", "face_1974, #guard cells Enc.faceValue.two 1974", "PMID:5329743 PMID:4293928 PMID:388618", "no"),
    ("CH-16", "A survey review outweighs any one experiment", "Review weight 3/5 against experiment 1/2",
     "Lehninger & Wadkins 1962 Annu Rev Biochem (PMID 14463786) on S (direction memory).",
     "A review summarises; it is not new evidence.",
     "Dual entry: 1965 contested rests on it (drop it: C unsupported). Reviews x2: 1974 C contested in single entry.",
     "FAIL", "#guard looFlips Enc.dualEntry 1965 = [14463786], reviewDoubled_single_1974", "PMID:14463786", "no"),
    ("CH-17", "One lab's series counts as many votes", "Independence (option G)",
     "Mitchell lab 1965 to 1969: PMIDs 4222981, 5870319, 5970114, 16742541, 6048801, 5776240.",
     "Not independent: one lab, one method.",
     "Counted as 6 items. Proto G (one lab, one vote): 18 of C's 28 items kept; C contested every year 1965 to 2025, never "
     "established, also in dual entry.",
     "FAIL", PROTO + ": #guard (labRivalry Enc.single).rivals.map, #guard yearsWhere (labRivalry Enc.single)",
     "PMID:4222981 PMID:5870319 PMID:5970114 PMID:16742541 PMID:6048801 PMID:5776240", "no"),
    ("CH-18", "Double counting across rivals not flagged", "Rivalry docstring warning against the code",
     "Dual entry: 7 PMIDs on both C and S.", "Warn: the Rivalry docstring says this counts the item twice.",
     "Accepted without a warning; distinctEvidence works per statement only. Proto M lint flags the 7 PMIDs.",
     "SILENT", "dual_accepted; " + PROTO + ": #guard sharedPmids Enc.dualEntry.two", "BioLean/Rivalry.lean BioLean/Evidence.lean",
     "no"),
    ("CH-19", "Williams' localised coupling as a flat third rival, with its real record", "Third rival (task); flat exclusion",
     "Rivalry [C, S, W]. W: same claim via amount of (CHEBI:15378 located_in GO:0005743). 17 W items: hypotheses Williams 1961, "
     "1975, Kell 1979, Westerhoff 1984, Lee 2021; advocate reviews Williams 1978 x2 (weight 0); experiments for: Hitchens & Kell "
     "1982, 1983 (Rhodobacter capsulatus NCBITaxon:1061), Chiang & Dilley 1989, Renganathan 1991, Heberle 1994, Rieger 2014, Toth "
     "2020; against: van der Bend 1985 (experiment), Ferguson 1985 (review, no PMID, direction memory), Silverstein 2024 (review).",
     "Proton coupling stays accepted. Localised against bulk coupling was a live sub-dispute in the 1980s (van der Bend 1985 'a "
     "critical appraisal'). Today it reads as a refinement: Rieger 2014 'necessitates a modification' of Mitchell; Williams 1978 "
     "says chemiosmosis 'is not so very different'. W should never be refuted without evidence.",
     "C contested 1965 to 1973 and 1982 to 2025 (2020 b=0.682 d=0.281), never established. W refuted 1962 to 1963, 1965, 1967 to "
     "1981 (1974 d=0.872, no data); unsupported 1982 to 1990; contested 1991 to 2025. Leave one out over W: only Hitchens & Kell 1982 "
     "or 1983 matter (without either, 1985 C unsupported and W refuted). Dropping Ferguson 1985: same verdicts. Dual entry: C "
     "established 1977 only. All weights x2: C established 1977 only; x1/2: never.",
     "FAIL", "w_refuted_1965, #guard yearsWhere Enc.single.three, #guard wLooFlips, #guard cells Enc.single.three 1974 and 2020",
     "PMID:13785509 PMID:237784 PMID:708723 PMID:23315 PMID:38839 PMID:6293600 PMID:6870853 PMID:6319178 PMID:2996506 "
     "DOI:10.1016/0304-4173(85)90005-9 PMID:16666959 PMID:1651763 PMID:8047144 PMID:24476986 PMID:31964824 PMID:34272427 "
     "PMID:39167050", "no"),
    ("CH-20", "A statement accepted as its own rival", "Rivalry well-formedness (option M)",
     "Rivalry [C, C'] with C' = C under another id.", "Rejected: one claim cannot exclude itself.",
     "Accepted; 1974 both contested (b=0.639 d=0.311). Proto M lint (sameClaim) flags it.",
     "FAIL", "self_rival_1974; " + PROTO + ": #guard sameClaim selfRival", "BioLean/Rivalry.lean", "yes"),
    ("CH-21", "Evidence that cannot tell bulk from local protons", "No parent claim (option J)",
     "Every C-supporting experiment also counted for W, with the full W record.",
     "These support proton coupling, the parent, not one child.",
     "Cannot be said. With shared counting C and W are contested in every year 1965 to 2025 (1974: C 0.412/0.555, W 0.624/0.328); "
     "S is unsupported in 1977 and 1982 to 1984, contested otherwise. (The research stage said all three were contested every year: "
     "not quite.)",
     "INEXPRESSIBLE", "#guard yearsWhere threeShared, #guard cells threeShared 1974", "PMID:8047144 PMID:2422160", "no"),
    ("CH-22", "Refuted before it was proposed (Green 1974)", "Rival scope (option I)",
     "Rivalry [C, S, W, G]; G: Green 1974 (PMID 4151654), hypothesis only; mediator BLN:conformational.",
     "No verdict before 1974. Prebble 2013 abstract: the conformational hypothesis was 'finally abandoned as an explanation of the "
     "overall process' (that is Boyer's; for Green's no checked source).",
     "G refuted in 1962, 1963, 1965 and every year from 1967, with no evidence.",
     "FAIL", "g_refuted_before_proposed, #guard yearsWhere Enc.single.four 3 .refuted", "PMID:4151654 PMID:23104597", "no"),
    ("CH-23", "Priority without evidence (Davies & Krebs 1952)", "Hypothesis weight 0",
     "Davies & Krebs 1952 (PMID 14925142) on C as a hypothesis.",
     "A proposal adds no belief. Prebble 1996 abstract: 'the essential elements of the theory were published 9 years earlier by "
     "Davies and Krebs'.",
     "Identical opinions in 1952, 1961, 1965, 1974, 2020 with or without it.",
     "PASS", "davies_krebs_weightless", "PMID:14925142 PMID:8842371", "no"),
    ("CH-24", "A theory with no data has no belief (Mitchell 1961)", "Derivation.opinionAt",
     "Derivation.lit C at 1961.", "Belief 0 (Prebble 2001: 'lacked any experimental support').", "Belief 0.",
     "PASS", "lit_1961", "PMID:13771349 PMID:11859886", "no"),
    ("CH-25", "Experiment weight x2 (1/2 to 2/3)", "Weight sensitivity (task)",
     "Record with the experiment pseudo-count doubled (1 to 2); 'all' variant also reviews 3/5 to 3/4.",
     "A factor of 2 on an uncalibrated weight should not flip the historical verdicts (1965 contested).",
     "Single entry: 1965 C unsupported (flip); C established in 1977 only. Dual entry: 1974 C established, S contested. All x2 with "
     "dual: C established in every year from 1974; S never refuted.",
     "FAIL", "expDoubled_single_1965, allDoubled_dual_1974, #guard @yearsWhere allDoubled Enc.dualEntry.two, #guard weightRow", "BioLean/Evidence.lean docs/programs/10a-evidence-weights.md", "no"),
    ("CH-26", "Experiment weight x1/2 (1/2 to 1/3)", "Weight sensitivity (task)", "Record with the experiment pseudo-count halved.",
     "As CH-02 and CH-03; and the verdicts should not flip on a factor of 2.",
     "Single: 1974 both contested (flip from unsupported); C never established (proved). Dual: 1974 C unsupported, S contested; C "
     "never established.",
     "FAIL", "expHalved_1974, expHalved_never_established, #guard weightRow", "BioLean/Evidence.lean", "no"),
    ("CH-27", "Down-weighting the unreplicated side", "Per-side weights (C x2, S x1/2)",
     "S experiments relabelled observational so one EvidenceModel can weigh them apart.",
     "S abandoned by the late 1970s.",
     "Single: 1974 C unsupported, established from 1976; S never refuted (proved). Dual: 1974 C established, S contested.",
     "FAIL", "sidesApart_single_1974, sidesApart_S_never_refuted, sidesApart_dual_1974, #guard weightRow", "BioLean/Evidence.lean", "no"),
    ("CH-28", "What it takes to pass the exit", "Retire every unreplicated report (option D) over a 72-encoding grid",
     "Proto D1: phosphohistidine reports retired from 1964, the other 5 from 1974; grid of entry x review rule x retirement x "
     "weights x memory items.",
     "Contested in 1965; C established and S refuted by the late 1970s.",
     "No retirement in the core. Proto D1 with dual entry: 1974 C established (0.803), S refuted (0.819), but 1965 C unsupported "
     "(0.585). The exit passes in 8 of 72 encodings; all 8 retire every report and drop the 6 memory-direction items. 1965 C "
     "contested in 50, 1974 C established in 35, 1974 S refuted in 18 (none without retirement; 2 with only the two "
     "sourced retirements, both dual entry with all weights x2 and the memory items dropped; 16 retiring all 7).",
     "INEXPRESSIBLE", PROTO + ".sup_dual_1974, sup_dual_1965, #guard grid.length, #guard [(gridParts.filter", "PMID:5871845 PMID:5332854", "no"),
    ("CH-29", "The textbook as canon (2013)", "Textbook evidence on the historical claim",
     "OpenStax how-cells-obtain-energy-m45439-73 'This flow of hydrogen ions across the membrane through ATP synthase is called "
     "chemiosmosis'; its R2 item (textbook 4/5, 2013) added to C.",
     "Established canon by 2013 (Harold 2001 agrees).", "C b=0.758 d=0.205 unsupported.",
     "FAIL", "textbook_2013", "how-cells-obtain-energy-m45439-73 PMID:11536297", "no"),
    ("CH-30", "The textbook claim and the historical claim never meet", "No rule over mediatedBy",
     "R2 m45439-37 'The potential energy of this gradient is used to generate ATP' (subject CHEBI:15378). C has subject GO:0022904.",
     "Same biology: linked, or flagged as agreeing.",
     "Different subjects; only lit, both and weaken take a mediatedBy claim, so nothing links them, and nothing says so.",
     "SILENT", "textbook_and_record_apart", "BioLean/Lib/TextbookClaimsR2/HowCellsObtainEnergy.lean", "no"),
    ("CH-31", "The gradient has no entity", "Target vocabulary",
     "m45439-36 'used to generate an electrochemical gradient across the inner mitochondrial membrane' (R2: GO:0022904 ->+ process "
     "GO:0010248); m45439-37 starts from CHEBI:15378 labelled 'H+ gradient'.",
     "One mediator: the transmembrane electrochemical proton gradient.",
     "-36 ends in a process, -37 starts from a chemical; viaAmount cannot chain them.",
     "INEXPRESSIBLE", "gradient_has_no_entity", "how-cells-obtain-energy-m45439-36 how-cells-obtain-energy-m45439-37 GO:0010248", "no"),
    ("CH-32", "Chloroplast, liposome and chromatophore evidence on a respiration claim", "Context transfer between systems",
     "Neumann & Jagendorf 1964, Jagendorf & Uribe 1966 (Spinacia oleracea NCBITaxon:3562); Racker & Stoeckenius 1974 (Halobacterium "
     "salinarum NCBITaxon:2242); Hitchens & Kell 1982, 1983 (NCBITaxon:1061); all on a respiratory-chain claim.",
     "They test the coupling principle the systems share; a respiration claim needs a stated transfer step from GO:0009777.",
     "Accepted with no transfer step. The taxonConsistent lint fails for spinach, but only because C has no taxon: rat fails too.",
     "SILENT", "#guard Statement.taxonConsistent", "PMID:14211549 PMID:5220864 PMID:4272126 PMID:6293600", "no"),
    ("CH-33", "Supports the whole, refutes a part (Wikstrom 1977)", "Part-of-mechanism evidence",
     "Wikstrom 1977 (PMID 15223): 'Proton pump coupled to cytochrome c oxidase in mitochondria'.",
     "Supports proton coupling; at odds with Mitchell's redox-loop scheme for complex IV (UNVERIFIED, memory).",
     "One polarity on C (supports); no claim for a part of the mechanism.",
     "INEXPRESSIBLE", "wikstrom_one_polarity", "PMID:15223", "no"),
    ("CH-34", "One late dissent un-establishes canon (Maloff 1978)", "Cumulative fusion after consensus",
     "Maloff 1978 (PMID 670292): microelectrodes read '10-20 mV, positive inside', 'independent of the metabolic state'.",
     "Chemiosmosis stayed accepted (Ernster 1978; Harold 2001).",
     "Dual: C 0.819 established in 1977; 0.782 unsupported in 1978 and every later year (proved).",
     "FAIL", "dual_1978, dual_not_established_from_1978", "PMID:670292 PMID:11536297", "no"),
    ("CH-35", "Order of evidence does not matter", "fuse_comm in practice", "C's items in reverse order.", "The same opinion.",
     "Identical in 2020 (fuse_comm proved; associativity is not stated in Belief.lean).",
     "PASS", "order_free", "BioLean/Belief.lean", "yes"),
    ("CH-36", "Eliminating a rival does not crown the other", "Rivalry.belief_le", "Any rivalry, on the 1974 record.",
     "C must earn its own belief: there were four hypotheses (Prebble 2013).", "Proved in the core, instantiated.",
     "PASS", "example using Rivalry.belief_le", "BioLean/Rivalry.lean PMID:23104597", "yes"),
    ("CH-37", "Swap each illustrative item for one real counterpart", "Option B",
     "protons65 -> PMID 4222981; intermediate65 -> PMID 14014715; reviews63 -> PMID 14463786 as a hypothesis.",
     "As CH-01 to CH-03.",
     "1965 and 1974 opinions equal the example's exactly; 1965 contested, 1974 established and refuted. Right, on a one-per-side "
     "sample.",
     "PASS", "swapped_same_as_toy, swapped_verdicts", "PMID:4222981 PMID:14014715 PMID:14463786", "no"),
    ("CH-38", "The same PMID twice counts once", "distinctEvidence", "Jagendorf & Uribe 1966 (PMID 5220864) twice on C.",
     "Counted once.", "Same 2020 belief as with one copy.", "PASS", "duplicate_counts_once", "BioLean/Evidence.lean", "yes"),
    ("CH-39", "Chemiosmosis on its own evidence", "Statement layer without rivalry", "C's 28 items alone, every year.",
     "Established by the mid-1970s and through the 1978 dissent (Harold 2001).",
     "Established 1973 to 2025 (1974 b=13/16; 2020 0.826).",
     "PASS", "#guard allYears.filter (fun y => ((Enc.single.stmt .C).opinionAt y)", "PMID:11536297", "no"),
    ("CH-40", "A rival that refines another", "Rivalry well-formedness (options J, M)",
     "W's mediator is CHEBI:15378 refined by located_in GO:0005743 (curie CHEBI:15378&RO:0001025=(GO:0005743)). The core's "
     "Entity.refineAxiom states it is_a hydron at 0.999, so W's claim implies C's.",
     "They cannot be exclusive: localised coupling is proton coupling (Williams 1978 'is not so very different'; Rieger 2014 "
     "'necessitates a modification').",
     "Rivalry accepts them; nothing checks for refinement between rivals, and no Derivation rule lifts a mediatedBy claim along is_a "
     "of its mediator. Proto M lint (refinesRival) flags (localised, chemiosmotic).",
     "SILENT", "w_refines_c; " + PROTO + ": #guard refinesRival Enc.single.three",
     "BioLean/Evidence.lean PMID:708723 PMID:24476986 GO:0005743", "no"),
    ("CH-41", "An undercutter, not a rebuttal (van der Bend 1985)", "Defeat of an inference (Pollock 1987)",
     "Van der Bend 1985 (PMID 2996506): liposomes with bacteriorhodopsin and ATP synthase and no specific contact reproduce the "
     "'localized' signatures but one: the effect of uncouplers at different levels of ATP synthase inhibition.",
     "It weakens the localised-coupling tests it reproduced; it does not show W false. It names the one test it did not "
     "reproduce as the one that 'may discriminate', which is the design of Hitchens & Kell 1983 (uncoupler with DCCD), so it does "
     "not weaken that item.",
     "Only as a refutation of W: it adds disbelief (W own 1985 b=0.444 d=0.333 without it, b=0.363 d=0.454 with it) and leaves "
     "every localised item at full weight. Leaving it out changes no verdict of the three rivals in 1985, 1994 or 2020 (#guard "
     "wLooFlips).",
     "INEXPRESSIBLE", "vdb_only_rebuts, #guard cell (({ Enc.single with dropKeys := [\"w13\"] }.stmt .W).opinionAt 1985), #guard cell ((Enc.single.stmt .W).opinionAt 1985)",
     "PMID:2996506 PMID:6293600 PMID:6870853 DOI:10.1207/s15516709cog1104_4", "no"),
    ("CH-42", "Coupling mode depends on a condition (Chiang & Dilley 1989)", "Context by refinement with Ctx.condition",
     "Subject GO:0009767 photosynthetic electron transport chain surrounded_by (RO:0002219) CHEBI:32588 potassium chloride, via bulk "
     "hydron; the same plus surrounded_by CHEBI:3312 calcium dichloride, via hydron located_in GO:0009535; target GO:0009777.",
     "Both hold, each in its condition. Abstract: 100 mM KCl gave 'delocalized proton gradient coupling'; adding 5 mM CaCl2 to the "
     "100 mM KCl gave 'a localized proton gradient coupling mode'. (The research stage said 'localised with 5 mM CaCl2, "
     "delocalised with 100 mM KCl': the localised arm is KCl plus CaCl2.)",
     "Stated as two subjects; they never fuse and never clash; each b=1/2. Limits: Ctx has one condition slot, so the second salt "
     "is a hand-made Entity.refine; nothing carries either to the mitochondrial claim (CH-32); the flat W encoding keeps only the "
     "CaCl2 half.",
     "PASS", "chiang_two_contexts", "PMID:16666959 CHEBI:32588 CHEBI:3312 GO:0009767 GO:0009535 BioLean/Context.lean", "no"),
    ("CH-43", "Modern dissent as a weightless theory (Nath 2017)", "Kind assignment for theory papers",
     "Nath 2017 (PMID 28882384) refutes C; hypothesis (baseline) or review 3/5.",
     "Chemiosmosis remains accepted. Silva 2020 abstract: such arguments are 'inconsistent with established experimental data'.",
     "Baseline: no change (2017 C b=0.719 d=0.239). As a review: 2017 C contested (b=0.677 d=0.283). The kind is the curator's call.",
     "PASS", "nath_kind_decides, #guard cells nathAsReview 2017", "PMID:28882384 PMID:32717593", "no"),
    ("CH-44", "An attack on an attacker (Silva 2020)", "Argument structure between papers",
     "Silva 2020 (PMID 32717593) rebuts Nath and murburn; entered as a review supporting C.",
     "It defeats two attacks on C; it is not fresh evidence for C.",
     "Counted as new support: C 2020 0.719 to 0.735 under the rivalry; own 0.813 to 0.826.",
     "INEXPRESSIBLE", "silva_counts_as_support, #guard cells { Enc.single with drop := [32717593] }.two 2020", "PMID:32717593 DOI:10.1016/0004-3702(94)00041-X",
     "no"),
    ("CH-45", "Murburn as a fourth rival (2019)", "Fringe rival with no accepted data",
     "Rivalry [C, S, W, M]; M: Manoj 2019 (PMID 31622585), hypothesis, mediator CHEBI:26523 reactive oxygen species.",
     "Disbelieved: Silva 2020 'inconsistent with established experimental data'.",
     "M refuted in 2019 (d=0.899), partly from S's undead belief. With C alone, M is still refuted (d=0.813) and C established "
     "(0.813). Under Proto I2 (scope by own evidence) M becomes unsupported: I2 breaks this case.",
     "PASS", "murburn_refuted_2019, #guard cells cVsM 2019; " + PROTO + ".scope_frees_murburn", "PMID:31622585 PMID:32717593", "no"),
    ("CH-46", "Late weightless proposal by the old rival (Slater 1985)", "Hypothesis weight 0 after consensus",
     "Slater, Berden & Herweijer 1985 (PMID 2861851), hypothesis, refutes C (title: the gradient is not an obligatory intermediate).",
     "No change: a proposal adds no data; consensus held (Ernster 1978).", "Opinions unchanged in 1985 and 2020.",
     "PASS", "slater85_weightless", "PMID:2861851 " + NOBEL, "no"),
    ("CH-47", "Recorded consensus as evidence (Nobel 1978)", "Canonical evidence kind (option K, M4)",
     "Ernster's 1978 presentation speech as a .textbook item (4/5, PMID 0) on C.",
     "Established from 1978: the basic postulates are 'generally regarded as experimentally proven'.",
     "Single entry: 1978 C b=0.758 d=0.205 unsupported. Dual entry: 0.815 established, and established in every year from 1977 "
     "(proved), through the 1978 dissent.",
     "FAIL", "nobel_single_1978, nobel_dual_from_1977", NOBEL, "no"),
    ("CH-48", "Verdicts on a knife edge", "Threshold sensitivity and margin (option L)",
     "Single entry, 1974: C d = 9/37. Vary tau and theta; measure the distance to the nearest threshold in every year.",
     "A verdict that flips with a small threshold change should be reported as borderline.",
     "No margin is reported. tau=1/5: 1974 C contested; theta=7/10: established from 1974; theta=3/4: established 1977 only. Proto "
     "L margin: 1974 at 1/148; single entry within 0.02 of a threshold in 47 years (1978 to 2019 all at 0.010), dual entry in 54.",
     "SILENT", "thresholds_1974, #guard allYears.filter (fun y => ((Rivalry.verdicts (Enc.single.two.asOf y) (θ := 3 / 4)); " + PROTO + ".margin_1974, #guard knifeEdge",
     "BioLean/Derivation.lean BioLean/Rivalry.lean", "no"),
    ("CH-49", "Same text in two venues (1966)", "Independence across venues; PMID 0 never deduplicated",
     "Mitchell 1966 Biol Rev (PMID 5329743) and the 1966 Glynn 'grey book' (no PMID; reprint PMID 22082452), same title.",
     "One argument, one vote (reprint abstract: the review known as the first 'Grey Book').",
     "At face value counted twice with no warning: 1974 C b 0.674 to 0.695. Two copies of one PMID-0 item both count. At baseline "
     "(an advocate's review weighs 0) no effect.",
     "SILENT", "grey_baseline_weightless, #guard (cells (withGrey Enc.faceValue .review) 1974)", "PMID:5329743 PMID:22082452", "no"),
]


# Root cause of each case (added at review, 2026-10-30), so the 49 marks read as a few causes.
CAUSES = {
    "undead": "unreplicated reports keep voting: nothing retires an item",
    "scope": "the rivalry gives disbelief to a rival with no evidence of its own",
    "hierarchy": "flat rivals where one refines the other",
    "weights": "the verdict moves with a weight or kind the curator picks",
    "independence": "one lab or one text counted as several items",
    "lint": "the core does not check that a rivalry is well formed",
    "argument": "the argument's structure cannot be stated (undercutter, neutral, part, reinterpretation)",
    "textbook": "the textbook and the record do not connect",
    "works": "the system does what it should",
}
CAUSE = {}
for ids, c in [
        ("02 03 04 05 06 09 10 12 27 28 29 34 47", "undead"), ("08 22 45", "scope"), ("19 21 40", "hierarchy"),
        ("07 15 16 25 26 43 48", "weights"), ("17 49", "independence"), ("18 20", "lint"),
        ("11 13 14 33 41 44", "argument"), ("30 31 32", "textbook"), ("01 23 24 35 36 37 38 39 42 46", "works")]:
    for i in ids.split():
        CAUSE["CH-" + i] = c


def main():
    assert len({c[0] for c in CASES}) == len(CASES) == 49
    assert set(CAUSE) == {c[0] for c in CASES} and set(CAUSE.values()) <= set(CAUSES)
    with open(OUT, "w", newline="") as f:
        w = csv.writer(f, delimiter="\t", lineterminator="\n")
        w.writerow(["id", "title", "probes", "input", "correct", "observed", "mark", "test", "source", "synthetic", "cause"])
        for c in CASES:
            w.writerow(c[:7] + (LEAN + ": " + c[7],) + c[8:] + (CAUSE[c[0]],))
    marks = {}
    for c in CASES:
        marks[c[6]] = marks.get(c[6], 0) + 1
    print(f"{len(CASES)} cases -> {OUT}: {marks}")
    for k, why in CAUSES.items():
        cs = [c for c in CASES if CAUSE[c[0]] == k]
        tally = {m: sum(c[6] == m for c in cs) for m in ("PASS", "FAIL", "SILENT", "INEXPRESSIBLE")}
        print(f"  {k:12} {len(cs):2}  " + " ".join(f"{m} {n}" for m, n in tally.items() if n) + f"  ({why})")
    missing = missing_tests()
    print("every test cited in cases.tsv is in the Lean file" if not missing else f"MISSING tests: {missing}")
    if missing:
        raise SystemExit(1)


def missing_tests():
    """Each cited theorem or def must exist, and each cited `#guard X` must begin some #guard line."""
    import re
    lean = open(os.path.join(ROOT, LEAN)).read()
    guards = [ln[len("#guard "):] for ln in lean.splitlines() if ln.startswith("#guard ")]
    names = set(re.findall(r"^(?:theorem|def)\s+([A-Za-z0-9_.]+)", lean, re.M))
    bad = []
    for c in CASES:
        for part in re.split(r"[;,]\s*(?![^()\[\]]*[)\]])", c[7].replace(PROTO + ":", "").replace(PROTO + ".", "")):
            part = part.strip()
            if not part or part.startswith("example") or part.endswith("F2 example"):
                continue
            if part.startswith("#guard"):
                body = part[len("#guard"):].strip()
                if not any(g.startswith(body) or g.startswith(" ".join(body.split()[:3])) for g in guards):
                    bad.append((c[0], part))
            elif part.split()[0] not in names:
                bad.append((c[0], part))
    return bad


if __name__ == "__main__":
    main()

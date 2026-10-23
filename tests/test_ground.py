from biolean.extract import ExtractionResult, Mention
from biolean.ground import ground, ground_results, uniprot_names

LOOKUP = {
    ("semaglutide", "chemical"): [("CHEBI:167574", "semaglutide", "exact_label")],
    ("glp-1r", "protein"): [("UniProt:P43220", "GLP1R", "exact_synonym")],
    ("insulin", "chemical"): [("CHEBI:145810", "insulin", "exact_label")],
    ("insulin", "protein"): [("UniProt:P01308", "INS", "exact_synonym")],
    ("obesity", "disease"): [("MONDO:0011122", "obesity disorder", "exact_synonym"),
                             ("MONDO:0019182", "obesity", "exact_label")],
    ("cd4", "protein"): [("UniProt:P01730", "CD4", "exact_synonym"), ("UniProt:Q00000", "X", "exact_synonym")],
}


def test_exact_case_insensitive():
    g = ground(Mention(mention=" Semaglutide ", kind="chemical"), LOOKUP)
    assert (g.curie, g.method, g.ambiguous) == ("CHEBI:167574", "exact_label", False)


def test_synonym():
    assert ground(Mention(mention="GLP-1R", kind="protein"), LOOKUP).curie == "UniProt:P43220"


def test_restricted_to_kind():
    assert ground(Mention(mention="insulin", kind="protein"), LOOKUP).curie == "UniProt:P01308"
    assert ground(Mention(mention="semaglutide", kind="protein"), LOOKUP) is None


def test_no_fuzzy_match():
    assert ground(Mention(mention="semaglutid", kind="chemical"), LOOKUP) is None


def test_label_beats_synonym():
    g = ground(Mention(mention="obesity", kind="disease"), LOOKUP)
    assert (g.curie, g.ambiguous) == ("MONDO:0019182", False)


def test_ambiguous_is_flagged():
    assert ground(Mention(mention="CD4", kind="protein"), LOOKUP).ambiguous


def test_ground_results_drops_misses_and_ambiguous():
    result = ExtractionResult.model_validate({"pmid": 1, "statements": [
        {"quote": q, "subject": {"mention": "semaglutide", "kind": "chemical"}, "relation": "increases_activity",
         "object": {"mention": m, "kind": "protein"}, "polarity": "supports", "evidence_kind": "rct",
         "species": "human", "hedged": False}
        for q, m in [("ok", "GLP-1R"), ("miss", "GIPR"), ("amb", "CD4")]
    ]})
    grounded, log = ground_results([result], {1: 2020}, LOOKUP)
    assert [g.quote for g in grounded] == ["ok"] and grounded[0].year == 2020
    assert log == ["PMID 1: ungrounded 'GIPR' (protein)", "PMID 1: ambiguous CD4"]


def test_uniprot_names():
    assert uniprot_names("Glucagon-like peptide 1 receptor (GLP-1 receptor) (GLP-1R) (EC 1.2.3.4)") == [
        "Glucagon-like peptide 1 receptor", "GLP-1 receptor", "GLP-1R"]
    assert uniprot_names("Lipoyl(octanoyl) transferase") == ["Lipoyl(octanoyl) transferase"]
    assert uniprot_names("Insulin [Cleaved into: Insulin B chain]") == ["Insulin"]

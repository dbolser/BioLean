import json

from biolean.corpus import strip_header, to_abstract

TEXT = (
    "PubMed article: Effects of semaglutide. (PMID:28266779).\n"
    "Authors: John Blundell; Graham Finlayson\n"
    "Journal: Diabetes, obesity & metabolism\n"
    "Publication year: 2017\n"
    "Abstract: AIM: The aim of this trial.\n"
    "RESULTS: Energy intake was lower."
)


def test_strip_header():
    assert strip_header(TEXT) == "AIM: The aim of this trial.\nRESULTS: Energy intake was lower."


def test_strip_header_without_abstract_label():
    assert strip_header("PubMed article: T (PMID:1).\nJournal: J\nBody text.") == "Body text."


def test_to_abstract():
    meta = json.dumps({"pmid": "28266779", "journal": "Diabetes, obesity & metabolism", "publication_year": "2017"})
    a = to_abstract("Effects of semaglutide.", TEXT, meta)
    assert (a.pmid, a.year, a.journal) == (28266779, 2017, "Diabetes, obesity & metabolism")
    assert a.abstract.startswith("AIM:")

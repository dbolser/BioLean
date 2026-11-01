"""Program 08, independent review: re-check every reference, quoted phrase and CURIE from scratch.

Read-only lookups (Europe PMC, Crossref, DataCite, OLS4). Raw JSON goes to a fresh directory,
/tmp/biolean-08/review/ (untrusted data: run with python3 -I, nothing from it is executed). It does
not reuse the cached downloads of gaps_refs.py or gaps_curies.py.

Writes data/stress/08/review_refs.tsv, review_quotes.tsv, review_curies.tsv and
review_textbook_quotes.tsv (every quoted phrase in the Lean doc comments, checked verbatim against
data/textbook/claims*/ and the downloaded abstracts and OLS4 definitions; a phrase that is not
found is a paraphrase of a claim reading, or an error to look at).

    python3 -I scripts/stress/gaps_review.py
"""

import json
import os
import re
import time
import urllib.parse
import urllib.request

ROOT = "/home/danbolser/Build/BioLean"
DL = "/tmp/biolean-08/review"
OUT = os.path.join(ROOT, "data", "stress", "08")
LEAN = ["BioLean/Stress/SchemaGaps.lean", "BioLean/Proto/SchemaGaps.lean"]

# key, id, expected first-author surname, expected year, expected title words
PMIDS = [
    ("Azevedo2009", "19226510", "Azevedo", "2009", "Equal numbers of neuronal and nonneuronal cells"),
    ("Bandaru", "32965812", "Bandaru", None, "Poikilocytosis"),
    ("Blattner1997", "9278503", "Blattner", "1997", "complete genome sequence of Escherichia coli K-12"),
    ("Cameron2001", "11406822", "Cameron", "2001", "Adult neurogenesis produces a large pool of new granule cells"),
    ("Centerwall1973", "4798734", "Centerwall", "1973", "Male tortoiseshell and calico"),
    ("Charkoudian2003", "12744548", "Charkoudian", "2003", "Skin blood flow in adult human thermoregulation"),
    ("Dorkenwald2024", "39358518", "Dorkenwald", "2024", "Neuronal wiring diagram of an adult brain"),
    ("Inada1996", "9133663", "Inada", "1996", "glucose-lactose diauxie"),
    ("Jaskelioff2011", "21113150", "Jaskelioff", "2011", "Telomerase reactivation reverses tissue degeneration in aged telomerase-deficient mice"),
    ("Kim1994", "7605428", "Kim", "1994", "Specific association of human telomerase activity with immortal cells and cancer"),
    ("Kumari2019", "31828242", "Kumari", "2019", "Vocal Cord-Carina Distance and Tracheal Length"),
    ("Lambeth2004", "15234968", "Lambeth", "2004", "two succinyl-CoA synthetases with different nucleotide specificities"),
    ("Liu2022", "36499153", "Liu", "2022", "Stomatal Closure in Response to Drought"),
    ("Lyon1961", "13764598", "Lyon", "1961", "Gene action in the X-chromosome of the mouse"),
    ("Mackman2007", "17556654", "Mackman", "2007", "extrinsic pathway of blood coagulation"),
    ("Morrison2019", "30256726", "Morrison", "2019", "Central Mechanisms for Thermoregulation"),
    ("Rapoport2007", "18046402", "Rapoport", "2007", "Protein translocation across the eukaryotic endoplasmic reticulum"),
    ("Sorrells2018", "29513649", "Sorrells", "2018", "Human hippocampal neurogenesis drops sharply"),
    ("Spalding2013", "23746839", "Spalding", "2013", "Dynamics of hippocampal neurogenesis in adult humans"),
    ("Urban2017", "28338959", "Urban", "2017", "Increase in leaf temperature opens stomata"),
    ("Cooper1968", "4866337", "Cooper", "1968", "Chromosome replication and the division cycle of Escherichia coli"),
    ("Hattori2000", "10830953", "Hattori", "2000", "The DNA sequence of human chromosome 21"),
]
DOIS = [("Josang2005", "crossref", "10.1016/j.ijar.2004.03.003", "J", "2005", "Multiplication and comultiplication of beliefs"),
        ("Josang2006", "datacite", "10.48550/arXiv.cs/0606029", "J", "2006", "Belief Calculus")]

# key, PMID, regex that must match the abstract, what the doc uses it for
QUOTES = [
    ("Azevedo2009", "19226510", r"86\.1\s*(±|\+/-)\s*8\.1\s*billion", "A09: 86.1 ± 8.1 billion neurons"),
    ("Bandaru", "32965812", r"6\.2\s*to\s*8\.2", "A01: 6.2 to 8.2 µm diameter"),
    ("Bandaru", "32965812", r"2\s*to\s*2\.5", "A02: 2 to 2.5 µm thick at the periphery"),
    ("Bandaru", "32965812", r"0\.8\s*to\s*1", "A02: 0.8 to 1 µm at the centre"),
    ("Blattner1997", "9278503", r"4,639,221", "A04: 4,639,221 bp"),
    ("Cameron2001", "11406822", r"9,?000", "A12: about 9,000 new cells a day, young adult rat"),
    ("Dorkenwald2024", "39358518", r"139,255", "A08: 139,255 neurons, adult fly brain"),
    ("Inada1996", "9133663", r"inducer exclusion", "C11, C12: inducer exclusion"),
    ("Inada1996", "9133663", r"lacI|IPTG", "C12: repressor inactivation abolishes glucose repression"),
    ("Jaskelioff2011", "21113150", r"neurodegeneration", "C04: reversed neurodegeneration"),
    ("Kim1994", "7605428", r"none of 50 normal somatic tissues", "C15: no telomerase in normal somatic tissue"),
    ("Kumari2019", "31828242", r"10\.14\s*±\s*2\.04", "A03: 10.14 ± 2.04 cm (men)"),
    ("Kumari2019", "31828242", r"9\.37\s*±\s*1\.28", "A03: 9.37 ± 1.28 cm (women)"),
    ("Lambeth2004", "15234968", r"GTP", "D03: GTP-forming succinyl-CoA synthetase"),
    ("Liu2022", "36499153", r"Stomatal closure is an efficient way", "C10: stomatal closure under drought"),
    ("Mackman2007", "17556654", r"endothelial", "C01: tissue factor on endothelial cells"),
    ("Morrison2019", "30256726", r"shivering", "D08: cold, shivering"),
    ("Morrison2019", "30256726", r"vasoconstriction", "D08: cold, vasoconstriction"),
    ("Charkoudian2003", "12744548", r"vasodilat", "D08: heat, vasodilation"),
    ("Rapoport2007", "18046402", r"plasma membrane", "D06: bacterial plasma membrane"),
    ("Sorrells2018", "29513649", r"undetectable|not detected", "A12: undetectable in adults (title; 'not detected' in the abstract)"),
    ("Hattori2000", "10830953", r"smallest human autosome", "D17: chromosome 21 is the smallest autosome"),
    ("Hattori2000", "10830953", r"127 known genes, 98 predicted genes", "D17: 225 genes on 21q"),
    ("Spalding2013", "23746839", r"700 new neurons", "A12: 700 new neurons a day"),
    ("Urban2017", "28338959", r"leaf temperature", "C09: heat opens stomata"),
]


def get(url, key):
    os.makedirs(DL, exist_ok=True)
    path = os.path.join(DL, re.sub(r"[^A-Za-z0-9_.-]", "_", key) + ".json")
    if not (os.path.exists(path) and os.path.getsize(path) > 0):
        req = urllib.request.Request(url, headers={"User-Agent": "BioLean-stress-08-review (read-only)",
                                                   "Accept": "application/json"})
        with urllib.request.urlopen(req, timeout=40) as r:
            data = r.read()
        with open(path, "wb") as f:
            f.write(data)
        time.sleep(0.25)
    return json.load(open(path))


def norm(s):
    return re.sub(r"[^a-z0-9]+", " ", (s or "").lower()).strip()


def epmc(pmid):
    q = urllib.parse.quote(f"EXT_ID:{pmid} AND SRC:MED")
    d = get(f"https://www.ebi.ac.uk/europepmc/webservices/rest/search?query={q}&format=json&resultType=core",
            "epmc_" + pmid)
    res = (d.get("resultList") or {}).get("result") or []
    return res[0] if res else None


def refs():
    rows = []
    for key, pmid, au, year, words in PMIDS:
        r = epmc(pmid)
        if not r:
            rows.append((key, f"PMID:{pmid}", "", "", "", "NOT FOUND"))
            continue
        title, y = r.get("title", ""), r.get("pubYear", "")
        first = (r.get("authorString") or "").split(",")[0]
        ok = (norm(words) in norm(title), norm(au)[:5] in norm(first), year is None or y == year)
        st = "checked" if all(ok) else f"MISMATCH title={ok[0]} author={ok[1]} year={ok[2]}"
        rows.append((key, f"PMID:{pmid}", y, first, title, st))
    for key, src, doi, au, year, words in DOIS:
        if src == "crossref":
            m = get("https://api.crossref.org/works/" + urllib.parse.quote(doi), "cr_" + doi).get("message") or {}
            title = (m.get("title") or [""])[0]
            y = str(((m.get("issued") or {}).get("date-parts") or [[""]])[0][0])
            first = ((m.get("author") or [{}])[0]).get("family", "")
        else:
            a = (get("https://api.datacite.org/dois/" + urllib.parse.quote(doi, safe=""), "dc_" + doi).get("data") or {}).get("attributes") or {}
            title = ((a.get("titles") or [{}])[0]).get("title", "")
            y = str(a.get("publicationYear", ""))
            c = (a.get("creators") or [{}])[0]
            first = c.get("familyName", "") or c.get("name", "")
        ok = (norm(words) in norm(title), first[:1] == au, y == year)
        rows.append((key, f"doi:{doi}", y, first, title, "checked" if all(ok) else f"MISMATCH {ok}"))
    with open(os.path.join(OUT, "review_refs.tsv"), "w") as f:
        f.write("key\tid\tyear\tfirst_author\ttitle\tstatus\n")
        for r in rows:
            f.write("\t".join(x.replace("\t", " ") for x in r) + "\n")
    return rows


def quotes():
    rows = []
    for key, pmid, pat, use in QUOTES:
        r = epmc(pmid) or {}
        ab = re.sub("<[^>]+>", "", r.get("abstractText") or "")
        sents = [s for s in re.split(r"(?<=[.;])\s+", ab) if re.search(pat, s, re.I)]
        rows.append((key, f"PMID:{pmid}", use, pat, "found" if sents else ("NO ABSTRACT" if not ab else "NOT FOUND"),
                     (sents[0] if sents else "")[:400]))
    with open(os.path.join(OUT, "review_quotes.tsv"), "w") as f:
        f.write("key\tid\tused_for\tpattern\tstatus\tsentence\n")
        for r in rows:
            f.write("\t".join(x.replace("\t", " ").replace("\n", " ") for x in r) + "\n")
    return rows


PREFIXES = "GO|CL|CHEBI|UBERON|NCBITaxon|PATO|PR|SO|HP|MONDO|PO|PECO|OBI|BLN|BIOLEAN"


def lean_curies():
    """CURIE -> labels written next to it in the Lean files (⟨"CURIE", "label"⟩), and library names."""
    found = {}
    for f in LEAN:
        txt = open(os.path.join(ROOT, f)).read()
        for m in re.finditer(rf'⟨"((?:{PREFIXES}):[A-Za-z0-9_]+)",\s*"([^"]*)"⟩', txt):
            found.setdefault(m.group(1), set()).add(m.group(2))
        for m in re.finditer(rf'"((?:{PREFIXES}):[A-Za-z0-9_]+)"', txt):
            found.setdefault(m.group(1), set())
        for m in re.finditer(rf'\be_({PREFIXES})_([A-Za-z0-9]+)\b', txt):
            found.setdefault(f"{m.group(1)}:{m.group(2)}", set())
    # curies inside curie strings, e.g. "GO:0000910&RO:0002162=(NCBITaxon:33208)"
    for f in LEAN:
        txt = open(os.path.join(ROOT, f)).read()
        for m in re.finditer(rf'\b((?:{PREFIXES}|RO|BFO):[A-Za-z0-9_]+)', txt):
            found.setdefault(m.group(1), set())
    return found


def ols_term(curie):
    pre = curie.split(":")[0]
    if pre in ("RO", "BFO"):
        iri = "http://purl.obolibrary.org/obo/" + curie.replace(":", "_")
        enc = urllib.parse.quote(urllib.parse.quote(iri, safe=""), safe="")
        try:
            d = get(f"https://www.ebi.ac.uk/ols4/api/ontologies/ro/properties/{enc}", "prop_" + curie)
        except Exception as e:  # noqa: BLE001
            return ("ERROR", str(e)[:60], "")
        return (d.get("label", ""), "obsolete" if d.get("is_obsolete") else "live", "")
    ont = pre.lower()
    try:
        d = get(f"https://www.ebi.ac.uk/ols4/api/ontologies/{ont}/terms?obo_id={urllib.parse.quote(curie)}",
                "term_" + curie)
    except Exception as e:  # noqa: BLE001
        return ("ERROR", str(e)[:60], "")
    ts = (d.get("_embedded") or {}).get("terms") or []
    if not ts:
        return ("", "NOT FOUND", "")
    t = ts[0]
    desc = (t.get("description") or [""])
    return (t.get("label", ""), "obsolete" if t.get("is_obsolete") else "live", (desc[0] if desc else "")[:200])


def curies():
    found = lean_curies()
    rows = []
    for c in sorted(found):
        if c.split(":")[0] in ("BLN", "BIOLEAN"):
            rows.append((c, "", "placeholder", "", ";".join(sorted(found[c])), ""))
            continue
        label, st, defn = ols_term(c)
        lean = sorted(found[c])
        # a Lean label agrees if it equals the OLS label, ignoring case
        agree = "" if not lean else ("yes" if any(norm(x) == norm(label) for x in lean) else "DIFFERS")
        rows.append((c, label, st, defn, ";".join(lean), agree))
    with open(os.path.join(OUT, "review_curies.tsv"), "w") as f:
        f.write("curie\tols_label\tstatus\tdefinition\tlean_label\tlabel_agrees\n")
        for r in rows:
            f.write("\t".join(x.replace("\t", " ").replace("\n", " ") for x in r) + "\n")
    return rows


def textbook_quotes():
    def nm(x):
        return re.sub(r"[^a-z0-9µ±]+", " ", (x or "").lower().replace("\u2019", "'")).strip()
    corpus = []
    for d in ("claims", "claims_m2", "claims_m3"):
        for f in sorted(os.listdir(os.path.join(ROOT, "data", "textbook", d))):
            if f.endswith(".json"):
                corpus += [nm(r.get("source", "")) for r in json.load(open(os.path.join(ROOT, "data", "textbook", d, f)))]
    for f in sorted(os.listdir(DL)):
        if f.endswith(".json"):
            corpus.append(nm(json.dumps(json.load(open(os.path.join(DL, f))), ensure_ascii=False)))
    big = " | ".join(corpus)
    rows = []
    for lf in LEAN:
        txt = open(os.path.join(ROOT, lf)).read()
        for block in re.findall(r"/-[!-](.*?)-/", txt, re.S):
            for m in re.finditer(r'"([^"]{12,}?)"', block.replace("\n", " ")):
                q = m.group(1)
                pieces = [x for x in re.split(r"\.\.\.|…", q) if len(nm(x).split()) >= 3]
                if not pieces:
                    continue
                ok = all(nm(x) in big for x in pieces)
                rows.append((os.path.basename(os.path.dirname(lf)), q, "verbatim" if ok else "not verbatim"))
    with open(os.path.join(OUT, "review_textbook_quotes.tsv"), "w") as f:
        f.write("file\tquoted\tstatus\n")
        for r in rows:
            f.write("\t".join(x.replace("\t", " ") for x in r) + "\n")
    return rows


def main():
    tq = textbook_quotes()
    print(f"quoted phrases in Lean comments: {len(tq)}, verbatim {sum(r[2] == 'verbatim' for r in tq)}")
    rr = refs()
    print(f"references: {len(rr)}, checked {sum(r[5] == 'checked' for r in rr)}")
    for r in rr:
        if r[5] != "checked":
            print("  ", r[0], r[1], r[5], r[2], r[3], r[4][:80])
    qq = quotes()
    print(f"quotes: {len(qq)}, found {sum(r[4] == 'found' for r in qq)}")
    for r in qq:
        if r[4] != "found":
            print("  ", r[0], r[3], r[4])
    cc = curies()
    print(f"curies: {len(cc)}, live {sum(r[2] == 'live' for r in cc)}, placeholders {sum(r[2] == 'placeholder' for r in cc)}, "
          f"other {sum(r[2] not in ('live', 'placeholder') for r in cc)}, label differs {sum(r[5] == 'DIFFERS' for r in cc)}")
    for r in cc:
        if r[2] not in ("live", "placeholder") or r[5] == "DIFFERS":
            print("  ", r[0], r[2], "OLS:", r[1], "| Lean:", r[4])


if __name__ == "__main__":
    main()

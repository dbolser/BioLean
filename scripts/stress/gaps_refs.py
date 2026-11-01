"""Check program 08 references on Europe PMC (PMIDs), Crossref (DOIs) and DataCite (arXiv DOIs). Read-only.

Raw JSON goes to /tmp/biolean-08/dl/refs/ (untrusted; run this with python3 -I).
Writes data/stress/08/references_checked.tsv: key, id, year, first author, title, status.

    python3 -I scripts/stress/gaps_refs.py            # check the list below
    python3 -I scripts/stress/gaps_refs.py search "query"
    python3 -I scripts/stress/gaps_refs.py abstract PMID REGEX
"""

import json
import os
import re
import sys
import time
import urllib.parse
import urllib.request

DL = "/tmp/biolean-08/dl/refs"
OUT = "/home/danbolser/Build/BioLean/data/stress/08/references_checked.tsv"

# key, kind, id, expected first-author surname, expected title words
REFS = [
    ("Azevedo2009", "pmid", "19226510", "Azevedo", "Equal numbers of neuronal and nonneuronal cells"),
    ("Dorkenwald2024", "pmid", "39358518", "Dorkenwald", "Neuronal wiring diagram of an adult brain"),
    ("Blattner1997", "pmid", "9278503", "Blattner", "complete genome sequence of Escherichia coli K-12"),
    ("Kumari2019", "pmid", "31828242", "Kumari", "Vocal Cord-Carina Distance and Tracheal Length"),
    ("Bandaru2026", "pmid", "32965812", "Bandaru", "Poikilocytosis"),
    ("Spalding2013", "pmid", "23746839", "Spalding", "Dynamics of hippocampal neurogenesis in adult humans"),
    ("Cameron2001", "pmid", "11406822", "Cameron", "Adult neurogenesis produces a large pool of new granule cells"),
    ("Sorrells2018", "pmid", "29513649", "Sorrells", "Human hippocampal neurogenesis drops sharply"),
    ("Lambeth2004", "pmid", "15234968", "Lambeth", "two succinyl-CoA synthetases with different nucleotide specificities"),
    ("Mackman2007", "pmid", "17556654", "Mackman", "extrinsic pathway of blood coagulation"),
    ("Jaskelioff2011", "pmid", "21113150", "Jaskelioff", "Telomerase reactivation reverses tissue degeneration"),
    ("Centerwall1973", "pmid", "4798734", "Centerwall", "Male tortoiseshell and calico"),
    ("Lyon1961", "pmid", "13764598", "Lyon", "Gene action in the X-chromosome of the mouse"),
    ("Urban2017", "pmid", "28338959", "Urban", "Increase in leaf temperature opens stomata"),
    ("Liu2022", "pmid", "36499153", "Liu", "Signaling Transduction of ABA, ROS, and Ca"),
    ("Inada1996", "pmid", "9133663", "Inada", "glucose-lactose diauxie"),
    ("Charkoudian2003", "pmid", "12744548", "Charkoudian", "Skin blood flow in adult human thermoregulation"),
    ("Morrison2019", "pmid", "30256726", "Morrison", "Central Mechanisms for Thermoregulation"),
    ("Rapoport2007", "pmid", "18046402", "Rapoport", "Protein translocation across the eukaryotic endoplasmic reticulum"),
    ("Kim1994", "pmid", "7605428", "Kim", "Specific association of human telomerase activity with immortal cells and cancer"),
    ("Hattori2000", "pmid", "10830953", "Hattori", "The DNA sequence of human chromosome 21"),  # added in review (D17)
    ("Josang2005", "doi", "10.1016/j.ijar.2004.03.003", "Jøsang", "Multiplication and comultiplication of beliefs"),
    ("Josang2006", "datacite", "10.48550/arXiv.cs/0606029", "Jøsang", "Belief Calculus"),
]


def get(url, key):
    os.makedirs(DL, exist_ok=True)
    path = os.path.join(DL, re.sub(r"[^A-Za-z0-9_.-]", "_", key) + ".json")
    if not (os.path.exists(path) and os.path.getsize(path) > 0):
        req = urllib.request.Request(url, headers={"User-Agent": "BioLean-stress-08 (read-only check)"})
        with urllib.request.urlopen(req, timeout=40) as r:
            data = r.read()
        with open(path, "wb") as f:
            f.write(data)
        time.sleep(0.3)
    return json.load(open(path))


def epmc(pmid):
    q = urllib.parse.quote(f"EXT_ID:{pmid} AND SRC:MED")
    d = get(f"https://www.ebi.ac.uk/europepmc/webservices/rest/search?query={q}&format=json&resultType=core", "pmid_" + pmid)
    res = (d.get("resultList") or {}).get("result") or []
    return res[0] if res else None


def datacite(doi):
    d = get("https://api.datacite.org/dois/" + urllib.parse.quote(doi, safe=""), "dc_" + doi)
    a = (d.get("data") or {}).get("attributes") or {}
    return a


def crossref(doi):
    d = get("https://api.crossref.org/works/" + urllib.parse.quote(doi), "doi_" + doi)
    return d.get("message") or {}


def norm(s):
    return re.sub(r"[^a-z0-9]+", " ", (s or "").lower()).strip()


def check():
    rows = []
    for key, kind, ident, au, words in REFS:
        try:
            if kind == "pmid":
                r = epmc(ident)
                if not r:
                    rows.append((key, f"PMID:{ident}", "", "", "", "NOT FOUND"))
                    continue
                title, year = r.get("title", ""), r.get("pubYear", "")
                first = (r.get("authorString") or "").split(",")[0]
                doi = r.get("doi", "")
            elif kind == "datacite":
                a = datacite(ident)
                title = ((a.get("titles") or [{}])[0]).get("title", "")
                year = str(a.get("publicationYear", ""))
                first = ((a.get("creators") or [{}])[0]).get("familyName", "") or ((a.get("creators") or [{}])[0]).get("name", "")
                doi = ident
            else:
                m = crossref(ident)
                title = (m.get("title") or [""])[0]
                year = str(((m.get("issued") or {}).get("date-parts") or [[""]])[0][0])
                first = ((m.get("author") or [{}])[0]).get("family", "")
                doi = ident
        except Exception as e:  # noqa: BLE001
            rows.append((key, ident, "", "", "", f"ERROR {str(e)[:60]}"))
            continue
        ok_t = norm(words) in norm(title)
        ok_a = norm(au).split()[0][:5] in norm(first)
        status = "checked" if ok_t and ok_a else f"MISMATCH title={ok_t} author={ok_a}"
        ident_s = f"PMID:{ident}" + (f" doi:{doi}" if doi else "") if kind == "pmid" else f"doi:{ident}" + (" (DataCite)" if kind == "datacite" else "")
        rows.append((key, ident_s, year, first, title.replace("\t", " "), status))
    with open(OUT, "w") as f:
        f.write("key\tid\tyear\tfirst_author\ttitle\tstatus\n")
        for r in rows:
            f.write("\t".join(r) + "\n")
    for r in rows:
        print("\t".join([r[0], r[1][:40], r[2], r[3][:20], r[5], r[4][:70]]))


def search(q):
    qq = urllib.parse.quote(q)
    d = get(f"https://www.ebi.ac.uk/europepmc/webservices/rest/search?query={qq}&format=json&pageSize=6&resultType=lite", "s_" + q[:60])
    for r in (d.get("resultList") or {}).get("result") or []:
        print("\t".join(str(r.get(k, "")) for k in ("pmid", "pubYear", "authorString", "title"))[:220])


def abstract(pmid, pat):
    r = epmc(pmid)
    ab = re.sub("<[^>]+>", "", (r or {}).get("abstractText") or "")
    print(pmid, (r or {}).get("title", "")[:100])
    for s in re.split(r"(?<=[.;])\s+", ab):
        if re.search(pat, s, re.I):
            print("  >", s[:420])


if __name__ == "__main__":
    if len(sys.argv) == 1:
        check()
    elif sys.argv[1] == "search":
        search(sys.argv[2])
    elif sys.argv[1] == "abstract":
        abstract(sys.argv[2], sys.argv[3] if len(sys.argv) > 3 else ".")

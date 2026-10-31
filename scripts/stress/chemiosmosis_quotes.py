"""Program 09: check that every quote the stress set leans on is a verbatim substring of its source.

Sources: Europe PMC abstracts cached by chemiosmosis_verify.py in /tmp/biolean-09/dl2/, and the
1978 Nobel presentation speech saved in /tmp/biolean-09/r2/dl/. Downloads are untrusted: run with
`python3 -I`. Matching ignores case, runs of white space and the characters "..." stand for a gap.
Writes data/stress/09/quotes_checked.tsv.

    python3 -I scripts/stress/chemiosmosis_quotes.py <repo root>
"""
import csv
import html
import json
import os
import re
import sys

ROOT = sys.argv[1] if len(sys.argv) > 1 else "."
DL = "/tmp/biolean-09/dl2"
SPEECH = "/tmp/biolean-09/r2/dl/nobel_speech.html"

# (case ids, source, quote)
QUOTES = [
    ("CH-01 CH-02", "11536297", "an intense controversy that lasted for 15 years"),
    ("CH-04 CH-19", "11536297", "generally accepted"),
    ("CH-08 CH-24", "11859886", "lacked any experimental support"),
    ("CH-02", "31622585", "Since mid-1970s"),
    ("CH-22", "23104597", "finally abandoned as an explanation of the overall process"),
    ("CH-19 CH-40", "24476986", "necessitates a modification"),
    ("CH-19 CH-40", "708723", "is not so very different"),
    ("CH-19", "708723", "I have put the argument for localised reactions"),
    ("CH-43 CH-45", "32717593", "inconsistent with established experimental data"),
    ("CH-23", "8842371", "the essential elements of the theory were published 9 years earlier by Davies and Krebs"),
    ("CH-42", "16666959", "adding 100 millimolar KCl to the intact organelle storage medium resulted in the subsequent ATP formation assay showing delocalized proton gradient coupling"),
    ("CH-42", "16666959", "Adding 5 millimolar CaCl(2) to the 100 millimolar KCl storage medium resulted in a localized proton gradient coupling mode"),
    ("CH-34", "670292", "10-20 mV, positive inside"),
    ("CH-34", "670292", "independent of the metabolic state"),
    ("CH-02", "4517939", "plays the central role"),
    ("CH-12", "138419", "analogous to those of substrate-level phosphorylation"),
    ("CH-12", "5507209", "may represent the type reaction"),
    ("CH-19 CH-41", "6293600", "energy coupling is strictly localized"),
    ("CH-19 CH-41", "6870853", "appears to be inconsistent with models"),
    ("CH-19", "39167050", "problematic interpretations"),
    ("CH-49", "22082452", "Grey Book"),
    ("CH-41", "2996506", "localized"),
    ("CH-14", "2422160", "localized"),
    ("CH-01", "SPEECH", "received with reservation"),
    ("CH-02 CH-47", "SPEECH", "generally regarded as experimentally proven"),
    ("CH-03 CH-12", "SPEECH", "no experimental evidence could be obtained"),
    # added by the review, 2026-10-31 (CH-50; the blanket retirement date in CH-12 and CH-28)
    ("CH-12 CH-28 CH-50", "SPEECH", "Despite intensive efforts in many laboratories, however, no experimental evidence could be obtained for these hypotheses"),
]


def norm(s):
    s = html.unescape(re.sub("<[^>]+>", " ", s))
    return re.sub(r"\s+", " ", s).strip().lower()


def text_of(src):
    if src == "SPEECH":
        with open(SPEECH, encoding="utf-8", errors="replace") as f:
            return norm(f.read())
    path = os.path.join(DL, f"core_{src}.json")
    if not os.path.exists(path):
        return None
    with open(path) as f:
        rs = json.load(f).get("resultList", {}).get("result", [])
    return norm(rs[0].get("abstractText", "")) if rs else None


def found(quote, text):
    parts = [norm(p) for p in quote.split("...")]
    i = 0
    for p in parts:
        j = text.find(p, i)
        if j < 0:
            return False
        i = j + len(p)
    return True


def main():
    out = []
    for cases, src, q in QUOTES:
        t = text_of(src)
        status = "NO SOURCE" if t is None else ("FOUND" if found(q, t) else "NOT FOUND")
        label = "Nobel 1978 presentation speech (nobelprize.org)" if src == "SPEECH" else f"PMID:{src} abstract"
        out.append([cases, label, q, status])
    with open(os.path.join(ROOT, "data/stress/09/quotes_checked.tsv"), "w", newline="") as f:
        w = csv.writer(f, delimiter="\t", lineterminator="\n")
        w.writerow(["cases", "source", "quote", "status"])
        w.writerows(out)
    for o in out:
        print("\t".join(o))
    print(sum(o[3] == "FOUND" for o in out), "of", len(out), "found")


if __name__ == "__main__":
    main()

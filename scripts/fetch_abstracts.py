"""Fetch titles/abstracts for a fixed PMID list from PubMed efetch into JSON."""
import json, sys, urllib.request, xml.etree.ElementTree as ET
PMIDS = {
  # chemiosmotic
  "13771349": "Mitchell 1961 Nature: chemiosmotic hypothesis",
  "13111237": "Slater 1953 Nature: chemical intermediate mechanism",
  "5220864":  "Jagendorf & Uribe 1966 PNAS: acid-bath ATP synthesis",
  "16742541": "Mitchell & Moyle 1967 Biochem J: respiration-driven proton translocation",
  "4272126":  "Racker & Stoeckenius 1974 JBC: bacteriorhodopsin + ATPase liposomes",
  "4330063":  "Hinkle & Horstman 1971 JBC: respiration-driven proton transport in submitochondrial particles",
  # NMN
  "21982712": "Yoshino 2011 Cell Metab: NMN in diet/age-induced diabetic mice",
  "24360282": "Gomes 2013 Cell: NMN reverses mitochondrial dysfunction in aged mice",
  "28068222": "Mills 2016 Cell Metab: long-term NMN mitigates age-associated decline in mice",
  "29570999": "Das 2018 Cell: NMN restores vascular aging, endurance in mice",
  "33888596": "Yoshino 2021 Science: NMN in prediabetic women (human RCT)",
}
url = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=pubmed&retmode=xml&id=" + ",".join(PMIDS)
root = ET.fromstring(urllib.request.urlopen(url, timeout=60).read())
out = []
for art in root.iter("PubmedArticle"):
    pmid = art.findtext(".//PMID")
    title = "".join(art.find(".//ArticleTitle").itertext())
    abst = " ".join("".join(a.itertext()) for a in art.findall(".//Abstract/AbstractText"))
    year = art.findtext(".//PubDate/Year") or art.findtext(".//PubDate/MedlineDate")
    journal = art.findtext(".//Journal/Title")
    out.append(dict(pmid=pmid, year=year, journal=journal, title=title, abstract=abst, note=PMIDS.get(pmid)))
json.dump(out, open(sys.argv[1], "w"), indent=1)
for o in out: print(o["pmid"], o["year"], len(o["abstract"]), o["title"][:70])

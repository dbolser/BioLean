"""Program 01b: option (k), common descent as a defeasible default, sketched and measured (E10).

One script, several steps. Run every step with `python3 -I` from the repo root: steps that read
downloads read them from /tmp/biolean-01b/ (untrusted data), and nothing here imports local code.

  python3 -I scripts/stress/descent_sketch.py search "free text"   # Europe PMC leads (prints only)
  python3 -I scripts/stress/descent_sketch.py abstract DOI          # print one abstract (prints only)
  python3 -I scripts/stress/descent_sketch.py fetch     # NCBI Taxonomy lineages -> data/stress/01b/lineages.tsv
  python3 -I scripts/stress/descent_sketch.py refs      # Europe PMC / Crossref -> references_checked.tsv
  python3 -I scripts/stress/descent_sketch.py curies    # OLS4 -> curies_checked.tsv
  python3 -I scripts/stress/descent_sketch.py quickgo   # QuickGO experimental counts -> quickgo_counts.tsv
  python3 -I scripts/stress/descent_sketch.py run       # the sketch: (b) and (b)+(k) on every case,
                                                        # sensitivity and coherence -> sketch.tsv, ...
  lake env lean BioLean/Stress/Descent.lean > data/stress/01b/lean_output.txt   # option (c), today's core
  python3 -I scripts/stress/descent_sketch.py table     # merge with the Lean OBS lines -> cases.tsv,
                                                        # scorecard.tsv, tallies.json
  python3 -I scripts/stress/descent_sketch.py check     # re-run run and table; assert the doc's numbers

Downloads are cached in /tmp/biolean-01b/dl2/. Outputs go to data/stress/01b/. Read-only web
lookups only (NCBI E-utilities, Europe PMC, Crossref, OLS4, QuickGO).
"""
import itertools
import json
import re
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from fractions import Fraction as F
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "data/stress/01b"
DL = Path("/tmp/biolean-01b/dl2")
TODAY = "2026-11-01"
UA = {"User-Agent": "BioLean-01b/0.1 (read-only research lookup)", "Accept": "application/json"}


# ---------------------------------------------------------------------------------------------
# Web helpers (read-only GETs, cached in /tmp/biolean-01b/dl2)
# ---------------------------------------------------------------------------------------------

def http_get(url, binary=False, tries=8):
    for i in range(tries):
        try:
            req = urllib.request.Request(url, headers=UA)
            with urllib.request.urlopen(req, timeout=60) as r:
                raw = r.read()
            return raw if binary else json.loads(raw.decode())
        except urllib.error.HTTPError as e:
            if e.code == 404:
                return None
            if e.code in (429, 500, 502, 503, 504):
                time.sleep(2 + 2 * i)
                continue
            raise
        except (urllib.error.URLError, TimeoutError):
            time.sleep(2 + 2 * i)
    raise RuntimeError(f"giving up on {url}")


def cached(name, fetch):
    DL.mkdir(parents=True, exist_ok=True)
    p = DL / name
    if p.exists():
        return json.loads(p.read_text())
    d = fetch()
    p.write_text(json.dumps(d))
    return d


def safe(s):
    return re.sub(r"[^A-Za-z0-9._-]", "_", s)[:120]


def strip_tags(s):
    return re.sub(r"<[^>]+>", "", s or "")


def epmc_search(query, page=8):
    q = urllib.parse.urlencode({"query": query, "resultType": "core", "format": "json", "pageSize": page})
    return cached("epmc_q_" + safe(query) + ".json",
                  lambda: http_get("https://www.ebi.ac.uk/europepmc/webservices/rest/search?" + q))


def epmc_doi(doi):
    return epmc_search(f'DOI:"{doi}"', page=2)


def crossref_doi(doi):
    return cached("crossref_" + safe(doi) + ".json",
                  lambda: http_get("https://api.crossref.org/works/" + urllib.parse.quote(doi)))


def cmd_search(args):
    for qq in args:
        d = epmc_search(qq)
        print("###", qq, d.get("hitCount"))
        for r in d.get("resultList", {}).get("result", []):
            first = (r.get("authorList", {}).get("author") or [{}])[0].get("fullName")
            print(f"  PMID {r.get('pmid')} doi {r.get('doi')} | {first} | {r.get('pubYear')} | {r.get('title', '')[:120]}")


def cmd_abstract(args):
    for doi in args:
        d = epmc_doi(doi)
        res = d.get("resultList", {}).get("result", [])
        if not res:
            print("NOT IN EPMC", doi)
            continue
        r = res[0]
        first = (r.get("authorList", {}).get("author") or [{}])[0].get("fullName")
        print(f"== {doi} PMID {r.get('pmid')} | {first} | {r.get('pubYear')} | {r.get('title')}")
        print(strip_tags(r.get("abstractText", "")))




# ---------------------------------------------------------------------------------------------
# Sources. Every key is checked by `refs` (DOI on Europe PMC, else Crossref; title and first
# author recorded). `qgo:` keys are QuickGO experimental-annotation counts (`quickgo`); `ncbi:`
# keys are NCBI Taxonomy genetic-code fields (`fetch`); `general` marks a fact I did not cite.
# ---------------------------------------------------------------------------------------------

SRC = {
    # methods
    "witmer1995": (None, "Witmer LM 1995, extant phylogenetic bracket (book chapter, no DOI)"),
    "farris1977": ("10.2307/2412867", "Dollo's law: gained once, lost many times"),
    "josang2005": ("10.1016/j.ijar.2004.03.003", "binomial multiplication of opinions"),
    "collin2008": ("10.1016/j.tree.2008.06.013", "Dollo's law is often broken"),
    "albalat2016": ("10.1038/nrg.2016.39", "evolution by gene loss (review)"),
    "kirilenko2023": ("10.1126/science.abn3107", "TOGA: orthology and gene loss at scale"),
    "sharma2018": ("10.1038/s41467-018-03667-1", "gene losses across mammals"),
    # program 01 test set
    "werner2011": ("10.1038/nrmicro2507", "multisubunit RNA polymerases in all three domains"),
    "woese1977": ("10.1073/pnas.74.11.5088", "rRNA in all three primary kingdoms"),
    "oftedal2002": ("10.1023/A:1022848632125", "lactation in all mammals, monotremes included"),
    "barrell1979": ("10.1038/282189a0", "human mitochondria use a different code"),
    "yamao1985": ("10.1073/pnas.82.8.2306", "UGA read as Trp in Mycoplasma capricolum"),
    "preer1985": ("10.1038/314188a0", "Paramecium deviates from the universal code"),
    "santos1995": ("10.1093/nar/23.9.1481", "CUG read as Ser in Candida albicans"),
    "tovar2003": ("10.1038/nature01945", "Giardia mitosomes, remnant organelles"),
    "bui1996": ("10.1073/pnas.93.18.9651", "hydrogenosomes share an origin with mitochondria"),
    "karnkowska2016": ("10.1016/j.cub.2016.03.053", "Monocercomonoides has no mitochondrial organelle"),
    "anderson1981": ("10.1038/290457a0", "human mtDNA: 37 genes"),
    "lang1997": ("10.1038/387493a0", "Reclinomonas mtDNA, bacteria-like, with rpo genes"),
    "burger2013": ("10.1093/gbe/evt008", "jakobid mtDNAs gene-rich (Andalucia 100 genes)"),
    "pollock1987": ("10.1002/ajpa.1330730106", "15 prosimians make vitamin C, Tarsius does not"),
    "nishikimi1994": ("10.1016/s0021-9258(17)36884-9", "human GULO pseudogene"),
    "nishikimi1992": ("10.1016/s0021-9258(19)36707-9", "guinea pig GULO pseudogene"),
    "koshizaka1988": ("10.1016/s0021-9258(19)77923-x", "rat liver GULO cDNA"),
    "maeda2000": ("10.1073/pnas.97.2.841", "mouse makes vitamin C (Gulo knockout)"),
    "ohta1999": ("10.1016/s0304-4165(99)00123-3", "GULO pseudogene in human, chimp, orangutan, macaque"),
    "yamamoto2000": ("10.1126/science.289.5479.631", "cave fish eye degeneration"),
    "jeffery2009": ("10.1146/annurev-genet-102108-134216", "regressive evolution in Astyanax cavefish"),
    "ji2011": ("10.1016/j.tcb.2011.04.003", "mammalian erythrocytes enucleate"),
    "ruud1954": ("10.1038/173848a0", "vertebrates without erythrocytes and blood pigment"),
    "cocca1995": ("10.1073/pnas.92.6.1817", "icefish alpha-globin remnants; red-blooded Notothenia"),
    "meredith2009": ("10.1371/journal.pgen.1000634", "ENAM decay in toothless mammals"),
    "ogura2004": ("10.1101/gr.2268104", "octopus and human camera eyes convergent"),
    "li2010": ("10.1016/j.cub.2009.11.042", "prestin convergence in bats and whales"),
    "liu2010": ("10.1016/j.cub.2009.11.058", "convergent sequence evolution, bats and dolphins"),
    "sage2011": ("10.1093/jxb/err048", "62 C4 lineages"),
    "chen1997": ("10.1073/pnas.94.8.3817", "convergent antifreeze glycoproteins"),
    "moran2010": ("10.1126/science.1187113", "aphids make carotenoids with fungal genes"),
    "embley2006": ("10.1038/nature04546", "Archezoa rejected"),
    "roger1998": ("10.1073/pnas.95.1.229", "Giardia mitochondrial-type cpn60"),
    "germot1996": ("10.1073/pnas.93.25.14614", "Trichomonas mitochondrial-type hsp70"),
    "clark1995": ("10.1073/pnas.92.14.6518", "Entamoeba genes of mitochondrial origin"),
    "williams2002": ("10.1038/nature00949", "mitochondrial remnant in a microsporidian"),
    "paredez2011": ("10.1073/pnas.1018593108", "Giardia has an actin cytoskeleton"),
    "higashiyama2018": ("10.1111/joa.12707", "rat has no gallbladder"),
    "holling2004": ("10.1016/j.humimm.2004.01.005", "mouse activated T cells lack MHC II"),
    "crocker1987": ("10.1084/jem.166.2.613", "mouse macrophages lack CD4"),
    "horn2013": ("10.1371/journal.pone.0060537", "rodents cannot vomit"),
    "he2021": ("10.1126/science.aay1513", "Typhlomys echolocates"),
    # new cases (01b)
    "tovar1999": ("10.1046/j.1365-2958.1999.01414.x", "Entamoeba mitosome"),
    "ogawa2000": ("10.1007/pl00008685", "Dictyostelium mtDNA: nad genes, cox1/2"),
    "yahalomi2020": ("10.1073/pnas.1909907117", "Henneguya lacks a mitochondrial genome; Myxobolus has one"),
    "she2018": ("10.1016/j.mito.2017.08.003", "C. albicans has complex I; S. cerevisiae lacks it"),
    "videira1998": ("10.1016/s0005-2728(98)00020-6", "Neurospora complex I"),
    "senkler2018": ("10.1016/j.cub.2018.03.050", "Viscum album lacks complex I"),
    "maclean2018": ("10.1016/j.cub.2018.03.036", "Viscum album lacks complex I (vs Arabidopsis)"),
    "covello1992": ("10.1002/j.1460-2075.1992.tb05473.x", "soybean cox2: silent in mtDNA, active in nucleus"),
    "nugent1991": ("PMID:1714355", "cox2 moved to the nucleus in legumes"),
    "chou1998": ("10.1073/pnas.95.20.11751", "human CMAH deletion after the Homo-Pan split"),
    "meredith2014": ("10.1126/science.1254390", "one loss of teeth in the avian ancestor; turtles toothless"),
    "wu2013": ("10.1073/pnas.1213202110", "alligator teeth"),
    "wolfe1992": ("10.1073/pnas.89.22.10648", "Epifagus plastid lacks all photosynthesis genes"),
    "shinozaki1986": ("10.1002/j.1460-2075.1986.tb04464.x", "tobacco chloroplast genome"),
    "denoeud2014": ("10.1126/science.1255274", "coffee caffeine NMTs evolved independently of tea and cacao"),
    "huang2016": ("10.1073/pnas.1602575113", "caffeine evolved several times"),
    "tishkoff2007": ("10.1038/ng1946", "lactase persistence convergent in Africa and Europe"),
    "wiens2011": ("10.1111/j.1558-5646.2011.01221.x", "mandibular teeth lost in the frog ancestor, regained in Gastrotheca"),
    "paluh2021": ("10.1111/evo.14379", "Gastrotheca guentheri has true mandibular teeth"),
    "bibb1981": ("10.1016/0092-8674(81)90300-7", "mouse mtDNA encodes cytochrome b"),
    "anderson1982": ("10.1016/0022-2836(82)90137-1", "bovine mtDNA sequence"),
    "general": (None, "general knowledge, not cited"),
    "synthetic": (None, "synthetic edge case"),
}

# Trait labels and CURIEs (checked by `curies`).
TRAIT = {
    "transcription": ("GO:0006351", "DNA-templated transcription"),
    "ribosome": ("GO:0005840", "ribosome"),
    "lactation": ("GO:0007595", "lactation"),
    "mitocode1": (None, "mitochondrial genetic code is the standard one (NCBI gc 1)"),
    "uga_stop": (None, "UGA is read as stop (NCBI gc 1 or 11)"),
    "uaa_stop": (None, "UAA and UAG are read as stop"),
    "cug_leu": (None, "CUG is read as leucine"),
    "nuc_code1": (None, "nuclear genes use the standard code (NCBI gc 1)"),
    "mito": ("GO:0005739", "mitochondrion"),
    "mro": ("GO:0005739|GO:0032047|GO:0042566", "mitochondrion or a mitochondrion-related organelle"),
    "mt_rpo": ("GO:0000262", "mitochondrial chromosome encodes a bacterial-type RNA polymerase (rpoB)"),
    "vitc": ("GO:0019853", "L-ascorbic acid biosynthetic process"),
    "eye": ("UBERON:0000970", "eye"),
    "haem": ("GO:0005833", "hemoglobin complex"),
    "tooth": ("UBERON:0001091", "calcareous tooth"),
    "camera_eye": ("UBERON:0000019", "camera-type eye"),
    "echolocation": ("GO:0050959", "echolocation"),
    "c4": ("GO:0009760", "C4 photosynthesis"),
    "afgp": ("GO:0016172", "antifreeze activity (antifreeze glycoprotein)"),
    "carotenoid": ("GO:0016117", "carotenoid biosynthetic process"),
    "actin": ("GO:0015629", "actin cytoskeleton"),
    "forelimb": ("UBERON:0002102", "forelimb"),
    "liver": ("UBERON:0002107", "liver"),
    "gallbladder": ("UBERON:0002110", "gall bladder"),
    "mhc2_t": ("GO:0042613", "MHC class II protein complex on activated T cells"),
    "cd4_mac": ("PR:000001004", "CD4 on macrophages"),
    "vomit": ("HP:0002013", "vomiting"),
    "sinusoid": ("UBERON:0003910", "splenic sinusoid"),
    "mtdna": ("GO:0000262", "mitochondrial chromosome"),
    "complex1": ("GO:0045271", "respiratory chain complex I"),
    "mt_cox2": ("GO:0000262", "cox2 expressed from the mitochondrial chromosome"),
    "cmah": ("GO:0030338", "CMP-N-acetylneuraminate monooxygenase activity"),
    "photosynthesis": ("GO:0015979", "photosynthesis"),
    "caffeine": ("GO:0102741", "caffeine synthase activity"),
    "lactase_adult": ("GO:0000016", "lactase activity in adults (lactase persistence)"),
    "mt_cytb": ("GO:0000262", "cytochrome b encoded by the mitochondrial chromosome"),
    "mand_tooth": ("UBERON:0003268", "tooth of lower jaw"),
    "cell_nucleus": ("CL:0000595", "every cell has a nucleus (enucleate erythrocyte is the exception)"),
}

# Other CURIEs cited in the doc and the Lean file.
EXTRA_CURIES = ["CL:0000000", "CL:0000084", "CL:0000235", "GO:0005634", "RO:0002200", "UBERON:0003268",
                "HOM:0000004", "HOM:0000007", "RO:0002504", "RO:0002162", "RO:0002215", "BFO:0000051",
                "GO:0032047", "GO:0042566", "GO:0009507", "CL:0000595", "CL:0000232", "ECO:0000269",
                "ECO:0000318", "ECO:0000501",
                # review: the homology relations used in Descent.lean (homolClaim, convRec)
                "RO:0002158", "RO:0002156", "RO:0002157"]


# ---------------------------------------------------------------------------------------------
# Cases. A record is (taxon, state, source). state: has (trait present); lacks (absent, nothing
# said about history); lost (absent, with DNA or relic evidence that an ancestor had it). A
# convergence record (a, b, source) says the trait in a and in b arose separately (HOM:0000004).
#
# form: has T   "every member of T has the trait" (a species or a clade: one shape)
#       homol A B "the trait in A and in B comes from their common ancestor"
#       never [S] "the ancestors of each S never had the trait" (Archezoa)
#       none T  "no member of T has the trait"
#       X       the sketch cannot state it (reason given)
# `own` records belong to the target and are withheld in the "-" row of a new case; `conv` in a
# convergence case is withheld in its "-" row. Program 01's cases have one row each, as written
# there, plus a withheld row for O cases (`withhold` = the change records).
# ---------------------------------------------------------------------------------------------

def R(t, state, src):
    return (int(t), state, src)


EUK_MITO = [R(4932, "has", "qgo:mito"), R(9606, "has", "qgo:mito"), R(3702, "has", "qgo:mito"),
            R(10090, "has", "qgo:mito")]
VITC = [R(10090, "has", "maeda2000"), R(10116, "has", "koshizaka1988"), R(376911, "has", "pollock1987")]

CASES = [
    # ---- program 01, universal (U) and override (O) ----
    dict(id="U1", mode="U", form=("has", 131567), trait="transcription", truth=True, src="werner2011",
         recs=[R(t, "has", "qgo:transcription") for t in (562, 4932, 10090, 9606, 3702, 330779)]),
    dict(id="U2", mode="U", form=("has", 131567), trait="ribosome", truth=True, src="woese1977",
         recs=[R(t, "has", "qgo:ribosome") for t in (562, 4932, 9606, 3702)] + [R(28890, "has", "woese1977")]),
    dict(id="LT1", mode="U", form=("has", 40674), trait="lactation", truth=True, src="oftedal2002",
         recs=[R(10090, "has", "qgo:lactation"), R(9606, "has", "qgo:lactation"), R(9913, "has", "general"),
               R(9258, "has", "oftedal2002")]),
    dict(id="N1", mode="O", form=("has", 7742), trait="mitocode1", truth=False, src="barrell1979",
         recs=[R(3702, "has", "ncbi:mgc"), R(44689, "has", "ncbi:mgc")],
         withhold=[R(9606, "lacks", "ncbi:mgc"), R(10090, "lacks", "ncbi:mgc"), R(7955, "lacks", "ncbi:mgc")]),
    dict(id="N2", mode="O", form=("has", 2095), trait="uga_stop", truth=False, src="yamao1985",
         recs=[R(562, "has", "ncbi:gc"), R(1423, "has", "ncbi:gc")], withhold=[R(2095, "lacks", "yamao1985")]),
    dict(id="N3", mode="O", form=("has", 5888), trait="uaa_stop", truth=False, src="preer1985",
         recs=[R(4932, "has", "ncbi:gc"), R(9606, "has", "ncbi:gc")], withhold=[R(5888, "lacks", "preer1985")]),
    dict(id="N4", mode="O", form=("has", 5476), trait="cug_leu", truth=False, src="santos1995",
         recs=[R(4932, "has", "ncbi:gc"), R(9606, "has", "ncbi:gc")], withhold=[R(5476, "lacks", "santos1995")]),
    dict(id="L1", mode="O", form=("has", 5741), trait="mito", truth=False, src="tovar2003",
         recs=EUK_MITO, withhold=[R(5741, "lost", "tovar2003")]),
    dict(id="L2", mode="O", form=("has", 5722), trait="mito", truth=False, src="bui1996",
         recs=EUK_MITO, withhold=[R(5722, "lost", "bui1996")]),
    dict(id="L3", mode="O", form=("has", 2049356), trait="mro", truth=False, src="karnkowska2016",
         recs=[R(5741, "has", "tovar2003"), R(5722, "has", "bui1996"), R(4932, "has", "qgo:mito"),
               R(9606, "has", "qgo:mito")], withhold=[R(2049356, "lacks", "karnkowska2016")]),
    dict(id="L4", mode="O", form=("has", 9606), trait="mt_rpo", truth=False, src="anderson1981",
         recs=[R(48483, "has", "lang1997"), R(505711, "has", "burger2013")],
         withhold=[R(9606, "lacks", "anderson1981")]),
    dict(id="L5", mode="O", form=("has", 40674), trait="vitc", truth=False, src="pollock1987",
         recs=VITC, withhold=[R(376913, "lost", "nishikimi1994"), R(10141, "lost", "nishikimi1992")]),
    dict(id="L6", mode="O", form=("has", 7994), trait="eye", truth="mixed", src="jeffery2009",
         recs=[R(7994, "has", "jeffery2009"), R(7955, "has", "general"), R(9606, "has", "general")],
         withhold=[R(7994, "lost", "yamamoto2000")]),
    dict(id="L7", mode="O", form=("X", "a cell type below the taxon (CL:0000595): the sketch reasons over taxa only"),
         trait="cell_nucleus", truth=False, src="ji2011", recs=[]),
    dict(id="L8", mode="O", form=("has", 7742), trait="haem", truth=False, src="cocca1995",
         recs=[R(9606, "has", "qgo:haem"), R(10090, "has", "qgo:haem"), R(8208, "has", "cocca1995")],
         withhold=[R(30806, "lost", "cocca1995")]),
    dict(id="L9", mode="O", form=("has", 40674), trait="tooth", truth=False, src="meredith2009",
         recs=[R(9606, "has", "general"), R(10090, "has", "general"), R(9913, "has", "general")],
         withhold=[R(9761, "lost", "meredith2009"), R(9971, "lost", "meredith2009")]),
    dict(id="CV1", mode="O", form=("homol", 7742, 6606), trait="camera_eye", truth=False, src="ogura2004",
         recs=[R(7742, "has", "general"), R(6606, "has", "general")], conv=[(7742, 6606, "ogura2004")]),
    dict(id="CV2", mode="O", form=("homol", 9397, 9722), trait="echolocation", truth=False, src="li2010",
         recs=[R(9397, "has", "li2010"), R(9722, "has", "liu2010")], conv=[(9397, 9722, "li2010")]),
    dict(id="CV3", mode="O", form=("homol", 4577, 4227), trait="c4", truth=False, src="sage2011",
         recs=[R(4577, "has", "sage2011"), R(4227, "has", "sage2011")], conv=[(4577, 4227, "sage2011")]),
    dict(id="CV4", mode="O", form=("homol", 8205, 8045), trait="afgp", truth=False, src="chen1997",
         recs=[R(8205, "has", "chen1997"), R(8045, "has", "chen1997")], conv=[(8205, 8045, "chen1997")]),
    dict(id="H1", mode="O", form=("none", 33208), trait="carotenoid", truth=False, src="moran2010",
         recs=[R(9606, "lacks", "general"), R(10090, "lacks", "general")],
         withhold=[R(7029, "has", "moran2010")]),
    dict(id="A1", mode="O", form=("never", (5741, 5722, 5759, 6029)), trait="mito", truth=False, src="embley2006",
         recs=EUK_MITO, withhold=[R(5741, "lost", "roger1998"), R(5722, "lost", "germot1996"),
                                  R(5759, "lost", "clark1995"), R(6029, "lost", "williams2002")]),
    # ---- program 01, predict (P): the target's own records are not given ----
    dict(id="NT1", mode="P", form=("has", 10090), trait="nuc_code1", truth=True, src="ncbi:gc",
         recs=[R(10116, "has", "ncbi:gc"), R(9606, "has", "ncbi:gc")]),
    dict(id="LT2", mode="P", form=("has", 5741), trait="actin", truth=True, src="paredez2011",
         recs=[R(4932, "has", "qgo:actin"), R(9606, "has", "qgo:actin"), R(3702, "has", "qgo:actin")]),
    dict(id="LT3", mode="P", form=("has", 10090), trait="vitc", truth=True, src="maeda2000",
         recs=[R(10116, "has", "koshizaka1988"), R(376911, "has", "pollock1987"),
               R(376913, "lost", "nishikimi1994"), R(10141, "lost", "nishikimi1992")]),
    dict(id="CVT1", mode="P", form=("homol", 9606, 10090), trait="camera_eye", truth=True, src="general",
         recs=[R(9606, "has", "general"), R(10090, "has", "general")]),
    dict(id="CVT2", mode="P", form=("homol", 9397, 10090), trait="forelimb", truth=True, src="general",
         recs=[R(9397, "has", "general"), R(10090, "has", "general")]),
    dict(id="RMT1", mode="P", form=("has", 10090), trait="liver", truth=True, src="general",
         recs=[R(10116, "has", "general"), R(9606, "has", "general")]),
    dict(id="RM1", mode="P", form=("has", 10116), trait="gallbladder", truth=False, src="higashiyama2018",
         recs=[R(10090, "has", "higashiyama2018"), R(9606, "has", "general")]),
    dict(id="RM2", mode="P", form=("has", 10090), trait="mhc2_t", truth=False, src="holling2004",
         recs=[R(10116, "has", "holling2004"), R(9606, "has", "holling2004")]),
    dict(id="RM3", mode="P", form=("has", 10090), trait="cd4_mac", truth=False, src="crocker1987",
         recs=[R(10116, "has", "crocker1987"), R(9606, "has", "crocker1987")]),
    dict(id="RM4", mode="P", form=("has", 10116), trait="vomit", truth=False, src="horn2013",
         recs=[R(10090, "lacks", "horn2013"), R(10141, "lacks", "horn2013"), R(9606, "has", "horn2013")]),
    dict(id="RM5", mode="P", form=("has", 10090), trait="sinusoid", truth=False, src="general",
         recs=[R(10116, "has", "general"), R(9606, "has", "general")]),
    # ---- 01b: new cases. Two rows each: "-" own record (or convergence record) withheld, "+" given ----
    dict(id="D01", mode="N", form=("has", 5759), trait="mito", truth=False, src="tovar1999",
         kind="amitochondriate protist", recs=EUK_MITO + [R(44689, "has", "ogawa2000")],
         own=[R(5759, "lost", "clark1995"), R(5759, "lost", "tovar1999")]),
    dict(id="D02", mode="N", form=("has", 69463), trait="mtdna", truth=False, src="yahalomi2020",
         kind="animal without mtDNA", recs=[R(59785, "has", "yahalomi2020"), R(9606, "has", "anderson1981")],
         own=[R(69463, "lost", "yahalomi2020")]),
    dict(id="D03", mode="N", form=("has", 4932), trait="complex1", truth=False, src="she2018",
         kind="mitochondrial complex lost", recs=[R(5476, "has", "she2018"), R(5141, "has", "videira1998"),
                                                 R(9606, "has", "qgo:complex1"), R(3702, "has", "qgo:complex1")],
         own=[R(4932, "lacks", "she2018")]),
    dict(id="D04", mode="N", form=("has", 3847), trait="mt_cox2", truth=False, src="covello1992",
         kind="gene moved to the nucleus", recs=[R(9606, "has", "anderson1981"), R(44689, "has", "ogawa2000")],
         own=[R(3847, "lost", "covello1992")]),
    dict(id="D05", mode="N", form=("has", 9598), trait="vitc", truth=False, src="ohta1999",
         kind="pseudogene (GULO)", recs=VITC + [R(9606, "lost", "nishikimi1994"), R(9544, "lost", "ohta1999"),
                                               R(10141, "lost", "nishikimi1992"), R(9476, "lacks", "pollock1987")],
         own=[R(9598, "lost", "ohta1999")]),
    dict(id="D06", mode="N", form=("has", 9606), trait="cmah", truth=False, src="chou1998",
         kind="pseudogene (CMAH)", recs=[R(9598, "has", "chou1998"), R(9593, "has", "chou1998"),
                                         R(10090, "has", "chou1998")],
         own=[R(9606, "lost", "chou1998")]),
    dict(id="D07", mode="N", form=("has", 9031), trait="tooth", truth=False, src="meredith2014",
         kind="pseudogenes (enamel, dentin)", recs=[R(8496, "has", "wu2013"), R(8459, "lacks", "meredith2014"),
                                                    R(9606, "has", "general")],
         own=[R(8782, "lost", "meredith2014")]),
    dict(id="D08", mode="N", form=("has", 36190), trait="haem", truth=False, src="cocca1995",
         kind="globin remnants (icefish)", recs=[R(8208, "has", "cocca1995"), R(7955, "has", "general"),
                                                 R(9606, "has", "qgo:haem")],
         own=[R(30806, "lost", "cocca1995")]),
    dict(id="D09", mode="N", form=("has", 4177), trait="photosynthesis", truth=False, src="wolfe1992",
         kind="plastid genes lost", recs=[R(4097, "has", "shinozaki1986"), R(3702, "has", "qgo:photosynthesis")],
         own=[R(4177, "lost", "wolfe1992")]),
    dict(id="D10", mode="N", form=("homol", 49390, 4442), trait="caffeine", truth=False, src="denoeud2014",
         kind="convergence", recs=[R(49390, "has", "denoeud2014"), R(4442, "has", "denoeud2014")],
         convown=[(49390, 4442, "denoeud2014")]),
    dict(id="D11", mode="N", form=("has", 9913), trait="echolocation", truth=False, src="synthetic",
         kind="convergence (synthetic)", recs=[R(9397, "has", "li2010"), R(9722, "has", "liu2010"),
                                               R(10090, "lacks", "general"), R(10116, "lacks", "general")],
         convown=[(9397, 9722, "li2010")]),
    dict(id="D12", mode="N", form=("has", 687454), trait="echolocation", truth=True, src="he2021",
         kind="convergent gain", recs=[R(9397, "has", "li2010"), R(9722, "has", "liu2010"),
                                       R(10090, "lacks", "general"), R(10116, "lacks", "general")],
         conv=[(9397, 9722, "li2010")], own=[R(687454, "has", "he2021")]),
    dict(id="D13", mode="N", form=("X", "a population below the species (Homo sapiens): no population slot"),
         trait="lactase_adult", truth=False, src="tishkoff2007", kind="convergence within a species", recs=[]),
    dict(id="D14", mode="N", form=("has", 394453), trait="mand_tooth", truth=True, src="wiens2011",
         kind="re-evolution (Dollo broken)", recs=[R(8296, "has", "wiens2011"), R(9606, "has", "general"),
                                                   R(8364, "lacks", "wiens2011"), R(8420, "lacks", "wiens2011")],
         own=[R(394453, "has", "paluh2021")]),
    dict(id="D15", mode="N", form=("has", 10090), trait="mt_cytb", truth=True, src="bibb1981",
         kind="retention (true)", recs=[R(9606, "has", "anderson1981"), R(9913, "has", "anderson1982")],
         own=[R(10090, "has", "bibb1981")]),
]


# ---------------------------------------------------------------------------------------------
# Rows: one per case (program 01), plus a "withheld" row for each O case; two per new case.
# ---------------------------------------------------------------------------------------------

def rows():
    out = []
    for c in CASES:
        base = dict(case=c["id"], form=c["form"], trait=c["trait"], truth=c["truth"], src=c["src"],
                    kind=c.get("kind", ""), conv=list(c.get("conv", [])))
        if c["mode"] in ("U", "P"):
            out.append(dict(base, id=c["id"], mode=c["mode"], recs=list(c["recs"]), given="all"))
        elif c["mode"] == "O":
            wh = c.get("withhold", [])
            out.append(dict(base, id=c["id"], mode="O", recs=c["recs"] + wh, given="all"))
            if wh or c.get("conv"):
                out.append(dict(base, id=c["id"] + "-", mode="O-", recs=list(c["recs"]), conv=[],
                                given="change record withheld"))
        else:
            own, convown = c.get("own", []), c.get("convown", [])
            out.append(dict(base, id=c["id"] + "-", mode="P", recs=list(c["recs"]), given="own record withheld"))
            out.append(dict(base, id=c["id"] + "+", mode="O", recs=c["recs"] + own,
                            conv=base["conv"] + convown, given="own record given"))
    return out


def all_taxa():
    ts = set()
    for c in CASES:
        for r in c.get("recs", []) + c.get("withhold", []) + c.get("own", []):
            ts.add(r[0])
        for a, b, _ in c.get("conv", []) + c.get("convown", []):
            ts.update((a, b))
        f = c["form"]
        if f[0] in ("has", "none"):
            ts.add(f[1])
        elif f[0] == "homol":
            ts.update(f[1:])
        elif f[0] == "never":
            ts.update(f[1])
    # taxa the Lean file and the doc name
    ts.update([131567, 2759, 33208, 40674, 7742, 314146, 376913, 9443, 8782, 28890])
    return sorted(ts)


# ---------------------------------------------------------------------------------------------
# fetch: NCBI Taxonomy lineages (E-utilities efetch, XML), parsed defensively
# ---------------------------------------------------------------------------------------------

def cmd_fetch(_args):
    import xml.etree.ElementTree as ET
    ids = all_taxa()
    rows_out = {}
    for k in range(0, len(ids), 40):
        chunk = ids[k:k + 40]
        name = f"ncbi_taxa_{chunk[0]}_{chunk[-1]}_{len(chunk)}.xml"
        p = DL / name
        if not p.exists():
            url = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?" + urllib.parse.urlencode(
                {"db": "taxonomy", "id": ",".join(map(str, chunk)), "retmode": "xml"})
            DL.mkdir(parents=True, exist_ok=True)
            p.write_bytes(http_get(url, binary=True))
            time.sleep(1.0)
        root = ET.fromstring(p.read_bytes())
        for t in root.findall("Taxon"):
            tid = t.findtext("TaxId")
            if not (tid and tid.isdigit()):
                continue
            lin = []
            le = t.find("LineageEx")
            for x in (le if le is not None else []):
                xi = x.findtext("TaxId")
                if xi and xi.isdigit():
                    lin.append((int(xi), (x.findtext("ScientificName") or "").replace("\t", " ")))
            nm = (t.findtext("ScientificName") or "").replace("\t", " ")
            rows_out[int(tid)] = dict(name=nm, rank=t.findtext("Rank") or "",
                                      lineage=[i for i, _ in lin] + [int(tid)],
                                      names={i: n for i, n in lin} | {int(tid): nm},
                                      gc=t.findtext("GeneticCode/GCId") or "", mgc=t.findtext("MitoGeneticCode/MGCId") or "")
    missing = [i for i in ids if i not in rows_out]
    OUT.mkdir(parents=True, exist_ok=True)
    with open(OUT / "lineages.tsv", "w") as f:
        f.write(f"# NCBI Taxonomy via E-utilities efetch, {TODAY}. lineage: root to taxon, NCBI ids; names: the same, by name.\n")
        f.write("taxid\tname\trank\tgc\tmgc\tlineage\tlineage_names\n")
        for i in sorted(rows_out):
            r = rows_out[i]
            f.write(f"{i}\t{r['name']}\t{r['rank']}\t{r['gc']}\t{r['mgc']}\t{' '.join(map(str, r['lineage']))}\t"
                    f"{' | '.join(r['names'].get(x, '') for x in r['lineage'])}\n")
    print(f"{len(rows_out)} taxa written; missing: {missing}")


def load_taxa():
    T = {}
    for line in open(OUT / "lineages.tsv"):
        if line.startswith("#") or line.startswith("taxid\t"):
            continue
        tid, name, rank, gc, mgc, lin, names = line.rstrip("\n").split("\t")
        lin = [int(x) for x in lin.split()]
        T[int(tid)] = dict(name=name, rank=rank, gc=gc, mgc=mgc, lineage=lin, names=dict(zip(lin, names.split(" | "))))
    return T


# ---------------------------------------------------------------------------------------------
# refs: every DOI in SRC on Europe PMC (title, first author, year, PMID); Crossref if absent
# ---------------------------------------------------------------------------------------------

def cmd_refs(_args):
    out = []
    for key, (doi, what) in SRC.items():
        if not doi:
            out.append((key, "", "", "", "", "", "", what, "not a DOI: " + ("UNVERIFIED" if key == "witmer1995" else key)))
            continue
        d = epmc_search(f"EXT_ID:{doi[5:]} AND SRC:MED", page=2) if doi.startswith("PMID:") else epmc_doi(doi)
        res = (d or {}).get("resultList", {}).get("result", [])
        if res:
            r = res[0]
            first = (r.get("authorList", {}).get("author") or [{}])[0].get("fullName") or r.get("authorString", "")
            out.append((key, r.get("doi") or "" if doi.startswith("PMID:") else doi, r.get("pmid") or "", first, r.get("pubYear") or "", (r.get("journalTitle") or r.get("journalInfo", {}).get("journal", {}).get("title") or ""),
                        strip_tags(r.get("title", "")), what, f"Europe PMC {TODAY}"))
            continue
        c = crossref_doi(doi)
        if c and c.get("message"):
            m = c["message"]
            a = (m.get("author") or [{}])[0]
            yr = (m.get("published-print") or m.get("published-online") or m.get("issued") or {}).get("date-parts", [[""]])[0][0]
            out.append((key, doi, "", f"{a.get('family', '')} {a.get('given', '')}".strip(), str(yr),
                        (m.get("container-title") or [""])[0], strip_tags((m.get("title") or [""])[0]), what, f"Crossref {TODAY}"))
        else:
            out.append((key, doi, "", "", "", "", "", what, "NOT FOUND: UNVERIFIED"))
    with open(OUT / "references_checked.tsv", "w") as f:
        f.write("key\tdoi\tpmid\tfirst_author\tyear\tjournal\ttitle\tused_for\tchecked\n")
        for row in out:
            f.write("\t".join(str(x).replace("\t", " ").replace("\n", " ") for x in row) + "\n")
    for row in out:
        print(f"{row[0]:15} {row[2]:>9} {row[4]:5} {row[3][:22]:22} {row[6][:80]}  [{row[8]}]")


# ---------------------------------------------------------------------------------------------
# curies: OLS4 label and obsolete flag for every CURIE used
# ---------------------------------------------------------------------------------------------

def used_curies():
    cs = set(EXTRA_CURIES)
    for cur, _ in TRAIT.values():
        for x in (cur or "").split("|"):
            if x:
                cs.add(x)
    return sorted(cs)


def cmd_curies(_args):
    out = []
    for c in used_curies():
        pre = c.split(":")[0].lower()
        d = cached("ols_" + safe(c) + ".json",
                   lambda c=c: http_get("https://www.ebi.ac.uk/ols4/api/terms?" + urllib.parse.urlencode({"obo_id": c})))
        ts = (d or {}).get("_embedded", {}).get("terms", [])
        if not ts and pre in ("ro", "bfo"):
            d = cached("olsprop_" + safe(c) + ".json", lambda c=c: http_get(
                "https://www.ebi.ac.uk/ols4/api/properties?" + urllib.parse.urlencode({"obo_id": c})))
            ts = (d or {}).get("_embedded", {}).get("properties", [])
        t = next((x for x in ts if x.get("ontology_name") == pre), ts[0] if ts else None)
        if not t:
            out.append((c, "", "", "NOT FOUND"))
            continue
        out.append((c, t.get("label", ""), "obsolete" if t.get("is_obsolete") else "",
                    f"OLS4 {t.get('ontology_name')} {TODAY}"))
    with open(OUT / "curies_checked.tsv", "w") as f:
        f.write("curie\tlabel\tobsolete\tchecked\n")
        for row in out:
            f.write("\t".join(row) + "\n")
    for row in out:
        print("\t".join(row))


# ---------------------------------------------------------------------------------------------
# quickgo: experimental annotations (ECO:0000269 and descendants) for each qgo: record
# ---------------------------------------------------------------------------------------------

def qgo_pairs():
    ps = set()
    for c in CASES:
        for r in c.get("recs", []) + c.get("withhold", []) + c.get("own", []):
            if r[2].startswith("qgo:"):
                ps.add((TRAIT[r[2][4:]][0], r[0]))
    return sorted(ps)


def cmd_quickgo(_args):
    out = []
    for go, tax in qgo_pairs():
        q = {"goId": go, "taxonId": tax, "taxonUsage": "descendants", "goUsage": "descendants",
             "goUsageRelationships": "is_a,part_of,occurs_in", "evidenceCode": "ECO:0000269",
             "evidenceCodeUsage": "descendants", "limit": 1}
        d = cached(f"quickgo_{safe(go)}_{tax}.json",
                   lambda q=q: http_get("https://www.ebi.ac.uk/QuickGO/services/annotation/search?" + urllib.parse.urlencode(q)))
        out.append((go, tax, (d or {}).get("numberOfHits", "ERROR")))
        time.sleep(0.3)
    with open(OUT / "quickgo_counts.tsv", "w") as f:
        f.write(f"# QuickGO {TODAY}: annotations with ECO:0000269 or a descendant (experimental), to the term or a descendant by is_a, part_of, occurs_in, in the taxon or a descendant.\n")
        f.write("go\ttaxon\texperimental_annotations\n")
        for row in out:
            f.write("\t".join(map(str, row)) + "\n")
    for row in out:
        print(*row)



# ---------------------------------------------------------------------------------------------
# The sketch: options (b) and (b)+(k), program 01 section 5 and E10.
#
# Opinions are (belief, disbelief, uncertainty) as exact fractions. `fuse` and `verdict` are
# BioLean's (`Opinion.fuse`, `Opinion.verdict`, theta 4/5, tau 1/4). `conj` is new: binomial
# multiplication (Josang and McAnally 2005) without the base-rate terms, so it carries disbelief,
# which BioLean's `chain` does not.
#
#  1. Ancestor rule (Witmer). The bracket of a node N is the nearest groups of records around it:
#     N's inner sides (children of N holding records) if there are two or more, else outgroups
#     walking up N's lineage until two groups are found. Groups at one node (a polytomy) are all
#     equally near and all count. A group shows the trait if any record in it is `has`. Level I if
#     at least two groups show it and they are a majority, II if one does (or a minority), III if
#     none does. If the inner sides disagree, the first outgroup level is added, as Fitch
#     parsimony would. (b)+(k) only: positive groups recorded as convergent count as one origin
#     between them, so the node between lacked it (level III).
#  2. Dollo default. Gained once, lost many times. The ancestor lookup is the bracket node; the set
#     difference is "every lineage below it, minus the lineages with a loss record". No regain:
#     an ancestor that lacked the trait gives disbelief whatever the retention.
#  3. Retention. "Every member of T has X" = ancestor rule AND retention (`conj`). A loss record
#     (lacks or lost) inside T replaces retention for T: it does not fuse with the default.
#     (b): no loss record gives a vacuous retention. (b)+(k): the descent default (0.9, 0, 0.1).
#  4. Own records. A record at T or at a clade containing T is an observation of T and replaces
#     the inference; the most specific wins; several sources on one lineage fuse.
#  5. Homology. "X in A and B comes from their common ancestor" = the bracket at LCA(A, B). In
#     (b)+(k) a convergence record (HOM:0000004) between A and B replaces it with disbelief.
#  6. Narrowing goes through retention: "S has X" is computed for S, never copied from a clade.
# ---------------------------------------------------------------------------------------------

PARAMS = dict(I=F(9, 10), II=F(1, 2), III=F(9, 10), default=F(9, 10), record=F(4, 5))
THETA, TAU = F(4, 5), F(1, 4)
VAC = (F(0), F(0), F(1))


def op_b(b):
    return (b, F(0), 1 - b)


def op_d(d):
    return (F(0), d, 1 - d)


def fuse(x, y):
    k = x[2] + y[2] - x[2] * y[2]
    return ((x[0] * y[2] + y[0] * x[2]) / k, (x[1] * y[2] + y[1] * x[2]) / k, x[2] * y[2] / k)


def conj(x, y):
    b = x[0] * y[0]
    d = x[1] + y[1] - x[1] * y[1]
    return (b, d, 1 - b - d)


def neg(x):
    return (x[1], x[0], x[2])


def verdict(o):
    if o[0] >= TAU and o[1] >= TAU:
        return "contested"
    if o[0] >= THETA:
        return "established"
    if o[1] >= THETA:
        return "refuted"
    return "unsupported"


def level_op(lvl, P):
    return {"I": op_b(P["I"]), "II": op_b(P["II"]), "III": op_d(P["III"])}[lvl]


class Sketch:
    def __init__(self, taxa, P=PARAMS, agree_fuses=False, one_side_vacuous=False):
        self.T, self.P, self.agree_fuses, self.one_side_vacuous = taxa, P, agree_fuses, one_side_vacuous
        # every node on a fetched lineage gets its own path (a prefix of that lineage)
        self.paths = {}
        for v in taxa.values():
            lin = v["lineage"]
            for i, x in enumerate(lin):
                self.paths.setdefault(x, lin[:i + 1])

    # taxonomy (NCBI lineages)
    def path(self, t):
        return self.paths[t]

    def under(self, a, b):
        return b in self.path(a)

    def depth(self, t):
        return len(self.path(t))

    def lca(self, ts):
        ps = [self.path(t) for t in ts]
        out = None
        for i, x in enumerate(ps[0]):
            if all(len(p) > i and p[i] == x for p in ps):
                out = x
            else:
                break
        return out

    def child_toward(self, node, t):
        p = self.path(t)
        return p[p.index(node) + 1]

    def name(self, t):
        for v in self.T.values():
            if t in v["names"]:
                return v["names"][t]
        return str(t)

    # records
    def rec_op(self, recs):
        o, seen = VAC, set()
        for r in recs:
            if r in seen:
                continue
            seen.add(r)
            o = fuse(o, op_b(self.P["record"]) if r[1] == "has" else op_d(self.P["record"]))
        return o

    def inner_groups(self, N, recs):
        g = {}
        for r in recs:
            if r[0] != N and self.under(r[0], N):
                g.setdefault(self.child_toward(N, r[0]), []).append(r)
        return list(g.values())

    def outgroup_levels(self, N, recs):
        p = self.path(N)
        for i in range(len(p) - 2, -1, -1):
            node, child = p[i], p[i + 1]
            g = {}
            for r in recs:
                if r[0] != node and self.under(r[0], node) and not self.under(r[0], child):
                    g.setdefault(self.child_toward(node, r[0]), []).append(r)
            if g:
                yield node, list(g.values())

    def conv_groups(self, g, h, conv):
        xs = [r[0] for r in g if r[1] == "has"]
        ys = [r[0] for r in h if r[1] == "has"]
        return any((self.under(x, a) and self.under(y, b)) or (self.under(x, b) and self.under(y, a))
                   for a, b, _ in conv for x in xs for y in ys)

    def witmer(self, N, recs, conv):
        groups = self.inner_groups(N, recs)
        tag = "inner" if len(groups) >= 2 else "outgroups"
        outs = self.outgroup_levels(N, recs)
        pos = lambda gs: [g for g in gs if any(r[1] == "has" for r in g)]
        if len(groups) >= 2 and 0 < len(pos(groups)) < len(groups):
            for _, gs in outs:
                groups = groups + gs
                tag = "inner+outgroup"
                break
        while len(groups) < 2:
            nxt = next(outs, None)
            if nxt is None:
                break
            groups = groups + nxt[1]
        n, ps = len(groups), pos(groups)
        p = len(ps)
        if conv and p >= 2:
            keep = []
            for g in ps:
                if not any(self.conv_groups(g, h, conv) for h in keep):
                    keep.append(g)
            if len(keep) == 1:
                p, tag = 0, tag + ", convergent"
            else:
                p = len(keep)
        if n == 0 or (n == 1 and self.one_side_vacuous):
            return VAC, "no bracket" if n == 0 else "one side only: no bracket"
        lvl = "I" if (p >= 2 and 2 * p > n) else "II" if p >= 1 else "III"
        return level_op(lvl, self.P), f"{lvl} ({tag}, {p}/{n} groups)"

    # claim forms. v is "b", "k" (defeat: a record replaces the inference) or "kf" (review
    # variant: the descent default kept, but every record fuses with the inference, as
    # `Derivation.clash` does in today's core; no defeat rule)
    def has(self, T, recs, conv, v):
        kk = v in ("k", "kf")
        own = [r for r in recs if self.under(T, r[0])]
        if own and v == "kf":
            d = max(self.depth(r[0]) for r in own)
            o = self.rec_op([r for r in own if self.depth(r[0]) == d])
            inferred, why = self.has(T, [r for r in recs if r not in own], conv, v)
            return fuse(o, inferred), f"own record fused with: {why}"
        if own:
            d = max(self.depth(r[0]) for r in own)
            own = [r for r in own if self.depth(r[0]) == d]
            o = self.rec_op(own)
            negs = [r for r in recs if r[0] != T and self.under(r[0], T) and r[1] != "has"]
            if negs:
                return fuse(o, self.rec_op(negs)), "own record"
            if v == "k" and self.agree_fuses and all(r[1] == "has" for r in own):
                # the fix tested in the coherence check: a record that agrees with the default fuses
                # with the inference from the other records; only a contradicting record replaces it
                inferred, _ = self.has(T, [r for r in recs if r not in own], conv, v)
                if inferred[1] == 0:
                    return fuse(o, inferred), "own record, fused with the default"
            return o, "own record"
        anc, lvl = self.witmer(T, recs, conv if kk else [])
        negs = [r for r in recs if r[0] != T and self.under(r[0], T) and r[1] != "has"]
        if negs and v == "kf":
            ret, rt = fuse(op_b(self.P["default"]), self.rec_op(negs)), "loss record fused with the default"
        elif negs:
            ret, rt = self.rec_op(negs), "loss record"
        else:
            ret, rt = (op_b(self.P["default"]), "default") if kk else (VAC, "no retention premise")
        return conj(anc, ret), f"{lvl}; retention: {rt}"

    def homol(self, A, B, recs, conv, v):
        anc, lvl = self.witmer(self.lca([A, B]), recs, [])
        if v in ("k", "kf"):
            cs = [c for c in conv if (self.under(A, c[0]) and self.under(B, c[1])) or
                  (self.under(A, c[1]) and self.under(B, c[0]))]
            if cs and v == "kf":
                return fuse(self.rec_op([(0, "lacks", c[2]) for c in cs]), anc), "convergence record fused with the bracket"
            if cs:
                return self.rec_op([(0, "lacks", c[2]) for c in cs]), "convergence record"
        return anc, f"bracket at LCA: {lvl}"

    def never(self, Ss, recs, conv, v):
        o, tags = None, []
        for S in Ss:
            relic = [r for r in recs if self.under(r[0], S) and r[1] == "lost"]
            anc, t = self.witmer(S, [r for r in recs if not self.under(r[0], S)], [])
            if relic and v == "kf":
                x, t = fuse(self.rec_op(relic), neg(anc)), "relic record fused with the bracket"
            elif relic:
                x, t = self.rec_op(relic), "relic record"
            else:
                x = neg(anc)
            o = x if o is None else conj(o, x)
            tags.append(t)
        return o, "; ".join(tags)

    def none(self, T, recs, conv, v):
        kk = v in ("k", "kf")
        hits = [r for r in recs if self.under(r[0], T) and r[1] == "has"]
        anc, lvl = self.witmer(T, recs, conv if kk else [])
        inferred = conj(neg(anc), op_b(self.P["default"]) if kk else VAC)
        if hits and v == "kf":
            return fuse(neg(self.rec_op(hits)), inferred), "record of the trait inside, fused with the default"
        if hits:
            return neg(self.rec_op(hits)), "record of the trait inside"
        return inferred, f"{lvl}; no gain: {'default' if kk else 'no premise'}"

    def evaluate(self, row, v):
        f, recs, conv = row["form"], row["recs"], row["conv"]
        if f[0] == "X":
            return None, f[1]
        if f[0] == "has":
            return self.has(f[1], recs, conv, v)
        if f[0] == "homol":
            return self.homol(f[1], f[2], recs, conv, v)
        if f[0] == "never":
            return self.never(f[1], recs, conv, v)
        if f[0] == "none":
            return self.none(f[1], recs, conv, v)
        raise ValueError(f)

    def nearest(self, row):
        """Review baseline for predict rows, 'always agree' read literally: the target has what
        its nearest recorded relatives have. Take the first node up the target's lineage that holds
        records outside it; each child group there votes has (any `has`) or not; majority decides,
        a tie is silent. A homology question between two taxa that both have the trait is 'yes'.
        Returns True, False or None."""
        f, recs = row["form"], row["recs"]
        if f[0] == "homol":
            return True
        if f[0] != "has":
            return None
        for _, gs in self.outgroup_levels(f[1], recs):
            p = sum(1 for g in gs if any(r[1] == "has" for r in g))
            if 2 * p != len(gs):
                return 2 * p > len(gs)
            return None
        return None

    def narrowed(self, row, v):
        """`has` with narrowing as a logical step: the best of T and every clade above it."""
        f = row["form"]
        if f[0] != "has":
            return self.evaluate(row, v)[0]
        best = self.has(f[1], row["recs"], row["conv"], v)[0]
        for M in self.path(f[1])[:-1]:
            b = self.has(M, row["recs"], row["conv"], v)[0][0]
            if b > best[0]:
                best = op_b(b)    # a logical step carries belief only (BioLean's `weakest`)
        return best

    def coherence(self, row, v, narrow=False):
        """Every pair of nodes (narrow, broad) on the record and target lineages: the broad claim
        "every member of broad has X" must not be believed more than the narrow one it implies."""
        if row["form"][0] == "X":
            return 0, []
        nodes = set()
        for r in row["recs"]:
            nodes.update(self.path(r[0]))
        f = row["form"]
        for t in (f[1:] if f[0] == "homol" else f[1] if f[0] == "never" else (f[1],)):
            nodes.update(self.path(t))
        vals = {N: self.has(N, row["recs"], row["conv"], v) for N in nodes}
        if narrow:
            # narrowing as a logical step: a node also gets the belief of every clade above it
            vals = {N: (max((vals[M] for M in self.path(N) if M in vals), key=lambda x: x[0][0]), )[0]
                    if max(vals[M][0][0] for M in self.path(N) if M in vals) > vals[N][0][0] else vals[N]
                    for N in nodes}
        pairs, bad = 0, []
        for a in nodes:
            for b in self.path(a):
                if b != a and b in nodes:
                    pairs += 1
                    if vals[b][0][0] > vals[a][0][0]:
                        kind = "record vs default" if vals[a][1].startswith("own record") else "bracket"
                        bad.append((b, a, vals[b][0][0], vals[a][0][0], kind))
        return pairs, bad


def letter(truth, o):
    if o is None:
        return "X"
    vd = verdict(o)
    if vd == "unsupported":
        return "S"
    if vd == "contested":
        return "C"
    if truth == "mixed":
        return "W"
    return "R" if (vd == "established") == truth else "W"


MARK = {"R": "PASS", "W": "FAIL", "S": "SILENT", "C": "SILENT", "X": "INEXPRESSIBLE"}


def mark_of(truth, let):
    if truth == "mixed" and let == "C":
        return "INEXPRESSIBLE"
    return MARK[let]


def fmt(o):
    return "-" if o is None else f"b={float(o[0]):.3f} d={float(o[1]):.3f} u={float(o[2]):.3f}"


def target_name(sk, f):
    if f[0] == "X":
        return "-"
    if f[0] == "has" or f[0] == "none":
        return sk.name(f[1])
    if f[0] == "homol":
        return f"{sk.name(f[1])} and {sk.name(f[2])}"
    return ", ".join(sk.name(t) for t in f[1])


def claim_text(sk, row):
    f, tr = row["form"], TRAIT[row["trait"]][1]
    if f[0] == "has":
        return f"every {sk.name(f[1])} has: {tr}"
    if f[0] == "none":
        return f"no {sk.name(f[1])} has: {tr}"
    if f[0] == "homol":
        return f"{tr} in {sk.name(f[1])} and in {sk.name(f[2])} comes from their common ancestor"
    if f[0] == "never":
        return f"the ancestors of {', '.join(sk.name(t) for t in f[1])} never had: {tr}"
    return f"{tr} ({f[1]})"


def inputs_text(sk, row):
    rs = [f"{sk.name(r[0])} [NCBITaxon:{r[0]}] {r[1]} ({r[2]})" for r in row["recs"]]
    cs = [f"convergent: {sk.name(a)} / {sk.name(b)} ({s})" for a, b, s in row["conv"]]
    return "; ".join(rs + cs) or "-"


def cmd_run(_args):
    taxa = load_taxa()
    sk = Sketch(taxa)
    sk_agree = Sketch(taxa, agree_fuses=True)
    rws = rows()
    res = []
    for row in rws:
        out = dict(row)
        for v in ("b", "k"):
            o, why = sk.evaluate(row, v)
            out[v] = (o, why, letter(row["truth"], o))
            out[v + "_narrow"] = letter(row["truth"], sk.narrowed(row, v) if o is not None else None)
            out[v + "_coh"] = sk.coherence(row, v)
        o_ag, _ = sk_agree.evaluate(row, "k")
        out["kagree"] = (o_ag, letter(row["truth"], o_ag))
        o_kf, why_kf = sk.evaluate(row, "kf")
        out["kf"] = (o_kf, why_kf, letter(row["truth"], o_kf))
        out["kagree_coh"] = sk_agree.coherence(row, "k")
        out["knarrow_coh"] = sk.coherence(row, "k", narrow=True)
        res.append(out)
    # sensitivity: move each value by 0.1, count verdict flips (b, k)
    sens = []
    for key in PARAMS:
        for delta in (F(-1, 10), F(1, 10)):
            P2 = dict(PARAMS)
            val = PARAMS[key] + delta
            capped = val >= 1
            P2[key] = min(val, F(99, 100))
            sk2 = Sketch(taxa, P2)
            flips = {"b": [], "k": []}
            for row, out in zip(rws, res):
                for v in ("b", "k"):
                    o2, _ = sk2.evaluate(row, v)
                    if o2 is not None and verdict(o2) != verdict(out[v][0]):
                        flips[v].append(f"{row['id']}:{verdict(out[v][0])}->{verdict(o2)}")
            sens.append((key, float(PARAMS[key]), float(P2[key]), capped, flips))
    # write sketch.tsv
    with open(OUT / "sketch.tsv", "w") as f:
        f.write("id\tcase\tmode\tgiven\tclaim\ttruth\tinputs\t"
                "b_opinion\tb_verdict\tb_letter\tb_why\tk_opinion\tk_verdict\tk_letter\tk_why\t"
                "b_narrow_letter\tk_narrow_letter\tb_coherence\tk_coherence\tkf_opinion\tkf_letter\tkf_why\n")
        for out in res:
            cols = [out["id"], out["case"], out["mode"], out["given"], claim_text(sk, out), str(out["truth"]),
                    inputs_text(sk, out)]
            for v in ("b", "k"):
                o, why, let = out[v]
                cols += [fmt(o), verdict(o) if o is not None else "-", let, why]
            cols += [out["b_narrow"], out["k_narrow"]]
            for v in ("b", "k"):
                pairs, bad = out[v + "_coh"]
                cols.append(f"{len(bad)}/{pairs}")
            cols += [fmt(out["kf"][0]), out["kf"][2], out["kf"][1]]
            f.write("\t".join(cols) + "\n")
    with open(OUT / "sensitivity.tsv", "w") as f:
        f.write("value\tbase\tmoved_to\tcapped_at_0.99\tflips_b\tflips_k\trows_k\trows_b\n")
        for key, base, moved, capped, flips in sens:
            f.write(f"{key}\t{base}\t{moved}\t{capped}\t{len(flips['b'])}\t{len(flips['k'])}\t"
                    f"{' '.join(flips['k'])}\t{' '.join(flips['b'])}\n")
    with open(OUT / "coherence.tsv", "w") as f:
        f.write("id\tvariant\tpairs\tviolations\trecord_vs_default\tbracket\texamples (broad > narrow, beliefs)\n")
        for out in res:
            for v in ("b", "k", "kagree", "knarrow"):
                pairs, bad = out[v + "_coh"]
                nrd = sum(1 for x in bad if x[4] == "record vs default")
                ex = "; ".join(f"{sk.name(b)} {float(x):.3f} > {sk.name(a)} {float(y):.3f} [{k}]" for b, a, x, y, k in bad[:4])
                f.write(f"{out['id']}\t{v}\t{pairs}\t{len(bad)}\t{nrd}\t{len(bad) - nrd}\t{ex}\n")
    # tallies
    def tally(sel, key):
        t = {}
        for out in sel:
            t[out[key][2] if isinstance(out[key], tuple) else out[key]] = t.get(out[key][2] if isinstance(out[key], tuple) else out[key], 0) + 1
        return t
    prog = [o for o in res if o["mode"] in ("U", "O", "P") and not o["case"].startswith("D")]
    newr = [o for o in res if o["case"].startswith("D")]
    summary = {
        "program01_rows": len(prog), "new_rows": len(newr), "all_rows": len(res),
        "program01": {v: tally(prog, v) for v in ("b", "k")},
        "program01_predict": {v: tally([o for o in prog if o["mode"] == "P"], v) for v in ("b", "k")},
        "program01_withheld": {v: tally([o for o in res if o["mode"] == "O-"], v) for v in ("b", "k")},
        "new_minus": {v: tally([o for o in newr if o["id"].endswith("-")], v) for v in ("b", "k")},
        "new_plus": {v: tally([o for o in newr if o["id"].endswith("+")], v) for v in ("b", "k")},
        "narrowing_changes": {v: [o["id"] for o in res if o[v][2] != o[v + "_narrow"]] for v in ("b", "k")},
        "coherence": {v: {"rows_with_violations": [o["id"] for o in res if o[v + "_coh"][1]],
                          "pairs": sum(o[v + "_coh"][0] for o in res),
                          "violations": sum(len(o[v + "_coh"][1]) for o in res),
                          "record_vs_default": sum(1 for o in res for x in o[v + "_coh"][1] if x[4] == "record vs default"),
                          "bracket": sum(1 for o in res for x in o[v + "_coh"][1] if x[4] == "bracket"),
                          "rows_bracket": sorted({o["id"] for o in res for x in o[v + "_coh"][1] if x[4] == "bracket"})}
                      for v in ("b", "k", "kagree", "knarrow")},
        "kagree_letter_changes": [o["id"] for o in res if o["kagree"][1] != o["k"][2]],
        "sensitivity": {f"{k}{'+' if m > b else '-'}": {"b": len(fl["b"]), "k": len(fl["k"])} for k, b, m, c, fl in sens},
    }
    pr = [o for o in prog if o["mode"] == "P"] + [o for o in newr if o["id"].endswith("-")]
    stateable = [o for o in pr if o["form"][0] != "X"]

    def base_letter(o, guess):
        return "S" if guess is None else "R" if guess == o["truth"] else "W"
    near = {o["id"]: base_letter(o, sk.nearest(o)) for o in stateable}
    summary["predict_all"] = {"rows": len(pr), "true": sum(1 for o in pr if o["truth"] is True),
                              "k_R": sum(1 for o in pr if o["k"][2] == "R"), "k_W": sum(1 for o in pr if o["k"][2] == "W"),
                              "k_S": sum(1 for o in pr if o["k"][2] in ("S", "C")),
                              "k_X": sum(1 for o in pr if o["k"][2] == "X"),
                              # 'always yes': the target has the trait, whatever its relatives show
                              "always_yes_R": sum(1 for o in stateable if o["truth"] is True),
                              "always_yes_W": sum(1 for o in stateable if o["truth"] is not True),
                              # 'nearest relatives': the target has what its nearest recorded relatives have
                              "nearest_R": sum(1 for x in near.values() if x == "R"),
                              "nearest_W": sum(1 for x in near.values() if x == "W"),
                              "nearest_S": sum(1 for x in near.values() if x == "S"),
                              "nearest_letters": near,
                              "k_letters": {o["id"]: o["k"][2] for o in pr}}
    # review variant: the descent default kept, records fused with it (no defeat rule)
    summary["kf"] = {"all": tally(res, "kf"), "program01": tally(prog, "kf"),
                     "new_plus": tally([o for o in newr if o["id"].endswith("+")], "kf"),
                     "program01_O_as_written": tally([o for o in prog if o["mode"] == "O"], "kf"),
                     "letters": {o["id"]: o["kf"][2] for o in res}}
    (OUT / "sketch_summary.json").write_text(json.dumps(summary, indent=1))
    for out in res:
        print(f"{out['id']:7} {out['mode']:3} truth={str(out['truth']):5} | b {out['b'][2]} {fmt(out['b'][0])} | "
              f"k {out['k'][2]} {fmt(out['k'][0])} | {out['k'][1]}")
    print(json.dumps(summary, indent=1))



# ---------------------------------------------------------------------------------------------
# table: merge the sketch with the Lean observations (BioLean/Stress/Descent.lean) into cases.tsv
# and the scorecard (program 01 section 8, predicted, against measured)
# ---------------------------------------------------------------------------------------------

# program 01 section 8, predicted cells for (b), (b)+(k), (c)
PREDICTED = {
    "U1": "SRR", "U2": "SRR", "LT1": "SRS", "N1": "SSS", "N2": "RRS", "N3": "RRS", "N4": "RRS",
    "L1": "RRS", "L2": "RRS", "L3": "RRS", "L4": "RRS", "L5": "RRS", "L6": "CCW", "L7": "SSS",
    "L8": "RR?", "L9": "RRS", "CV1": "WRS", "CV2": "WRS", "CV3": "WRS", "CV4": "WRS", "H1": "RRS",
    "A1": "RRS", "NT1": "SRR", "LT2": "SRS", "LT3": "SRS", "CVT1": "RRS", "CVT2": "RRS", "RMT1": "SRR",
    "RM1": "SWW", "RM2": "SWW", "RM3": "SWW", "RM4": "SRW", "RM5": "SWW",
}

PROBE = {
    "U1": "a true universal from six experimental instances", "U2": "a true universal (ribosomes)",
    "LT1": "a true universal over a clade with a monotreme instance", "N1": "a change on record inside the clade (mitochondrial code)",
    "N2": "the brake: the species' own changed code", "N3": "the brake: own changed code", "N4": "the brake: own changed code",
    "L1": "amitochondriate protist: loss with a relic", "L2": "amitochondriate protist: loss with a relic",
    "L3": "a eukaryote with no mitochondrial organelle", "L4": "mitochondrial gene loss after endosymbiosis (a count does not inherit)",
    "L5": "a universal with two recorded losses (GULO)", "L6": "two populations of one species (cave fish)",
    "L7": "an exception at cell-type level (enucleate red cell)", "L8": "a universal with a recorded loss (icefish)",
    "L9": "a universal with recorded losses (ENAM, toothless mammals)", "CV1": "convergence: camera eyes",
    "CV2": "convergence: echolocation", "CV3": "convergence: C4 photosynthesis", "CV4": "convergence: antifreeze glycoproteins",
    "H1": "a gain by gene transfer (aphid carotenoids)", "A1": "the Archezoa hypothesis (never had mitochondria)",
    "NT1": "predict: an unchanged species", "LT2": "predict: a trait kept by an amitochondriate protist",
    "LT3": "predict: a trait kept next to recorded losses", "CVT1": "predict: a true homology", "CVT2": "predict: a true homology",
    "RMT1": "predict: an unchanged organ", "RM1": "predict: a species that lost an organ (no record given)",
    "RM2": "predict: a species that changed (no record given)", "RM3": "predict: a species that changed (no record given)",
    "RM4": "predict: neighbours' losses on record", "RM5": "predict: a species that changed (no record given)",
    "D01": "amitochondriate protist (Entamoeba)", "D02": "an animal without mitochondrial DNA (Henneguya)",
    "D03": "mitochondrial complex I lost (yeast)", "D04": "mitochondrial gene moved to the nucleus (soybean cox2)",
    "D05": "GULO pseudogene, neighbours' losses on record (chimpanzee)", "D06": "CMAH pseudogene in one species (human)",
    "D07": "tooth loss with pseudogenes (birds)", "D08": "globin loss with remnants (icefish)",
    "D09": "plastid photosynthesis genes lost (Epifagus)", "D10": "convergence: caffeine synthesis",
    "D11": "convergence used in prediction (synthetic)", "D12": "a convergent gain (Typhlomys echolocation)",
    "D13": "convergence within one species (lactase persistence)", "D14": "re-evolution after loss (Dollo broken)",
    "D15": "a true retention (mtDNA cytochrome b)", "TB1": "free narrowing of a textbook universal",
    "TB2": "free narrowing of a textbook universal, hedged in R3", "TB3": "free narrowing of a textbook universal, hedged in R3",
    "TB4": "free narrowing of a textbook universal (right)",
}

CORRECT = {
    "U1": "true: all cellular organisms transcribe DNA with multisubunit RNA polymerases",
    "U2": "true: every cellular organism has ribosomes", "LT1": "true: all mammals lactate, monotremes too",
    "N1": "false: vertebrate mitochondria use code 2", "N2": "false: Mycoplasma capricolum reads UGA as Trp (code 4)",
    "N3": "false: Paramecium reads UAA and UAG as Gln (code 6)", "N4": "false: Candida albicans reads CUG as Ser (code 12)",
    "L1": "false: Giardia has mitosomes, remnant organelles", "L2": "false: Trichomonas has hydrogenosomes",
    "L3": "false: Monocercomonoides has no mitochondrial organelle", "L4": "false: human mtDNA has 37 genes and no rpo genes",
    "L5": "false: haplorhine primates and guinea pigs cannot make vitamin C", "L6": "mixed: surface fish have eyes, cave fish do not",
    "L7": "false: mature mammalian red cells have no nucleus", "L8": "false: icefishes have no haemoglobin",
    "L9": "false: baleen whales and pangolins have no teeth", "CV1": "false: convergent", "CV2": "false: convergent",
    "CV3": "false: C4 arose in about 62 lineages", "CV4": "false: convergent", "H1": "false: aphids make carotenoids",
    "A1": "false: all four lineages carry relics of a mitochondrion", "NT1": "true: code 1", "LT2": "true: Giardia has an actin cytoskeleton",
    "LT3": "true: mice make vitamin C", "CVT1": "true", "CVT2": "true", "RMT1": "true", "RM1": "false: rats have no gallbladder",
    "RM2": "false: mouse activated T cells lack MHC class II", "RM3": "false: mouse macrophages lack CD4",
    "RM4": "false: rats cannot vomit", "RM5": "false: per UBERON (JAX Green Book), mice lack splenic sinusoids",
    "D01": "false: Entamoeba has a mitosome and relic genes", "D02": "false: Henneguya has no mitochondrial genome",
    "D03": "false: S. cerevisiae has no complex I", "D04": "false: soybean's mitochondrial cox2 is silent; the active copy is nuclear",
    "D05": "false: chimpanzee GULO is a pseudogene", "D06": "false: human CMAH carries a 92-bp deletion",
    "D07": "false: modern birds have no mineralised teeth", "D08": "false: icefishes have no haemoglobin",
    "D09": "false: Epifagus' plastid lacks every photosynthesis gene", "D10": "false: caffeine synthesis evolved separately",
    "D11": "false: cattle do not echolocate", "D12": "true: Typhlomys echolocates",
    "D13": "false: the African and European alleles arose separately", "D14": "true: Gastrotheca guentheri has mandibular teeth",
    "D15": "true: mouse mtDNA encodes cytochrome b", "TB1": "false: Epifagus does not photosynthesise",
    "TB2": "false: Epifagus' plastid is not a chloroplast", "TB3": "false: baleen whales have no teeth",
    "TB4": "true: mistletoe has mitochondria (it lost complex I, not the organelle)",
}

TB_INPUT = {
    "TB1": "R2 photosynthesis-m45453-100 'plants are capable of photosynthesis' (NCBITaxon:33090 RO:0002215 GO:0015979); Epifagus virginiana [NCBITaxon:4177] is_a Viridiplantae",
    "TB2": "R2/R3 photosynthesis-m45453-72 'plants have chloroplasts' (NCBITaxon:33090 BFO:0000051 GO:0009507; R3 `most`); Epifagus is_a Viridiplantae",
    "TB3": "R2/R3 the-body-s-systems-m45535-39 'All mammals have teeth' (NCBITaxon:40674 BFO:0000051 UBERON:0001091; R3 `most`); Mysticeti [NCBITaxon:9761] is_a Mammalia",
    "TB4": "R2 photosynthesis-m45453-71 'plants have mitochondria' (NCBITaxon:33090 BFO:0000051 GO:0005739); Viscum album [NCBITaxon:3972] is_a Viridiplantae",
}
TB_TRUTH = {"TB1": False, "TB2": False, "TB3": False, "TB4": True}
TB_SRC = {"TB1": "wolfe1992", "TB2": "wolfe1992", "TB3": "meredith2009", "TB4": "senkler2018"}


def read_obs():
    out = {}
    for line in open(OUT / "lean_output.txt"):
        if not line.startswith("OBS\t"):
            continue
        f = line.rstrip("\n").split("\t")
        c, frm, core, note = f[2][2:], f[3][5:], f[4][5:], f[5] if len(f) > 5 else ""
        out[f[1]] = dict(c=c, frm=frm, core=core, note=note)
    return out


def lean_letter(truth, v):
    if v == "none" or v.startswith("none"):
        return "S"
    vd = v.split()[0]
    if vd == "unsupported":
        return "S"
    if vd == "contested":
        return "C"
    if truth == "mixed":
        return "W"
    return "R" if (vd == "established") == truth else "W"


def refs_index():
    idx = {}
    for line in open(OUT / "references_checked.tsv"):
        f = line.rstrip("\n").split("\t")
        if f[0] == "key":
            continue
        idx[f[0]] = f
    return idx


def cite(key, refs):
    if key.startswith("qgo:"):
        return f"QuickGO experimental annotations ({TRAIT[key[4:]][0]})"
    if key.startswith("ncbi:"):
        return "NCBI Taxonomy genetic code field"
    if key in ("general", "synthetic"):
        return key
    f = refs.get(key)
    if not f or not f[1]:
        return key + " (UNVERIFIED)" if key == "witmer1995" else key
    first = f[3].split()[0] if f[3] else key
    return f"{first} {f[4]}, PMID {f[2]}, doi:{f[1]}" if f[2] else f"{first} {f[4]}, doi:{f[1]}"


def cmd_table(_args):
    taxa = load_taxa()
    sk = Sketch(taxa)
    obs = read_obs()
    refs = refs_index()
    sketch = {}
    for line in open(OUT / "sketch.tsv"):
        f = line.rstrip("\n").split("\t")
        if f[0] == "id":
            head = f
            continue
        sketch[f[0]] = dict(zip(head, f))
    rws = {r["id"]: r for r in rows()}
    out_rows, score = [], []
    for rid, r in rws.items():
        s_ = sketch[rid]
        o = obs[rid]
        truth = r["truth"]
        lc, lcore = lean_letter(truth, o["c"]), lean_letter(truth, o["core"])
        if o["note"].startswith("INEXPRESSIBLE"):
            lc = lcore = "X"
        mark = mark_of(truth, lcore)
        srcs = sorted({x[2] for x in r["recs"]} | {c[2] for c in r["conv"]} | {r["src"]})
        case = r["case"]
        kind = "synthetic" if r["src"] == "synthetic" else "real"
        observed = f"core: {o['core']}" + (f"; (c): {o['c']} from {o['frm']}" if o["c"] != "none" else "; (c): no derivation") + (f"; {o['note']}" if o["note"] else "")
        tests = ("BioLean/Stress/Descent.lean `verdicts` pin"
                 + (", theorems" if case in ("RM1", "D06", "D15", "U2", "D07") else "")
                 + (", homolRow and the RO.chainOK pin" if case.startswith("CV") or case == "D10" else "")
                 + (", h1Claim pin" if case == "H1" else "")
                 + (", review #guard on the fused opinion" if rid == "L1" else "")
                 + "; descent_sketch.py run, check")
        out_rows.append([rid, kind, PROBE.get(case, ""), f"{claim_text(sk, r)} | given: {r['given']} | {inputs_text(sk, r)}",
                         f"{CORRECT[case]} ({cite(r['src'], refs)})", observed, mark,
                         f"{s_['b_verdict']} {s_['b_opinion']} [{s_['b_why']}]", MARK[s_["b_letter"]] if not (truth == 'mixed' and s_['b_letter'] == 'C') else 'INEXPRESSIBLE',
                         f"{s_['k_verdict']} {s_['k_opinion']} [{s_['k_why']}]", MARK[s_["k_letter"]] if not (truth == 'mixed' and s_['k_letter'] == 'C') else 'INEXPRESSIBLE',
                         lc, s_["b_letter"], s_["k_letter"], tests, "; ".join(cite(x, refs) for x in srcs)])
        if case in PREDICTED and r["mode"] in ("U", "O", "P"):
            pb, pk, pc = PREDICTED[case]
            score.append([case, str(truth), pb, s_["b_letter"], pk, s_["k_letter"], pc, lc])
    for tb in ("TB1", "TB2", "TB3", "TB4"):
        o = obs[tb]
        lcore = lean_letter(TB_TRUTH[tb], o["core"])
        out_rows.append([tb, "textbook", PROBE[tb], TB_INPUT[tb], f"{CORRECT[tb]} ({cite(TB_SRC[tb], refs)})",
                         f"core: {o['core']}; {o['note']}", mark_of(TB_TRUTH[tb], lcore), "-", "-", "-", "-", lcore, "-", "-",
                         "BioLean/Stress/Descent.lean `verdicts textbookRows`" + (", tb1_epifagus" if tb == "TB1" else ", tb4_viscum" if tb == "TB4" else ", #check_failure"),
                         cite(TB_SRC[tb], refs)])
    with open(OUT / "cases.tsv", "w") as f:
        f.write("id\tkind\tprobes\tinput\tcorrect\tobserved\tmark\tobserved_b\tmark_b\tobserved_bk\tmark_bk\t"
                "letter_c\tletter_b\tletter_bk\ttest\tsource\n")
        for row in out_rows:
            f.write("\t".join(x.replace("\t", " ") for x in row) + "\n")
    with open(OUT / "scorecard.tsv", "w") as f:
        f.write("# program 01 section 8 (predicted) against measured. R right, W wrong, S silent (X: cannot state, counted as S), C contested, ? predicted unknown.\n")
        f.write("case\ttruth\tb_predicted\tb_measured\tbk_predicted\tbk_measured\tc_predicted\tc_measured\n")
        for row in score:
            f.write("\t".join(row) + "\n")
    # tallies
    def T(col):
        t = {}
        for row in score:
            x = row[col]
            x = "S" if x == "X" else x
            t[x] = t.get(x, 0) + 1
        return t
    print("scorecard, 33 cases:")
    for name, col in (("b pred", 2), ("b meas", 3), ("bk pred", 4), ("bk meas", 5), ("c pred", 6), ("c meas", 7)):
        print(f"  {name:8} {T(col)}")
    diffs = [(r[0], f"b {r[2]}->{r[3]}" if r[2] != r[3].replace('X', 'S') else "", f"bk {r[4]}->{r[5]}" if r[4] != r[5].replace('X', 'S') else "",
              f"c {r[6]}->{r[7]}" if r[6] != r[7].replace('X', 'S') else "") for r in score]
    print("cells that differ:", [d for d in diffs if any(d[1:])])
    marks = {}
    for row in out_rows:
        marks[row[6]] = marks.get(row[6], 0) + 1
    print("core marks over", len(out_rows), "rows:", marks)
    for col, name in ((8, "b"), (10, "bk")):
        m = {}
        for row in out_rows:
            if row[col] != "-":
                m[row[col]] = m.get(row[col], 0) + 1
        print(f"{name} marks:", m)
    # tallies.json: marks by group, for the doc's tables (written here so they can be reproduced)
    def group(rid):
        if rid.startswith("TB"):
            return "textbook"
        if rid.startswith("D"):
            return "new given" if rid.endswith("+") else "new withheld"
        return "p01 withheld" if rid.endswith("-") else "p01"
    by = {}
    for row in out_rows:
        for col, name in ((6, "mark"), (8, "mark_b"), (10, "mark_bk")):
            t = by.setdefault(f"{group(row[0])}|{name}", {})
            t[row[col]] = t.get(row[col], 0) + 1
    tallies = {"core_marks": marks, "by_group": by,
               "scorecard": {name: T(col) for name, col in (("b_pred", 2), ("b_meas", 3), ("bk_pred", 4),
                                                            ("bk_meas", 5), ("c_pred", 6), ("c_meas", 7))},
               "sketch": json.loads((OUT / "sketch_summary.json").read_text())}
    (OUT / "tallies.json").write_text(json.dumps(tallies, indent=1))


# ---------------------------------------------------------------------------------------------
# check: the numbers the doc reports, pinned. Re-runs `run` and `table` (deterministic; they
# rewrite data/stress/01b/), then asserts. Run after `lake env lean ... > lean_output.txt`.
# ---------------------------------------------------------------------------------------------

EXPECTED = {
    ("sketch", "program01", "k"): {"R": 26, "W": 4, "C": 1, "S": 1, "X": 1},
    ("sketch", "program01", "b"): {"R": 16, "W": 4, "C": 1, "S": 11, "X": 1},
    ("sketch", "new_plus", "k"): {"R": 14, "X": 1},
    ("sketch", "new_minus", "k"): {"W": 10, "R": 2, "S": 2, "X": 1},
    ("sketch", "narrowing_changes", "k"): [],
    ("sketch", "coherence", "b", "violations"): 0,
    ("sketch", "coherence", "k", "pairs"): 58949,
    ("sketch", "coherence", "k", "violations"): 2977,
    ("sketch", "coherence", "k", "record_vs_default"): 2220,
    ("sketch", "coherence", "k", "bracket"): 757,
    ("sketch", "coherence", "kagree", "violations"): 757,
    ("sketch", "coherence", "knarrow", "violations"): 0,
    ("sketch", "sensitivity"): {"I-": {"b": 0, "k": 25}, "I+": {"b": 0, "k": 0}, "II-": {"b": 0, "k": 0},
                                "II+": {"b": 0, "k": 0}, "III-": {"b": 0, "k": 1}, "III+": {"b": 0, "k": 0},
                                "default-": {"b": 0, "k": 26}, "default+": {"b": 0, "k": 0},
                                "record-": {"b": 21, "k": 26}, "record+": {"b": 0, "k": 0}},
    ("sketch", "predict_all", "k_R"): 8, ("sketch", "predict_all", "k_W"): 14,
    ("sketch", "predict_all", "k_S"): 3, ("sketch", "predict_all", "k_X"): 1,
    ("sketch", "predict_all", "always_yes_R"): 9, ("sketch", "predict_all", "always_yes_W"): 16,
    ("sketch", "predict_all", "nearest_R"): 9, ("sketch", "predict_all", "nearest_W"): 16,
    ("sketch", "predict_all", "nearest_S"): 0,
    ("sketch", "kf", "program01"): {"R": 11, "C": 14, "W": 4, "S": 3, "X": 1},
    ("sketch", "kf", "new_plus"): {"C": 9, "R": 4, "S": 1, "X": 1},
    ("core_marks",): {"PASS": 19, "FAIL": 7, "SILENT": 43, "INEXPRESSIBLE": 16},
    ("scorecard", "bk_meas"): {"R": 26, "W": 4, "C": 1, "S": 2},
    ("scorecard", "b_meas"): {"R": 16, "W": 4, "C": 1, "S": 12},
    ("scorecard", "c_meas"): {"R": 3, "W": 5, "S": 25},
}


def cmd_check(_args):
    import contextlib
    import io
    with contextlib.redirect_stdout(io.StringIO()):
        cmd_run([])
        cmd_table([])
    t = json.loads((OUT / "tallies.json").read_text())
    bad = []
    for path, want in EXPECTED.items():
        got = t
        for k in path:
            got = got[k]
        if got != want:
            bad.append(f"{'/'.join(path)}: expected {want}, got {got}")
    print("\n".join(bad) if bad else f"all {len(EXPECTED)} checks pass")
    sys.exit(1 if bad else 0)


COMMANDS = {"search": cmd_search, "abstract": cmd_abstract, "fetch": cmd_fetch, "refs": cmd_refs,
            "curies": cmd_curies, "quickgo": cmd_quickgo, "run": cmd_run, "table": cmd_table,
            "check": cmd_check}

if __name__ == "__main__":
    if len(sys.argv) < 2 or sys.argv[1] not in COMMANDS:
        print(__doc__)
        sys.exit(1)
    COMMANDS[sys.argv[1]](sys.argv[2:])

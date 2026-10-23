"""Sentence-level evidence mining for statements S1..S9 (tasks 2 and 6).

Reads  data/demo/glp1_corpus.parquet, data/demo/pubtator3_relations.tsv
Writes data/demo/evidence_candidates.tsv  every matching (statement, pmid, sentence)
       data/demo/evidence.json            top picks per statement, with grounding ids

Run:  uv run --with duckdb python scripts/demo/04_evidence.py
"""
import csv, json, re
from collections import Counter, defaultdict
import duckdb

D = "/home/danbolser/Build/BioLean/data/demo"
I = re.IGNORECASE

# ---- vocab ---------------------------------------------------------------
GLP1   = r"glp-?1\b|glp-?1\(|glucagon[- ]like peptide[- ]?1\b|glucagon[- ]like peptide[- ]?\(?1\)?"
GLP1R  = r"glp-?1 ?receptors?|glp-?1 ?rs?\b|glp-?1 ?ras?\b|glucagon[- ]like peptide[- ]?1 receptors?"
GLP1RA = r"glp-?1 ?receptor agonists?|glp-?1 ?ras?\b|glp-?1r agonists?|incretin mimetics?|semaglutide|liraglutide|exenatide|exendin-?4|lixisenatide|dulaglutide|albiglutide|tirzepatide"
DPP4   = r"dpp-?4|dpp-?iv|dipeptidyl[- ]peptidase"
DPP4I  = r"dpp-?4 inhibitors?|dpp-?iv inhibitors?|dipeptidyl[- ]peptidase[- ]?(4|iv) inhibitors?|gliptins?|sitagliptin|vildagliptin|saxagliptin|linagliptin|alogliptin"
APPET  = r"appetite|satiety|satiation|food intake|energy intake|calori[ec] intake|hunger|feeding|anorexi|anorectic|hyperphagi|fullness|eating"
WEIGHT = r"body ?weight|weight loss|weight reduction|weight gain|adiposity|\bbmi\b"
NEUROP = r"\bpomc\b|pro-?opiomelanocortin|\bcart\b|cocaine-? and amphetamine|\bnpy\b|neuropeptide y|agrp|agouti"
REGION = r"hypothalam|arcuate|\barc\b|brainstem|brain stem|hindbrain|nucleus (of the )?(tractus )?solitari|\bnts\b|area postrema|paraventricular|\bpvn\b|parabrachial|\bpbn\b"
REDUCE = r"reduc|decreas|lower|suppress|less\b|loss|diminish|fewer|smaller|declin|inhibit|attenuat|curb"
NAUSEA = r"nausea|aversi|malaise|conditioned taste|visceral illness|\billness\b|emesis|emetic|vomit|kaolin|\bpica\b|sickness"
NEG    = r"\b(not|no|never|neither|nor|without|lack\w*|poor\w*|limited|minimal|unable|little|restricted|does not|did not|cannot|unlikely)\b"
HUMAN  = r"participants|patients|subjects|adults|volunteers|\bmen\b|\bwomen\b|individuals|people|humans?\b|randomi[sz]ed|placebo|\bstep\b|trial|obes\w+ (adults|individuals|subjects)"

# statement -> list of rules; a rule = dict(all=[regex...], none=[regex...], tag=str)
RULES = {
 "S1": [dict(all=[r"semaglutide", r"agonist|activat|bind|affinity|ligand|stimulat", GLP1R], tag="sema+agonist+GLP1R")],
 "S2": [dict(all=[GLP1, NEUROP, f"{REGION}|{APPET}|{WEIGHT}"], tag="GLP1+POMC/CART/NPY/AgRP"),
        dict(all=[GLP1R, REGION, APPET, r"neuron|neural|central|activat|signal"], tag="GLP1R+region+appetite")],
 "S3": [dict(all=[GLP1, r"proglucagon|preproglucagon|\bgcg\b|l[- ]cells?|enteroendocrine", r"secret|releas|derived|cleav|process|produc|encod|post-?translational|prohormone convertase|pc1|pcsk1|precursor"], tag="GLP1 from proglucagon/L-cell"),
        dict(all=[GLP1, r"endogenous|native|physiological", r"ligand|agonist|hormone", GLP1R], tag="GLP1 endogenous ligand of GLP1R")],
 "S4": [dict(all=[DPP4, GLP1, r"degrad|inactivat|cleav|half-?life|metaboli[sz]|9-36|9-37|truncat|rapidly|break\w* down|hydroly"], tag="DPP4 degrades GLP1")],
 "S5": [dict(all=[r"sitagliptin", DPP4, r"inhibit|block|antagoni"], tag="sitagliptin inhibits DPP4")],
 "S6": [dict(all=[f"{GLP1}|{GLP1RA}", r"gastric emptying", r"delay|slow|inhibit|retard|decreas|reduc|prolong", f"{APPET}|{WEIGHT}"], tag="GE delay + satiety/weight"),
        dict(all=[f"{GLP1}|{GLP1RA}", r"gastric emptying", r"delay|slow|inhibit|retard|decreas|reduc|prolong"], tag="GE delay")],
 "S7": [dict(all=[r"semaglutide", f"{APPET}|{WEIGHT}", REDUCE], none=[r"\bmice\b|\bmouse\b|\brats?\b|rodent|minipig|monkey"], tag="sema reduces appetite/weight", doc=HUMAN)],
 "S8": [dict(all=[DPP4I, f"{APPET}|{WEIGHT}", r"weight[- ]neutral|neutral|no (significant |clinically relevant |meaningful )?(effect|change|difference|impact|influence)|did not|does not|do not|not (significantly )?(affect|alter|change|reduce|influence|associated)|unchanged|modest|minimal|little|lack|minor|less (weight|effect|pronounced)|without (weight|significant)|limited"], tag="DPP4i weight/appetite neutral", direction="supports"),
        dict(all=[DPP4I, f"{APPET}|{WEIGHT}", r"reduc|decreas|suppress|lower|loss|anorectic|less food"], none=[r"neutral|no (significant )?(effect|change|difference)|did not|does not|not significantly|unchanged|\bless (weight|effect)|compared|versus|\bvs\b|than"], tag="DPP4i reduces weight/appetite (contra)", direction="contradicts")],
 "S9a": [dict(all=[f"{GLP1}|{GLP1RA}", NAUSEA, f"{APPET}|{WEIGHT}", r"mediat|contribut|due to|because|explain|account|depend|driven|secondary to|result|underl|caus|via|through|link|associated with|correlat|predict"], none=[r"independent|not (explained|mediated|due|attributable|related|associated|dependent|caused|require)|dissociat|regardless|irrespective|unrelated|cannot be explained|not solely|not simply|absence of nausea|without nausea|beyond"], tag="nausea/aversion mediates intake/weight", direction="nausea_hypothesis")],
 "S9b": [dict(all=[f"{GLP1}|{GLP1RA}", NAUSEA, f"{APPET}|{WEIGHT}", r"independent|not (explained|mediated|due|attributable|related|associated|dependent|caused|require)|dissociat|regardless|irrespective|unrelated|separate|distinct|cannot be explained|not solely|only partly|not simply|absence of nausea|without nausea|beyond|even in|persist|did not (differ|correlate|predict)|no (correlation|relationship|association)"], tag="intake/weight effect independent of nausea", direction="satiety_hypothesis")],
 "S9c": [dict(all=[f"{GLP1}|{GLP1RA}", r"blood[- ]brain barrier|\bbbb\b|brain (uptake|penetration|penetrance|access|entry)|penetrat\w*( into| the| to)? (the )?(brain|cns|hypothalam|parenchyma)|cross\w*( into| the| to)? (the )?(blood|brain|bbb|cns)|access\w*( to)? the (brain|hypothalam|cns)|enter\w* the (brain|cns)|reach\w* the (brain|hypothalam|cns)|gain\w* access"], tag="BBB / brain access")],
 "S9d": [dict(all=[f"{GLP1}|{GLP1RA}", r"vagal|vagus|vagotomy|nodose|afferent|area postrema|circumventricular|median eminence|fenestrated|tanycyte|subfornical|organum vasculosum|peripheral(ly)? (administ|inject|GLP|acting|site)|periphery", f"{APPET}|{WEIGHT}|anorex|{NAUSEA}|brain|central"], tag="vagal / circumventricular route")],
}

STATEMENTS = {
 "S1": dict(statement="Semaglutide is an agonist of the GLP-1 receptor (GLP1R): it binds and activates GLP1R.",
            subject={"label": "semaglutide", "ids": ["CHEBI:167574", "MESH:D000099194"]}, relation={"label": "agonist of / activates", "ids": ["CHEBI:71196 (role: glucagon-like peptide-1 receptor agonist)", "RO:0000087 has role"]},
            object={"label": "GLP-1 receptor", "ids": ["UniProt:P43220", "NCBIGene:2740", "GO:0044508"]},
            pubtator_pairs=[("Chemical|MESH:D000099194", "Gene|2740"), ("Chemical|MESH:C000592913", "Gene|2740")],
            pubtator_note="PubTator3 has essentially no normalised semaglutide concept (1 row in whole file); exenatide-GLP1R rows shown as class-level proxy",
            pubtator_proxy_pairs=[("Chemical|MESH:D000077270", "Gene|2740")]),
 "S2": dict(statement="GLP1R activation in hypothalamic (arcuate POMC/CART) and brainstem neurons, with inhibition of NPY/AgRP neurons, reduces appetite and food intake.",
            subject={"label": "GLP-1 receptor signalling in hypothalamus/brainstem", "ids": ["UniProt:P43220", "NCBIGene:2740", "POMC UniProt:P01189 / NCBIGene:5443", "CARTPT NCBIGene:9607", "NPY NCBIGene:4852", "AGRP NCBIGene:181"]},
            relation={"label": "negatively regulates", "ids": ["GO:0032099 negative regulation of appetite", "GO:2000252 negative regulation of feeding behavior"]},
            object={"label": "appetite / feeding behaviour", "ids": ["GO:0007631", "GO:0060259"]},
            pubtator_pairs=[("Gene|2740", "Gene|5443"), ("Gene|2740", "Gene|9607"), ("Gene|2740", "Gene|4852"), ("Gene|2740", "Gene|181"), ("Gene|2641", "Gene|5443"), ("Gene|2641", "Gene|4852"), ("Gene|2641", "Gene|181")]),
 "S3": dict(statement="GLP-1, a proglucagon (GCG)-derived peptide secreted by intestinal L-cells, is the endogenous agonist of GLP1R.",
            subject={"label": "GLP-1 (7-36 amide)", "ids": ["CHEBI:80270", "UniProt:P01275 (pro-glucagon, cleaved into GLP-1)", "NCBIGene:2641"]}, relation={"label": "endogenous agonist of", "ids": ["GO:0005179 hormone activity", "GO:0044508 glucagon-like peptide 1 receptor activity"]},
            object={"label": "GLP-1 receptor", "ids": ["UniProt:P43220", "NCBIGene:2740"]},
            pubtator_pairs=[("Gene|2641", "Gene|2740")]),
 "S4": dict(statement="DPP4 degrades and inactivates GLP-1 by cleaving GLP-1(7-36) to GLP-1(9-36), giving active GLP-1 a plasma half-life of ~1-2 minutes.",
            subject={"label": "dipeptidyl peptidase 4", "ids": ["UniProt:P27487", "NCBIGene:1803", "GO:0008239 dipeptidyl-peptidase activity", "GO:0008233 peptidase activity"]}, relation={"label": "cleaves / inactivates", "ids": ["GO:0008239"]},
            object={"label": "GLP-1", "ids": ["CHEBI:80270", "UniProt:P01275", "NCBIGene:2641"]},
            pubtator_pairs=[("Gene|1803", "Gene|2641")]),
 "S5": dict(statement="Sitagliptin inhibits DPP4.",
            subject={"label": "sitagliptin", "ids": ["CHEBI:40237", "MESH:D000068900"]}, relation={"label": "inhibits", "ids": ["CHEBI:68612 (role: EC 3.4.14.5 (dipeptidyl-peptidase IV) inhibitor)"]},
            object={"label": "dipeptidyl peptidase 4", "ids": ["UniProt:P27487", "NCBIGene:1803"]},
            pubtator_pairs=[("Chemical|MESH:D000068900", "Gene|1803")]),
 "S6": dict(statement="GLP1R agonism delays gastric emptying, which increases satiety / fullness.",
            subject={"label": "GLP-1 receptor agonists", "ids": ["CHEBI:71196", "UniProt:P43220"]}, relation={"label": "negatively regulates", "ids": ["GO:0120061 negative regulation of gastric emptying"]},
            object={"label": "gastric emptying -> satiety", "ids": ["GO:0120060 regulation of gastric emptying", "HP:0033842 Early satiety"]},
            pubtator_pairs=[], pubtator_note="gastric emptying is not a PubTator3 entity type (Gene/Chemical/Disease/Variant only)"),
 "S7": dict(statement="Semaglutide reduces appetite, energy intake and body weight in humans.",
            subject={"label": "semaglutide", "ids": ["CHEBI:167574", "MESH:D000099194"]}, relation={"label": "reduces", "ids": ["CHEBI:50507 (role: appetite depressant)", "GO:0032099"]},
            object={"label": "appetite / energy intake / body weight (obesity)", "ids": ["HP:0004396 Poor appetite", "MONDO:0011122 obesity disorder", "HP:0001513 Obesity"]},
            pubtator_pairs=[("Chemical|MESH:D000099194", "Disease|MESH:D009765"), ("Chemical|MESH:D000099194", "Disease|MESH:D015431")],
            pubtator_note="no semaglutide concept in PubTator3 relations"),
 "S8": dict(statement="DPP4 inhibitors (e.g. sitagliptin) have little or no effect on appetite or body weight (weight-neutral), because they raise active GLP-1 only ~2-3 fold.",
            subject={"label": "DPP4 inhibitors / sitagliptin", "ids": ["CHEBI:68612", "CHEBI:40237", "MESH:D000068900"]}, relation={"label": "does not (substantially) reduce", "ids": []},
            object={"label": "appetite / body weight", "ids": ["GO:0007631", "HP:0001513"]},
            pubtator_pairs=[("Chemical|MESH:D000068900", "Disease|MESH:D009765"), ("Chemical|MESH:D000068900", "Disease|MESH:D015431"), ("Chemical|MESH:D000068900", "Disease|MESH:D001835")]),
 "S9a": dict(statement="Competing hypothesis: appetite/weight reduction with GLP-1RAs is partly or mostly due to nausea / visceral malaise / aversion.",
            subject={"label": "GLP-1 receptor agonists", "ids": ["CHEBI:71196"]}, relation={"label": "causes (aversive)", "ids": []}, object={"label": "nausea -> reduced intake", "ids": ["HP:0002018 Nausea"]},
            pubtator_pairs=[("Chemical|MESH:D000077270", "Disease|MESH:D009325"), ("Gene|2740", "Disease|MESH:D009325")]),
 "S9b": dict(statement="Counter-hypothesis: GLP-1RA effects on intake/weight are largely independent of nausea, reflecting direct satiety signalling.",
            subject={"label": "GLP-1 receptor agonists", "ids": ["CHEBI:71196"]}, relation={"label": "reduces, independent of", "ids": ["GO:0032099"]}, object={"label": "appetite, independent of nausea", "ids": ["HP:0002018 Nausea", "GO:0007631"]},
            pubtator_pairs=[]),
 "S9c": dict(statement="Debate: semaglutide/liraglutide act centrally by crossing the blood-brain barrier into hypothalamic/brainstem parenchyma.",
            subject={"label": "semaglutide / liraglutide", "ids": ["CHEBI:167574", "CHEBI:71193"]}, relation={"label": "crosses / does not cross", "ids": []}, object={"label": "blood-brain barrier", "ids": []},
            pubtator_pairs=[]),
 "S9d": dict(statement="Debate: semaglutide/liraglutide act via circumventricular organs (area postrema, median eminence) and vagal afferents rather than general BBB penetration.",
            subject={"label": "semaglutide / liraglutide / GLP-1", "ids": ["CHEBI:167574", "CHEBI:71193", "CHEBI:80270"]}, relation={"label": "acts via", "ids": []}, object={"label": "circumventricular organs / vagal afferents", "ids": []},
            pubtator_pairs=[]),
}

# ---- kind classifier (document level, heuristic) --------------------------
REVIEW_T = re.compile(r"\breview\b|meta-analys|systematic|overview|perspective|current (understanding|knowledge|concepts)|state of the art|update\b|mechanisms? of action|what we know|insights into|lessons from|opportunities|challenges|an update|: (a|the) (role|story|journey)", I)
REVIEW_A = re.compile(r"\b(this|the present|our) (review|article|paper|chapter) (summari|discuss|review|focus|highlight|describe|provide|outline|examine|explore)|we (review|summari[sz]e|discuss|highlight) |are reviewed|is reviewed|meta-analys|systematic review|literature search|pubmed, embase|we searched", I)
RCT      = re.compile(r"randomi[sz]ed|placebo-controlled|double-blind|double blind|crossover trial|cross-over trial|phase (1|2|3|i|ii|iii)\b|clinicaltrials\.gov|nct\d{6}", I)
MECH     = re.compile(r"\bmice\b|\bmouse\b|\brats?\b|rodent|knockout|knock-out|\bko\b|neurons?|in vitro|cell line|hek293|cho cells|receptor binding|camp|c-fos|electrophysiolog|cryo-?em|crystal structure|affinity|\bkd\b|ec50|ic50|transgenic|cre\b|optogenetic|chemogenetic|dreadd|tracing|immunohisto|in situ hybridi", I)
OBS      = re.compile(r"cohort|retrospective|registry|real-world|cross-sectional|case-control|observational|claims database|electronic health", I)

def kind_of(title, abstract):
    if REVIEW_T.search(title) and not RCT.search(title): return "review"
    if RCT.search(title) or (RCT.search(abstract) and re.search(r"participants|patients|subjects|volunteers|adults", abstract, I) and not REVIEW_A.search(abstract)): return "rct"
    if REVIEW_A.search(abstract): return "review"
    if MECH.search(abstract) or MECH.search(title): return "mechanistic"
    if OBS.search(abstract): return "observational"
    return "other"

TOP_J = re.compile(r"lancet|n engl j med|new england|\bjama\b|\bnature\b|cell metab|\bcell\b|\bscience\b|diabetes care|diabetologia|^diabetes$|endocr rev|physiol rev|nat rev|nature reviews|diabetes obes metab|j clin endocrinol|endocrinology|mol metab|int j obes|obes rev|obesity \(silver|am j physiol|peptides|\bgut\b|gastroenterology|br j pharmacol|j clin invest|annu rev|nat med|cell rep|neuron\b|j neurosci|j physiol|am j clin nutr|appetite", I)

# ---- sentence splitting ---------------------------------------------------
ABBR = re.compile(r"\b(e\.g|i\.e|vs|et al|fig|approx|ca|cf|resp|vol|dr|prof|st|jr|inc|ltd|u\.s|u\.k|i\.v|s\.c|p\.o|wk|mo|min|max|no)\.", I)
def sentences(t):
    t = ABBR.sub(lambda m: m.group(0).replace(".", "<DOT>"), t)
    return [p.replace("<DOT>", ".").strip() for p in re.split(r"(?<=[.!?])\s+(?=[A-Z0-9(\"\[])", t) if p.strip()]

def abstract_of(text):
    i = text.find("\nAbstract: ")
    return text[i + 11:] if i >= 0 else ""

# ---- load -----------------------------------------------------------------
con = duckdb.connect(); con.execute("SET threads TO 64")
docs = con.execute(f"SELECT DISTINCT ON (pmid) pmid, publication_year, journal, title, text FROM read_parquet('{D}/glp1_corpus.parquet') ORDER BY pmid").fetchall()
rel = defaultdict(list)          # pmid -> rows
pair_count = Counter()           # frozenset(c1,c2) -> n
with open(f"{D}/pubtator3_relations.tsv") as fh:
    next(fh)
    for line in fh:
        pmid, r, c1, c2 = line.rstrip("\n").split("\t")
        rel[int(pmid)].append((r, c1, c2)); pair_count[frozenset((c1, c2))] += 1

compiled = {s: [dict(r, all=[re.compile(x, I) for x in r["all"]], none=[re.compile(x, I) for x in r.get("none", [])],
                     doc=re.compile(r["doc"], I) if r.get("doc") else None) for r in rules] for s, rules in RULES.items()}

cands = []   # dicts
for pmid, year, journal, title, text in docs:
    abstract = abstract_of(text)
    full = f"{title} {abstract}"
    kind = None
    for sid, rules in compiled.items():
        for rule in rules:
            if rule["doc"] and not rule["doc"].search(full): continue
            for sent in [title] + sentences(abstract):
                if all(p.search(sent) for p in rule["all"]) and not any(p.search(sent) for p in rule["none"]):
                    kind = kind or kind_of(title, abstract)
                    cands.append(dict(statement=sid, pmid=pmid, year=year, journal=journal, title=title, kind=kind,
                                      rule=rule["tag"], direction=rule.get("direction", "supports"), quote=sent, in_title=(sent == title)))

# ---- score & pick ---------------------------------------------------------
KIND_W = dict(review=3, rct=3, mechanistic=2, observational=1, other=0)
def score(c, nsent):
    s = KIND_W[c["kind"]] + min(nsent, 3) + (2 if c["in_title"] else 0) + (2 if TOP_J.search(c["journal"] or "") else 0)
    s += 1 if c["year"] and c["year"] >= 2015 else 0
    s += 1 if c["statement"] == "S6" and c["rule"].endswith("weight") else 0
    s += 1 if c["statement"] == "S7" and re.search(r"appetite|energy intake|hunger|food intake", c["quote"], I) else 0
    s += 2 if c["statement"] == "S1" and re.search(r"semaglutide", c["title"], I) else 0
    return s

by_stmt = defaultdict(lambda: defaultdict(list))
for c in cands: by_stmt[c["statement"]][c["pmid"]].append(c)

def pick(items, n=15):
    """Round-robin over (direction, kind) buckets so picks are diverse."""
    buckets = defaultdict(list)
    for it in sorted(items, key=lambda x: -x["score"]): buckets[(it["direction"], it["kind"])].append(it)
    order = sorted(buckets, key=lambda k: -buckets[k][0]["score"])
    out = []
    while len(out) < n and any(buckets.values()):
        for k in order:
            if buckets[k] and len(out) < n: out.append(buckets[k].pop(0))
    return out

evidence = []
summary = []
with open(f"{D}/evidence_candidates.tsv", "w", newline="") as fh:
    w = csv.writer(fh, delimiter="\t")
    w.writerow(["statement", "pmid", "year", "journal", "kind", "direction", "rule", "in_title", "title", "quote"])
    for sid, meta in STATEMENTS.items():
        per_pmid = by_stmt.get(sid, {})
        items = []
        for pmid, cs in per_pmid.items():
            best = max(cs, key=lambda c: (c["in_title"] is False, len(c["quote"]) < 450, -len(c["quote"])))  # prefer abstract sentence, not over-long
            best = dict(best, n_sentences=len(cs), score=score(best, len(cs)))
            items.append(best)
            for c in cs: w.writerow([sid, c["pmid"], c["year"], c["journal"], c["kind"], c["direction"], c["rule"], c["in_title"], c["title"], c["quote"]])
        pairs = [frozenset(p) for p in meta["pubtator_pairs"]]
        proxy = [frozenset(p) for p in meta.get("pubtator_proxy_pairs", [])]
        picked = pick(items)
        for it in picked:
            it["pubtator3_relations"] = [dict(relation=r, concept1=c1, concept2=c2) for r, c1, c2 in rel.get(it["pmid"], []) if frozenset((c1, c2)) in pairs + proxy]
        kinds = Counter(i["kind"] for i in items); dirs = Counter(i["direction"] for i in items)
        evidence.append(dict(id=sid, statement=meta["statement"], subject=meta["subject"], relation=meta["relation"], object=meta["object"],
                             pubtator3_relation_count=sum(pair_count[p] for p in pairs),
                             pubtator3_pairs={" -- ".join(sorted(p)): pair_count[p] for p in pairs},
                             pubtator3_proxy_pairs={" -- ".join(sorted(p)): pair_count[p] for p in proxy} if proxy else None,
                             pubtator3_note=meta.get("pubtator_note"),
                             candidate_pmid_count=len(items), candidate_kinds=dict(kinds), candidate_directions=dict(dirs),
                             evidence=[dict(pmid=i["pmid"], year=i["year"], journal=i["journal"], title=i["title"], quote=i["quote"], kind=i["kind"],
                                            direction=i["direction"], rule=i["rule"], score=i["score"], pubtator3_relations=i["pubtator3_relations"]) for i in picked]))
        summary.append((sid, len(items), len(picked), dict(kinds), dict(dirs), sum(pair_count[p] for p in pairs)))

json.dump(evidence, open(f"{D}/evidence.json", "w"), indent=1)
print(f"{'stmt':5} {'cand_pmids':>10} {'picked':>6} {'pubtator':>8}  kinds / directions")
for sid, n, k, kinds, dirs, pt in summary:
    print(f"{sid:5} {n:>10} {k:>6} {pt:>8}  {kinds} {dirs}")

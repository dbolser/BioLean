"""Check a run's curation, compose its arms, and render it as a Lean module.

    uv run python scripts/ipf/render.py data/ipf/runs/<run>            # check, compose, render
    uv run python scripts/ipf/render.py data/ipf/runs/<run> --lean     # ... and elaborate in Lean
    uv run python scripts/ipf/render.py --all [--lean]

Input: `curated.json` beside `run.json` and `sources.json` (format: docs/ipf-curation.md).
Output: `BioLean/Lib/IPF/Runs/<Module>.lean`, one module per run dir.

Checks, all fatal: names are valid and defined; every CURIE is in the local corpus with the
declared kind (dbSNP, BLN, Reactome, ClinVar and HGNC are unchecked); labels are the corpus
labels, so two runs that name the same term get equal entities; every quote is in its source
(case, whitespace and markup folded); every run step is a statement or listed as unexpressed;
categories come from the guide's lists.

Composition: for every claim a hypothesis makes ("MUC5B →+ risk of IPF"), every simple path of
statements from the claim's subject to its target is an arm. A path is effects, except that a
signed association may stand in for an effect, through `fromAssoc` (discounted). Signs and
strengths are not computed here: Lean computes them, and the module prints one JSON row per arm.
"""
import argparse
import html
import json
import re
import subprocess
import sys
from pathlib import Path

import duckdb

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))
from biolean.corpus import query  # noqa: E402

RUNS = ROOT / "data/ipf/runs"
OUT = ROOT / "BioLean/Lib/IPF/Runs"
LOOKUP = ROOT / "data/lookup/labels.parquet"
SNAPSHOT_YEAR = 2026  # database records as fetched by the runs

KINDS = {"chemical", "protein", "gene", "process", "function", "phenotype", "disease", "anatomy",
         "cellType", "component", "taxon", "variant"}
EVIDENCE_KINDS = {"metaAnalysis", "rct", "curatedDb", "textbook", "ontologyAxiom", "mechanistic",
                  "review", "observational", "inVitro", "textMined", "hypothesis", "crossSpecies"}
TARGET_KINDS = {"activity": {"protein", "function"}, "amount": {"chemical", "protein", "gene"},
                "process": {"process"}, "phenotype": {"phenotype"}, "site": {"anatomy"},
                "disease": {"disease"}}
CHAIN_RULE = {"amount": "viaAmount", "activity": "viaActivity", "process": "viaProcess",
              "phenotype": "viaPhenotype"}
ASPECTS = {"risk", "severity", "progression"}
CTX_FIELDS = {"taxon": "taxon", "anatomy": "anatomy", "cellType": "cellType", "component": "component",
              "stage": "process", "lifeStage": "anatomy", "condition": None}
TAXA = {"human": "Taxa.human", "mouse": "Taxa.mouse", "rat": "Taxa.rat", "zebrafish": "Taxa.zebrafish",
        "fly": "Taxa.fly", "worm": "Taxa.worm", "yeast": "Taxa.yeast"}
UNCHECKED = ("dbSNP:", "BLN:", "Reactome:", "ClinVar:", "HGNC:")
LOOKUP_KIND = {"cell_type": "cellType"}
# Kinds of corpus terms that are not in the label table, by prefix (GO by its namespace).
PREFIX_KIND = {"MP": "phenotype", "ZP": "phenotype", "WBPhenotype": "phenotype", "FYPO": "phenotype",
               "UPHENO": "phenotype", "OBA": "phenotype", "HP": "phenotype", "PATO": "phenotype",
               "SO": "variant", "PR": "protein", "CL": "cellType", "UBERON": "anatomy", "CHEBI": "chemical",
               "MONDO": "disease", "DOID": "disease", "EFO": "disease", "NCBITaxon": "taxon"}
GO_NAMESPACE = {"biological_process": "process", "molecular_function": "function", "cellular_component": "component"}
EXCLUDE_CATEGORIES = {"not_in_text", "not_this_entity", "parent_disease", "undirected", "no_direction",
                      "association_only", "disease_feature", "enrichment", "no_text", "other"}
UNEXPRESSED_CATEGORIES = {"unsigned_association", "no_sign", "compound_entity", "set_valued",
                          "ungroundable", "evidence_does_not_test_step", "not_causal", "other_construct"}
PROJECTS = {"hypothesis-agent", "biolean", "both"}
RESERVED = {"at", "by", "do", "else", "end", "fun", "have", "if", "in", "let", "match", "then",
            "where", "with", "from", "show", "open", "def", "theorem", "example", "this", "Type",
            "Prop", "Sort", "Entity", "Kind", "Claim", "Target", "Sign", "Statement", "Evidence",
            "Derivation", "Taxa", "Ctx", "Opinion", "Rel", "RO", "arm", "statementRow",
            "printRows", "statements", "rows", "lit"}
NAME = re.compile(r"[A-Za-z][A-Za-z0-9_]*")
TAG = re.compile(r"</?[A-Za-z][^<>]*>")  # a tag, not the '<' of 'P<0.001'
MAX_DEPTH = 7
MAX_ARMS = 12


def fold(text: str) -> str:
    return " ".join(html.unescape(TAG.sub(" ", text)).split()).casefold()


def esc(s: str, n: int = 240) -> str:
    return " ".join(s.replace("\\", "\\\\").replace('"', "'").split())[:n]


def module_name(run_dir: Path) -> str:
    return "R" + re.sub(r"[^A-Za-z0-9]", "_", run_dir.name)


def run_steps(run: dict) -> dict[str, dict]:
    return {f"{h['hypothesis_id']}.{i + 1}": s for h in run["hypotheses"] for i, s in enumerate(h["chain"])}


def steps_of(s: dict) -> list[str]:
    """A statement's run steps: one, or several when hypotheses repeat a step."""
    return s["step"] if isinstance(s["step"], list) else [s["step"]]


def claim_parts(c: dict) -> tuple[str, str, str, dict]:
    """(form, subject, sign, target) of an effect or an association; sign 'none' if unsigned."""
    if "effect" in c:
        return "effect", c["effect"]["subject"], c["effect"]["sign"], c["effect"]["target"]
    a = c["assoc"]
    return "assoc", a["subject"], a["direction"], a["target"]


def target_of(t: dict) -> tuple[str, str, str]:
    (tk, ent), = [(k, v) for k, v in t.items() if k in TARGET_KINDS]
    return tk, ent, t.get("aspect", "risk")


def claim_target(cl: dict) -> dict:
    """A hypothesis claim's target; the old form names only a disease and an aspect."""
    return cl["target"] if "target" in cl else {"disease": cl["disease"], "aspect": cl.get("aspect", "risk")}


class Checker:
    def __init__(self) -> None:
        self.errors: list[str] = []
        self.warnings: list[str] = []

    def __call__(self, ok: bool, msg: str) -> bool:
        if not ok:
            self.errors.append(msg)
        return ok


def corpus_terms(curies: list[str], need_text: list[str]) -> dict[str, tuple[str, str, str]]:
    """curie -> (kind, label, text) for ontology and UniProt terms: the label table first, then the
    corpus for terms the table lacks (GO functions and components, MP, SO, PR) or whose text is needed."""
    out: dict[str, tuple[str, str, str]] = {}
    curies = list(dict.fromkeys(curies + need_text))
    if not curies:
        return out
    rows = duckdb.execute(f"select curie, kind, label, method from '{LOOKUP}' where list_contains(?, curie)",
                          [curies]).fetchall()
    for curie, kind, label, method in sorted(rows, key=lambda r: r[3] != "exact_label"):
        out.setdefault(curie, (LOOKUP_KIND.get(kind, kind), label, ""))
    ids = [c.removeprefix("UniProt:") for c in curies if c not in out or c in need_text]
    if not ids:
        return out
    for rid, rtype, title, text, meta in query(
            "select record_id, record_type, title, text, metadata from records"
            " where record_id = any(?) and record_class in ('Ontology', 'UniProt')", [ids]):
        curie = rid if rid in curies else f"UniProt:{rid}"
        kind, label, prev = out.get(curie, ("", title, ""))
        if not kind:
            if rtype == "go_term":
                kind = GO_NAMESPACE.get(json.loads(meta or "{}").get("namespace"), "")
            elif not rid.startswith("GO:"):
                kind = PREFIX_KIND.get(rid.split(":")[0], "")
        text = "\n".join(line for line in text.splitlines() if "\\1" not in line)  # corpus artefact
        out[curie] = (kind, label, f"{prev}\n{text}".strip())  # a term can have several records
    return out


def check_evidence(owner: str, item: dict, sources: dict, terms: dict, ck: Checker) -> None:
    for ev in item.get("evidence", []):
        ref = ev.get("ref", "")
        ck(ev.get("kind") in EVIDENCE_KINDS, f"{owner} {ref}: kind {ev.get('kind')!r} is not an EvidenceKind")
        ck(ev.get("polarity", "supports") in ("supports", "refutes"), f"{owner} {ref}: polarity")
        ck(ev.get("taxon") in (None, *TAXA), f"{owner} {ref}: taxon {ev.get('taxon')!r} is not one of {sorted(TAXA)}")
        text = (sources.get(ref) or {}).get("text") or terms.get(ref, ("", "", ""))[2]
        if ck(bool(text), f"{owner} {ref}: no source text (not cited by the run, not an ontology term)"):
            ck(bool(ev.get("quote")) and fold(ev["quote"]) in fold(text),
               f"{owner} {ref}: quote not in source: {ev.get('quote', '')[:70]!r}")
    for ex in item.get("excluded", []):
        ck(bool(ex.get("ref")) and bool(ex.get("reason")), f"{owner}: an exclusion needs ref and reason")
        ck(ex.get("category") in EXCLUDE_CATEGORIES,
           f"{owner} {ex.get('ref')}: exclusion category {ex.get('category')!r} is not one of {sorted(EXCLUDE_CATEGORIES)}")


def check(cur: dict, run: dict, sources: dict, ck: Checker) -> dict:
    """Validate the curation; return the resolved entity table: name -> (kind, curie, label, refines)."""
    names: set[str] = set()

    def new_name(n: str, what: str) -> None:
        ck(bool(NAME.fullmatch(n)) and n not in RESERVED, f"{what} name {n!r} is not a usable Lean name")
        ck(n not in names, f"name {n!r} defined twice")
        names.add(n)

    entities = cur.get("entities", {})
    base = {n: e for n, e in entities.items() if "refines" not in e}
    evidence_refs = [ev["ref"] for item in cur.get("statements", []) + cur.get("unexpressed", [])
                     for ev in item.get("evidence", [])]
    terms = corpus_terms([e.get("curie", "") for e in base.values() if not e.get("curie", "").startswith(UNCHECKED)],
                         [r for r in evidence_refs if r not in sources and not r.startswith(UNCHECKED)])
    table = {}
    for n, e in entities.items():
        new_name(n, "entity")
        if not ck(e.get("kind") in KINDS, f"entity {n}: kind {e.get('kind')!r} is not a Kind"):
            continue
        if "refines" in e:
            r = e["refines"]
            ck(r.get("base") in entities and "refines" not in entities.get(r.get("base"), {}),
               f"entity {n}: refines {r.get('base')!r}, which is not a base entity")
            for field, value in r.get("ctx", {}).items():
                if field == "taxon":
                    ck(value in TAXA, f"entity {n}: taxon {value!r} is not one of {sorted(TAXA)}")
                elif field == "condition":
                    ck(value in entities, f"entity {n}: condition {value!r} is not an entity")
                else:
                    ck(field in CTX_FIELDS and entities.get(value, {}).get("kind") == CTX_FIELDS[field],
                       f"entity {n}: ctx {field} := {value!r} needs a {CTX_FIELDS.get(field)} entity")
            table[n] = (e["kind"], None, None, r)
            continue
        curie = e.get("curie", "")
        if curie.startswith(UNCHECKED):
            ck(bool(e.get("label")), f"entity {n}: {curie} is not in the corpus, so it needs a label")
            if curie.startswith("BLN:") and e["kind"] != "variant":
                ck(bool(e.get("why_no_term")), f"entity {n}: a BLN term needs why_no_term (what you searched)")
            table[n] = (e["kind"], curie, e.get("label", ""), None)
            continue
        if not ck(curie in terms, f"entity {n}: CURIE {curie!r} not in the local corpus"):
            continue
        kind, label, _ = terms[curie]
        ck(kind == e["kind"], f"entity {n}: {curie} is a {kind or 'term of unknown kind'} in the corpus, not a {e['kind']}")
        table[n] = (e["kind"], curie, label, None)

    steps = run_steps(run)
    hyp_ids = {h["hypothesis_id"] for h in run["hypotheses"]}
    stated: set[str] = set()
    for s in cur.get("statements", []):
        sid = s.get("id", "?")
        new_name(sid, "statement")
        if s.get("step") == "bridge":
            ck(bool(s.get("for")) and set(s["for"]) <= hyp_ids, f"{sid}: a bridge names the hypotheses it is for")
        else:
            for step in steps_of(s):
                ck(step in steps, f"{sid}: step {step!r} is not a step of the run")
                stated.add(step)
        c = s.get("claim", {})
        if "effect" in c or "assoc" in c:
            form, subject, sign, t = claim_parts(c)
            ck(subject in table, f"{sid}: subject {subject!r} is not an entity")
            signs = ("pos", "neg") if form == "effect" else ("pos", "neg", "none")
            ck(sign in signs, f"{sid}: {'sign' if form == 'effect' else 'direction'} must be one of {signs}")
            tk = [k for k in t if k in TARGET_KINDS]
            if ck(len(tk) == 1, f"{sid}: target needs exactly one of {sorted(TARGET_KINDS)}"):
                ent = t[tk[0]]
                ck(ent in table and table[ent][0] in TARGET_KINDS[tk[0]],
                   f"{sid}: {tk[0]} target {ent!r} must be a {'/'.join(sorted(TARGET_KINDS[tk[0]]))} entity")
                ck(tk[0] == "disease" or "aspect" not in t, f"{sid}: only a disease target has an aspect")
                ck(t.get("aspect", "risk") in ASPECTS, f"{sid}: aspect must be one of {sorted(ASPECTS)}")
        elif "rel" in c:
            r = c["rel"]
            ck(bool(re.fullmatch(r"(RO|BFO):\d{7}", r.get("relation", ""))), f"{sid}: relation must be an RO or BFO CURIE")
            ck(r.get("a") in table and r.get("b") in table, f"{sid}: rel ends must be entities")
        else:
            ck(False, f"{sid}: claim must be an effect, an assoc or a rel")
        check_evidence(sid, s, sources, terms, ck)
    unexpressed = set()
    for u in cur.get("unexpressed", []):
        ck(u.get("step") in steps, f"unexpressed step {u.get('step')!r} is not a step of the run")
        ck(bool(u.get("reason")), f"unexpressed {u.get('step')}: needs a reason")
        ck(u.get("category") in UNEXPRESSED_CATEGORIES,
           f"unexpressed {u.get('step')}: category {u.get('category')!r} is not one of {sorted(UNEXPRESSED_CATEGORIES)}")
        check_evidence(f"unexpressed {u.get('step')}", u, sources, terms, ck)
        unexpressed.add(u.get("step"))
    for step in steps:
        ck(step in stated | unexpressed, f"step {step} is neither stated nor unexpressed")
    hyps = cur.get("hypotheses", {})
    for hid in hyp_ids:
        h = hyps.get(hid)
        if not ck(h is not None, f"hypothesis {hid} has no entry in `hypotheses`"):
            continue
        ck(bool(h.get("claims")) or bool(h.get("no_claim_reason")), f"hypothesis {hid}: claims, or no_claim_reason")
        for cl in h.get("claims", []):
            ck(cl.get("subject") in table and table[cl["subject"]][0] != "disease", f"{hid}: claim subject {cl.get('subject')!r}")
            ck(cl.get("sign") in ("pos", "neg"), f"{hid}: claim sign")
            t = claim_target(cl)
            tk = [k for k in t if k in TARGET_KINDS]
            if ck(len(tk) == 1, f"{hid}: claim target needs exactly one of {sorted(TARGET_KINDS)}"):
                ck(t[tk[0]] in table and table[t[tk[0]]][0] in TARGET_KINDS[tk[0]], f"{hid}: claim target {t[tk[0]]!r}")
                ck(t.get("aspect", "risk") in ASPECTS, f"{hid}: claim aspect")
    for f in cur.get("findings", []):
        ck(f.get("project") in PROJECTS, f"finding {f.get('category')}: project must be one of {sorted(PROJECTS)}")
        ck(bool(f.get("category")) and bool(f.get("detail")), "a finding needs category and detail")
    bln = [n for n, (_, curie, _, _) in table.items() if curie and curie.startswith("BLN:")]
    noted = " ".join(json.dumps(f) for f in cur.get("findings", []) if f.get("category") == "missing_term")
    for n in bln:
        if table[n][1] not in noted:
            ck.warnings.append(f"entity {n}: {table[n][1]} has no missing_term finding naming it")
    return table


def arms_for(claim: dict, statements: list[dict]) -> list[list[dict]]:
    """Every simple path from the claim's subject to its target: effects, or signed associations."""
    edges: dict[str, list[tuple[str, str, str, dict]]] = {}
    for s in statements:
        if "effect" not in s["claim"] and "assoc" not in s["claim"]:
            continue
        form, subject, sign, t = claim_parts(s["claim"])
        if sign == "none":
            continue
        tk, ent, aspect = target_of(t)
        edges.setdefault(subject, []).append((tk, ent, aspect, s))
    gk, gent, gaspect = target_of(claim_target(claim))
    out: list[list[dict]] = []

    def walk(node: str, seen: set[str], path: list[dict]) -> None:
        if len(out) >= MAX_ARMS or len(path) >= MAX_DEPTH:
            return
        for tk, ent, aspect, s in edges.get(node, []):
            if (tk, ent) == (gk, gent) and (tk != "disease" or aspect == gaspect):
                out.append(path + [s])
            elif tk in CHAIN_RULE and ent not in seen:
                walk(ent, seen | {ent}, path + [s])

    walk(claim["subject"], {claim["subject"]}, [])
    return out


def leaf(s: dict) -> str:
    return f"fromAssoc (lit {s['id']})" if "assoc" in s["claim"] else f"lit {s['id']}"


def term(path: list[dict]) -> str:
    """Right-nested chain: `via(s₁, via(s₂, s₃))`, the rule set by each statement's target kind."""
    if len(path) == 1:
        return leaf(path[0])
    tk, _, _ = target_of(claim_parts(path[0]["claim"])[3])
    return f"{CHAIN_RULE[tk]} ({leaf(path[0])}) ({term(path[1:])})"


def target_lean(t: dict) -> str:
    tk, ent, aspect = target_of(t)
    if tk == "disease" and aspect != "risk":
        return f"(.disease {ent} .{aspect})"
    return f"(.{tk} {ent})"


def claim_lean(c: dict) -> str:
    if "effect" in c:
        ef = c["effect"]
        return f".effect {ef['subject']} .{ef['sign']} {target_lean(ef['target'])}"
    if "assoc" in c:
        a = c["assoc"]
        d = "none" if a["direction"] == "none" else f"(some .{a['direction']})"
        return f".assoc {a['subject']} {d} {target_lean(a['target'])}"
    r = c["rel"]
    prefix, num = r["relation"].split(":")
    return f".rel ⟨.{prefix.lower()}, {int(num)}, false⟩ {r['a']} {r['b']}"


def evidence_lean(ev: dict, sources: dict) -> str:
    ref = ev["ref"]
    src = sources.get(ref) or {}
    if re.fullmatch(r"PMID:\d+", ref):
        head = f"pmid := {int(ref[5:])}, year := {src.get('year') or SNAPSHOT_YEAR}"
    else:  # a record, or a preprint Europe PMC files under 'PMID:PPR…'
        head = f'pmid := 0, year := {src.get("year") or SNAPSHOT_YEAR}, ref := "{esc(ref)}"'
    pol = ", polarity := .refutes" if ev.get("polarity") == "refutes" else ""
    taxon = f", taxon := some {TAXA[ev['taxon']]}" if ev.get("taxon") else ""
    return f'    {{ {head}, kind := .{ev["kind"]}{pol}, note := "{esc(ev["quote"])}"{taxon} }}'


def ctx_lean(field: str, value: str) -> str:
    if field == "taxon":
        return f"taxon := {TAXA[value]}"
    if field == "condition":
        return f"condition := some (.organism {value})"
    return f"{field} := {value}"


def render(run_dir: Path, cur: dict, run: dict, sources: dict, table: dict) -> tuple[str, list[str]]:
    mod = module_name(run_dir)
    q = run.get("question", {})
    out = ["import BioLean.Lib.IPF.Common", "",
           f"/-! Rendered from `data/ipf/runs/{run_dir.name}/curated.json` by `scripts/ipf/render.py`.",
           f"Do not edit by hand. Run `{cur['run_id']}`: {esc(str(run.get('model')), 80)}, "
           f"{esc(str(q.get('disease')), 80)}, genes {', '.join(q.get('genes', [])[:12])}. -/", "",
           f"namespace BioLean.Lib.IPF.Runs.{mod}", "", "open BioLean BioLean.Lib.IPF Derivation", ""]
    for n, (kind, curie, label, refines) in table.items():
        if refines is None:
            out.append(f'def {n} : Entity .{kind} := ⟨"{esc(curie)}", "{esc(label)}"⟩')
    for n, (kind, _, _, refines) in table.items():
        if refines is not None:
            fields = ", ".join(ctx_lean(f, v) for f, v in refines.get("ctx", {}).items())
            out.append(f"def {n} : Entity .{kind} := {refines['base']}.inCtx {{ {fields} }}")
    out.append("")
    stmts = cur["statements"]
    for s in stmts:
        rows = [evidence_lean(ev, sources) for ev in s.get("evidence", [])]
        where = "Bridge, not in the run" if s["step"] == "bridge" else "Run step " + ", ".join(steps_of(s))
        note = f" Sign: {esc(s['sign_note'])}." if s.get("sign_note") else ""
        out += [f"/-- {where}: {esc(s.get('text', ''))}.{note} -/",
                f"def {s['id']} : Statement where", f'  id := "{s["id"]}"', f'  text := "{esc(s.get("text", ""))}"',
                f"  claim := {claim_lean(s['claim'])}",
                "  evidence := [" + ("\n" + ",\n".join(rows) + "\n  ]" if rows else "]"), ""]
    out += [f"def statements : List Statement := [{', '.join(s['id'] for s in stmts)}]", ""]
    arm_rows, log = [], []
    for hi, h in enumerate(run["hypotheses"], 1):
        hid = h["hypothesis_id"]
        for ci, cl in enumerate(cur["hypotheses"][hid].get("claims", []), 1):
            paths = arms_for(cl, stmts)
            tk, ent, aspect = target_of(claim_target(cl))
            what = f"{aspect} of {ent}" if tk == "disease" else f"{tk} {ent}"
            want = f"{cl['subject']} {'→+' if cl['sign'] == 'pos' else '→−'} {what}"
            if not paths:
                log.append(f"  {hid} claim {ci} ({want}): no route")
            for ai, path in enumerate(paths, 1):
                name = f"h{hi}c{ci}a{ai}"
                sign = "pos"
                for s in path:
                    sign = "pos" if sign == claim_parts(s["claim"])[2] else "neg"
                flag = "" if sign == cl["sign"] else "   <-- SIGN DIFFERS FROM THE CLAIM"
                log.append(f"  {hid} claim {ci} ({want}): {' → '.join(s['id'] for s in path)}  sign {sign}{flag}")
                out += [f"/-- {esc(hid)}, claim {ci}: {esc(h.get('title', ''), 160)}. -/",
                        f"def {name} := {term(path)}", ""]
                arm_rows.append(f'arm "{esc(hid)}" "c{ci}a{ai}" {name}')
    out += ["def rows : List Lean.Json :=",
            "  statements.map statementRow ++ [" + ",\n    ".join(arm_rows) + "]", "",
            f'#eval printRows "{run_dir.name}" rows', "",
            f"end BioLean.Lib.IPF.Runs.{mod}", ""]
    return "\n".join(out), log


def process(run_dir: Path, lean: bool) -> bool:
    cur = json.loads((run_dir / "curated.json").read_text())
    run = json.loads((run_dir / "run.json").read_text())
    sources = json.loads((run_dir / "sources.json").read_text())
    ck = Checker()
    table = check(cur, run, sources, ck)
    if ck.errors:
        print(f"{run_dir.name}: {len(ck.errors)} problems\n  " + "\n  ".join(ck.errors))
        return False
    text, log = render(run_dir, cur, run, sources, table)
    path = OUT / f"{module_name(run_dir)}.lean"
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text)
    n_ev = sum(len(s.get("evidence", [])) for s in cur["statements"] + cur.get("unexpressed", []))
    n_ex = sum(len(s.get("excluded", [])) for s in cur["statements"] + cur.get("unexpressed", []))
    unexpressed = {u["step"] for u in cur.get("unexpressed", [])} - {x for s in cur["statements"] for x in steps_of(s)}
    print(f"{run_dir.name}: wrote {path.relative_to(ROOT)}: {len(cur['statements'])} statements, "
          f"{n_ev} evidence kept, {n_ex} excluded, {len(unexpressed)} steps wholly unexpressed")
    print("\n".join(["  warning: " + w for w in ck.warnings] + log))
    if lean:
        res = subprocess.run(["lake", "env", "lean", str(path)], cwd=ROOT, capture_output=True, text=True)
        rows = [line for line in res.stdout.splitlines() if line.startswith("{")]
        errs = [line for line in res.stdout.splitlines() + res.stderr.splitlines() if not line.startswith("{")]
        if res.returncode:
            print("Lean: FAILED\n" + "\n".join(errs[:40]))
            return False
        (run_dir / "report.jsonl").write_text("".join(f"{r}\n" for r in rows))
        print(f"Lean: ok, {len(rows)} rows -> {(run_dir / 'report.jsonl').relative_to(ROOT)}")
        for r in map(json.loads, rows):
            if r["row"] == "arm":
                print(f"  arm {r['hypothesis']} {r['name']}: {r['claim']['text']}  belief {r['opinion']['b']} {r['verdict']}")
    return True


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("runs", nargs="*", type=Path)
    ap.add_argument("--all", action="store_true")
    ap.add_argument("--lean", action="store_true")
    args = ap.parse_args()
    dirs = sorted(p.parent for p in RUNS.glob("*/curated.json")) if args.all else args.runs
    ok = [process(d.resolve(), args.lean) for d in dirs]
    sys.exit(0 if all(ok) else 1)


if __name__ == "__main__":
    main()

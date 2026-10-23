"""Render data/demo/curated.json into BioLean/Lib/GLP1Statements.lean.

Each curated statement becomes one Lean `Statement`. The claim for each id is fixed
here, because turning a curated English sentence into a typed claim is a modelling
decision, not a data transformation. S8's polarity is flipped: its evidence supports
"DPP-4 inhibitors do not reduce intake", which refutes the claim we encode.
"""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CURATED = ROOT / "data/demo/curated.json"
OUT = ROOT / "BioLean/Lib/GLP1Statements.lean"

# id -> (Lean claim, English text, flip polarity?)
CLAIMS = {
    "S1": (".effect semaglutide .pos (.activity GLP1R)", "semaglutide activates GLP1R", False),
    "S2": (".effect GLP1R .neg (.process feedingBehavior)", "GLP1R activity reduces food intake", False),
    "S3": (".effect glp1 .pos (.activity GLP1R)", "GLP-1 activates GLP1R", False),
    "S4": (".effect DPP4 .neg (.amount glp1)", "DPP4 degrades GLP-1", False),
    "S5": (".effect sitagliptin .neg (.activity DPP4)", "sitagliptin inhibits DPP4", False),
    "S6": (".effect GLP1R .neg (.process gastricEmptying)", "GLP1R activity delays gastric emptying", False),
    "S7": (".effect semaglutide .neg (.process feedingBehavior)", "semaglutide reduces food intake and body weight in humans", False),
    "S8": (".effect sitagliptin .neg (.process feedingBehavior)", "sitagliptin reduces food intake or body weight", True),
    "S9a": (".mediatedBy GLP1R .neg (.process feedingBehavior) (.phenotype nausea)", "the anorectic effect of GLP1R agonism is mediated by nausea", False),
    "S9b": (".mediatedBy GLP1R .neg (.process feedingBehavior) (.phenotype nausea)", "the anorectic effect of GLP1R agonism is mediated by nausea", True),
    "S9c": (".mediatedBy semaglutide .neg (.process feedingBehavior) (.site hypothalamus)", "semaglutide acts centrally, crossing the blood-brain barrier into the hypothalamus", False),
    "S9d": (".mediatedBy semaglutide .neg (.process feedingBehavior) (.site areaPostrema)", "semaglutide acts via circumventricular organs and vagal afferents", False),
}


def esc(s: str) -> str:
    return " ".join(s.replace("\\", "\\\\").replace('"', "'").split())[:160]


def main() -> None:
    curated = {s["id"]: s for s in json.loads(CURATED.read_text())}
    out = ["import BioLean", "import BioLean.Lib.Entities", "",
           "/-! Rendered from `data/demo/curated.json` by `scripts/demo/05_render_lean.py`. Do not edit by hand.",
           "Every quote is a verified substring of the cited abstract. -/", "",
           "namespace BioLean.Lib", ""]
    names = []
    for sid, (claim, text, flip) in CLAIMS.items():
        ev = curated[sid]["evidence"]
        name = sid
        names.append(name)
        out += [f"/-- {esc(curated[sid]['statement'])} -/", f"def {name} : Statement where",
                f'  id := "{sid}"', f'  text := "{text}"', f"  claim := {claim}", "  evidence := ["]
        rows = []
        for e in ev:
            pol = e["polarity"]
            if flip:
                pol = "refutes" if pol == "supports" else "supports"
            rows.append(f'    {{ pmid := {e["pmid"]}, year := {e["year"]}, kind := .{e["kind"]}, '
                        f'polarity := .{pol}, note := "{esc(e["note"])}" }}')
        out += [",\n".join(rows), "  ]", ""]
    out += [f"def glp1Statements : List Statement := [{', '.join(names)}]", "", "end BioLean.Lib", ""]
    OUT.write_text("\n".join(out))
    print(f"wrote {OUT} with {len(names)} statements")


if __name__ == "__main__":
    main()

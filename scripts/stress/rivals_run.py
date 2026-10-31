"""Run program 03's Lean files, record what they print, then pin it.

  1. rivals_gen.py writes unpinned BioLean/Stress/Rivals.lean and BioLean/Proto/Multinomial.lean.
  2. `lake env lean` runs each; every `OBS|...` line is parsed into data/stress/03/observed_*.json.
  3. rivals_gen.py --pin writes the files again with every observation pinned as a theorem.
  4. `lake env lean` checks the pinned files: no errors, no `sorry`, timed.

Usage (repo root):  python3 scripts/stress/rivals_run.py
Writes only under data/stress/03/, BioLean/Stress/Rivals.lean and BioLean/Proto/Multinomial.lean.
"""
import json, os, subprocess, sys, time

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
DATA = os.path.join(ROOT, "data", "stress", "03")
STRESS = "BioLean/Stress/Rivals.lean"
PROTO = "BioLean/Proto/Multinomial.lean"


def lean(path):
    t = time.time()
    p = subprocess.run(["lake", "env", "lean", path], cwd=ROOT, capture_output=True, text=True)
    return p.returncode, p.stdout + p.stderr, time.time() - t


def parse_stress(out):
    obs = {}
    for l in out.splitlines():
        if not l.startswith("OBS|"): continue
        _, t, c, v, y, rid, b, d, verdict = l.split("|")
        obs.setdefault(t, {}).setdefault(c, {}).setdefault(v, {}).setdefault(y, []).append([rid, b, d, verdict])
    return obs


def parse_proto(out):
    obs = {}
    for l in out.splitlines():
        if not l.startswith("OBS|"): continue
        _, c, fr, model, y, cell, b, d, verdict, extra = l.split("|")
        rows = obs.setdefault(c, {}).setdefault(fr, {}).setdefault(y, [])
        row = next((r for r in rows if r["cell"] == cell and model not in r), None)
        if row is None:
            row = {"cell": cell}
            rows.append(row)
        row[model] = [b, d, verdict, extra]
    return obs


def problems(out):
    bad = [l for l in out.splitlines() if ("error" in l and not l.startswith("OBS|")) or "sorry" in l]
    return bad


def main():
    os.makedirs(DATA, exist_ok=True)
    log = []
    subprocess.run([sys.executable, os.path.join(HERE, "rivals_gen.py")], cwd=ROOT, check=True)
    rc, out, dt = lean(STRESS)
    if rc or problems(out): sys.exit("stress file failed:\n" + "\n".join(problems(out)[:20]))
    cur = parse_stress(out)
    log.append(f"unpinned {STRESS}: {dt:.1f} s, {sum(l.startswith('OBS|') for l in out.splitlines())} OBS lines")
    rc, out2, dt = lean(PROTO)
    if rc or problems(out2): sys.exit("proto file failed:\n" + "\n".join(problems(out2)[:20]))
    pro = parse_proto(out2)
    log.append(f"unpinned {PROTO}: {dt:.1f} s, {sum(l.startswith('OBS|') for l in out2.splitlines())} OBS lines")
    json.dump(cur, open(os.path.join(DATA, "observed_current.json"), "w"), indent=0)
    json.dump(pro, open(os.path.join(DATA, "observed_proto.json"), "w"), indent=0)
    open(os.path.join(DATA, "lean_output_current.txt"), "w").write(out)
    open(os.path.join(DATA, "lean_output_proto.txt"), "w").write(out2)
    subprocess.run([sys.executable, os.path.join(HERE, "rivals_gen.py"), "--pin"], cwd=ROOT, check=True)
    for path in (STRESS, PROTO):
        src = open(os.path.join(ROOT, path)).read()
        npins = src.count(":= by decide") + src.count("by decide +kernel\n") - src.count(":= by decide +kernel\n") * 0
        rc, o, dt = lean(path)
        bad = problems(o)
        warn = [l for l in o.splitlines() if "warning" in l]
        theorems = sum(1 for l in src.splitlines() if l.startswith("theorem "))
        log.append(f"pinned {path}: exit {rc}, {dt:.1f} s, {theorems} theorems, {len(bad)} error or sorry lines, {len(warn)} warnings")
        if rc or bad: sys.exit(f"pinned {path} failed:\n" + "\n".join(bad[:30]))
    open(os.path.join(DATA, "run_log.txt"), "w").write("\n".join(log) + "\n")
    print("\n".join(log))


if __name__ == "__main__":
    main()

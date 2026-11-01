"""Program 10a, option D: an automatic "same source" key for papers.

Two papers are joined when they share a first or a last author (Europe PMC author lists); groups are
the connected components. Collective authors ("... Investigators", "... Group") are ignored. This is
the cheapest key an importer could compute; the curated key (cohort, trial, lab) is by hand in
`BioLean/Stress/Weights.lean`. Writes data/stress/10a/groups_auto.tsv and prints the Lean table.

usage: python3 -I scripts/stress/weights_groups.py META.json OUT.tsv
META.json is the output of weights_epmc_fetch.py (untrusted data; read with python3 -I).
"""
import json
import sys


def ends(authors):
    """First and last author, case-folded: Europe PMC writes 1950s names in capitals ("DOLL R")."""
    names = [a for a in authors if a and not any(w in a for w in ("Investigat", "Group", "Collaborat", "Writing", "Study"))]
    return {names[0].casefold(), names[-1].casefold()} if names else set()


def main():
    meta = json.load(open(sys.argv[1]))
    out = sys.argv[2]
    pmids = sorted(meta, key=int)
    parent = {p: p for p in pmids}

    def find(x):
        while parent[x] != x:
            parent[x] = parent[parent[x]]
            x = parent[x]
        return x

    by_author = {}
    for p in pmids:
        for a in ends(meta[p].get("authors", [])):
            by_author.setdefault(a, []).append(p)
    for a, ps in by_author.items():
        for q in ps[1:]:
            parent[find(q)] = find(ps[0])
    comps = {}
    for p in pmids:
        comps.setdefault(find(p), []).append(p)
    groups = [sorted(c, key=int) for c in comps.values() if len(c) > 1]
    groups.sort(key=lambda c: int(c[0]))
    with open(out, "w") as f:
        f.write("group\tpmid\tyear\tfirst_author\tlast_author\ttitle\n")
        for g in groups:
            key = "auto:" + g[0]
            for p in g:
                v = meta[p]
                au = v.get("authors") or [""]
                f.write(f"{key}\t{p}\t{v.get('year')}\t{au[0]}\t{au[-1]}\t{(v.get('title') or '')[:120]}\n")
    pairs = ", ".join(f"({p}, \"auto:{g[0]}\")" for g in groups for p in g)
    print(f"{len(groups)} groups, {sum(len(g) for g in groups)} papers")
    print(f"def autoGroup : List (Nat × String) := [{pairs}]")


if __name__ == "__main__":
    main()

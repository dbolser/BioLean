"""Estimate the textbook 'now' bin after M1: claims whose missing construct is an RO relation that
Claim.rel can now hold are counted as expressible. Heuristic over missing_construct names only."""
import json, glob, collections, re
RO_FAMILIES = re.compile(r'^(is_a|has_part|part_of|made_of|contains|located_in|occurs_in|occurs_during|'
                         r'has_input|has_output|capable_of|has_function|enables|precedes|sequence|'
                         r'connects|continuous_with|transport|binding|negation|lacks|derives_from|overlaps|adjacent)', re.I)
tot = collections.Counter(); before = collections.Counter(); after = collections.Counter(); hit = collections.Counter()
for p in glob.glob('data/textbook/claims/*.json'):
    for r in json.load(open(p)):
        b = r.get('bin');
        if b == 'not_claim': continue
        tot['claims'] += 1; before[b] += 1
        mc = (r.get('missing_construct') or '').strip()
        if b == 'missing_construct' and RO_FAMILIES.match(mc):
            after['now (via Claim.rel)'] += 1; hit[mc.split(' (')[0].split('/')[0].strip().lower()] += 1
        else: after[b] += 1
n = tot['claims']
print(f"claims {n}")
print("before:", {k: f"{v} ({100*v/n:.1f}%)" for k, v in before.most_common()})
print("after M1:", {k: f"{v} ({100*v/n:.1f}%)" for k, v in after.most_common()})
now = before['now'] + after['now (via Claim.rel)']
print(f"expressible now: {before['now']} -> {now} ({100*now/n:.1f}%); with_context on top: {100*(now+before['with_context'])/n:.1f}%")
print("moved by family:", hit.most_common(12))

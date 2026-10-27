"""Aggregate the M1 re-annotation in data/textbook/claims_m1/*.json.
bin_m1 overrides bin where present; not_claim records are excluded.
Prints the bin split, RO relations used (rel_m1 on now/with_context), and the still-missing reasons
(lean_m1 on missing_construct) folded into coarse groups, each with one example."""
import collections, glob, json, re, sys

GROUPS = [  # first match wins; pattern is tested against the lower-cased reason
    ('grounding (ungrounded, mis-grounded, kind/sort mismatch)', r'ground|entity|kind|sort mismatch|source conflict|sequence_feature|class not in record'),
    ('quantity / quantifier / universal / existential', r'quantit|quantifier|universal|existential|superlative|probab|equation'),
    ('compound (conjunction, multi-argument, relative clause, n-ary)', r'conjunction|multi-arg|compound|relative clause|n-ary|3-place|disjunction'),
    ('is_a with extra predicate / definition', r'^is_a|definition|process description'),
    ('relation with no RO term', r'no ro|unmapped|vague|binds|binding|synonym|naming|equality|identity|spatial|geometry|articulation|connects|encodes|polymer|differs|similar|associat|surrounded|fuses|inherited|converts|located_between|separated|treats|uses|synapse|secretion|coordination|correlation|calibrated|variant|in place|contrast|implies|sufficient|relation|catalyzes|homology|evolution|ecological|derivation|made_of|composition|adjacent|located_in|occurs_in|part_of|has_part|has_input|has_output|process output'),
    ('effect / regulation sign, causal, mechanism', r'regulat|effect|causal|mechanism|change|disease|function|role|transport|signalling|unnamed process'),
    ('sequence / temporal / historical', r'sequence|temporal|historical'),
    ('necessity / conditional / modality / counterfactual', r'necess|condition|modal|possib|counterfactual|negation|independ|intent|specificity'),
    ('has_quality / comparison / variation', r'quality|compar|vari|observab'),
    ('context / scope / qualifier', r'context|scope|qualifier'),
    ('procedure / method', r'procedure|method'),
]

def group(reason):
    r = (reason or '').lower()
    for name, pat in GROUPS:
        if re.search(pat, r): return name
    return 'other'

def main(paths):
    split, rel, miss, raw = (collections.Counter() for _ in range(4)); ex = {}
    for p in paths:
        for x in json.load(open(p)):
            b = x.get('bin_m1') or x.get('bin')
            if x.get('bin') == 'not_claim' or b == 'not_claim': continue
            split[b] += 1
            if 'bin_m1' in x and b in ('now', 'with_context') and x.get('rel_m1'): rel[x['rel_m1']] += 1
            if x.get('bin_m1') == 'missing_construct':
                g = group(x.get('lean_m1')); miss[g] += 1; raw[(x.get('lean_m1') or '').split(' (')[0].lower()] += 1
                ex.setdefault(g, f"{x['id']}: {x['claim']}")
    n = sum(split.values())
    print(f'claims {n}')
    for k in ('now', 'with_context', 'missing_construct'): print(f'{k}\t{split[k]}\t{100*split[k]/n:.1f}%')
    print('\nrelations used (now + with_context)')
    for k, v in rel.most_common(): print(f'{v}\t{k}')
    print('\nstill missing (grouped)')
    for k, v in miss.most_common(): print(f'{v}\t{k}\t{ex[k]}')
    print(f'\n{len(raw)} distinct raw reason labels')

if __name__ == '__main__':
    main(sys.argv[1:] or sorted(glob.glob('data/textbook/claims_m1/*.json')))

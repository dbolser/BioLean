"""Rate the program 07 facts one at a time, two keypresses each. Saves after every fact; quit and come back any time.

    python3 scripts/stress/rate.py

Keys: 0 1 2 3 = interesting (as if true), then y n ? = true. b = back one, s = skip, q = quit.
Writes data/stress/07/rating_dan.tsv, which scripts/stress/ic_analysis.py reads."""
import csv, os, re, sys, termios, tty, textwrap

D = 'data/stress/07'
SHEET, OUT = f'{D}/rating_sheet_blind.tsv', f'{D}/rating_dan.tsv'
HELP = ('interesting, as if true:  0 trivial or restated   1 obvious   2 worth stating   3 surprising\n'
        'true:                     y yes   n no   ? unsure          b back   s skip   q quit')

def key(allowed):
    fd = sys.stdin.fileno(); old = termios.tcgetattr(fd)
    try:
        tty.setcbreak(fd)
        while (k := sys.stdin.read(1).lower()) not in allowed: pass
        return k
    finally: termios.tcsetattr(fd, termios.TCSADRAIN, old)

def main():
    src = OUT if os.path.exists(OUT) else SHEET
    with open(src, newline='') as f:
        r = csv.DictReader(f, delimiter='\t'); fields, rows = r.fieldnames, list(r)
    def save():
        with open(OUT, 'w', newline='') as f:
            out = csv.DictWriter(f, fields, delimiter='\t'); out.writeheader(); out.writerows(rows)
    w = lambda s: textwrap.fill(s, 100, subsequent_indent='    ')
    i = next((n for n, x in enumerate(rows) if not x['interesting']), len(rows))
    while i < len(rows):
        x = rows[i]; done = sum(1 for y in rows if y['interesting'])
        print('\033[H\033[2J\033[3J', end='', flush=True); os.system('clear')
        print(f'Fact {i + 1} of {len(rows)}   ({done} rated so far)\n')
        print('BioLean derived this fact:\n')
        print('    \033[1m' + w(x['fact']) + '\033[0m\n')
        print('It got there by joining these textbook sentences:\n')
        for p in x['premise_sentences'].split(' | '): print('    ' + w(re.sub(r'^(\(\d+\)) \S+: ', r'\1 ', p)) + '\n')
        print(HELP + '\n')
        print('interesting? ', end='', flush=True)
        k = key('0123bsq')
        if k == 'q': break
        if k == 'b': i = max(0, i - 1); continue
        if k == 's': i += 1; continue
        print(k + '   true? ', end='', flush=True)
        t = key('yn?bq')
        if t == 'q': break
        if t == 'b': continue
        x['interesting'], x['true'] = k, {'y': 'yes', 'n': 'no', '?': 'unsure'}[t]
        save(); i += 1
    save()
    done = sum(1 for y in rows if y['interesting'])
    print(f'\n\nSaved {done} of {len(rows)} to {OUT}.' + (' All done: run  python3 scripts/stress/ic_analysis.py' if done == len(rows) else ' Run again to carry on.'))

if __name__ == '__main__': main()

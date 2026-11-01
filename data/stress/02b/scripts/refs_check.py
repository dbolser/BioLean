"""Check every paper program 02b cites: title and first author on Europe PMC (by PMID) or Crossref (by DOI), and each
quote as a verbatim substring of the Europe PMC abstract. Writes data/stress/02b/refs.tsv.
Records are cached in /tmp/biolean-02b/dl/epmc2 (untrusted; run with python3 -I).
Usage (repo root): python3 -I data/stress/02b/scripts/refs_check.py
"""
import json, re, pathlib, urllib.request, urllib.parse, time, html

DL = pathlib.Path('/tmp/biolean-02b/dl/epmc2'); DL.mkdir(parents=True, exist_ok=True)
# key, PMID or DOI, first author surname, title words, quotes (verbatim in the abstract; [] = title only), used for
REFS = [
 ('Argoud1987', '3297890', 'Argoud', 'Insulin suppresses its own secretion', ['a dose-dependent suppression of prehepatic insulin production'], 'L01 note'),
 ('Hirsch2001', '15758481', 'Hirsch', 'Calcitonin, an enigmatic hormone', ['are no longer considered as physiological functions'], 'L04'),
 ('Morrison2019', '30256726', 'Morrison', 'Central Mechanisms for Thermoregulation', ['Maintenance of a homeostatic body core temperature is a critical brain function', 'cutaneous vasoconstriction regulating heat loss and shivering and brown adipose tissue for heat production'], 'L05, T03'),
 ('Kondo2004', '14613925', 'Kondo', 'Osmoregulation of vasopressin release', ['the thresholds of plasma Na for AVP release were significantly decreased only in the PEG group', 'Plasma AVP levels were correlated with plasma Na levels in all groups'], 'L06, T04'),
 ('Juul2012', '22374125', 'Juul', 'vasopressin/V2-type receptor/aquaporin axis', ['by controlling the elimination/reabsorption of fluid trough stimulating V2-type receptors to mobilize aquaporin water channels'], 'L06'),
 ('Bourque2008', '18509340', 'Bourque', 'Central mechanisms of osmosensation', ['changes in plasma osmolality, detected by osmoreceptors, modulate ingestive behaviour, sympathetic outflow and renal function to stabilize the tonicity'], 'L06'),
 ('Guyton1991', '2063193', 'Guyton', 'Blood pressure control', ['Several are based on neural receptors that respond within seconds', 'This kidney-fluid system is the dominant method of establishing long-term pressure control.'], 'L07'),
 ('Chopra1975', '1117981', 'Chopra', 'endemic goiter regions of New Guinea', ['supranormal serum TSH', 'supranormal serum T3', 'subnormal serum T4'], 'L09'),
 ('OrtigaCarvalho2016', '27347897', 'Ortiga-Carvalho', 'Hypothalamus-Pituitary-Thyroid Axis', ['control the secretion of TRH and TSH by negative feedback', 'Reduction of circulating TH levels due to primary thyroid failure results in increased TRH and TSH production'], 'L08, L09'),
 ('Herman2016', '27065163', 'Herman', 'Hypothalamic-Pituitary-Adrenocortical Stress Response', ['Glucocorticoids also act at the PVN to rapidly inhibit CRH neuronal activity', 'Stress responses are inhibited by negative feedback mechanisms'], 'L10'),
 ('Aouizerate2006', '16759341', 'Aouizerate', 'Glucocorticoid negative feedback', ['Multiple dose dexamethasone suppression tests'], 'L11'),
 ('Nieman2008', '18334580', 'Nieman', "The diagnosis of Cushing's syndrome", ['1 mg overnight or 2 mg 48-h dexamethasone suppression test'], 'L11'),
 ('Jelkmann2011', '21078592', 'Jelkmann', 'Regulation of erythropoietin production', ['The hormone erythropoietin (Epo) maintains red blood cell mass'], 'L12'),
 ('Guyenet2015', '26335642', 'Guyenet', 'Neural Control of Breathing and CO2 Homeostasis', ['are activated by PCO2 and stimulate breathing', 'mediate rapid stabilization of arterial PCO2 and pH'], 'L13'),
 ('Buckley2005', '16219068', 'Buckley', 'The control of stomata by water balance', ["hydro-active local feedback", 'stomata play a critical role in regulating water loss'], 'L14'),
 ('Ahima1996', '8717038', 'Ahima', 'Role of leptin in the neuroendocrine response to fasting', ["it is proposed to act as a negative feedback 'adipostatic signal'", 'Leptin concentration falls during starvation'], 'L17'),
 ('Eisenstein1991', '2005118', 'Eisenstein', 'biosynthetic threonine deaminase from Escherichia coli', ['Feedback inhibition of the regulatory enzyme threonine deaminase by isoleucine'], 'L18'),
 ('Atkinson1968', '4972613', 'Atkinson', 'The energy charge of the adenylate pool', [], 'L19'),
 ('Russell2003', '12609499', 'Russell', 'The magnocellular oxytocin system', ['Oxytocin secretion from the posterior pituitary gland is increased during parturition, stimulated by the uterine contractions', 'a positive feedback loop is activated'], 'P01'),
 ('Panteleev2010', '20441738', 'Panteleev', 'trigger mechanism in blood coagulation', ['a single positive feedback of factor V activation by thrombin'], 'P02'),
 ('Hoffman2001', '11434702', 'Hoffman', 'A cell-based model of hemostasis', ['to set the stage for large scale thrombin generation'], 'P02'),
 ('Esmon2003', '12970121', 'Esmon', 'The protein C pathway', ['it inactivates factors Va and VIIIa, thereby inhibiting further thrombin generation', 'augmenting protein C'], 'P03'),
 ('Hodgkin1952', '12991237', 'Hodgkin', 'A quantitative description of membrane current', [], 'P04, P05'),
 ('Christian2010', '20237240', 'Christian', 'preovulatory and estradiol-induced gonadotropin-releasing hormone surges', ['Ovarian steroids normally exert homeostatic negative feedback on GnRH release', 'the feedback action of estradiol switches to positive'], 'P06'),
 ('Alexander2002', '12324528', 'Alexander', 'Ethylene biosynthesis and action in tomato', ['initiation and subsequent autocatalytic phase of ethylene production during ripening'], 'P07'),
 ('Protsiv2020', '31908267', 'Protsiv', 'Decreasing human body temperature', ['lower than the canonical 37°C established in the 19th century', 'has decreased monotonically by 0.03°C per birth decade'], 'S01'),
 ('Cabanac2006', '16540712', 'Cabanac', 'Adjustable set point', ['concludes that to abandon the concepts of set point, fever, and anapyrexia is premature', 'the "error signal," is the difference between the actual temperature and the set point'], 'S02'),
 ('Biddle2006', '16617919', 'Biddle', 'The neurobiology of the human febrile response', ['Fever differs from hyperpyrexia and hyperthermia associated with hot environs'], 'S03'),
 ('Porte1966', '5327883', 'Porte', 'Inhibition of insulin release by norepinephrine in man', ['norepinephrine inhibits the release of insulin from pancreatic beta cells'], 'N04'),
 ('Kris1966', '4955799', 'Kris', 'Inhibition of insulin secretion by infused epinephrine in rhesus monkeys', [], 'N04'),
 ('Porte1967', '6018752', 'Porte', 'A receptor mechanism for the inhibition of insulin release by epinephrine in man', ['These findings are compatible with an alpha receptor mechanism for the epinephrine inhibition of insulin release'], 'C11'),
 ('Gardner2000', '10659857', 'Gardner', 'Construction of a genetic toggle switch in Escherichia coli', ['The toggle is constructed from any two repressible promoters arranged in a mutually inhibitory network'], 'P08'),
 ('Samols1965', '14346763', 'Samols', 'PROMOTION OF INSULIN SECRETION BY GLUCAGON', [], 'N05'),
 ('Teff2011', '21256146', 'Teff', 'anticipatory and compensatory insulin release', ['cephalic phase insulin and pancreatic polypeptide release'], 'N06'),
 ('Sterling2012', '21684297', 'Sterling', 'Allostasis: a model of predictive regulation', ['homeostasis (error-correction by feedback) is inherently inefficient'], 'limits'),
 ('Thomas1998', '9654035', 'Thomas', 'Laws for the dynamics of regulatory networks', ['Two laws give the minimal logical ingredients required for differentiative and homeostatic regulations'], 'option F'),
 ('Ozbudak2004', '14973486', 'Ozbudak', 'Multistability in the lactose utilization network', ['However, feedback alone does not guarantee multistability.'], 'limits'),
 ('Yi2000', '10781070', 'Yi', 'Robust perfect adaptation in bacterial chemotaxis', ['the robustness of perfect adaptation is the result of this system possessing the property of integral feedback control'], 'limits'),
 ('ElSamad2002', '11786029', 'El-Samad', 'Calcium homeostasis and parturient hypocalcemia', ['identify integral feedback control as a functional module that maintains this homeostasis'], 'T02'),
 ('Alon2007', '17510665', 'Alon', 'Network motifs: theory and experimental approaches', [], 'survey'),
 ('Kotas2015', '25723161', 'Kotas', 'Homeostasis, inflammation, and disease susceptibility', ['adaptability of homeostatic systems with adjustable set points creates vulnerability'], 'survey'),
 ('Modell2015', '26628646', 'Modell', "A physiologist's view of homeostasis", ['Walter Cannon introduced the term "homeostasis"'], 'survey'),
 ('Courtot2011', '22027554', 'Courtot', 'Controlled vocabularies and semantics in systems biology', ['The Systems Biology Ontology (SBO) provides semantic information about the model components'], 'survey (TEDDY)'),
 ('Gavin1974', '4359334', 'Gavin', 'Insulin-dependent regulation of insulin receptor concentrations', ['acute exposure (0-2 hr) was without effect'], 'T05'),
 ('Benarroch2008', '19015490', 'Benarroch', 'The arterial baroreflex', [], 'L07'),
 ('Cannon1929', '10.1152/physrev.1929.9.3.399', 'Cannon', 'ORGANIZATION FOR PHYSIOLOGICAL HOMEOSTASIS', [], 'survey'),
 ('Kuipers1986', '10.1016/0004-3702(86)90073-1', 'Kuipers', 'Qualitative simulation', [], 'survey'),
 ('Forbus1984', '10.1016/0004-3702(84)90038-9', 'Forbus', 'Qualitative process theory', [], 'survey'),
]

def get(url, f):
    if not f.exists() or f.stat().st_size == 0:
        with urllib.request.urlopen(url, timeout=40) as r: f.write_bytes(r.read())
        time.sleep(0.15)
    return json.loads(f.read_text())

def norm(t): return re.sub(r'\s+', ' ', html.unescape(re.sub(r'<[^>]+>', '', t or ''))).strip()

def main():
    rows, bad = [], 0
    for key, ident, au, title_words, quotes, used in REFS:
        if ident.startswith('10.'):
            d = get('https://api.crossref.org/works/' + urllib.parse.quote(ident), DL / ('crossref_' + re.sub(r'[^A-Za-z0-9]', '_', ident) + '.json'))['message']
            title = norm((d.get('title') or [''])[0]); first = (d.get('author') or [{}])[0].get('family', ''); year = (d.get('issued', {}).get('date-parts') or [[None]])[0][0]
            abstract, where = '', 'Crossref'
        else:
            d = get('https://www.ebi.ac.uk/europepmc/webservices/rest/search?' + urllib.parse.urlencode({'query': f'EXT_ID:{ident} AND SRC:MED', 'format': 'json', 'resultType': 'core'}), DL / f'{ident}.json')
            r = (d.get('resultList', {}).get('result') or [{}])[0]
            title = norm(r.get('title')); first = (r.get('authorString') or '').split(',')[0]; year = r.get('pubYear')
            abstract, where = norm(r.get('abstractText')), 'Europe PMC'
        t_ok = title_words.lower() in title.lower(); a_ok = au.lower() in first.lower()
        q_ok = [q for q in quotes if q in abstract]
        status = 'OK' if t_ok and a_ok and len(q_ok) == len(quotes) else 'CHECK'
        bad += status != 'OK'
        rows.append([key, ident, where, first, str(year), title, 'yes' if t_ok else 'NO', 'yes' if a_ok else 'NO',
                     f'{len(q_ok)}/{len(quotes)}' if quotes else 'title only', ' | '.join(quotes), used, status])
    with open('data/stress/02b/refs.tsv', 'w') as f:
        f.write('key\tid\tchecked_on\tfirst_author\tyear\ttitle\ttitle_match\tauthor_match\tquotes_verbatim\tquotes\tused_for\tstatus\n')
        for r in rows: f.write('\t'.join(r) + '\n')
    print(f'{len(rows)} references; not OK: {bad}')
    for r in rows:
        if r[-1] != 'OK': print('  ', r[0], r[3], r[6], r[7], r[8])

if __name__ == '__main__': main()

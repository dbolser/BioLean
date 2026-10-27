# Shared brief for formalism annotators

Input: `data/formalisms/abstracts.json` (11 papers; field `abstract_is_summary` = true means the text is a
labelled secondary-source summary because the scanned paper has no abstract on record; annotate it anyway
but mark provenance as "summary").

Topics:
- Chemiosmotic controversy: Mitchell 1961 (hypothesis), Slater 1953 (rival chemical-intermediate hypothesis),
  Jagendorf & Uribe 1966, Mitchell & Moyle 1967, Hinkle & Horstman 1971, Racker & Stoeckenius 1974.
- NMN: Yoshino 2011, Gomes 2013, Mills 2016, Das 2018 (all mice), Yoshino 2021 (human RCT).

Task: annotate EVERY paper's main findings in your assigned formalism, as faithfully to that formalism's
real syntax and conventions as you can. Then assess fit.

Rules:
- Use real identifiers (CHEBI, UniProt, GO, HP, MP, MONDO, UBERON, CL, NCBITaxon, PATO, ECO, RO, BFO).
  Look them up with the OLS4 API, e.g. https://www.ebi.ac.uk/ols4/api/search?q=proton%20motive%20force&ontology=go
  If you cannot verify an ID, write `?:unverified` rather than guessing.
- Capture CONTEXT wherever the formalism allows: species, strain, age, tissue/cell, disease model, dose,
  duration, sex, in vitro vs in vivo, direction of effect, and whether a statement is a hypothesis,
  a prediction, or an experimental result.
- Capture the CONTROVERSY structure if the formalism allows: Slater and Mitchell are rival hypotheses;
  Jagendorf, Hinkle, Racker are evidence for Mitchell and against the chemical intermediate.
- For each paper, after the annotation, list in a short bullet list what you could NOT express.

Output: write to `docs/formalisms/<your-formalism>.md`, INCREMENTALLY (write after every paper so partial
work survives). Structure:
1. One paragraph: the formalism, what a unit of annotation is, where context lives.
2. Per paper: PMID, 3-10 annotation units in the formalism's syntax (code block), then "Could not express:".
3. A fit table: rows = {direction of effect, quantitative result, species/strain, age/stage, tissue/cell,
   disease model, dose/duration, hypothesis-vs-result, rival hypotheses, evidence type, cross-species
   transfer, negative results}; columns = {expressible? yes/partial/no, how}.
4. Verdict: 5 sentences on natural fit for (a) the mechanistic chemiosmotic papers, (b) the
   phenotype-in-mice NMN papers. Be blunt about where the formalism is awkward.

Do not edit any other file. Do not read other annotators' files.

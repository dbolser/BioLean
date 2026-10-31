<!-- First draft of rubric.md, kept for provenance only: the three LLM stand-in ratings (rating_llm_*.tsv) were made
with it. Do not rate with this file; use rubric.md. Six of its worked examples were near-twins of sheet rows. -->

# Rating rubric: derived facts

Use `rating_sheet_blind.tsv` (it has no IC column). Each row is one fact the closure derived from textbook
sentences. Read `fact`, glance at `derivation` and `premise_sentences`, then fill three columns. Aim for about a
minute a row, so about two hours for 100 rows. If a row takes more than two minutes, write `unsure` and move on.
`rating_sheet_old9_blind.tsv` is optional: 9 more rows, the old rated facts the closure no longer derives.

**How to read a fact.** "S has as a part O" means every S has some O as a part. "S raises O" means S raises O,
directly or through the chain shown. Words in (round brackets) are a context: "Brain (in Insecta)" is the insect
brain. Words in [square brackets] are the ontology's own name for the term. If that name changes the meaning, say
so in `note`.

## interesting (0 to 3): rate it as if it were true

If a fact would be surprising were it true, rate it high even if you think it is false. Put the falsity in `true`.

| level | meaning | quick test |
|---|---|---|
| 0 | trivial, or a restatement | adds nothing to its premises: a generic subject (cell, body, tissue); the same fact for a narrower context; a weaker form of a premise |
| 1 | obvious but real | joins two premises; anyone who knows both sees it at once |
| 2 | worth stating | a link a student might not make alone; joins different topics; a teacher might use it |
| 3 | surprising, worth checking | you would stop and look it up: a link you did not expect |

Worked examples. None of these is on either sheet. The text is exactly as a sheet would show it.

| level | fact | why |
|---|---|---|
| 0 | Cells has as a part proteins. | about every cell; restates "membranes have proteins" |
| 0 | Telomerase (part of adult somatic cells) (existing during adult) is a kind of telomerase. | says "X in a context is X" |
| 0 | DNA-templated transcription takes as input polymer. | weaker than its own premise, "takes as input DNA" |
| 1 | Axial skeleton has as a part cranial bone. | skull is in the axial skeleton; cranial bones are in the skull |
| 1 | Meiosis II is part of sexual reproduction. | two textbook part-of steps |
| 1 | Transfer RNA has as a part uracil. | tRNA is RNA; RNA has uracil |
| 2 | Respiratory system inhibits erythropoiesis (occurring in bone marrow) [erythrocyte differentiation]. | more oxygen, less EPO, fewer new red cells: joins two topics |
| 2 | Capillaries [capillary] promotes this reaction [aerobic respiration]. | vessels deliver oxygen; oxygen drives aerobic respiration |
| 2 | ATP synthase promotes muscle cell contraction [muscle contraction]. | ATP synthase makes ATP; ATP powers contraction |
| 3 | Glucagon (located in blood) raises the amount of insulin (located in blood). | two opposing hormones, yet one raises the other, through blood glucose |
| 3 | Meiosis (in animals) [meiotic cell cycle] happens during mitotic phase [mitotic M phase]. | would be startling if true; it is false, and shows "cell division happens in M phase" read as true of every division |
| 3 | Antibodies [immunoglobulin complex] lowers the amount of antibodies (located in immune system) [immunoglobulin complex]. | a loop: clearing the virus removes the trigger for more antibody |

## true (yes, no, unsure)

| value | meaning | example |
|---|---|---|
| yes | true of the subject as a class, in the context the fact names (or the book's normal context) | Transfer RNA has as a part uracil. |
| no | false for the subject, or false for a large, standard part of it ("cells have a nucleus" fails for bacteria) | Meiosis (in animals) [meiotic cell cycle] happens during mitotic phase [mitotic M phase]. |
| unsure | you would need to check, or it depends on the reading (a direct effect against an indirect one) | Antibodies [immunoglobulin complex] lowers the amount of antibodies (located in immune system) [immunoglobulin complex]. |

`interesting` and `true` are separate. A false fact can still be a 3.

## note

Free text. Useful notes: "wrong ontology term", "unreadable", "true only in humans", "already a sentence in the
book", "same as row R0xx".

The example levels above are my judgement (an LLM). If you disagree with one, that is useful: write it down.

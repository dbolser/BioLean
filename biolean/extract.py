"""Stage 2: extract typed, quoted statements from one abstract with Claude (structured outputs)."""

import json
from typing import Literal

import anthropic
from pydantic import BaseModel

from biolean.corpus import Abstract

MODEL = "claude-opus-5-5"

Kind = Literal["chemical", "protein", "gene", "process", "phenotype", "disease", "anatomy", "cell_type"]
Relation = Literal[
    "increases_activity", "decreases_activity",
    "increases_amount", "decreases_amount",
    "increases_process", "decreases_process",
    "increases_phenotype", "decreases_phenotype",
]


class Mention(BaseModel):
    mention: str
    kind: Kind


class Extracted(BaseModel):
    quote: str
    subject: Mention
    relation: Relation
    object: Mention
    polarity: Literal["supports", "refutes"]
    evidence_kind: Literal["meta_analysis", "rct", "mechanistic", "observational", "review", "in_vitro", "other"]
    species: str
    hedged: bool


class ExtractionResult(BaseModel):
    pmid: int
    statements: list[Extracted]


SYSTEM = """\
You extract causal biomedical statements from one PubMed abstract.

Rules:
- Extract only relations the text itself asserts. Do not add background knowledge. One statement per sentence-level claim.
- subject.kind is one of: chemical, protein, gene.
- object.kind must match the relation family:
  - *_activity  -> object is a protein
  - *_amount    -> object is a chemical or protein
  - *_process   -> object is a biological process
  - *_phenotype -> object is a phenotype or disease
- mention is the shortest name used in the text (e.g. "semaglutide", "GLP-1R", "body weight"), without dose or modifiers.
- quote is the full sentence that asserts the relation, copied verbatim, character for character.
- hedged is true if the claim is qualified ("may", "might", "could", "likely", "suggest").
- evidence_kind is the study design the abstract states for this finding (meta_analysis, rct, mechanistic, observational, review, in_vitro); use other if none is stated.
- polarity is refutes for explicit negative findings ("did not reduce", "no effect on", "did not differ"); otherwise supports.
- species is the organism studied (e.g. "human", "mouse"); "unknown" if not stated.
- If the abstract asserts no such relation, return an empty statements list.
"""


def user_message(abstract: Abstract) -> str:
    return f"PMID: {abstract.pmid}\nTitle: {abstract.title}\n\n{abstract.abstract}"


def extract(abstract: Abstract, client: anthropic.Anthropic | None = None) -> ExtractionResult:
    client = client or anthropic.Anthropic()
    response = client.messages.parse(
        model=MODEL,
        max_tokens=16000,
        output_config={"effort": "medium"},
        system=[{"type": "text", "text": SYSTEM, "cache_control": {"type": "ephemeral"}}],
        messages=[{"role": "user", "content": user_message(abstract)}],
        output_format=ExtractionResult,
    )
    if response.stop_reason in ("refusal", "max_tokens"):
        raise RuntimeError(f"PMID {abstract.pmid}: extraction stopped with stop_reason={response.stop_reason!r}")
    result = response.parsed_output
    if result is None:
        raise RuntimeError(f"PMID {abstract.pmid}: no parsed output (stop_reason={response.stop_reason!r})")
    return result.model_copy(update={"pmid": abstract.pmid})


def dry_run(abstract: Abstract) -> str:
    """Everything that would be sent, without calling the API."""
    schema = json.dumps(ExtractionResult.model_json_schema(), indent=2)
    return f"=== system ===\n{SYSTEM}\n=== user ===\n{user_message(abstract)}\n\n=== output schema ===\n{schema}\n"

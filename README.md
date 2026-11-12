# Citizen Science for Mental Health

This repository holds the writing and analysis behind a citizen science
movement on mental health: research in which people with lived experience take
part as partners, from choosing questions, designing methods, interpreting
findings, rather than only as participants. The focus is distress and resilience in
Indonesia, where the conditions for phone-based, citizen-centred research
exist but the practice does not yet. The working premise is simple: when many
people describe the same experience in similar words, that shared description
is evidence waiting to be given structure.

## Start reading here

Open [manuscripts/case-series-review/article.qmd](manuscripts/case-series-review/article.qmd).
It is the entry point of the first paper and pulls the sections together in
reading order:

- `blocks/_introduction.qmd` — why citizen science, why mental health, why
  Indonesia, and the three research questions
- `blocks/_methods.qmd` — how cases were selected and scored
- `blocks/_results.qmd`, `blocks/_discussion.qmd`, `blocks/_conclusion.qmd` —
  findings and what they teach
- [manuscripts/references.bib](manuscripts/references.bib) — shared
  bibliography, cited as `@citekey` throughout

## Repository layout

- `manuscripts/` — Quarto manuscripts; one directory per paper, with
  `article.qmd` as each paper's entry point
- `data/` — raw and processed data
- `src/` — analysis code (`R/`, `python/`, `shell/`)
- `.github/workflows/` — pull request checks: markdown lint and render of
  affected manuscripts

## A series of papers

The case-series review is Paper 1 of 4. Its lessons feed a set of principles
for research-ready health data (Paper 2), an assessment of an open-source
research platform against those principles (Paper 3), and a baseline study of
depression, anxiety, burnout, resilience and functioning among adults in
three Indonesian cities (Paper 4).

## Contributing

Environment setup (mise), git hooks (lefthook), linting (rumdl) and the
pull request checks are described in
[CONTRIBUTING.md](CONTRIBUTING.md).

# Contributing

Thanks for helping with this citizen science research on mental health. This
guide covers the environment (mise), the git hooks (lefthook), linting (rumdl)
and what happens when you open a pull request.

## Prerequisites

- git
- [mise](https://mise.jdx.dev/) — the version manager that installs everything
  else from this repository's `mise.toml`

## 1. Initialize the environment

```bash
mise trust     # accept this repository's mise.toml when prompted
mise install   # quarto 1.11.9 (conda-forge), rumdl 0.3.3, lefthook 2.2.2
mise x -- quarto --version   # should print 1.11.9
```

quarto is installed through mise's conda backend directly from conda-forge,
so no conda or mamba is needed. Everything is pinned in `mise.toml`; do not
install quarto, rumdl or lefthook globally for this project — CI uses the same
file.

## 2. Install the git hooks (lefthook)

```bash
mise run hooks   # runs `lefthook install`
```

Two hooks are configured in `lefthook.yml`:

- **pre-commit** — runs `mise run lint:md` on the staged `.md` and `.qmd`
  files; the job is skipped when no markdown is staged. Fix violations before
  committing, usually with `mise x -- rumdl fmt <file>`.
- **pre-push** — runs `mise run lint:md` over all repository markdown, so
  broken markdown cannot leave your machine.

Both hooks run through `mise run`, which loads the toolchain from `mise.toml`,
so they work regardless of your `PATH`.

## 3. Lint your writing

```bash
mise run lint:md        # lint all markdown and Quarto markdown (what the hooks and CI run)
mise run lint:md <path> # narrow the scope, e.g. manuscripts/case-series-review
mise x -- rumdl fmt manuscripts/  # auto-fix whitespace issues
```

`mise run lint` runs every `lint:*` task — `lint:md` today, with `lint:py` and
`lint:R` planned for other sources later.

Configuration lives in `.rumdl.toml`: `.qmd` files are linted with rumdl's
quarto flavor, while `MD013` (line length), `MD041` (first line heading) and
`MD069` (duplicate list marker) are disabled — manuscript prose is not
reflowed to 80 columns, Quarto files start with YAML frontmatter, and `- - Cell`
rows are official Quarto list-table syntax.

## 4. Writing a manuscript

- One directory per paper: `manuscripts/<id>/article.qmd` is the entry point.
  Split sections into `blocks/_*.qmd` and include them from `article.qmd`.
- Cite with `@citekey`; keys live in the shared `manuscripts/references.bib`.
- Render locally before pushing:
  `mise run render manuscripts/<id>/article.qmd`.

## 5. What a pull request must pass

CI runs on every PR (`.github/workflows/ci.yml`):

**Lint** — `mise run lint:md` (rumdl over all repository markdown), using the
toolchain from `mise.toml`.

**Render** — every affected manuscript is rendered with
`mise run render manuscripts/<id>/article.qmd` (the task wraps `quarto render`),
as a matrix with
`fail-fast: false` so one broken paper does not hide another. Rendered output
is not uploaded. Affected manuscripts are derived from the changed files by
`src/shell/affected-manuscripts.sh`, following these rules:

- a change anywhere under `manuscripts/<id>/` (where `article.qmd` exists)
  renders that manuscript
- shared or toolchain changes — files directly under `manuscripts/` (such as
  `references.bib`), `mise.toml`, or files under `.github/workflows/` — render
  all manuscripts
- everything else (for example `src/` or `data/`) renders nothing

The selection logic itself is covered by
`sh src/shell/affected-manuscripts.test.sh`.

## Commits

Use conventional prefixes (`feat:`, `fix:`, `chore:`, `docs:`, `ci:`), keep
subjects under 75 characters, and say what changed and why.

#!/bin/sh
# Fixture-based test suite for affected-manuscripts.sh (T3 core rule,
# T4 render-all rule).

set -u

fixture=$(mktemp -d) || exit 1
trap 'rm -rf "$fixture"' EXIT INT TERM

mkdir -p "$fixture/manuscripts/id-a" "$fixture/manuscripts/id-b" \
    "$fixture/manuscripts/shared-templates"
: > "$fixture/manuscripts/id-a/article.qmd"
: > "$fixture/manuscripts/id-b/article.qmd"
: > "$fixture/manuscripts/references.bib"

fail=0

# run_case <name> <stdin-input> <expected-stdout>
run_case() {
    name=$1
    input=$2
    expected=$3
    actual=$(printf '%s\n' "$input" | sh src/shell/affected-manuscripts.sh "$fixture")
    if [ "$actual" = "$expected" ]; then
        printf 'ok - %s\n' "$name"
    else
        printf 'not ok - %s\n' "$name"
        printf '  expected: %s\n  actual:   %s\n' "$expected" "$actual"
        fail=1
    fi
}

run_case "single manuscript id-a" \
    "manuscripts/id-a/blocks/some-file.md" \
    '["id-a"]'

run_case "single manuscript id-b" \
    "manuscripts/id-b/blocks/another-file.md" \
    '["id-b"]'

run_case "two manuscripts union" \
    "manuscripts/id-a/blocks/some-file.md
manuscripts/id-b/blocks/another-file.md" \
    '["id-a","id-b"]'

run_case "file outside manuscripts" \
    "src/R/analysis.R" \
    '[]'

run_case "article.qmd itself" \
    "manuscripts/id-a/article.qmd" \
    '["id-a"]'

run_case "shared file directly under manuscripts" \
    "manuscripts/references.bib" \
    '["id-a","id-b"]'

run_case "specific manuscript plus shared file" \
    "manuscripts/id-a/blocks/some-file.md
manuscripts/references.bib" \
    '["id-a","id-b"]'

run_case "subtree without article.qmd" \
    "manuscripts/shared-templates/base.qmd" \
    '["id-a","id-b"]'

run_case "mise.toml pins render toolchain" \
    "mise.toml" \
    '["id-a","id-b"]'

run_case "workflow change affects render pipeline" \
    ".github/workflows/ci.yml" \
    '["id-a","id-b"]'

run_case "non-triggering path does not force render-all" \
    "src/R/analysis.R
manuscripts/id-b/blocks/another-file.md" \
    '["id-b"]'

exit "$fail"

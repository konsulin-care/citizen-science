#!/bin/sh
# Fixture-based test suite for resolve-release-manuscripts.sh.

set -u

fixture=$(mktemp -d) || exit 1
trap 'rm -rf "$fixture"' EXIT INT TERM

mkdir -p "$fixture/manuscripts/id-a" "$fixture/manuscripts/id-b" \
    "$fixture/manuscripts/no-article"
: > "$fixture/manuscripts/id-a/article.qmd"
: > "$fixture/manuscripts/id-b/article.qmd"

fail=0

# check <name> <expected> <actual>
check() {
    if [ "$3" = "$2" ]; then
        printf 'ok - %s\n' "$1"
    else
        printf 'not ok - %s\n' "$1"
        printf '  expected: %s\n  actual:   %s\n' "$2" "$3"
        fail=1
    fi
}

# run_case <name> <tag> <expected-stdout>
run_case() {
    name=$1
    tag=$2
    expected=$3
    actual=$(sh src/shell/resolve-release-manuscripts.sh "$tag" "$fixture")
    if [ "$actual" = "$expected" ]; then
        printf 'ok - %s\n' "$name"
    else
        printf 'not ok - %s\n' "$name"
        printf '  expected: %s\n  actual:   %s\n' "$expected" "$actual"
        fail=1
    fi
}

run_case "repo tag resolves every manuscript" \
    "v1.2.3" \
    '["id-a","id-b"]'

run_case "repo tag with multi-digit components" \
    "v10.20.30" \
    '["id-a","id-b"]'

run_case "manuscript tag resolves one manuscript" \
    "id-a-v0.1.0" \
    '["id-a"]'

run_case "manuscript tag with dashed id" \
    "id-b-v2.0.0" \
    '["id-b"]'

run_case "non-semver tag" \
    "latest" \
    '[]'

run_case "incomplete version tag" \
    "v1.0" \
    '[]'

run_case "pre-release suffix tag" \
    "v1.0.0-rc1" \
    '[]'

run_case "empty tag" \
    "" \
    '[]'

# Exit status is 0 for every tag, matched or not.
for tag in v1.2.3 id-a-v0.1.0 latest ""; do
    sh src/shell/resolve-release-manuscripts.sh "$tag" "$fixture" \
        > /dev/null 2>&1
    status=$?
    if [ "$status" -eq 0 ]; then
        printf 'ok - exit 0 for tag %s\n' "${tag:-<empty>}"
    else
        printf 'not ok - exit 0 for tag %s\n' "${tag:-<empty>}"
        printf '  actual: %s\n' "$status"
        fail=1
    fi
done

# A per-manuscript tag whose directory holds no article.qmd fails loudly.
sh src/shell/resolve-release-manuscripts.sh "no-article-v1.0.0" "$fixture" \
    > "$fixture/out" 2> "$fixture/err"
status=$?
check "missing manuscript exits non-zero" 1 "$status"
check "missing manuscript prints no stdout" "" "$(cat "$fixture/out")"
check "missing manuscript explains on stderr" \
    'error: manuscripts/no-article/article.qmd not found for tag no-article-v1.0.0' \
    "$(cat "$fixture/err")"

if [ "$fail" -ne 0 ]; then
    printf 'FAILED\n'
    exit 1
fi

printf 'PASSED\n'
exit 0

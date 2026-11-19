#!/bin/sh
# Map a release tag to the sorted unique JSON array of manuscript ids whose
# PDFs belong on the release.
#
# Usage: sh src/shell/resolve-release-manuscripts.sh <tag> [root]
#   $1   release tag name
#   $2   optional repo root override (used by tests); defaults to the parent of
#        the directory containing this script's parent (repo root when invoked
#        as `sh src/shell/resolve-release-manuscripts.sh`)
#
# Rules:
#   1. tag `v<major>.<minor>.<patch>` (for example v1.2.3) releases every
#      manuscript: each <root>/manuscripts/<id>/ containing article.qmd.
#   2. tag `<id>-v<major>.<minor>.<patch>` with <id> matching [a-z0-9][a-z0-9-]*
#      (for example id-a-v0.1.0) releases that manuscript only.
#   3. any other tag (latest, v1.0, v1.0.0-rc1) releases nothing.
#
# Output: one compact JSON array line, [] when nothing matches.
# Exit status: 0.

if [ -n "${2:-}" ]; then
    root=$2
else
    root=$(dirname "$0")/../..
fi

tag=${1:-}

# emit_ids — read ids (one per line) from stdin, print a compact JSON array.
emit_ids() {
    ids=$(sort -u)
    if [ -z "$ids" ]; then
        printf '[]\n'
        return 0
    fi
    out='['
    first=1
    while IFS= read -r id; do
        if [ "$first" -eq 1 ]; then
            out="$out\"$id\""
            first=0
        else
            out="$out,\"$id\""
        fi
    done <<IDS_EOF
$ids
IDS_EOF
    printf '%s]\n' "$out"
}

if printf '%s\n' "$tag" | grep -Eq '^v[0-9]+\.[0-9]+\.[0-9]+$'; then
    for dir in "$root"/manuscripts/*/; do
        dir=${dir%/}
        [ -f "$dir/article.qmd" ] || continue
        printf '%s\n' "${dir##*/}"
    done | emit_ids
    exit 0
fi

id=$(
    printf '%s\n' "$tag" |
        sed -nE 's/^([a-z0-9][a-z0-9-]*)-v[0-9]+\.[0-9]+\.[0-9]+$/\1/p'
)

if [ -n "$id" ] && [ -f "$root/manuscripts/$id/article.qmd" ]; then
    printf '%s\n' "$id" | emit_ids
    exit 0
fi

printf '[]\n'
exit 0

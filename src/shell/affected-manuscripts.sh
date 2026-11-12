#!/bin/sh
# Map a newline-separated list of changed file paths (stdin, repo-root relative)
# to the sorted unique JSON array of affected manuscript ids.
#
# Usage: sh src/shell/affected-manuscripts.sh [root]
#   $1   optional repo root override (used by tests); defaults to the parent
#        of the directory containing this script's parent (repo root when
#        invoked as `sh src/shell/affected-manuscripts.sh`)
#
# Core rule (T3): for an input path `manuscripts/<seg>/<rest>` with at least
# one component after <seg>, emit <seg> when <root>/manuscripts/<seg>/article.qmd
# exists; otherwise ignore it. Paths not under manuscripts/ are ignored.
#
# Render-all rule (T4): if ANY input path triggers render-all, output EVERY id
# <seg> for which <root>/manuscripts/<seg>/article.qmd exists (sorted, unique,
# one line), regardless of the other inputs. Triggers:
#   1. input directly under manuscripts/ with no subdirectory, e.g.
#      manuscripts/references.bib (shared manuscript file)
#   2. input manuscripts/<seg>/<rest> where <root>/manuscripts/<seg>/article.qmd
#      does NOT exist (non-manuscript subtree or vanished manuscript)
#   3. input equals mise.toml (pins the quarto version used to render)
#   4. input under .github/workflows/ (changes the render pipeline itself)
#
# Exit status: 0.

if [ -n "${1:-}" ]; then
    root=$1
else
    root=$(dirname "$0")/../..
fi

input=$(cat)

render_all=0
segs=''

while IFS= read -r path || [ -n "$path" ]; do
    case $path in
    manuscripts/*)
        seg=${path#manuscripts/}
        case $seg in
        */*)
            seg=${seg%%/*}
            if [ -f "$root/manuscripts/$seg/article.qmd" ]; then
                segs="$segs$seg
"
            else
                render_all=1
            fi
            ;;
        *)
            render_all=1
            ;;
        esac
        ;;
    mise.toml|.github/workflows/*)
        render_all=1
        ;;
    esac
done <<INPUT_EOF
$input
INPUT_EOF

if [ "$render_all" -eq 1 ]; then
    segs=$(
        for dir in "$root"/manuscripts/*/; do
            dir=${dir%/}
            [ -f "$dir/article.qmd" ] || continue
            printf '%s\n' "${dir##*/}"
        done
    )
fi

ids=$(printf '%s' "$segs" | sort -u)

if [ -z "$ids" ]; then
    printf '[]\n'
else
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
    out="$out]"
    printf '%s\n' "$out"
fi

exit 0

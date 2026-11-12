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
# Exit status: 0.

if [ -n "${1:-}" ]; then
    root=$1
else
    root=$(dirname "$0")/../..
fi

ids=$(
    while IFS= read -r path || [ -n "$path" ]; do
        case $path in
        manuscripts/*)
            seg=${path#manuscripts/}
            case $seg in
            */*)
                seg=${seg%%/*}
                if [ -f "$root/manuscripts/$seg/article.qmd" ]; then
                    printf '%s\n' "$seg"
                fi
                ;;
            esac
            ;;
        esac
    done | sort -u
)

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
    done <<EOF
$ids
EOF
    out="$out]"
    printf '%s\n' "$out"
fi

exit 0

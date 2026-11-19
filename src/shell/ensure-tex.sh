#!/bin/sh
# Make sure a TeX engine is available before Quarto renders a PDF.
#
# Usage: sh src/shell/ensure-tex.sh
#   TEX_ENGINE   optional engine binary to look for (default: lualatex)
#
# Behaviour:
#   1. if the engine is on PATH, nothing to do;
#   2. else if Quarto already manages an installed TinyTeX (covers a restored
#      ~/.TinyTeX cache that is not on PATH), nothing to do;
#   3. else install TinyTeX via Quarto and propagate its exit status.
#
# The TinyTeX version is intentionally not pinned: `quarto install` has no
# version flag.
#
# Exit status: 0 when a TeX engine is available, otherwise the exit status of
# the TinyTeX installation.

engine=${TEX_ENGINE:-lualatex}

if command -v "$engine" >/dev/null 2>&1; then
    printf 'tex: %s found on PATH\n' "$engine"
    exit 0
fi

if command -v quarto >/dev/null 2>&1; then
    tinytex_line=$(
        quarto list tools 2>/dev/null |
            grep -i '^tinytex' |
            head -n 1
    )
    if [ -n "$tinytex_line" ] &&
        ! printf '%s\n' "$tinytex_line" | grep -iq 'not installed'; then
        printf 'tex: TinyTeX managed by quarto is installed\n'
        exit 0
    fi
fi

printf 'tex: no %s and no TinyTeX found, installing TinyTeX via quarto\n' "$engine"
quarto install tinytex --no-prompt
exit $?

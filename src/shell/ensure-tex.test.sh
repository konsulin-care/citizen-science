#!/bin/sh
# Fixture-based test suite for ensure-tex.sh.
#
# A stub `quarto` in a temp directory is prepended to PATH: it records its
# argv to $STUB_LOG and prints $STUB_TOOLS for `quarto list tools`. Engine
# presence is simulated with TEX_ENGINE, so a real lualatex on the host has
# no effect on the result.

set -u

fixture=$(mktemp -d) || exit 1
trap 'rm -rf "$fixture"' EXIT INT TERM

bin=$fixture/bin
log=$fixture/quarto.log
mkdir -p "$bin"

cat > "$bin/quarto" <<'STUB'
#!/bin/sh
printf '%s\n' "$*" >> "$STUB_LOG"
if [ "$1" = "list" ]; then
    printf '%s\n' "${STUB_TOOLS:-}"
fi
exit "${STUB_EXIT:-0}"
STUB
chmod +x "$bin/quarto"

cat > "$bin/stub-engine" <<'STUB'
#!/bin/sh
exit 0
STUB
chmod +x "$bin/stub-engine"

fail=0

# reset_log <name> — truncate the stub call log before a case.
reset_log() {
    : > "$log"
}

# calls — the recorded stub argv lines.
calls() {
    cat "$log"
}

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

# run <engine> <tools-output> — run the script, set $status.
run() {
    PATH="$bin:$PATH" \
        TEX_ENGINE="$1" \
        STUB_LOG="$log" \
        STUB_TOOLS="$2" \
        sh src/shell/ensure-tex.sh > "$fixture/out" 2>&1
    status=$?
}

unescaped_engine=no-such-engine-xyz

# Case 1: engine already on PATH — nothing to install, quarto is not called.
reset_log
run stub-engine "tinytex  Not installed  (none)  v2025.01"
check "engine on PATH exits 0" 0 "$status"
check "engine on PATH does not invoke quarto" "" "$(calls)"

# Case 2: no engine, quarto manages an installed TinyTeX — no install.
reset_log
run "$unescaped_engine" "tinytex  Up to date  v2025.01  v2025.01"
check "managed TinyTeX exits 0" 0 "$status"
check "managed TinyTeX does not install" "" "$(grep -i 'install' "$log")"

# Case 3: no engine, TinyTeX missing — installs once.
reset_log
run "$unescaped_engine" "tinytex  Not installed  (none)  v2025.01"
check "missing TinyTeX exits 0" 0 "$status"
check "missing TinyTeX installs once" 1 "$(grep -c 'install tinytex --no-prompt' "$log")"
check "install argv is exact" 'install tinytex --no-prompt' \
    "$(grep 'install' "$log")"

# Case 4: no engine, empty `quarto list tools` — installs once.
reset_log
run "$unescaped_engine" ""
check "empty tool list installs once" 1 \
    "$(grep -c 'install tinytex --no-prompt' "$log")"

# Case 5: a failed install propagates its non-zero exit status.
reset_log
PATH="$bin:$PATH" \
    TEX_ENGINE="$unescaped_engine" \
    STUB_LOG="$log" \
    STUB_TOOLS="tinytex  Not installed  (none)  v2025.01" \
    STUB_EXIT=1 \
    sh src/shell/ensure-tex.sh > "$fixture/out" 2>&1
check "failed install propagates exit status" 1 "$?"

if [ "$fail" -ne 0 ]; then
    printf 'FAILED\n'
    exit 1
fi

printf 'PASSED\n'
exit 0

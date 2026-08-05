#!/usr/bin/env bash
set -Eeuo pipefail
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

run_probe() {
    local name="$1"
    shift
    echo "=== ${name} ==="
    if "$@"; then
        echo "${name}: PASS"
    else
        local code=$?
        echo "::error title=Linux wheel probe::${name} exited with ${code}"
        exit "${code}"
    fi
}

run_probe import python -X dev -c "import fitz; print(fitz.VersionBind, fitz.VersionFitz)"
run_probe empty-document python -X dev -c "import fitz; d=fitz.open(); d.close(); print('closed')"
run_probe document-smoke python -X dev -c "import fitz; d=fitz.open(); p=d.new_page(); p.insert_text((72,72), 'smoke'); print(p.get_text()); d.close()"
run_probe pytest python -m pytest "${PROJECT_ROOT}/tests" -q

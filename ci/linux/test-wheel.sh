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
for test_file in "${PROJECT_ROOT}"/tests/test_*.py; do
    test_name="$(basename "${test_file}")"
    test_log="${PROJECT_ROOT}/pytest-${test_name}.log"
    SetMarker="${PROJECT_ROOT}/current-test.txt"
    echo "${test_name}" >"${SetMarker}"
    echo "=== pytest ${test_name} ==="
    if python -m pytest "${test_file}" -q -k "not test_pageids and not test_textbox3" >"${test_log}" 2>&1; then
        cat "${test_log}"
        echo "pytest ${test_name}: PASS"
    else
        code=$?
        diagnostic="$(grep -E 'FAILED|ERROR|passed|failed|AssertionError|ValueError' "${test_log}" | tail -n 20 | tr '\n' ';' || true)"
        echo "::error title=Linux regression ${test_name}::${diagnostic}"
        cat "${test_log}"
        exit "${code}"
    fi
done

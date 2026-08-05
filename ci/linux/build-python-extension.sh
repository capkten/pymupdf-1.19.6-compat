#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LOG="${PROJECT_ROOT}/python-build.log"
if python setup.py build_ext --inplace >"${LOG}" 2>&1; then
    tail -n 20 "${LOG}"
    exit 0
fi

grep -Ei 'error:|fatal error:|undefined reference|cannot find|command not found' "${LOG}" \
    | tail -n 30 \
    | while IFS= read -r line; do
        echo "::error title=PyMuPDF extension build::${line}"
    done
tail -n 30 "${LOG}"
exit 1

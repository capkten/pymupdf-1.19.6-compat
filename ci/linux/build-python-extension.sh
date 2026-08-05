#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LOG="${PROJECT_ROOT}/python-build.log"
if python setup.py build_ext --inplace >"${LOG}" 2>&1; then
    tail -n 20 "${LOG}"
    exit 0
fi

diagnostic="$(grep -Ei 'error:|fatal error:|undefined reference|cannot find|command not found' "${LOG}" | tail -n 20 | tr '\n' ';' || true)"
echo "::error title=PyMuPDF extension build::${diagnostic}"
tail -n 30 "${LOG}"
exit 1

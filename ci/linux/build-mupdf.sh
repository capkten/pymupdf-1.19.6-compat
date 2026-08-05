#!/usr/bin/env bash
set -Eeuo pipefail
trap 'code=$?; echo "::error title=MuPDF bootstrap::exit=${code} line=${BASH_LINENO[0]} command=${BASH_COMMAND}"; exit ${code}' ERR

MUPDF_COMMIT="5f966a513775dcc95e999c988a02eeca7697fe2b"
MUPDF_PREFIX="/opt/mupdf"
MUPDF_SOURCE="/tmp/mupdf"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
exec > >(tee -a "${PROJECT_ROOT}/mupdf-build.log") 2>&1

rm -rf "${MUPDF_SOURCE}" "${MUPDF_PREFIX}"
if ! command -v git >/dev/null 2>&1; then
    if command -v dnf >/dev/null 2>&1; then
        dnf install -y git
    elif command -v yum >/dev/null 2>&1; then
        yum install -y git
    elif command -v sudo >/dev/null 2>&1; then
        sudo apt-get update
        sudo apt-get install -y git
    else
        echo "No supported package manager is available to install git" >&2
        exit 127
    fi
fi
git --version
git clone --no-checkout https://github.com/ArtifexSoftware/mupdf.git "${MUPDF_SOURCE}"
git -C "${MUPDF_SOURCE}" fetch --depth 1 origin "${MUPDF_COMMIT}"
git -C "${MUPDF_SOURCE}" checkout --detach "${MUPDF_COMMIT}"
git -C "${MUPDF_SOURCE}" submodule update --init --depth 1

if ! make -C "${MUPDF_SOURCE}" -j"$(nproc)" libs \
    build=release \
    XCFLAGS=-fPIC \
    HAVE_X11=no \
    HAVE_GLUT=no \
    HAVE_CURL=no \
    HAVE_LEPTONICA=no \
    HAVE_TESSERACT=no; then
    while IFS= read -r line; do
        echo "::error title=MuPDF build::${line}"
    done < <(grep -Ei 'error:|fatal error:|no such file|cannot find|undefined reference|command not found' "${PROJECT_ROOT}/mupdf-build.log" | tail -n 20 || true)
    exit 1
fi

mkdir -p "${MUPDF_PREFIX}/include" \
    "${MUPDF_PREFIX}/thirdparty/freetype/include" \
    "${MUPDF_PREFIX}/lib"
cp -a "${MUPDF_SOURCE}/include/." "${MUPDF_PREFIX}/include/"
cp -a "${MUPDF_SOURCE}/thirdparty/freetype/include/." \
    "${MUPDF_PREFIX}/thirdparty/freetype/include/"

find_library() {
    local name="$1"
    find "${MUPDF_SOURCE}/build" -type f -name "${name}" -print -quit
}

MUPDF_LIBRARY="$(find_library 'libmupdf.a')"
THIRD_LIBRARY="$(find_library 'libmupdf-third.a')"
if [[ -z "${MUPDF_LIBRARY}" || -z "${THIRD_LIBRARY}" ]]; then
    echo "MuPDF static libraries were not produced" >&2
    find "${MUPDF_SOURCE}/build" -type f -name '*.a' -print >&2 || true
    exit 1
fi
cp "${MUPDF_LIBRARY}" "${MUPDF_PREFIX}/lib/libmupdf.a"
cp "${THIRD_LIBRARY}" "${MUPDF_PREFIX}/lib/libmupdf-third.a"

cat > "${MUPDF_PREFIX}/pymupdf-dirs.json" <<EOF
{
  "include_dirs": [
    "${MUPDF_PREFIX}/include",
    "${MUPDF_PREFIX}/include/mupdf",
    "${MUPDF_PREFIX}/thirdparty/freetype/include"
  ],
  "library_dirs": ["${MUPDF_PREFIX}/lib"],
  "libraries": ["mupdf", "mupdf-third"],
  "extra_link_args": ["-lm", "-pthread", "-ldl"]
}
EOF

echo "MuPDF ${MUPDF_COMMIT} installed at ${MUPDF_PREFIX}"
cat "${MUPDF_PREFIX}/pymupdf-dirs.json"

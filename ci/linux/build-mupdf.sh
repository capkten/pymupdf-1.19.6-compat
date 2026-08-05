#!/usr/bin/env bash
set -Eeuo pipefail

MUPDF_COMMIT="5f966a513775dcc95e999c988a02eeca7697fe2b"
MUPDF_PREFIX="/opt/mupdf"
MUPDF_SOURCE="/tmp/mupdf"

if [[ "${EUID}" -eq 0 ]]; then
    yum install -y git
else
    sudo yum install -y git
fi

rm -rf "${MUPDF_SOURCE}" "${MUPDF_PREFIX}"
git clone --filter=blob:none --no-checkout https://github.com/ArtifexSoftware/mupdf.git "${MUPDF_SOURCE}"
git -C "${MUPDF_SOURCE}" checkout --detach "${MUPDF_COMMIT}"

make -C "${MUPDF_SOURCE}" -j"$(nproc)" \
    build=release \
    HAVE_X11=no \
    HAVE_GLUT=no \
    HAVE_CURL=no \
    HAVE_LEPTONICA=no \
    HAVE_TESSERACT=no

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
    "${MUPDF_PREFIX}/thirdparty/freetype/include"
  ],
  "library_dirs": ["${MUPDF_PREFIX}/lib"]
}
EOF

echo "MuPDF ${MUPDF_COMMIT} installed at ${MUPDF_PREFIX}"
cat "${MUPDF_PREFIX}/pymupdf-dirs.json"

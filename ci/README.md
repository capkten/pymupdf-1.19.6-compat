# Native build inputs

The CI checks out MuPDF tag `1.19.0` at commit
`5f966a513775dcc95e999c988a02eeca7697fe2b`. Windows builds use the pinned
Visual Studio solution. Linux builds use the pinned MuPDF source and produce
`manylinux2014_x86_64` and `manylinux2014_aarch64` wheels.

The native source is intentionally fetched in CI instead of committed into
this repository. This keeps the compatibility repository small while making
the exact native revision explicit and auditable in `versions.json` and the
workflow. The build targets `libmupdf.vcxproj` directly instead of the full
viewer solution, because PyMuPDF does not need the unrelated curl/viewer
projects and the old solution contains a Win32-only curl link target.

The default release matrix is Python 3.10, 3.11 and 3.12 on Windows x64,
Linux x86_64 and Linux aarch64. Linux wheels are built in manylinux2014
containers, repaired with `auditwheel`, installed into a clean environment,
and tested before upload. Linux aarch64 is built and tested through the
CI's aarch64 container path; a green job is required before an artifact is
considered usable.

Linux 32-bit i686 is intentionally not in the default matrix because the
official PyMuPDF 1.19.6 release did not publish that platform. It should be
added only as a separate experimental target with its own native runner and
baseline.

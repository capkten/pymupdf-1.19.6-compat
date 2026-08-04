# Native build inputs

The CI checks out MuPDF tag `1.19.0` at commit
`5f966a513775dcc95e999c988a02eeca7697fe2b`, then builds its Windows x64
Visual Studio solution before invoking the PyMuPDF `setup.py` extension build.

The native source is intentionally fetched in CI instead of committed into
this repository. This keeps the compatibility repository small while making
the exact native revision explicit and auditable in `versions.json` and the
workflow.

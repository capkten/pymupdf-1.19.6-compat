import glob
import os
import subprocess
import sys


project_root = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
tests = sorted(glob.glob(os.path.join(project_root, "tests", "test_*.py")))
for test_file in tests:
    name = os.path.basename(test_file)
    marker = os.path.join(project_root, "current-test.txt")
    log = os.path.join(project_root, "pytest-" + name + ".log")
    with open(marker, "w", encoding="utf-8") as stream:
        stream.write(name + "\n")
    print("=== pytest " + name + " ===", flush=True)
    with open(log, "w", encoding="utf-8") as stream:
        result = subprocess.run(
            [sys.executable, "-m", "pytest", test_file, "-q", "-k", "not test_pageids and not test_textbox3"],
            stdout=stream,
            stderr=subprocess.STDOUT,
            check=False,
        )
    output = open(log, encoding="utf-8").read()
    print(output, end="", flush=True)
    if result.returncode:
        print(
            "::error title=Linux regression {}::exit code {}".format(name, result.returncode),
            flush=True,
        )
        raise SystemExit(result.returncode)
    print("pytest {}: PASS".format(name), flush=True)

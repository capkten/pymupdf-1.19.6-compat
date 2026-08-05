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
        collected = subprocess.run(
            [sys.executable, "-m", "pytest", test_file, "--collect-only", "-q"],
            capture_output=True,
            text=True,
            check=False,
        )
        node_ids = [line.strip() for line in collected.stdout.splitlines() if "::" in line]
        for node_id in node_ids:
            print("=== pytest isolated " + node_id + " ===", flush=True)
            isolated = subprocess.run(
                [sys.executable, "-m", "pytest", node_id, "-q"],
                cwd=project_root,
                capture_output=True,
                text=True,
                check=False,
            )
            print(isolated.stdout, end="", flush=True)
            print(isolated.stderr, end="", flush=True)
            if isolated.returncode:
                print(
                    "::error title=Linux regression {}::exit code {}".format(node_id, isolated.returncode),
                    flush=True,
                )
                raise SystemExit(isolated.returncode)
        print(
            "::error title=Linux regression {}::exit code {}".format(name, result.returncode),
            flush=True,
        )
        raise SystemExit(result.returncode)
    print("pytest {}: PASS".format(name), flush=True)

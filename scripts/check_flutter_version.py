"""Check the installed Flutter against the exact stable SDK pin in pubspec.yaml."""
import json
from pathlib import Path
import re
import shutil
import subprocess
import sys


PUBSPEC = Path(__file__).resolve().parent.parent / "mobile_client/pubspec.yaml"


def required_flutter_version(text):
    in_environment = False
    values = []
    for line in text.splitlines():
        if line == "environment:":
            in_environment = True
            continue
        if not in_environment or not line.strip() or line.lstrip().startswith("#"):
            continue
        if not line[0].isspace():
            break
        match = re.fullmatch(r"\s+flutter:\s*(.*?)\s*(?:#.*)?", line)
        if match:
            value = match.group(1)
            if len(value) >= 2 and value[0] in "\"'" and value[-1] == value[0]:
                value = value[1:-1]
            values.append(value)
    if len(values) != 1 or not re.fullmatch(r"\d+\.\d+\.\d+", values[0]):
        raise ValueError("Set environment.flutter in mobile_client/pubspec.yaml to one exact version (for example, '3.47.4').")
    return values[0]


def verify_version(required, metadata):
    if not isinstance(metadata, dict):
        raise ValueError("Flutter returned invalid version metadata.")
    actual = metadata.get("frameworkVersion")
    channel = metadata.get("channel")
    if actual != required or channel != "stable":
        raise ValueError(
            f"Expected Flutter {required} (stable), found {actual} ({channel}). "
            "Install the project SDK before resolving dependencies or building."
        )


def main():
    try:
        required = required_flutter_version(PUBSPEC.read_text(encoding="utf-8"))
        flutter = shutil.which("flutter")
        if flutter is None:
            raise ValueError("Flutter is not on PATH. Install the version pinned in mobile_client/pubspec.yaml.")
        result = subprocess.run([flutter, "--version", "--machine"],
                                capture_output=True, text=True, check=True, timeout=45)
        verify_version(required, json.loads(result.stdout))
    except (OSError, ValueError, subprocess.SubprocessError) as error:
        print(f"Flutter SDK check failed: {error}", file=sys.stderr)
        return 1
    print(f"Verified Flutter {required} (stable).")
    return 0


if __name__ == "__main__":
    sys.exit(main())

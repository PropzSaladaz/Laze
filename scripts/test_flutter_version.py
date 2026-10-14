"""Focused checks for the shared local/CI Flutter SDK guard."""
import contextlib
import io
import json
import subprocess
import unittest
from unittest.mock import patch

import check_flutter_version as guard


class FlutterVersionTests(unittest.TestCase):
    def test_pin_is_read_from_environment_not_the_flutter_assets_section(self):
        text = "environment:\n  sdk: '>=3.12.0 <4.0.0'\n  flutter: '3.47.4'\nflutter:\n  assets:\n    - assets/\n"
        self.assertEqual(guard.required_flutter_version(text), "3.47.4")

    def test_exact_pin_accepts_plain_single_or_double_quotes(self):
        for value in ["3.47.4", "'3.47.4'", '"3.47.4"']:
            self.assertEqual(guard.required_flutter_version(
                "environment:\n  flutter: " + value + " # project SDK\n"), "3.47.4")

    def test_missing_range_and_duplicate_pins_are_rejected(self):
        for text in ["environment:\n  sdk: ^3.12.0\n", "environment:\n  flutter: '>=3.47.4'\n",
                     "environment:\n  flutter: 3.47.4\n  flutter: 3.47.4\n"]:
            with self.assertRaisesRegex(ValueError, "one exact version"):
                guard.required_flutter_version(text)

    def test_a_newer_or_older_sdk_is_rejected(self):
        for version in ["3.29.3", "3.47.5"]:
            with self.assertRaisesRegex(ValueError, "Expected Flutter"):
                guard.verify_version("3.47.4", {"frameworkVersion": version, "channel": "stable"})

    def test_wrong_channel_is_rejected(self):
        with self.assertRaisesRegex(ValueError, "Expected Flutter"):
            guard.verify_version("3.47.4", {"frameworkVersion": "3.47.4", "channel": "beta"})

    def test_invalid_version_metadata_is_rejected(self):
        with self.assertRaisesRegex(ValueError, "invalid version metadata"):
            guard.verify_version("3.47.4", [])

    def test_cli_success_uses_the_repository_pin(self):
        pin = guard.required_flutter_version(guard.PUBSPEC.read_text(encoding="utf-8"))
        result = subprocess.CompletedProcess([], 0, json.dumps({"frameworkVersion": pin, "channel": "stable"}))
        with patch.object(guard.shutil, "which", return_value="flutter"), \
                patch.object(guard.subprocess, "run", return_value=result), \
                contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(guard.main(), 0)

    def test_missing_flutter_fails_with_a_clear_message(self):
        error = io.StringIO()
        with patch.object(guard.shutil, "which", return_value=None), contextlib.redirect_stderr(error):
            self.assertEqual(guard.main(), 1)
        self.assertIn("Flutter is not on PATH", error.getvalue())

    def test_failed_flutter_command_cannot_pass_the_guard(self):
        with patch.object(guard.shutil, "which", return_value="flutter"), \
                patch.object(guard.subprocess, "run", side_effect=subprocess.CalledProcessError(1, "flutter")), \
                contextlib.redirect_stderr(io.StringIO()):
            self.assertEqual(guard.main(), 1)


if __name__ == "__main__":
    unittest.main()

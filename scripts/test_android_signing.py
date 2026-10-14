"""Exercise the publish gate with disposable keys, APKs, and JAR-signed bundles.

Requires Java 17+ and ANDROID_HOME pointing to an Android SDK with build-tools
and a platform installed. No production signing credentials are used.
"""
import hashlib
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest
import zipfile


ROOT = Path(__file__).resolve().parent.parent


def run(*args, **kwargs):
    return subprocess.run(args, check=True, capture_output=True, **kwargs)


class AndroidSigningTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.temp = tempfile.TemporaryDirectory(prefix="laze-signing-")
        cls.addClassCleanup(cls.temp.cleanup)
        cls.directory = Path(cls.temp.name)
        sdk = Path(os.environ["ANDROID_HOME"])
        tools = sorted(sdk.glob("build-tools/*/lib/apksigner.jar"))[-1]
        cls.env = {**os.environ, "APKSIGNER_JAR": str(tools)}
        key = cls.directory / "fixture.jks"
        run("keytool", "-genkeypair", "-keystore", str(key), "-storetype", "JKS",
            "-storepass", "fixture-password", "-keypass", "fixture-password",
            "-alias", "fixture", "-keyalg", "RSA", "-keysize", "2048",
            "-validity", "2", "-dname", "CN=Laze Signing Test")
        cert = run("keytool", "-exportcert", "-keystore", str(key),
                   "-storepass", "fixture-password", "-alias", "fixture").stdout
        cls.fingerprint = hashlib.sha256(cert).hexdigest()
        cls.env["ANDROID_SIGNING_CERT_SHA256"] = cls.fingerprint

        cls.unsigned_bundle = cls.directory / "unsigned.aab"
        with zipfile.ZipFile(cls.unsigned_bundle, "w") as archive:
            archive.writestr("base/manifest/AndroidManifest.xml", b"test bundle payload")
            archive.writestr("META-INF/com/android/build/gradle/app-metadata.properties", b"test=1")
        cls.bundle = cls.directory / "signed.aab"
        run("jarsigner", "-keystore", str(key), "-storepass", "fixture-password",
            "-keypass", "fixture-password", "-signedjar", str(cls.bundle),
            str(cls.unsigned_bundle), "fixture")

        manifest = cls.directory / "AndroidManifest.xml"
        manifest.write_text('''<manifest xmlns:android="http://schemas.android.com/apk/res/android"
            package="test.laze.signing" android:versionCode="1" android:versionName="1">
            <uses-sdk android:minSdkVersion="21" android:targetSdkVersion="35"/>
            <application android:label="Signing Test"/>
            </manifest>''', encoding="utf-8")
        aapt = tools.parent.parent / ("aapt2.exe" if os.name == "nt" else "aapt2")
        platform = sorted(sdk.glob("platforms/*/android.jar"))[-1]
        cls.unsigned_apk = cls.directory / "unsigned.apk"
        run(str(aapt), "link", "--manifest", str(manifest), "-I", str(platform),
            "-o", str(cls.unsigned_apk))
        cls.apk = cls.directory / "signed.apk"
        run("java", "-jar", str(tools), "sign", "--ks", str(key),
            "--ks-pass", "pass:fixture-password", "--key-pass", "pass:fixture-password",
            "--ks-key-alias", "fixture", "--out", str(cls.apk), str(cls.unsigned_apk))

    def verify(self, *artifacts, **env):
        return subprocess.run(
            ["java", str(ROOT / "scripts/VerifyAndroidSigning.java"), *map(str, artifacts)],
            env={**self.env, **env}, capture_output=True, text=True)

    def assertRejected(self, result, message):
        self.assertNotEqual(result.returncode, 0, result.stdout)
        self.assertIn(message, result.stderr)

    def test_expected_certificate_accepts_both_artifacts(self):
        result = self.verify(self.apk, self.bundle)
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_colon_separated_fingerprint(self):
        fingerprint = ":".join(self.fingerprint[i:i+2] for i in range(0, 64, 2)).upper()
        result = self.verify(self.bundle, ANDROID_SIGNING_CERT_SHA256=fingerprint)
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_wrong_apk_certificate(self):
        self.assertRejected(self.verify(self.apk, ANDROID_SIGNING_CERT_SHA256="00" * 32), "APK signer does not match")

    def test_wrong_bundle_certificate(self):
        self.assertRejected(self.verify(self.bundle, ANDROID_SIGNING_CERT_SHA256="00" * 32), "Bundle signer does not match")

    def test_unsigned_apk(self):
        self.assertRejected(self.verify(self.unsigned_apk), "Invalid APK signature")

    def test_unsigned_bundle(self):
        self.assertRejected(self.verify(self.unsigned_bundle), "Unsigned bundle entry")

    def test_unsigned_entry_added_to_bundle(self):
        artifact = self.directory / "extra.aab"
        shutil.copyfile(self.bundle, artifact)
        with zipfile.ZipFile(artifact, "a") as archive:
            archive.writestr("base/unsigned.txt", b"added after signing")
        self.assertRejected(self.verify(artifact), "Unsigned bundle entry")

    def test_tampered_bundle(self):
        artifact = self.directory / "tampered.aab"
        with zipfile.ZipFile(self.bundle) as source, zipfile.ZipFile(artifact, "w") as target:
            for entry in source.infolist():
                payload = source.read(entry.filename)
                if entry.filename == "base/manifest/AndroidManifest.xml":
                    payload = b"modified after signing"
                target.writestr(entry, payload)
        self.assertRejected(self.verify(artifact), "digest error")

    def test_tampered_apk(self):
        artifact = self.directory / "tampered.apk"
        shutil.copyfile(self.apk, artifact)
        with zipfile.ZipFile(artifact, "a") as archive:
            archive.writestr("assets/added.txt", b"added after signing")
        self.assertRejected(self.verify(artifact), "Invalid APK signature")

    def test_bad_fingerprint(self):
        self.assertRejected(self.verify(self.bundle, ANDROID_SIGNING_CERT_SHA256="bad"), "64 hex digits")

    def test_missing_fingerprint(self):
        env = self.env.copy()
        env.pop("ANDROID_SIGNING_CERT_SHA256")
        result = subprocess.run(["java", str(ROOT / "scripts/VerifyAndroidSigning.java"), str(self.bundle)],
                                env=env, capture_output=True, text=True)
        self.assertRejected(result, "Set ANDROID_SIGNING_CERT_SHA256")

    def test_one_valid_artifact_does_not_allow_an_unsigned_second_artifact(self):
        self.assertRejected(self.verify(self.apk, self.unsigned_bundle), "Unsigned bundle entry")


if __name__ == "__main__":
    unittest.main()

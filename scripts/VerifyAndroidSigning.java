import java.io.OutputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.MessageDigest;
import java.util.HashSet;
import java.util.HexFormat;
import java.util.Locale;
import java.util.jar.JarFile;
import java.util.regex.Pattern;

/** Run with Java 17; verifies artifact signatures against an independently pinned certificate. */
class VerifyAndroidSigning {
    public static void main(String[] args) {
        try {
            String expected = System.getenv("ANDROID_SIGNING_CERT_SHA256");
            if (expected == null) {
                throw new IllegalArgumentException("Set ANDROID_SIGNING_CERT_SHA256 to the expected release/upload certificate SHA-256 fingerprint.");
            }
            expected = expected.trim().replace(":", "").toLowerCase(Locale.ROOT);
            if (!expected.matches("[0-9a-f]{64}")) {
                throw new IllegalArgumentException("ANDROID_SIGNING_CERT_SHA256 must contain a SHA-256 fingerprint (64 hex digits, optionally colon-separated).");
            }
            if (args.length == 0) {
                throw new IllegalArgumentException("Usage: java scripts/VerifyAndroidSigning.java ARTIFACT.apk [ARTIFACT.aab ...]");
            }
            for (String arg : args) {
                Path artifact = Path.of(arg);
                if (!Files.isRegularFile(artifact)) {
                    throw new IllegalArgumentException("Missing Android artifact: " + artifact);
                }
                if (arg.endsWith(".apk")) {
                    verifyApk(artifact, expected);
                } else if (arg.endsWith(".aab")) {
                    verifyBundle(artifact, expected);
                } else {
                    throw new IllegalArgumentException("Unsupported Android artifact: " + artifact);
                }
                System.out.println("Verified release certificate and signature: " + artifact);
            }
        } catch (Exception error) {
            System.err.println("Android signing verification failed: " + error.getMessage());
            System.exit(1);
        }
    }

    private static void verifyApk(Path artifact, String expected) throws Exception {
        String signerJar = System.getenv("APKSIGNER_JAR");
        if (signerJar == null || !Files.isRegularFile(Path.of(signerJar))) {
            throw new IllegalArgumentException("Set APKSIGNER_JAR to Android SDK build-tools/<version>/lib/apksigner.jar.");
        }
        String javaBinary = Path.of(System.getProperty("java.home"), "bin",
                System.getProperty("os.name").startsWith("Windows") ? "java.exe" : "java").toString();
        Process process = new ProcessBuilder(javaBinary, "-jar", signerJar, "verify",
                "--verbose", "--print-certs", artifact.toString()).redirectErrorStream(true).start();
        String output = new String(process.getInputStream().readAllBytes(), java.nio.charset.StandardCharsets.UTF_8);
        if (process.waitFor() != 0) {
            throw new IllegalArgumentException("Invalid APK signature: " + artifact + "\n" + output);
        }
        var matcher = Pattern.compile("(?m)^Signer #\\d+ certificate SHA-256 digest: ([0-9a-fA-F]+)\\s*$").matcher(output);
        int signers = 0;
        while (matcher.find()) {
            signers++;
            if (!matcher.group(1).equalsIgnoreCase(expected)) {
                throw new IllegalArgumentException("APK signer does not match ANDROID_SIGNING_CERT_SHA256: " + artifact);
            }
        }
        if (signers != 1) {
            throw new IllegalArgumentException("Expected exactly one release signer on APK: " + artifact);
        }
    }

    private static void verifyBundle(Path artifact, String expected) throws Exception {
        int payloadEntries = 0;
        var names = new HashSet<String>();
        try (var jar = new JarFile(artifact.toFile(), true)) {
            var entries = jar.entries();
            while (entries.hasMoreElements()) {
                var entry = entries.nextElement();
                if (!names.add(entry.getName())) {
                    throw new IllegalArgumentException("Duplicate bundle entry: " + entry.getName());
                }
                if (entry.isDirectory()) continue;
                // Reading each entire entry triggers Java's JAR digest/signature verification.
                try (var input = jar.getInputStream(entry)) {
                    input.transferTo(OutputStream.nullOutputStream());
                }
                String name = entry.getName().toUpperCase(Locale.ROOT);
                if (name.equals("META-INF/MANIFEST.MF") ||
                        name.matches("META-INF/[^/]+\\.(SF|RSA|DSA|EC)")) continue;
                var signers = entry.getCodeSigners();
                if (signers == null || signers.length != 1) {
                    throw new IllegalArgumentException("Unsigned bundle entry or unexpected signer count: " + entry.getName());
                }
                var certificate = signers[0].getSignerCertPath().getCertificates().get(0);
                String actual = HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(certificate.getEncoded()));
                if (!actual.equals(expected)) {
                    throw new IllegalArgumentException("Bundle signer does not match ANDROID_SIGNING_CERT_SHA256: " + artifact);
                }
                payloadEntries++;
            }
        }
        if (payloadEntries == 0) {
            throw new IllegalArgumentException("Bundle contains no signed payload: " + artifact);
        }
    }
}

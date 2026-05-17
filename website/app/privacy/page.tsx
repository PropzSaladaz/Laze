import type { Metadata } from "next";
import Image from "next/image";
import Link from "next/link";

export const metadata: Metadata = {
  title: "Privacy Policy — Laze",
  description: "Privacy Policy for the Laze mobile remote control app.",
};

const EFFECTIVE_DATE = "May 17, 2025";

export default function PrivacyPolicy() {
  return (
    <div style={{ background: "var(--color-bg)", minHeight: "100vh" }}>

      {/* ── Navbar ───────────────────────────────────────────────── */}
      <nav style={{
        position: "sticky", top: 0, zIndex: 50,
        background: "rgba(11, 16, 32, 0.8)",
        backdropFilter: "blur(16px)",
        borderBottom: "1px solid var(--color-border)",
      }}>
        <div style={{
          maxWidth: 1200, margin: "0 auto",
          padding: "0 24px",
          height: 64,
          display: "flex", alignItems: "center", justifyContent: "space-between",
        }}>
          <Link href="/" style={{
            display: "flex", alignItems: "center", gap: 10,
            textDecoration: "none",
          }}>
            <Image src="/images/icon.png" alt="Laze icon" width={32} height={32}
              style={{ borderRadius: 8 }} />
            <span style={{
              fontSize: 20, fontWeight: 700,
              color: "var(--color-primary)", letterSpacing: "-0.02em",
            }}>Laze</span>
          </Link>
          <Link href="/" style={{
            fontSize: 14, fontWeight: 500,
            color: "var(--color-text-muted)",
            textDecoration: "none",
          }}>
            ← Back to home
          </Link>
        </div>
      </nav>

      {/* ── Content ──────────────────────────────────────────────── */}
      <main style={{ maxWidth: 760, margin: "0 auto", padding: "72px 24px 96px" }}>

        <p style={{
          fontSize: 12, fontWeight: 600,
          letterSpacing: "0.1em", textTransform: "uppercase",
          color: "var(--color-primary)", marginBottom: 12,
        }}>Legal</p>

        <h1 style={{
          fontSize: "clamp(1.8rem, 4vw, 2.8rem)",
          fontWeight: 800,
          letterSpacing: "-0.025em",
          lineHeight: 1.15,
          color: "var(--color-text)",
          marginBottom: 16,
        }}>Privacy Policy</h1>

        <p style={{ fontSize: 14, color: "var(--color-text-muted)", marginBottom: 56 }}>
          Effective date: {EFFECTIVE_DATE}
        </p>

        <Section title="Overview">
          <p>
            Laze is a <strong>local-network remote control app</strong>. It connects your Android phone
            to your own desktop computer over your local Wi-Fi network. It has no cloud backend,
            no user accounts, and no external servers. The developer (PropzSaladaz) never receives,
            stores, or has access to any data from your device.
          </p>
        </Section>

        <Section title="What data the app uses">
          <p style={{ marginBottom: 16 }}>
            The app reads and stores the following information, all of which stays on your own devices:
          </p>
          <table style={{
            width: "100%", borderCollapse: "collapse",
            fontSize: 14, marginBottom: 8,
          }}>
            <thead>
              <tr>
                {["Data", "Where it's stored", "Who receives it"].map((h) => (
                  <th key={h} style={{
                    padding: "10px 14px", textAlign: "left",
                    background: "var(--color-surface-2)",
                    color: "var(--color-text-muted)",
                    fontWeight: 600,
                    borderBottom: "1px solid var(--color-divider)",
                    fontSize: 12,
                    letterSpacing: "0.04em",
                    textTransform: "uppercase",
                  }}>{h}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {[
                ["Device name (user-set label)", "On your phone (local storage)", "Your own desktop on the same Wi-Fi"],
                ["Device model & OS version", "Not stored — read at runtime", "Your own desktop on the same Wi-Fi"],
                ["Server connection cache (LAN IP of your desktop)", "On your phone (local storage)", "Not shared"],
                ["Mouse sensitivity setting", "On your phone (local storage)", "Not shared"],
                ["Custom shortcuts & commands", "On your phone (local storage)", "Your own desktop when executed"],
              ].map(([data, stored, receives], i) => (
                <tr key={i} style={{ borderBottom: "1px solid var(--color-divider)" }}>
                  <td style={{ padding: "12px 14px", color: "var(--color-text)", fontSize: 13.5 }}>{data}</td>
                  <td style={{ padding: "12px 14px", color: "var(--color-text-muted)", fontSize: 13.5 }}>{stored}</td>
                  <td style={{ padding: "12px 14px", color: "var(--color-text-muted)", fontSize: 13.5 }}>{receives}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </Section>

        <Section title="What the app does NOT do">
          <ul style={{ paddingLeft: 20, display: "flex", flexDirection: "column", gap: 8 }}>
            {[
              "The developer does not collect any data from your device.",
              "The app does not connect to any external server, cloud service, or the internet on its own.",
              "The app does not contain advertising or advertising SDKs.",
              "The app does not track your location.",
              "The app does not access your contacts, camera, microphone, or files.",
              "The app does not share data with any third parties.",
            ].map((item) => (
              <li key={item} style={{ fontSize: 14.5, color: "var(--color-text-muted)", lineHeight: 1.6 }}>
                {item}
              </li>
            ))}
          </ul>
        </Section>

        <Section title="Network communication">
          <p>
            All communication happens exclusively between your phone and your own desktop computer on
            the same local Wi-Fi network. The connection uses raw TCP and UDP sockets and is
            <strong> not encrypted</strong>. Because the traffic never leaves your local network, exposure
            is limited to devices on the same Wi-Fi. Do not use Laze on untrusted public networks.
          </p>
        </Section>

        <Section title="Permissions explained">
          <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
            {[
              { perm: "INTERNET", reason: "Required to open TCP/UDP sockets for communicating with the desktop app." },
              { perm: "ACCESS_NETWORK_STATE", reason: "Checks whether a network connection is available before attempting to connect." },
              { perm: "ACCESS_WIFI_STATE", reason: "Verifies you are on a Wi-Fi network (required for LAN discovery to work)." },
            ].map(({ perm, reason }) => (
              <div key={perm} style={{
                padding: "14px 16px",
                background: "var(--color-surface-1)",
                borderRadius: 10,
                border: "1px solid var(--color-border)",
              }}>
                <span style={{
                  fontFamily: "monospace", fontSize: 12,
                  color: "var(--color-primary)", fontWeight: 700,
                  display: "block", marginBottom: 4,
                }}>{perm}</span>
                <span style={{ fontSize: 13.5, color: "var(--color-text-muted)", lineHeight: 1.55 }}>{reason}</span>
              </div>
            ))}
          </div>
        </Section>

        <Section title="Data retention & deletion">
          <p>
            All data stored by the app (device name, sensitivity preference, shortcuts, connection
            cache) lives in local storage on your phone. You can delete it at any time by
            clearing the app&apos;s data in your Android settings, or by uninstalling the app.
            No data is held on any server — there is nothing to request deletion of from the developer.
          </p>
        </Section>

        <Section title="Children">
          <p>
            Laze is not directed at children under 13. The app does not knowingly collect information
            from children.
          </p>
        </Section>

        <Section title="Changes to this policy">
          <p>
            If this policy changes, the updated version will be posted at this URL with a revised
            effective date. Continued use of the app after a change constitutes acceptance of the
            new policy.
          </p>
        </Section>

        <Section title="Contact">
          <p>
            Questions about this policy? Open an issue on{" "}
            <a
              href="https://github.com/PropzSaladaz/Laze"
              target="_blank" rel="noopener noreferrer"
              style={{ color: "var(--color-secondary)", textDecoration: "underline" }}
            >
              GitHub
            </a>.
          </p>
        </Section>

      </main>

      {/* ── Footer ───────────────────────────────────────────────── */}
      <footer style={{
        borderTop: "1px solid var(--color-divider)",
        padding: "40px 24px",
        textAlign: "center",
      }}>
        <div style={{ display: "flex", alignItems: "center", justifyContent: "center", gap: 10, marginBottom: 16 }}>
          <Image src="/images/icon.png" alt="Laze icon" width={24} height={24}
            style={{ borderRadius: 6, opacity: 0.8 }} />
          <span style={{ fontWeight: 700, color: "var(--color-primary)", fontSize: 16 }}>Laze</span>
        </div>
        <p style={{ fontSize: 13, color: "var(--color-text-muted)" }}>
          MIT License —{" "}
          <a href="https://github.com/PropzSaladaz/Laze" target="_blank" rel="noopener noreferrer"
            style={{ color: "var(--color-text-muted)", textDecoration: "underline" }}>
            View on GitHub
          </a>
        </p>
      </footer>

    </div>
  );
}

function Section({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <section style={{ marginBottom: 48 }}>
      <h2 style={{
        fontSize: "1.1rem",
        fontWeight: 700,
        color: "var(--color-text)",
        marginBottom: 16,
        paddingBottom: 10,
        borderBottom: "1px solid var(--color-divider)",
      }}>{title}</h2>
      <div style={{ fontSize: 14.5, color: "var(--color-text-muted)", lineHeight: 1.75 }}>
        {children}
      </div>
    </section>
  );
}

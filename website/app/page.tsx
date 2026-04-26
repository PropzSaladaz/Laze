import Image from "next/image";
import {
  HeroCTAs,
  MobileDownloadList,
  DesktopDownloadList,
} from "./components/PlatformDownloads";

// ── Feature data ──────────────────────────────────────────────────────
const features = [
  {
    title: "Mouse & Cursor Control",
    icon: "🖱️",
    color: "var(--color-primary)",
    items: [
      "Precision movement with velocity acceleration",
      "Two-finger scroll & drag-and-drop",
      "Adjustable sensitivity on-the-fly",
      "Sub-pixel smoothing — no jitter",
    ],
  },
  {
    title: "Desktop Server",
    icon: "🖥️",
    color: "var(--color-secondary)",
    items: [
      "Multi-client support",
      "System tray with autostart on boot",
      "Instant LAN discovery — no IP config",
      "Graceful disconnect notifications",
    ],
  },
  {
    title: "Mobile App",
    icon: "📱",
    color: "#a78bfa",
    items: [
      "Pre-built & custom shortcuts",
      "Terminal commands from your phone",
      "Cross-platform commands (Linux, Windows, macOS)",
      "Fullscreen touchpad & theme support",
    ],
  },
  {
    title: "Personalization",
    icon: "✨",
    color: "#34d399",
    items: [
      "Shortcuts & settings persist across restarts",
      "Custom device naming",
      "Session continuity — pick up where you left off",
    ],
  },
];

// ── Comparison table data ─────────────────────────────────────────────
const compareRows = [
  { feature: "Cost / License",     laze: "Free & Open Source", kde: "Free & Open Source", unified: "Freemium",         remote: "Freemium" },
  { feature: "Custom Commands",    laze: "✅ On phone",         kde: "⚠️ On desktop",      unified: "💰 Paid feature",   remote: "❌ Limited" },
  { feature: "Auto Discovery",     laze: "✅ Instant LAN",      kde: "⚠️ Pairing needed",  unified: "⚠️ Server install", remote: "⚠️ Helper install" },
  { feature: "UX Design",          laze: "Modern, mobile-first",kde: "Functional",         unified: "Functional",        remote: "Basic" },
  { feature: "Architecture",       laze: "Rust + Tauri + Flutter",kde:"C++ / Qt",          unified: "Mixed native",      remote: "Proprietary" },
];

export default function Home() {
  return (
    <div style={{ background: "var(--color-bg)", minHeight: "100vh" }}>

      {/* ── Navbar ─────────────────────────────────────────────────── */}
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
          {/* Logo */}
          <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
            <Image src="/images/icon.png" alt="Laze icon" width={32} height={32}
              style={{ borderRadius: 8 }} />
            <span style={{
              fontSize: 20, fontWeight: 700,
              color: "var(--color-primary)", letterSpacing: "-0.02em",
            }}>Laze</span>
          </div>

          {/* Nav links */}
          <div style={{ display: "flex", alignItems: "center", gap: 32 }}>
            <NavLink href="#features">Features</NavLink>
            <NavLink href="#screenshots">Screenshots</NavLink>
            <NavLink href="#download">Download</NavLink>
            <a
              href="https://github.com/PropzSaladaz/Laze"
              target="_blank" rel="noopener noreferrer"
              style={{
                display: "flex", alignItems: "center", gap: 8,
                padding: "8px 18px",
                background: "var(--color-surface-2)",
                border: "1px solid var(--color-border)",
                borderRadius: "var(--radius-pill)",
                color: "var(--color-text)",
                textDecoration: "none",
                fontSize: 14, fontWeight: 500,
                transition: "border-color 0.2s",
              }}
            >
              <GithubIcon /> GitHub
            </a>
          </div>
        </div>
      </nav>

      {/* ── Hero ───────────────────────────────────────────────────── */}
      <section style={{
        position: "relative", overflow: "hidden",
        padding: "100px 24px 120px",
        textAlign: "center",
      }}>
        {/* Background glow blobs */}
        <div style={{
          position: "absolute", top: "10%", left: "50%",
          transform: "translateX(-50%)",
          width: 600, height: 400,
          background: "radial-gradient(ellipse, rgba(233,188,116,0.08) 0%, transparent 70%)",
          pointerEvents: "none",
        }} />

        <div style={{ maxWidth: 800, margin: "0 auto", position: "relative" }}>
          {/* Badge */}
          <div style={{
            display: "inline-flex", alignItems: "center", gap: 8,
            padding: "6px 16px",
            background: "rgba(233,188,116,0.1)",
            border: "1px solid rgba(233,188,116,0.3)",
            borderRadius: "var(--radius-pill)",
            marginBottom: 28,
          }}>
            <span style={{ fontSize: 12, color: "var(--color-primary)", fontWeight: 600, letterSpacing: "0.06em", textTransform: "uppercase" }}>
              Free &amp; Open Source
            </span>
          </div>

          <h1 style={{
            fontSize: "clamp(2.4rem, 6vw, 4rem)",
            fontWeight: 800,
            lineHeight: 1.1,
            letterSpacing: "-0.03em",
            marginBottom: 20,
            color: "var(--color-text)",
          }}>
            Your Phone.{" "}
            <span className="gradient-text">Your Remote.</span>
            <br />Your Control.
          </h1>

          <p style={{
            fontSize: "clamp(1rem, 2vw, 1.2rem)",
            color: "var(--color-text-muted)",
            lineHeight: 1.7,
            maxWidth: 560, margin: "0 auto 40px",
          }}>
            Transform your smartphone into a powerful, intuitive remote control for
            your desktop. <strong style={{ color: "var(--color-text)" }}>Seamless. Responsive. Beautiful.</strong>
          </p>

          {/* CTA buttons */}
          <HeroCTAs />

          {/* Mobile screenshots */}
          <div style={{ marginTop: 64, maxWidth: 860, margin: "64px auto 0" }}>
            <div style={{
              display: "grid",
              gridTemplateColumns: "repeat(3, 1fr)",
              gap: 16,
            }}>
              {["p1.jpg", "p2.jpg", "p3.jpg"].map((img, i) => (
                <div key={img} style={{
                  borderRadius: "var(--radius-xl)",
                  overflow: "hidden",
                  border: "1px solid var(--color-border)",
                  boxShadow: "0 16px 40px rgba(0,0,0,0.4)",
                }}>
                  <Image
                    src={`/images/${img}`}
                    alt={`Laze mobile app screenshot ${i + 1}`}
                    width={400} height={800}
                    style={{ width: "100%", height: "auto", display: "block" }}
                  />
                </div>
              ))}
            </div>
          </div>
        </div>

      </section>

      {/* ── What is Laze ───────────────────────────────────────────── */}
      <section style={{ padding: "96px 24px", borderTop: "1px solid var(--color-divider)" }}>
        <div style={{ maxWidth: 1100, margin: "0 auto" }}>
          <SectionLabel>What is Laze?</SectionLabel>
          <h2 style={{ ...h2Style, maxWidth: 640 }}>
            Built for the ultimate{" "}
            <span className="gradient-text">lazy lifestyle</span>
          </h2>
          <p style={{ ...bodyStyle, maxWidth: 660, marginBottom: 48 }}>
            Laze is a cross-platform remote control system that bridges your mobile device and
            desktop computer. Whether you're giving a presentation, watching media from across
            the room, or just want freedom from your desk — Laze delivers a fluid, lag-free experience
            designed to feel like an extension of your computer.
          </p>

          {/* Differentiator cards */}
          <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(220px, 1fr))", gap: 16 }}>
            {[
              { icon: "⚡", title: "Instant Setup", desc: "Auto-discovers your desktop over LAN — no IP configuration, no pairing codes." },
              { icon: "🎨", title: "Modern UI", desc: "Clean, minimal design that feels right. Not an afterthought." },
              { icon: "🔓", title: "Free Forever", desc: "MIT licensed. No subscriptions, no feature gates, no nonsense." },
              { icon: "🛠️", title: "Fully Custom", desc: "Create your own shortcuts and terminal commands directly on your phone." },
            ].map((c) => (
              <div key={c.title} className="card" style={{ padding: 24 }}>
                <div style={{ fontSize: 28, marginBottom: 12 }}>{c.icon}</div>
                <div style={{ fontWeight: 700, fontSize: 15, marginBottom: 8, color: "var(--color-text)" }}>{c.title}</div>
                <div style={{ fontSize: 14, color: "var(--color-text-muted)", lineHeight: 1.6 }}>{c.desc}</div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ── Features ───────────────────────────────────────────────── */}
      <section id="features" style={{ padding: "96px 24px", borderTop: "1px solid var(--color-divider)" }}>
        <div style={{ maxWidth: 1100, margin: "0 auto" }}>
          <SectionLabel>Features</SectionLabel>
          <h2 style={h2Style}>Everything you need,{" "}
            <span className="gradient-text">nothing you don't</span>
          </h2>

          <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(280px, 1fr))", gap: 20, marginTop: 52 }}>
            {features.map((group) => (
              <div key={group.title} className="card" style={{ padding: "28px 28px 24px" }}>
                <div style={{ display: "flex", alignItems: "center", gap: 10, marginBottom: 20 }}>
                  <span style={{ fontSize: 22 }}>{group.icon}</span>
                  <span style={{
                    fontWeight: 700, fontSize: 15,
                    color: group.color,
                  }}>{group.title}</span>
                </div>
                <ul style={{ listStyle: "none", display: "flex", flexDirection: "column", gap: 10 }}>
                  {group.items.map((item) => (
                    <li key={item} style={{ display: "flex", gap: 10, alignItems: "flex-start" }}>
                      <span style={{
                        width: 5, height: 5, borderRadius: "50%",
                        background: group.color,
                        marginTop: 7, flexShrink: 0,
                      }} />
                      <span style={{ fontSize: 13.5, color: "var(--color-text-muted)", lineHeight: 1.5 }}>{item}</span>
                    </li>
                  ))}
                </ul>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ── Screenshots ────────────────────────────────────────────── */}
      <section id="screenshots" style={{ padding: "96px 24px", borderTop: "1px solid var(--color-divider)" }}>
        <div style={{ maxWidth: 1100, margin: "0 auto" }}>
          <SectionLabel>Screenshots</SectionLabel>
          <h2 style={h2Style}>See it in action</h2>

          {/* Desktop screenshot */}
          <div style={{ marginTop: 52 }}>
            <p style={{ ...captionStyle, marginBottom: 20 }}>Desktop Dashboard</p>
            <div style={{
              borderRadius: "var(--radius-xl)",
              overflow: "hidden",
              border: "1px solid var(--color-border)",
              boxShadow: "0 24px 60px rgba(0,0,0,0.45)",
            }} className="glow-secondary">
              <Image
                src="/images/desktop.png"
                alt="Laze desktop dashboard"
                width={1200} height={700}
                style={{ width: "100%", height: "auto", display: "block" }}
              />
            </div>
            <p style={{ ...bodyStyle, textAlign: "center", maxWidth: 580, margin: "16px auto 0" }}>
              A clean, unobtrusive control center that lives in your system tray. Monitor connections,
              toggle autostart, and see your server status at a glance.
            </p>
          </div>
        </div>
      </section>

      {/* ── The Story ──────────────────────────────────────────────── */}
      <section style={{ padding: "96px 24px", borderTop: "1px solid var(--color-divider)" }}>
        <div style={{ maxWidth: 720, margin: "0 auto", textAlign: "center" }}>
          <SectionLabel>The Story</SectionLabel>
          <h2 style={{ ...h2Style, textAlign: "center" }}>
            Born from watching movies{" "}
            <span className="gradient-text">in bed</span>
          </h2>
          <p style={{ ...bodyStyle, textAlign: "center", marginBottom: 20 }}>
            It all started with a simple frustration: watching a movie from bed, but having to get up
            every time something needed adjusting. No TV subscription — just a laptop connected to the
            TV and free streaming sites.
          </p>
          <p style={{ ...bodyStyle, textAlign: "center", marginBottom: 20 }}>
            Every existing app was either cumbersome to configure, ugly, or both. So Laze was built:
            a clean, modern, simple UI where you can open Firefox on your favourite movie site with{" "}
            <strong style={{ color: "var(--color-primary)" }}>1 swipe and 1 click</strong>.
          </p>
          <p style={{ color: "var(--color-text-muted)", fontSize: 15, lineHeight: 1.7, textAlign: "center" }}>
            The ultimate lazy solution for the ultimate lazy lifestyle. 🛋️
          </p>
        </div>
      </section>

      {/* ── How it compares ────────────────────────────────────────── */}
      <section style={{ padding: "96px 24px", borderTop: "1px solid var(--color-divider)" }}>
        <div style={{ maxWidth: 1000, margin: "0 auto" }}>
          <SectionLabel>Comparison</SectionLabel>
          <h2 style={h2Style}>How Laze compares</h2>
          <div style={{ marginTop: 40, overflowX: "auto" }}>
            <table style={{
              width: "100%", borderCollapse: "collapse",
              fontSize: 14,
            }}>
              <thead>
                <tr>
                  {["Feature", "Laze", "KDE Connect", "Unified Remote", "Remote Mouse"].map((h, i) => (
                    <th key={h} style={{
                      padding: "12px 16px",
                      textAlign: "left",
                      background: i === 1 ? "rgba(233,188,116,0.08)" : "var(--color-surface-1)",
                      color: i === 1 ? "var(--color-primary)" : "var(--color-text-muted)",
                      fontWeight: 600,
                      borderBottom: "1px solid var(--color-divider)",
                      borderLeft: i === 1 ? "1px solid rgba(233,188,116,0.2)" : "none",
                      borderRight: i === 1 ? "1px solid rgba(233,188,116,0.2)" : "none",
                      fontSize: 13,
                    }}>{h}</th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {compareRows.map((row, ri) => (
                  <tr key={row.feature} style={{
                    borderBottom: ri < compareRows.length - 1 ? "1px solid var(--color-divider)" : "none",
                  }}>
                    {[row.feature, row.laze, row.kde, row.unified, row.remote].map((cell, ci) => (
                      <td key={ci} style={{
                        padding: "14px 16px",
                        color: ci === 0 ? "var(--color-text-muted)" : ci === 1 ? "var(--color-text)" : "var(--color-text-muted)",
                        fontWeight: ci === 0 ? 600 : ci === 1 ? 500 : 400,
                        background: ci === 1 ? "rgba(233,188,116,0.04)" : "transparent",
                        borderLeft: ci === 1 ? "1px solid rgba(233,188,116,0.1)" : "none",
                        borderRight: ci === 1 ? "1px solid rgba(233,188,116,0.1)" : "none",
                      }}>{cell}</td>
                    ))}
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </section>

      {/* ── Download ───────────────────────────────────────────────── */}
      <section id="download" style={{
        padding: "96px 24px",
        borderTop: "1px solid var(--color-divider)",
      }}>
        <div style={{ maxWidth: 860, margin: "0 auto", textAlign: "center" }}>
          <SectionLabel>Download</SectionLabel>
          <h2 style={{ ...h2Style, textAlign: "center" }}>Get Laze for free</h2>
          <p style={{ ...bodyStyle, textAlign: "center", maxWidth: 500, margin: "0 auto 52px" }}>
            Pre-built binaries are available on GitHub Releases. No account required, no store needed.
          </p>

          <div style={{
            display: "grid",
            gridTemplateColumns: "repeat(auto-fit, minmax(280px, 1fr))",
            gap: 20,
          }}>
            {/* Android card */}
            <div className="card glow-primary" style={{ padding: "32px 28px", textAlign: "left" }}>
              <div style={{ fontSize: 36, marginBottom: 16 }}>📱</div>
              <h3 style={{ fontSize: 18, fontWeight: 700, marginBottom: 8, color: "var(--color-text)" }}>
                Mobile App
              </h3>
              <p style={{ fontSize: 14, color: "var(--color-text-muted)", lineHeight: 1.6, marginBottom: 24 }}>
                The remote controller for your phone. Tested on Android.
              </p>
              <MobileDownloadList />
            </div>

            {/* Desktop card */}
            <div className="card glow-secondary" style={{ padding: "32px 28px", textAlign: "left" }}>
              <div style={{ fontSize: 36, marginBottom: 16 }}>🖥️</div>
              <h3 style={{ fontSize: 18, fontWeight: 700, marginBottom: 8, color: "var(--color-text)" }}>
                Desktop Server
              </h3>
              <p style={{ fontSize: 14, color: "var(--color-text-muted)", lineHeight: 1.6, marginBottom: 24 }}>
                The server that runs on your computer. Available for Linux, Windows, and macOS.
              </p>
              <DesktopDownloadList />
            </div>
          </div>

          <p style={{ marginTop: 32, fontSize: 13, color: "var(--color-text-muted)" }}>
            Not yet on the Play Store or any desktop store — coming soon.
          </p>
        </div>
      </section>

      {/* ── Footer ─────────────────────────────────────────────────── */}
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
        <p style={{ fontSize: 13, color: "var(--color-text-muted)", marginBottom: 12 }}>
          Built with ❤️ by{" "}
          <a href="https://github.com/PropzSaladaz" target="_blank" rel="noopener noreferrer"
            style={{ color: "var(--color-secondary)", textDecoration: "none" }}>PropzSaladaz</a>
        </p>
        <p style={{ fontSize: 12, color: "var(--color-text-muted)" }}>
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

// ── Shared style objects ──────────────────────────────────────────────
const h2Style: React.CSSProperties = {
  fontSize: "clamp(1.6rem, 3.5vw, 2.4rem)",
  fontWeight: 800,
  letterSpacing: "-0.025em",
  lineHeight: 1.2,
  color: "var(--color-text)",
  marginBottom: 16,
};

const bodyStyle: React.CSSProperties = {
  fontSize: 16,
  color: "var(--color-text-muted)",
  lineHeight: 1.75,
};

const captionStyle: React.CSSProperties = {
  fontSize: 13,
  fontWeight: 600,
  letterSpacing: "0.06em",
  textTransform: "uppercase" as const,
  color: "var(--color-secondary)",
};

// ── Reusable components ───────────────────────────────────────────────
function SectionLabel({ children }: { children: React.ReactNode }) {
  return (
    <p style={{
      fontSize: 12, fontWeight: 600,
      letterSpacing: "0.1em", textTransform: "uppercase",
      color: "var(--color-primary)",
      marginBottom: 12,
    }}>{children}</p>
  );
}

function NavLink({ href, children }: { href: string; children: React.ReactNode }) {
  return (
    <a href={href} style={{
      color: "var(--color-text-muted)", textDecoration: "none",
      fontSize: 14, fontWeight: 500,
      transition: "color 0.2s",
    }}>{children}</a>
  );
}

// ── Inline SVG icons ──────────────────────────────────────────────────
function GithubIcon() {
  return (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor">
      <path d="M12 0C5.37 0 0 5.37 0 12c0 5.3 3.438 9.8 8.205 11.385.6.113.82-.258.82-.577 0-.285-.01-1.04-.015-2.04-3.338.724-4.042-1.61-4.042-1.61-.546-1.387-1.333-1.757-1.333-1.757-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23A11.509 11.509 0 0 1 12 5.803c1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.91 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222 0 1.606-.015 2.896-.015 3.286 0 .322.216.694.825.576C20.565 21.796 24 17.296 24 12c0-6.63-5.37-12-12-12z" />
    </svg>
  );
}

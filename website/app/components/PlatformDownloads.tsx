"use client";

import { useEffect, useState } from "react";

// All assets live under the same GitHub Releases page — file names carry
// version suffixes so we can't deep-link by extension reliably.
const RELEASES = "https://github.com/PropzSaladaz/Laze/releases/latest";

type DesktopOS = "linux" | "windows" | "macos";
type MobileOS = "android" | "ios";
type OS = DesktopOS | MobileOS | "unknown";

type DesktopFormat = {
  os: DesktopOS;
  label: string;
};

const DESKTOP_FORMATS: DesktopFormat[] = [
  { os: "linux",   label: "Linux .AppImage" },
  { os: "linux",   label: "Linux .deb" },
  { os: "windows", label: "Windows installer (.exe)" },
  { os: "windows", label: "Windows .msi" },
  { os: "macos",   label: "macOS .dmg" },
];

const DESKTOP_LABELS: Record<DesktopOS, string> = {
  linux: "Linux",
  windows: "Windows",
  macos: "macOS",
};

function detectOS(): OS {
  if (typeof navigator === "undefined") return "unknown";
  const ua = navigator.userAgent.toLowerCase();
  const platform = (navigator.platform || "").toLowerCase();
  if (/android/.test(ua)) return "android";
  if (/iphone|ipad|ipod/.test(ua) || (/mac/.test(platform) && navigator.maxTouchPoints > 1)) return "ios";
  if (/win/.test(ua) || /win/.test(platform)) return "windows";
  if (/mac/.test(ua) || /mac/.test(platform)) return "macos";
  if (/linux|x11|cros/.test(ua) || /linux/.test(platform)) return "linux";
  return "unknown";
}

function usePlatform(): { os: OS; ready: boolean } {
  // Render in a neutral state on the server, then hydrate with the real OS.
  // This keeps SSR markup deterministic and avoids hydration mismatches.
  const [state, setState] = useState<{ os: OS; ready: boolean }>({ os: "unknown", ready: false });
  useEffect(() => { setState({ os: detectOS(), ready: true }); }, []);
  return state;
}

// ── Hero CTAs ─────────────────────────────────────────────────────────
export function HeroCTAs() {
  const { os, ready } = usePlatform();
  const isMobile = os === "android" || os === "ios";
  const detectedDesktop: DesktopOS = (os === "linux" || os === "windows" || os === "macos") ? os : "linux";

  // Until we know the OS, show both buttons un-emphasised so SSR/CSR match.
  const mobilePrimary = ready && isMobile;
  const desktopPrimary = ready && !isMobile && os !== "unknown";

  return (
    <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 14 }}>
      <div style={{ display: "flex", gap: 16, justifyContent: "center", flexWrap: "wrap" }}>
        <DownloadBtn href={RELEASES} primary={mobilePrimary}>
          <AndroidIcon /> Download for Android
        </DownloadBtn>
        <DownloadBtn href={RELEASES} primary={desktopPrimary}>
          <PlatformIcon os={detectedDesktop} /> Download for {DESKTOP_LABELS[detectedDesktop]}
        </DownloadBtn>
      </div>
      <a href="#download" style={{
        fontSize: 13,
        color: "var(--color-text-muted)",
        textDecoration: "none",
        borderBottom: "1px dashed var(--color-border)",
        paddingBottom: 1,
      }}>
        {ready && os !== "unknown"
          ? `Detected ${prettyOSName(os)} — see all platforms ↓`
          : "See all platforms ↓"}
      </a>
    </div>
  );
}

// ── Mobile download card body ─────────────────────────────────────────
export function MobileDownloadList() {
  const { os, ready } = usePlatform();
  const onIOS = ready && os === "ios";
  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
      <DownloadBtn href={RELEASES} primary full>
        <AndroidIcon /> Android APK
        {ready && os === "android" && <RecommendedBadge />}
      </DownloadBtn>
      <span style={{ fontSize: 12, color: "var(--color-text-muted)" }}>
        {onIOS ? "iOS — coming soon (we noticed you're on iOS)" : "iOS — not yet released"}
      </span>
    </div>
  );
}

// ── Desktop download card body ────────────────────────────────────────
export function DesktopDownloadList() {
  const { os, ready } = usePlatform();
  const detected: DesktopOS | null =
    ready && (os === "linux" || os === "windows" || os === "macos") ? os : null;

  // Sort detected OS's formats first, preserving order otherwise.
  const sorted = detected
    ? [...DESKTOP_FORMATS].sort((a, b) => Number(b.os === detected) - Number(a.os === detected))
    : DESKTOP_FORMATS;

  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
      {sorted.map((fmt, i) => {
        const isRecommended = detected !== null && fmt.os === detected && i === 0;
        return (
          <DownloadBtn key={fmt.label} href={RELEASES} primary={isRecommended} full>
            <PlatformIcon os={fmt.os} /> {fmt.label}
            {isRecommended && <RecommendedBadge />}
          </DownloadBtn>
        );
      })}
    </div>
  );
}

// ── Helpers ───────────────────────────────────────────────────────────
function prettyOSName(os: OS): string {
  switch (os) {
    case "android": return "Android";
    case "ios":     return "iOS";
    case "linux":   return "Linux";
    case "windows": return "Windows";
    case "macos":   return "macOS";
    default:        return "your system";
  }
}

function PlatformIcon({ os }: { os: DesktopOS }) {
  if (os === "linux")   return <LinuxIcon />;
  if (os === "windows") return <WindowsIcon />;
  return <AppleIcon />;
}

function RecommendedBadge() {
  return (
    <span style={{
      marginLeft: 6,
      fontSize: 10,
      fontWeight: 700,
      letterSpacing: "0.06em",
      textTransform: "uppercase",
      padding: "2px 8px",
      borderRadius: "var(--radius-pill)",
      background: "rgba(0,0,0,0.18)",
      color: "inherit",
    }}>
      For your system
    </span>
  );
}

function DownloadBtn({
  href, children, primary, full,
}: {
  href: string;
  children: React.ReactNode;
  primary?: boolean;
  full?: boolean;
}) {
  return (
    <a
      href={href}
      target="_blank" rel="noopener noreferrer"
      style={{
        display: "inline-flex", alignItems: "center", justifyContent: "center", gap: 8,
        padding: "12px 24px",
        background: primary ? "var(--color-primary)" : "var(--color-surface-2)",
        border: primary ? "none" : "1px solid var(--color-border)",
        borderRadius: "var(--radius-pill)",
        color: primary ? "var(--color-on-primary)" : "var(--color-text)",
        textDecoration: "none",
        fontSize: 14, fontWeight: 600,
        width: full ? "100%" : undefined,
        transition: "opacity 0.2s",
      }}
    >
      {children}
    </a>
  );
}

// ── Icons ─────────────────────────────────────────────────────────────
function AndroidIcon() {
  return (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
      <path d="M17.523 15.341A5.97 5.97 0 0 0 18 13a5.97 5.97 0 0 0-.477-2.341l2.247-2.247a9.97 9.97 0 0 1 0 9.176l-2.247-2.247zM13 18a5.97 5.97 0 0 0 2.341-.477l2.247 2.247a9.97 9.97 0 0 1-9.176 0l2.247-2.247A5.97 5.97 0 0 0 13 18zM6.477 15.341L4.23 17.588a9.97 9.97 0 0 1 0-9.176l2.247 2.247A5.97 5.97 0 0 0 6 13a5.97 5.97 0 0 0 .477 2.341zM13 8a5.97 5.97 0 0 0-2.341.477L8.412 6.23a9.97 9.97 0 0 1 9.176 0l-2.247 2.247A5.97 5.97 0 0 0 13 8zm0 8a3 3 0 1 1 0-6 3 3 0 0 1 0 6z"/>
    </svg>
  );
}

function LinuxIcon() {
  return (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
      <path d="M12.504 0C6.111 0 1.5 5.188 1.5 11.5c0 3.916 2.001 7.391 5.068 9.506l-.006 1.494H9l.001-1.19A10.977 10.977 0 0 0 12.504 23C18.896 23 23.5 17.812 23.5 11.5S18.896 0 12.504 0zm0 2C17.74 2 21.5 6.313 21.5 11.5S17.74 21 12.504 21A10.5 10.5 0 0 1 2.5 11.5C2.5 6.313 7.267 2 12.504 2zm-.004 3c-1.93 0-3.5 1.57-3.5 3.5 0 1.374.799 2.566 1.961 3.146C8.976 12.454 8 14.362 8 16.5V18h9v-1.5c0-2.138-.976-4.046-2.961-4.854C15.2 11.066 16 9.874 16 8.5c0-1.93-1.57-3.5-3.5-3.5z"/>
    </svg>
  );
}

function WindowsIcon() {
  return (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
      <path d="M0 3.449L9.75 2.1v9.451H0m10.949-9.602L24 0v11.4H10.949M0 12.6h9.75v9.451L0 20.699M10.949 12.6H24V24l-12.9-1.801"/>
    </svg>
  );
}

function AppleIcon() {
  return (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
      <path d="M17.05 20.28c-.98.95-2.05.8-3.08.35-1.09-.46-2.09-.48-3.24 0-1.44.62-2.2.44-3.06-.35C2.79 15.25 3.51 7.59 9.05 7.31c1.35.07 2.29.74 3.08.8 1.18-.24 2.31-.93 3.57-.84 1.51.12 2.65.72 3.4 1.8-3.12 1.87-2.38 5.98.48 7.13-.57 1.5-1.31 2.99-2.54 4.09zM12.03 7.25c-.15-2.23 1.66-4.07 3.74-4.25.29 2.58-2.34 4.5-3.74 4.25z"/>
    </svg>
  );
}

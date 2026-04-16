import type { Metadata } from "next";
import { SpeedInsights } from "@vercel/speed-insights/next";
import { Analytics } from "@vercel/analytics/next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Laze — Your Phone. Your Remote. Your Control.",
  description:
    "Transform your smartphone into a powerful, intuitive remote control for your desktop. Seamless. Responsive. Beautiful.",
  icons: { icon: "/images/icon.png" },
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" data-theme="dark">
      <body>
        {children}
        <SpeedInsights />
        <Analytics />
      </body>
    </html>
  );
}

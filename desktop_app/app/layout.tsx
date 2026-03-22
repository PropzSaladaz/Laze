import "./theme/css-vars.css";
import "./globals.css";

export const metadata = {
  title: 'Mobile Virtual Device',
  description: 'Desktop control panel for mobile virtual input',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en" data-theme="light">
      <body>{children}</body>
    </html>
  )
}

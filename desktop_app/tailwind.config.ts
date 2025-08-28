// tailwind.config.ts
import type { Config } from 'tailwindcss'

const config: Config = {
  content: [
    './app/**/*.{ts,tsx}',
    './pages/**/*.{ts,tsx}',
    './components/**/*.{ts,tsx}',
  ],
  // Let either a class OR your data-attr flip dark mode:
  darkMode: ['class', '[data-theme="dark"]'],
  theme: {
    extend: {
      colors: {
        bg: 'var(--color-bg)',
        fg: 'var(--color-fg)',
        surface1: 'var(--color-surface-1)',
        surface2: 'var(--color-surface-2)',
        surface3: 'var(--color-surface-3)',
        text: 'var(--color-text)',
        'text-muted': 'var(--color-text-muted)',
        'text-inverse': 'var(--color-text-inverse)',
        muted: 'var(--color-muted)',
        border: 'var(--color-border)',
        divider: 'var(--color-divider)',
        primary: 'var(--color-primary)',
        onPrimary: 'var(--color-onPrimary)',
        secondary: 'var(--color-secondary)',
        onSecondary: 'var(--color-onSecondary)',
        link: 'var(--color-link)',
        success: 'var(--color-success)',
        onSuccess: 'var(--color-onSuccess)',
        warning: 'var(--color-warning)',
        onWarning: 'var(--color-onWarning)',
        error: 'var(--color-error)',
        onError: 'var(--color-onError)',
        hover: 'var(--color-hover)',
        active: 'var(--color-active)',
        focus: 'var(--color-focus)',
        'disabled-bg': 'var(--color-disabled-bg)',
        'disabled-fg': 'var(--color-disabled-fg)',
        'disabled-border': 'var(--color-disabled-border)',
        overlay: 'var(--color-overlay)',
      },
      ringColor: {
        DEFAULT: 'var(--color-focus)',
      },
      divideColor: {
        DEFAULT: 'var(--color-divider)',
      },
      // Optional: shadows via vars (nice for elevation themes)
      boxShadow: {
        low: '0 1px 2px 0 var(--color-shadow-low)',
        high: '0 10px 15px -3px var(--color-shadow-high), 0 4px 6px -4px var(--color-shadow-high)',
      },
    },
  },
  plugins: [],
}

export default config

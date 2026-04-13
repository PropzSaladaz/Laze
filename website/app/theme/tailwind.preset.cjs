/*
 * AUTO-GENERATED Tailwind preset from tokens.json
 * Usage in tailwind.config.ts:
 *   export default { presets: [require('./theme/tailwind.preset.cjs')], ... }
 */
const plugin = require('tailwindcss/plugin');

module.exports = {
  darkMode: ['class', '[data-theme="dark"]'],
  theme: {
    extend: {
      colors: {
  "bg": "var(--color-bg)",
  "fg": "var(--color-fg)",
  "surface-1": "var(--color-surface-1)",
  "surface-2": "var(--color-surface-2)",
  "surface-3": "var(--color-surface-3)",
  "text": "var(--color-text)",
  "text-muted": "var(--color-text-muted)",
  "text-inverse": "var(--color-text-inverse)",
  "muted": "var(--color-muted)",
  "border": "var(--color-border)",
  "divider": "var(--color-divider)",
  "primary": "var(--color-primary)",
  "onPrimary": "var(--color-onPrimary)",
  "secondary": "var(--color-secondary)",
  "onSecondary": "var(--color-onSecondary)",
  "link": "var(--color-link)",
  "success": "var(--color-success)",
  "onSuccess": "var(--color-onSuccess)",
  "warning": "var(--color-warning)",
  "onWarning": "var(--color-onWarning)",
  "error": "var(--color-error)",
  "onError": "var(--color-onError)",
  "hover": "var(--color-hover)",
  "active": "var(--color-active)",
  "focus": "var(--color-focus)",
  "disabled-bg": "var(--color-disabled-bg)",
  "disabled-fg": "var(--color-disabled-fg)",
  "disabled-border": "var(--color-disabled-border)",
  "overlay": "var(--color-overlay)",
  "shadow-high": "var(--color-shadow-high)",
  "shadow-low": "var(--color-shadow-low)"
},
      spacing: {
  "2xs": "var(--space-2xs)",
  "xs": "var(--space-xs)",
  "sm": "var(--space-sm)",
  "md": "var(--space-md)",
  "lg": "var(--space-lg)",
  "xl": "var(--space-xl)",
  "2xl": "var(--space-2xl)",
  "3xl": "var(--space-3xl)"
},
      borderRadius: {
  "xs": "var(--radius-xs)",
  "sm": "var(--radius-sm)",
  "md": "var(--radius-md)",
  "lg": "var(--radius-lg)",
  "xl": "var(--radius-xl)",
  "pill": "var(--radius-pill)"
},
      boxShadow: {
        '2layer': '0 1px 2px var(--color-shadow-low), 0 4px 8px var(--color-shadow-high)'
      }
    }
  },
  plugins: [
    // Optional: ensure ring utilities pick up tokenized color via ring-*
    plugin(function({ addUtilities, theme }) {
      const ring = {};
      const colors = theme('colors') || {};
      Object.keys(colors).forEach(name => {
        ring[`.ring-${name}`] = { '--tw-ring-color': colors[name] };
      });
      addUtilities(ring, { variants: ['responsive', 'hover', 'focus'] });
    })
  ]
};

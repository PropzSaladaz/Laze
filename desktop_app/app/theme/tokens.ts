// GENERATED — Source: tokens.json

export type ThemeMode = 'light' | 'dark';

export const tokens = {
  space: {
  "2xs": 2,
  "xs": 4,
  "sm": 8,
  "md": 12,
  "lg": 16,
  "xl": 24,
  "2xl": 32,
  "3xl": 48
},
  radius: {
  "xs": 4,
  "sm": 6,
  "md": 10,
  "lg": 14,
  "xl": 20,
  "pill": 999
},
  color: {
'bg': { light: "#ffffff", dark: "#0b1020" },
'fg': { light: "#0f172a", dark: "#e5e7eb" },
'surface-1': { light: "#f8fafc", dark: "#0f172a" },
'surface-2': { light: "#f3f6fa", dark: "#111827" },
'surface-3': { light: "#eef2f7", dark: "#161b22" },
'text': { light: "#0f172a", dark: "#e5e7eb" },
'text-muted': { light: "#64748b", dark: "#9ca3af" },
'text-inverse': { light: "#ffffff", dark: "#0b1020" },
'muted': { light: "#f1f5f9", dark: "#111827" },
'border': { light: "#e2e8f0", dark: "#1f2937" },
'divider': { light: "#e5e7eb", dark: "#293241" },
'primary': { light: "#4f46e5", dark: "#818cf8" },
'onPrimary': { light: "#ffffff", dark: "#0b1020" },
'secondary': { light: "#06b6d4", dark: "#67e8f9" },
'onSecondary': { light: "#001219", dark: "#001219" },
'link': { light: "#2563eb", dark: "#93c5fd" },
'success': { light: "#16a34a", dark: "#22c55e" },
'onSuccess': { light: "#ffffff", dark: "#0b1020" },
'warning': { light: "#f59e0b", dark: "#fbbf24" },
'onWarning': { light: "#0b1020", dark: "#0b1020" },
'error': { light: "#dc2626", dark: "#f87171" },
'onError': { light: "#ffffff", dark: "#0b1020" },
'hover': { light: "rgba(15, 23, 42, 0.04)", dark: "rgba(229, 231, 235, 0.06)" },
'active': { light: "rgba(15, 23, 42, 0.08)", dark: "rgba(229, 231, 235, 0.12)" },
'focus': { light: "#60a5fa", dark: "#60a5fa" },
'disabled-bg': { light: "#f3f4f6", dark: "#1f2937" },
'disabled-fg': { light: "#9ca3af", dark: "#6b7280" },
'disabled-border': { light: "#e5e7eb", dark: "#273043" },
'overlay': { light: "rgba(2, 6, 23, 0.36)", dark: "rgba(0, 0, 0, 0.5)" },
'shadow-high': { light: "rgba(0, 0, 0, 0.1)", dark: "rgba(0, 0, 0, 0.1)" },
'shadow-low': { light: "rgba(0, 0, 0, 0.25)", dark: "rgba(0, 0, 0, 0.25)" },
  }
} as const;

export function getTheme(mode: ThemeMode) {
  const c = Object.fromEntries(Object.entries(tokens.color).map(([k,v]) => [k, v[mode]]));
  return { color: c, space: tokens.space, radius: tokens.radius };
}

export function applyTheme(mode: ThemeMode, root: HTMLElement = document.documentElement) {
  const theme = getTheme(mode);
  for (const [k, val] of Object.entries(theme.color)) root.style.setProperty(`--color-${k}`, String(val));
  for (const [k, val] of Object.entries(theme.space)) root.style.setProperty(`--space-${k}`, `${val}px`);
  for (const [k, val] of Object.entries(theme.radius)) root.style.setProperty(`--radius-${k}`, `${val}px`);
  root.setAttribute('data-theme', mode);
}

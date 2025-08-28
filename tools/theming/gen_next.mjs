// tools/next/gen_next.mjs
import fs from 'fs';
import path from 'path';
import { readTokens, ensureDir, flattenColorTokens, anyColorToCss, banner } from './utils.mjs';

export function generateNext(tokens, outDir, srcName = 'tokens.json') {
  const { color = {}, space = {}, radius = {} } = tokens;
  const flat = flattenColorTokens(color); // [{name, light, dark}, ...]

<<<<<<< HEAD
  // tokens.ts
  const ts = `${banner(srcName)}
export type ThemeMode = 'light' | 'dark';

export const tokens = {
  space: ${JSON.stringify(space, null, 2)},
  radius: ${JSON.stringify(radius, null, 2)},
  color: {
${flat.map(t => `'${t.name}': { light: ${JSON.stringify(t.light)}, dark: ${JSON.stringify(t.dark)} },`).join('\n')}
  }
} as const;

export function getTheme(mode: ThemeMode) {
  const c = Object.fromEntries(Object.entries(tokens.color).map(([k,v]) => [k, v[mode]]));
  return { color: c, space: tokens.space, radius: tokens.radius };
}

export function applyTheme(mode: ThemeMode, root: HTMLElement = document.documentElement) {
  const theme = getTheme(mode);
  for (const [k, val] of Object.entries(theme.color)) root.style.setProperty(\`--color-\${k}\`, String(val));
  for (const [k, val] of Object.entries(theme.space)) root.style.setProperty(\`--space-\${k}\`, \`\${val}px\`);
  for (const [k, val] of Object.entries(theme.radius)) root.style.setProperty(\`--radius-\${k}\`, \`\${val}px\`);
  root.setAttribute('data-theme', mode);
}
`;

  // css-vars.css
=======
  // ---------- css-vars.css ----------
>>>>>>> ce0240a7e269d875eb2f395fcb39776673a8f1c2
  const lightCss = [], darkCss = [];
  for (const t of flat) {
    lightCss.push(`  --color-${t.name}: ${anyColorToCss(t.light)};`);
    darkCss.push(`  --color-${t.name}: ${anyColorToCss(t.dark)};`);
  }
  for (const [k,v] of Object.entries(space)) {
    lightCss.push(`  --space-${k}: ${v}px;`);
    darkCss.push(`  --space-${k}: ${v}px;`);
  }
  for (const [k,v] of Object.entries(radius)) {
    lightCss.push(`  --radius-${k}: ${v}px;`);
    darkCss.push(`  --radius-${k}: ${v}px;`);
  }
  const css = `/* GENERATED — Source: ${path.basename(srcName)} */
:root[data-theme="light"] {
${lightCss.join('\n')}
}
:root[data-theme="dark"] {
${darkCss.join('\n')}
}
/* Optional helpers */
.focus-ring { outline: 2px solid var(--color-focus); outline-offset: 2px; }
.shadow-2layer {
  box-shadow:
    0 1px 2px var(--color-shadow-low),
    0 4px 8px var(--color-shadow-high);
}
`;

<<<<<<< HEAD
  // write
  ensureDir(outDir);
  fs.writeFileSync(path.join(outDir, 'tokens.ts'), ts, 'utf8');
  fs.writeFileSync(path.join(outDir, 'css-vars.css'), css, 'utf8');
}
=======
  // ---------- tailwind.preset.cjs ----------
  // Map keys so Tailwind exposes classes like bg-surface-1, text-text, border-divider, p-md, rounded-lg, etc.
  const colorsMap = Object.fromEntries(
    flat.map(t => [t.name, `var(--${`color-${t.name}`})`])
  );
  const spacingMap = Object.fromEntries(
    Object.keys(space).map(k => [k, `var(--space-${k})`])
  );
  const radiusMap = Object.fromEntries(
    Object.keys(radius).map(k => [k, `var(--radius-${k})`])
  );

  const tailwindPreset = `/*
 * AUTO-GENERATED Tailwind preset from ${path.basename(srcName)}
 * Usage in tailwind.config.ts:
 *   export default { presets: [require('./theme/tailwind.preset.cjs')], ... }
 */
const plugin = require('tailwindcss/plugin');

module.exports = {
  darkMode: ['class', '[data-theme="dark"]'],
  theme: {
    extend: {
      colors: ${JSON.stringify(colorsMap, null, 2)},
      spacing: ${JSON.stringify(spacingMap, null, 2)},
      borderRadius: ${JSON.stringify(radiusMap, null, 2)},
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
        ring[\`.ring-\${name}\`] = { '--tw-ring-color': colors[name] };
      });
      addUtilities(ring, { variants: ['responsive', 'hover', 'focus'] });
    })
  ]
};
`;

  // ---------- optional alias utilities (shorthand helpers) ----------
  // e.g. `.surface-1` = `@apply bg-surface-1`
  const aliasLines = [];
  for (const t of flat) {
    if (t.name.startsWith('surface-')) {
      const suffix = t.name.replace('surface-', '');
      aliasLines.push(`  .surface-${suffix}{@apply bg-${t.name};}`);
    }
  }
  aliasLines.push(`  .muted{@apply text-text-muted;}`);
  aliasLines.push(`  .inverse{@apply text-text-inverse;}`);

  const aliasesCss = `/* AUTO-GENERATED utilities — optional sugar */
@tailwind utilities;
@layer utilities {
${aliasLines.join('\n')}
}
`;

  // ---------- write outputs ----------
  const target = path.join(outDir, 'theme');
  ensureDir(target);
  fs.writeFileSync(path.join(target, 'css-vars.css'), css, 'utf8');
  fs.writeFileSync(path.join(target, 'tailwind.preset.cjs'), tailwindPreset, 'utf8');
  fs.writeFileSync(path.join(target, 'tailwind.aliases.css'), aliasesCss, 'utf8');
}
>>>>>>> ce0240a7e269d875eb2f395fcb39776673a8f1c2

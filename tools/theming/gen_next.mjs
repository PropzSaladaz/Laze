// tools/next/gen_next.mjs
import fs from 'fs';
import path from 'path';
import { readTokens, ensureDir, flattenColorTokens, anyColorToCss, banner } from './utils.mjs';

export function generateNext(tokens, outDir, srcName = 'tokens.json') {
  const { color, space, radius } = tokens;
  const flat = flattenColorTokens(color);

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

  // write
  ensureDir(outDir);
  fs.writeFileSync(path.join(outDir, 'tokens.ts'), ts, 'utf8');
  fs.writeFileSync(path.join(outDir, 'css-vars.css'), css, 'utf8');
}
// tools/shared/utils.mjs
import fs from 'fs';
import path from 'path';

export function readTokens(filePath) {
  const raw = fs.readFileSync(filePath, 'utf8');
  return JSON.parse(raw);
}

export function ensureDir(p) {
  if (!fs.existsSync(p)) fs.mkdirSync(p, { recursive: true });
}

export function flattenColorTokens(colorObj) {
  // Turns { primary:{light,dark}, overlay:"rgba(...)" } into
  // [{name, light, dark}, ...]
  const out = [];
  for (const [k, v] of Object.entries(colorObj)) {
    // case where color is same independently of theme
    if (typeof v === 'string') {
      out.push({ name: k, light: v, dark: v });
    } // case where color has separate light/dark values 
    else if (v && typeof v === 'object') {
      out.push({ name: k, light: v.light, dark: v.dark });
    }
  }
  return out;
}

/**
 * Checks if a value is a valid hex color string.
 * @param {*} v - The value to check.
 * @returns {boolean} - True if the value is a valid hex color, false otherwise.
 */
export function isHex(v) {
  return typeof v === 'string' && /^#([0-9a-f]{6}|[0-9a-f]{3})$/i.test(v);
}

/** * Checks if a value is a valid RGBA color string.
 * @param {*} v - The value to check.
 * @returns {boolean} - True if the value is a valid RGBA color, false otherwise.
 */
export function isRgba(v) {
  return typeof v === 'string' && /^rgba?\(\s*\d+\s*,\s*\d+\s*,\s*\d+(?:\s*,\s*(\d*\.?\d+))?\s*\)$/i.test(v);
}

export function hexToFlutter(v) {
  // Flutter ARGB: 0xAARRGGBB
  let hex = v.replace('#','');
  if (hex.length === 3) hex = hex.split('').map(c => c+c).join('');
  const rr = hex.slice(0,2), gg = hex.slice(2,4), bb = hex.slice(4,6);
  return `0xFF${rr.toUpperCase()}${gg.toUpperCase()}${bb.toUpperCase()}`;
}

export function rgbaToFlutter(v) {
  const m = v.match(/rgba?\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)(?:\s*,\s*(\d*\.?\d+))?\s*\)/i);
  const r = Number(m[1]), g = Number(m[2]), b = Number(m[3]), a = m[4] !== undefined ? Number(m[4]) : 1;
  return `Color.fromRGBO(${r}, ${g}, ${b}, ${a})`;
}
export function anyColorToFlutter(v) {
  if (isHex(v)) return `Color(${hexToFlutter(v)})`;
  if (isRgba(v)) return rgbaToFlutter(v);
  throw new Error(`Unsupported color format: ${v}`);
}

export function anyColorToCss(v) {
  return v; // hex/rgba as-is
}

export function camel(s) {
  return s.replace(/-([a-z])/g, (_,c)=>c.toUpperCase()).replace(/[^a-zA-Z0-9_]/g,'_');
}
export function camelCap(s) {
  const c = camel(s);
  return c.charAt(0).toUpperCase() + c.slice(1);
}

export const banner = (src) => `// GENERATED — Source: ${path.basename(src)}\n`;

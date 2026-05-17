// tools/theming/gen_splash.mjs
import fs from 'fs';
import path from 'path';
import { readTokens, banner } from './utils.mjs';

export function generateSplash(tokens, outPath, srcName = 'tokens.json') {
  const bg = tokens.color.bg;
  const light = bg.light;
  const dark  = bg.dark;

  const yaml = `${banner(srcName).replace('//', '#')}# Re-generate: node tools/index.mjs design-tokens/tokens/tokens.json
# Apply:       cd mobile_client && dart run flutter_native_splash:create --path=splash_config.yaml

flutter_native_splash:
  # Pre-Android-12: window background while Flutter initialises
  color: "${light}"
  color_dark: "${dark}"
  image: "../design-tokens/icon.png"
  image_dark: "../design-tokens/icon.png"

  # Android 12+: system-controlled splash screen before Flutter starts
  android_12:
    color: "${light}"
    color_dark: "${dark}"
    image: "../design-tokens/icon.png"
    image_dark: "../design-tokens/icon.png"
    icon_background_color: "${light}"
    icon_background_color_dark: "${dark}"
`;

  fs.writeFileSync(outPath, yaml, 'utf8');
  console.log(`  splash_config.yaml → ${outPath}`);
}

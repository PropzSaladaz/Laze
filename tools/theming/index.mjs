// tools/index.mjs
import { readTokens } from './utils.mjs';
import { generateNext } from './gen_next.mjs';
import { generateFlutter } from './gen_flutter.mjs';
import { generateSplash } from './gen_splash.mjs';

const input = process.argv[2];
const targetDesktop = 'desktop_app/app';
const targetWebsite = 'website/app';
const targetFlutter = 'mobile_client/lib/presentation/core/themes';
const targetSplash  = 'mobile_client/splash_config.yaml';

if (!input) {
  console.error('Usage: node tools/index.mjs <tokens.json>');
  process.exit(1);
}

const tokens = readTokens(input);
generateNext(tokens, targetDesktop, input);
generateNext(tokens, targetWebsite, input);
generateFlutter(tokens, targetFlutter, input);
generateSplash(tokens, targetSplash, input);

console.log('✅ All artifacts generated.');

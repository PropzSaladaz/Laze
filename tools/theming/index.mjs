// tools/index.mjs
import { readTokens } from './utils.mjs';
import { generateNext } from './gen_next.mjs';
import { generateFlutter } from './gen_flutter.mjs';

const input = process.argv[2];
const targetNext = 'desktop_app/app/src/theme';
const targetFlutter = 'mobile_client/lib/presentation/core/themes';

if (!input) {
  console.error('Usage: node tools/index.mjs <tokens.json>');
  process.exit(1);
}

const tokens = readTokens(input);
generateNext(tokens, targetNext, input);
// generateFlutter(tokens, targetFlutter, input);

console.log('✅ All artifacts generated.');

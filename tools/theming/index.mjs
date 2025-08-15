// tools/index.mjs
import { readTokens } from './utils.mjs';
import { generateNext } from './gen_next.mjs';
import { generateFlutter } from './gen_flutter.mjs';

const input = process.argv[2];
const targetNext = process.argv[3] || 'desktop_app/app';
const targetFlutter = process.argv[4] || 'mobile_client/lib/presentation/core/themes';

if (!input) {
  console.error('Usage: node tools/index.mjs <tokens.json> [webOutDir] [flutterOutDir]');
  process.exit(1);
}

const tokens = readTokens(input);
generateNext(tokens, targetNext, input);
// generateFlutter(tokens, targetFlutter, input);

console.log('✅ All artifacts generated.');

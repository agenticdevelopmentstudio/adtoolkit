// Measures how time and memory grow with input length, one length per
// process so each peak is its own.
//
//   node scaling.js <bundle dir> [tokens ...]
//
// The default lengths are 128, 256, 512, 1024, 2048 and 4096 tokens.

import { execFileSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

import { loadEmbedder } from './embedder.js';

const [dir, ...rest] = process.argv.slice(2);
if (!dir) {
  console.error('usage: node scaling.js <bundle dir> [tokens ...]');
  process.exit(64);
}

if (process.env.SCALING_TOKENS) {
  const target = Number(process.env.SCALING_TOKENS);
  const embedder = await loadEmbedder(dir, { verify: false });
  const loaded = process.memoryUsage().rss;
  let text = '';
  while (embedder.tokenize(embedder.documentText(text)).length < target) text += 'The quick brown fox jumps over the lazy dog. ';
  // The first run at a new length pays for planning, so it is a warm-up, and
  // the time is the median of the three after it.
  await embedder.embedDocument(text);
  const times = [];
  for (let i = 0; i < 3; i++) {
    const started = performance.now();
    await embedder.embedDocument(text);
    times.push(performance.now() - started);
  }
  const ms = times.sort((a, b) => a - b)[1];
  const peak = Math.max(loaded, process.memoryUsage().rss);
  console.log(JSON.stringify({ tokens: embedder.tokenize(embedder.documentText(text)).length, ms: Math.round(ms), loaded_mb: Math.round(loaded / 2 ** 20), peak_mb: Math.round(peak / 2 ** 20) }));
} else {
  const lengths = rest.length ? rest.map(Number) : [128, 256, 512, 1024, 2048, 4096];
  console.log('tokens        ms   loaded MB   peak MB');
  for (const n of lengths) {
    const out = execFileSync(process.execPath, [fileURLToPath(import.meta.url), dir], { env: { ...process.env, SCALING_TOKENS: String(n) }, encoding: 'utf8' });
    const r = JSON.parse(out);
    console.log(`${String(r.tokens).padStart(6)}  ${String(r.ms).padStart(8)}  ${String(r.loaded_mb).padStart(10)}  ${String(r.peak_mb).padStart(8)}`);
  }
}

// Checks the Node embedder against a bundle's golden set.
//
//   node parity.js <bundle dir> [--json <report path>]
//
// For every golden case it checks that the embedder builds the same prefixed
// text, gives the same token IDs, and gives a vector whose cosine against the
// golden one clears the bundle's floor. It prints a line per case and a
// summary, writes the measurements as JSON when asked, and exits 1 on any
// failure.

import { readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { parseArgs } from 'node:util';

import { loadEmbedder } from './embedder.js';

function cosine(a, b) {
  let dot = 0;
  for (let i = 0; i < a.length; i++) dot += a[i] * b[i];
  return dot;
}

function sameIds(a, b) {
  return a.length === b.length && a.every((v, i) => v === b[i]);
}

const mb = (bytes) => Math.round(bytes / 2 ** 20);

async function main() {
  const { values, positionals } = parseArgs({ allowPositionals: true, options: { json: { type: 'string' } } });
  const dir = positionals[0] ?? process.env.EMBEDDING_BUNDLE;
  if (!dir) {
    console.error('usage: node parity.js <bundle dir> [--json <report path>]  (or set EMBEDDING_BUNDLE)');
    return 64;
  }

  const golden = JSON.parse(await readFile(path.join(dir, 'golden.json'), 'utf8'));
  const rssBefore = process.memoryUsage().rss;
  let started = performance.now();
  const embedder = await loadEmbedder(dir);
  const loadMs = performance.now() - started;
  const rssLoaded = process.memoryUsage().rss;

  if (golden.model_sha256 !== embedder.manifest.files['model.onnx'].sha256) {
    console.error(`golden.json was made from model ${golden.model_sha256}, the bundle holds ${embedder.manifest.files['model.onnx'].sha256}`);
    return 1;
  }

  const cases = [];
  let rssPeak = rssLoaded;
  for (const c of golden.cases) {
    const prefixed = c.kind === 'query' ? embedder.queryText(c.text) : embedder.documentText(c.text, c.title);
    const ids = embedder.tokenize(c.prefixed);
    started = performance.now();
    const vector = await embedder.embedPrefixed(c.prefixed);
    const ms = performance.now() - started;
    rssPeak = Math.max(rssPeak, process.memoryUsage().rss);
    const result = {
      id: c.id,
      tokens: c.input_ids.length,
      prefix_ok: prefixed === c.prefixed,
      ids_ok: sameIds(ids, c.input_ids),
      cosine: cosine(vector, c.vector),
      ms: Math.round(ms * 10) / 10,
    };
    result.ok = result.prefix_ok && result.ids_ok && result.cosine >= golden.min_cosine;
    cases.push(result);
    const flags = [result.prefix_ok ? '' : 'PREFIX', result.ids_ok ? '' : 'IDS'].filter(Boolean).join(' ');
    console.log(`${result.ok ? 'ok  ' : 'FAIL'}  ${result.cosine.toFixed(6)}  ${String(result.tokens).padStart(5)} tok  ${result.ms.toFixed(1).padStart(8)} ms  ${c.id}${flags ? `  ${flags}` : ''}`);
  }

  const short = cases.filter((c) => c.tokens <= 64).map((c) => c.ms).sort((a, b) => a - b);
  const report = {
    runtime: `node ${process.version}, onnxruntime-node, @huggingface/tokenizers`,
    platform: `${process.platform} ${process.arch}`,
    bundle: golden.name,
    model_sha256: golden.model_sha256,
    min_cosine: golden.min_cosine,
    load_ms: Math.round(loadMs),
    rss_mb: { before: mb(rssBefore), loaded: mb(rssLoaded), peak: mb(rssPeak) },
    short_text_median_ms: short[Math.floor(short.length / 2)],
    worst_cosine: Math.min(...cases.map((c) => c.cosine)),
    failures: cases.filter((c) => !c.ok).map((c) => c.id),
    cases,
  };
  console.log(
    `\n${cases.length - report.failures.length}/${cases.length} pass, worst cosine ${report.worst_cosine.toFixed(6)} (floor ${golden.min_cosine}), ` +
      `load ${report.load_ms} ms, short-text median ${report.short_text_median_ms} ms, rss ${report.rss_mb.loaded} MB loaded / ${report.rss_mb.peak} MB peak`,
  );
  if (values.json) await writeFile(values.json, `${JSON.stringify(report, null, 2)}\n`);
  return report.failures.length ? 1 : 0;
}

process.exitCode = await main();

// Turns text into a semantic search vector from a model bundle built by
// symanticsearchmodel. It reads everything model-specific from the bundle's
// manifest, so swapping the model means swapping the bundle, not this file.
// It is written to move into the backend unchanged.

import { createHash } from 'node:crypto';
import { createReadStream } from 'node:fs';
import { readFile } from 'node:fs/promises';
import path from 'node:path';

import { Tokenizer } from '@huggingface/tokenizers';
import ort from 'onnxruntime-node';

async function sha256(file) {
  const hash = createHash('sha256');
  for await (const chunk of createReadStream(file)) hash.update(chunk);
  return hash.digest('hex');
}

// Fails unless every file the manifest lists is present with its recorded
// hash. A bundle checked out without git LFS holds pointer files instead, and
// this is where that shows up.
export async function verifyBundle(dir, manifest) {
  for (const [name, { sha256: expected }] of Object.entries(manifest.files)) {
    const actual = await sha256(path.join(dir, name));
    if (actual !== expected) {
      throw new Error(`${name} in ${dir} has sha256 ${actual}, the manifest says ${expected}`);
    }
  }
}

function truncate(vector, dims) {
  const cut = vector.slice(0, dims);
  let norm = 0;
  for (const v of cut) norm += v * v;
  norm = Math.sqrt(norm);
  return cut.map((v) => v / norm);
}

export async function loadEmbedder(dir, { verify = true } = {}) {
  const manifest = JSON.parse(await readFile(path.join(dir, 'manifest.json'), 'utf8'));
  if (manifest.max_tokens !== null) {
    throw new Error(`${dir}: this embedder cuts nothing, and the manifest asks for max_tokens ${manifest.max_tokens}`);
  }
  if (verify) await verifyBundle(dir, manifest);

  const tokenizer = new Tokenizer(JSON.parse(await readFile(path.join(dir, 'tokenizer.json'), 'utf8')), {});
  const session = await ort.InferenceSession.create(path.join(dir, 'model.onnx'), {
    executionProviders: ['cpu'],
    graphOptimizationLevel: 'all',
  });
  const { prefixes, truncate_dims: dims, output } = manifest;

  function tokenize(prefixed) {
    return tokenizer.encode(prefixed).ids;
  }

  async function embedPrefixed(prefixed) {
    const ids = tokenize(prefixed);
    const shape = [1, ids.length];
    const result = await session.run({
      input_ids: new ort.Tensor('int64', BigInt64Array.from(ids, BigInt), shape),
      attention_mask: new ort.Tensor('int64', new BigInt64Array(ids.length).fill(1n), shape),
    });
    return truncate(Array.from(result[output].data), dims);
  }

  const queryText = (text) => prefixes.query + text;
  const documentText = (text, title = null) =>
    title === null ? prefixes.document_untitled + text : prefixes.document.replace('{title}', () => title) + text;

  return {
    manifest,
    dims,
    tokenize,
    embedPrefixed,
    queryText,
    documentText,
    embedQuery: (text) => embedPrefixed(queryText(text)),
    embedDocument: (text, title = null) => embedPrefixed(documentText(text, title)),
  };
}

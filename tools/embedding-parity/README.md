# embedding-parity

Checks that every platform turns text into the same semantic search vector.
Each runtime here loads a model bundle built by `symanticsearchmodel`. It is
then checked against the bundle's `golden.json`: for every case the prefixed
text must match, the token IDs must be identical, and the cosine against the
golden vector must clear the bundle's `min_cosine`.

The bundle is a directory such as
`symanticsearchmodel/models/embeddinggemma-2`, checked out with git LFS. Every
runtime checks the sha256 of each file against the manifest before it loads
anything, so a checkout holding LFS pointer files fails straight away.

## Node

`node/embedder.js` is the reference embedder, built on `onnxruntime-node` and
`@huggingface/tokenizers`. It is written so it can move into the backend
unchanged.

```
pnpm --dir node install
node node/parity.js <bundle dir> [--json report.json]
node node/scaling.js <bundle dir> [tokens ...]
```

`scaling.js` measures time and peak memory at a range of input lengths, one
process per length.

## Swift, macOS and iOS

`swift/` is a Swift package built on `onnxruntime-swift-package-manager` and the
`Tokenizers` library from `swift-transformers`.

```
EMBEDDING_BUNDLE=<bundle dir> swift test -c release --package-path swift
```

In the iOS simulator, run from `swift/`:

```
TEST_RUNNER_EMBEDDING_BUNDLE=<bundle dir> xcodebuild test -scheme EmbeddingParity \
    -destination 'platform=iOS Simulator,name=iPhone 18 Pro' -configuration Release
```

Set `EMBEDDING_PARITY_REPORT` (with the `TEST_RUNNER_` prefix under xcodebuild)
to write the measurements as JSON.

## The tokenizer option

`tokenizer_option.py` tests whether onnxruntime-extensions can build the
tokenizer into an ONNX graph, so that every platform would run the same
tokenizer code. For EmbeddingGemma 2 it cannot: onnxruntime-extensions 0.15.2
refuses `GemmaTokenizer`. Each platform therefore loads the bundle's
`tokenizer.json`, and the golden token IDs are the check that they agree.

The results and what they mean for the plan are recorded in the planning
repo, beside the semantic search plan.

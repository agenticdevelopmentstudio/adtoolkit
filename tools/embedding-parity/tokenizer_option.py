"""Check whether onnxruntime-extensions can put a bundle's tokenizer inside an ONNX graph.

The parity plan's first choice was an in-graph tokenizer, so every platform
runs the same tokenizer code. This tries to generate one from the bundle's
tokenizer files and, if that works, compares its token IDs with the golden set.

    uv run --with onnxruntime-extensions --with onnx --with transformers --with sentencepiece \\
        --with protobuf --with onnxruntime python tokenizer_option.py <bundle dir>

It prints what happened and exits 0 whether or not the option is viable; the
answer is the report, not the exit code.
"""
from __future__ import annotations

import json
import sys
import traceback
from pathlib import Path


def main(bundle: Path) -> int:
    import onnxruntime_extensions as ortx
    from transformers import AutoTokenizer

    print(f"onnxruntime-extensions {ortx.__version__}")
    golden = json.loads((bundle / "golden.json").read_text())
    tok = AutoTokenizer.from_pretrained(str(bundle))
    print(f"transformers loads it as {type(tok).__name__}")

    try:
        pre, _ = ortx.gen_processing_models(tok, pre_kwargs={})
    except Exception as e:  # noqa: BLE001 - the failure is the finding
        print(f"gen_processing_models refused it: {type(e).__name__}: {e}")
        traceback.print_exc(limit=3)
        return 0

    import numpy as np
    import onnxruntime as ort

    opts = ort.SessionOptions()
    opts.register_custom_ops_library(ortx.get_library_path())
    session = ort.InferenceSession(pre.SerializeToString(), opts, providers=["CPUExecutionProvider"])
    name = session.get_inputs()[0].name
    same = 0
    for case in golden["cases"]:
        ids = session.run(None, {name: np.array([case["prefixed"]])})[0].reshape(-1).tolist()
        ok = ids == case["input_ids"]
        same += ok
        if not ok:
            print(f"  differs: {case['id']}\n    graph  {ids[:24]}\n    golden {case['input_ids'][:24]}")
    print(f"in-graph tokenizer: {same}/{len(golden['cases'])} cases give the golden token IDs")
    return 0


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(__doc__, file=sys.stderr)
        sys.exit(64)
    sys.exit(main(Path(sys.argv[1])))

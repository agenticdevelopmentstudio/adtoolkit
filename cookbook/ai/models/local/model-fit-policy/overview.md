
This is a toolkit-level policy for whether a local ("loopback") model should
run on the current machine. Per the source's own doc comment, it is "a pure
function from (model size, machine RAM, thresholds, pressure) to a
tier/verdict," kept at a shared level so every host in this family shares one
representation: an inference guard enforces with it before dispatching a
chat request to a local model server, and a model chooser labels candidate
models with it via its picker-label and fit-info computations — "so the two
cannot drift." This policy holds no mutable state of its own and performs no
I/O; it is exposed purely as constants and pure functions, and there is no
way to construct an instance of it.


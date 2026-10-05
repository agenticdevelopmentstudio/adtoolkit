
Four small, immutable value shapes together form the input contract passed
into a plugin's request-building step for one chat turn: the chat message
(one turn of conversation history), the tool specification (one tool the
model may call), the plugin configuration (the plugin's resolved,
ready-to-use configuration values), and the chat context itself (the
conversation, model, limits, tools, and configuration bundled for a single
request). None of the four performs I/O, validation beyond what its own
field constraints express, or any side effect — they are pure data carried
from the host into the request-building step, which turns them into a
description of the outgoing request (an HTTP call or a subprocess
invocation). This contract has no logic of its own: it is the shape of the
data, not an implementation of it.


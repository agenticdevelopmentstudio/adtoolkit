
The stream event type defines the shape of one event in an assistant
response stream, and the decoder role defines the interface that produces a
sequence of them from a provider's raw bytes. A plugin's request-building
operation describes the outgoing request; a fresh decoder it creates via its
decoder-construction operation then turns whatever bytes the host's
transport receives into stream events, which the host renders. Neither type
performs I/O itself — decoding only transforms bytes already in hand into a
typed event sequence.


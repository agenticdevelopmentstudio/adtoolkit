
Status server is an HTTP API built on OpenAPIHono that provides real-time and historical monitoring of deployment and service health. It maintains a periodic monitoring loop via a scheduler with deadlock prevention, caches expensive status computations to prevent thundering herd on the public endpoint, and gates authenticated endpoints behind an auth middleware seam. The server is designed to run as a long-lived backend process with health-check observability.


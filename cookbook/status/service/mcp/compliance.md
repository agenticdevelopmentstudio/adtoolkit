
| Check | Status | Category |
|-------|--------|----------|
| [server-side-authorization](agenticdevelopercookbook://compliance/security#server-side-authorization) | passed | Security |
| [input-sanitization](agenticdevelopercookbook://compliance/security#input-sanitization) | passed | Security |
| [secure-log-output](agenticdevelopercookbook://compliance/security#secure-log-output) | passed | Security |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |
| [explicit-error-handling](agenticdevelopercookbook://compliance/best-practices#explicit-error-handling) | partial | Best Practices |

`server-side-authorization` passes: both fail-closed layers
(`mcp-registers-tier-set-only`, `mcp-handler-recheck`) resolve tier
entirely server-side from `c.get('tier')`, upstream of these three files;
no tool trusts a client-supplied role or tier value. `input-sanitization`
passes: every write tool's argument is parsed through its zod schema
before reaching a store call, and no tool interpolates a string argument
into a query, shell command, or rendered markup — arguments flow only into
typed store-function parameters. `secure-log-output` passes trivially — per
Logging, there is no log output in these three files to leak anything
into. `separation-of-concerns` passes: `route.ts` owns transport mounting
and the DNS-rebinding/host-allowlist concern, `server.ts` owns server
construction and the fail-closed authorization gate, and `tools.ts` owns
the tool catalog and its REST-parity delegation, with every actual
store/service operation living in files outside this recipe entirely.
`unit-test-coverage` passes: `mcp.int.test.ts` exercises the transport's
auth boundary, tier-based tool visibility, the success/failure envelope,
and both fail-closed refusal shapes; `mcp-deploy-tools.int.test.ts` covers
the deploy-project re-verification fix; `board-route.test.ts`'s MCP
`describe` block covers `get_problems`/`get_issue` parity with `GET /board`,
including the Task-14 stale-ledger regression. `explicit-error-handling` is
`partial`: every thrown `execute()` error is caught and converted to a
typed `execution_error` envelope, never silently swallowed — but a
malformed JSON `POST` body is caught and discarded
(`.catch(() => undefined)`) with no signal distinguishing it from a
bodyless `GET`/`DELETE` request, so that one specific failure mode
produces no error of its own at this layer (see Edge Cases).


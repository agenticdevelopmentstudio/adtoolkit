
- **Data collected**: nothing new — every tool reads or writes data the
  REST API already collects through the same `Storage` port. The data in
  scope that these three files specifically handle: a peer's `token`
  (`list_peers`, `add_peer` — always redacted to `hasToken` before
  returning, per `list-peers-redacts-token`/`add-peer-redacts-result`), the
  user roster (`list_users`, `update_user` — "no secrets" per its
  description), and site/group/platform configuration (the `adminOnly`
  reads and the create/update/delete write tools).
- **Storage**: none of these three files writes to persistent storage
  directly — every mutation goes through the `Storage` port's
  `config`/`auth` namespaces, whose implementation (table layout, hashing)
  is external and not specified here.
- **Transmission**: a tool's result crosses back to the MCP client inside
  the JSON text envelope (`ok`/`fail`) over the same Streamable-HTTP
  connection the request arrived on; these three files add no separate
  transmission channel. `run_auto_configure`/`configure_telemetry` are the
  only tools that cause outbound network calls (to configured deploy/error/analytics
  providers), and those calls carry platform credentials from
  `config.credentials`/`config.secrets`, never the caller's own MCP bearer
  (`no-caller-token-passthrough`).
- **Retention**: these three files set no retention policy of their own;
  `delete_site`/`delete_group`/`delete_platform`/`remove_peer` delete rows
  immediately through the `Storage` port, and the board-ledger sweep
  (`delete-tools-reconcile-board`) closes derived issues in the same call
  rather than leaving them to expire later.


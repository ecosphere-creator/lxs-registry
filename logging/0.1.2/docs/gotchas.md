# gotchas

- **One VictoriaLogs per host, not per estate.** The `server` role is
  `scope: host` — never compose more than one `server` instance per machine,
  or ports collide (default `9428`) and storage fragments. Agents are
  per-estate/per-CT; the server is shared.
- **`_stream` must be the string form `{service="<name>"}`** in each pushed
  line — VictoriaLogs parses it into the indexed stream. Sending a bare
  `service` field (without `_stream`) leaves the log with an empty stream and
  `_stream:{service=...}` queries return nothing.
- **NDJSON lines must end with `\n`.** `victoria-logs` silently drops a final
  line without a trailing newline on `/insert/jsonline`. The agent always
  terminates batches with `\n`.
- **journald-only on Linux.** The agent's `journald` source shells out to
  `journalctl -f -o json`; it needs the `systemd` binary on the CT. In dev on
  macOS use `LOG_SOURCE=stdin` or `fifo:` (there is no journald).
- **Version drift:** the VictoriaLogs download URL embeds the release tag
  (`VICTORIA_VERSION`, default `v1.93.0`). VictoriaMetrics ship victoria-logs
  in their combined releases — the tag is NOT the same as the docs "quickstart"
  version string. If a download 404s, check the release assets for the exact
  `victoria-logs-{os}-{arch}-{tag}.tar.gz` name.
- **First start needs network** to fetch the victoria-logs binary; subsequent
  starts are offline (cached in `VICTORIA_BIN_DIR`).
- **Raw non-NDJSON lines still flow** (wrapped as `info`) so the pipeline never
  loses data while services migrate to the contract.

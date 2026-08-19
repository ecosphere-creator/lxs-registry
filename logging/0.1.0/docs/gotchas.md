# logging — gotchas

- **Run exactly one `server` per machine.** It binds one port and owns one data
  dir. Multiple instances on one host collide on the port / double-provision the
  download. Agents (one per estate/CT) are the per-estate part — the server is
  shared (scope: host).
- **First `server` start downloads ~15MB** from GitHub; requires outbound https.
  Subsequent starts use the cached binary.
- The download cache key is the version; bump `VICTORIA_VERSION` to upgrade.
  Data dir is version-independent (VictoriaLogs migrates its own storage).
- **Agent on a CT reads journald of that CT only.** To see all estates, run one
  agent per CT (each estate's services log into its own CT's journald). The
  stream label is taken from the source systemd unit (`eco-<estate>-<svc>.service`),
  so one agent can forward many services with distinct `service` labels.
- **`_time` is taken from `ts`/`timestamp`** in the NDJSON line, falling back to
  the journald realtime timestamp, then agent receive-time. Keep `ts` in UTC
  (ISO8601 with `Z`) — VictoriaLogs expects an absolute timestamp.
- **Level is a log field, not a stream label** — query it with `level:error`,
  not `level="error"`. Service is the stream label — query with
  `_stream:{service="..."}`, not `service="..."`.
- **High-cardinality warning:** each distinct `service` value creates a stream.
  Keep service values bounded (estate/service names, not request ids).
- Empty `level` or missing `service` falls back to `info` / `STREAM`/`SERVICE`
  env; set `STREAM` explicitly for stdin/FIFO (dev) mode.

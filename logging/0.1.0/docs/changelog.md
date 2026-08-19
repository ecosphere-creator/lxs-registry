# changelog

## 0.1.0 (2026-08-19)

Initial release.

- `MODE=server`: provisions + supervises VictoriaLogs (v1.93.0), downloads the
  binary on first start, health-gated readiness. Scope: host (one per machine).
- `MODE=agent`: tails NDJSON from journald (Linux) or stdin/FIFO (dev),
  normalizes to the VictoriaLogs contract (`_time`, `_msg`, `level`, `service`
  stream label), batches and pushes to `/insert/jsonline?_stream_fields=service`
  with backoff.
- Accepts the mandatory LXS NDJSON log contract; raw non-JSON lines are wrapped
  and ingested as `info`.
- Stream filter query: `_stream:{service="<name>"}`; log-field filter e.g.
  `level:error`.

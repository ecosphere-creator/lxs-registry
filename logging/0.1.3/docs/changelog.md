# changelog

## 0.1.3 (2026-08-19)

- agent: convert journald `__REALTIME_TIMESTAMP` (unix microseconds) and other
  numeric timestamps to RFC3339 — VictoriaLogs rejected numeric epoch `_time`
  (silently, HTTP 200 but the line was dropped).
- agent: keep `_stream_fields=service` on the insert URL so the `_stream`
  string parses into an indexed stream (without it the stream came back empty).

## 0.1.2 (2026-08-19)

- agent: decode journald `MESSAGE` byte-arrays and strip ANSI escape codes so
  structured fields (`level`, `request_id`, ...) parse cleanly from traced
  services instead of being wrapped as raw journald JSON.

## 0.1.1 (2026-08-19)

- Built artifacts for linux/amd64 + darwin/arm64; registry packaging fixes.

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

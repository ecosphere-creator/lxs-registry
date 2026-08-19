# changelog

## 1.0.1 (2026-08-19)

- server: stream binary downloads to disk instead of buffering in RAM (Grafana
  is ~428MB); find the grafana binary when the tarball carries a top-level
  `grafana-<ver>/` directory (was failing → endless re-download loop).
- server: depend on system `unzip` for Loki's zip (documented in gotchas).

## 1.0.0 (2026-08-19)

**Breaking: replaced VictoriaLogs with Grafana + Loki.**

- `server` now provisions and supervises **Loki** (v3.7.6, engine) + **Grafana**
  (v13.2.0, UI) wired together (Grafana datasource → Loki), instead of
  VictoriaLogs. Ports: Loki `3100`, Grafana `3000` (env `LOKI_PORT` /
  `GRAFANA_PORT`, `LOG_DATA_DIR`).
- `agent` now pushes to **Loki `/loki/api/v1/push`** (stream label `service`)
  instead of VictoriaLogs `/insert/jsonline`. Env `VICTORIA_URL` →
  **`LOKI_URL`** (default `http://127.0.0.1:3100`).
- Rationale: VictoriaLogs v1.93.0 ARM64 builds (darwin/linux) silently drop
  jsonline inserts (HTTP 200, nothing written) — an upstream bug. Loki works
  on arm64 (M1) and amd64 alike. Grafana is the standard log UI.
- Structured fields stay in the log content (NDJSON); extract in LogQL with
  `| json` and use Grafana Explore / live tail.

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

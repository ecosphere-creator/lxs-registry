# logging LXS — API

## Modes (env `MODE`, or argv `[1]`)

### `MODE=server` — run Loki + Grafana (scope: host)

| Env | Default | Meaning |
|---|---|---|
| `LOKI_PORT` | `3100` | Loki HTTP port |
| `GRAFANA_PORT` | `3000` | Grafana HTTP port |
| `BIND` | `0.0.0.0` | Listen address |
| `LOG_DATA_DIR` | `~/.eco/logging` | binaries, data, provisioning |

On first start the server downloads Loki (GitHub, zip) and Grafana
(dl.grafana.com, tar.gz), caches them, writes a minimal Loki config +
Grafana datasource provisioning (Loki → 127.0.0.1:LokiPort), spawns both and
reports ready once Loki `/ready` and Grafana `/api/health` pass.

### `MODE=agent` — forward NDJSON logs to Loki

| Env | Default | Meaning |
|---|---|---|
| `LOKI_URL` | `http://127.0.0.1:3100` | target Loki base URL |
| `LOG_SOURCE` | `journald` (linux) / `stdin` (other) | `journald` \| `stdin` \| `fifo:<path>` |
| `STREAM` | `SERVICE` env, else `unknown` | stream name when the line has no `service` |

Per line, the agent derives `service` (from `_SYSTEMD_UNIT`, the `service`
field, or `STREAM`), the timestamp (journald `__REALTIME_TIMESTAMP` µs → ns,
or the `ts` field → ns), and the content (ANSI-stripped message). Batches up to
512 lines or 3s grouped by service and POSTs to `LOKI_URL/loki/api/v1/push`
(`{"streams":[{"stream":{"service":...},"values":[[ns,line],...]}]}`), retries
with backoff, trims beyond 10k buffered lines.

## Endpoints exposed

- Loki: `GET /ready`, `POST /loki/api/v1/push`, `GET /loki/api/v1/query_range`
- Grafana: `GET /api/health`, `GET /explore` (Loki datasource, `| json` parsing)

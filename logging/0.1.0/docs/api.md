# logging LXS — API

## Modes (env `MODE`, or argv `[1]`)

### `MODE=server` — run VictoriaLogs (scope: host)

| Env | Default | Meaning |
|---|---|---|
| `PORT` | `9428` | VictoriaLogs HTTP port |
| `BIND` | `0.0.0.0` | Listen address |
| `VICTORIA_VERSION` | `v1.93.0` | victoria-logs release to fetch |
| `VICTORIA_BIN_DIR` | `~/.eco/victoria-logs` | binary cache dir |
| `VICTORIA_DATA_DIR` | `~/.eco/victoria-logs-data` | log storage dir |

On first start the server downloads `victoria-logs-{os}-{arch}-{version}.tar.gz`
from the VictoriaMetrics GitHub releases and caches it. It then spawns
`victoria-logs` and reports ready once `/health` returns 200.

### `MODE=agent` — forward NDJSON logs to VictoriaLogs

| Env | Default | Meaning |
|---|---|---|
| `VICTORIA_URL` | `http://127.0.0.1:9428` | target VictoriaLogs base URL |
| `LOG_SOURCE` | `journald` (linux) / `stdin` (other) | `journald` \| `stdin` \| `fifo:<path>` |
| `STREAM` | `SERVICE` env, else `unknown` | stream name when the line has no `service` |

Batches up to 256 lines or 3s, POSTs to `/insert/jsonline?_stream_fields=service`,
retries with backoff, drops oldest beyond 10k buffered lines.

## VictoriaLogs endpoints exposed

- `GET /health`
- `POST /insert/jsonline`
- `GET /select/logsql/query`
- `GET /select/vmui` — built-in UI

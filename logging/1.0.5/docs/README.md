# logging

Observability LXS for Eco estates. Provisions **Loki** (log engine) +
**Grafana** (UI) — one instance per host (`scope: host`) — and forwards
**NDJSON logs** from services/estates into Loki, browsable in Grafana (or the
Loki API).

## Why Grafana + Loki

Replaces the original VictoriaLogs backend: VictoriaLogs v1.93.0 **ARM64
builds silently drop jsonline inserts** (HTTP 200, nothing written) — an
upstream bug that broke the M1 (dev) experience. Loki works on arm64 and amd64
alike, and Grafana is the standard log UI (Explore + live tail).

## Two roles, one binary

`MODE` env (or first argv) selects the role:

- **`server`** — provisions and runs **Loki** (v3.7.6, single-binary) +
  **Grafana** (v13.2.0), downloads both on first start (cached), wires Grafana
  to Loki via a provisioned datasource, supervises both. **Exactly one per
  machine** (the monitoring CT in prod, the dev machine locally). Ports: Loki
  `3100`, Grafana `3000`.
- **`agent`** — tails logs and pushes them to Loki:
  - Linux: reads `journalctl -f -o json` (the whole CT's services).
  - Dev: reads stdin or a FIFO (`LOG_SOURCE=fifo:/path`).
  - Derives the stream label `service` (from `_SYSTEMD_UNIT`, the `service`
    field, or `STREAM`/`SERVICE` env), normalizes the line (ANSI strip,
    journald byte-array decode), and POSTs batches to
    `LOKI_URL/loki/api/v1/push`.

## Env

| Var | Default | Role |
|---|---|---|
| `MODE` | `server` | `server` \| `agent` |
| `LOKI_PORT` | `3100` | Loki listen port (server) |
| `GRAFANA_PORT` | `3000` | Grafana listen port (server) |
| `BIND` | `0.0.0.0` | listen addr (server) |
| `LOG_DATA_DIR` | `~/.eco/logging` | binaries + data (server) |
| `LOKI_URL` | `http://127.0.0.1:3100` | push target (agent) |
| `LOG_SOURCE` | `journald` (linux) / `stdin` | `journald` \| `stdin` \| `fifo:<path>` |
| `STREAM` / `SERVICE` | `unknown` | default stream label for non-journald sources |

## Compose

```yaml
# ecompose.yml — per estate: the agent
services:
  logging-agent:
    lxs: logging@1.0.1
    env:
      MODE: agent
      LOKI_URL: http://<monitoring-host>:3100

# one host-level `server` instance lives on the monitoring CT / dev machine:
#   MODE=server logging   → Grafana at :3000, Loki at :3100
```

## Querying

Grafana → Explore → Loki (datasource auto-provisioned). Logs are NDJSON in the
message; use the LogQL `| json` parser to expose structured fields:

```logql
{service="eco-assessment-email-manager-backend.service"} | json
{service=~"eco-assessment.*"} |= "ERROR" | json
```

Raw Loki API:

```bash
curl 'http://<host>:3100/loki/api/v1/query_range?query={service="assessment"}&limit=50'
```

Open `http://<host>:3000` for Grafana (admin/admin; anonymous access enabled).

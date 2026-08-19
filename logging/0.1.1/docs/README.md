# logging

Observability LXS for Eco estates. Provisions **VictoriaLogs** (one instance
per host — `scope: host`) and forwards **NDJSON logs** from services/estates
into it, queryable from VictoriaLogs' UI or Grafana.

## Why

Eco's contract requires every LXS to emit newline-delimited JSON to stdout
(see the NDJSON logging contract). The `logging` LXS turns that contract into
observability: plug it into an estate and its service logs immediately flow
into a VictoriaLogs you can query — in dev (localhost) and in prod (host).

## Two roles, one binary

`MODE` env (or first argv) selects the role:

- **`server`** — provisions and runs VictoriaLogs. Downloads the
  `victoria-logs` binary (GitHub releases) on first start and caches it,
  then supervises the process. **Exactly one per machine** (the monitoring
  CT in prod, the dev machine locally). Port `9428` by default.
- **`agent`** — tails logs and pushes them to a VictoriaLogs URL:
  - Linux: reads `journalctl -f -o json` (the whole CT's services).
  - Dev: reads stdin or a FIFO (`LOG_SOURCE=fifo:/path`).
  - Normalizes every line to the contract and labels the stream
    `{service="<name>"}` (from `_SYSTEMD_UNIT`, `service` field, or
    `STREAM`/`SERVICE` env), then POSTs NDJSON batches to
    `VICTORIA_URL/insert/jsonline`.

## Env

| Var | Default | Role |
|---|---|---|
| `MODE` | `server` | `server` \| `agent` |
| `PORT` | `9428` | VictoriaLogs listen port (server) |
| `BIND` | `0.0.0.0` | VictoriaLogs bind addr (server) |
| `VICTORIA_VERSION` | `v1.93.0` | victoria-logs release tag |
| `VICTORIA_BIN_DIR` | `~/.eco/victoria-logs` | binary cache |
| `VICTORIA_DATA_DIR` | `~/.eco/victoria-logs-data` | log storage |
| `VICTORIA_URL` | `http://127.0.0.1:9428` | push target (agent) |
| `LOG_SOURCE` | `journald` (linux) / `stdin` | `journald` \| `stdin` \| `fifo:<path>` |
| `STREAM` / `SERVICE` | `unknown` | default stream label for non-journald sources |

## Compose

```yaml
# ecompose.yml — per estate: the agent
services:
  logging-agent:
    lxs: logging@0.1.0
    env:
      MODE: agent
      VICTORIA_URL: http://<monitoring-host>:9428

# one host-level `server` instance lives on the monitoring CT / dev machine:
#   MODE=server logging
```

## Querying

```bash
curl 'http://<host>:9428/select/logsql/query?query=_stream:{service="assessment"}&limit=50'
curl 'http://<host>:9428/select/logsql/query?query=level:"error"&limit=50'
```

Open `http://<host>:9428/select/vmui` for the VictoriaLogs UI (live tail).

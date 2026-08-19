# logging LXS

Eco observability LXS. One binary, two roles:

- **server** (`MODE=server`) — provisions and runs **VictoriaLogs** (downloads the
  binary on first start, then supervises it). **Scope: host** — run exactly one
  per machine (dev machine locally, monitoring CT in prod).
- **agent** (`MODE=agent`) — tails NDJSON logs (journald on Linux, stdin/FIFO in
  dev), normalizes them to the VictoriaLogs contract, and pushes them.

## Quick start (dev)

```bash
# 1. Start a local VictoriaLogs (one per machine)
MODE=server PORT=9428 ./logging

# 2. Pipe any NDJSON logs through the agent
printf '%s\n' \
  '{"ts":"2026-08-19T09:00:00Z","level":"info","msg":"hello","service":"myapp"}' \
  | MODE=agent STREAM=myapp VICTORIA_URL=http://127.0.0.1:9428 LOG_SOURCE=stdin ./logging

# 3. Query
curl 'http://127.0.0.1:9428/select/logsql/query?query=_stream:%7Bservice=%22myapp%22%7D&limit=10'
```

## The log contract

The agent accepts and normalizes **newline-delimited JSON (NDJSON)** — the
mandatory format for every LXS (see AGENTS.md, "LXS logging contract"). Required
keys: `ts` (ISO8601), `level` (`trace|debug|info|warn|error`), `msg`. Optional:
`service`, `request_id`, `status`, `latency_ms`, `user_id`, `error`. Raw
non-JSON lines are accepted too (wrapped as `info`).

Normalization to VictoriaLogs: `ts|timestamp → _time`, `msg|message → _msg`,
`level` lowercased and kept as a field, `service` → stream label, tracing's
nested `fields` flattened. Journald envelopes (Linux) are unwrapped — the stream
label is taken from the source systemd unit.

## Querying (LogsQL)

```text
_stream:{service="assessment"}            all logs of one estate/service stream
level:error                                errors (log field filter)
*                                         everything
```

Query API: `GET /select/logsql/query?query=<LogsQL>&limit=N`
VictoriaLogs UI: `http://<host>:<port>/select/vmui` (after server start).

#!/usr/bin/env bash
# logging LXS — quick examples

# 1. Run VictoriaLogs (scope: host, once per machine)
MODE=server PORT=9428 logging

# 2. Forward logs from the current CT/service (prod, journald)
MODE=agent VICTORIA_URL=http://127.0.0.1:9428 logging

# 3. Forward logs from stdin (dev / pipe a process)
MODE=agent STREAM=assessment LOG_SOURCE=stdin VICTORIA_URL=http://127.0.0.1:9428 \
  < <(your-service 2>&1)

# 4. Query
curl 'http://127.0.0.1:9428/select/logsql/query?query=_stream:{service="assessment"}&limit=20'

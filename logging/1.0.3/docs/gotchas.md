# gotchas

- **One Loki+Grafana per host, not per estate.** The `server` role is
  `scope: host` — never compose more than one `server` instance per machine,
  or ports collide (Loki `3100`, Grafana `3000`) and storage fragments. Agents
  are per-estate/per-CT; the server is shared.
- **Grafana's tarball carries a top-level `grafana-<ver>/` directory.** The
  server locates the binary underneath it. Do not assume `bin/grafana` at the
  extraction root.
- **Loki needs `unzip`** for its zip release (single binary inside). Install it
  on the host (`apt-get install -y unzip`) or ship a zip-capable host.
- **Downloads are streamed to disk** (`LOG_DATA_DIR/bin`), so first start needs
  network and disk headroom: Grafana ~430MB download / ~1.4GB extracted.
- **Loki rejects out-of-order samples** older than the newest sample in a
  stream (default `out_of_order_time_window`). Live logs arrive ~now, so this
  only affects historical replay (`journalctl -n 1000` on start) — acceptable;
  tune the Loki config if replay retention matters.
- **Structured fields live in the log content (NDJSON).** Use LogQL `| json`
  in Grafana to expose `level`/`request_id`/`status` etc. Labels are
  low-cardinality by design (`service`); do not add high-cardinality labels.
- **Raw non-NDJSON lines still flow** (wrapped as-is) so the pipeline never
  loses data while services migrate to the contract.

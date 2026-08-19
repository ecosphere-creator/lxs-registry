# Changelog

## 2.0.0 (2026-08-19)
- Logging contract: service logs now emitted as newline-delimited JSON (NDJSON) to stdout per the platform LXS logging contract (`ts`/`level`/`msg` + optional `service`,`request_id`,`status`,`latency_ms`,`user_id`,`error`). Breaking change — log output format changed.

## 1.0.1

- multi-arch artifacts: linux/amd64, linux/arm64, darwin/arm64, darwin/amd64, windows/amd64

## 1.0.0

- initial publish

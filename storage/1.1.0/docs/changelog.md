# storage changelog

## 1.0.6 — port fix (2026-08-16)
- Read `SERVER_PORT` (matching the contract) before falling back to `PORT`.
  The binary previously only read `PORT` while the LXS contract declared
  `SERVER_PORT`, so configgen's allocated port was ignored and the service
  listened on 8081.

## 1.0.5 — previous
See 1.0.5 docs.

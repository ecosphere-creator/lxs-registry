# LXS Manifest Spec (`lxs.yml`)

**LXS — Linux Service.** A versioned executable capability packaged with the
contract and runtime metadata an Estate needs to compose, run, observe, and
distribute it. An LXS is **not merely a binary** and **not merely a process**:

```
LXS
├── executable            # the compiled binary (per target architecture)
├── identity              # name, domain, publisher
├── version               # immutable semantic version
├── contract              # API, env, db, network, resources
├── configuration schema  # what the estate may configure
├── dependency metadata   # native libs / runtime requirements
├── health metadata       # readiness/liveness expectations
├── resource metadata     # memory, disk, startup
├── target architecture   # linux/amd64, linux/arm64, ...
├── provenance            # source, commit, builder, timestamp
└── signature/checksum    # integrity
```

## File layout

```yaml
# lxs.yml — one per version, at <name>/<version>/lxs.yml
name: auth                      # LXS name (the reusable capability)
domain: auth                    # the Domain this implements — Domain ≠ LXS.
                                # A Domain may have several LXS (shipping-api + shipping-worker)
version: 1.1.0                  # immutable semantic version
publisher: stuff8               # publisher identity
status: verified                # verified | unverified | deprecated | private | enterprise
license: mit
summary: "Authentication: login, register, JWT, email verification, avatars"

targets:
  - linux/amd64
  - linux/arm64

artifacts:
  linux/amd64:
    path: linux-amd64/auth
    sha256: <hex digest>
    size: <bytes>
  linux/arm64:
    path: linux-arm64/auth
    sha256: <hex digest>
    size: <bytes>

contract:
  version: 1                    # contract schema version — bump on breaking change
  api: "auth REST API"          # surface summary; future: OpenAPI ref
  env:
    required:
      - JWT_SECRET
      - MONGODB_URI
      - SERVER_PORT
    optional:
      - JWT_EXPIRATION
      - CORS_ALLOWED_ORIGINS
  db: mongodb@7                 # database it needs (or "none")
  network:
    inbound: [http]
    outbound: []                # outbound permissions required by this LXS
  resources:
    memory: "128m"              # resource profile the estate must reserve
    disk: "256m"
    startup_seconds: 5

runtime:
  base: self-contained-static   # self-contained-static | runtime-backed
  libc: musl
  dependencies: []              # native libs that must exist on the CT (e.g. onnxruntime)

provenance:
  source: git@github-kelastanpatembok:kelastanpatembok/auth.git
  commit: <sha>
  built_by: eco@0.2.0
  built_at: "2026-08-12T00:00:00Z"
  target: x86_64-unknown-linux-musl

release:
  - 1.0.0
  - 1.1.0
```

## Field rules

| Field | Required | Rule |
| --- | --- | --- |
| `name` | yes | lowercase, `[a-z0-9-]`. The capability identity. |
| `domain` | yes | the Domain this implements. Distinct from `name`. |
| `version` | yes | `MAJOR.MINOR.PATCH`. Immutable once published. |
| `publisher` | yes | identity of the authoring org/account. |
| `status` | yes | one of `verified/unverified/deprecated/private/enterprise`. |
| `targets` | yes | ≥1 `linux/<arch>` the version ships. |
| `artifacts.<arch>.sha256` | yes | integrity digest. |
| `contract.version` | yes | bumped on any breaking contract change. |
| `contract.env.required` | yes | secrets/config the estate must grant. |
| `runtime.base` | yes | `self-contained-static` (preferred) or `runtime-backed`. |
| `runtime.dependencies` | no | native libraries the host must provide (never assume). |
| `provenance` | yes | source repo + commit + builder + timestamp. |
| `release` | yes | the ordered release history of this LXS. |

## Supply-chain boundary

A composed third-party LXS must **not** implicitly get every Estate resource.
The estate grants it explicit capabilities via `ecompose.yml`:

```yaml
services:
  shipping-backend:
    lxs: shipping@2.0.1
    grants:
      secrets: [SHIPPING_API_KEY]
      network: [outbound-https]
```

`eco up` verifies the grants satisfy the contract (`contract.env.required`,
`contract.db`, `contract.network`) **before** deploying and rejects mismatches
at compose time.

## Publishing workflow

1. Cross-compile the domain for each target arch (`eco lxs build`).
2. Write `lxs.yml` with the contract + provenance + checksums
   (`eco lxs publish <name>@<version>`).
3. Commit the version directory to this repo; tag `name-version`.
4. Estates reference `name@version`; `ecompose.lock` pins the sha256.

## Registry vs Marketplace

| | Registry (this repo) | Marketplace (product layer) |
| --- | --- | --- |
| role | technical distribution | discovery + economics |
| holds | versions, artifacts, manifests, checksums, contracts | publishers, licensing, pricing, categories |
| access | git + agent-mediated pull | user-facing browse/buy |

The Marketplace is built **on** the Registry; this repo is the source of truth
for what exists and at which version.

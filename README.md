# LXS Registry

**LXS — Linux Service.** The continuation of LXC (Linux Container) / CT: where a
CT runs binaries, an **LXS is the versioned executable capability** those CTs
compose into an Estate.

> LXC · Linux **Container** → CT → run **one** estate's OS
> LXS · Linux **Service** → binary → compose **many** capabilities into an Estate

This repository is the **technical distribution layer** of the Ecosphere model:

- **Registry** (this repo) — identity, versions, artifacts, manifests, checksums,
  contracts, retrieval. *Technical.*
- **Marketplace** — discovery, publishers, licensing, pricing, purchase/access.
  *Economic layer, built on top of this registry.*

A Docker image is a filesystem layer; an LXS is a **single compiled binary** with
a contract. That binary — not source — is what estates reuse.

## Published LXS — binary → source

Each version's `lxs.yml` records the exact source repo + commit it was built
from (`provenance.source` / `provenance.commit`), so a binary is fully traceable
to its code. The source repos are public; the source tag `v<version>` matches
the published commit.

| LXS | version | status | source |
| --- | --- | --- | --- |
| `auth` | 1.0.0 | unverified | [getecosphere/auth](https://github.com/getecosphere/auth) |
| `storage` | 1.0.0 | unverified | [getecosphere/storage](https://github.com/getecosphere/storage) |
| `notifications` | 1.0.0 | unverified | [getecosphere/notifications](https://github.com/getecosphere/notifications) |
| `chat` | 1.0.0 | unverified | [getecosphere/chat](https://github.com/getecosphere/chat) |
| `email-manager` | 1.0.0 | unverified | [getecosphere/email-manager](https://github.com/getecosphere/email-manager) |
| `profile` | 1.0.0 | unverified | [getecosphere/profile](https://github.com/getecosphere/profile) |
| `articles` | 1.0.0 | unverified | [getecosphere/articles](https://github.com/getecosphere/articles) |

**Contributing:** fork a domain repo, improve it, open a PR. On merge, a
`vX.Y.Z` tag triggers CI to publish the new LXS version. See
[Contributing LXS](https://eco.stuff8.com/ecosphere/contribute).

## The canonical pipeline

```
SOURCE CODE  →  BINARY  →  LXS  →  ESTATE  →  THE WORLD
 human / AI     compile    package    compose     operate
               (author)    +contract
```

- **Author**: builds on their own machine (`eco lxs build`), packages a manifest,
  publishes an immutable version (`eco lxs publish`).
- **Estate**: `ecompose.yml` references `auth@1.1.0`; `eco up` pulls the binary
  from this registry and runs it. **No compiler, no build step, no rustc on the CT.**

## Registry layout

```
lxs-registry/
├── README.md
├── lxs-spec.md              # the lxs.yml manifest schema (canonical)
└── <name>/                  # one directory per LXS (capability)
    └── <version>/           # immutable semantic version
        ├── lxs.yml          # manifest: contract, runtime, provenance, checksums
        └── linux-<arch>/    # one artifact per target architecture
            └── <name>       # the compiled binary
```

Example:

```
auth/
└── 1.1.0/
    ├── lxs.yml
    ├── linux-amd64/auth
    └── linux-arm64/auth
```

## Versioning

- **Immutable** — a published `name@version` never changes. Fix forward, never
  mutate. Version numbers are semantic (`MAJOR.MINOR.PATCH`).
- **Release identity** — git tags `name-version` (e.g. `auth-1.1.0`) mark each
  published version.
- **Status** — an LXS version declares `status:` (`verified | unverified |
  deprecated | private | enterprise`). `verified` means it passed the platform's
  verification process — nothing is labelled verified until that process exists.
- **Contract version** — the `contract.version` is bumped on any breaking change
  to the contract, so estates can detect incompatibility before runtime.

## Publishing

An author publishes from a domain source repo (dual-mode: the same domain can
still be consumed as source via `repos.json` until the migration is complete).

```bash
cd <domain-source>
eco lxs build                      # cross-compile for the target archs
eco lxs publish auth@1.1.0         # write manifest + artifacts, checksum, tag
eco lxs verify auth@1.1.0          # verify checksums / signature
```

See [lxs-spec.md](lxs-spec.md) for the full manifest schema and
[publishing workflow](lxs-spec.md#publishing-workflow).

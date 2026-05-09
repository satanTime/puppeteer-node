# Agent Guide

This repository publishes `satantime/puppeteer-node` Docker images.
Each image follows the matching official `node:<tag>` image and adds
only the Debian packages needed to run browsers used by Puppeteer.
The images intentionally do not include Puppeteer itself.

Alpine tags are not supported.

## Repository Shape

- `build.sh` is the main production build loop.
- `docker/Dockerfile` and `docker/*/Dockerfile` are Dockerfile
  fragments. They do not contain `FROM` lines.
- `hashes/` is generated build state for Docker Hub `node` tags.
- `compose.yml` runs a local Debian package mirror and Docker registry
  proxy used by builds.
- `mirror/` contains the nginx config for the Debian package cache.
- `staging/` is a smoke-test harness for browser launches.
- `.circleci/config.yml` runs scheduled E2E smoke tests against
  already-published `satantime/puppeteer-node` tags.
- `docs/` is the GitHub Pages redirect site.

Ignored local state includes `.env`, `.url`, root `Dockerfile`,
`buildx-data/`, `mirror-data/`, `registry-data/`,
`staging/Dockerfile`, and `staging/src/node_modules/`.

Do not commit ignored generated files.

## Build Flow

`build.sh` reads Docker Hub `library/node` tags, skips `alpine` and
`onbuild`, ignores schema-v1 manifests, and gathers current manifest
digests for each supported tag.

For each tag, it detects the Debian release in this order:

1. Existing `version:<codename>` from `hashes/<tag>`.
2. The tag name itself, such as `bookworm` or `bullseye`.
3. Running `node:<tag>` and reading `/etc/os-release`.

The supported release names are:

- `trixie`
- `bookworm`
- `bullseye`
- `buster`
- `stretch`
- `jessie`
- `wheezy`

The build script chooses `docker/<release>/Dockerfile` when present
and falls back to `docker/Dockerfile` otherwise. Current `trixie` tags
use the generic fragment.

For a changed tag, `build.sh` generates a temporary root `Dockerfile`
from:

```Dockerfile
FROM node:<tag>
```

followed by the selected fragment. It builds and pushes
`satantime/puppeteer-node:<tag>`, updates `hashes/<tag>`, and commits
that one hash file as:

```text
chore(<tag>): updated
```

Existing hash files contain upstream `sha256:` digests, a
`dockerfile:<md5>` line, a `version:<codename>` line, and often a
`buildx:<digest>` cache line. `hashes/<tag>@error` files record failed
build state and force later retries.

Do not bulk-edit `hashes/`. Treat it as generated state unless the
task is explicitly about repairing build state for a specific tag.

## Dockerfile Fragments

The fragments install browser runtime dependencies with `apt` or
`apt-get`. They also rewrite Debian repository hosts to `.lo` names so
the build can use the local nginx mirror through `--add-host` entries.

The `UPDATE_REPO=""` and `SECURITY_REPO=""` placeholders in modern
fragments are replaced by `build.sh` before building. This lets the
build remove unavailable update or security repositories for old base
images.

The legacy fragments for `stretch`, `jessie`, and `wheezy` are
deliberately different. Preserve archive mirror handling, disabled
valid-until checks, pinned old packages, and `--force-yes` usage
unless the task is specifically to change old-Debian support.

Changing any Dockerfile fragment changes the `dockerfile:<md5>` value
and can trigger many tag rebuilds.

## Local Build Setup

Expected host tools:

- Docker with buildx
- `bash`
- `curl`
- `jq`
- `git`
- either `md5` or `md5sum`

The local mirror flow expects loopback alias `172.16.0.1`.

Linux:

```sh
sudo ip addr add 172.16.0.1 dev lo
```

macOS:

```sh
/sbin/ifconfig lo0 alias 172.16.0.1
```

`compose.yml` reads Docker Hub proxy credentials from `.env`:

```text
DOCKER_HUB_USERNAME=...
DOCKER_HUB_ACCESS_TOKEN=...
```

Start local services before production builds:

```sh
docker compose up -d debian registry
```

Create the buildx builder:

```sh
./init-buildx.sh
```

The builder is named `puppeteer-node` and uses
`init-buildx.toml`. That config points Docker Hub pulls at the local
registry mirror on `172.16.0.1:5000` and enables multiple Linux
platform families.

Running `./build.sh` is a real publish operation. It can push images
to Docker Hub and create many `hashes/<tag>` commits.

## Staging

The documented smoke test is:

```sh
cd staging
sh index.sh trixie-slim
```

`staging/index.sh` generates ignored `staging/Dockerfile`, appends the
generic root fragment, sets `/src` as the working directory, and makes
`staging/src/test.sh` the container command.

`staging/src/test.sh` is the shared local and CI smoke-test
entrypoint. It installs `unzip`, installs Puppeteer from
`staging/src/package.json`, downloads Chrome and Firefox browser
builds, unpacks cached browser archives, and runs
`staging/src/index.js`. The script launches both products headless
with `--no-sandbox` and prints:

```text
chrome success
firefox success
```

when the runtime dependencies are sufficient.

If a task changes a release-specific fragment, adjust staging or mimic
`build.sh` manually so the relevant fragment is actually tested.

## CircleCI

CircleCI is configured only for the scheduled `Daily` workflow. It
runs at `06:00` UTC on the `master` branch and does not define any
commit-triggered workflow.

The workflow uses a parameterized `E2E` job. Each matrix entry runs in
the matching already-published image:

```yaml
satantime/puppeteer-node:<tag>
```

The job checks out the repository, enters `staging/src`, and runs
`sh test.sh`. The current matrix covers alias tags, Debian codename
tags, and the slim tags that are published for this image family.

## Validation

For script-only changes, run syntax checks:

```sh
bash -n build.sh
bash -n init-buildx.sh
bash -n init.sh
bash -n push.sh
bash -n staging/index.sh
sh -n staging/src/test.sh
```

For Docker dependency changes, run the staging smoke test above. This
requires Docker, network access, and the local mirror alias.

For CircleCI config changes, parse `.circleci/config.yml` as YAML and
check that `workflows.Daily.jobs` contains the E2E matrix. The
CircleCI CLI can be used for full validation when available.

For production build changes, inspect generated diffs carefully
before letting `build.sh` push or commit. Prefer testing one
representative tag through staging first.

## Working Rules

- Preserve the image contract: only add browser runtime dependencies
  on top of official Debian-based Node images.
- Do not add Puppeteer itself to the published runtime images.
- Keep Alpine unsupported unless the task explicitly changes that
  policy.
- Prefer focused edits to the relevant Dockerfile fragment or script.
- Be cautious with `build.sh`; it has side effects in Docker Hub and
  Git.
- Keep the generated `hashes/` model intact.
- Follow `.editorconfig`: LF, UTF-8, two-space indentation, no
  trailing whitespace, and short wrapped Markdown lines.
- Use path-limited `git log` instead of reading the whole history when
  investigating authored code.
- Never remove old Debian compatibility paths casually; they exist for
  historical Node tags.

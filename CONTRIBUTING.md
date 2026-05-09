## Loopback alias

Linux:

```sh
ip addr add 172.16.0.1/32 dev lo label lo:1
```

macOS:

```sh
/sbin/ifconfig lo0 alias 172.16.0.1
```

## Mount

Linux:

```sh
sshfs -o allow_other root@192.168.50.83:/Volumes/TB5 /home/michael/TB5
```

## Staging

To debug and verify the current build, run:

```sh
docker compose up -d debian
cd staging
sh index.sh trixie-slim
```

The staging build uses the same Debian package mirror hostnames as the
production build fragments. Make sure the loopback alias above exists
and the root `debian` compose service is running before starting the
staging smoke test.

`staging/index.sh` generates the ignored `staging/Dockerfile` from the
requested `node:<tag>` base image and the generic Dockerfile fragment.
The generated image runs `sh test.sh` from `/src`. That script lives
in `staging/src`, installs the test dependencies, downloads Chrome and
Firefox through Puppeteer, unpacks cached browser archives, and runs
`node index.js`.

CircleCI runs the same `staging/src/test.sh` entrypoint daily at
`06:00` UTC on `master`, using already-published
`satantime/puppeteer-node:<tag>` images from the E2E matrix. Pushing a
commit does not trigger this workflow.

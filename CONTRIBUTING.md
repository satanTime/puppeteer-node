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
cd staging
sh index.sh trixie-slim
```

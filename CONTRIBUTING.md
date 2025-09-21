## lo alias

Linux
> ip addr add 172.16.0.1/32 dev lo label lo:1

Mac
> /sbin/ifconfig lo0 alias 172.16.0.1

## mount

Linux
> sshfs -o allow_other root@192.168.50.83:/Volumes/TB5 /home/michael/TB5

## staging

if you need to debug to ensure that current build works well,
use the next command:

> cd staging 
> sh index.sh trixie-slim 

#!/bin/sh
set -e

TO=/takeover
PORT=80

cd "$TO"

if [ ! -e fakeinit ]; then
    ./busybox echo "Please compile fakeinit.c first"
    exit 1
fi

./busybox echo "Please set a root password for sshd"

./busybox chroot . /bin/passwd

./busybox echo "Setting up target filesystem..."
./busybox rm -f etc/mtab
./busybox ln -s /proc/mounts etc/mtab
./busybox mkdir -p old_root

./busybox echo "Mounting pseudo-filesystems..."
./busybox mount -t tmpfs tmp tmp
./busybox mount -t proc proc proc
./busybox mount -t sysfs sys sys
if ! ./busybox mount -t devtmpfs dev dev; then
    ./busybox mount -t tmpfs dev dev
    ./busybox cp -a /dev/* dev/
    ./busybox rm -rf dev/pts
    ./busybox mkdir dev/pts
fi
./busybox mount -t devpts devpts dev/pts

TTY="$(./busybox tty)"

./busybox echo "Checking and switching TTY..."

exec <"$TO/$TTY" >"$TO/$TTY" 2>"$TO/$TTY"

./busybox echo "Type 'OK' to continue"
./busybox echo -n "> "
read a
if [ "$a" != "OK" ] ; then
    exit 1
fi

./busybox echo "Preparing init..."
./busybox cat >tmp/init <<EOF
#!${TO}/busybox sh

exec <"${TO}/${TTY}" >"${TO}/${TTY}" 2>"${TO}/${TTY}"
cd "${TO}"

./busybox echo "Init takeover successful"
./busybox echo "Pivoting root..."
./busybox pivot_root . old_root
./busybox echo "Chrooting and running init..."
exec ./busybox chroot . /fakeinit
EOF
./busybox chmod +x tmp/init

./busybox echo "Starting secondary sshd"

./busybox chroot . /usr/bin/ssh-keygen -A
./busybox chroot . /usr/sbin/sshd -p $PORT

./busybox echo "You should SSH into the secondary sshd now."
./busybox echo "Type OK to continue"
./busybox echo -n "> "
read a
if [ "$a" != "OK" ] ; then
    exit 1
fi

./busybox echo "About to take over init. This script will now pause for a few seconds."
./busybox echo "If the takeover was successful, you will see output from the new init."
./busybox echo "You may then kill the remnants of this session and any remaining"
./busybox echo "processes from your new SSH session, and umount the old root filesystem."

./busybox mount --bind tmp/init /sbin/init

telinit u

./busybox sleep 10


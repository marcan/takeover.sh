# takeover.sh

A script to completely take over a running Linux system remotely, allowing you
to log into an in-memory rescue environment, unmount the original root
filesystem, and do anything you want, all without rebooting. Replace one distro
with another without touching a physical console.

## WARNING WARNING WARNING WARNING

This is experimental. Do not use this script if you don't understand exactly
how it works. Do not use this script on any system you care about. Do not use
this script on any system you expect to be up. Do not run this script unless
you can afford to get physical access to fix a botched takeover. If anything
goes wrong, your system will most likely panic.

That said, this script will not (itself) make any permanent changes to your
existing root filesystem (assuming you run it from a tmpfs), so as long as you
can remotely reboot your box using an out-of-band mechanism, you *should* be OK.
But don't blame me if it eats your dog.

This script does not have any provisions for exiting *out* of the new
environment back into something sane. You *will* have to reboot when you're
done. If you get anything wrong, your machine won't boot. Tough luck.

This is not a guide for newbies. I'm deliberately not giving you commands you
can copy and paste. If you can't figure out what to do exactly without
handholding, this script is not for you.

## Compatibility

This script is designed for systems using sysvinit that support the `telinit u`
command to reload `/sbin/init`. If your system uses something else, you will
have to adapt it, or this might not work at all. You're on your own here.

You should always test this in a VM first. You can grab a tarball of your live
root filesystem, extract it into a VM image, get your VM up and running (boot
loader setup is left as an exercise for the reader), then try the process there
and see if it works. Hint: `mount --bind / /mnt` will get you a view of your
root filesystem on `/mnt` without any other filesystems that are mounted on top.

## Usage

You need to decide on what rescue environment you want. I recommend
[SystemRescueCD](https://www.system-rescue-cd.org/), which comes with many
useful tools (you have to loopmount the ISO and then use `unsquashfs`).
Obviously, whatever you pick has to fit into free RAM, with room to spare. If
your chosen rescue environment has `/lib/modules`, you may want to get rid of
it to save space, as its kernel modules won't be useful on the host kernel
anyway.

1. Create a directory `/takeover` on your target system and mount a tmpfs on it
2. Extract your rescue environment there. Make sure it works by chrooting into
   it and running a few commands. Make sure you do not bork filesystem
   permissions. Exit the chroot.
3. Grab a recent copy of `busybox` (statically linked) and put it in
   `/takeover/busybox`. You can find binaries
   [here](https://www.busybox.net/downloads/binaries/1.26.2-defconfig-multiarch/).
   Make sure it works by trying something like `/takeover/busybox sh`.
4. Copy the contents of this repository into `/takeover`.
5. Compile `fakeinit.c`. It must be compiled such that it works inside the
   takeover environment. If your rescue environment has `gcc`, you can just
   compile it inside the chroot: `chroot /takeover gcc /fakeinit.c -o /fakeinit`.
   Otherwise, you might want to statically link it.
6. Shut down as many services as you can on your host. `takeover.sh` will by
   default set up an SSHd listening on port 80, though you may edit this in
   the script.
7. Run `sh /takeover/takeover.sh` and follow the prompts.

If everything worked, congratulations! You may now use your new SSH session
to kill any remaining old daemons (`kill -9` is recommended to make sure they
don't try to do anything silly during shutdown), and then unmount all
filesystems under `/old_root`, including `/old_root` itself. You may want to
first copy `/old_root/lib/modules` into your new tmpfs in case you need any old
kernel modules.

You are now running entirely from RAM and should be able to do as you please.
Note that you may still have to clean up LVM volumes (`dmsetup` is your friend)
and similar before you can safely repartition your disk and install Gentoo
Linux, which is of course the whole reason you're doing this crazy thing to
begin with. 

When you're done, unmount all filesystems, then `reboot -f` or `echo b >
/proc/sysrq-trigger` and cross your fingers.

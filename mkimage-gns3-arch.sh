#!/usr/bin/env bash
# Generate a minimal filesystem for archlinux and load it into the local
# docker as "archlinux"
# requires root
set -e
SCRIPTPATH=$(readlink -f $0)
SCRIPTPATH=${SCRIPTPATH%/*}
REPOPATH=${SCRIPTPATH}/repo

hash pacstrap &>/dev/null || {
    echo "Could not find pacstrap. Run pacman -S arch-install-scripts"
    exit 1
}

hash expect &>/dev/null || {
    echo "Could not find expect. Run pacman -S expect"
    exit 1
}

ROOTFS=$(mktemp -d /tmp/rootfs-archlinux-XXXXXXXXXX)
chmod 755 $ROOTFS

# packages to ignore for space savings
PKGIGNORE=linux,jfsutils,lvm2,groff,man-db,man-pages,mdadm,pciutils,pcmciautils,reiserfsprogs,s-nail,xfsprogs
EXTRA="icu xorg-fonts-misc python-setuptools dynamips-git  gns3-gui-git  gns3-server-git  iouyap-git  vpcs-git python-apache-libcloud python-netifaces-git ws4py"
#add localrepo
cp mkimage-gns3-arch-pacman.conf.template mkimage-gns3-arch-pacman.conf
cat >> mkimage-gns3-arch-pacman.conf <<!EOF
[custom]
SigLevel = Optional TrustAll
Server = file:///${REPOPATH}
!EOF


expect <<EOF
  set timeout 60
  set send_slow {1 1}
  spawn pacstrap -C ${SCRIPTPATH}/mkimage-gns3-arch-pacman.conf -c -d -G -i $ROOTFS base haveged  $EXTRA --ignore $PKGIGNORE
  expect {
    "Install anyway?" { send n\r; exp_continue }
    "(default=all)" { send \r; exp_continue }
    "Proceed with installation?" { send "\r"; exp_continue }
    "skip the above package" {send "y\r"; exp_continue }
    "checking" { exp_continue }
    "loading" { exp_continue }
    "installing" { exp_continue }
    "Enter a number (default=1):" { send 1\r; exp_continue }
  }
EOF

arch-chroot $ROOTFS /bin/sh -c "haveged -w 1024; pacman-key --init; pkill haveged; pacman -Rs --noconfirm haveged; pacman-key --populate archlinux"
arch-chroot $ROOTFS /bin/sh -c "ln -s /usr/share/zoneinfo/UTC /etc/localtime"
echo 'en_US.UTF-8 UTF-8' > $ROOTFS/etc/locale.gen
arch-chroot $ROOTFS locale-gen
arch-chroot $ROOTFS /bin/sh -c 'echo "Server = https://mirrors.kernel.org/archlinux/\$repo/os/\$arch" > /etc/pacman.d/mirrorlist'

# udev doesn't work in containers, rebuild /dev
DEV=$ROOTFS/dev
rm -rf $DEV
mkdir -p $DEV
mknod -m 666 $DEV/null c 1 3
mknod -m 666 $DEV/zero c 1 5
mknod -m 666 $DEV/random c 1 8
mknod -m 666 $DEV/urandom c 1 9
mkdir -m 755 $DEV/pts
mkdir -m 1777 $DEV/shm
mknod -m 666 $DEV/tty c 5 0
mknod -m 600 $DEV/console c 5 1
mknod -m 666 $DEV/tty0 c 4 0
mknod -m 666 $DEV/full c 1 7
mknod -m 600 $DEV/initctl p
mknod -m 666 $DEV/ptmx c 5 2
ln -sf /proc/self/fd $DEV/fd

tar --numeric-owner -C $ROOTFS -c . | docker import - ppickfor/gns3-1.0alpha
docker run -i -t ppickfor/gns3-1.0alpha echo Success.
rm -rf $ROOTFS

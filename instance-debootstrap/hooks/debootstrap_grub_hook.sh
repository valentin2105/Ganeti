#!/bin/bash
# To use it put it in your CUSTOMIZE_DIR and make it executable.

#
# Do not include grub in EXTRA_PKGS of
# $sysconfdir/default/ganeti-instance-debootstrap because it will
# cause error of debootstrap.

set -e

. common.sh

CLEANUP=( )

trap cleanup EXIT

if [ -z "$TARGET" -o ! -d "$TARGET" ]; then
echo "Missing target directory"
exit 1
fi

# make /dev/vda
mknod $TARGET/dev/xvda b $(stat -L -c "0x%t 0x%T" $BLOCKDEV)
CLEANUP+=("rm -f $TARGET/dev/xvda")

# make /dev/vda1
mknod $TARGET/dev/xvda1 b $(stat -L -c "0x%t 0x%T" $FSYSDEV)
CLEANUP+=("rm -f $TARGET/dev/xvda1")

# create grub directory
mkdir -p "$TARGET/boot/grub"

# create device.map
cat > "$TARGET/boot/grub/device.map" <<EOF
(hd0,0) $TARGET/dev/xvda
EOF

# preconfigure debconf
chroot "$TARGET" debconf-set-selections <<EOF
grub-pc grub-pc/install_devices multiselect
grub-pc grub-pc/install_devices_empty   boolean true
EOF

# install grub
export LANG=C
if [ "$PROXY" ]; then
export http_proxy="$PROXY"
export https_proxy="$PROXY"
fi
export DEBIAN_FRONTEND=noninteractive
chroot "$TARGET" apt-get -y --force-yes install grub2

# deploy custom grub config generator
chmod -x $TARGET/etc/grub.d/*
wget -O $TARGET/etc/grub.d/40_custom https://raw.githubusercontent.com/welterde/ec2debian/master/src/root/etc/grub.d/40_custom
chmod +x $TARGET/etc/grub.d/40_custom
chroot "$TARGET" ln -s /boot/grub/grub.cfg /boot/grub/menu.lst

# execute update-grub
chroot "$TARGET" update-grub

# install kernel
chroot "$TARGET" apt-get install -y $KERNEL_IMAGE_PKG

# execute cleanups
cleanup
trap - EXIT

exit 0



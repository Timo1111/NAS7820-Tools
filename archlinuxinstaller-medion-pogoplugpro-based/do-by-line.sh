#!/bin/sh

stage1variant=750
disk=/dev/sda

echo "Mount disk to get the regular system available"
DISK_PATH="/zyxel/mnt/sysdisk"

cd /mnt/parnerkey

/bin/mkdir -p ${DISK_PATH}
IMG_PATH="/ram_bin"
/bin/mount -t ext2 -o loop,ro ${DISK_PATH}/sysdisk.img ${IMG_PATH} || exit 0

# Mount some read-only directories and make everything available for us
/bin/mount --bind ${IMG_PATH}/usr /usr
/bin/mount --bind ${IMG_PATH}/lib/security /lib/security
/bin/mount --bind ${IMG_PATH}/lib/modules /lib/modules
cp -a ${IMG_PATH}/bin/* /bin/
cp -a ${IMG_PATH}/sbin/* /sbin/

/sbin/udhcpc -i egiga0
if [ $? == 0 ]; then
    echo "OK, get IP via DHCP"
else
    echo "Error: Cannot get IP via DHCP!"
    echo "continue boot process..."
    exit 1
fi

echo "Installing Binaries to disk"
dd if=/dev/zero of=$disk bs=512 count=65536 || exit 0
echo "Writing stage1"
dd if=stage1.wrapped$stage1variant of=$disk bs=512 seek=34 || exit 0
echo "Writing uboot"
dd if=u-boot.wrapped of=$disk bs=512 seek=154 || exit 0

parted $disk -s -- mklabel msdos
parted $disk -s -- mkpart primary ext3 2048s 22527s
parted $disk -s -- mkpart primary ext3 22528s -1048577s
parted $disk -s -- mkpart primary linux-swap -1048576s -1s

dd if=uImage.nopci of="$disk"1 bs=512 || exit 0
mke2fs -j "$disk"2 || exit 0
mkdir /install || exit 0
mount "$disk"2 /install || exit 0
echo "Installing ArchLinuxARM rootfs"
cd /install
if [ ! -f /mnt/parnerkey/ArchLinuxARM-oxnas-latest.tar.gz ] ; then
    echo "Downloading ArchLinuxARM rootfs"
    wget http://archlinuxarm.org/os/ArchLinuxARM-oxnas-latest.tar.gz || exit 0
    echo "Extracting ArchLinuxARM rootfs"
    tar xvzf ArchLinuxARM-oxnas-latest.tar.gz || exit 0
    rm ArchLinuxARM-oxnas-latest.tar.gz || exit 0
else
    echo "Installing ArchLinuxARM rootfs from USB stick"
    tar xvzf /mnt/parnerkey/ArchLinuxARM-oxnas-latest.tar.gz || exit 0
fi
echo "Extracting MAC address"
/sbin/ifconfig egiga0 | grep HWaddr | awk "{ print \$5 }" >usr/local/mac_addr
echo -n "MAC address: "
cat usr/local/mac_addr
[ -f /mnt/parnerkey/rc.conf ] && {
	echo "Installing pre-setup rc.conf"
	cp /mnt/parnerkey/rc.conf etc/
}
cd /
umount "$disk"2 || exit 0
cd /mnt/parnerkey
# Restore special MBR of PLX
dd if=mbr.bin of=$disk count=444 bs=1

reboot

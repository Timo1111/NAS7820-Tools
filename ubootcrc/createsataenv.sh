#!/bin/sh

echo "Generating U-Boot Environment"
echo -en "\0\0\0\0" >uboot.env
echo -en "bootdelay=3\0" >>uboot.env
echo -en "baudrate=115200\0" >>uboot.env
echo -en "ethaddr=00:30:e0:00:00:01\0" >>uboot.env
echo -en "ipaddr=172.31.0.128\0" >>uboot.env
echo -en "serverip=172.31.0.100\0" >>uboot.env
echo -en "autoload=n\0" >>uboot.env
echo -en "netmask=255.255.0.0\0" >>uboot.env
echo -en "bootfile="uImage"\0" >>uboot.env
echo -en "select0=ide dev 0\0" >>uboot.env
echo -en "load1=ide read 0x60500000 50a 1644\0" >>uboot.env
echo -en "load2=ide read 0x60500000 e3e8 1644\0" >>uboot.env
echo -en "load_rd=ide read 0x60800000 4122 1644\0" >>uboot.env
echo -en "lightled=ledfail 1\0" >>uboot.env
echo -en "extinguishled=ledfail 0\0" >>uboot.env
echo -en "bootcmd=run select0 load1 boot || run lightled select0 load2 extinguishled boot || lightled\0" >>uboot.env
echo -en "boot=bootm 60500000\0" >>uboot.env
echo -en "stdin=serial\0" >>uboot.env
echo -en "stdout=serial\0" >>uboot.env
echo -en "stderr=serial\0" >>uboot.env
echo -en "bootargs=root=/dev/sda1 console=ttyS0,115200 elevator=cfq mem=256M  poweroutage=yes mac_adr=0x00,0xd0,0xb8,0x19,0x81,0xfb\0" >>uboot.env
echo -en "\0" >>uboot.env

if [ ! -e ./ubootcrc-8192bytes ] ; then
    echo "Compiling CRC calculation tool"
    gcc -o ubootcrc-8192bytes ubootcrc-8192bytes.c
fi
echo "Finalizing U-Boot Environment"
./ubootcrc-8192bytes <uboot.env >uboot.newenv

echo "uboot.newenv contains a valid environment for SATA disk"

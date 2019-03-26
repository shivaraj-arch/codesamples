#Notes unetbootin vs dd
#usb is a pxe uefi device always should be formatted which is recognized by BIOS. dd will not install bootloader(syslinux.cfg) which unetbootin does.

#unetbootin for creating linux based and dos based bootable usb live systems:


#liveOS for linux on a EFI based usb parition - to extract squashfs on linux into usb device (/dev/sdb) partition /dev/sdbX 
#sdbX is a usb parition and not entire usb disk (X=number shown in lsblk). If using entire disk replace it by /dev/sdb
#Make sure to toggle the bootable flag to correct partition after creating liveOS using fdisk / gparted / parted
#always be root or use sudo creating liveOS
sudo QT_X11_NO_MITSHM=1 unetbootin targetdrive=/dev/sdbX isofile=./centos.iso


#liveOS for windows on a EFI based usb stick - on linux into usb /dev/sdbX 
#1.fdisk to usb 
#2.create a dos partition table
#3.create a partition 
#4.create a filesystem mkfs.vfat /dev/sdbX: 
sudo QT_X11_NO_MITSHM=1 unetbootin-linux64-647.bin targetdrive=/dev/sdbX isofile=./ISO/Win10_1709_English_x64.iso

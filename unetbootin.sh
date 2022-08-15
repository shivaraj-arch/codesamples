#Notes unetbootin vs dd
#usb is a pxe uefi device. It should be formatted to get recognized by BIOS. 
#dd will not install bootloader(syslinux.cfg) which unetbootin does.

#unetbootin for creating linux based and dos based bootable usb live systems:

#1.linux liveOS on a EFI based usb parition - to extract squashfs on linux into usb device (/dev/sdb) partition /dev/sdbX 
#1.1 sdbX is a usb parition and not entire usb disk (X=number shown in lsblk). If using entire disk replace it by /dev/sdb
#1.2 Make sure to toggle the bootable flag to correct partition after creating liveOS using fdisk / gparted / parted
#1.3 Always be root or use sudo creating liveOS
sudo QT_X11_NO_MITSHM=1 unetbootin targetdrive=/dev/sdbX isofile=./centos.iso


#2.windows 10 liveOS on a EFI based usb stick - on linux into usb /dev/sdbX 
#2.1 fdisk usb 
#2.2 create a dos partition table
#2.3 create a partition 
#2.4 create a filesystem mkfs.vfat /dev/sdbX
#2.5 set bootable flag
#2.6 Be root or use sudo
sudo QT_X11_NO_MITSHM=1 unetbootin-linux64-647.bin targetdrive=/dev/sdbX isofile=./ISO/Win10_1709_English_x64.iso

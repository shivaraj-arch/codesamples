#unetbootin for creating linux based and dos based bootable usb live systems: 
#this is for liveOS on a EFI based usb stick - to extract squashfs on linux into usb /dev/sdbX
sudo QT_X11_NO_MITSHM=1 unetbootin targetdrive=/dev/sdbX isofile=./centos.iso


#for windows first 
#1.fdisk to usb 
#2.create a dos partition table
#3.create a partition 
#4.create a filesystem mkfs.vfat /dev/sdbX: 
sudo QT_X11_NO_MITSHM=1 unetbootin-linux64-647.bin targetdrive=/dev/sdbX isofile=./ISO/Win10_1709_English_x64.iso



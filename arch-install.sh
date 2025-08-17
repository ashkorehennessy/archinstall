#!/bin/bash
#by Ashkore
echo "changing mirror to ustc"
rm /etc/pacman.d/mirrorlist
echo 'Server = https://mirrors.ustc.edu.cn/archlinux/$repo/os/$arch' > /etc/pacman.d/mirrorlist
echo "select partition to install"
for ((;;))
do
	echo "list available partitions"
	for dev in /dev/sd[a-z]* /dev/vd[a-z]* /dev/mmcblk[0-9]* /dev/nvme[0-9]*n[0-9]*; do
		[[ -e "$dev" ]] && echo "$dev"
	done
	echo "enter partition path or run parted (p)"
	read par
	case $par in
		"p")
			parted
			;;

		"")
			continue
			;;
		*)
			if [ -b $par ]
			then
				echo "select partition : $par"
				break
			else
				echo "partition not found"
			fi
			;;
	esac
done
for ((;;))
do
	read -p "format $par? (y/*)" f
	case $f in
		"y")
			mkfs.ext4 $par
			break
			;;
		"n")
			echo "without format will cause some problem after install"
			read -p "are you sure? (y/*)" nofmt
			if [ $nofmt != y ]
			then
				continue
			fi
			break
			;;
		*)
			;;
	esac
done
echo "mount $par to /mnt"
mount $par /mnt
echo "installing base packages to new root"
pacstrap /mnt base linux linux-firmware dhcpcd vim sudo grub efibootmgr intel-ucode exfat-utils dosfstools openssh base-devel bash-completion unzip zip wget net-tools bind-tools htop btop fastfetch rsync
echo "generate fstab to new root"
genfstab -U /mnt >> /mnt/etc/fstab
echo "downloading postinstall script"
curl -LO https://ashkorehennessy.oss-cn-shanghai.aliyuncs.com/postinstall.sh
cp postinstall.sh /mnt/root/postinstall.sh
chmod +x /mnt/root/postinstall.sh
echo "running postinstall"
arch-chroot /mnt /root/postinstall.sh


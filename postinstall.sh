#!/bin/bash
#by Ashkore
echo "change mirror to ustc"
echo 'Server = https://mirrors.ustc.edu.cn/archlinux/$repo/os/$arch' > /etc/pacman.d/mirrorlist
echo "set timezone to Asia/Shanghai"
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
hwclock --systohc
echo "set language to zh_CN.UTF-8"
sed -i 's/#zh_CN.UTF-8/zh_CN.UTF-8/g' /etc/locale.gen
locale-gen
echo "LANG=zh_CN.UTF-8" > /etc/locale.conf
echo "LC_ALL=zh_CN.UTF-8" >> /etc/locale.conf
echo "add user"
read -p "user name:" username
useradd -m -G wheel $username
echo "set password"
passwd $username
echo "configure sudo"
chmod +w /etc/sudoers
for ((;;))
do
	read -p "would you want to run sudo without password? (y/*)" sn
	case $sn in
		"y")
			sed -i 's/^# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/' /etc/sudoers
			break
			;;
		*)
			sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
			break
			;;
	esac
done
for ((;;))
do
	read -p "install grub? (y/n)" ig
	case $ig in
		"y")
		  sed -i 's/#GRUB_DISABLE_OS_PROBER=false/GRUB_DISABLE_OS_PROBER=false/g' /etc/default/grub
			for ((;;))
			do
				echo "list available partitions"
				for dev in /dev/sd[a-z]* /dev/vd[a-z]* /dev/mmcblk[0-9]* /dev/nvme[0-9]*n[0-9]*; do
					[[ -e "$dev" ]] && echo "$dev"
				done
				echo "enter EFI partition to install or install to vdisk (v) ;parted(p)"
				read ef
				case $ef in
					"p")
						parted
						;;
					"v")
						dd if=/dev/zero of=efi.img bs=1M count=300
						parted efi.img mklabel gpt
						parted efi.img mkpart esp fat32 0% 100%
						parted efi.img set 1 esp on
						pacman -S multipath-tools
						kpartx -a -v efi.img
						mkfs.fat -F32 -s1 /dev/mapper/loop0p1
						mkdir /boot/EFI
						mount /dev/mapper/loop0p1 /boot/EFI
						grub-install --target=x86_64-efi --efi-directory=/boot/EFI
						grub-mkconfig > /boot/grub/grub.cfg
						echo "you should copy out the efi file from /boot/EFI to other place"
						break 3
						;;
					*)
						if [ -b $ef ]
						then
							mkdir /boot/EFI
							read -p "format $ef? (y/*)" fmt
							if [ $fmt == "y" ]
							then
								mkfs.fat -F32 -s1 $ef
							fi
							mount $ef /boot/EFI
							echo "list available devices"
							for dev in /dev/sd[a-z] /dev/vd[a-z] /dev/mmcblk[0-9] /dev/nvme[0-9]*n[0-9]; do
								[[ -e "$dev" ]] && echo "$dev"
							done
							echo "enter device to install"
							read de
							grub-install --target=x86_64-efi --efi-directory=/boot/EFI $de
							grub-mkconfig > /boot/grub/grub.cfg
							break 3
						else
							echo "partition not found"
						fi
						;;
				esac
			done
			;;
		"n")
			break
			;;
		*)
			;;
	esac
done

sed -i 's/#Color/Color/g' /etc/pacman.conf
echo "install plasma"
pacman -Sy --noconfirm --needed plasma sddm sddm-kcm xorg wayland kate konsole yakuake ark dolphin dolphin-plugins networkmanager kdeconnect wqy-microhei kwalletmanager partitionmanager plasma-x11-session
echo "configure plasma"
systemctl enable NetworkManager
systemctl enable sddm
systemctl enable dhcpcd
echo "install audio system"
pacman -Sy --noconfirm --needed pipewire wireplumber pipewire-pulse pipewire-alsa pipewire-jack alsa-utils sof-firmware bluez bluez-utils libldac libfreeaptx libfdk-aac
systemctl enable bluetooth.service
echo "configure archlinuxcn"
echo '[archlinuxcn]' >> /etc/pacman.conf
echo 'Server = https://mirrors.ustc.edu.cn/archlinuxcn/$arch' >> /etc/pacman.conf
pacman -Sy --noconfirm --needed archlinuxcn-keyring
echo "install fcitx5"
pacman -Sy --noconfirm --needed paru fcitx5 fcitx5-gtk fcitx5-qt fcitx5-chinese-addons fcitx5-configtool fcitx5-breeze fcitx5-pinyin-zhwiki fcitx5-pinyin-moegirl
echo "install some useful packages"
echo '[ashkorehennessy]' >> /etc/pacman.conf
echo 'SigLevel = Never' >> /etc/pacman.conf
echo 'Server = https://ashkorehennessy.oss-cn-shanghai.aliyuncs.com/ashkorehennessy' >> /etc/pacman.conf
pacman -Sy --noconfirm fcitx5-input-support v2rayn-bin
sed -i '$d' /etc/pacman.conf
sed -i '$d' /etc/pacman.conf
sed -i '$d' /etc/pacman.conf
pacman -Syy
fastfetch
echo "install finished, reboot to use your new system"


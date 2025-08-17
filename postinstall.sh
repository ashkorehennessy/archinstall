#!/bin/bash
#by Ashkore
echo "set timezone to Asia/Shanghai"
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
hwclock --systohc
echo "set language to zh_CN.UTF-8"
sed -i 's/#zh_CN.UTF-8/zh_CN.UTF-8/g' /etc/locale.gen
locale-gen
echo "LANG=zh_CN.UTF-8" > /etc/locale.conf
echo "LC_ALL=zh_CN.UTF-8" >> /etc/locale.conf
echo "adding user"
read -p "user name:" username
useradd -m -G wheel $username
echo "setting password"
passwd $username
echo "configuring sudo"
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
			for ((;;))
			do
				echo "list available partitions"
				for dev in /dev/sd[a-z]* /dev/vd[a-z]* /dev/mmcblk[0-9]* /dev/nvme[0-9]*n[0-9]*; do
					[[ -e "$dev" ]] && echo "$dev"
				done
				echo "enter EFi partition to install or install to vdisk (v) ;parted(p)"
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
						echo "installing kpartx"
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
							echo "enter device to be installed"
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
echo "installing plasma"
pacman -Sy --noconfirm --needed plasma sddm sddm-kcm xorg wayland kate konsole yakuake ark dolphin dolphin-plugins networkmanager kdeconnect wqy-microhei kwalletmanager partitionmanager
echo "configuring plasma"
systemctl enable NetworkManager
systemctl enable sddm
systemctl enable dhcpcd
echo "configuring archlinuxcn"
echo '[archlinuxcn]' >> /etc/pacman.conf
echo 'Server = https://mirrors.ustc.edu.cn/archlinuxcn/$arch' >> /etc/pacman.conf
pacman -Sy --noconfirm --needed archlinuxcn-keyring
echo "installing fcitx5"
pacman -Sy --noconfirm --needed paru fcitx5 fcitx5-gtk fcitx5-qt fcitx5-chinese-addons fcitx5-configtool fcitx5-breeze fcitx5-pinyin-zhwiki fcitx5-pinyin-moegirl
echo "configuring fcitx5"
sudo -u $username paru -S --noconfirm --needed fcitx5-input-support
echo "installing chrome"
sudo -u $username paru -S --noconfirm --needed google-chrome
echo "install finished"


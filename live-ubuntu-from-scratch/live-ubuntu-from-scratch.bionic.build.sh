
set -x
set -e

mkdir $HOME/live-ubuntu-from-scratch -p

sudo apt-get install \
    binutils \
    debootstrap \
    squashfs-tools \
    xorriso \
    grub-pc-bin \
    grub-efi-amd64-bin \
    mtools \
    p7zip-full

test -d  $HOME/live-ubuntu-from-scratch/chroot || {

test -f $HOME/live-ubuntu-from-scratch/deb.tar || sudo debootstrap --arch=amd64 --variant=minbase --make-tarball=$HOME/live-ubuntu-from-scratch/deb.tar bionic $HOME/live-ubuntu-from-scratch/chroot http://us.archive.ubuntu.com/ubuntu/

sudo debootstrap --arch=amd64 --variant=minbase --unpack-tarball=$HOME/live-ubuntu-from-scratch/deb.tar  bionic $HOME/live-ubuntu-from-scratch/chroot http://us.archive.ubuntu.com/ubuntu/ 


}


umount $HOME/live-ubuntu-from-scratch/chroot/proc || true
umount $HOME/live-ubuntu-from-scratch/chroot/sys || true
umount $HOME/live-ubuntu-from-scratch/chroot/dev/pts || true
umount $HOME/live-ubuntu-from-scratch/chroot/dev || true
umount $HOME/live-ubuntu-from-scratch/chroot/run || true

mount --bind /dev $HOME/live-ubuntu-from-scratch/chroot/dev
mount --bind /run $HOME/live-ubuntu-from-scratch/chroot/run
mount none -t proc $HOME/live-ubuntu-from-scratch/chroot/proc
mount none -t sysfs $HOME/live-ubuntu-from-scratch/chroot/sys
mount none -t devpts $HOME/live-ubuntu-from-scratch/chroot/dev/pts

####### chroot start!! {

chroot $HOME/live-ubuntu-from-scratch/chroot bash -c '

set -x
set -e

export HOME=/root
export LC_ALL=C

echo "ubuntu-fs-live" > /etc/hostname

echo "
deb http://us.archive.ubuntu.com/ubuntu/ bionic main restricted universe multiverse
deb http://us.archive.ubuntu.com/ubuntu/ bionic-updates main restricted universe multiverse
deb http://us.archive.ubuntu.com/ubuntu/ bionic-security main restricted universe multiverse
"> /etc/apt/sources.list
apt-get update
apt-get install -y systemd-sysv

dbus-uuidgen > /etc/machine-id
ln -fs /etc/machine-id /var/lib/dbus/machine-id

dpkg-divert --local --rename --add /sbin/initctl
ln -s /bin/true /sbin/initctl

    #ubuntu-standard \

apt-get install -y  resolvconf net-tools wireless-tools locales linux-generic bash-completion htop grub-pc lsb-release
apt-get install -y --no-install-recommends network-manager 
apt-get install -y --no-install-recommends apt-transport-https curl vim nano less ssh
apt-get install -y --no-install-recommends netplan.io iputils-ping
apt-get install -y --no-install-recommends discover laptop-detect os-prober openssl
apt-get install -y  casper lupin-casper 

echo "
network:
  version: 2
  renderer: NetworkManager
#  ethernets:
#        enp0s3:
#            dhcp4: yes
"> /etc/netplan/my.yaml

truncate -s 0 /etc/machine-id
rm /sbin/initctl
dpkg-divert --rename --remove /sbin/initctl

apt-get clean
rm -vrf /tmp/* ~/.bash_history /var/lib/apt/lists/*ubuntu.com*

echo root:1 | chpasswd
grep --color -q ^PermitRootLogin /etc/ssh/sshd_config && sed -i "s@^PermitRootLogin.*@PermitRootLogin yes@" /etc/ssh/sshd_config || sed -i "/LogLevel/a PermitRootLogin yes" /etc/ssh/sshd_config;
sed -i "s@^PasswordAuthentication.*@PasswordAuthentication yes@" /etc/ssh/sshd_config;


export HISTSIZE=0
exit
####### CHROOT stop!! }

'

umount $HOME/live-ubuntu-from-scratch/chroot/proc
umount $HOME/live-ubuntu-from-scratch/chroot/sys
umount $HOME/live-ubuntu-from-scratch/chroot/dev/pts
umount $HOME/live-ubuntu-from-scratch/chroot/dev
umount $HOME/live-ubuntu-from-scratch/chroot/run

cd $HOME/live-ubuntu-from-scratch
mkdir -p image/{casper,isolinux,install}

sudo cp chroot/boot/vmlinuz-**-**-generic image/casper/vmlinuz
sudo cp chroot/boot/initrd.img-**-**-generic image/casper/initrd

######### bootloaders end

#sudo cp chroot/boot/memtest86+.bin image/install/memtest86+
#wget --progress=dot https://www.memtest86.com/downloads/memtest86-usb.zip -O image/install/memtest86-usb.zip
#unzip -p image/install/memtest86-usb.zip memtest86-usb.img > image/install/memtest86
#rm image/install/memtest86-usb.zip

cd $HOME/live-ubuntu-from-scratch
touch image/ubuntu

cat <<EOF > image/isolinux/grub.cfg

search --set=root --file /ubuntu

insmod all_video

set default="0"
set timeout=30

menuentry "Try Ubuntu FS without installing" {
   linux /casper/vmlinuz boot=casper noquiet nosplash ---
   initrd /casper/initrd
}

#menuentry "Install Ubuntu FS" {
#   linux /casper/vmlinuz boot=casper only-ubiquity quiet splash ---
#   initrd /casper/initrd
#}

#menuentry "Check disc for defects" {
#   linux /casper/vmlinuz boot=casper integrity-check noquiet nosplash ---
#   initrd /casper/initrd
#}

#menuentry "Test memory Memtest86+ (BIOS)" {
#   linux16 /install/memtest86+
#}
#
#menuentry "Test memory Memtest86 (UEFI, long load time)" {
#   insmod part_gpt
#   insmod search_fs_uuid
#   insmod chain
#   loopback loop /install/memtest86
#   chainloader (loop,gpt1)/efi/boot/BOOTX64.efi
#}
EOF

cd $HOME/live-ubuntu-from-scratch



chroot chroot dpkg-query -W --showformat='${Package} ${Version}\n' >  image/casper/filesystem.manifest 
cp -v image/casper/filesystem.manifest image/casper/filesystem.manifest-desktop 
sed -i '/ubiquity/d' image/casper/filesystem.manifest-desktop 
sed -i '/casper/d' image/casper/filesystem.manifest-desktop 
sed -i '/discover/d' image/casper/filesystem.manifest-desktop 
sed -i '/laptop-detect/d' image/casper/filesystem.manifest-desktop 
sed -i '/os-prober/d' image/casper/filesystem.manifest-desktop


cd $HOME/live-ubuntu-from-scratch
cat <<EOF > image/README.diskdefines
#define DISKNAME Ubuntu from scratch
#define TYPE binary
#define TYPEbinary 1
#define ARCH amd64
#define ARCHamd64 1
#define DISKNUM 1
#define DISKNUM1 1
#define TOTALNUM 0
#define TOTALNUM0 1
EOF

cd $HOME/live-ubuntu-from-scratch/image
grub-mkstandalone \
--format=x86_64-efi \
--output=isolinux/bootx64.efi \
--locales="" \
--fonts="" \
"boot/grub/grub.cfg=isolinux/grub.cfg"

(
cd isolinux && \
    dd if=/dev/zero of=efiboot.img bs=1M count=10 && \
    sudo mkfs.vfat efiboot.img && \
    LC_CTYPE=C mmd -i efiboot.img efi efi/boot && \
    LC_CTYPE=C mcopy -i efiboot.img ./bootx64.efi ::efi/boot/
)

grub-mkstandalone \
    --format=i386-pc \
    --output=isolinux/core.img \
    --install-modules="linux16 linux normal iso9660 biosdisk memdisk
    search tar ls" \
    --modules="linux16 linux normal iso9660 biosdisk search" \
    --locales="" \
    --fonts="" \
    "boot/grub/grub.cfg=isolinux/grub.cfg"

cat /usr/lib/grub/i386-pc/cdboot.img isolinux/core.img > isolinux/bios.img


######### bootloaders end

######### pack start

cd $HOME/live-ubuntu-from-scratch

rm $HOME/live-ubuntu-from-scratch/image/casper/filesystem.squashfs -f
mksquashfs $HOME/live-ubuntu-from-scratch/chroot $HOME/live-ubuntu-from-scratch/image/casper/filesystem.squashfs
du -h $HOME/live-ubuntu-from-scratch/image/casper/filesystem.squashfs


printf $(sudo du -sx --block-size=1 chroot | cut -f1) > image/casper/filesystem.size

cd image 
find . -type f -print0 | xargs -0 md5sum | grep -v "\./md5sum.txt" > md5sum.txt 

sudo xorriso \
    -as mkisofs \
    -iso-level 3 \
    -full-iso9660-filenames \
    -volid "Ubuntu from scratch" \
    -eltorito-boot boot/grub/bios.img \
    -no-emul-boot \
    -boot-load-size 4 \
    -boot-info-table \
    --eltorito-catalog boot/grub/boot.cat \
    --grub2-boot-info \
    --grub2-mbr /usr/lib/grub/i386-pc/boot_hybrid.img \
    -eltorito-alt-boot \
    -e EFI/efiboot.img \
    -no-emul-boot \
    -append_partition 2 0xef isolinux/efiboot.img \
    -output "../ubuntu-from-scratch.iso" \
    -graft-points \
     .  \
    /boot/grub/bios.img=isolinux/bios.img \
    /EFI/efiboot.img=isolinux/efiboot.img

mk_iso() {
sudo xorriso \
    -as mkisofs \
    -iso-level 3 \
    -full-iso9660-filenames \
    -volid "Ubuntu from scratch" \
    -eltorito-boot boot/grub/bios.img \
    -no-emul-boot \
    -boot-load-size 4 \
    -boot-info-table \
    --eltorito-catalog boot/grub/boot.cat \
    --grub2-boot-info \
    --grub2-mbr /usr/lib/grub/i386-pc/boot_hybrid.img \
    -eltorito-alt-boot \
    -e EFI/efiboot.img \
    -no-emul-boot \
    -append_partition 2 0xef isolinux/efiboot.img \
    -output "../ubuntu-from-scratch.bionic.iso" \
    -graft-points \
     .  \
    /boot/grub/bios.img=isolinux/bios.img \
    /EFI/efiboot.img=isolinux/efiboot.img

}

mk_iso

sed -i /bios.img/d md5sum.txt
B_MD5=$( 7z -aoa e ../ubuntu-from-scratch.iso isolinux/bios.img &>/dev/null ; md5sum bios.img | grep bios.img |cut -d\   -f1  ; rm bios.img )
echo "$B_MD5  ./isolinux/bios.img" >> md5sum.txt

mk_iso

du -h "../ubuntu-from-scratch.bionic.iso"

######### pack end

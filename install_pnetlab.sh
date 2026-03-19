#!/bin/bash

export LC_ALL=C
export DEBIAN_FRONTEND=noninteractive

GREEN='\033[32m'
RED='\033[31m'
NO_COLOR='\033[0m'

KERNEL_NAME="linux-5.17.15-pnetlab-uksm.zip"

clear

rm /var/lib/dpkg/lock* &>/dev/null
dpkg --configure -a &>/dev/null

FILES_DIR="$(pwd)/files"
KERNEL="$FILES_DIR/L/$KERNEL_NAME"
PRE_DOCKER="$FILES_DIR/D/pre-docker.zip"
PNET_TPM="$FILES_DIR/T/swtpm-focal.zip"
PNET_GUACAMOLE="$FILES_DIR/P/pnetlab-guacamole_6.0.0-7_amd64.deb"
PNET_DYNAMIPS="$FILES_DIR/P/pnetlab-dynamips_6.0.0-30_amd64.deb"
PNET_SCHEMA="$FILES_DIR/P/pnetlab-schema_6.0.0-30_amd64.deb"
PNET_VPC="$FILES_DIR/P/pnetlab-vpcs_6.0.0-30_amd64.deb"
PNET_QEMU="$FILES_DIR/P/pnetlab-qemu_6.0.0-30_amd64.deb"
PNET_DOCKER="$FILES_DIR/P/pnetlab-docker_6.0.0-30_amd64.deb"
PNET_PNETLAB="$FILES_DIR/P/pnetlab_6.0.0-103_amd64.deb"
PNET_WIRESHARK="$FILES_DIR/P/pnetlab-wireshark_6.0.0-30_amd64.deb"

if [ "$(lsb_release -c -s)" != "focal" ]; then
    echo -e "${RED}Upgrade has been rejected. You need to have Ubuntu 20.04 (focal) to use this script${NO_COLOR}"
    exit 1
fi

# On Azure attach data disk
azure_disk_tune() {
    ls -l /dev/disk/by-id/ | grep -q sdc && (
        echo o # Create a new empty DOS partition table
        echo n # Add a new partition
        echo p # Primary partition
        echo 1 # Partition number
        echo   # First sector (Accept default: 1)
        echo   # Last sector (Accept default: varies)
        echo w # Write changes
    ) | sudo fdisk /dev/sdc && (
        mke2fs -F /dev/sdc1
        echo "/dev/sdc1 /opt    ext4    defaults,discard    0   0 " | tee -a /etc/fstab
        mount /opt
    )
}

uname -a | grep -q -- "-azure " && azure_disk_tune

apt-get update

# Install required packages
add-apt-repository --yes ppa:ondrej/php &>/dev/null

# Detect kvm hypervisor or bare metal installation
systemd-detect-virt -v | tee /tmp/hypervisor

resize() {
    ROOTLV=$(mount | grep ' / ' | awk '{print $1}')
    echo "$ROOTLV"
    lvextend -l +100%FREE "$ROOTLV"
    echo Resizing ROOT FS
    resize2fs "$ROOTLV"
}

grep -F -e kvm -e none /tmp/hypervisor 2>&1 >/dev/null
if [[ $? -eq 0 ]]; then
    grep -q kvm /tmp/hypervisor && resize &>/dev/null
    grep -q none /tmp/hypervisor && resize &>/dev/null
fi

apt-get purge --autoremove -y docker.io containerd runc php8* -q &>/dev/null
rm /var/lib/dpkg/lock* &>/dev/null

apt-get install -y ifupdown unzip &>/dev/null
echo -e "${GREEN}Downloading dependencies for PNETLAB ${NO_COLOR}"

sudo apt-get install -y resolvconf php7.4 php7.4-yaml php7.4-common php7.4-cli php7.4-curl php7.4-gd php7.4-mbstring php7.4-mysql php7.4-sqlite3 php7.4-xml php7.4-zip libapache2-mod-php7.4 libnet-pcap-perl duc libspice-client-glib-2.0-8 libtinfo5 libncurses5 libncursesw5 php-gd ntpdate vim dos2unix apache2 bridge-utils build-essential cpulimit debconf-utils dialog dmidecode genisoimage iptables lib32gcc1 lib32z1 pastebinit php-xml libc6 libc6-i386 libelf1 libpcap0.8 libsdl1.2debian logrotate lsb-release lvm2 ntp php rsync sshpass autossh php-cli php-imagick php-mysql php-sqlite3 plymouth-label python3-pexpect sqlite3 tcpdump telnet uml-utilities zip libguestfs-tools cgroup-tools libyaml-0-2 php-curl php-mbstring net-tools php-zip python2 libapache2-mod-php mysql-server libavcodec58 libavformat58 libavutil56 libswscale5 libfreerdp-client2-2 libfreerdp-server2-2 libfreerdp-shadow-subsystem2-2 libfreerdp-shadow2-2 libfreerdp2-2 winpr-utils gir1.2-pango-1.0 libpango-1.0-0 libpangocairo-1.0-0 libpangoft2-1.0-0 libpangoxft-1.0-0 pango1.0-tools pkg-config libssh2-1 libtelnet2 libvncclient1 libvncserver1 libwebsockets15 libpulse0 libpulse-mainloop-glib0 libssl1.1 libvorbis0a libvorbisenc2 libvorbisfile3 libwebp6 libwebpmux3 libwebpdemux2 libcairo2 libcairo-gobject2 libcairo-script-interpreter2 libjpeg62 libpng16-16 libtool libuuid1 libossp-uuid16 default-jdk default-jdk-headless tomcat9 tomcat9-admin tomcat9-docs libaio1 libasound2 libbrlapi0.7 libcacard0 libepoxy0 libfdt1 libgbm1 libgcc-s1 libglib2.0-0 libgnutls30 libibverbs1 libjpeg8 libncursesw6 libnettle7 libnuma1 libpixman-1-0 libpmem1 librdmacm1 libsasl2-2 libseccomp2 libslirp0 libspice-server1 libtinfo6 libusb-1.0-0 libusbredirparser1 libvirglrenderer1 zlib1g qemu-system-common libxenmisc4.11 libcapstone3 libvdeplug2 libnfs13 udhcpd libxss1  libxencall1 libxendevicemodel1 libxenevtchn1 libxenforeignmemory1 libxengnttab1 libxenstore3.0 libxentoollog1 udhcpd libxss1 libxentoolcore1 libxentoollog1 libxencall1 libxendevicemodel1 libxenevtchn1 libxenmisc4.11 libcapstone3 libvdeplug2 libnfs13 php7.4 php7.4-cli php-common php7.4-curl php7.4-gd php7.4-mbstring php7.4-mysql php7.4-sqlite3 php7.4-xml php7.4-zip libapache2-mod-php7.4
update-alternatives --set php /usr/bin/php &>/dev/null

echo -e "${GREEN}Installing PNET-Lab...${NO_COLOR}"
rm -rf /tmp/* &>/dev/null

dpkg-query -l | grep linux-image-5.17.15-pnetlab-uksm-2 | grep 5.17.15-pnetlab-uksm-2-1 -q
if [ $? -ne 0 ]; then
    unzip -d /tmp "$KERNEL" &>/dev/null
    dpkg -i /tmp/pnetlab_kernel/*.deb
fi

dpkg-query -l | grep docker-ce -q
if [ $? -ne 0 ]; then
    unzip -d /tmp "$PRE_DOCKER" &>/dev/null
    dpkg -i /tmp/pre-docker/*.deb
fi

dpkg-query -l | grep swtpm -q
if [ $? -ne 0 ]; then
    unzip -d /tmp "$PNET_TPM" &>/dev/null
    dpkg -i /tmp/swtpm-focal/*.deb
fi

dpkg-query -l | grep pnetlab-docker | grep 6.0.0-30 -q
if [ $? -ne 0 ]; then
    dpkg -i "$PNET_DOCKER"
fi

dpkg-query -l | grep pnetlab-schema | grep 6.0.0-30 -q
if [ $? -ne 0 ]; then
    dpkg -i "$PNET_SCHEMA"
fi

dpkg-query -l | grep pnetlab-guacamole | grep 6.0.0-7 -q
if [ $? -ne 0 ]; then
    dpkg -i "$PNET_GUACAMOLE"
fi

dpkg-query -l | grep pnetlab-vpcs | grep 6.0.0-30 -q
if [ $? -ne 0 ]; then
    dpkg -i "$PNET_VPC"
fi

dpkg-query -l | grep pnetlab-dynamips | grep 6.0.0-30 -q
if [ $? -ne 0 ]; then
    dpkg -i "$PNET_DYNAMIPS"
fi

dpkg-query -l | grep pnetlab-wireshark | grep 6.0.0-30 -q
if [ $? -ne 0 ]; then
    dpkg -i "$PNET_WIRESHARK"
fi

dpkg-query -l | grep pnetlab-qemu | grep 6.0.0-30 -q
if [ $? -ne 0 ]; then
    dpkg -i "$PNET_QEMU"
fi

grep -F "127.0.1.1 pnetlab.example.com pnetlab" /etc/hosts || echo 127.0.2.1 pnetlab.example.com pnetlab | tee -a /etc/hosts 2>/dev/null
echo pnetlab | tee /etc/hostname 2>/dev/null

dpkg -i "$PNET_PNETLAB"

# Detect cloud
gcp_tune() {
    cd /sys/class/net/ || return
    for i in ens*; do echo 'SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", ATTR{address}=="'$(cat $i/address)'", ATTR{type}=="1", KERNEL=="ens*", NAME="'$i'"'; done >/etc/udev/rules.d/70-persistent-net.rules
    sed -i -e 's/NAME="ens.*/NAME="eth0"/' /etc/udev/rules.d/70-persistent-net.rules
    sed -i -e 's/ens4/eth0/' /etc/netplan/50-cloud-init.yaml
    apt-mark hold linux-image-gcp
    mv /boot/vmlinuz-*gcp /root
    update-grub2
}

azure_kernel_tune() {
    echo "options kvm_intel nested=1 vmentry_l1d_flush=never" | tee /etc/modprobe.d/qemu-system-x86.conf
    sudo -i
}

# GCP
dmidecode -t bios | grep -q Google && gcp_tune

# Azure
uname -a | grep -q -- "-azure " && azure_kernel_tune

apt autoremove --purge -y -q
apt autoclean -y -q

echo -e "${GREEN}Upgrade has been done successfully. Please reboot your system${NO_COLOR}"

# PNET-Lab 6.0.0-103 install guide on Ubuntu 20.04 (focal)

> You can install PNET with any hypervisor. Not only QEMU.<br>
> More detailed Wiki-style instructions will be written soon.

## QEMU Virtual Machine

Create virtual drive
```shell
qemu-img create -f qcow2 pnet-lab-6.qcow2 192G
```

Create Bridge network interface
```shell
sudo ip link add name br-pnet-lab-6 type bridge && \
    sudo ip addr add 192.168.100.1/24 dev br-pnet-lab-6 && \
    sudo ip link set br-pnet-lab-6 up
```

Create TAP network interface
```shell
sudo ip tuntap add tap0 mode tap user "$(whoami)" && \
    sudo ip link set tap0 master br-pnet-lab-6 up && \
    sudo ip link set tap0 up
```

Launch Ubuntu 20.04-live virtual machine
```shell
qemu-system-x86_64 -enable-kvm -cpu host -smp 12,sockets=1,cores=12,threads=1 -m 10G \
    -drive file=pnet-lab-6.qcow2,if=none,id=drive0,format=qcow2,aio=native,cache=none,discard=on \
    -device virtio-blk-pci,drive=drive0 \
    -netdev tap,id=net-hostonly,ifname=tap0,script=no,downscript=no,vhost=on \
    -device vmxnet3,netdev=net-hostonly,mac=52:69:67:13:37:88 \
    -netdev user,id=net-nat,ipv6=off \
    -device vmxnet3,netdev=net-nat,mac=52:69:67:13:37:89 \
    -cdrom ubuntu-20.04.6-live-server-amd64.iso -boot d
```

Install OS
1. Select and install openssh;
2. Give all harddisk for LVM LV;
3. Configure static IP on first interface. (e.g. 192.168.100.10/24)
4. Install

Launch fresh OS
```shell
qemu-system-x86_64 -enable-kvm -cpu host -smp 12,sockets=1,cores=12,threads=1 -m 10G \
    -drive file=pnet-lab-6.qcow2,if=none,id=drive0,format=qcow2,aio=native,cache=none,discard=on \
    -device virtio-blk-pci,drive=drive0 \
    -netdev tap,id=net-hostonly,ifname=tap0,script=no,downscript=no,vhost=on \
    -device vmxnet3,netdev=net-hostonly,mac=52:69:67:13:37:88 \
    -netdev user,id=net-nat,ipv6=off \
    -device vmxnet3,netdev=net-nat,mac=52:69:67:13:37:89 \
    -nographic -monitor none
```

Configure Ubuntu
1. Login by account you created
2. Go to root user (`sudo -i` or `sudo su`)
3. Set the root password with `passwd`
4. Allow root access over SSH in `/etc/ssh/sshd_config` (PermitRootLogin yes)
5. `apt update && apt upgrade -y && apt autoremove --purge -y`
6. `reboot`
7. SSH as root with static VM IP and delete installation-created account: `userdel -rf <username>`
8. Install git and git-lfs `apt install git git-lfs -y`

## PNET-Lab

Clone this repo into home directory (/root/ for root user).

Add execution rights to script
```shell
cd pnetlab-6.0.0-ubuntu20.04 && chmod +x install_pnetlab.sh
```

Run script and wait
```shell
./install_pnetlab.sh
```

Reboot your system again and configure PNET-Lab (autostarted TUI utility after reboot).

Important! Set the same static IP, not autoconfigured

Remove added default gateway from management interface _(192.168.100.0/24)_. Edit `/etc/network/interfaces` (remove `gateway` and dns servers).

Reboot :)
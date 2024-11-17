#!/bin/bash
echo "deb http://download.proxmox.com/debian/pve bookworm pve-no-subscription" >> /etc/apt/sources.list
rm /etc/apt/sources.list.d/pve-enterprise.list
apt-get update
apt-get upgrade -y
apt-get install nala -y
nala install -y git build-essential dkms pve-headers mdevctl
git clone https://gitlab.com/polloloco/vgpu-proxmox.git
cd /opt
git clone https://github.com/mbilker/vgpu_unlock-rs.git
curl https://sh.rustup.rs -sSf | sh -s -- -y --profile minimal
source $HOME/.cargo/env
cd vgpu_unlock-rs/
cargo build --release
mkdir /etc/vgpu_unlock
touch /etc/vgpu_unlock/profile_override.toml
mkdir /etc/systemd/system/{nvidia-vgpud.service.d,nvidia-vgpu-mgr.service.d}
echo -e "[Service]\nEnvironment=LD_PRELOAD=/opt/vgpu_unlock-rs/target/release/libvgpu_unlock_rs.so" > /etc/systemd/system/nvidia-vgpud.service.d/vgpu_unlock.conf
echo -e "[Service]\nEnvironment=LD_PRELOAD=/opt/vgpu_unlock-rs/target/release/libvgpu_unlock_rs.so" > /etc/systemd/system/nvidia-vgpu-mgr.service.d/vgpu_unlock.conf
echo -e "vfio\nvfio_iommu_type1\nvfio_pci\nvfio_virqfd" >> /etc/modules
echo "blacklist nouveau" >> /etc/modprobe.d/blacklist.conf
update-initramfs -u -k all
reboot

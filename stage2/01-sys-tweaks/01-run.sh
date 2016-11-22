#!/bin/bash -e

install -m 755 files/regenerate_ssh_host_keys		${ROOTFS_DIR}/etc/init.d/
install -m 755 files/apply_noobs_os_config		${ROOTFS_DIR}/etc/init.d/
install -m 755 files/resize2fs_once			${ROOTFS_DIR}/etc/init.d/

install -d						${ROOTFS_DIR}/etc/systemd/system/rc-local.service.d
install -m 644 files/ttyoutput.conf			${ROOTFS_DIR}/etc/systemd/system/rc-local.service.d/

install -m 644 files/50raspi				${ROOTFS_DIR}/etc/apt/apt.conf.d/


on_chroot sh -e - <<EOF
systemctl disable hwclock.sh
systemctl disable nfs-common
systemctl disable rpcbind
systemctl disable ssh
systemctl enable regenerate_ssh_host_keys
systemctl enable apply_noobs_os_config
systemctl enable resize2fs_once
EOF

on_chroot sh -e - << \EOF
for GRP in input spi i2c gpio; do
	groupadd -f -r $GRP
done
for GRP in adm dialout cdrom audio users sudo video games plugdev input gpio spi i2c netdev; do
  adduser pi $GRP
done
EOF

on_chroot sh -e - <<EOF
setupcon --force --save-only -v
EOF

on_chroot sh -e - <<EOF
usermod --pass='*' root
EOF

on_chroot sh -e - <<EOF
pvcreate /dev/sda4
vg create --autobackup y --verbose --name vg0 /dev/sda4
lvcreate --autobackup y --verbose --cache --cachemode writethrough --name opt --size 1G vg0
mkfs.ext4 -m 12 -E num_backup_sb=2,discard,mmp_update_interval=120 /dev/vg0/opt
EOF

# ext4 options
# -m 12 - reserve 12%
# num_backup_sb=2 - create 3 backup superblocks
# discard - true
# mmp_update_interval=120 - only force write every 120 seconds to increase sdcard lifespan

rm -f ${ROOTFS_DIR}/etc/ssh/ssh_host_*_key*

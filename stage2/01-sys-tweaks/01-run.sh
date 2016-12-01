#!/bin/bash -e

install -m 755 files/regenerate_ssh_host_keys ${ROOTFS_DIR}/etc/init.d/
install -m 755 files/apply_noobs_os_config		${ROOTFS_DIR}/etc/init.d/
install -m 755 files/resize2fs_once			      ${ROOTFS_DIR}/etc/init.d/
install -d						              ${ROOTFS_DIR}/etc/systemd/system/rc-local.service.d
install -m 644 files/ttyoutput.conf	${ROOTFS_DIR}/etc/systemd/system/rc-local.service.d/
install -m 644 files/50raspi				${ROOTFS_DIR}/etc/apt/apt.conf.d/
install -m 755 files/nodepath.sh    ${ROOTFS_DIR}/etc/profile.d/

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

_install_node(){

	NODE_URL=${NODE_URL:-"https://nodejs.org/dist/v6.9.1/node-v6.9.1-linux-armv7l.tar.xz"}
	BIN_DIR=${SCRIPT_DIR}/binaries
	NODE_TAR=${BIN_DIR}/node.tar.xz
	NODE_ROOTFS_DEST=/usr/local/node
	NODE_DEST=${ROOTFS_DIR}/${NODE_ROOTFS_DEST}

	mkdir -p ${BIN_DIR}
	install -d ${NODE_DEST}
	wget -c -q -N "$NODE_URL" -O $NODE_TAR || true
	tar xf $NODE_TAR  -C ${NODE_DEST} --strip=1
}

_install_node

rm -f ${ROOTFS_DIR}/etc/ssh/ssh_host_*_key*

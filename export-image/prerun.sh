#!/bin/bash -e
IMG_FILE="${STAGE_WORK_DIR}/${IMG_DATE}-${IMG_NAME}${IMG_SUFFIX}.img"

_mkparts()(
#IMG_FILE="testing_empty_delete.img"
P1_OFFSET=8192    # where official raspbian starts partition 1 (sectors)
BOOT_FS_SIZE=64     # how big will partition 1 be in MB
ROOT_FS_SIZE=1024      # how big will partition 2 and 3 be in MB
OPT_FS_INITIAL_SIZE=96  # how big initially ( before post reboot resize+grow)
                          # will exteneded partition 4 be in MB


#unmount_image ${IMG_FILE}
rm -fv ${IMG_FILE}


P1_MB=$BOOT_FS_SIZE # rename for fdisk
P2_MB=$ROOT_FS_SIZE # rename for fdisk
P3_MB=$ROOT_FS_SIZE
P4_MB=$OPT_FS_INITIAL_SIZE


### calculate total image size to create a file with fallocate
### if generate all now
# IMG_SIZE=$(expr $P1_MB \+ $P2_MB \+ $P3_MB \+ $P4_MB \+ 32)M

# to keep initial img small we only generate minimum now and create others on first boot
IMG_SIZE=$(expr $P1_MB \+ $P2_MB \+ 32)M

SECTOR_SIZE=512
SZ=$SECTOR_SIZE
# calculate sectors in each partion
P1_SECTORS=$(expr $P1_MB \* 1024 \* 1024 \/ $SZ )
P2_SECTORS=$(expr $P2_MB \* 1024 \* 1024 \/ $SZ )
P3_SECTORS=$(expr $P3_MB \* 1024 \* 1024 \/ $SZ )
P4_SECTORS=$(expr $P4_MB \* 1024 \* 1024 \/ $SZ )

#add the inital offset to factor
P1_SECTORS=$(expr $P1_SECTORS \+ $P1_OFFSET )

P1_START_SEC=$P1_OFFSET
P2_START_SEC=$(expr $P1_SECTORS + 1 )
P3_START_SEC=$(expr $P2_START_SEC \+ $P2_SECTORS + 1 )
P4_START_SEC=$(expr $P3_START_SEC \+ $P3_SECTORS + 1 )

echo "START SEC            OFFSET   "
echo "============================="
echo $P1_START_SEC     $P1_OFFSET
echo $P2_START_SEC     $P1_SECTORS
echo $P3_START_SEC     $P2_SECTORS
echo $P4_START_SEC     $P3_SECTORS



fallocate -l ${IMG_SIZE} ${IMG_FILE}
# t type
# c Changed type of partition 'Linux' to 'W95 FAT32 (LBA)'.
# new
# " "  default p
# " "  default 2
# > /dev/null 2>&1
fdisk ${IMG_FILE} <<EOF
o
n


$P1_START_SEC
+${P1_MB}M
p
t
c
n


$P2_START_SEC
+${P2_MB}M
p
w
EOF


fdisk -l ${IMG_FILE}
)

unmount_image ${IMG_FILE}

rm -f ${IMG_FILE}

rm -rf ${ROOTFS_DIR}

mkdir -p ${ROOTFS_DIR}

_mkparts

LOOP_DEV=`kpartx -asv ${IMG_FILE} | grep -E -o -m1 'loop[[:digit:]]+' | head -n 1`
BOOT_DEV=/dev/mapper/${LOOP_DEV}p1
ROOT_DEV=/dev/mapper/${LOOP_DEV}p2
ROOT2_DEV=/dev/mapper/${LOOP_DEV}p3
OPT_DEV=/dev/mapper/${LOOP_DEV}p4

mkdosfs -n boot -S 512 -s 16 -v $BOOT_DEV > /dev/null
mkfs.ext4 -O ^huge_file $ROOT_DEV > /dev/null

# create after to reduce image write times
# #savetime
# mkfs.ext4 -O ^huge_file $ROOT2_DEV > /dev/null


_lvm_setup(){
 echo "doing lvm setup"
  # create a
  # pv
  # vg
  # lv
  # ext4 fs

  # # mkfs.ext4 -O ^huge_file $OPT_DEV > /dev/null

}
_lvm_setup


mount -v $ROOT_DEV ${ROOTFS_DIR} -t ext4
mkdir -p ${ROOTFS_DIR}/boot
mkdir -p ${ROOTFS_DIR}/opt/$APP_NAME/data
mount -v $BOOT_DEV ${ROOTFS_DIR}/boot -t vfat



rsync -aHAXx ${EXPORT_ROOTFS_DIR}/ ${ROOTFS_DIR}/


original(){
BOOT_SIZE=$(du -sh ${EXPORT_ROOTFS_DIR}/boot -B M | cut -f 1 | tr -d M)
TOTAL_SIZE=$(du -sh ${EXPORT_ROOTFS_DIR} -B M | cut -f 1 | tr -d M)

IMG_SIZE=$(expr $BOOT_SIZE \* 2 \+ $TOTAL_SIZE \+ 512)M

fallocate -l ${IMG_SIZE} ${IMG_FILE}

}

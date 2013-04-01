#!/bin/sh
#
# gluster setup automation script.
#
set -x

DIR=/home/ocdet
GVOL=gvol1
BRICK_PATH=/mnt/sdb1
BRICK_DEV=/dev/sdb1

LEADER=1.1.1.202
SLAVES="1.1.1.203 1.1.1.203 1.1.1.204"
SLAVES2=" "
#
HOSTS="${LEADER} ${SLAVES}"
ALL_HOSTS="${LEADER} ${SLAVES} ${SLAVES2}"
MPOINT=/gluster1

BRICKS=""
for h in ${HOSTS}
do
    BRICKS="${BRICKS} ${h}:${BRICK_PATH}"
done
echo ${BRICKS}

#
#
#
for h in ${ALL_HOSTS}
do
    ssh root@${LEADER} umount ${MPOINT}
done
ssh root@${LEADER} gluster volume stop ${GVOL}
ssh root@${LEADER} gluster volume delete ${GVOL}
for h in ${SLAVES} ${SLAVES2}
do
    ssh root@${LEADER} gluster peer detach ${h}
done


for h in ${ALL_HOSTS}
do
    ssh root@${h} service glusterd stop
done

for h in ${ALL_HOSTS}
do
    ssh root@${h} umount ${BRICK_DEV} ${BRICK_PATH}
done

for h in ${ALL_HOSTS}
do
#    ssh root@${h} mkfs.xfs -f -i size=1024 ${BRICK_DEV}
    ssh root@${h} mkfs -t ext4 ${BRICK_DEV}
done

MOPT="-t ext4 -o rw,user_xattr"

for h in ${ALL_HOSTS}
do
    ssh root@${h} mount ${MOPT} ${BRICK_DEV} ${BRICK_PATH}
done

#
#
#
for h in ${ALL_HOSTS}
do
    ssh root@${h} service glusterd start
done


for h in ${SLAVES}
do
    ssh root@${LEADER} gluster peer probe ${h}
done

GV_OPT="replica 3 transport tcp"
#GV_OPT="replica 3 transport rdma"
ssh root@${LEADER} gluster volume create ${GVOL} ${GV_OPT} ${BRICKS}
ssh root@${LEADER} gluster volume start ${GVOL}

ssh root@${LEADER} mount -t glusterfs ${LEADER}:${GVOL} ${MPOINT}



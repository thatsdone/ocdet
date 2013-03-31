#!/bin/sh
set -x

YUMCONF=/etc/yum.repos.d/sl.repo
YUMSERVER=192.168.1.1

create () {
    BASEDIR=$1
    mkdir -p ${BASEDIR}/proc
    mkdir -p ${BASEDIR}/etc
    mkdir -p ${BASEDIR}/dev
    mkdir -p ${BASEDIR}/var/cache
    mkdir -p ${BASEDIR}/var/log
    mkdir -p ${BASEDIR}/var/lock/rpm
    /sbin/MAKEDEV -d ${BASEDIR}/dev -x console
    /sbin/MAKEDEV -d ${BASEDIR}/dev -x null
    /sbin/MAKEDEV -d ${BASEDIR}/dev -x zero
    cat > ${BASEDIR}/etc/fstab <<EOF
tmpfs                   /dev/shm                tmpfs   defaults        0 0
devpts                  /dev/pts                devpts  gid=5,mode=620  0 0
sysfs                   /sys                    sysfs   defaults        0 0
proc                    /proc                   proc    defaults        0 0
EOF

    mount -t proc none ${BASEDIR}/proc

    yum  -c ${YUMCONF} -y --installroot=${BASEDIR} groupinstall Base
    yum  -c ${YUMCONF} -y --installroot=${BASEDIR} install openssh-server
    yum  -c ${YUMCONF} -y --installroot=${BASEDIR} groupinstall "Network file system client"

    chroot ${BASEDIR} passwd --stdin <<EOF
yourpassword
EOF

#    cat > ${BASEDIR}/etc/yum.repos.d/sl.repo <<EOF
#[sl]
#name=Scientific Linux $releasever - $basearch
#baseurl=http://10.192.37.64/install/SL/6.1/x86_64/
#enabled=1
#gpgcheck=0
#gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-sl file:///etc/pki/rpm-gpg/RPM-GPG-KEY-dawson
#EOF
    umount ${BASEDIR}/proc
}


create /tftpboot/host128


#!/bin/bash

ACTION=$1
DEVBASE=$2
DEVICE="/dev/${DEVBASE}"
MOUNT_POINTS="/media/usb0 /media/usb1 /media/usb2 /media/usb3
              /media/usb4 /media/usb5 /media/usb6 /media/usb7
              /media/usb8 /media/usb9 /media/usb10 /media/usb11
              /media/usb12 /media/usb13 /media/usb14 /media/usb15"

# See if this drive is already mounted
MOUNT_POINT=$(/bin/mount | /bin/grep ${DEVICE} | /usr/bin/awk '{ print $3 }')

do_mount()
{
    if [[ -n ${MOUNT_POINT} ]]; then
        # Already mounted, exit
        exit 1
    fi

    # Get info for this drive: $ID_FS_LABEL, $ID_FS_UUID, and $ID_FS_TYPE
    eval $(/sbin/blkid -o udev ${DEVICE} | sed -e 's/ /_/g')

    if [[ -z "${ID_FS_TYPE}" ]]; then
        # Invalid partition, exit
        exit 1
    fi

    # Aquire lock
    exec {lock_fd}>/var/lock/usb-mount || exit 1
    flock -x -w 60 "$lock_fd" || exit 1

    # Figure out a mount point to use
    MOUNT_POINT=""
    for i in $MOUNT_POINTS ; do
        if [[ ! -d $i ]]; then
            MOUNT_POINT=$i
            break
        fi
    done

    if [[ -z "${MOUNT_POINT}" ]]; then
        # Release lock
        flock -u "$lock_fd"
        # No available mount point, exit
        exit 1
    fi

    /bin/mkdir -p ${MOUNT_POINT}

    # Release lock
    flock -u "$lock_fd"

    # Global mount options
    OPTS="noexec,nodev,noatime,nodiratime"

    # File system type specific mount options
    if [[ ${ID_FS_TYPE} == "vfat" ]]; then
        OPTS+=",gid=1000,uid=1000,umask=007"
    fi
    if [[ ${ID_FS_TYPE} == "ntfs-3g" ]]; then
        OPTS+=",nls=utf8,umask=007,gid=46"
    fi

    if ! /bin/mount -o ${OPTS} ${DEVICE} ${MOUNT_POINT}; then
        # Error during mount process: cleanup mountpoint
        /bin/rmdir ${MOUNT_POINT}
        exit 1
    fi
}

do_unmount()
{
    if [[ -n ${MOUNT_POINT} ]]; then
        /bin/umount -l ${DEVICE}
    fi

    # Delete all empty dirs in /media that aren't being used as mount points.
    for f in /media/* ; do
        if [[ -n $(/usr/bin/find "$f" -maxdepth 0 -type d -empty) ]]; then
            if ! /bin/grep -q " $f " /etc/mtab; then
                /bin/rmdir "$f"
            fi
        fi
    done
}

case "${ACTION}" in
    add)
        do_mount
        ;;
    remove)
        do_unmount
        ;;
esac
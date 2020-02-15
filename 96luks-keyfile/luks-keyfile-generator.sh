#!/bin/bash

NORMAL_DIR="/run/systemd/system"
LUKS_KEYFILE_WANTS="/etc/systemd/system/luks-keyfile.target.wants"

CRYPTSETUP="/usr/lib/systemd/systemd-cryptsetup"
MOUNT=$(command -v mount)
UMOUNT=$(command -v umount)

TIMEOUT=30

generate_service () {
        local keyfile_uuid=$1 keyfile_path=$2 target_uuid=$3 timeout=$4 mountopts=$5 sd_dir=${6:-$NORMAL_DIR}

        local keyfile_dev="dev-disk-by\x2duuid-$(systemd-escape -p $keyfile_uuid).device"

        local sd_target_uuid=$(systemd-escape -p $target_uuid)
        local target_dev="dev-disk-by\x2duuid-${sd_target_uuid}.device"

        local keyfile_mountpoint="/luks-keyfile/luks-${target_uuid}"
        mkdir -p "$keyfile_mountpoint"
        keyfile_path="${keyfile_mountpoint}/${keyfile_path}"

        local crypto_target_service="systemd-cryptsetup@luks\x2d${sd_target_uuid}.service"
        local sd_service="${sd_dir}/luks-keyfile@luks\x2d${sd_target_uuid}.service"
        {
                printf -- "[Unit]"
                printf -- "\nBindsTo=%s %s" "$keyfile_dev" "$target_dev"
                printf -- "\nAfter=%s %s cryptsetup-pre.target systemd-journald.socket" "$keyfile_dev" "$target_dev"
                printf -- "\nBefore=%s umount.target luks-keyfile.target" "$crypto_target_service"
                printf -- "\nConflicts=umount.target"
                printf -- "\nDefaultDependencies=no"
                printf -- "\nJobTimeoutSec=%s" "$timeout"
                printf -- "\nIgnoreOnIsolate=true"

                printf -- "\n\n[Service]"
                printf -- "\nType=oneshot"
                printf -- "\nRemainAfterExit=yes"
                printf -- "\nExecStart=${MOUNT} -o ro '/dev/disk/by-uuid/%s' %s" "$keyfile_uuid" "$keyfile_mountpoint"
                printf -- "\nExecStart=${CRYPTSETUP} attach 'luks-%s' '/dev/disk/by-uuid/%s' '%s' '%s'" "$target_uuid" "$target_uuid" "$keyfile_path" "$mountopts"
                printf -- "\nExecStart=${UMOUNT} '%s'" "$keyfile_mountpoint"
                printf -- "\nExecStop=${CRYPTSETUP} detach 'luks-%s'" "$target_uuid"
        } > "$sd_service"

        mkdir -p "${sd_dir}/${crypto_target_service}.d"
        {
                printf -- "[Unit]"
                printf -- "\nConditionPathExists=!/dev/mapper/luks-%s" "$target_uuid"
        } > "${sd_dir}/${crypto_target_service}.d/drop-in.conf"

        mkdir -p "${sd_dir}/initrd-switch-root.target.d"
        {
                printf -- "[Unit]"
                printf -- "\nWants=luks-keyfile@luks\x2d%s.service luks-keyfile.target" "$sd_target_uuid"
        } > "${sd_dir}/initrd-switch-root.target.d/luks-keyfile-${target_uuid}.conf"

        ln -sf "$sd_service" "${LUKS_KEYFILE_WANTS}/"
}

parse_cmdline () {
        local CMDLINE
        IFS=':' read -ra CMDLINE <<<${1#rd.luks.keyfile=}

        local __k_uuid=$2
        eval $__k_uuid=${CMDLINE[0]#UUID=}

        local __k_path=$3
        [[ ${CMDLINE[1]:0:1} != "/" ]] || ${CMDLINE[1]}=${CMDLINE[1]:1}
        eval $__k_path=${CMDLINE[1]}

        local __t_uuid=$4
        eval $__t_uuid=${CMDLINE[2]#UUID=}

        local __t=$5
        eval $__t=${CMDLINE[3]:-$TIMEOUT}

        local __t=$6
        eval $__t=${CMDLINE[4]:-defaults}
}

generate_from_cmdline () {
        local keyfile_uuid= keyfile_path= target_uuid= timeout=

        for argv in $(cat /proc/cmdline); do
                case $argv in
                        rd.luks.keyfile=*)
                                parse_cmdline $argv keyfile_uuid keyfile_path target_uuid timeout mountopts
                                generate_service $keyfile_uuid $keyfile_path $target_uuid $timeout $mountopts
                                ;;
                esac
        done
}

generate_from_cmdline

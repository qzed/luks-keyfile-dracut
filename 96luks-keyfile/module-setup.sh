#!/bin/bash

check () {
        if ! dracut_module_included "systemd"; then
                "luks-keyfile needs systemd in the initramfs"
                return 1
        fi
        return 255
}

depends () {
        echo "systemd"
        return 0
}

install () {
        inst "$moddir/luks-keyfile-generator.sh" "/etc/systemd/system-generators/luks-keyfile-generator.sh"
        inst "$systemdutildir/systemd-cryptsetup"
        mkdir -p "$initdir/luks-keyfile"

        inst "$moddir/luks-keyfile.target" "/etc/systemd/system/luks-keyfile.target"
        mkdir -p "$initdir/etc/systemd/system/luks-keyfile.target.wants"

        mkdir -p "$initdir/etc/systemd/system/sysinit.target.wants"
        ln -sf "/etc/systemd/system/luks-keyfile.target" "$initdir/etc/systemd/system/sysinit.target.wants/"
}

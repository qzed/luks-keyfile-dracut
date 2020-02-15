# luks-keyfile-dracut

Fully automated unlock of LUKS encrypted partitions (including root partition) via a key file stored on a USB stick (or any partition in general), no user-interaction required.

Based on https://github.com/raffaeleflorio/luks-2fa-dracut.

## Motivation

The main motivation of this module is automated unlocking of encrypted LUKS partitions during boot.
Note that this is essentially implies a trade-off between security and convenience.
With the convenience of a fully autonomous boot (that doesn't require any kind of network access like other similar solutions), you are forced to store the key unencrypted.
This project does not aim to provide bullet proof security, but rather a convenient way to have a small bit of security.
Specifically, this project was developed for a network attached storage setup, with the idea that destroying the key on a small USB stick is easier and a lot faster than over-writing large drives multiple times before decomissioning them.

## Configuration

During boot, specified partitions will be unlocked by reading a keyfile from a secondary partition, e.g. a USB stick.
To configure which paritions will be unlocked using what key, you will need to specify the following command line option (one per partition to be unlocked):
```
rd.luks.keyfile=UUID=keyfile_uuid:keyfile_path:UUID=target_uuid[:timeout[:mount_opts]]
```
The options are
- `keyfile_uuid`: UUID of the partition where the key file is stored.
- `keyfile_path`: The path on the key file partition pointing to the key file.
- `target_uuid`: The UUID of the partition to unlock.
- `timeout`: A timeout in seconds.
   When the timeout is reached, unlocking via key file will be aborted and the user will be asked for a bassword.
- `mount_opts`: Mount options as specified in `/etc/fstab`.

See `/dev/disks/by-uuid/` for the partition UUIDs. These parameters will be translated by the systemd generator into a systemd service.

## Setup

### Via Package

There is a pre-built package available for Fedora in the [release](https://github.com/qzed/luks-keyfile-dracut/releases) section.
This package will automatically install and set-up the module.
You still need to configure it via the command line as described above.

### Manual Installation

Installation:
1. Set up your keyfile and make sure it can be used to decrypt the desired partition(s).
2. Clone this repo (`git clone https://github.com/qzed/luks-keyfile-dracut.git`) and change into its directory.
3. Install the module via `make install`.
   A new initramfs will be automatically created with `dracut -fv`.
4. Configure the kernel command line options, as described above, by adding your LUKS volume and key partiton via the `rd.luks.keyfile` parameter.
   This can, for example, be done by editing `/etc/default/grub` if you use GRUB.

Removal:
- Run `make uninstall`.
  A new initramfs will be created automatically via `dracut -fv`:

---

Tested on Fedora 31 (Server Edition).

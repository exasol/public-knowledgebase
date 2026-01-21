# /etc/lvm/devices/system.devices

`/etc/lvm/devices/system.devices` is an **LVM devices file** used by Logical Volume Manager (LVM) to control **which block devices LVM is allowed to scan and use**.

It acts as an **allow-list**. If this file exists, **only the devices listed in it will be considered by LVM**.

---

## What this file is

- Part of **LVM device management (devicesfile)**
- Introduced to make device discovery **safer and more deterministic**
- Prevents LVM from scanning all block devices
- Especially important on systems with:
  - Many disks
  - SAN / iSCSI / FC storage
  - Multipath devices

---

## Typical contents

```ini
devices {
    device {
        id = "scsi-3600508b400105e210000900000490000"
        devname = "/dev/sda"
    }

    device {
        id = "scsi-3600508b400105e210000900000490001"
        devname = "/dev/sdb"
    }

    device {
        id = "lvm-pv-uuid-9xA1bC-DEF2-ghI3-jK4L-mN5O-pQ6R"
        devname = "/dev/mapper/mpatha"
    }
}
```

## Device identification

Each device entry contains:

- id

A stable identifier such as:

- SCSI WWID
- LVM PV UUID
- Multipath identifier
- devname

The current device node (e.g. /dev/sda, /dev/mapper/mpatha)

LVM trusts the id, not the device name.
This prevents issues when device names change across reboots.

## Why it exists

- Avoid accidentally using:
  - Backup disks
  - Installer leftovers
  - Foreign SAN LUNs
  - Improve performance on hosts with many block devices
- Required for reliable:
  - Multipath setups
  - SAN / enterprise storage
  - Strict storage policies

## How the file is managed

Normally managed automatically by LVM tools.

Common commands

```bash
lvmdevices           # list known devices
lvmdevices --adddev /dev/sda
lvmdevices --addpv  /dev/sda2
lvmdevices --deldev /dev/sdb
pvscan               # rescan physical volumes
```

Manual editing is strongly discouraged.

## When to check this file

- Volume group or PV missing after reboot
- Disk replacement or resizing
- SAN LUN ID changes
- Multipath issues
- After system cloning or imaging

## Summary

- system.devices = explicit allow-list for LVM
- Ensures predictable, safe device handling
- Essential in enterprise and SAN environments
- Misconfiguration can make entire VGs disappear

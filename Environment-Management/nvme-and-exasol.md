# Can You Use an NVME with Exasol?

## Question
On many machines, Nvme drives are not mounted by default before the OS installs.  They must be partitioned after install... ie. they are not managed by on-board RAID.  This would pose a chicken-egg problem as Exasol does not provide root access to the operating system.  When and how to provision the drives for use by Exasol?

## Answer
Don't count on booting to NVME (we used SSD, shown as "/dev/sda" below) but it turns out that assigning the drive handles of NVME drives is quite predictable and supported.

Here's what our config looked like for one node in one environment with a 4tb nvme ("0") and 500gb name ("1") 

|Name| Type| Size| RAID| Encryption Devices| Free SW| RAID State| Next Filesystem Check on Boot|  Mount Count| Expiration Date
|-|-|-|-|-|-|-|-|-|-|
d00_os|OS|200 GiB|None|AES 256|/dev/sda|175.4 GiB|None|3/-1|-
d01_swap|Swap|16 GiB|None|AES 256|/dev/sda|16.0 GiB|None|-|-
d02_data|Data|400 GiB|None|AES 256|/dev/nvme1n1|370.6 GiB|None|3/-1|-
d03_storage|Storage|Rest (3726 GiB)|None|AES 256|/dev/nvme0n1|0.0 GiB|None|-|-

If you have root or loaded Centos separately on the system you will see that the device names shown here map to the physical.  You don't need to add "p" (partition) notation to the device name, Exasol takes care of that.  Remember to "Add Unused Drives" in ExaStorage.
# Working with LVM for your Docker Container (file device) 
Exasol on Docker has multiple options when it comes to data storage. You can either use a partition/disk or a storage file located in a specific location on the Docker host. The examples below all use a file system to store the dev.1 file which is used by EXAStorage.

### Create a logical volume

1. Add a physical device to LVM:


```
$ pvcreate /dev/vda 
```
2. Create a volume group:


```
$ vgcreate VG1 /dev/vda 
```
3. Create a logical volume: 


```
$ lvcreate --size 30G VG1 
```
4. Add a filesystem:


```
$ mkfs.ext4 /dev/VG1/lvol0 
```
5. Mount:


```
$ mount /dev/VG1/lvol0 /mnt/ 
```
5.1. or Mount Permanently by adding it to ***/etc/fstab***:


```
$ echo 
```
When you reach the limit of your storage device you can increase its capacity by executing the commands below:

### Increase the size of the physical device

1. Increase the size of the physical device:


```
$ pvresize /dev/vda 
```
2. Extend logical volume and resize the file system:


```
$ lvextend -r -L +20GB /dev/VG1/lvol0 
```
2.1. or if lvextend was executed without -r:


```
$ resize2fs /dev/VG1/lvol0 
```
If you prefer using a storage file, you can do the following:

### Add a disk to an existing volume group and logical volume

1. Add physical device to LVM:


```
$ pvcreate /dev/vdb 
```
2. Extend volume group:


```
$ vgextend VG1 /dev/vdb 
```
3. Extend logical volume and resize FS:


```
$ lvextend -r -L+100G /dev/VG1/lvol0 
```
3.1. or if lvextend was executed without -r:


```
$ resize2fs /dev/VG1/lvol0 
```
4. Enter container and enlarge file device:


```
$ truncate --size=+10GB /exa/data/storage/dev.1 
$ cshdd --enlarge -n 11 -h /exa/data/storage/dev.1
```

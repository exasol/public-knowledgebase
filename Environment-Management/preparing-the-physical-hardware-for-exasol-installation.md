# Preparing the physical hardware for Exasol installation 
This article describes how the physical hardware must be configured prior to an Exasol installation. There are 2 categories of settings that must be applied, for data nodes and for the management node.

## Data nodes settings:

### BIOS:

* Disable EFI
* Disable C-States (Maximum Performance)
* Enable PXE on "CICN" Ethernet interfaces
* Enable Hyperthreading
* Boot order: Boot from PXE 1st NIC (VLAN CICN)

### RAID:

* Controller RW-Cache only enabled with BBU
* All disks are configured as RAID-1 mirrors (best practice. For different setup, ask EXASOL Support)
* Keep the default strip size
* Keep the default R/W cache ratio

### LOM Interface

* Enable SOL (Serial over LAN console)

## Management node settings:

### BIOS:

* Disable EFI
* Disable C-States (Maximum Performance)
* Enable Hyperthreading
* Boot order: Boot from disk

### RAID:

* Controller RW-Cache only enabled with BBU
* All disks are configured as RAID-1 mirrors (best-practice, for different setup ask EXASOL Support)
* Keep the default strip size
* Keep the default R/W cache ratio

### LOM Interface

* Enable SOL (Serial over LAN console)

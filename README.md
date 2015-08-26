# Ganeti-Configuration
Ganeti Cluster configurations for Xen hypervisor on Debian 8.

This configuration provide **Virtuals Machines on Debian 8 or Ubuntu 14.04** and can make clone of VM.

## All VMs have : 

* **Own /boot** virtual drive
* **Own kernel** (doesn't use dom0's kernel)
* **LVM2 configuration** based  
* **Minimum pkgs** like vim, htop, screen ...


## Requirements :

* Need dom0 with Volum Group "vgganeti"
* Need **DRBD8** working fine
* Requires at least 2 nodes
* "os" folder is for /usr/share/ganeti/os/
* "instance-debootstrap" is for /etc/ganeti-instance-debootstrap
* Folders /srv/ganeti/vminitlog and /srv/ganeti/vmcreation must exist


**newVM.sh**, automated VMs creation's script :


```
NewVM.sh v0.1 - Create a Ganeti Virtual Machine
Author: Valentin OUVRARD
Usage: newVM.sh --name <NAME> --disk <DISK> --ram <RAM> 

Options:

	--name    <VM_NAME>		New virtual machine hostname
	--disk    <DISK>		Disk size in gigabytes (G|g)
	--ram 	  <RAM>			Memory size in gigabytes (G|g)
	--vcpu    <VCPU>		Virtual CPU number
	--nodes   <NODES>		First node and second node(1st:2nd) 
	--clone   <CLONE>		Name of a VM to clone
	--variant <OS>			Choose between trusty and jessie (by default)
	--no-confirm			Disable VM creation's confirmation

Networking options:

	--ipv4 	  <IPV4>		Virtual machine IPV4 Address 
	--gw      <GW>			Virtual machine IPV4 Gateway
	--netmask <MASK>		Virtual machine IPV4 Netmask (CIDR)
	--ipv6 	  <IPV6>		Virtual machine IPV6 Address 
	--vlan 	  <VLAN>		Specify a VLAN for eth0 (none by default) 

Advanced Disk options:	(in gigabytes)

	--root    <ROOT>		Give the / partition size
	--boot    <BOOT>		Give the /boot partition size (in megabytes)
	--swap	  <SWAP>		Give the SWAP partition size
	--tmp	  <TMP>			Give the /tmp partition size (in megabytes)
	--usr	  <USR>			Give the /usr partition size
	--var  	  <VAR>			Give the /var partition size
	--vlog 	  <VARLOG>		Give the /var/log partition size
	--plain				Create the VM with plain disk (no drbd)

Examples:

	./newVM.sh --name vm1 --disk 15G --ram 2G
	./newVM.sh --name vm2 --disk 15G --ram 2G --var 4G --ipv4 192.168.1.42

```

# Ganeti with Xen and Saltstack

This Ganeti configuration provide **Virtuals Machines on Debian 8 or Ubuntu 14.04** with debootstrap via an automated script and can make clone of VMs. 

![alt tag](http://blog.ouvrard.it/wp-content/uploads/2015/09/ganeti-banner1.jpg)

* **Documentation** <http://ganeti-xen-and-saltstack.readthedocs.org/en/master/>
* **Advanced Tutorial** (French) <http://blog.ouvrard.it/index.php/2015/09/12/cluster-ganeti-xen-saltstack/>


## Virtuals Machines configurations

* **Own /boot** virtual drive
* **Own kernel** 
* **LVM configuration** based  
* **SWAP partition**
* **Somes pkgs** like vim, htop, screen, git ...

## System requirement

* Debian 8 with Xen 4.4, Ganeti v2.12.4, DRBD 8.4.0 
* Volume Group **"vgganeti"**
* At least **2 nodes**
* The **"os"** folder in /usr/share/ganeti/
* The **"instance-debootstrap"** in /etc/ganeti/
* Folders **/srv/ganeti/** must exist

## Automated creation and cloning script

**NewVM.sh V0.1** - Create or Clone Virtuals Machines

A script for create and clone Virtuals Machines simply !

![alt tag](http://blog.ouvrard.it/wp-content/uploads/2015/09/newVM.jpg)

```
NewVM.sh v0.1 - Create or Clone Virtuals Machines
Author: Valentin OUVRARD
Usage: newVM.sh --name <NAME> --disk <DISK> --ram <RAM> 

### Options:

	--name    <VM_NAME>		New virtual machine hostname
	--disk    <DISK>		Disk size in gigabytes (G|g)
	--ram 	  <RAM>			Memory size in gigabytes (G|g)
	--vcpu    <VCPU>		Virtual CPU number
	--nodes   <NODES>		First node and second node(1st:2nd) 
	--clone   <CLONE>		Name of a VM to clone
	--variant <OS>			Choose between trusty and jessie (by default)
	--no-confirm			Disable VM creation confirmation

### Networking options:

	--ipv4 	  <IPV4>		Virtual machine IPV4 Address 
	--gw      <GW>			Virtual machine IPV4 Gateway
	--netmask <MASK>		Virtual machine IPV4 Netmask (CIDR)
	--ipv6 	  <IPV6>		Virtual machine IPV6 Address 
	--vlan 	  <VLAN>		Specify a VLAN for eth0 (none by default) 

### Advanced Disk options:	(in gigabytes)

	--root    <ROOT>		Give the / partition size
	--boot    <BOOT>		Give the /boot partition size (in megabytes)
	--swap	  <SWAP>		Give the SWAP partition size
	--tmp	  <TMP>			Give the /tmp partition size (in megabytes)
	--usr	  <USR>			Give the /usr partition size
	--var  	  <VAR>			Give the /var partition size
	--vlog 	  <VARLOG>		Give the /var/log partition size
	--plain				Create the VM with plain disk (no drbd)

### Examples:

	./newVM.sh --name vm1 --disk 15G --ram 2G
	./newVM.sh --name vm2 --disk 15G --ram 2G --var 4G --ipv4 192.168.1.42

```

## Contact

Ganeti-Github@ouvrard.it

@Valentin_NC


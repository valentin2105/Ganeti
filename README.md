# Ganeti-Configuration
Ganeti Cluster configurations for Xen hypervisor on Debian 8.

Requirements :

* Need dom0 with Volum Group "vgganeti"
* Need **DRBD8** working fine
* Requires at least 2 nodes
* "os" folder is for /usr/share/ganeti/os/
* "instance-debootstrap" is for /etc/ganeti-instance-debootstrap
* Folders /srv/ganeti/vminitlog and /srv/ganeti/vmcreation must exist
* **newVM.sh** is the automated VMs creation's script


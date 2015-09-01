# HOW-TO install this Ganeti configuration ?

You need at least of **two Debian Jessie** servers with clean install.                                                                                                         

## 1 - Xen Installation


```
apt-get -y install xen-linux-system xen-tools
dpkg-divert --divert /etc/grub.d/08_linux_xen --rename /etc/grub.d/20_linux_xen
update-grub
sed -i '/TOOLSTACK/s/=.*/=xl/' /etc/default/xen
reboot
```

**/etc/network/interfaces** :

```
auto  eth0
iface eth0 inet manual

auto xenbr0
iface xenbr0 inet static
  address   <Ip> 
  broadcast <Broadcast>
  netmask   <NetMask>
  gateway   <GWAddr>
  bridge_ports eth0
  bridge_stp off       # disable Spanning Tree Protocol
  bridge_waitport 0    # no delay unless port available
  bridge_fd 0          # no forwarding delay
```

**/etc/default/grub** :


```
GRUB_CMDLINE_XEN_DEFAULT="dom0_mem=1024M,max:1024M dom0_max_vcpus=1 dom0_vcpus_pin"
```

**/etc/default/xendomains** :

```
XENDOMAINS_SAVE=
```

## 2 - Ganeti Installation


```
mkdir /root/.ssh/
apt-get install ganeti2 ganeti-instance-debootstrap
cd /boot
ln -s vmlinuz-3.16* vmlinuz-3-xenU
ln -s initrd.img-3.16* initrd-3-xenU
```

**/var/lib/ganeti/config.data** :

```
"xen_cmd":"xl"},
"link":"xenbr0",
"initrd_path":"/boot/initrd-3-xenU",
"kernel_args":"ro",
"kernel_path":"/boot/vmlinuz-3-xenU",
"min disk-size":"150",
"master_netdev":"xenbr0",
"link":"xenbr0",
```


### DRBD :

```
apt-get install drbd8-utils
echo "options drbd minor_count=128 usermode_helper=/bin/true" \
   > /etc/modprobe.d/drbd.conf
echo "drbd" >> /etc/modules
depmod -a
modprobe drbd
service ganeti restart
```


**/etc/hosts** :

```
127.0.0.1	localhost
192.168.1.10 server.domain.you	server
192.168.1.11 cluster.domain.you	cluster
```

## 3 - Ganeti Cluster Init

```
gnt-cluster init --vg-name=vgganeti --master-netdev=xenbr0 cluster.domain.you
```

## 4 - Adding Ganeti Nodes


```
gnt-node add mynewnode.node
gnt-node list

Don't forget to deploy your configuration (or clone this repo) on all your nodes !

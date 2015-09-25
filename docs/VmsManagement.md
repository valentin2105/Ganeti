# How-To Manage the Cluster ?

* Migrate a VM to the secondary node
```
gnt-instance migrate <vm>
```

* Migrate the secondary disk to another node
```
gnt-instance migrate-disks <newnode> <vm>
```

* Cluster's Health verification
```
gnt-cluster verify-disk
gnt-cluster verify
```

* Migrate all the VM of a node & flag it offline
```
gnt-node migrate <node>
gnt-node failover <node>
# flag the node "offline"
gnt-node modify -C no -O yes <node>
```

* Change VM parameters
```
gnt-instance modify --backend-parameters=vcpus=4 <vm>
gnt-instance modify -B memory=4096M <vm>
```

* Extend a VM's disk
```
gnt-instance grow-disk <vm> <disk-number> <size-to-grow>
gnt-instance reboot <vm>
```

On the VM :
```
fdisk /dev/xvda (in my case)
l # List and note starting partition number
d # Delete the partition
n # New partition with same number and starting number
w # Write
reboot
pvresize /dev/xvda1
lvextend -L+<size-in-giga> /dev/vg<vm>/<lv-to-extend>
```
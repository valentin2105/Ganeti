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

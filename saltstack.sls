xen-linux-system:
  pkg:
    - latest

xen-tools:
  pkg:
    - latest

ganeti-instance-debootstrap:
  pkg:
    - latest

ganeti2:
  pkg:
    - latest

drbd8-utils:
  pkg:
    - latest

/usr/local/bin/newVM:
  file.managed:
    - source: salt://ganeti/newVM.sh
    - user: root
    - group: root
    - mode: 774

/srv/ganeti/vmcreation:
  file.directory:
    - user: root
    - group: root
    - mode: 755
    - makedirs: True

/srv/ganeti/vminitlog:
  file.directory:
    - user: root
    - group: root
    - mode: 755
    - makedirs: True

/usr/share/ganeti/os:
  file.recurse:
    - source: salt://ganeti/os
    - user: root
    - group: root
    - file_mode: '0755'
    - makedirs: true

/etc/ganeti/instance-debootstrap:
  file.recurse:
    - source: salt://ganeti/instance-debootstrap
    - user: root
    - group: root
    - makedirs: true


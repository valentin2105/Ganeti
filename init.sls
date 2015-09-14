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
    - source: salt://ganeti/latest/newVM.sh
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
    - source: salt://ganeti/latest/os
    - user: root
    - group: root
    - file_mode: '0755'
    - makedirs: true

/etc/ganeti/instance-debootstrap:
  file.recurse:
    - source: salt://ganeti/latest/instance-debootstrap
    - user: root
    - group: root
    - makedirs: true

/boot/initrd-3-xenU:
  file.symlink:
    - target: /boot/initrd.img-3.16.0-4-amd64

/boot/vmlinuz-3-xenU:
  file.symlink:
    - target: /boot/vmlinuz-3.16.0-4-amd64

grub-pc:
  pkg:
    - installed
    - require:
      - pkg: xen-linux-system

dpkg-divert --divert /etc/grub.d/08_linux_xen --rename /etc/grub.d/20_linux_xen:
  cmd:
    - wait
    - watch:
      - pkg: grub-pc

update-grub:
  cmd:
    - wait
    - watch:
      - cmd: dpkg-divert --divert /etc/grub.d/08_linux_xen --rename /etc/grub.d/20_linux_xen

#https://github.com/valentin2105/Ganeti.git:
#  git.latest:
#    - rev: master
#    - target: /srv/salt/ganeti/latest



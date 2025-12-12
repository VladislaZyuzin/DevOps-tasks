# /srv/salt/base/k3s/init.sls
install_dependencies:
  pkg.installed:
    - pkgs:
      - curl
      - socat
      - iptables
      - conntrack
      - bash
      - ca-certificates

disable_swap:
  cmd.run:
    - name: swapoff -a
    - unless: free | awk '/Swap/ {print $2}' | grep -q '^0$'

create_k3s_lv:
  cmd.run:
    - name: lvcreate -L 15G -n k3s-lv ubuntu-vg
    - unless: lvdisplay /dev/ubuntu-vg/k3s-lv
    - require:
      - pkg: install_dependencies

format_k3s_btrfs:
  cmd.run:
    - name: mkfs.btrfs -f /dev/ubuntu-vg/k3s-lv
    - unless: blkid /dev/ubuntu-vg/k3s-lv | grep btrfs
    - require:
      - cmd: create_k3s_lv

create_k3s_subvolume:
  cmd.run:
    - name: |
        mount /dev/ubuntu-vg/k3s-lv /mnt
        if [ ! -d /mnt/@k3s ]; then btrfs subvolume create /mnt/@k3s; fi
        umount /mnt
    - unless: btrfs subvolume list /mnt 2>/dev/null | grep -q '@k3s'
    - require:
      - cmd: format_k3s_btrfs

# ensure directories
/var/lib/rancher/k3s:
  file.directory:
    - user: root
    - group: root
    - mode: 755
    - makedirs: True

/etc/rancher/k3s:
  file.directory:
    - user: root
    - group: root
    - mode: 755
    - makedirs: True

# Create a systemd mount unit to ensure the storage mount happens BEFORE k3s
/etc/systemd/system/var-lib-rancher-k3s.mount:
  file.managed:
    - contents: |
        [Unit]
        Description=Mount for /var/lib/rancher/k3s
        # RequiredBy will ensure k3s waits for mount
        [Install]
        WantedBy=multi-user.target
        [Mount]
        What=/dev/ubuntu-vg/k3s-lv
        Where=/var/lib/rancher/k3s
        Type=btrfs
        Options=subvol=/@k3s
    - mode: '644'
    - user: root
    - group: root
    - require:
      - cmd: create_k3s_subvolume

# reload systemd if unit changed
systemd-daemon-reload:
  cmd.run:
    - name: systemctl daemon-reload
    - onchanges:
      - file: /etc/systemd/system/var-lib-rancher-k3s.mount

# Correct mount handling!
mount-k3s:
  mount.mounted:
    - name: /var/lib/rancher/k3s
    - device: /dev/ubuntu-vg/k3s-lv
    - fstype: btrfs
    - options: subvol=/@k3s
    - mkmnt: False
    - persist: True
    - require:
      - file: /etc/systemd/system/var-lib-rancher-k3s.mount
      - cmd: systemd-daemon-reload

# systemd mount unit сервис
var-lib-rancher-k3s.mount:
  service.running:
    - enable: true
    - require:
      - mount: mount-k3s

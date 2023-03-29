# stands-03-lvm

Стенд для домашнего занятия "Файловые системы и LVM"

создание нового рут диска

```
vagrant up
vagrant ssh
[vagrant@lvm ~]$ disk=$(lsblk -nl -o NAME,SIZE | awk  '{gsub(/G/,"", $2); if ($2 == 10) print $1}')
[vagrant@lvm ~]$ echo $disk
sdb
[vagrant@lvm ~]$ disks=$(lsblk -nl -o NAME,SIZE | awk  '{gsub(/G/,"", $2); if ($2 == 1) print $1}' | awk '{if ($1 ~ /[^0-9]$/) printf "/dev/"$1" "}')
[vagrant@lvm ~]$ echo $disks
/dev/sdd /dev/sde
[vagrant@lvm ~]$ sudo pvcreate /dev/$disk
  Physical volume "/dev/sdb" successfully created.
[vagrant@lvm ~]$ sudo  vgcreate vg_root /dev/$disk
  Volume group "vg_root" successfully created
[vagrant@lvm ~]$ sudo lvcreate -n lv_root -l +100%FREE /dev/vg_root
  Logical volume "lv_root" created.
[vagrant@lvm ~]$ sudo mkfs.xfs /dev/vg_root/lv_root
meta-data=/dev/vg_root/lv_root   isize=512    agcount=4, agsize=655104 blks
         =                       sectsz=512   attr=2, projid32bit=1
         =                       crc=1        finobt=0, sparse=0
data     =                       bsize=4096   blocks=2620416, imaxpct=25
         =                       sunit=0      swidth=0 blks
naming   =version 2              bsize=4096   ascii-ci=0 ftype=1
log      =internal log           bsize=4096   blocks=2560, version=2
         =                       sectsz=512   sunit=0 blks, lazy-count=1
realtime =none                   extsz=4096   blocks=0, rtextents=0
[vagrant@lvm ~]$ sudo mount /dev/vg_root/lv_root /mnt

[vagrant@lvm ~]$ sudo xfsdump -J - /dev/VolGroup00/LogVol00 | sudo xfsrestore -J - /mnt
xfsdump: using file dump (drive_simple) strategy
xfsdump: version 3.1.7 (dump format 3.0)
xfsdump: level 0 dump of lvm:/
xfsdump: dump date: Sun Mar 26 20:43:42 2023
xfsdump: session id: dd20677d-11bb-479a-a7a2-a5668c06e9f5
...
xfsdump: Dump Status: SUCCESS
xfsrestore: restore complete: 44 seconds elapsed
xfsrestore: Restore Status: SUCCESS

[vagrant@lvm ~]$ ls /mnt
bin  boot  dev  etc  home  lib  lib64  media  mnt  opt  proc  root  run  sbin  srv  sys  tmp  usr  vagrant  var

[vagrant@lvm ~]$ for i in /proc/ /sys/ /dev/ /run/ /boot/; do sudo mount --bind $i /mnt/$i; done

[vagrant@lvm ~]$ sudo chroot /mnt/
[root@lvm /]# 

[root@lvm /]# grub2-mkconfig -o /boot/grub2/grub.cfg
Generating grub configuration file ...
Found linux image: /boot/vmlinuz-3.10.0-862.2.3.el7.x86_64
Found initrd image: /boot/initramfs-3.10.0-862.2.3.el7.x86_64.img
done

[root@lvm /]# cd /boot ; for i in `ls initramfs-*img`; do dracut -v $i `echo $i|sed "s/initramfs-//g;s/.img//g"` --force; done
...
*** Creating image file ***
*** Creating image file done ***
*** Creating initramfs image file '/boot/initramfs-3.10.0-862.2.3.el7.x86_64.img' done ***

[root@lvm boot]# sed -i 's/rd.lvm.lv\=VolGroup00\/LogVol00/rd.lvm.lv=vg_root\/lv_root/' /boot/grub2/grub.cfg
[root@lvm boot]# cat /boot/grub2/grub.cfg | grep vg_root\/lv_root
        linux16 /vmlinuz-3.10.0-862.2.3.el7.x86_64 root=/dev/mapper/vg_root-lv_root ro no_timer_check console=tty0 console=ttyS0,115200n8 net.ifnames=0 biosdevname=0 elevator=noop crashkernel=auto rd.lvm.lv=vg_root/lv_root rd.lvm.lv=VolGroup00/LogVol01 rhgb quiet 

[root@lvm boot]# exit
exit
[vagrant@lvm ~]$ sudo systemctl reboot


```

обрезаем размер

```
vagrant ssh
Last login: Sun Mar 26 20:06:44 2023 from 10.0.2.2
[vagrant@lvm ~]$ lsblk
NAME                    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                       8:0    0   40G  0 disk 
├─sda1                    8:1    0    1M  0 part 
├─sda2                    8:2    0    1G  0 part /boot
└─sda3                    8:3    0   39G  0 part 
  ├─VolGroup00-LogVol01 253:1    0  1.5G  0 lvm  [SWAP]
  └─VolGroup00-LogVol00 253:2    0 37.5G  0 lvm  
sdb                       8:16   0   10G  0 disk 
└─vg_root-lv_root       253:0    0   10G  0 lvm  /
sdc                       8:32   0    2G  0 disk 
sdd                       8:48   0    1G  0 disk 
sde                       8:64   0    1G  0 disk 

[vagrant@lvm ~]$ sudo lvremove /dev/VolGroup00/LogVol00 -f
  Logical volume "LogVol00" successfully removed
[vagrant@lvm ~]$ sudo lvcreate -n VolGroup00/LogVol00 -L 8G /dev/VolGroup00 -y
  Wiping xfs signature on /dev/VolGroup00/LogVol00.
  Logical volume "LogVol00" created.
[vagrant@lvm ~]$ sudo mkfs.xfs /dev/VolGroup00/LogVol00
meta-data=/dev/VolGroup00/LogVol00 isize=512    agcount=4, agsize=524288 blks
         =                       sectsz=512   attr=2, projid32bit=1
         =                       crc=1        finobt=0, sparse=0
data     =                       bsize=4096   blocks=2097152, imaxpct=25
         =                       sunit=0      swidth=0 blks
naming   =version 2              bsize=4096   ascii-ci=0 ftype=1
log      =internal log           bsize=4096   blocks=2560, version=2
         =                       sectsz=512   sunit=0 blks, lazy-count=1
realtime =none                   extsz=4096   blocks=0, rtextents=0

[vagrant@lvm ~]$ sudo mount /dev/VolGroup00/LogVol00 /mnt

[vagrant@lvm ~]$ sudo xfsdump -J - /dev/vg_root/lv_root | sudo xfsrestore -J - /mnt
xfsrestore: using file dump (drive_simple) strategy
...
xfsdump: dump complete: 50 seconds elapsed
xfsdump: Dump Status: SUCCESS
xfsrestore: restore complete: 50 seconds elapsed
xfsrestore: Restore Status: SUCCESS

[vagrant@lvm ~]$ for i in /proc/ /sys/ /dev/ /run/ /boot/; do sudo mount --bind $i /mnt/$i; done
[vagrant@lvm ~]$ sudo chroot /mnt/
[root@lvm /]# 

[root@lvm /]# grub2-mkconfig -o /boot/grub2/grub.cfg
Generating grub configuration file ...
Found linux image: /boot/vmlinuz-3.10.0-862.2.3.el7.x86_64
Found initrd image: /boot/initramfs-3.10.0-862.2.3.el7.x86_64.img
done

[root@lvm /]# cd /boot ; for i in `ls initramfs-*img`; do dracut -v $i `echo $i|sed "s/initramfs-//g;s/.img//g"` --force; done
Executing: /sbin/dracut -v initramfs-3.10.0-862.2.3.el7.x86_64.img 3.10.0-862.2.3.el7.x86_64 --force
...
*** Store current command line parameters ***
*** Creating image file ***
*** Creating image file done ***
*** Creating initramfs image file '/boot/initramfs-3.10.0-862.2.3.el7.x86_64.img' done ***

```
новый var, оставаясь в chroot

```
[root@lvm boot]# disks=$(lsblk -nl -o NAME,SIZE | awk  '{gsub(/G/,"", $2); if ($2 == 1) print $1}' | awk '{if ($1 ~ /[^0-9]$/) printf "/dev/"$1" "}')
[root@lvm boot]# echo $disks
/dev/sdd /dev/sde
[root@lvm boot]# pvcreate $disks
  Physical volume "/dev/sdd" successfully created.
  Physical volume "/dev/sde" successfully created.
[root@lvm boot]# vgcreate vg_var $disks
  Volume group "vg_var" successfully created
[root@lvm boot]# vgdisplay vg_var
  --- Volume group ---
  VG Name               vg_var
  System ID             
  Format                lvm2
  Metadata Areas        2
  Metadata Sequence No  1
  VG Access             read/write
  VG Status             resizable
  MAX LV                0
  Cur LV                0
  Open LV               0
  Max PV                0
  Cur PV                2
  Act PV                2
  VG Size               1.99 GiB
  PE Size               4.00 MiB
  Total PE              510
  Alloc PE / Size       0 / 0   
  Free  PE / Size       510 / 1.99 GiB
  VG UUID               6PD6qL-oaQ0-4E9Y-Y0uK-wINx-U9Qr-Y9M4TX

[root@lvm boot]# lvcreate -L 950M -m1 -n lv_var vg_var
  Rounding up size to full physical extent 952.00 MiB
  Logical volume "lv_var" created.
[root@lvm boot]# mkfs.ext4 /dev/vg_var/lv_var
mke2fs 1.42.9 (28-Dec-2013)
...
Allocating group tables: done                            
Writing inode tables: done                            
Creating journal (4096 blocks): done
Writing superblocks and filesystem accounting information: done

[root@lvm boot]# mount /dev/vg_var/lv_var /mnt
[root@lvm boot]# cp -aR /var/* /mnt/
[root@lvm boot]# umount /mnt
[root@lvm boot]# mount /dev/vg_var/lv_var /var
[root@lvm boot]# echo "`blkid | grep var: | awk '{print $2}'` /var ext4 defaults 0 0" | tee -a /etc/fstab
UUID="2b3dfd06-260e-4dbb-9511-b32dac9c9a73" /var ext4 defaults 0 0
[root@lvm boot]# cat /etc/fstab

#
# /etc/fstab
# Created by anaconda on Sat May 12 18:50:26 2018
#
# Accessible filesystems, by reference, are maintained under '/dev/disk'
# See man pages fstab(5), findfs(8), mount(8) and/or blkid(8) for more info
#
/dev/mapper/VolGroup00-LogVol00 /                       xfs     defaults        0 0
UUID=570897ca-e759-4c81-90cf-389da6eee4cc /boot                   xfs     defaults        0 0
/dev/mapper/VolGroup00-LogVol01 swap                    swap    defaults        0 0
#VAGRANT-BEGIN
# The contents below are automatically generated by Vagrant. Do not modify.
#VAGRANT-END
UUID="2b3dfd06-260e-4dbb-9511-b32dac9c9a73" /var ext4 defaults 0 0
exit
reboot

[vagrant@lvm ~]$ lsblk
NAME                     MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                        8:0    0   40G  0 disk 
├─sda1                     8:1    0    1M  0 part 
├─sda2                     8:2    0    1G  0 part /boot
└─sda3                     8:3    0   39G  0 part 
  ├─VolGroup00-LogVol00  253:0    0    8G  0 lvm  /
  └─VolGroup00-LogVol01  253:1    0  1.5G  0 lvm  [SWAP]
sdb                        8:16   0   10G  0 disk 
└─vg_root-lv_root        253:2    0   10G  0 lvm  
sdc                        8:32   0    2G  0 disk 
sdd                        8:48   0    1G  0 disk 
├─vg_var-lv_var_rmeta_0  253:3    0    4M  0 lvm  
│ └─vg_var-lv_var        253:7    0  952M  0 lvm  /var
└─vg_var-lv_var_rimage_0 253:4    0  952M  0 lvm  
  └─vg_var-lv_var        253:7    0  952M  0 lvm  /var
sde                        8:64   0    1G  0 disk 
├─vg_var-lv_var_rmeta_1  253:5    0    4M  0 lvm  
│ └─vg_var-lv_var        253:7    0  952M  0 lvm  /var
└─vg_var-lv_var_rimage_1 253:6    0  952M  0 lvm  
  └─vg_var-lv_var        253:7    0  952M  0 lvm  /var

[vagrant@lvm ~]$ sudo lvremove /dev/vg_root/lv_root
Do you really want to remove active logical volume vg_root/lv_root? [y/n]: y
  Logical volume "lv_root" successfully removed
[vagrant@lvm ~]$ sudo vgremove /dev/vg_root
  Volume group "vg_root" successfully removed
```

новый home
```
[vagrant@lvm ~]$ sudo lvcreate -n LogVol_Home -L 2G /dev/VolGroup00
  Logical volume "LogVol_Home" created.
[vagrant@lvm ~]$ sudo mkfs.xfs /dev/VolGroup00/LogVol_Home
meta-data=/dev/VolGroup00/LogVol_Home isize=512    agcount=4, agsize=131072 blks
         =                       sectsz=512   attr=2, projid32bit=1
         =                       crc=1        finobt=0, sparse=0
data     =                       bsize=4096   blocks=524288, imaxpct=25
         =                       sunit=0      swidth=0 blks
naming   =version 2              bsize=4096   ascii-ci=0 ftype=1
log      =internal log           bsize=4096   blocks=2560, version=2
         =                       sectsz=512   sunit=0 blks, lazy-count=1
realtime =none                   extsz=4096   blocks=0, rtextents=0
[vagrant@lvm ~]$ sudo mount /dev/VolGroup00/LogVol_Home /mnt/
[vagrant@lvm ~]$ sudo cp -aR /home/* /mnt/
[vagrant@lvm ~]$ ls /mnt/
vagrant
[vagrant@lvm ~]$ sudo rm -rf /home/*
[vagrant@lvm ~]$ sudo umount /mnt
[vagrant@lvm ~]$ sudo mount /dev/VolGroup00/LogVol_Home /home/

[vagrant@lvm ~]$ echo `lsblk -l -o name,uuid | grep Home | awk -v dq=\" '{printf "UUID="dq$2dq" /home xfs defaults 0 0"}'` | sudo tee -a /etc/fstab
UUID="98567513-d524-4b11-a717-7499d1240e6e" /home xfs defaults 0 0
[vagrant@lvm ~]$ cat /etc/fstab 

#
# /etc/fstab
# Created by anaconda on Sat May 12 18:50:26 2018
#
# Accessible filesystems, by reference, are maintained under '/dev/disk'
# See man pages fstab(5), findfs(8), mount(8) and/or blkid(8) for more info
#
/dev/mapper/VolGroup00-LogVol00 /                       xfs     defaults        0 0
UUID=570897ca-e759-4c81-90cf-389da6eee4cc /boot                   xfs     defaults        0 0
/dev/mapper/VolGroup00-LogVol01 swap                    swap    defaults        0 0
#VAGRANT-BEGIN
# The contents below are automatically generated by Vagrant. Do not modify.
#VAGRANT-END
UUID="2b3dfd06-260e-4dbb-9511-b32dac9c9a73" /var ext4 defaults 0 0
UUID="98567513-d524-4b11-a717-7499d1240e6e" /home xfs defaults 0 0

```
создание снапшота

```
sudo touch /home/file{1..20}
vagrant@lvm ~]$ sudo lvcreate -L 100MB -s -n home_snap /dev/VolGroup00/LogVol_Home
  Rounding up size to full physical extent 128.00 MiB
  Logical volume "home_snap" created.
sudo rm -f /home/file{11..20}

vagrant@lvm ~]$ sudo umount /home
[vagrant@lvm ~]$ sudo lvconvert --merge /dev/VolGroup00/home_snap
  Merging of volume VolGroup00/home_snap started.
  VolGroup00/LogVol_Home: Merged: 100.00%

[vagrant@lvm ~]$ sudo mount /home
[vagrant@lvm ~]$ ls /home
file1  file10  file11  file12  file13  file14  file15  file16  file17  file18  file19  file2  file20  file3  file4  file5  file6  file7  file8  file9  vagrant
```
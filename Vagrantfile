# -*- mode: ruby -*-
# vim: set ft=ruby :
home = ENV['HOME']
ENV["LC_ALL"] = "en_US.UTF-8"

MACHINES = {
  :lvm => {
        :box_name => "centos/7",
        :box_version => "1804.02",
        :ip_addr => '192.168.56.101',
    :disks => {
        :sata1 => {
            :dfile => home + '/VirtualBox VMs/sata1.vdi',
            :size => 10240,
            :port => 1
        },
        :sata2 => {
            :dfile => home + '/VirtualBox VMs/sata2.vdi',
            :size => 2048, # Megabytes
            :port => 2
        },
        :sata3 => {
            :dfile => home + '/VirtualBox VMs/sata3.vdi',
            :size => 1024, # Megabytes
            :port => 3
        },
        :sata4 => {
            :dfile => home + '/VirtualBox VMs/sata4.vdi',
            :size => 1024,
            :port => 4
        }
    }
  },
}

Vagrant.configure("2") do |config|

    config.vm.box_version = "1804.02"
    MACHINES.each do |boxname, boxconfig|
  
        config.vm.define boxname do |box|
  
            box.vm.box = boxconfig[:box_name]
            box.vm.host_name = boxname.to_s
  
            #box.vm.network "forwarded_port", guest: 3260, host: 3260+offset
  
            box.vm.network "private_network", ip: boxconfig[:ip_addr]
  
            box.vm.provider :virtualbox do |vb|
                    vb.customize ["modifyvm", :id, "--memory", "256"]
                    needsController = false
            boxconfig[:disks].each do |dname, dconf|
                unless File.exist?(dconf[:dfile])
                  vb.customize ['createhd', '--filename', dconf[:dfile], '--variant', 'Fixed', '--size', dconf[:size]]
                                  needsController =  true
                            end
  
            end
                    if needsController == true
                       vb.customize ["storagectl", :id, "--name", "SATA", "--add", "sata" ]
                       boxconfig[:disks].each do |dname, dconf|
                           vb.customize ['storageattach', :id,  '--storagectl', 'SATA', '--port', dconf[:port], '--device', 0, '--type', 'hdd', '--medium', dconf[:dfile]]
                       end
                    end
            end
  
        box.vm.provision "shell", inline: <<-SHELL
            mkdir -p ~root/.ssh
            cp ~vagrant/.ssh/auth* ~root/.ssh
            yum install -y mdadm smartmontools hdparm gdisk xfsdump
          SHELL
        box.vm.provision "file", source: "./get_disk_for_root.sh", destination: "./get_disk_for_root.sh"
        box.vm.provision "file", source: "./get_disks_no_root.sh", destination: "./get_disks_no_root.sh"
        box.vm.provision "shell", inline: <<-SHELL
            chmod +x ./get_disks_no_root.sh
            chmod +x ./get_disk_for_root.sh
            disk=`/bin/bash ./get_disk_for_root.sh`
            pvcreate /dev/$disk
            vgcreate /vg_toor /dev/$disk
            lvcreate -n lv_root -l +100%FREE /dev/vg_root
            mkfs.xfs /dev/vg_root/lv_root
            mount /dev/vg_root/lv_root /mnt
            xfsdump -J - /dev/VolGroup00/LogVol00 | xfsrestore -J - /mnt
            ls /mnt
            for i in /proc/ /sys/ /dev/ /run/ /boot/; do mount --bind $i /mnt/$i; done
            chroot /mnt/
            grub2-mkconfig -o /boot/grub2/grub.cfg
            cd /boot ; for i in `ls initramfs-*img`; do dracut -v $i `echo $i|sed "s/initramfs-//g;s/.img//g"` --force; done
            sed -i "s/rd.lvm.lv=VolGroup00\/LogVol00/rd.lvm.lv=vg_root\/lv_root/" /boot/grub2/grub.cfg
          SHELL
        config.vm.provision "shell", reboot: true
        box.vm.provision "shell", inline: <<-SHELL
            lsblk
            lvremove /dev/VolGroup00/LogVol00
            lvcreate -n VolGroup00/LogVol00 -L 8G /dev/VolGroup00
            mkfs.xfs /dev/VolGroup00/LogVol00
            mount /dev/VolGroup00/LogVol00 /mnt
            xfsdump -J - /dev/vg_root/lv_root | xfsrestore -J - /mnt
            for i in /proc/ /sys/ /dev/ /run/ /boot/; do mount --bind $i /mnt/$i; done
            chroot /mnt/
            grub2-mkconfig -o /boot/grub2/grub.cfg
            cd /boot ; for i in `ls initramfs-*img`; do dracut -v $i `echo $i|sed "s/initramfs-//g;s/.img//g"` --force; done
            disks=`/bin/bash ./get_disk_for_mirror.sh`
            pvcreate $disks
            vgcreate vg_var $disks
            lvcreate -L 950M -m1 -n lv_var vg_var
            mkfs.ext4 /dev/vg_var/lv_var
            mount /dev/vg_var/lv_var /mnt
            cp -aR /var/* /mnt/
            mkdir /tmp/oldvar && mv /var/* /tmp/oldvar
            umount /mnt
            mount /dev/vg_var/lv_var /var
            echo "`blkid | grep var: | awk '{print $2}'` /var ext4 defaults 0 0" | tee -a /etc/fstab
            
          SHELL
        end
    end
  end
  

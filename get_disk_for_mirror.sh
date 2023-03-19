#! /bin/bash
disks=$(lsblk -nl -o NAME,SIZE | awk  '{gsub(/G/,"", $2); if ($2 == 1) print $1}' | awk '{if ($1 ~ /[^0-9]$/) printf "/dev/"$1" "}')
echo $disks

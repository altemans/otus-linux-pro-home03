#! /bin/bash
disk=$(lsblk -nl -o NAME,SIZE | awk  '{gsub(/G/,"", $2); if ($2 == 10) print $1}')
echo $disk

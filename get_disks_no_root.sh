#! /bin/bash

readarray -t arr < <( lsblk -n -l -o NAME )

declare -a del

for i in "${arr[@]}"
do
        if [[ $i =~ [0-9]$ ]]
        then
                del+=($i)
                str="$(echo $i | sed -e 's/[0-9]\+$//')"
                del+=($str)
        fi
done

for d in "${del[@]}"
do
        for a in "${!arr[@]}"
        do
                if [[ ${arr[$a]} == $d ]]
                then
                        unset 'arr[a]'
                fi
        done
done

for i in "${arr[@]}"
do
        echo $i
done


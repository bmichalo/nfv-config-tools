#!/bin/bash

cpu_list=$1
pmd_cpu_mask=0
for cpu in `echo $cpu_list | sed -e 's/,/ /'g`; do
        bc_math="$bc_math + 2^$cpu"
done
bc_math=`echo $bc_math | sed -e 's/\+//'`
pmd_cpu_mask=`echo "obase=16; $bc_math" | bc`
echo "$pmd_cpu_mask"


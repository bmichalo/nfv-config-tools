#!/bin/bash

testvar=1

function convert_bitmask_to_list() {
	# converts a range of cpus, like "10111" to 1,2,3,5"
	local bitmask=$1
	local cpu=0
	local bit=""
	while [ "$bitmask" != "" ]; do
		bit=${bitmask: -1}
		if [ "$bit" == "1" ]; then
			cpu_list="$cpu_list,$cpu"
		fi
		bitmask=`echo $bitmask | sed -e 's/[0-1]$//'`
		((cpu++))
	done
	cpu_list=`echo $cpu_list | sed -e 's/,//'`
	echo "$cpu_list"
}

function convert_list_to_bitmask() {
	# converts a range of cpus, like "1-3,5" to a bitmask, like "10111"
	local cpu_list=$1
	local cpu=""
	local bitmask=0
	for cpu in `echo "$cpu_list" | sed -e 's/,/ /g'`; do
		bitmask=`echo "$bitmask + (2^$cpu)" | bc`
		echo "cpu = $cpu, bitmask = $bitmask"
	done
	bitmask=`echo "obase=2; $bitmask" | bc`
	echo "$bitmask"
}


test_bitmask="1011"
echo "test_bitmask= $test_bitmask"

convert_bitmask_to_list $test_bitmask

test_list="0,1,3"
echo "test_list= $test_list"

convert_list_to_bitmask $test_list






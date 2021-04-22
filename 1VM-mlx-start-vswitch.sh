#!/bin/bash

# This script will start a vswitch of your choice, doing the following:
# -use multi-queue (for DPDK)
# -bind DPDK PMDs to optimal CPUs
# -for pvp topologies, provide a list of optimal cpus available for the VM
# configure an overlay network such as VxLAN

# The following features are not implemented but would be nice to add:
# -for ovs, configure x flows
# -for a router, configure x routes
# -configure VLAN
# -configure a firewall



###############################################################################
# Default values
###############################################################################

#
# topology:
#
#	Two physical devices on one switch.  'topology' is desctibed by a list 
#	of 1 or more switches separated by commas.  The supported interfaces on 
#	a switch are:
#
#	p:		A physical port.  This may include host physical ports, or 
#			SR-IOV PCIe or virtio devices seen within a guest
#
#	v:		A virtio-net interface like dpdkvhostuser or vhost-net (depending on dataplane)
#
topology="pp"	


#
# queues:
#
#	Number of queue-pairs (rx/tx) to use per device	
#
queues=1


#
# switch:
#
#	Type of forwarding engine to be used on the DUT topology.
#	Currently supported switch types:
#
#	testpmd:	DPDK's L2 forwarding test program
#
#	ovs:		Open vSwitch
#
#	linuxbridge:	L2 kernel networking stack
#
#	linuxrouter:	L3 kernel networking stack
#
switch="ovs"


#
# switch_mode:
#
# 	Configuration of the $switch in use.  Currently supported list depends on $switch.
#	Modes support by switch type are:
#
#	linuxbridge:	default
#
#	linuxrouter:	default
#
#	testpmd:	default
#
#	ovs:		default/direct-flow-rule, l2-bridge
#
switch_mode="default"


#
# numa_mode:
#
#	'numa_mode' is for DPDK vswitches only.
#
#	strict:		All PMD threads for all phys and virt devices use memory and cpu only 
#			from the numa node where the physical adapters are located.
#			This implies the VMs must be on the same node.
#
#	preferred:	Just like 'strict', but the vswitch also has memory and in some cases 
#			uses cpu from the non-local NUMA nodes.
#
#	cross:		The PMD threads for all phys devices use memory and cpu from
#			the local NUMA node, but VMs are present on another NUMA node,
#			and so the PMD threads for those virt devices are also on
#			another NUMA node.
#
numa_mode="strict" 


#
# overlay_network:
#
#	Currently supported are the following overlay network types:
#
#	none:		For all switch types
#
#	vxlan:		For linuxbridge and ovs
#
overlay_network="none" 


#
# ovs_build:
#
#	Specify to use OVS either from:
#
#	rpm:		Pre-built package
#
#	src:		Manually built and installed
#
ovs_build="rpm"


#
# dpdk_nic_kmod:
#
#	The kernel module to use when assigning an Intel network device to a 
#	userspace program (DPDK application)
#
dpdk_nic_kmod="vfio-pci"


#
# dataplane:
#
#	The type of forwarding plane to be used on the DUT.
#
#	dpdk:			Intel's Data Plane Development Kit
#
#	kernel:			The Linux kernel's networking stack
#
#	kernel-hw-offload:	OVS dataplane handled in NIC hardware
#
dataplane="dpdk"


#
# use_ht:
#
#	Specify if hyperthreaded processors should be used or not for
#	forwading packets
#
#	y:			yes
#
#	n:			no
#
use_ht="y"


#
# testpmd_path:
#
#	Specifies the location of DPDK's L2 forwarding program testpmd
#
testpmd_path="/usr/bin/testpmd"


#
# supported_switches:
#
#	The list of supported switches that may be used upon the DUT
#
supported_switches="linuxbridge ovs linuxrouter testpmd"


#
# pci_descriptors:
#
#	Sets the DPDK physical port queue size.
#	NOTE:  Also used to set testpmd rxd/txd ring size.  We may want to make this separate
#       from the DPDK physical port descriptor programming.
#
#	Size should probably not be larger than 2048.  Using a size of 4096 may have a negative 
#	impact upon performance.  See:  http://docs.openvswitch.org/en/latest/intro/install/dpdk/
#	
pci_descriptors=2048


#
# pci_desc_ovveride:
#
#	Used to override the desriptor size of any of the vswitches here.  
#
pci_desc_override="" 


#
# vhu_desc_override:
#
#	Use to override the desriptor size of any of the vswitches here. 
#	NOTE:  This needs to be fixed given we also have pci_desc_override as
#	well as pci_descriptors all doing similar things
#
vhu_desc_override=""


#
# cpu_usage_file:
#
#	After the vswitch is started, it must decide which host cpus the VM uses.  
#	The file $cpu_usage_file, defaulting to /var/log/isolated_cpu_usage.conf, 
#	shows which cpus are used for the vswitch and which cpus are left for the 
#	VM.  The shell script can be used virt-pin.sh to pin the vcpus. It will read 
#	the /var/log/isolated_cpu_usage.conf ($cpu_usage_file) file to make sure 
#	it does not use cpus already used by the vswitch.
#
cpu_usage_file="/var/log/isolated_cpu_usage.conf"


#
# vhost_affinity:
#
# 	NOTE:  This is not working yet 
#
# 	local: the vhost interface will reside in the same node as the physical interface on the same bridge
#
#  	remote: The vhost interface will reside in remote node as the physical interface on the same bridge
#
#	This locality is an assumption and must match what was configured when VMs are created
#
vhost_affinity="local"


#
# no_kill:
#
# Don't kill all OVS sessions.  However, any process 
# owning a DPDK device will still be killed
#
no_kill=0


function log() {
	echo -e "start-vswitch: LINENO: ${BASH_LINENO[0]} $1"
}

function exit_error() {
	local error_message=$1
	local error_code=$2
	if [ -z "$error_code"] ; then
		error_code=1
	fi
	log "ERROR: $error_message"
	exit $error_code
}

function init_cpu_usage_file() {
	local opt
	local var
	local val
	local cpu
	local non_iso_cpu_bitmask
	local non_iso_cpu_hexmask
	local non_iso_cpu_list
	local online_cpu_range
	local online_cpu_list
	local iso_cpu_list
	local iso_cpus
	/bin/rm -f $cpu_usage_file
	touch $cpu_usage_file
	iso_cpus=$(cat /sys/devices/system/cpu/isolated)
	if [ -n "${iso_cpus}" ]; then
		iso_cpu_list=$(convert_number_range "${iso_cpus}")
	else
		for opt in `cat /proc/cmdline`; do
			var=`echo $opt | awk -F= '{print $1}'`
			if [ $var == "tuned.non_isolcpus" ]; then
				val=`echo $opt | awk -F= '{print $2}'`
				non_iso_cpu_hexmask=`echo "$val" | sed -e s/,//g | tr a-f A-F`
				non_iso_cpu_bitmask=`echo "ibase=16; obase=2; $non_iso_cpu_hexmask" | bc`
				non_iso_cpu_list=`convert_bitmask_to_list $non_iso_cpu_bitmask`
				online_cpu_range=`cat /sys/devices/system/cpu/online`
				online_cpu_list=`convert_number_range $online_cpu_range`
				iso_cpu_list=`sub_from_list $online_cpu_list $non_iso_cpu_list`
				break
			fi
		done
	fi
	for cpu in `echo $iso_cpu_list | sed -e 's/,/ /g'`; do
		echo "$cpu:" >>$cpu_usage_file
	done
	echo "$iso_cpu_list"
}

function get_iso_cpus() {
	local cpu
	local list
	for cpu in `grep -E "[0-9]+:$" $cpu_usage_file | awk -F: '{print $1}'`; do
		list="$list,$cpu"
	done
	list=`echo $list | sed -e 's/^,//'`
	echo "$list"
}

function log_cpu_usage() {
	# $1 = list of cpus, no spaces: 1,2,3
	local cpulist=$1
	local usage=$2
	local cpu
	if [ "$usage" == "" ]; then
		exit_error "a string describing the usage must accompany the cpu list"
	fi
	for cpu in `echo $cpulist | sed -e 's/,/ /g'`; do
		if grep -q -E "^$cpu:" $cpu_usage_file; then
			if grep -q -E "^$cpu:.+" $cpu_usage_file; then
				# $cpu is already used
				return 1
			else
				sed -i -e s/^$cpu:$/$cpu:$usage/ $cpu_usage_file
			fi
		else
			# $cpu is not in $cpu_usage_file
			return 1
		fi
	done
	return 0
}

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
	done
	bitmask=`echo "obase=2; $bitmask" | bc`
	echo "$bitmask"
}

function convert_number_range() {
	# converts a range of cpus, like "1-3,5" to a list, like "1,2,3,5"
	local cpu_range=$1
	local cpus_list=""
	local cpus=""
	for cpus in `echo "$cpu_range" | sed -e 's/,/ /g'`; do
		if echo "$cpus" | grep -q -- "-"; then
			cpus=`echo $cpus | sed -e 's/-/ /'`
			cpus=`seq $cpus | sed -e 's/ /,/g'`
		fi
		for cpu in $cpus; do
			cpus_list="$cpus_list,$cpu"
		done
	done
	cpus_list=`echo $cpus_list | sed -e 's/^,//'`
	echo "$cpus_list"
}

function node_cpus_list() {
	local node_id=$1
	local cpu_range=`cat /sys/devices/system/node/node$node_id/cpulist`
	local cpu_list=`convert_number_range $cpu_range`
	echo "$cpu_list"
}

function add_to_list() {
	local list=$1
	local add_list=$2
	local list_set
	local i
	# for easier manipulation, convert the current_elements string to a associative array
	for i in `echo $list | sed -e 's/,/ /g'`; do
		list_set["$i"]=1
	done
	list=""
	for i in `echo $add_list | sed -e 's/,/ /g'`; do
		list_set["$i"]=1
	done
	for i in "${!list_set[@]}"; do
		list="$list,$i"
	done
	list=`echo $list | sed -e 's/^,//'`
	echo "$list"
}

function sub_from_list () {
	local list=$1
	local sub_list=$2
	local list_set
	local i
	# for easier manipulation, convert the current_elements string to a associative array
	for i in `echo $list | sed -e 's/,/ /g'`; do
		list_set["$i"]=1
	done
	list=""
	for i in `echo $sub_list | sed -e 's/,/ /g'`; do
		unset list_set[$i]
	done
	for i in "${!list_set[@]}"; do
		list="$list,$i"
	done
	list=`echo $list | sed -e 's/^,//'`
	echo "$list"
}

function intersect_cpus() {
	local cpus_a=$1
	local cpus_b=$2
	local cpu_set_a
	local cpu_set_b
	local intersect_cpu_list=""
	# for easier manipulation, convert the cpu list strings to a associative array
	for i in `echo $cpus_a | sed -e 's/,/ /g'`; do
		cpu_set_a["$i"]=1
	done
	for i in `echo $cpus_b | sed -e 's/,/ /g'`; do
		cpu_set_b["$i"]=1
	done
	for cpu in "${!cpu_set_a[@]}"; do
		if [ "${cpu_set_b[$cpu]}" != "" ]; then
			intersect_cpu_list="$intersect_cpu_list,$cpu"
		fi
	done
	intersect_cpu_list=`echo $intersect_cpu_list | sed -e s/^,//`
	echo "$intersect_cpu_list"
}

function remove_sibling_cpus() {
	local cpu_range=$1
	local cpu_list=`convert_number_range $cpu_range`
	local no_sibling_list=""
	local socket_core_id_list="," #commas on front and end of list and in between IDs for easier grepping
	while [ ! -z "$cpu_list" ]; do
		this_cpu=`echo $cpu_list | awk -F, '{print $1}'`
		cpu_list=`echo $cpu_list | sed -e s/^$this_cpu//`
		cpu_list=`echo $cpu_list | sed -e s/^,//`
		core=`cat /sys/devices/system/cpu/cpu$this_cpu/topology/core_id`
		socket=`cat /sys/devices/system/cpu/cpu$this_cpu/topology/physical_package_id`
		socket_core_id="$socket:$core"
		if echo $socket_core_id_list | grep -q ",$socket_core_id,"; then
			# this core has already been taken
			continue
		else
			# first time this core has been found, use it
			socket_core_id_list="${socket_core_id_list}${socket_core_id},"
			no_sibling_list="$no_sibling_list,$this_cpu"
		fi

	done
	no_sibling_list=`echo $no_sibling_list | sed -e s/^,//`
	echo "$no_sibling_list"
}

function get_pmd_cpus() {
	local devs=$1
	local nr_queues=$2
	local cpu_usage=$3
	local pmd_cpu_list=""
	local pci_dev=""
	local node_id=""
	local cpus_list=""
	local iso_cpus_list=""
	local pmd_cpus_list=""
	local queue_num=
	local count=
	local prev_cpu=""
	# for each device, get N cpus, where N = number of queues
	local this_dev
	for this_dev in `echo $devs | sed -e 's/,/ /g'`; do
		if echo $this_dev | grep -q vhost; then
			# the file name for vhostuser ends with a number matching the NUMA node
			node_id="${this_dev: -1}"
		else
			node_id=`cat /sys/bus/pci/devices/$(get_dev_loc $this_dev)/numa_node`
			# -1 means there is no topology, so we use node0
			if [ "$node_id" == "-1" ]; then
				node_id=0
			fi
		fi
		cpus_list=`node_cpus_list "$node_id"`
		iso_cpus_list=`get_iso_cpus`
		node_iso_cpus_list=`intersect_cpus "$cpus_list" "$iso_cpus_list"`
		if [ "$use_ht" == "n" ]; then
			node_iso_cpus_list=`remove_sibling_cpus $node_iso_cpus_list`
		fi
		if [ "$node_iso_cpus_list" == "" ]; then
			echo ""
			exit
		fi
		queue_num=0
		while [ $queue_num -lt $nr_queues ]; do
			new_cpu=""
			if [ "$use_ht" == "y" -a "$prev_cpu" != "" ]; then
				# search for sibling cpu-threads before picking next avail cpu
				cpu_siblings_range=`cat /sys/devices/system/cpu/cpu$prev_cpu/topology/thread_siblings_list`
				cpu_siblings_list=`convert_number_range $cpu_siblings_range`
				cpu_siblings_avail_list=`sub_from_list  $cpu_siblings_list $pmd_cpus_list`
				if [ "$cpu_siblings_avail_list" != "" ]; then
					# if all of the siblings are depleted, then fall back to getting a new (non-sibling) cpu
					new_cpu="`echo $cpu_siblings_avail_list | awk -F, '{print $1}'`"
				fi
			fi
			if [ "$new_cpu" == "" ]; then
				# allocate a new cpu
				new_cpu="`echo $node_iso_cpus_list | awk -F, '{print $1}'`"
			fi
			if [ "$use_ht" == "n" ]; then
				# make sure sibling threads don't get used next time a isolated cpu is found
				sibling_cpus=`cat /sys/devices/system/cpu/cpu$new_cpu/topology/thread_siblings_list`
				sibling_cpus=`convert_number_range $sibling_cpus`
				sibling_cpus=`sub_from_list $sibling_cpus $new_cpu`
				for i in `echo $sibling_cpus | sed -e 's/,/ /g'`; do
					log_cpu_usage "$i" "idle-sibling-thread"
					if [ $? -gt 0 ]; then
						exit 1
					fi
				done
			fi
			log_cpu_usage "$new_cpu" "$cpu_usage"
			if [ $? -gt 0 ]; then
				exit 1
			fi
			node_iso_cpus_list=`sub_from_list "$node_iso_cpus_list" "$new_cpu"`
			pmd_cpus_list="$pmd_cpus_list,$new_cpu"
			((queue_num++))
			((count++))
			prev_cpu=$new_cpu
		done
	done
	pmd_cpus_list=`echo $pmd_cpus_list | sed -e 's/^,//'`
	echo "$pmd_cpus_list"
	return 0
}

function get_cpumask() {
	local cpu_list=$1
	local pmd_cpu_mask=0
	for cpu in `echo $cpu_list | sed -e 's/,/ /'g`; do
		bc_math="$bc_math + 2^$cpu"
	done
	bc_math=`echo $bc_math | sed -e 's/\+//'`
	pmd_cpu_mask=`echo "obase=16; $bc_math" | bc`
	echo "$pmd_cpu_mask"
}

function set_ovs_bridge_mode() {
	local bridge=$1
	local switch_mode=$2

	$ovs_bin/ovs-ofctl del-flows ${bridge}
	case "${switch_mode}" in
		"l2-bridge")
			$ovs_bin/ovs-ofctl add-flow ${bridge} action=NORMAL
			;;
		"default"|"direct-flow-rule")
			$ovs_bin/ovs-ofctl add-flow ${bridge} "in_port=1,idle_timeout=0 actions=output:2"
			$ovs_bin/ovs-ofctl add-flow ${bridge} "in_port=2,idle_timeout=0 actions=output:1"
			;;
	esac
}



function get_dev_loc() {
	# input should be pci_location/port-number, like 0000:86:0.0/1
	echo $1 | awk -F/ '{print $1}'
}

function get_devs_locs() {
	# input should be a list of pci_location/port-number, like 0000:86:0.0/0,0000:86:0.0/1
	# returns a list of PCI location IDs with no repeats
	# for exmaple get_devs_locs "0000:86:0.0/0,0000:86:0.0/1" returns "0000:86:0.0"
	local this_dev
	for this_dev in `echo $1 | sed -e 's/,/ /g'`; do
		get_dev_loc $this_dev
	done | sort | uniq 
}

function get_dev_port() {
	# input should be pci_location/port-number, like 0000:86:0.0/1
	echo $1 | awk -F/ '{print $2}'
}

function get_dev_desc() {
	# input should be pci_location/port-number, like 0000:86:0.0/1
	lspci -s $(get_dev_loc $1) | cut -d" " -f 2- | sed -s 's/ (.*$//'
}



# Process options and arguments
opts=$(getopt -q -o i:c:t:r:m:p:M:S:C:o --longoptions "no-kill,vhost-affinity:,numa-mode:,desc-override:,vhost_devices:,pci-devices:,devices:,nr-queues:,use-ht:,overlay-network:,topology:,dataplane:,switch:,switch-mode:,testpmd-path:,dpdk-nic-kmod:,prefix:,pci-desc-override:,print-config" -n "getopt.sh" -- "$@")
if [ $? -ne 0 ]; then
	printf -- "$*\n"
	printf "\n"
	printf "\t${benchmark_name}: you specified an invalid option\n\n"
	printf "\tThe following options are available:\n\n"
	#              1   2         3         4         5         6         7         8         9         0         1         2         3
	#              678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012
	printf -- "\t\t--[pci-]devices=str/port,str/port ..... Two PCI locations of Ethenret adapters to use, like:\n"
        printf -- "\t\t                                        '--devices=0000:83:00.0/0,0000:86:00.0/0'.  Port numbers are optional\n"
	printf -- "\t\t                                        You can list the same PCI device twice only if the physical function has \n"
	printf -- "\t\t                                        two netdev devices\n\n"
	printf -- "\t\t--device-ports=int,int ................ If a PCI device has more than 1 netdev, then you need to specify the port ID for each device.  Port enumeration starts with \"0\"\n\n"
	printf -- "\t\t--no-kill ............................. Don't kill all OVS sessions (however, anything process owning a DPDK device will still be killed)\n\n"
	printf -- "\t\t--vhost-affinity=str .................. local [default]: Use same numa node as PCI device\n"
	printf -- "\t\t                                        remote:          Use opposite numa node as PCI device\n\n"
	printf -- "\t\t--nr-queues=int ....................... The number of queues per device\n\n"
	printf -- "\t\t--use-ht=[y|n] ........................ y=Use both cpu-threads on HT core\n"
	printf -- "\t\t                                        n=Only use 1 cpu-thread per core\n"
	printf -- "\t\t                                        Note: Using HT has better per/core throuhgput, but not using HT has better per-queue throughput\n\n"
	printf -- "\t\t--overlay-network=[none|vxlan] ........ Network overlay used, if any (not supported on all bridge types)\n\n"
	printf -- "\t\t--topology=str ........................ pp:            Two physical devices on same bridge\n"
        printf -- "\t\t                                        pvp or pv,vp:  Two bridges, each with a phys port and a virtio port)\n\n"
	printf -- "\t\t--dataplane=str ....................... dpdk, kernel, or kernel-hw-offload\n\n"
	printf -- "\t\t--desc-override ....................... Override default size for descriptor size\n\n"
	printf -- "\t\t--switch=str .......................... testpmd, ovs, linuxrouter, or linuxbridge\n\n"
	printf -- "\t\t--switch-mode=str ..................... Mode that the selected switch operates in.  Modes differ between switches\n"
	printf -- "\t\t                                        \tlinuxbridge: default\n"
	printf -- "\t\t                                        \tlinuxrouter: default\n"
	printf -- "\t\t                                        \ttestpmd:     default\n"
	printf -- "\t\t                                        \tovs:         default/direct-flow-rule, l2-bridge\n"
	printf -- "\t\t--testpmd-path=str .................... Override the default location for the testpmd binary (${testpmd_path})\n\n"
	printf -- "\t\t--dpdk-nic-kmod=str ................... Use this kernel modeule for the devices (default is $dpdk_nic_kmod)\n\n"
	printf -- "\t\t--numa-mode=str ....................... strict:    (default).  All PMD threads for all phys and virt devices use memory and cpu only\n"
        printf -- "\t\t                                                   from the numa node where the physical adapters are located.\n"
        printf -- "\t\t                                                   This implies the VMs must be on the same node.\n"
	printf -- "\t\t                                        preferred: Just like 'strict', but the vswitch also has memory and in some cases\n"
	printf -- "\t\t                                                   uses cpu from the non-local NUMA nodes.\n"
	printf -- "\t\t                                        cross:     The PMD threads for all phys devices use memory and cpu from\n"
	printf -- "\t\t                                                   the local NUMA node, but VMs are present on another NUMA node,\n"
	printf -- "\t\t                                                   and so the PMD threads for those virt devices are also on\n"
	printf -- "\t\t                                                   another NUMA node.\n"
	exit_error ""
fi
log "opts: [$opts]"
eval set -- "$opts"
log "Processing options:"
while true; do
	case "$1" in
		--no-kill)
		shift
		no_kill=1
		log "no_kill: [$no_kill]"
		;;
		--devices)
		shift
		if [ -n "$1" ]; then
			for dev in `echo $1 | sed -e 's/,/ /g'`; do
				devs="$devs,$dev"
			done
			devs=`echo $devs | sed -e s/^,//`
			log "devs: [$devs]"
			shift
		fi
		;;
		--vhost-affinity)
		shift
		if [ -n "$1" ]; then
			vhost_affinity="$1"
			log "vhost_affinity: [$vhost_affinity]"
			shift
		fi
		;;
		--nr-queues)
		shift
		if [ -n "$1" ]; then
			queues="$1"
			log "nr_queues: [$queues]"
			shift
		fi
		;;
		--use-ht)
		shift
		if [ -n "$1" ]; then
			use_ht="$1"
			log "use_ht: [$use_ht]"
			shift
		fi
		;;
		--overlay-network)
		shift
		if [ -n "$1" ]; then
			overlay_network="$1"
			log "overlay_network: [$overlay_network]"
			shift
		fi
		;;
		--topology)
		shift
		if [ -n "$1" ]; then
			topology="$1"
			log "topology: [$topology]"
			shift
		fi
		;;
		--dataplane)
		shift
		if [ -n "$1" ]; then
			dataplane="$1"
			log "dataplane: [$dataplane]"
			shift
		fi
		;;
		--pci-desc-override)
		shift
		if [ -n "$1" ]; then
			pci_desc_override="$1"
			log "pci-desc-override: [$pci_desc_override]"
			shift
		fi
		;;
		--vhu-desc-override)
		shift
		if [ -n "$1" ]; then
			vhu_desc_override="$1"
			log "vhu-desc-override: [$vhu_desc_override]"
			shift
		fi
		;;
		--switch)
		shift
		if [ -n "$1" ]; then
			switch="$1"
			shift
			ok=0
			for i in $supported_switches; do
				if [ "$switch" == "$i" ]; then
					ok=1
				fi
			done
			if [ $ok -eq 1 ]; then
				log "switch: [$switch]"
			else
				exit_error "switch: [$switch] is not supported by this script"
			fi
		fi
		;;
		--switch-mode)
		shift
		if [ -n "$1" ]; then
			switch_mode="$1"
			shift
			log "switch_mode: [$switch_mode]"
		fi
		;;
		--testpmd-path)
		shift
		if [ -n "$1" ]; then
			testpmd_path="$1"
			shift
			if [ ! -e ${testpmd_path} -o ! -x "${testpmd_path}" ]; then
				exit_error "testpmd_path: [${testpmd_path}] does not exist or is not exexecutable"
			fi
			log "testpmd_path: [${testpmd_path}]"
		fi
		;;
		--numa-mode)
		shift
		if [ -n "$1" ]; then
			numa_mode="$1"
			shift
			log "numa_mode: [$numa_mode]"
		fi
		;;
		--dpdk-nic-kmod)
		shift
		if [ -n "$1" ]; then
			dpdk_nic_kmod="$1"
			shift
			log "dpdk_nic_kmod: [$dpdk_nic_kmod]"
		fi
		;;
		--prefix)
		shift
		if [ -n "$1" ]; then
			prefix="$1"
			shift
			log "prefix: [$prefix]"
		fi
		;;
		--print-config)
		shift
		echo ""
		echo "topology = $topology"	
		echo "queues = $queues"	
		echo "switch = $switch"
		echo "switch_mode = $switch_mode"
		echo "numa_mode = $numa_mode"
		echo "overlay_network = $overlay_network"
		echo "ovs_build = $ovs_build"
		echo "dpdk_nic_kmod = $dpdk_nic_kmod"
		echo "dataplane = $dataplane"
		echo "use_ht = $use_ht"
		echo "testpmd_path = $testpmd_path"
		echo "supported_switches = $supported_switches"
		echo "pci_descriptors = $pci_descriptors"
		echo "pci_desc_override = $pci_descriptor_override"
		echo "vhu_desc_override = $vhu_desc_override"
		echo "cpu_usage_file = $cpu_usage_file"
		echo "vhost_affinity = $vhost_affinity"
		echo "no_kill = $no_kill"
		echo ""
		;;
		--)
		shift
		break
		;;
		*)
		log "[$script_name] bad option, \"$1 $2\""
		break
		;;
	esac
done

# validate switch modes
log "Validating the switch-mode $switch_mode given the switch is $switch..."
case "${switch}" in
	"linuxbridge"|"linuxrouter"|"testpmd")
		case "${switch_mode}" in
			"default")
				;;
			*)
				exit_error "switch=${switch} does not support switch_mode=${switch_mode}"
				;;
		esac
		;;
	"ovs")
		case "${switch_mode}" in
			"default"|"direct-flow-rule"|"l2-bridge")
				;;
			*)
				exit_error "switch=${switch} does not support switch_mode=${switch_mode}"
				;;
		esac
		;;
esac
log "switch-mode $switch_mode is valid"

# check for software dependencies.  Just make sure everything possibly needed is installed.
log "Determining if proper software tools are installed..."
all_deps="lsof lspci bc dpdk-devbind.py driverctl udevadm ip screen tmux brctl"
for i in $all_deps; do
	if which $i >/dev/null 2>&1; then
		continue
	else
		exit_error "You must have the following installed to run this script: '$i'  Please install first"
	fi
done


# only run if selinux is disabled
selinuxenabled && exit_error "disable selinux before using this script"

# either "rpm" or "src"
if [ "$ovs_build"="rpm" ]; then
	ovs_bin="/usr/bin"
	ovs_sbin="/usr/sbin"
	ovs_run="/var/run/openvswitch"
	ovs_etc="/etc/openvswitch"
log "Using OVS from RPM"
else
	ovs_bin="/usr/local/bin"
	ovs_sbin="/usr/local/sbin"
	ovs_run="/usr/local/var/run/openvswitch"
	ovs_etc="/usr/local/etc/openvswitch"
log "Using OVS that has been build locally"
fi

# Get RHEL major version.  Sometimes /sysfs changes between versions
rhel_major_version=`cat /etc/redhat-release | tr -dc '0-9.'|cut -d \. -f1`

dev_count=0
# make sure all of the pci devices used are exactly the same and that there is more than one
prev_dev_desc=""
log "devs = $devs"
for this_dev in `echo $devs | sed -e 's/,/ /g'`; do

	this_pci_desc=$(get_dev_desc $this_dev)
	if [ "$prev_pci_desc" != "" -a "$prev_pci_desc" != "$(get_dev_desc $this_dev)" ]; then
		exit_error "PCI devices are not the exact same type: $prev_pci_desc, $this_pci_desc"
	else
		prev_pci_desc=$this_pci_desc
		log "Using PCI device: $(lspci -s $this_dev)"
	fi

	((dev_count++))
done
if [ $dev_count -ne 2 ]; then
	exit_error "you must use 2 PCI devices, you used: $dev_count"
fi

kernel_nic_kmod=`lspci -k -s $(get_dev_loc $this_dev) | grep "Kernel modules:" | awk -F": " '{print $2}' | sed -e s/virtio_pci/virtio-pci/`
log "kernel mod: $kernel_nic_kmod"

# kill any process using the 2 devices
log "Checking for an existing process using $devs"
for this_dev in `echo $devs | sed -e 's/,/ /g'`; do
	iommu_group=`readlink /sys/bus/pci/devices/$(get_dev_loc $this_dev)/iommu_group | awk -Fiommu_groups/ '{print $2}'`
	log "/sys/bus/pci/devices/$(get_dev_loc $this_dev)/iommu_group"
	ans=`readlink /sys/bus/pci/devices/$(get_dev_loc $this_dev)/iommu_group`
	log "$ans" 
	log "iommu_group = $iommu_group"
	pids=`lsof -n -T -X | grep -- "/dev/vfio/$iommu_group" | awk '{print $2}' | sort | uniq`
	if [ ! -z "$pids" ]; then
		log "killing PID $pids, which is using device $pci_dev"
		kill $pids
	fi
done

if [ $no_kill -ne 1 ]; then
	# completely kill and remove old ovs configuration
	log "stopping ovs"
	killall -q -w ovs-vswitchd
	killall -q -w ovsdb-server
	killall -q -w ovsdb-server ovs-vswitchd
	log "stopping testpmd"
	killall -q -w testpmd
	rm -rf $ovs_run/ovs-vswitchd.pid
	rm -rf $ovs_run/ovsdb-server.pid
	rm -rf $ovs_etc/*db*
	rm -rf $ovs_var/*.log
fi


# initialize the devices
case $dataplane in
	dpdk)
	log "Initializing devices to use DPDK as the dataplane"
	# keep track of cpus we can use for DPDK
	iso_cpus_list=`init_cpu_usage_file`
	# create the option for --socket-mem that DPDK apoplications use
	socket_mem=
	node_range=`cat /sys/devices/system/node/has_memory`
	node_list=`convert_number_range $node_range`
	for node in `echo $node_list | sed -e 's/,/ /g'`; do
		local_socket_mem[$node]=0
		all_socket_mem[$node]=1024
	done
	for this_dev in `echo $devs | sed -e 's/,/ /g'`; do
		dev_numa_node=`cat /sys/bus/pci/devices/$(get_dev_loc $this_dev)/numa_node`
		if [ $dev_numa_node -eq -1 ]; then
			dev_numa_node=0
		fi
		log "device $this_dev node is $dev_numa_node"
		local_socket_mem[$dev_numa_node]=1024
	done
	log "local_socket_mem: ${local_socket_mem[@]}"
	local_socket_mem_opt=""
	for mem in "${local_socket_mem[@]}"; do
		log "mem: $mem"
		local_socket_mem_opt="$local_socket_mem_opt,$mem"
		all_socket_mem_opt="$all_socket_mem_opt,1024"
	done
	for node in "${!local_socket_mem[@]}"; do
		if [ "${local_socket_mem[$node]}" == "1024" ]; then
			local_numa_nodes="$local_numa_nodes,$node"
			local_node_cpus_list=`node_cpus_list $node`
			local_nodes_cpus_list=`add_to_list "$local_nodes_cpus_list" "$local_node_cpus_list"`
		fi
	done
	local_nodes_non_iso_cpus_list=`sub_from_list "$local_nodes_cpus_list" "$iso_cpus_list"`
	local_numa_nodes=`echo $local_numa_nodes | sed -e 's/^,//'`
	log "local_numa_nodes: $local_numa_nodes"
	local_socket_mem_opt=`echo $local_socket_mem_opt | sed -e 's/^,//'`
	log "local_socket_mem_opt: $local_socket_mem_opt"
	all_socket_mem_opt=`echo $all_socket_mem_opt | sed -e 's/^,//'`
	log "all_socket_mem_opt: $all_socket_mem_opt"
	
	all_cpus_range=`cat /sys/devices/system/cpu/online`
	all_cpus_list=`convert_number_range $all_cpus_range`
	all_nodes_non_iso_cpus_list=`sub_from_list $all_cpus_list $iso_cpus_list`
	log "isol cpus_list is $iso_cpus_list"
	log "all-nodes-non-isolated cpus list is $all_nodes_non_iso_cpus_list"

	if [ "$kernel_nic_kmod" != "mlx5_core" ]; then
		exit_error "Wrong kernel module $kernel_nic_kmod  It should be 'mlx5_core'"
	else
		log "Mellanox adapter in use.  Using kernel module $kernel_nic_kmod"
	fi
	;;
esac

# configure the vSwitch
log "Configuring the vswitch: $switch"

case $switch in
ovs) #switch configuration
	DB_SOCK="$ovs_run/db.sock"
	ovs_ver=`$ovs_sbin/ovs-vswitchd --version | awk '{print $4}'`
	log "starting ovs (ovs_ver=${ovs_ver})"
	mkdir -p $ovs_run
	mkdir -p $ovs_etc
	$ovs_bin/ovsdb-tool create $ovs_etc/conf.db /usr/share/openvswitch/vswitch.ovsschema
	$ovs_sbin/ovsdb-server -v --remote=punix:$DB_SOCK \
	--remote=db:Open_vSwitch,Open_vSwitch,manager_options \
	--pidfile --detach || exit_error "failed to start ovsdb"
	/bin/rm -f /var/log/openvswitch/ovs-vswitchd.log

	log "starting ovs-vswitchd"
	case $dataplane in
	"dpdk")
		if echo $ovs_ver | grep -q "^2\.6\|^2\.7\|^2\.8\|^2\.9\|^2\.10\|^2\.11\|^2\.12\|^2\.13"; then
			dpdk_opts=""
			$ovs_bin/ovs-vsctl --no-wait set Open_vSwitch . other_config:dpdk-init=true
			#$ovs_bin/ovs-vsctl --no-wait set Open_vSwitch . other_config:vhost-sock-dir=/tmp
			#$ovs_bin/ovs-vsctl --no-wait set Open_vSwitch . other_config:vhost-iommu-support=true

			case $numa_mode in
			strict)
				$ovs_bin/ovs-vsctl --no-wait set Open_vSwitch . other_config:dpdk-socket-mem="$local_socket_mem_opt"
				$ovs_bin/ovs-vsctl --no-wait set Open_vSwitch . other_config:dpdk-lcore-mask="`get_cpumask $local_nodes_non_iso_cpus_list`"
				;;
			preferred)
				$ovs_bin/ovs-vsctl --no-wait set Open_vSwitch . other_config:dpdk-socket-mem="$all_socket_mem_opt"
				$ovs_bin/ovs-vsctl --no-wait set Open_vSwitch . other_config:dpdk-lcore-mask="`get_cpumask $all_nodes_non_iso_cpus_list`"
				;;
			esac
		else
			dpdk_opts="--dpdk -n 4 --socket-mem $local_socket_mem_opt --"
		fi

		case $numa_mode in
		strict)
			sudo su -g qemu -c "umask 002; numactl --cpunodebind=$local_numa_nodes $ovs_sbin/ovs-vswitchd $dpdk_opts unix:$DB_SOCK --pidfile --log-file=/var/log/openvswitch/ovs-vswitchd.log --detach"
			;;
		preferred)
			sudo su -g qemu -c "umask 002; $ovs_sbin/ovs-vswitchd $dpdk_opts unix:$DB_SOCK --pidfile --log-file=/var/log/openvswitch/ovs-vswitchd.log --detach"
			;;
		esac

		rc=$?
		;;
	esac

	if [ $rc -ne 0 ]; then
		exit_error "Aborting since openvswitch did not start correctly. Openvswitch exit code: [$rc]"
	fi
	
	log "waiting for ovs to init"
	$ovs_bin/ovs-vsctl --no-wait init

	if [ "$dataplane" == "dpdk" ]; then
		if echo $ovs_ver | grep -q "^2\.7\|^2\.8\|^2\.9\|^2\.10\|^2\.11\|^2\.12\|^2\.13"; then
			pci_devs=`get_devs_locs $devs`

			ovs_dpdk_interface_0_name="dpdk-0"
			#pci_dev=`echo ${devs} | awk -F, '{ print $1}'`
			pci_dev=`echo $pci_devs | awk '{print $1}'`
			ovs_dpdk_interface_0_args="options:dpdk-devargs=${pci_dev}"
			log "ovs_dpdk_interface_0_args[$ovs_dpdk_interface_0_args]"

			ovs_dpdk_interface_1_name="dpdk-1"
			#pci_dev=`echo ${devs} | awk -F, '{ print $2}'`
			pci_dev=`echo $pci_devs | awk '{print $2}'`
			ovs_dpdk_interface_1_args="options:dpdk-devargs=${pci_dev}"
			log "ovs_dpdk_interface_1_args[$ovs_dpdk_interface_1_args]"
		else
			ovs_dpdk_interface_0_name="dpdk0"
			ovs_dpdk_interface_0_args=""
			ovs_dpdk_interface_1_name="dpdk1"
			ovs_dpdk_interface_1_args=""
		fi
	
		log "configuring ovs with network topology: $topology"

		case $topology in
		pvp|pv,vp)   # 10GbP1<-->VM1P1, VM1P2<-->10GbP2
			# create the bridges/ports with 1 phys dev and 1 virt dev per bridge, to be used for 1 VM to forward packets
			vhost_ports=""
			ifaces=""
			for i in `seq 0 1`; do
				phy_br="phy-br-$i"
				log "phy_br = $phy_br"
				pci_dev_index=$(( i + 1 ))
				log "pci_dev_index = $pci_dev_index"
				pci_dev=`echo ${devs} | awk -F, "{ print \\$${pci_dev_index}}"`
				log "pci_dev (in progress) = $pci_dev"
				log "pci_dev = $pci_dev"
				pci_node=`cat /sys/bus/pci/devices/"$pci_dev"/numa_node`
				log "pci_node = $pci_node"

				if [ "$vhost_affinity" == "local" ]; then
					vhost_port="vm0-vhost-user-$i-n$pci_node"
					log "vhost_port = $vhost_port"
				else # use a non-local node
					remote_pci_nodes=`sub_from_list $node_list $pci_node`
					remote_pci_node=`echo $remote_pci_nodes | awk -F, '{print $1}'`
					vhost_port="vm0-vhost-user-$i-n$remote_pci_node"
				fi

				log "vhost_port: $vhost_port"
				vhost_ports="$vhost_ports,$vhost_port"
				log "vhost_ports = $vhost_ports"

				if echo $ovs_ver | grep -q "^2\.7\|^2\.8\|^2\.9\|^2\.10\|^2\.11\|^2\.12\|^2\.13"; then
					phys_port_name="dpdk-${i}"
					phys_port_args="options:dpdk-devargs=${pci_dev}"
					log "phys_port_name = $phys_port_name"
					log "phys_port_args = $phys_port_args"
				else
					phys_port_name="dpdk$i"
					phys_port_args=""
				fi

				$ovs_bin/ovs-vsctl --if-exists del-br $phy_br
				$ovs_bin/ovs-vsctl add-br $phy_br -- set bridge $phy_br datapath_type=netdev
				$ovs_bin/ovs-vsctl add-port $phy_br ${phys_port_name} -- set Interface ${phys_port_name} type=dpdk ${phys_port_args}
				ifaces="$ifaces,${phys_port_name}"
				phy_ifaces="$ifaces,${phys_port_name}"

				$ovs_bin/ovs-vsctl add-port $phy_br $vhost_port -- set Interface $vhost_port type=dpdkvhostuser
				ifaces="$ifaces,$vhost_port"
				vhu_ifaces="$ifaces,$vhost_port"

				if [ ! -z "$vhu_desc_override" ]; then
					echo "overriding vhostuser descriptors/queue with $vhu_desc_override"
					$ovs_bin/ovs-vsctl set Interface $vhost_port options:n_txq_desc=$vhu_desc_override
					$ovs_bin/ovs-vsctl set Interface $vhost_port options:n_rxq_desc=$vhu_desc_override
				fi

				$ovs_bin/ovs-ofctl del-flows $phy_br
				set_ovs_bridge_mode $phy_br ${switch_mode}
			done

			ifaces=`echo $ifaces | sed -e s/^,//`
			log "ifaces = $ifaces"
			vhost_ports=`echo $vhost_ports | sed -e 's/^,//'`
			log "vhost_ports = $vhost_ports"
			ovs_ports=4
			;;
		esac

		log "using $queues queue(s) per port"
		$ovs_bin/ovs-vsctl set interface ${ovs_dpdk_interface_0_name} options:n_rxq=$queues
		$ovs_bin/ovs-vsctl set interface ${ovs_dpdk_interface_1_name} options:n_rxq=$queues
		
		if [ ! -z "$pci_desc_override" ]; then
			log "overriding PCI descriptors/queue with $pci_desc_override"
			$ovs_bin/ovs-vsctl set Interface ${ovs_dpdk_interface_0_name} options:n_txq_desc=$pci_desc_override
			$ovs_bin/ovs-vsctl set Interface ${ovs_dpdk_interface_0_name} options:n_rxq_desc=$pci_desc_override
			$ovs_bin/ovs-vsctl set Interface ${ovs_dpdk_interface_1_name} options:n_txq_desc=$pci_desc_override
			$ovs_bin/ovs-vsctl set Interface ${ovs_dpdk_interface_1_name} options:n_rxq_desc=$pci_desc_override
		else
			log "setting PCI descriptors/queue with $pci_descriptors"
			$ovs_bin/ovs-vsctl set Interface ${ovs_dpdk_interface_0_name} options:n_txq_desc=$pci_descriptors
			$ovs_bin/ovs-vsctl set Interface ${ovs_dpdk_interface_0_name} options:n_rxq_desc=$pci_descriptors
			$ovs_bin/ovs-vsctl set Interface ${ovs_dpdk_interface_1_name} options:n_txq_desc=$pci_descriptors
			$ovs_bin/ovs-vsctl set Interface ${ovs_dpdk_interface_1_name} options:n_rxq_desc=$pci_descriptors
		fi
		
		#$ovs_bin/ovs-vsctl set Open_vSwitch . other_config:vhost-iommu-support=true

		#configure the number of PMD threads to use
		pmd_threads=`echo "$ovs_ports * $queues" | bc`
		log "using a total of $pmd_threads PMD threads"
		pmdcpus=`get_pmd_cpus "$devs,$vhost_ports" $queues "ovs-pmd"`

		if [ -z "$pmdcpus" ]; then
			exit_error "Could not allocate PMD threads.  Do you have enough isolated cpus in the right NUAM nodes?"
		fi

		pmd_cpu_mask=`get_cpumask $pmdcpus`
		log "pmd_cpus_list is [$pmdcpus]"
		log "pmd_cpu_mask is [$pmd_cpu_mask]"
		vm_cpus=`sub_from_list $ded_cpus_list $pmdcpus`
		log "vm_cpus is [$vm_cpus]"
		$ovs_bin/ovs-vsctl set Open_vSwitch . other_config:pmd-cpu-mask=$pmd_cpu_mask

		#if using HT, bind 1 PF and 1 VHU to same core
		if [ "$use_ht" == "y" ]; then
			while [ ! -z "$pmdcpus" ]; do
				this_cpu=`echo $pmdcpus | awk -F, '{print $1}'`
				cpu_siblings_range=`cat /sys/devices/system/cpu/cpu$this_cpu/topology/thread_siblings_list`
				cpu_siblings_list=`convert_number_range $cpu_siblings_range`
				pmdcpus=`sub_from_list $pmdcpus $cpu_siblings_list`
				while [ ! -z "$cpu_siblings_list" ]; do
				this_cpu_thread=`echo $cpu_siblings_list | awk -F, '{print $1}'`
				cpu_siblings_list=`sub_from_list $cpu_siblings_list $this_cpu_thread`
				iface=`echo $ifaces | awk -F, '{print $1}'`
				ifaces=`echo $ifaces | sed -e s/^$iface,//`
				log "$ovs_bin/ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
				$ovs_bin/ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread
			done
		done
		fi

		log "PMD cpumask command: ovs-vsctl set Open_vSwitch . other_config:pmd-cpu-mask=$pmd_cpu_mask"
		log "PMD thread assignments:"
		$ovs_bin/ovs-appctl dpif-netdev/pmd-rxq-show
	fi
	;;

esac

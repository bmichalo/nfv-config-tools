#!/bin/bash

# This script will start a vswitch of your choice, doing the following:
# -use multi-queue (for DPDK)
# -bind DPDK PMDs to optimal CPUs
# -for pvp topologies, provide a list of optimal cpus available for the VM

# The following features are not implemented but would be nice to add:
# -for ovs, configure x flows
# -for a router, configure x routes
# -configure VLAN
# -configure a firewall

script_root=$(dirname $(readlink -f $0))
. $script_root/utils/cpu_parsing.sh


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

: <<'END'
END



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
opts=$(getopt -q -o i:c:t:r:m:p:M:S:C:o --longoptions "no-kill,vhost-affinity:,numa-mode:,desc-override:,vhost_devices:,pci-devices:,devices:,nr-queues:,use-ht:,topology:,dataplane:,switch:,switch-mode:,testpmd-path:,dpdk-nic-kmod:,prefix:,pci-desc-override:,print-config" -n "getopt.sh" -- "$@")
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
	log "********** Starting OVS (ovs_ver=${ovs_ver}) **********"
	mkdir -p $ovs_run
	mkdir -p $ovs_etc
	log "Initializing the OVS configuration database at $ovs_etc/conf.db using 'ovsdb-tool create'..."
	$ovs_bin/ovsdb-tool create $ovs_etc/conf.db /usr/share/openvswitch/vswitch.ovsschema

	log "Starting the OVS configuration database process ovsdb-server and connecting to Unix socket $DB_SOCK..." 
	$ovs_sbin/ovsdb-server -v --remote=punix:$DB_SOCK \
	--remote=db:Open_vSwitch,Open_vSwitch,manager_options \
	--pidfile --detach || exit_error "failed to start ovsdb"
	/bin/rm -f /var/log/openvswitch/ovs-vswitchd.log

	log "Now intialize the OVS database using 'ovs-vsctl --no-wait init' ..."
	$ovs_bin/ovs-vsctl --no-wait init


	log "starting ovs-vswitchd"
	case $dataplane in
	"dpdk")
		if echo $ovs_ver | grep -q "^2\.6\|^2\.7\|^2\.8\|^2\.9\|^2\.10\|^2\.11\|^2\.12\|^2\.13"; then
			dpdk_opts=""

			#$ovs_bin/ovs-vsctl --no-wait set Open_vSwitch . other_config:vhost-sock-dir=/tmp

			#
			# Enable Vhost IOMMU feature which restricts memory that a virtio device can access.  
			# Setting 'vfio-iommu-support' to 'true' enable vhost IOMMU support for all vhost ports 
			# 
			#$ovs_bin/ovs-vsctl --no-wait set Open_vSwitch . other_config:vhost-iommu-support=true

			#
			# Note both dpdk-socket-mem and dpdk-lcore-mask should be set before dpdk-init is set to 
			# true (OVS 2.7) or OVS-DPDK is started (OVS 2.6)
			#
			case $numa_mode in
			strict)
				log "OVS setting other_config:dpdk-socket-mem = $local_socket_mem_opt"
				$ovs_bin/ovs-vsctl --no-wait set Open_vSwitch . other_config:dpdk-socket-mem="$local_socket_mem_opt"
				log "Local NUMA node non-isolated CPUs list: $local_nodes_non_iso_cpus_list"
				log "OVS setting other_config:dpdk-lcore-mask = `get_cpumask $local_nodes_non_iso_cpus_list`"
				$ovs_bin/ovs-vsctl --no-wait set Open_vSwitch . other_config:dpdk-lcore-mask="`get_cpumask $local_nodes_non_iso_cpus_list`"
				;;
			preferred)
				$ovs_bin/ovs-vsctl --no-wait set Open_vSwitch . other_config:dpdk-socket-mem="$all_socket_mem_opt"
				$ovs_bin/ovs-vsctl --no-wait set Open_vSwitch . other_config:dpdk-lcore-mask="`get_cpumask $all_nodes_non_iso_cpus_list`"
				;;
			esac

			#
			# Specify OVS should support DPDK ports
			#
			$ovs_bin/ovs-vsctl --no-wait set Open_vSwitch . other_config:dpdk-init=true
		else
			dpdk_opts="--dpdk -n 4 --socket-mem $local_socket_mem_opt --"
		fi


		#
		# umask 002 changes the default file creation mode for the ovs-vswitchd process to itself and its group.
		#
		# su -g qemu changes the default group the ovs-vswitchd process runs as part of to the same group as the qemu process.
		#
		# The sudo causes the ovs-vswitchd process to run as the root user.  sudo support setting the group with the -g flag directly so su is not needed.
		#
		# The result of combining these commands is that all vhost-user socket created by OVS will be owned by the root user and the 
		# Libvirt-qemu users group (previously "libvirt-qemu" now "kvm")
		# 

		#
		# umask 002 changes the default file creation mode for the ovs-vswitchd process to itself and its group.
		#
		# su -g qemu changes the default group the ovs-vswitchd process runs as part of to the same group as the qemu process.
		#
		# The sudo causes the ovs-vswitchd process to run as the root user.  sudo support setting the group with the -g flag directly so su is not needed.
		#
		# The result of combining these commands is that all vhost-user socket created by OVS will be owned by the root user and the 
		# qemu users group
		# 
		# For example, if we start ovs-vswitchd daemon without above commands, we get the file permissions as follows:
		#
		#
		# numactl --cpunodebind=$local_numa_nodes $ovs_sbin/ovs-vswitchd $dpdk_opts unix:$DB_SOCK --pidfile --log-file=/var/log/openvswitch/ovs-vswitchd.log --detach
		# 
		# ls /var/run/openvswitch/ -ltra
		# 
		# total 8
		# drwxr-xr-x 36 root root  ..
		# -rw-r--r--  1 root root  ovsdb-server.pid
		# srwxr-x---  1 root root  db.sock
		# srwxr-x---  1 root root  ovsdb-server.53200.ctl
		# -rw-r--r--  1 root root  ovs-vswitchd.pid
		# srwxr-x---  1 root root  ovs-vswitchd.53229.ctl
		# drwxr-xr-x  2 root root  .
		# 
		# Note group is owned by root, and ovs-vswitchd.pid and ovs-vswitchd.53229.ctl do not have the group 'w' bit set.  
		# 
		# Creating the rest of the OVS related sockets, we see the same ownership and permissions issue:
		# 
		# srwxr-x---  1 root root phy-br-0.snoop
		# srwxr-x---  1 root root phy-br-0.mgmt
		# srwxr-xr-x  1 root root vm0-vhost-user-0-n0
		# srwxr-x---  1 root root phy-br-1.mgmt
		# srwxr-x---  1 root root phy-br-1.snoop
		# srwxr-xr-x  1 root root vm0-vhost-user-1-n0
		# 
		# When this occurs, the VM will fail to start (virsh start ....) because of the socket permissions.
		# 
		# What we want is to use this:
		# 
		# sudo su -g qemu -c "umask 002; numactl --cpunodebind=$local_numa_nodes $ovs_sbin/ovs-vswitchd $dpdk_opts unix:$DB_SOCK --pidfile --log-file=/var/log/openvswitch/ovs-vswitchd.log --detach"
		# 
		# which will eventually yield the following (not the group qemu and group 'w' permissions:
		# 
		# -rw-r--r--  1 root root ovsdb-server.pid
		# srwxr-x---  1 root root db.sock
		# srwxr-x---  1 root root ovsdb-server.18481.ctl
		# -rw-rw-r--  1 root qemu ovs-vswitchd.pid
		# srwxrwx---  1 root qemu ovs-vswitchd.18515.ctl
		# srwxrwx---  1 root qemu phy-br-0.snoop
		# srwxrwx---  1 root qemu phy-br-0.mgmt
		# srwxrwxr-x  1 root qemu vm0-vhost-user-0-n0
		# srwxrwx---  1 root qemu phy-br-1.mgmt
		# srwxrwx---  1 root qemu phy-br-1.snoop
		# srwxrwxr-x  1 root qemu vm0-vhost-user-1-n0
		# 
		# and therefore allow the VM to start successfully
		# 
		case $numa_mode in
		strict)
			log "Using strict NUMA configuration mode when starting OVS:"
			sudo su -g qemu -c "umask 002; numactl --cpunodebind=$local_numa_nodes $ovs_sbin/ovs-vswitchd $dpdk_opts unix:$DB_SOCK --pidfile --log-file=/var/log/openvswitch/ovs-vswitchd.log --detach"
			#numactl --cpunodebind=$local_numa_nodes $ovs_sbin/ovs-vswitchd $dpdk_opts unix:$DB_SOCK --pidfile --log-file=/var/log/openvswitch/ovs-vswitchd.log --detach
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

				if [[ "$pci_node" -eq -1 ]]; then
					log "pci_node = $pci_node  Therefore, assume one flat NUMA node with a node ID of 0.  Setting pci_node=0"
					pci_node=0
				fi

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
		echo "pmdcpus= $pmdcpus"
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

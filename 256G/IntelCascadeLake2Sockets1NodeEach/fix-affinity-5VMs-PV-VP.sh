#!/bin/bash


echo "*****************************************************"
echo "* Fixing 5VMs PMD / CPU Affinity for PV-VV-VV-VV-VP *"
echo "*****************************************************"
echo ""

echo "* Original affinity settings...                "
echo ""

ovs-appctl dpif-netdev/pmd-rxq-show
echo""


#cpu_list=1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,91,92,93,94,95,97,98,99,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119,120,121,122,123,124,125,126,127


cpu_list=2,4,10,14,18,22,34,36,42,46,50,54


pmd_cpu_mask=0
for cpu in `echo $cpu_list | sed -e 's/,/ /'g`; do
        bc_math="$bc_math + 2^$cpu"
done
bc_math=`echo $bc_math | sed -e 's/\+//'`
pmd_cpu_mask=`echo "obase=16; $bc_math" | bc`
echo "$pmd_cpu_mask"
binary_pmd_cpu_mask=`echo "ibase=16;obase=2;$pmd_cpu_mask" | bc`
echo "$binary_pmd_cpu_mask"


ovs-vsctl set Open_vSwitch . other_config:pmd-cpu-mask=$pmd_cpu_mask


# phy-br-0
iface=dpdk-0
this_cpu_thread=2
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread

iface=vm0-vhost-user-0-n0
this_cpu_thread=34
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread

# phy-br-1
iface=vm4-vhost-user-1-n0
this_cpu_thread=4
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread

iface=dpdk-1
this_cpu_thread=36
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread



# phy-br-2
iface=vm0-vhost-user-1-n0
this_cpu_thread=10
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread

iface=vm1-vhost-user-0-n0
this_cpu_thread=42
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread



# phy-br-3
iface=vm1-vhost-user-1-n0
this_cpu_thread=14
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread

iface=vm2-vhost-user-0-n0
this_cpu_thread=46
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread



# phy-br-4
iface=vm2-vhost-user-1-n0
this_cpu_thread=18
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread

iface=vm3-vhost-user-0-n0
this_cpu_thread=50
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread



# phy-br-5
iface=vm3-vhost-user-1-n0
this_cpu_thread=22
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread

iface=vm4-vhost-user-0-n0
this_cpu_thread=54
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread






echo ""

echo "* New affinity settings...                "
echo ""

ovs-appctl dpif-netdev/pmd-rxq-show
echo ""


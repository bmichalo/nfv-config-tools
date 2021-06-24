#!/bin/bash


echo "*****************************************************"
echo "* Fixing 2VMs PMD / CPU Affinity for PV-VV-VV-VV-VP *"
echo "*****************************************************"
echo ""

echo "* Original affinity settings...                "
echo ""

ovs-appctl dpif-netdev/pmd-rxq-show
echo""

cpu_list=1,2,5,65,66,69


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
this_cpu_thread=1
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread

iface=vm0-vhost-user-0-n0
this_cpu_thread=65
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread


# phy-br-1
iface=vm1-vhost-user-1-n0
this_cpu_thread=2
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread

iface=dpdk-1
this_cpu_thread=66
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread


# phy-br-2
iface=vm0-vhost-user-1-n0
this_cpu_thread=5
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread

iface=vm1-vhost-user-0-n0
this_cpu_thread=69
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread






echo ""

echo "* New affinity settings...                "
echo ""

ovs-appctl dpif-netdev/pmd-rxq-show
echo ""


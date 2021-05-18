#!/bin/bash


echo "*****************************************************"
echo "* Fixing 4VMs PMD / CPU Affinity for PV-VV-VV-VV-VP *"
echo "*****************************************************"
echo ""

echo "* Original affinity settings...                "
echo ""

ovs-appctl dpif-netdev/pmd-rxq-show
echo""

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
iface=vm0-vhost-user-1-n0
this_cpu_thread=2
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread

iface=dpdk-1
this_cpu_thread=66
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread





echo ""

echo "* New affinity settings...                "
echo ""

ovs-appctl dpif-netdev/pmd-rxq-show
echo ""


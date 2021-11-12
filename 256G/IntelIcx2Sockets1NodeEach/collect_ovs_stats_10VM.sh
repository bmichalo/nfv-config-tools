#!/bin/bash
while getopts s:r:t:n: option
do 
    case "${option}"
        in
        s)vm_chain_size=${OPTARG};;
        r)start_rate=${OPTARG};;
        t)trial=${OPTARG};;
        n)trial_name=${OPTARG};;
    esac
done


mkdir -p $trial

outfile="${trial}/2544_PVP-IcxCtx5-pt002Pct-${vm_chain_size}VM-x16-1adapter-${start_rate}pctStart_noBF_OVSCtrs_${trial}_${trial_name}"

echo "****************************************************************" >> "${outfile}"
echo "* OVS report for $vm_chain_size VM service chain" >> "${outfile}"
echo "****************************************************************" >> "${outfile}"

echo "vm_chain_size = $vm_chain_size" >> "${outfile}"
echo "start_rate = $start_rate" >> "${outfile}"
echo "trial = $trial" >> "${outfile}"
echo "trial_name = $trial_name" >> "${outfile}"


echo -e "\n\n"

echo "
DUT Configuration:
------------------
Bridge phy-br-0
    Port dpdk-0
    Port vm0-vhost-user-0-n1
Bridge phy-br-1
    Port vm9-vhost-user-1-n1
    Port dpdk-1
Bridge phy-br-2
    Port vm0-vhost-user-1-n1
    Port vm1-vhost-user-0-n1
Bridge phy-br-3
    Port vm1-vhost-user-1-n1
    Port vm2-vhost-user-0-n1
Bridge phy-br-4
    Port vm2-vhost-user-1-n1
    Port vm3-vhost-user-0-n1
Bridge phy-br-5
    Port vm3-vhost-user-1-n1
    Port vm4-vhost-user-0-n1
Bridge phy-br-6
    Port vm4-vhost-user-1-n1
    Port vm5-vhost-user-0-n1
Bridge phy-br-7
    Port vm5-vhost-user-1-n1
    Port vm6-vhost-user-0-n1
Bridge phy-br-8
    Port vm6-vhost-user-1-n1
    Port vm7-vhost-user-0-n1
Bridge phy-br-9
    Port vm7-vhost-user-1-n1
    Port vm8-vhost-user-0-n1
Bridge phy-br-10
    Port vm8-vhost-user-1-n1
    Port vm9-vhost-user-0-n1" >> "${outfile}"

echo -e "\n\n" >> "${outfile}"

echo "=====================================================================" >> "${outfile}"
echo "ovs-ofctl dump-ports <bridge>" >> "${outfile}"
echo -e "=====================================================================\n" >> "${outfile}"

echo "ovs-ofctl dump-ports phy-br-0" >> "${outfile}"
echo "dpdk-0: " >> "${outfile}"
ovs-vsctl list interface dpdk-0 | grep "ofport " >> "${outfile}"
echo "vm0-vhost-user-0-n1: " >> "${outfile}"
ovs-vsctl list interface vm0-vhost-user-0-n1 | grep "ofport " >> "${outfile}"
echo "" >> "${outfile}"
ovs-ofctl dump-ports phy-br-0 >> "${outfile}"

echo "" >> "${outfile}"

echo "ovs-ofctl dump-ports phy-br-1" >> "${outfile}"
echo "vm9-vhost-user-0-n1: " >> "${outfile}"
ovs-vsctl list interface vm9-vhost-user-1-n1 | grep "ofport " >> "${outfile}"
echo "dpdk-1: " >> "${outfile}"
ovs-vsctl list interface dpdk-1 | grep "ofport " >> "${outfile}"
echo "" >> "${outfile}"
ovs-ofctl dump-ports phy-br-1 >> "${outfile}"

echo "" >> "${outfile}"

echo "ovs-ofctl dump-ports phy-br-2" >> "${outfile}"
echo "vm0-vhost-user-1-n1: " >> "${outfile}"
ovs-vsctl list interface vm0-vhost-user-1-n1 | grep "ofport " >> "${outfile}"
echo "vm1-vhost-user-0-n1: " >> "${outfile}"
ovs-vsctl list interface vm1-vhost-user-0-n1 | grep "ofport " >> "${outfile}"
echo "" >> "${outfile}"
ovs-ofctl dump-ports phy-br-2 >> "${outfile}"

echo "" >> "${outfile}"

echo "ovs-ofctl dump-ports phy-br-3" >> "${outfile}"
echo "vm1-vhost-user-1-n1: " >> "${outfile}"
ovs-vsctl list interface vm1-vhost-user-1-n1 | grep "ofport " >> "${outfile}"
echo "vm2-vhost-user-0-n1: " >> "${outfile}"
ovs-vsctl list interface vm2-vhost-user-0-n1 | grep "ofport " >> "${outfile}"
echo "" >> "${outfile}"
ovs-ofctl dump-ports phy-br-3 >> "${outfile}"

echo "" >> "${outfile}"

echo "ovs-ofctl dump-ports phy-br-4" >> "${outfile}"
echo "vm2-vhost-user-1-n1: " >> "${outfile}"
ovs-vsctl list interface vm2-vhost-user-1-n1 | grep "ofport " >> "${outfile}"
echo "vm3-vhost-user-0-n1: " >> "${outfile}"
ovs-vsctl list interface vm3-vhost-user-0-n1 | grep "ofport " >> "${outfile}"
echo "" >> "${outfile}"
ovs-ofctl dump-ports phy-br-4 >> "${outfile}"

echo "" >> "${outfile}"

echo "ovs-ofctl dump-ports phy-br-5" >> "${outfile}"
echo "vm3-vhost-user-1-n1: " >> "${outfile}"
ovs-vsctl list interface vm3-vhost-user-1-n1 | grep "ofport " >> "${outfile}"
echo "vm4-vhost-user-0-n1: " >> "${outfile}"
ovs-vsctl list interface vm4-vhost-user-0-n1 | grep "ofport " >> "${outfile}"
echo "" >> "${outfile}"
ovs-ofctl dump-ports phy-br-5 >> "${outfile}"

echo "" >> "${outfile}"

echo "ovs-ofctl dump-ports phy-br-6" >> "${outfile}"
echo "vm4-vhost-user-1-n1: " >> "${outfile}"
ovs-vsctl list interface vm4-vhost-user-1-n1 | grep "ofport " >> "${outfile}"
echo "vm5-vhost-user-0-n1: " >> "${outfile}"
ovs-vsctl list interface vm5-vhost-user-0-n1 | grep "ofport " >> "${outfile}"
echo "" >> "${outfile}"
ovs-ofctl dump-ports phy-br-6 >> "${outfile}"

echo "" >> "${outfile}"

echo "ovs-ofctl dump-ports phy-br-7" >> "${outfile}"
echo "vm5-vhost-user-1-n1: " >> "${outfile}"
ovs-vsctl list interface vm5-vhost-user-1-n1 | grep "ofport " >> "${outfile}"
echo "vm6-vhost-user-0-n1: " >> "${outfile}"
ovs-vsctl list interface vm6-vhost-user-0-n1 | grep "ofport " >> "${outfile}"
echo "" >> "${outfile}"
ovs-ofctl dump-ports phy-br-7 >> "${outfile}"

echo "" >> "${outfile}"

echo "ovs-ofctl dump-ports phy-br-8" >> "${outfile}"
echo "vm6-vhost-user-1-n1: " >> "${outfile}"
ovs-vsctl list interface vm6-vhost-user-1-n1 | grep "ofport " >> "${outfile}"
echo "vm7-vhost-user-0-n1: " >> "${outfile}"
ovs-vsctl list interface vm7-vhost-user-0-n1 | grep "ofport " >> "${outfile}"
echo "" >> "${outfile}"
ovs-ofctl dump-ports phy-br-8 >> "${outfile}"

echo "" >> "${outfile}"

echo "ovs-ofctl dump-ports phy-br-9" >> "${outfile}"
echo "vm7-vhost-user-1-n1: " >> "${outfile}"
ovs-vsctl list interface vm7-vhost-user-1-n1 | grep "ofport " >> "${outfile}"
echo "vm8-vhost-user-0-n1: " >> "${outfile}"
ovs-vsctl list interface vm8-vhost-user-0-n1 | grep "ofport " >> "${outfile}"
echo "" >> "${outfile}"
ovs-ofctl dump-ports phy-br-9 >> "${outfile}"

echo "" >> "${outfile}"

echo "ovs-ofctl dump-ports phy-br-10" >> "${outfile}"
echo "vm8-vhost-user-1-n1: " >> "${outfile}"
ovs-vsctl list interface vm8-vhost-user-1-n1 | grep "ofport " >> "${outfile}"
echo "vm9-vhost-user-0-n1: " >> "${outfile}"
ovs-vsctl list interface vm9-vhost-user-0-n1 | grep "ofport " >> "${outfile}"
echo "" >> "${outfile}"
ovs-ofctl dump-ports phy-br-10 >> "${outfile}"

echo "" >> "${outfile}"
echo "" >> "${outfile}"

echo -e "\n=====================================================================" >> "${outfile}"
echo "ovs-vsctl get interface <iface> statistics" >> "${outfile}"
echo -e "=====================================================================\n" >> "${outfile}"

echo "Bridge phy-br-0
    Port dpdk-0
    Port vm0-vhost-user-0-n1" >> "${outfile}"
echo "" >> "${outfile}"
echo "ovs-vsctl get interface dpdk-0 statistics" >> "${outfile}"
ovs-vsctl get interface dpdk-0 statistics >> "${outfile}"
echo "" >> "${outfile}"
echo "ovs-vsctl get interface vm0-vhost-user-0-n1 statistics" >> "${outfile}"
ovs-vsctl get interface vm0-vhost-user-0-n1 statistics >> "${outfile}"

echo "" >> "${outfile}"
echo "Bridge phy-br-1
    Port vm9-vhost-user-1-n1
    Port dpdk-1" >> "${outfile}"

echo "ovs-vsctl get interface vm9-vhost-user-0-n1 statistics" >> "${outfile}"
ovs-vsctl get interface vm9-vhost-user-0-n1 statistics >> "${outfile}"
echo "" >> "${outfile}"
echo "ovs-vsctl get interface dpdk-1 statistics" >> "${outfile}"
ovs-vsctl get interface dpdk-1 statistics >> "${outfile}"


echo "" >> "${outfile}"
echo "Bridge phy-br-2
    Port vm0-vhost-user-1-n1
    Port vm1-vhost-user-0-n1" >> "${outfile}"

echo "" >> "${outfile}"
echo "ovs-vsctl get interface vm0-vhost-user-1-n1 statistics" >> "${outfile}"
ovs-vsctl get interface vm0-vhost-user-1-n1 statistics >> "${outfile}"
echo "" >> "${outfile}"
echo "ovs-vsctl get interface vm1-vhost-user-0-n1 statistics" >> "${outfile}"
ovs-vsctl get interface vm1-vhost-user-0-n1 statistics >> "${outfile}"

echo "" >> "${outfile}"
echo "Bridge phy-br-3
    Port vm1-vhost-user-1-n1
    Port vm2-vhost-user-0-n1" >> "${outfile}"

echo "" >> "${outfile}"
echo "ovs-vsctl get interface vm1-vhost-user-1-n1 statistics" >> "${outfile}"
ovs-vsctl get interface vm1-vhost-user-1-n1 statistics >> "${outfile}"
echo "" >> "${outfile}"
echo "ovs-vsctl get interface vm2-vhost-user-0-n1 statistics" >> "${outfile}"
ovs-vsctl get interface vm2-vhost-user-0-n1 statistics >> "${outfile}"

echo "" >> "${outfile}"
echo "Bridge phy-br-4
    Port vm2-vhost-user-1-n1
    Port vm3-vhost-user-0-n1" >> "${outfile}"


echo "" >> "${outfile}"
echo "ovs-vsctl get interface vm2-vhost-user-1-n1 statistics" >> "${outfile}"
ovs-vsctl get interface vm2-vhost-user-1-n1 statistics >> "${outfile}"
echo "" >> "${outfile}"
echo "ovs-vsctl get interface vm3-vhost-user-0-n1 statistics" >> "${outfile}"
ovs-vsctl get interface vm3-vhost-user-0-n1 statistics >> "${outfile}"

echo "" >> "${outfile}"
echo "Bridge phy-br-5
    Port vm3-vhost-user-1-n1
    Port vm4-vhost-user-0-n1" >> "${outfile}"

echo "" >> "${outfile}"
echo "ovs-vsctl get interface vm3-vhost-user-1-n1 statistics" >> "${outfile}"
ovs-vsctl get interface vm3-vhost-user-1-n1 statistics >> "${outfile}"
echo "" >> "${outfile}"
echo "ovs-vsctl get interface vm4-vhost-user-0-n1 statistics" >> "${outfile}"
ovs-vsctl get interface vm4-vhost-user-0-n1 statistics >> "${outfile}"


echo "" >> "${outfile}"
echo "Bridge phy-br-6
    Port vm4-vhost-user-1-n1
    Port vm5-vhost-user-0-n1" >> "${outfile}"

echo "" >> "${outfile}"
echo "ovs-vsctl get interface vm4-vhost-user-1-n1 statistics" >> "${outfile}"
ovs-vsctl get interface vm4-vhost-user-1-n1 statistics >> "${outfile}"
echo "" >> "${outfile}"
echo "ovs-vsctl get interface vm5-vhost-user-0-n1 statistics" >> "${outfile}"
ovs-vsctl get interface vm5-vhost-user-0-n1 statistics >> "${outfile}"


echo "" >> "${outfile}"
echo "Bridge phy-br-7
    Port vm5-vhost-user-1-n1
    Port vm6-vhost-user-0-n1" >> "${outfile}"

echo "" >> "${outfile}"
echo "ovs-vsctl get interface vm5-vhost-user-1-n1 statistics" >> "${outfile}"
ovs-vsctl get interface vm5-vhost-user-1-n1 statistics >> "${outfile}"
echo "" >> "${outfile}"
echo "ovs-vsctl get interface vm6-vhost-user-0-n1 statistics" >> "${outfile}"
ovs-vsctl get interface vm6-vhost-user-0-n1 statistics >> "${outfile}"


echo "" >> "${outfile}"
echo "Bridge phy-br-8
    Port vm6-vhost-user-1-n1
    Port vm7-vhost-user-0-n1" >> "${outfile}"

echo "" >> "${outfile}"
echo "ovs-vsctl get interface vm6-vhost-user-1-n1 statistics" >> "${outfile}"
ovs-vsctl get interface vm6-vhost-user-1-n1 statistics >> "${outfile}"
echo "" >> "${outfile}"
echo "ovs-vsctl get interface vm7-vhost-user-0-n1 statistics" >> "${outfile}"
ovs-vsctl get interface vm7-vhost-user-0-n1 statistics >> "${outfile}"


echo "" >> "${outfile}"
echo "Bridge phy-br-9
    Port vm7-vhost-user-1-n1
    Port vm8-vhost-user-0-n1" >> "${outfile}"

echo "" >> "${outfile}"
echo "ovs-vsctl get interface vm7-vhost-user-1-n1 statistics" >> "${outfile}"
ovs-vsctl get interface vm7-vhost-user-1-n1 statistics >> "${outfile}"
echo "" >> "${outfile}"
echo "ovs-vsctl get interface vm8-vhost-user-0-n1 statistics" >> "${outfile}"
ovs-vsctl get interface vm8-vhost-user-0-n1 statistics >> "${outfile}"



echo "" >> "${outfile}"
echo "Bridge phy-br-10
    Port vm8-vhost-user-1-n1
    Port vm9-vhost-user-0-n1" >> "${outfile}"

echo "" >> "${outfile}"
echo "ovs-vsctl get interface vm8-vhost-user-1-n1 statistics" >> "${outfile}"
ovs-vsctl get interface vm8-vhost-user-1-n1 statistics >> "${outfile}"
echo "" >> "${outfile}"
echo "ovs-vsctl get interface vm9-vhost-user-0-n1 statistics" >> "${outfile}"
ovs-vsctl get interface vm9-vhost-user-0-n1 statistics >> "${outfile}"




echo "=====================================================================" >> "${outfile}"
echo "ovs-appctl dpif-netdev/pmd-perf-show" >> "${outfile}"
echo -e "=====================================================================\n" >> "${outfile}"
ovs-appctl dpif-netdev/pmd-perf-show >> "${outfile}"
echo -e "\n\n=====================================================================" >> "${outfile}"
echo "ovs-appctl dpif-netdev/pmd-perf-show | grep -e numa -e packets" >> "${outfile}"
echo -e "=====================================================================\n" >> "${outfile}"
ovs-appctl dpif-netdev/pmd-perf-show | grep -e numa -e packets >> "${outfile}"
echo -e "\n\n=====================================================================" >> "${outfile}"
echo "ovs-appctl dpctl/show --statistics" >> "${outfile}"
echo -e "=====================================================================\n" >> "${outfile}"
ovs-appctl dpctl/show --statistics >> "${outfile}"
echo -e "\n\n=====================================================================" >> "${outfile}"
echo "ovs-appctl dpif-netdev/pmd-stats-show" >> "${outfile}"
echo -e "=====================================================================\n" >> "${outfile}"
ovs-appctl dpif-netdev/pmd-stats-show >> "${outfile}"
echo -e "\n\n=====================================================================" >> "${outfile}"
echo "=====================================================================" >> "${outfile}"
echo "=====================================================================" >> "${outfile}"
echo "ovs-vsctl show" >> "${outfile}"
echo -e "=====================================================================\n" >> "${outfile}"
ovs-vsctl show >> "${outfile}"



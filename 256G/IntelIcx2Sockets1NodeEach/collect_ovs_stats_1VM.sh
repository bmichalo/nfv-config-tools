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
    Port vm0-vhost-user-1-n1
    Port dpdk-1" >> "${outfile}"

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
echo "vm0-vhost-user-0-n1: " >> "${outfile}"
ovs-vsctl list interface vm0-vhost-user-1-n1 | grep "ofport " >> "${outfile}"
echo "dpdk-1: " >> "${outfile}"
ovs-vsctl list interface dpdk-1 | grep "ofport " >> "${outfile}"
echo "" >> "${outfile}"
ovs-ofctl dump-ports phy-br-1 >> "${outfile}"

echo "" >> "${outfile}"


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
    Port vm0-vhost-user-1-n1
    Port dpdk-1" >> "${outfile}"

echo "ovs-vsctl get interface vm0-vhost-user-0-n1 statistics" >> "${outfile}"
ovs-vsctl get interface vm0-vhost-user-0-n1 statistics >> "${outfile}"
echo "" >> "${outfile}"
echo "ovs-vsctl get interface dpdk-1 statistics" >> "${outfile}"
ovs-vsctl get interface dpdk-1 statistics >> "${outfile}"


echo "" >> "${outfile}"


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



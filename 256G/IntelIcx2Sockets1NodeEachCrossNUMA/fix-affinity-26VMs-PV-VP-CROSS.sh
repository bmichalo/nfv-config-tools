#!/bin/bash


echo "*****************************************************"
echo "* Fixing 26VMs PMD / CPU Affinity for PV-VV-VV-VV-VP *"
echo "*****************************************************"
echo ""

echo "* Original affinity settings...                "
echo ""

ovs-appctl dpif-netdev/pmd-rxq-show
echo""


#cpu_list=1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,91,92,93,94,95,97,98,99,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119,120,121,122,123,124,125,126,127


cpu_list=3,5,6,10,11,14,15,18,19,22,23,26,27,30,31,34,35,38,39,42,43,46,47,51,55,59,63,67,69,70,74,75,78,79,82,83,86,87,90,91,94,95,98,99,102,103,106,107,110,111,115,119,123,127


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
this_cpu_thread=3
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread

iface=vm0-vhost-user-0-n1
this_cpu_thread=67
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread

# phy-br-1
iface=vm25-vhost-user-1-n1
this_cpu_thread=5
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread

iface=dpdk-1
this_cpu_thread=69
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread


# phy-br-2
iface=vm0-vhost-user-1-n1
this_cpu_thread=63
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread

iface=vm1-vhost-user-0-n1
this_cpu_thread=127
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread


# phy-br-3
iface=vm1-vhost-user-1-n1
this_cpu_thread=59
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread

iface=vm2-vhost-user-0-n1
this_cpu_thread=123
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread


# phy-br-4
iface=vm2-vhost-user-1-n1
this_cpu_thread=55
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread

iface=vm3-vhost-user-0-n1
this_cpu_thread=119
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread



# phy-br-5
iface=vm3-vhost-user-1-n1
this_cpu_thread=51
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread

iface=vm4-vhost-user-0-n1
this_cpu_thread=115
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread


# phy-br-6
iface=vm4-vhost-user-1-n1
this_cpu_thread=47
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread

iface=vm5-vhost-user-0-n1
this_cpu_thread=111
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread



# phy-br-7
iface=vm5-vhost-user-1-n1
this_cpu_thread=43
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread

iface=vm6-vhost-user-0-n1
this_cpu_thread=107
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread



# phy-br-8
iface=vm6-vhost-user-1-n1
this_cpu_thread=39
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread

iface=vm7-vhost-user-0-n1
this_cpu_thread=103
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread


# phy-br-9
iface=vm7-vhost-user-1-n1
this_cpu_thread=35
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread

iface=vm8-vhost-user-0-n1
this_cpu_thread=99
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread


# phy-br-10
iface=vm8-vhost-user-1-n1
this_cpu_thread=31
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread

iface=vm9-vhost-user-0-n1
this_cpu_thread=95
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread



# phy-br-11
iface=vm9-vhost-user-1-n1
this_cpu_thread=27
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread

iface=vm10-vhost-user-0-n1
this_cpu_thread=91
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread



# phy-br-12
iface=vm10-vhost-user-1-n1
this_cpu_thread=23
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread

iface=vm11-vhost-user-0-n1
this_cpu_thread=87
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread



# phy-br-13
iface=vm11-vhost-user-1-n1
this_cpu_thread=19
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread

iface=vm12-vhost-user-0-n1
this_cpu_thread=83
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread



# phy-br-14
iface=vm12-vhost-user-1-n1
this_cpu_thread=15
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread

iface=vm13-vhost-user-0-n1
this_cpu_thread=79
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread


# phy-br-15
iface=vm13-vhost-user-1-n1
this_cpu_thread=11
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread

iface=vm14-vhost-user-0-n1
this_cpu_thread=75
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread


# phy-br-16
iface=vm14-vhost-user-1-n1
this_cpu_thread=6
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread

iface=vm15-vhost-user-0-n1
this_cpu_thread=70
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread



# phy-br-17
iface=vm15-vhost-user-1-n1
this_cpu_thread=10
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread

iface=vm16-vhost-user-0-n1
this_cpu_thread=74
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread


# phy-br-18
iface=vm16-vhost-user-1-n1
this_cpu_thread=14
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread

iface=vm17-vhost-user-0-n1
this_cpu_thread=78
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread



# phy-br-19
iface=vm17-vhost-user-1-n1
this_cpu_thread=18
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread

iface=vm18-vhost-user-0-n1
this_cpu_thread=82
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread


# phy-br-20
iface=vm18-vhost-user-1-n1
this_cpu_thread=22
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread

iface=vm19-vhost-user-0-n1
this_cpu_thread=86
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread



# phy-br-21
iface=vm19-vhost-user-1-n1
this_cpu_thread=26
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread

iface=vm20-vhost-user-0-n1
this_cpu_thread=90
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread



# phy-br-22
iface=vm20-vhost-user-1-n1
this_cpu_thread=30
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread

iface=vm21-vhost-user-0-n1
this_cpu_thread=94
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread



# phy-br-23
iface=vm21-vhost-user-1-n1
this_cpu_thread=34
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread

iface=vm22-vhost-user-0-n1
this_cpu_thread=98
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread


# phy-br-24
iface=vm22-vhost-user-1-n1
this_cpu_thread=38
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread

iface=vm23-vhost-user-0-n1
this_cpu_thread=102
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread


# phy-br-25
iface=vm23-vhost-user-1-n1
this_cpu_thread=42
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread

iface=vm24-vhost-user-0-n1
this_cpu_thread=106
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread


# phy-br-26
iface=vm24-vhost-user-1-n1
this_cpu_thread=46
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread

iface=vm25-vhost-user-0-n1
this_cpu_thread=110
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread





echo ""

echo "* New affinity settings...                "
echo ""

ovs-appctl dpif-netdev/pmd-rxq-show
echo ""
echo "ovs-appctl dpif-netdev/pmd-rxq-show"
echo ""


#!/bin/bash


echo "********************************************************"
echo "* Fixing 11 VMs PMD / CPU Affinity for PV-VV-...-VV-VP *"
echo "********************************************************"
echo ""

echo "* Original affinity settings...                "
echo ""

ovs-appctl dpif-netdev/pmd-rxq-show
echo""

cpu_list=1,4,6,8,10,12,14,16,18,20,22,31,36,38,40,42,44,46,48,50,52,54,56,65,68,70,72,74,76,78,80,82,84,86,95,100,102,104,106,108,110,112,114,116,118,120

#cpu_list=1,4,6,8,10,12,14,16,18,20,22,24,26,28,31,65,68,70,72,74,76,78,80,82,84,86,88,90,92,95
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
iface=vm0-vhost-user-1-n0
this_cpu_thread=4
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread

iface=vm1-vhost-user-0-n0
this_cpu_thread=68
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread



# phy-br-2
iface=vm1-vhost-user-1-n0
this_cpu_thread=6
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread

iface=vm2-vhost-user-0-n0
this_cpu_thread=70
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread



# phy-br-3
iface=vm2-vhost-user-1-n0
this_cpu_thread=8
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread

iface=vm3-vhost-user-0-n0
this_cpu_thread=72
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread




# phy-br-4
iface=vm3-vhost-user-1-n0
this_cpu_thread=10
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread

iface=vm4-vhost-user-0-n0
this_cpu_thread=74
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread




# phy-br-5
iface=vm4-vhost-user-1-n0
this_cpu_thread=12
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread

iface=vm5-vhost-user-0-n0
this_cpu_thread=76
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread





# phy-br-6
iface=vm5-vhost-user-1-n0
this_cpu_thread=14
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread

iface=vm6-vhost-user-0-n0
this_cpu_thread=78
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread


# phy-br-7
iface=vm6-vhost-user-1-n0
this_cpu_thread=16
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread

iface=vm7-vhost-user-0-n0
this_cpu_thread=80
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread



# phy-br-8
iface=vm7-vhost-user-1-n0
this_cpu_thread=18
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread

iface=vm8-vhost-user-0-n0
this_cpu_thread=82
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread



# phy-br-9
iface=vm8-vhost-user-1-n0
this_cpu_thread=20
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread

iface=vm9-vhost-user-0-n0
this_cpu_thread=84
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread


# phy-br-10
iface=vm9-vhost-user-1-n0
this_cpu_thread=22
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread

iface=vm10-vhost-user-0-n0
this_cpu_thread=86
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread


# phy-br-11
iface=vm10-vhost-user-1-n0
this_cpu_thread=36
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread

iface=vm11-vhost-user-0-n1
this_cpu_thread=100
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread


# phy-br-12
iface=vm11-vhost-user-1-n1
this_cpu_thread=38
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread

iface=vm12-vhost-user-0-n1
this_cpu_thread=102
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread



# phy-br-13
iface=vm12-vhost-user-1-n1
this_cpu_thread=40
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread

iface=vm13-vhost-user-0-n1
this_cpu_thread=104
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread



# phy-br-14
iface=vm13-vhost-user-1-n1
this_cpu_thread=42
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread

iface=vm14-vhost-user-0-n1
this_cpu_thread=106
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread



# phy-br-15
iface=vm14-vhost-user-1-n1
this_cpu_thread=44
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread

iface=vm15-vhost-user-0-n1
this_cpu_thread=108
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread



# phy-br-16
iface=vm15-vhost-user-1-n1
this_cpu_thread=46
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread

iface=vm16-vhost-user-0-n1
this_cpu_thread=110
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread



# phy-br-17
iface=vm16-vhost-user-1-n1
this_cpu_thread=48
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread

iface=vm17-vhost-user-0-n1
this_cpu_thread=112
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread



# phy-br-18
iface=vm17-vhost-user-1-n1
this_cpu_thread=50
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread

iface=vm18-vhost-user-0-n1
this_cpu_thread=114
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread



# phy-br-19
iface=vm18-vhost-user-1-n1
this_cpu_thread=52
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread

iface=vm19-vhost-user-0-n1
this_cpu_thread=116
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread



# phy-br-20
iface=vm19-vhost-user-1-n1
this_cpu_thread=54
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread

iface=vm20-vhost-user-0-n1
this_cpu_thread=118
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread



# phy-br-21
iface=vm20-vhost-user-1-n1
this_cpu_thread=56
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread

iface=vm21-vhost-user-0-n1
this_cpu_thread=120
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread





# phy-br-22
iface=vm21-vhost-user-1-n1
this_cpu_thread=31
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread

iface=dpdk-1
this_cpu_thread=95
echo "ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread"
ovs-vsctl set Interface $iface other_config:pmd-rxq-affinity=0:$this_cpu_thread


: <<'END'
END

echo ""

echo "* New affinity settings...                "
echo ""

ovs-appctl dpif-netdev/pmd-rxq-show
echo ""


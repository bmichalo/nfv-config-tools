#!/bin/bash


nps=$( numactl -H | grep available | awk '{print $2}' )
outfile="outfileMemProfileNPS$nps"
echo "$HOSTNAME" | tee -a $outfile
echo "NPS = $nps" | tee -a $outfile
echo "$( uname -r )" | tee -a $outfile
echo "$( cat /etc/redhat-release )" | tee -a $outfile
echo "==============================================================================================================================" | tee -a $outfile
echo "sysbench memory --memory-block-size=1K --memory-scope=global --memory-total-size=100G --memory-oper=read run" | tee -a $outfile
sysbench memory --memory-block-size=1K --memory-scope=global --memory-total-size=100G --memory-oper=read run | tee -a $outfile
echo "==============================================================================================================================" | tee -a $outfile
echo "sysbench memory --memory-block-size=1K --memory-scope=global --memory-total-size=100G --memory-oper=write run" | tee -a $outfile
sysbench memory --memory-block-size=1K --memory-scope=global --memory-total-size=100G --memory-oper=read run | tee -a $outfile
echo "==============================================================================================================================" | tee -a $outfile
echo "sysbench memory --memory-block-size=1M --memory-total-size=100G run" | tee -a $outfile
sysbench memory --memory-block-size=1M --memory-total-size=100G run | tee -a $outfile
echo "==============================================================================================================================" | tee -a $outfile
echo "dmidecode -t memory" | tee -a $outfile
dmidecode -t memory | tee -a $outfile
echo "==============================================================================================================================" | tee -a $outfile
echo "lshw -short -C memory" | tee -a $outfile
lshw -short -C memory | tee -a $outfile
echo "==============================================================================================================================" | tee -a $outfile
echo "lshw -short -C memory" | tee -a $outfile
lshw -short -C memory | tee -a $outfile
echo "==============================================================================================================================" | tee -a $outfile
echo "lshw -C memory" | tee -a $outfile
lshw -C memory | tee -a $outfile
echo "==============================================================================================================================" | tee -a $outfile
echo "numastat -m" | tee -a $outfile
numastat -m memory | tee -a $outfile
echo "==============================================================================================================================" | tee -a $outfile
echo "cat /proc/cpuinfo" | tee -a $outfile
cat /proc/cpuinfo | tee -a $outfile


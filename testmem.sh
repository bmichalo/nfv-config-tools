#!/bin/bash


nps=$( numactl -H | grep available | awk '{print $2}' )
outfile="outfileNPS$nps"
echo "$HOSTNAME" | tee -a $outfile
echo "NPS = $nps"
echo "sysbench --test=memory --memory-block-size=1K --memory-scope=global --memory-total-size=100G --memory-oper=read run" | tee -a $outfile
sysbench --test=memory --memory-block-size=1K --memory-scope=global --memory-total-size=100G --memory-oper=read run | tee -a $outfile
echo "sysbench --test=memory --memory-block-size=1K --memory-scope=global --memory-total-size=100G --memory-oper=write run" | tee -a $outfile
sysbench --test=memory --memory-block-size=1K --memory-scope=global --memory-total-size=100G --memory-oper=read run | tee -a $outfile
echo "sysbench --test=memory --memory-block-size=1M --memory-total-size=100G run" | tee -a $outfile
sysbench --test=memory --memory-block-size=1M --memory-total-size=100G run | tee -a $outfile
echo "==============================================================================================================================" | tee -a $outfile
echo "dmidecode -t memory" | tee -a $outfile
dmidecode -t memory | tee -a $outfile


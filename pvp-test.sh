#!/bin/bash

./1VM-mlx-start-vswitch.sh --devices=0000:c4:00.0,0000:c4:00.1 --dataplane=dpdk --dpdk-nic-kmod=mlx5_core --switch=ovs --topology=pv,vp --use-ht=y --numa-mode=strict --switch-mode=l2-bridge

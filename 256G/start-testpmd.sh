/usr/bin/dpdk-testpmd -v -l 1,2,3 --socket-mem 1024,0 -n 4 --proc-type auto --file-prefix testpmd0 -a 0000:10:00.0 -a 0000:11:00.0 -- --nb-cores=2 --nb-ports=2 --portmask=3 --auto-start --rxq=1 --txq=1 --rxd=1024 --txd=1024 -i
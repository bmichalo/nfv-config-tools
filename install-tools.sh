#!/bin/bash

#subscription-manager register --username bmichalowski --password '#!1RedHat$' --auto-attach
#subscription-manager repos --enable ansible-2.9-for-rhel-8-x86_64-rpms
#subscription-manager repos --enable codeready-builder-for-rhel-8-x86_64-rpms
#subscription-manager repos --enable=fast-datapath-for-rhel-8-x86_64-rpms
#dnf install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
dnf -y install git
dnf -y install vim
dnf -y install gcc
dnf -y install ncurses-devel
dnf -y install tar
dnf -y install make
dnf -y install python36
dnf -y install tmux
dnf -y install numactl
dnf -y install xz-utils
dnf -y install autoconf
dnf -y install hwloc
dnf -y install mlocate
dnf -y install dpdk
dnf -y install dpdk-tools
dnf -y install lsof
dnf -y install driverctl
dnf -y install tuned-profiles-cpu-partitioning.noarch
dnf -y install virt-manager libvirt libvirt-client virt-install virt-viewer
dnf -y install qemu-kvm qemu-img
dnf -y install xauth
dnf -y install wireshark
dnf -y install tree 
#dnf -y install openvswitch2.13
#dnf -y install openvswitch2.13-devel
dnf -y install redhat-lsb-core
dnf -y install ansible
dnf -y install automake
dnf -y install uperf
dnf -y install kernel-devel
dnf -y install rpm-build
dnf -y install elfutils-libelf-devel
dnf -y install tuna
dnf -y install htop
dnf -y install screen
dnf -y install dpdk-devel
dnf -y install numactl-devel

cd /etc/selinux
sed -i -e 's/SELINUX=permissive/SELINUX=disabled/g' config
sed -i -e 's/SELINUX=enforcing/SELINUX=disabled/g' config

# Add this to .bash_profile:
# export ANSIBLE_ROLES_PATH=$HOME/.ansible/collections/ansible_collections/pbench/agent/roles:$ANSIBLE_ROLES_PATH
# source .bash_profile
#

# ssh-keygen -b 2048 -t rsa
# ssh-copy-id localhost
# ssh-copy-id <peer server>

# ansible-galaxy collection install pbench.agent 
# git config --global http.sslVerify false
# git clone https://code.engineering.redhat.com/gerrit/perf-dept
# cd .config/Inventory/
# vim repo-bootstrap.hosts
# Add contents:
# [servers]
# localhost
#
# Back in the shell:
# inv=/root/.config/Inventory/repo-bootstrap.hosts
# cd ~
# cd perf-dept/sysadmin/Ansible/
# ansible-playbook  --user=root -i ${inv} repo-bootstrap.yml
# cd ~/.config/Inventory
# vim myhosts.inv
# Add content:
#[servers]
#localhost
#
## DO NOT CHANGE ANYTHING BELOW THIS LINE
#[servers:vars]
#pbench_repo_url_prefix = https://copr-be.cloud.fedoraproject.org/results/ndokos
#
## where to get the key
#pbench_key_url = http://git.app.eng.bos.redhat.com/git/pbench.git/plain/agent/{{ pbench_configuration_environment }}/ssh
#
# where to get the config file
#pbench_config_url = http://git.app.eng.bos.redhat.com/git/pbench.git/plain/agent/{{ pbench_configuration_environment }}/config

# http://pbench.perf.lab.eng.bos.redhat.com/agent/installation.html#orgc9f62f1
# Create a playbook (one-time task)
# You can copy the following playbook to some place locally - save it under the name pbench_agent_install.yml.
# cd ~
# vim perf-dept/sysadmin/Ansible/pbench_agent_install.yml
# Add content:
# ---
#- name: install pbench-agent
#  hosts: servers
#  become: yes
#  become_user: root
#
#  # The default value ('production') can be overriddent by cenv, a host-specific
#  # inventory variable.
#  vars:
#    pbench_configuration_environment: "{{ cenv | default('production') }}"
#
#  roles:
#    - pbench_repo_install
#    - pbench_agent_install
#    - pbench_agent_config


# cd perf-dept/sysadmin/Ansible/
# ansible-playbook -i ~/.config/Inventory/myhosts.inv pbench_agent_install.yml
# exit out of the system then ssh back into it.  pbench now available

# cd /opt/
# git clone https://github.com/htop-dev/htop
# cd htop/
# ./autogen.sh
# ./configure 
# make
# make install


# cd /opt/
# mkdir -p /opt/bridge-utils;cd /opt/bridge-utils
# wget https://www.kernel.org/pub/linux/utils/net/bridge-utils/bridge-utils-1.6.tar.xz
# unxz bridge-utils-1.6.tar.xz
# tar xvf bridge-utils-1.6.tar
# cd bridge-utils-1.6
# autoconf
# ./configure;make;make install









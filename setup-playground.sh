#!/bin/bash
# #######
# Copyright (c) 2016 Fortinet All rights reserved
# Author: Nicolas Thomas nthomas_at_fortinet.com
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
#    * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    * See the License for the specific language governing permissions and
#    * limitations under the License.

set -e
export LC_ALL=C

## avoid warnings about utf-8


is-root()
{
    if [ "$(id -u)" == "0" ]; then
	echo "This script is to be run by your normal user using sudo for root"
	exit 77
    fi
}

control_c()
# run if user hits control-c
{
  echo -en "\n*** Ouch! Exiting ***\n"
  # can put some cleaning here
  exit $?
}
 
# trap keyboard interrupt (control-c)
trap control_c SIGINT

usage()
{
cat << EOF
    
setup-playground - This script aims to setup you host to be fully ready for playground usage LXD/Docker peros lab

USAGE: -d /dev/sdaX

  The options  must be passed as follows:
  -d /dev/sdaX   - give a free to use device with zfs type.

 Note: actions requires root privileges use sudo 

EOF
exit 0
}


is-lxd-ready()
{
    is_ready=0
    # check lxc is on zfs
    (dpkg -l zfsutils-linux >/dev/null ) || (is_ready=1;exit 0) 
    ( lxc info |grep "storage:" | grep zfs >/dev/null ) || (is_ready=1;exit 0) 
    if [ "$(id -u)" != "0" ]; then
	lxc launch ubuntu:16.04 testme || is_ready=1 
	lxc exec testme apt update || is_ready=1 
        lxc delete testme --force
    else
	echo "should run this script as a user in the lxd group to check availability"
	exit 2
    fi
 }

lxd-init()
{
    # assume lxd as not been setup correctly 
    sudo lxd init --auto   --storage-backend=zfs --storage-create-device=$PARTITION --storage-pool=lxd
    sudo debconf-set-selections <<< "lxd lxd/bridge-empty-error boolean true"
    sudo debconf-set-selections <<< "lxd lxd/bridge-name string lxdbr0"
    sudo debconf-set-selections <<< "lxd lxd/bridge-ipv6 string false"
    sudo debconf-set-selections <<< "lxd lxd/bridge-ipv4 string true"
    sudo debconf-set-selections <<< "lxd lxd/bridge-ipv4-nat string true"
    sudo debconf-set-selections <<< "lxd lxd/bridge-ipv4-dhcp-first string 10.10.10.10"
    sudo debconf-set-selections <<< "lxd lxd/bridge-ipv4-address string 10.10.10.1"
    sudo debconf-set-selections <<< "lxd lxd/bridge-ipv4-dhcp-last string 10.10.11.253"
    sudo debconf-set-selections <<< "lxd lxd/bridge-ipv4-netmask string 21"
    sudo debconf-set-selections <<< "lxd lxd/setup-bridge string true"
    sudo debconf-set-selections <<< "lxd lxd/bridge-ipv4-dhcp-leases string 510"
    sudo cp lxd-bridge /etc/default/
    sudo dpkg-reconfigure -p high lxd
}


 #check-zfspart()
 #{
    # check the partition is up and type zfs 
     #sudo parted $PARTITION print -m | grep zfs
    
 #}


install-packages()
{
   #  Go passwordless for sudo this is a dev playground DO NOT DO in Prod

    echo “ubuntu ALL=(ALL) NOPASSWD:ALL” > sudo tee /etc/sudoers.d/99-nopasswd
    # install all the package/ppa sudo kernel setup .

    sudo add-apt-repository -y ppa:ubuntu-lxc/lxd-stable
    sudo add-apt-repository -y ppa:juju/stable
    sudo apt update
    sudo apt install zfsutils-linux lxd virt-manager openvswitch-switch-dpdk juju python-openstackclient python-novaclient python-glanceclient python-neutronclient ubuntu-desktop chromium-browser vino python-pip
    [ -f $HOME/.ssh/id_rsa ] ||  ssh-keygen  -t rsa -b 4096 -C "autogenerated key"  -q -P "" -f "$HOME/.ssh/id_rsa"
}

lxd-prod-configure()
{  
   #  # refer to https://github.com/lxc/lxd/blob/master/doc/production-setup.md
    sudo sed -i '/^root:/d' /etc/subuid /etc/subgid
    echo "root:500000:196608"  | sudo tee -a /etc/subgid /etc/subuid
    cat << EOF | sudo tee -a  /etc/security/limits.conf 
#Add    rules to allow LXD in production type of setups
*  soft  nofile  1048576 #  unset  maximum number of open files
*  hard  nofile  1048576  #unset  maximum number of open files
root  soft  nofile  1048576  #unset  maximum number of open files
root  hard  nofile  1048576  #unset  maximum number of open files
*  soft  memlock  unlimited  #unset  maximum locked-in-memory address space (KB)
*  hard  memlock  unlimited #unset  maximum locked-in-memory address space (KB)
EOF

cat << EOF  | sudo tee /etc/sysctl.d/90-lxd.conf 
#Add rules to allow LXD in production type of setups
fs.inotify.max_queued_events=1048576
fs.inotify.max_user_instances=1048576
fs.inotify.max_user_watches=1048576
vm.max_map_count=262144


net.core.netdev_max_backlog=182757

EOF
cat << EOF | sudo tee -a  /etc/sysctl.conf
fs.inotify.max_user_instances=1048576
fs.inotify.max_user_watches=1048576
EOF
sudo rm /usr/lib/sysctl.d/juju-2.0.conf
#To see what is going on
sudo sysctl --system

}
   
OPTS=$(getopt -o hd: --long help,device: \
     -n 'setup-playground' -- "$@")

if [ $? != 0 ] ; then echo "Terminating..." >&2 ; exit 1 ; fi

# Note the quotes around `$OPTS': they are essential!
eval set -- "$OPTS"
MAIN=0
while true ; do
        case "$1" in
                -h|--help) usage ; exit 0 ;;
                -d|--device) PARTITION="$2" ; MAIN=1; shift 2 ;;
                --) shift ; usage ;;
                *) usage; exit 1 ;;
        esac
done

if "$MAIN" != 0 then
   is-root
   install-packages
   is-lxd-ready || lxd-init
   lxd-prod-configure
   echo "You are all set it is highly recommended to restart now"
fi

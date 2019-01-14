#!/bin/bash -x

COMMON_PKGS="lldpd traceroute"
SWITCH_PKGS="bird iptables-persistent"

HOSTNAME=${1}
TYPE=${2}

is_tor() {
  [[ ${1} == 'tor' ]]
}

is_spine() {
  [[ ${1} == 'spine' ]]
}

apt_get="sudo DEBIAN_FRONTEND=noninteractive apt-get -y"

switch_config() {
    # enable ipv4 forwarding
    sudo sed -i 's/#\(net.ipv4.ip_forward\)/\1/g' /etc/sysctl.d/99-sysctl.conf
    sudo sysctl -q -p /etc/sysctl.d/99-sysctl.conf

    if is_spine ${1} ; then
        # add masquerading source NAT rule on spines
        sudo iptables -A POSTROUTING -j MASQUERADE -o eth0 -t nat
        sudo iptables-save | sudo tee /etc/iptables/rules.v4
    fi

    # configure BIRD
    sudo cp /vagrant/bird/${2}.conf /etc/bird/bird.conf
    sudo systemctl restart bird
}

common_config() {
    for s in rpcbind lxcfs snapd lxd iscsid ; do
        sudo systemctl stop ${s}
        sudo systemctl disable ${s}
    done
    sudo cp /vagrant/netplan/${2}.yaml /etc/netplan/01-netcfg.yaml
    # stop dhclient on the TORs as netplan(5) doesn't
    is_tor ${1} && dhclient -x
    sudo netplan apply
    sudo systemctl restart lldpd
}

ADDITIONAL_PKGS=${COMMON_PKGS}
is_spine ${TYPE} || is_tor ${TYPE} && \
  ADDITIONAL_PKGS="${ADDITIONAL_PKGS} ${SWITCH_PKGS}"
${apt_get} update
${apt_get} install ${ADDITIONAL_PKGS}

common_config ${TYPE} ${HOSTNAME}
is_spine ${TYPE} || is_tor ${TYPE} && switch_config ${TYPE} ${HOSTNAME}

exit 0

#!/bin/bash -x

http_proxy=${1}
https_proxy=${2}
if [ "${http_proxy}" != "" ] ; then
    echo 'Acquire::http::Proxy '\""${http_proxy}"\"';' | \
      sudo tee -a /etc/apt/apt.conf
    echo 'http_proxy='"${http_proxy}" | sudo tee -a /etc/environment
fi
if [ "${https_proxy}" != "" ] ; then
    echo 'Acquire::https::Proxy '\""${https_proxy}"\"';' | \
      sudo tee -a /etc/apt/apt.conf
    echo 'https_proxy='"${https_proxy}" | sudo tee -a /etc/environment
fi

sudo rm /etc/apt/apt.conf.d/70debconf

# Cookbook:: bcpc
# Recipe:: neutron-head
#
# Copyright:: 2019 Bloomberg Finance L.P.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'ipaddress'
include_recipe 'bcpc::calico-head'

region = node['bcpc']['cloud']['region']
config = data_bag_item(region, 'config')

mysqladmin = mysqladmin()

# hash used for database creation and access
#
database = {
  'host' => node['bcpc']['mysql']['host'],
  'dbname' => node['bcpc']['neutron']['db']['dbname'],
  'username' => config['neutron']['creds']['db']['username'],
  'password' => config['neutron']['creds']['db']['password'],
}

# hash used for openstack access
#
openstack = {
  'role' => node['bcpc']['keystone']['roles']['admin'],
  'project' => node['bcpc']['keystone']['service_project']['name'],
  'domain' => node['bcpc']['keystone']['service_project']['domain'],
  'username' => config['neutron']['creds']['os']['username'],
  'password' => config['neutron']['creds']['os']['password'],
}

# create neutron user starts
#
execute 'create the neutron user' do
  environment os_adminrc

  command <<-DOC
    openstack user create #{openstack['username']} \
      --domain #{openstack['domain']} \
      --password #{openstack['password']}
  DOC

  not_if <<-DOC
    openstack user show #{openstack['username']} \
      --domain #{openstack['domain']}
  DOC
end

execute 'add admin role to neutron user' do
  environment os_adminrc

  command <<-DOC
    openstack role add #{openstack['role']} \
       --user #{openstack['username']} --project #{openstack['project']}
  DOC

  not_if <<-DOC
    openstack role assignment list --names \
      --role #{openstack['role']} \
      --project #{openstack['project']} \
      --user #{openstack['username']} | grep #{openstack['username']}
  DOC
end
#
# create neutron user ends

# create network service and endpoints starts
#
begin
  type = 'network'
  service = node['bcpc']['catalog'][type]
  project = service['project']

  execute "create the #{project} #{type} service" do
    environment os_adminrc

    name = service['name']
    desc = service['description']

    command <<-DOC
      openstack service create \
        --name "#{name}" --description "#{desc}" #{type}
    DOC

    not_if "openstack service list | grep #{type}"
  end

  %w(admin internal public).each do |uri|
    url = generate_service_catalog_uri(service, uri)

    execute "create the #{project} #{type} #{uri} endpoint" do
      environment os_adminrc

      command <<-DOC
        openstack endpoint create \
          --region #{region} #{type} #{uri} '#{url}'
      DOC

      not_if "openstack endpoint list \
        | grep #{type} | grep #{uri}
      "
    end
  end
end
#
# create network service and endpoints ends

# install haproxy fragment
template '/etc/haproxy/haproxy.d/neutron.cfg' do
  source 'neutron/haproxy.cfg.erb'
  variables(
    headnodes: headnodes(all: true),
    vip: node['bcpc']['cloud']['vip']
  )
  notifies :restart, 'service[haproxy-neutron]', :immediately
end

# neutron package installation and service definition starts
#
package 'neutron-server'
service 'neutron-server'
service 'haproxy-neutron' do
  service_name 'haproxy'
end
#
# neutron package installation and service definition ends

# add neutron to etcd so that it will be able to read the etcd ssl certs
group 'etcd' do
  action :modify
  members 'neutron'
  append true
end

# create/manage neutron database starts
#
file '/tmp/neutron-db.sql' do
  action :nothing
end

template '/tmp/neutron-db.sql' do
  source 'neutron/neutron-db.sql.erb'
  variables(
    db: database
  )
  notifies :run, 'execute[create neutron database]', :immediately
  not_if "
    user=#{mysqladmin['username']}
    db=#{database['dbname']}
    count=$(mysql -u ${user} ${db} -e 'show tables' | wc -l)
    [ $count -gt 0 ]
  ", environment: { 'MYSQL_PWD' => mysqladmin['password'] }
end

execute 'create neutron database' do
  action :nothing
  environment('MYSQL_PWD' => mysqladmin['password'])

  command "mysql -u #{mysqladmin['username']} < /tmp/neutron-db.sql"

  notifies :delete, 'file[/tmp/neutron-db.sql]', :immediately
  notifies :create, 'template[/etc/neutron/neutron.conf]', :immediately
  notifies :create, 'template[/etc/neutron/plugins/ml2/ml2_conf.ini]', :immediately
  notifies :run, 'execute[neutron-db-manage upgrade heads]', :immediately
end

execute 'neutron-db-manage upgrade heads' do
  action :nothing
  command 'su -s /bin/sh -c "neutron-db-manage upgrade heads" neutron'
end
#
# create/manage neutron database ends

# configure neutron starts
#
template '/etc/neutron/neutron.conf' do
  source 'neutron/neutron.conf.erb'
  variables(
    db: database,
    os: openstack,
    config: config,
    headnodes: headnodes(all: true)
  )
  notifies :restart, 'service[neutron-server]', :immediately
end

template '/etc/neutron/plugins/ml2/ml2_conf.ini' do
  source 'neutron/neutron.ml2_conf.ini.erb'
  notifies :restart, 'service[neutron-server]', :immediately
end
#
# configure neutron ends

execute 'wait for neutron to come online' do
  environment os_adminrc
  retries 15
  command 'openstack network list'
end

# create networks starts
node['bcpc']['neutron']['networks'].each do |network|
  fixed_network = network['name']

  raise "#{fixed_network}: no subnets defined" unless network.key?('fixed')

  # create fixed network
  execute "create the #{fixed_network} network" do
    environment os_adminrc

    command <<-DOC
      openstack network create #{fixed_network} \
        --share --provider-network-type local
    DOC

    not_if "openstack network show #{fixed_network}"
  end

  # create fixed subnets
  network['fixed'].fetch('subnets', []).each do |subnet|
    allocation = IPAddress(subnet['allocation'])
    cidr = "#{allocation.network.address}/#{allocation.prefix}"
    subnet_name = "#{fixed_network}-fixed-#{cidr}"

    execute "create the #{fixed_network} network #{subnet_name} subnet" do
      environment os_adminrc

      # convert nameservers list into repeated --dns-nameserver arguments
      nameservers = node['bcpc']['neutron']['network']['nameservers']
      nameservers = nameservers.map do |n|
        "--dns-nameserver #{n}"
      end
      nameservers = nameservers.join(' ')

      command <<-DOC
        openstack subnet create #{subnet_name} \
          #{nameservers} \
          --network #{fixed_network} \
          --subnet-range #{cidr}
      DOC

      not_if <<-DOC
        openstack subnet list -c Subnet -f value | grep -w #{cidr}
      DOC
    end
  end

  next unless network.key?('float')

  # create float network
  float_network = "#{network['name']}-float"

  execute "create the #{float_network} network" do
    environment os_adminrc

    command <<-DOC
      openstack network create #{float_network} --external
    DOC

    not_if "openstack network show #{float_network}"
  end

  # create float subnets
  network['float'].fetch('subnets', []).each do |subnet|
    allocation = IPAddress(subnet['allocation'])
    cidr = "#{allocation.network.address}/#{allocation.prefix}"
    subnet_name = "#{float_network}-#{cidr}"

    execute "create the #{float_network} network #{subnet_name} subnet" do
      environment os_adminrc

      command <<-DOC
        openstack subnet create #{subnet_name} \
          --network #{float_network} --subnet-range #{cidr}
      DOC

      not_if <<-DOC
        openstack subnet list -c Subnet -f value | grep -w #{cidr}
      DOC
    end
  end

  # create router
  router_name = fixed_network

  execute "create the #{fixed_network} network router (#{router_name})" do
    environment os_adminrc

    command <<-DOC
      openstack router create #{router_name}
    DOC

    not_if "openstack router show #{router_name}"
  end

  # add subnets to router
  bash 'add subnets to router' do
    environment os_adminrc
    code <<-EOH
      set -e

      subnets=$(openstack subnet list --network #{fixed_network} -c ID -f value)
      ifaces=$(openstack router show #{router_name} -f json | jq -r .interfaces_info)

      for subnet_id in ${subnets}; do
        exists=$(echo $ifaces | jq --arg SUBNET_ID "$subnet_id" '.[] | select(.subnet_id == $SUBNET_ID)')

        if [ ${#exists} -eq 0 ]; then
          openstack router add subnet #{router_name} ${subnet_id}
        fi
      done
    EOH
  end

  # set router external gateway
  bash 'set external gateway for router' do
    environment os_adminrc

    code <<-EOH
      set -e

      router=$(openstack router show #{router_name} -f json)
      gateway=$(echo ${router} | jq -r .external_gateway_info)

      if [ "${gateway}" = "null" ]; then
        openstack router set #{router_name} --external-gateway #{float_network}
      fi
    EOH
  end
end
# create networks ends

bash 'update admin default security group' do
  environment os_adminrc

  code <<-DOC
    admin_project=#{node['bcpc']['openstack']['admin']['project']}
    id=$(openstack project show ${admin_project} -f value -c id)

    sec_groups=$(openstack security group list --project ${id} -f json)
    sec_id=$(echo ${sec_groups} | jq -r '.[] | select(.Name == "default") .ID')

    for ethertype in IPv4 IPv6; do

      # allow icmp
      if ! openstack security group rule list ${sec_id} \
            --protocol icmp \
            --long -c Ethertype -f value | grep -q ${ethertype}; then

        openstack security group rule create ${sec_id} \
          --protocol icmp \
          --ethertype ${ethertype}

      fi

      # allow ssh, http and https
      for port_range in 22:22 80:80 443:443; do
        if ! openstack security group rule list ${sec_id} \
              --protocol tcp --long \
              -c "Port Range" -c "Ethertype" \
              -f value | grep "${port_range}" | grep "${ethertype}"; then

          [[ ${ethertype} = 'IPv4' ]] && \
            remote_ip='0.0.0.0/0' || remote_ip='::/0'

          openstack security group rule create ${sec_id} \
            --protocol tcp \
            --dst-port ${port_range} \
            --remote-ip ${remote_ip} \
            --ethertype ${ethertype}
        fi
      done

    done
  DOC
end

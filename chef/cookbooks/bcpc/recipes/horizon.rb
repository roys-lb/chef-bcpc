# Cookbook:: bcpc
# Recipe:: horizon
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

region = node['bcpc']['cloud']['region']
config = data_bag_item(region, 'config')

package 'openstack-dashboard'

service 'horizon' do
  service_name 'apache2'
end

execute 'disable old openstack-dashboard config' do
  command 'a2disconf openstack-dashboard'
  only_if 'a2query -c openstack-dashboard'
end

file '/etc/apache2/conf-available/openstack-dashboard.conf' do
  action :delete
end

template '/etc/apache2/sites-available/openstack-dashboard.conf' do
  source 'horizon/apache-openstack-dashboard.conf.erb'
  notifies :run, 'execute[enable openstack-dashboard]', :immediately
  notifies :restart, 'service[horizon]', :immediately
end

execute 'enable openstack-dashboard' do
  command 'a2ensite openstack-dashboard'
  not_if 'a2query -s openstack-dashboard'
end

template '/etc/openstack-dashboard/local_settings.py' do
  source 'horizon/local_settings.py.erb'
  variables(
    config: config,
    headnodes: headnodes(all: true),
    domains: node['bcpc']['keystone'].fetch('domains', [])
  )
  notifies :restart, 'service[horizon]', :delayed
end

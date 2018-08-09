# Cookbook Name:: bcpc
# Recipe:: unbound
#
# Copyright 2018, Bloomberg Finance L.P.
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

package 'unbound'

# libnss-resolve package is needed for glibc based binaries that require name
# resolution from /etc/resolv.conf which is now managed by systemd-resolve
package 'libnss-resolve'

service 'unbound'
service 'systemd-resolved'

template '/etc/default/unbound' do
  source 'unbound/default.erb'
  variables(
    config: node['bcpc']['unbound']['default']
  )
  notifies :restart, 'service[unbound]', :delayed
end

template '/etc/unbound/unbound.conf.d/server.conf' do
  source 'unbound/server.conf.erb'
  variables(
    server: node['bcpc']['unbound']['server'],
    forward: node['bcpc']['unbound']['forward-zone']
  )
  notifies :restart, 'service[unbound]', :delayed
end

# Disable DNSSEC
file '/etc/unbound/unbound.conf.d/root-auto-trust-anchor-file.conf' do
  action :delete
  notifies :restart, 'service[unbound]', :immediately
end

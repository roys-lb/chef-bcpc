# Cookbook:: bcpc
# Recipe:: calico-apt
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

fn = node['bcpc']['calico']['calicoctl']['remote']['file']
fp = "#{Chef::Config[:file_cache_path]}/#{fn}"

remote_file fp do
  mode '755'
  source node['bcpc']['calico']['calicoctl']['remote']['source']
  checksum node['bcpc']['calico']['calicoctl']['remote']['checksum']
  notifies :create, 'remote_file[install calicoctl]', :immediately
end

remote_file 'install calicoctl' do
  action :nothing
  mode '755'
  path '/usr/local/bin/calicoctl'
  source "file://#{fp}"
end

apt_repository 'calico' do
  uri node['bcpc']['calico']['repo']['url']
  distribution node['lsb']['codename']
  components ['main']
  key 'calico/release.key'
end

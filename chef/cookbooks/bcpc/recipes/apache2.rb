#
# Cookbook:: bcpc
# Recipe:: apache2
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
#

region = node['bcpc']['cloud']['region']
config = data_bag_item(region, 'config')

%w(
  apache2
  apache2-utils
  libapache2-mod-fcgid
  libapache2-mod-wsgi
).each do |pkg|
  package pkg
end

service 'apache2'

%w(
  ssl
  wsgi
  proxy_http
  rewrite
  cache
  cache_disk
).each do |mod|
  execute "enable #{mod} apache2 module" do
    command "a2enmod #{mod}"
    not_if "a2query -m #{mod}"
    notifies :restart, 'service[apache2]', :delayed
  end
end

# remote default ssl site conf
file '/etc/apache2/sites-available/default-ssl.conf' do
  action :delete
end

template '/etc/apache2/sites-available/000-default.conf' do
  source 'apache2/default.conf.erb'
  notifies :restart, 'service[apache2]', :delayed
end

template '/var/www/index.html' do
  source 'apache2/index.html.erb'

  version = run_context.cookbook_collection[cookbook_name].metadata.version

  intermediate = config['ssl']['intermediate']
  intermediate = Base64.decode64(intermediate) unless intermediate.nil?

  variables(
    cookbook_version: version,
    vip: node['bcpc']['cloud']['vip'],
    ssl_crt: Base64.decode64(config['ssl']['crt']),
    ssl_intermediate: intermediate
  )
end

template '/etc/apache2/ports.conf' do
  source 'apache2/ports.conf.erb'
  notifies :restart, 'service[apache2]', :immediately
end

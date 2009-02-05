#
# Author:: Tim Dysinger (<tim@dysinger.net>)
# Author:: Benjamin Black (<bb@opscode.com>)
# Copyright:: Copyright (c) 2009 Opscode, Inc.
# License:: Apache License, Version 2.0
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

require 'open-uri'

require_plugin "hostname"
require_plugin "kernel"
require_plugin "network"

def have_ec2_mac?
  network[:interfaces].each do |iface|
    unless iface[:arp].nil?
      return true if iface[:arp].value?("fe:ff:ff:ff:ff:ff")
    end
  end
  false
end

def metadata(id='')
  OpenURI.open_uri("http://169.254.169.254/2008-02-01/meta-data/#{id}").
    read.split("\n").each do |o|
    key = "#{id}#{o.gsub(/\=.*$/, '/')}"
    if key[-1..-1] != '/'
      ec2[key.gsub(/\-|\//, '_').to_sym] =
        OpenURI.open_uri("http://169.254.169.254/2008-02-01" +
                         "/meta-data/#{key}").gets
    else
      metadata(key)
    end
  end
end

if have_ec2_mac?
  ec2 Mash.new
  self.metadata
end

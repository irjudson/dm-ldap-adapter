require 'pathname'
require 'rubygems'

gem 'addressable', '~>2.0'
gem 'rspec', '>1.1.2'

require 'addressable/uri'
require 'spec'

require 'dm-core'

require Pathname(__FILE__).dirname.expand_path.parent + 'lib/ldap_adapter'


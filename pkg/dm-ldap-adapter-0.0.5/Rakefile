require 'pathname'
require 'rubygems'
require 'hoe'

ROOT    = Pathname(__FILE__).dirname.expand_path
JRUBY   = RUBY_PLATFORM =~ /java/
WINDOWS = Gem.win_platform?
SUDO    = (WINDOWS || JRUBY) ? '' : ('sudo' unless ENV['SUDOLESS'])

require ROOT + 'lib/ldap_adapter/version'

# define some constants to help with task files
GEM_NAME    = 'dm-ldap-adapter'
GEM_VERSION = DataMapper::LdapAdapter::VERSION

Hoe.new(GEM_NAME, GEM_VERSION) do |p|
  p.developer('Ivan R. Judson', 'ivan.judson [a] montana [d] edu')

  p.description = 'A DataMapper Adapter for LDAP.'
  p.summary = 'A DataMapper Adapter for LDAP (The Lightweight Directory Access Protocol)'
  p.url = 'http://github.com/irjudson/dm-ldap-adapter'

  p.clean_globs |= %w[ log pkg coverage ]
  p.spec_extras = { :has_rdoc => true, :extra_rdoc_files => %w[ README.txt LICENSE TODO History.txt ] }

  p.extra_deps << ['dm-core', "0.9.11"]

end

Pathname.glob(ROOT.join('tasks/**/*.rb').to_s).each { |f| require f }

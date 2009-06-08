require File.dirname(__FILE__) + '/spec_helper'


require DataMapper.root / 'lib' / 'dm-core' / 'spec' / 'adapter_shared_spec'

describe DataMapper::Adapters::LdapAdapter do
  before :all do
    # This needs to point to a valid ldap server
    @adapter = DataMapper.setup(:default, {:adapter => 'ldap_adapter',
                                :host => HOSTNAME,
                                :port => PORT,
                                :base => LDAP_BASE,
                                :username => LDAP_USER,
                                :password => LDAP_PASSWORD
                               })

  end

  it should_behave_like 'An Adapter'

end

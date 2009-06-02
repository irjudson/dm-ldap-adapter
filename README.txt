= dm-ldap-adapter

A DataMapper adapter for Lightweight Directory Access Protocol (LDAP) servers.

== Usage

DM LDAP Adapter enables the creation of application objects that map
against an existing LDAP server. For example, a "user" can map against
the posixAccount schema in an LDAP server providing uidNumber,
gidNumber, uid, homeDirectory and userPassword. These are intended to
map to unix accounts so that authentication on unix systems can be
centrally managed by the LDAP server.

Currently, mapping LDAP schemas to application objects must be done
manually by the developer, but the intent is to create a set of
objects corresponding to the set of most commonly used LDAP schemas so
application developers can leverage them with less effort.

DataMapper.setup(:default, {
                   :adapter => 'ldap',
                   :host => 'localhost',
                   :port => '389',
                   :base => "ou=people,dc=example,dc=com",
                   :username => "cn=admin,dc=example,dc=com",
                   :password => "exPa5$w0rd"
                 })


class User
  include DataMapper::Resource

  @@base = "ou=people,dc=example,dc=com"

  @@objectclass = [ "top", "person", "organizationalPerson", "inetOrgPerson",
                     "extensibleObject", "shadowAccount", "posixAccount" ]

  property :username,      String,   :field => "uid", :key => true
  property :uuid,          String,   :field => "uniqueidentifier"
  property :name,          String,   :field => "cn"
  property :first_name,    String,   :field => "givenname"
  property :last_name,     String,   :field => "sn"
  property :mail,          String,   :field => "mail"
  property :groupid,       Integer,  :field => "gidnumber"
  property :userid,        Integer,  :field => "uidnumber"
  property :homedirectory, String,   :field => "homedirectory"

  def objectclass
    @@objectclass
  end

  def make_dn
    "uid=#{netid},#{@@base}"
  end
end

This is exactly like normal datamapper models, with a couple of extras
to make LDAP function.

@@base is a class variable that defines where in the LDAP hierarchy
this class of objects reside, it represents a path from the root. This
is important because each piece of ldap data is uniquely identified by
a distinguisedName which is the key attribute + @@base. For example,
the distinguishedName "uid=testuser,ou=people,dc=example,dc=com"
uniquely identifies the test user in the LDAP server.

@@objectclass is the list of LDAP schemas that are required to define
this particular LDAP object. Each schema contributes some set of
attributes that, when taken together, define all the objects at that
location in the LDAP tree. This list is required when new resources
are created in LDAP, but ideally should be hidden from the application
developer.

== Code

# Create
user = User.new(:username => "dmtest", :uuid => UUID.random_create().to_s,
                :name => "DataMapper Test", :homedirectory => "/home/dmtest",
                :first_name => "DataMapperTest", :last_name => "User",
                :userid => 3, :groupid => 500)

user.save

# Retrieve
user = User.first(:username => 'dmtest')
puts user

# Modify
user.update_attributes(:name => 'DM Test')
user.save
puts user

# Delete
result = user.destroy
puts "Result: #{result}"

== TODO:

- Figure out a good testing strategy, get standard adapter tests in place

- Finish query implementation (limit, order, etc)

- Consider making pre-mapped resources corresponding to the most
  commonly used LDAP object types so applications can use them without
  duplication of effort for each application.

- Documentation clean up


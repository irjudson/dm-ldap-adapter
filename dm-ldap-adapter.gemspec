Gem::Specification.new do |s|
  s.name = %q{dm-ldap-adapter}
  s.version = "0.0.9"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Ivan R. Judson"]
  s.date = %q{2009-03-25}
  s.description = %q{A DataMapper Adapter for LDAP, as simply as possible.}
  s.email = ["ivan.judson [a] montana [d] edu"]
  s.extra_rdoc_files = ["README.txt", "LICENSE", "TODO", "History.txt"]
  s.files = ["History.txt", "LICENSE", "Manifest.txt", "README.txt", "Rakefile", "TODO", "lib/ldap_adapter.rb", "lib/ldap_adapter/version.rb", "spec/integration/ldap_adapter_spec.rb", "spec/spec.opts", "spec/spec_helper.rb", "tasks/install.rb", "tasks/spec.rb"]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/irjudson/dm-ldap-adapter}
  s.rdoc_options = ["--main", "README.txt"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{dm-ldap-adapter}
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{A DataMapper Adapter for LDAP}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<dm-core~>, [">= 0.9.10"])
      s.add_development_dependency(%q<hoe>, [">= 1.11.0"])
    else
      s.add_dependency(%q<dm-core~>, [">= 0.9.10"])
      s.add_dependency(%q<hoe>, [">= 1.11.0"])
    end
  else
    s.add_dependency(%q<dm-core~>, [">= 0.9.10"])
    s.add_dependency(%q<hoe>, [">= 1.11.0"])
  end
end

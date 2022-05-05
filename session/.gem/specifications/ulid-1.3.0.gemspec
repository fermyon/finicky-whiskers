# -*- encoding: utf-8 -*-
# stub: ulid 1.3.0 ruby lib

Gem::Specification.new do |s|
  s.name = "ulid".freeze
  s.version = "1.3.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Rafael Sales".freeze]
  s.date = "2021-03-01"
  s.email = ["rafaelcds@gmail.com".freeze]
  s.homepage = "https://github.com/rafaelsales/ulid".freeze
  s.licenses = ["MIT".freeze]
  s.post_install_message = "\nulid gem needs to install sysrandom gem if you use Ruby 2.4 or older.\nExecute `gem install sysrandom` or add `gem \"sysrandom\"` to Gemfile.\n".freeze
  s.rubygems_version = "3.3.11".freeze
  s.summary = "Universally Unique Lexicographically Sortable Identifier implementation for Ruby".freeze

  s.installed_by_version = "3.3.11" if s.respond_to? :installed_by_version
end

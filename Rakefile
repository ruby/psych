# -*- ruby -*-

require 'rubygems'
require 'hoe'

gem 'rake-compiler', '>= 0.4.1'
require "rake/extensiontask"

Hoe.plugin :debugging, :doofus, :git
Hoe::RUBY_FLAGS << " -I. "

Hoe.spec 'psych' do
  developer 'Aaron Patterson', 'aaronp@rubyforge.org'
  developer 'John Barnette',   'jbarnette@rubyforge.org'

  self.extra_rdoc_files  = Dir['*.rdoc']
  self.history_file      = 'CHANGELOG.rdoc'
  self.readme_file       = 'README.rdoc'
  self.testlib           = :minitest

  extra_dev_deps << ['rake-compiler', '>= 0.4.1']

  self.spec_extras = { :extensions => ["ext/psych/extconf.rb"] }

  Rake::ExtensionTask.new "psych", spec do |ext|
    ext.lib_dir = File.join(*['lib', 'psych', ENV['FAT_DIR']].compact)
  end
end

Hoe.add_include_dirs('.')

task :test => :compile

# vim: syntax=ruby

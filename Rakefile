# -*- ruby -*-

require 'rubygems'
require 'hoe'

gem 'rake-compiler', '>= 0.4.1'
require "rake/extensiontask"

Hoe.plugin :debugging, :doofus, :git

Hoe.spec 'psych' do
  developer 'Aaron Patterson', 'aaronp@rubyforge.org'
  developer 'John Barnette',   'jbarnette@rubyforge.org'

  self.extra_rdoc_files  = Dir['*.rdoc']
  self.history_file      = 'CHANGELOG.rdoc'
  self.readme_file       = 'README.rdoc'

  extra_dev_deps << ['rake-compiler', '>= 0.4.1']

  Rake::ExtensionTask.new "psych", spec do |ext|
    ext.lib_dir = File.join(*['lib', 'psych', ENV['FAT_DIR']].compact)
  end
end

task :test => :compile

# vim: syntax=ruby

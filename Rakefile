# -*- ruby -*-

require 'rubygems'
require 'hoe'

# Make sure hoe-debugging is installed
Hoe.plugin :debugging

HOE = Hoe.spec 'psych' do
  developer('Aaron Patterson', 'aaronp@rubyforge.org')
  self.readme_file   = 'README.rdoc'
  self.history_file  = 'CHANGELOG.rdoc'
  self.extra_rdoc_files  = FileList['*.rdoc']

  %w{ rake-compiler }.each do |dep|
    self.extra_dev_deps << [dep, '>= 0']
  end
end

gem 'rake-compiler', '>= 0.4.1'
require "rake/extensiontask"

RET = Rake::ExtensionTask.new("psych", HOE.spec) do |ext|
  ext.lib_dir = File.join(*['lib', 'psych', ENV['FAT_DIR']].compact)
end

Rake::Task[:test].prerequisites << :compile

# vim: syntax=ruby

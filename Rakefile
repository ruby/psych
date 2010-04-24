# -*- ruby -*-

require 'rubygems'
require 'hoe'

class Hoe
  remove_const :RUBY_FLAGS
  RUBY_FLAGS = "-I#{%w(lib ext bin test).join(File::PATH_SEPARATOR)}"
end

gem 'rake-compiler', '>= 0.4.1'
require "rake/extensiontask"

Hoe.plugin :debugging, :doofus, :git

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

Hoe.add_include_dirs('.:lib/psych')

task :test => :compile

desc "merge psych in to ruby trunk"
namespace :merge do
  basedir = File.expand_path File.dirname __FILE__
  rubydir = File.join ENV['HOME'], 'git', 'ruby'
  mergedirs = {
    # From                          # To
    [basedir, 'ext', 'psych/']  => [rubydir, 'ext', 'psych/'],
    [basedir, 'lib/']           => [rubydir, 'ext', 'psych', 'lib/'],
    [basedir, 'test', 'psych/'] => [rubydir, 'test', 'psych/'],
  }

  rsync = 'rsync -av --exclude extconf.rb --exclude lib --exclude ".*" --delete'

  task :to_ruby do
    mergedirs.each do |from, to|
      sh "#{rsync} #{File.join(*from)} #{File.join(*to)}"
    end
  end

  task :from_ruby do
    mergedirs.each do |from, to|
      sh "#{rsync} #{File.join(*to)} #{File.join(*from)}"
    end
  end
end

# vim: syntax=ruby

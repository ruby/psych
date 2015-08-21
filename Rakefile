# -*- ruby -*-

require 'psych'
require 'rubygems'
require 'hoe'

def java?
  RUBY_PLATFORM =~ /java/
end

class Hoe
  remove_const :RUBY_FLAGS
  flags = "-I#{%w(lib ext bin test).join(File::PATH_SEPARATOR)}"
  flags = "--1.9 " + flags if java?
  RUBY_FLAGS = flags
end

gem 'rake-compiler', '>= 0.4.1'
gem 'minitest', '~> 5.0'
require "rake/extensiontask"

Hoe.plugin :doofus, :git, :gemspec

$hoe = Hoe.spec 'psych' do
  license   'MIT'
  developer 'Aaron Patterson', 'aaron@tenderlovemaking.com'

  self.extra_rdoc_files  = Dir['*.rdoc']
  self.history_file      = 'CHANGELOG.rdoc'
  self.readme_file       = 'README.rdoc'
  self.testlib           = :minitest

  extra_dev_deps << ['rake-compiler', '>= 0.4.1']
  extra_dev_deps << ['minitest', '~> 5.0']

  self.spec_extras = {
    :required_ruby_version => '>= 1.9.2'
  }

  if java?
    require './lib/psych/versions.rb'
    extra_deps << ['jar-dependencies', '>= 0.1.7']

    # the jar declaration for jar-dependencies
    self.spec_extras[ 'requirements' ] = "jar org.yaml:snakeyaml, #{Psych::DEFAULT_SNAKEYAML_VERSION}"
    self.spec_extras[ 'platform' ] = 'java'
    # TODO: clean this section up.
    require "rake/javaextensiontask"
    Rake::JavaExtensionTask.new("psych", spec) do |ext|
      require 'maven/ruby/maven'
      # uses Mavenfile to write classpath into pkg/classpath
      # and tell maven via system properties the snakeyaml version
      # this is basically the same as running from the commandline:
      # rmvn dependency:build-classpath -Dsnakeyaml.version='use version from Psych::DEFAULT_SNAKEYAML_VERSION here'
      Maven::Ruby::Maven.new.exec( 'dependency:build-classpath', "-Dsnakeyaml.version=#{Psych::DEFAULT_SNAKEYAML_VERSION}", '-Dverbose=true')#, '--quiet' )
      ext.source_version = '1.7'
      ext.target_version = '1.7'
      ext.classpath = File.read('pkg/classpath')
      ext.ext_dir = 'ext/java'
    end
  else
    self.spec_extras[:extensions] = ["ext/psych/extconf.rb"]
    Rake::ExtensionTask.new "psych", spec do |ext|
      ext.lib_dir = File.join(*['lib', ENV['FAT_DIR']].compact)
    end
  end
end

def gem_build_path
  File.join 'pkg', $hoe.spec.full_name
end

def add_file_to_gem relative_path
  target_path = File.join gem_build_path, relative_path
  target_dir = File.dirname(target_path)
  mkdir_p target_dir unless File.directory?(target_dir)
  rm_f target_path
  safe_ln relative_path, target_path
  $hoe.spec.files.concat [relative_path]
end

if java?
  task gem_build_path => [:compile] do
    add_file_to_gem 'lib/psych.jar'
  end
end

Hoe.add_include_dirs('.:lib/psych')

task :test => :compile

task :hack_spec do
  $hoe.spec.extra_rdoc_files.clear
end
task 'core:spec' => [:hack_spec, 'gem:spec']

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

  rsync = 'rsync -av --exclude lib --exclude ".*" --exclude "*.o" --exclude Makefile --exclude mkmf.log --delete'

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

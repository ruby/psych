require "bundler"
Bundler::GemHelper.install_tasks

require "rake/testtask"
Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList['test/**/test_*.rb']
  t.verbose = true
  t.warning = true
end

if RUBY_PLATFORM =~ /java/
  require 'rake/javaextensiontask'
  Rake::JavaExtensionTask.new("psych") do |ext|
    require 'maven/ruby/maven'
    # uses Mavenfile to write classpath into pkg/classpath
    # and tell maven via system properties the snakeyaml version
    # this is basically the same as running from the commandline:
    # rmvn dependency:build-classpath -Dsnakeyaml.version='use version from Psych::DEFAULT_SNAKEYAML_VERSION here'
    default_snakeyaml_version = File.read File.expand_path('lib/psych/versions.rb', File.dirname(__FILE__))
    default_snakeyaml_version = default_snakeyaml_version[/DEFAULT_SNAKEYAML_VERSION\s?=\s?'(.*?)'.*/, 1]
    raise "DEFAULT_SNAKEYAML_VERSION = '...' not matched" unless default_snakeyaml_version
    Maven::Ruby::Maven.new.exec('dependency:build-classpath', "-Dsnakeyaml.version=#{default_snakeyaml_version}", '-Dverbose=true')
    ext.source_version = '1.7'
    ext.target_version = '1.7'
    ext.classpath = File.read('pkg/classpath')
    ext.ext_dir = 'ext/java'
  end
else
  require 'rake/extensiontask'
  spec = eval File.read("psych.gemspec")
  Rake::ExtensionTask.new("psych", spec) do |ext|
    ext.lib_dir = File.join(*['lib', ENV['FAT_DIR']].compact)
    ext.cross_compile = true
    ext.cross_platform = %w[x86-mingw32 x64-mingw32]
    ext.cross_compiling do |s|
      s.files.concat ["lib/2.2/psych.so", "lib/2.3/psych.so", "lib/2.4/psych.so"]
    end
  end
end

desc "Compile binaries for mingw platform using rake-compiler-dock"
task 'build:mingw' do
  require 'rake_compiler_dock'
  RakeCompilerDock.sh "bundle && rake cross native gem RUBY_CC_VERSION=2.2.2:2.3.0:2.4.0"
end

task :default => [:compile, :test]

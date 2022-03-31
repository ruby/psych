# -*- coding: us-ascii -*-
# frozen_string_literal: true
require 'mkmf'

if $mswin or $mingw or $cygwin
  $CPPFLAGS << " -DYAML_DECLARE_STATIC"
end

yaml_source = with_config("libyaml-source-dir") || enable_config("bundled-libyaml", false)
unless yaml_source # default to pre-installed libyaml
  pkg_config('yaml-0.1')
  dir_config('libyaml')
  unless find_header('yaml.h') && find_library('yaml', 'yaml_get_version')
    yaml_source = true # fallback to the bundled source if exists
  end
end

if yaml_source == true
  # search the latest libyaml source under $srcdir
  yaml_source = Dir.glob("#{$srcdir}/yaml{,-*}/").max_by {|n| File.basename(n).scan(/\d+/).map(&:to_i)}
  unless yaml_source
    require_relative '../../tool/extlibs.rb'
    cache_dir = File.expand_path("../../tmp/download_cache", $srcdir)
    extlibs = ExtLibs.new(cache_dir: cache_dir)
    unless extlibs.process_under($srcdir)
      raise "failed to download libyaml source"
    end
    yaml_source, = Dir.glob("#{$srcdir}/yaml-*/")
    raise "libyaml not found" unless yaml_source

    config_dir = File.join(File.expand_path(yaml_source), "config")
    config_tools = ["config.guess", "config.sub"]
    puts("Downloading latest #{config_tools.join(" ")}")
    config_tools.each do |tool|
      # remove bundled old config tools
      rm_f File.join(config_dir, tool)
      Downloader::GNU.download(tool, config_dir, false, cache_dir: cache_dir)
    end
  end
elsif yaml_source
  yaml_source = yaml_source.gsub(/\$\((\w+)\)|\$\{(\w+)\}/) {ENV[$1||$2]}
end
if yaml_source
  yaml_configure = "#{File.expand_path(yaml_source)}/configure"
  unless File.exist?(yaml_configure)
    raise "Configure script not found in #{yaml_source.quote}"
  end

  puts("Configuring libyaml source in #{yaml_source.quote}")
  yaml = "libyaml"
  Dir.mkdir(yaml) unless File.directory?(yaml)
  unless system(yaml_configure, "-q",
                "--enable-#{$enable_shared || !$static ? 'shared' : 'static'}",
                "--host=#{RbConfig::CONFIG['host'].sub(/-unknown-/, '-')}",
                *(["CFLAGS=-w"] if RbConfig::CONFIG["GCC"] == "yes"),
                chdir: yaml)
    raise "failed to configure libyaml"
  end
  Logging.message("libyaml configured\n")
  inc = yaml_source.start_with?("#$srcdir/") ? "$(srcdir)#{yaml_source[$srcdir.size..-1]}" : yaml_source
  $INCFLAGS << " -I#{yaml}/include -I#{inc}/include"
  Logging.message("INCLFAG=#$INCLFAG\n")
  libyaml = "#{yaml}/src/.libs/libyaml.#$LIBEXT"
  $LOCAL_LIBS.prepend("$(LIBYAML) ")
end

create_makefile 'psych' do |mk|
  mk << "LIBYAML = #{libyaml}".strip << "\n"
end

# :startdoc:

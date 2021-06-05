# -*- coding: us-ascii -*-
# frozen_string_literal: true
require 'mkmf'
require 'fileutils'

# :stopdoc:

dir_config 'libyaml'

$VPATH << "$(srcdir)/yaml"
$INCFLAGS << " -I$(srcdir)/yaml"

$srcs = Dir.glob("#{$srcdir}/{,yaml/}*.c").map {|n| File.basename(n)}.sort

header = 'yaml/yaml.h'
header = "{$(VPATH)}#{header}" if $nmake
if have_macro("_WIN32")
  $CPPFLAGS << " -DYAML_DECLARE_STATIC -DHAVE_CONFIG_H"
end

have_header 'dlfcn.h'
have_header 'inttypes.h'
have_header 'memory.h'
have_header 'stdint.h'
have_header 'stdlib.h'
have_header 'strings.h'
have_header 'string.h'
have_header 'sys/stat.h'
have_header 'sys/types.h'
have_header 'unistd.h'
have_header 'unicode/ucol.h'

find_header 'yaml.h'
have_header 'config.h'

##
# ICU dependency
#

ldflags = cppflags = nil

if RbConfig::CONFIG["host_os"] =~ /darwin/
  begin
    brew_prefix = `brew --prefix icu4c`.chomp
    ldflags   = "#{brew_prefix}/lib"
    cppflags  = "#{brew_prefix}/include"
    pkg_conf  = "#{brew_prefix}/lib/pkgconfig"
    # pkg_config should be less error prone than parsing compiler
    # commandline options, but we need to set default ldflags and cpp flags
    # in case the user doesn't have pkg-config installed
    ENV['PKG_CONFIG_PATH'] ||= pkg_conf
  rescue
  end
end

dir_config 'icu', cppflags, ldflags

pkg_config("icu-i18n")
pkg_config("icu-io")
pkg_config("icu-uc")

$CXXFLAGS << ' -std=c++11' unless $CXXFLAGS.include?("-std=")

unless have_library 'icui18n' and have_header 'unicode/ucnv.h'
  STDERR.puts "\n\n"
  STDERR.puts "***************************************************************************************"
  STDERR.puts "*********** icu required (brew install icu4c or apt-get install libicu-dev) ***********"
  STDERR.puts "***************************************************************************************"
  exit(1)
end

have_library 'z' or abort 'libz missing'
have_library 'icuuc' or abort 'libicuuc missing'
have_library 'icudata' or abort 'libicudata missing'

$CFLAGS << ' -Wall -funroll-loops'
$CFLAGS << ' -Wextra -O0 -ggdb3' if ENV['DEBUG']

create_makefile 'psych' do |mk|
  mk << "YAML_H = #{header}".strip << "\n"
end

# :startdoc:

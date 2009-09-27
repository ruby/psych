require 'mkmf'

$CFLAGS << " -O3 -Wall -Wcast-qual -Wwrite-strings -Wconversion -Wmissing-noreturn -Winline"

LIBDIR = Config::CONFIG['libdir']
INCLUDEDIR = Config::CONFIG['includedir']

LIB_DIRS = [
  '/opt/local/lib',
  '/usr/local/lib',
  LIBDIR,
  '/usr/lib',
]

libyaml = dir_config('libyaml', '/opt/local/include', '/opt/local/lib')

unless find_header('yaml.h')
  abort "yaml.y is missing.  try 'port install libyaml +universal' or 'yum install libyaml-devel'"
end

unless find_library('yaml', 'yaml_get_version')
  abort "libyaml is missing.  try 'port install libyaml +universal' or 'yum install libyaml-devel'"
end

create_makefile('psych/psych')

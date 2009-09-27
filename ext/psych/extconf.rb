require 'mkmf'

$CFLAGS << " -O3 -Wall -Wcast-qual -Wwrite-strings -Wconversion -Wmissing-noreturn -Winline"

libyaml = dir_config('libyaml', '/opt/local/include', '/opt/local/lib')

find_header('yaml.h')

create_makefile('psych/psych')

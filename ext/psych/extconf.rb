require 'mkmf'

# :stopdoc:

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
have_header 'config.h'

create_makefile 'psych'

# :startdoc:

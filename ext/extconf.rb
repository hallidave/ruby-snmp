require 'mkmf'

have_library 'smi', 'smiInit' 
have_header 'smi.h'

create_makefile 'smi'

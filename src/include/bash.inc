.define PATH_CURRENT_MAX_LEVEL        4       ; Only in telemon 3.0 number of level, if we add more, we should have to many RAM, if you need to set more level add bytes here : ptr_path_current_low and ptr_path_current_high
.define MAX_LENGTH_OF_FILES           9       ;  We say 8 chars for directory and end of string
.define ORIX_MAX_PATH_LENGTH  MAX_LENGTH_OF_FILES*PATH_CURRENT_MAX_LEVEL+PATH_CURRENT_MAX_LEVEL
MAX_LENGTH_OF_A_COMMAND       = 9
MAX_ARGS                      = 3       ;  Number of possible args in the command line

MAX_LENGTH_BUFEDT     =  ORIX_MAX_PATH_LENGTH+9
ORIX_MAX_MAX_LENGTH_BUFEDT     =  ORIX_MAX_PATH_LENGTH+9

.struct shell_bash_struct
path_current    .res ORIX_MAX_PATH_LENGTH
.endstruct

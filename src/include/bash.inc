BASH_MAX_ARGS                      = 3       ;  Number of possible args in the command line


BASH_MAX_BUFEDT_LENGTH         = 37

; Environnement variables

.define BASH_MAX_LENGTH_OF_ENVIRONNEMENT_VARIABLES 0
.define BASH_MAX_NUMBER_OF_ENVIRONNEMENT_VARIABLES 1

.struct shell_bash_struct
path_current              .res ORIX_MAX_PATH_LENGTH
;environnement_variables   .res BASH_MAX_LENGTH_OF_ENVIRONNEMENT_VARIABLES*BASH_MAX_NUMBER_OF_ENVIRONNEMENT_VARIABLES
.endstruct

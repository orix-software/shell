BASH_MAX_ARGS                      = 3       ;  Number of possible args in the command line


BASH_MAX_BUFEDT_LENGTH         = 110

; Environnement variables

.define BASH_MAX_LENGTH_OF_ENVIRONNEMENT_VARIABLES 0
.define BASH_MAX_NUMBER_OF_ENVIRONNEMENT_VARIABLES 1

.define BASH_MAX_LENGTH_COMMAND_LINE 37

.define BASH_NUMBER_OF_COMMANDS_BUILTIN  4

.struct shell_bash_struct
    command_line              .res BASH_MAX_LENGTH_COMMAND_LINE
    pos_command_line          .res 1
.endstruct

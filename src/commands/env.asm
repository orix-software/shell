.export _env

.proc _env
    PRINT str_PATH
    BRK_ORIX XCRLF
    PRINT str_PWD
    PRINT shell_bash_variables+shell_bash_struct::path_current
    BRK_ORIX XCRLF
    rts
str_PWD:
    .asciiz "PWD="
str_PATH:
    .asciiz "PATH=/bin"
str_USER:
    .asciiz "USER="
str_HOME:
    .asciiz "HOME="
str_OLDPWD:
    .asciiz "OLDPWD="
str_SHELL:
    .asciiz "SHELL="
str_HOSTTYPE:
    .asciiz "HOSTTYPE="
.endproc 

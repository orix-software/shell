.proc _env
    PRINT str_PATH
    BRK_ORIX XCRLF
    PRINT str_PWD
    PRINT ORIX_PATH_CURRENT
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

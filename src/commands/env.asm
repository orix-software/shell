.export _env

.proc _env
    print str_PATH,NOSAVE
    BRK_KERNEL XCRLF
    print str_PWD,NOSAVE
    BRK_KERNEL XGETCWD ; XGETCWD
    BRK_KERNEL XWSTR0
    BRK_KERNEL XCRLF
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

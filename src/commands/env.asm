.export _env

.proc _env
    print str_PATH
    crlf
    print str_PWD
    BRK_KERNEL XGETCWD ; XGETCWD
    BRK_KERNEL XWSTR0
    crlf
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

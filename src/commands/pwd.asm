.export _pwd

.proc _pwd
    BRK_KERNEL XGETCWD
    BRK_KERNEL XWSTR0
    crlf
    rts
.endproc

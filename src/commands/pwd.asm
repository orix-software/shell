.export _pwd

.proc _pwd
    BRK_KERNEL XGETCWD
    BRK_KERNEL XWSTR0
    BRK_KERNEL XCRLF
    rts
.endproc

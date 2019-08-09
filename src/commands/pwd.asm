.export _pwd

.proc _pwd
    PRINT shell_bash_variables+shell_bash_struct::path_current
    BRK_ORIX XCRLF
    rts
.endproc


.export _echo

.proc _echo
    ldx #$01
    jsr _orix_get_opt
    STRCPY ORIX_ARGV,BUFNOM
    PRINT ORIX_ARGV
    BRK_KERNEL XCRLF
    rts
.endproc



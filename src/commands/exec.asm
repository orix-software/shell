
.export _exec

.proc _exec
    exec_argv_ptr       := userzp ; 16 bits
    exec_argc           := userzp+2 ; 8 bits



    lda     #$00 ; return args with cut
    BRK_KERNEL XMAINARGS

    sta     exec_argv_ptr
    sty     exec_argv_ptr+1
    stx     exec_argc
    cpx     #$01
    beq     @usage

    ldx     #$01
    lda     exec_argv_ptr
    ldy     exec_argv_ptr+1

    BRK_KERNEL XGETARGV

    ; A et Y at this step contains the ptr
@L1:
    ldx #$01
    BRK_KERNEL XEXEC

@usage:
    rts

.endproc

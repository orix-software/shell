.export _touch

.proc _touch
    touch_mainargs_argv     := userzp
    touch_mainargs_argc     := userzp+2 ; 1 byte
    touch_fp                := userzp+3 ; 2 bytes
    touch_mainargs_arg1_ptr := userzp+5 ; 2 bytes

    lda     #$00 ; return args with cut
    BRK_KERNEL XMAINARGS
    sta     touch_mainargs_argv
    sty     touch_mainargs_argv+1
    stx     touch_mainargs_argc

    cpx     #$01
    beq     @missing_operand

    ldx     #$01
    lda     touch_mainargs_argv
    ldy     touch_mainargs_argv+1

    BRK_KERNEL XGETARGV
    sta     touch_mainargs_arg1_ptr
    sty     touch_mainargs_arg1_ptr+1

    fopen (touch_mainargs_arg1_ptr), O_CREAT,,touch_fp

    fclose(touch_fp)

    rts

@missing_operand:
    print   touch
    print   str_missing_operand
    rts

.endproc

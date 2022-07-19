.export _touch

.proc _touch
    touch_ptr1              := userzp
    touch_mainargs_argv     := userzp+4
    touch_mainargs_argc     := userzp+8 ; 8 bits
    touch_mainargs_arg1_ptr := userzp+15

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

    fopen (touch_mainargs_arg1_ptr), O_CREAT

    BRK_KERNEL XCLOSE

    rts
@missing_operand:
    print   touch
    print   str_missing_operand
    rts

.endproc
str_arg_not_managed_yet:
    .asciiz "path with folders in arg not managed yet"

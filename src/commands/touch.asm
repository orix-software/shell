.export _touch

.proc _touch
    touch_mainargs_argv     := userzp
    touch_mainargs_argc     := userzp+2 ; 1 byte
    touch_fp                := userzp+3 ; 2 bytes
    touch_mainargs_arg1_ptr := userzp+5 ; 2 bytes

    initmainargs touch_mainargs_argv, touch_mainargs_argc, 0

    cpx     #$01
    beq     @missing_operand

    getmainarg #1, (touch_mainargs_argv)
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

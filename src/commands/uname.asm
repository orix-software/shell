.proc _uname
    uname_mainargs_ptr := userzp

    uname_mainargs_argv := userzp+3
    uname_mainargs_argc := userzp+2


    BRK_KERNEL XMAINARGS
    sta     uname_mainargs_ptr
    sty     uname_mainargs_ptr+1
    stx     uname_mainargs_argc

    ldx     #$01
    lda     uname_mainargs_ptr
    ldy     uname_mainargs_ptr+1

    BRK_KERNEL XGETARGV
    sta     uname_mainargs_argv
    sty     uname_mainargs_argv+1

    lda     uname_mainargs_argc
    cmp     #$01
    beq     no_param

    ldy     #$00
    lda     (uname_mainargs_argv),y
    cmp     #'-'
    bne     error

    iny
    lda     (uname_mainargs_argv),y
    cmp     #'a'
    bne     error
    print   str_os
    lda     #' '                ; FIXME CGETC
    BRK_KERNEL XWR0
    print   str_compile_time
    BRK_KERNEL XCRLF
    rts
no_param:
    print   str_os
    BRK_KERNEL XCRLF
error:
    rts

.endproc

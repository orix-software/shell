.proc _uname
    uname_mainargs_ptr := userzp

    uname_mainargs_argv := userzp+3
    uname_mainargs_argc := userzp+2


    initmainargs uname_mainargs_ptr, uname_mainargs_argc, 0

    getmainarg #1, (uname_mainargs_ptr)

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
    print   #' '
    print   str_compile_time
    crlf
    rts

no_param:
    print   str_os
    crlf

error:
    rts

.endproc

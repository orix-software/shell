.export _watch

.proc _watch
    save_mainargs_ptr       := userzp
    watch_ptr1              := userzp+2
    watch_ptr2              := userzp+4
    watch_mainargs_argv     := userzp+6
    watch_mainargs_argc     := userzp+8
    watch_mainargs_arg1_ptr := userzp+10 ; 2 bytes
    watch_save_bank         := userzp+12

    initmainargs watch_mainargs_argv, watch_mainargs_argc, 0

    malloc 100
    sta     save_mainargs_ptr
    sty     save_mainargs_ptr+1

    cpx     #$01

    beq     @usage

    getmainarg #1, (watch_mainargs_argv)
    sta     watch_mainargs_arg1_ptr
    sty     watch_mainargs_arg1_ptr+1

    lda     watch_mainargs_arg1_ptr
    sta     watch_ptr1
    lda     watch_mainargs_arg1_ptr+1
    sta     watch_ptr1+1
    ; copy command
    ldy     #$00
@L5:
    lda     (watch_ptr1),y
    beq     @S3
    sta     (save_mainargs_ptr),y
    iny
    bne     @L5
@S3:
    sta     (save_mainargs_ptr),y

    mfree   (watch_mainargs_argv)

    print (save_mainargs_ptr)


    SWITCH_OFF_CURSOR
@L1:
    asl     KBDCTC
    bcc     @no_ctrl

    SWITCH_ON_CURSOR
    rts

@no_ctrl:
    jsr     _clrscr

    lda     save_mainargs_ptr
    ldy     save_mainargs_ptr+1
    jsr     _bash


    cmp     #EOK
    beq     @isok

    jsr     external_cmd

    rts


@isok:
    jsr     @wait
    jmp     @L1

@notfound:
    print   save_mainargs_ptr
    print str_not_found
    rts

@usage:
    rts

@wait:
    ldy     #$00
    ldx     #$00
@lwait:
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    inx
    bne     @lwait
    iny
    bne     @lwait
    rts
str_argc:
    .asciiz "Argc: "
str_param:
    .asciiz "Param: "
.endproc

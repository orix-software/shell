.export _cat

.proc _cat
    cat_save_argvlow  := userzp+1
    cat_save_argvhigh := userzp+2
    cat_save_argc     := userzp+3
    cat_save_ptr_arg  := userzp+4 ; 16 bits

    XMAINARGS = $2C
    XGETARGV =  $2E

    lda     #$00 ; return args with cut
    BRK_KERNEL XMAINARGS

    sta     cat_save_argvlow
    sty     cat_save_argvhigh
    stx     cat_save_argc

    cpx     #$01
    beq     @print_usage


    ldx     #$01 ; get arg
    lda     cat_save_argvlow
    ldy     cat_save_argvhigh
    BRK_KERNEL XGETARGV


    sta     cat_save_ptr_arg
    sty     cat_save_ptr_arg+1

    fopen (cat_save_ptr_arg), O_RDONLY
    cpx     #$FF
    bne     @readfile
    cmp     #$FF
    bne     @readfile

    print   (cat_save_ptr_arg)

    print   str_not_found
    rts

@print_usage:
@cat_error_param:
    print     txt_usage
    rts

@readfile:

    lda     #$FF
    tay
    jsr     _ch376_set_bytes_read
    ; Renvoie CH376_USB_INT_SUCCESS ($14) si le fichier est vide, CH376_USB_INT_DISK_READ ($1D) si ok

  @loop:
    cmp     #CH376_USB_INT_DISK_READ
    bne     @finished

    lda     #CH376_RD_USB_DATA0
    sta     CH376_COMMAND
    lda     CH376_DATA
    sta     userzp
    ; Tester si userzp == 0?

  @read_byte:
    lda     CH376_DATA
    cmp     #$0A
    bne     @autre

    crlf
    bne     @next    ; ACC n'est pas modifié par XCRLF, donc saut inconditionnel

  @autre:
    cmp     #$0D
    beq     @next

    BRK_TELEMON XWR0

  @next:
    dec     userzp
    bne     @read_byte

    lda     #CH376_BYTE_RD_GO
    sta     CH376_COMMAND
    jsr     _ch376_wait_response

    ; _ch376_wait_response renvoie 1 en cas d'erreur et le CH376 ne renvoie pas de valeur 0
    ; donc le bne devient un saut inconditionnel!
    bne     @loop

    ; Tester si ACC==1 pour détecter une éventuelle erreur?

  @finished:
    crlf
    rts

txt_usage:
    .byte "usage: cat FILE",$0D,$0A,0

.endproc

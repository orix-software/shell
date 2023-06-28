.proc _sh

    ptr_file_sh_interactive_ptr_save  := userzp+2
    ptr_file_sh_interactive_size_file := userzp+4  ; 16 bits
    ptr_file_sh_interactive_ptr       := userzp+6
    sh_interactive_line_number        := userzp+8
    sh_interactive_save_ptr           := userzp+10    ; one byte
    fp_ptr_file_sh_interactive        := userzp+12

    sh_mainargs_argv                  := userzp+14
    sh_mainargs_argc                  := userzp+16
    sh_mainargs_arg1_ptr              := userzp+18
    sh_saveY                          := userzp+20

    lda     #$00 ; return args with cut
    BRK_KERNEL XMAINARGS
    sta     sh_mainargs_argv
    sty     sh_mainargs_argv+1
    stx     sh_mainargs_argc

    cpx     #$01

    beq     @start_normal


    ldx     #$01
    lda     sh_mainargs_argv
    ldy     sh_mainargs_argv+1

    BRK_KERNEL XGETARGV
    sta     sh_mainargs_arg1_ptr
    sty     sh_mainargs_arg1_ptr+1

    ldy     #$00
    lda     (sh_mainargs_arg1_ptr),y
    bne     thereis_a_script_to_execute

@start_normal:
    mfree(sh_mainargs_argv)
    jmp     start_sh_interactive


thereis_a_script_to_execute:

    fopen (sh_mainargs_arg1_ptr),O_RDONLY



    ; A register contains FP id
    sta     fp_ptr_file_sh_interactive
    sty     fp_ptr_file_sh_interactive+1

    lda     #$01
    sta     sh_interactive_line_number

    lda     #CH376_GET_FILE_SIZE
    sta     CH376_COMMAND
    lda     #$68
    sta     CH376_DATA ; ????
    ; store file length
    ldx     CH376_DATA
    stx     ptr_file_sh_interactive_size_file


    ldy     CH376_DATA
    sty     ptr_file_sh_interactive_size_file+1

    ; and drop others (max 64KB of file)
    lda     CH376_DATA
    lda     CH376_DATA

    txa     ; get low byte of the size

    BRK_KERNEL XMALLOC
    sta      ptr_file_sh_interactive_ptr
    sta      ptr_file_sh_interactive_ptr_save

    sty      ptr_file_sh_interactive_ptr+1
    sty      ptr_file_sh_interactive_ptr_save+1

  ; define target address
    lda     ptr_file_sh_interactive_ptr
    sta     PTR_READ_DEST

    lda     ptr_file_sh_interactive_ptr+1
    sta     PTR_READ_DEST+1

  ; We read the file with the correct
    lda     ptr_file_sh_interactive_size_file
    ldy     ptr_file_sh_interactive_size_file+1
  ; reads byte
    BRK_KERNEL XFREAD
    fclose (fp_ptr_file_sh_interactive)



@restart:

@L1:
    ldy    #$00
@L4:
    lda    (ptr_file_sh_interactive_ptr),y
    pha
    BRK_KERNEL XWR0
    pla
    cmp     #$0D
    beq     @compute
    inc     ptr_file_sh_interactive_ptr
    bne     @do_not_inc
    inc    ptr_file_sh_interactive_ptr+1
@do_not_inc:
    ;iny
    bne    @L4
@compute:
    lda    #$00
    sta    (ptr_file_sh_interactive_ptr),y
    inc    ptr_file_sh_interactive_ptr
    bne    @do_not_inc2
    inc    ptr_file_sh_interactive_ptr+1
@do_not_inc2:

@found_end_command:

@do_not_inc3:


@call_xexec:

    lda    ptr_file_sh_interactive_ptr_save
    ldy    ptr_file_sh_interactive_ptr_save+1

    BRK_KERNEL XWSTR0

@nextline2:

    lda     ptr_file_sh_interactive_ptr_save

    ldy     ptr_file_sh_interactive_ptr_save+1
    BRK_KERNEL XEXEC

    cmp    #EOK
    beq    @nextline
    print str_error
    lda    sh_interactive_line_number
    ldy    #$00
    ldx    #$10 ;
    stx    DEFAFF
    ldx    #$00
    BRK_KERNEL XDECIM
    crlf
    lda     ptr_file_sh_interactive_ptr_save

    ldy     ptr_file_sh_interactive_ptr_save+1
    BRK_KERNEL XWSTR0
    crlf
    rts
@nextline:
    lda     ptr_file_sh_interactive_ptr
    sta     ptr_file_sh_interactive_ptr_save
    lda     ptr_file_sh_interactive_ptr+1
    sta     ptr_file_sh_interactive_ptr_save+1


    inc     sh_interactive_line_number


@not_finished:
    jmp    @restart

@update_length:
    lda    ptr_file_sh_interactive_size_file
    bne    @notHigh
    dec    ptr_file_sh_interactive_size_file+1
@notHigh:
    dec    ptr_file_sh_interactive_size_file
    rts

@check_EOF:
; Now verify
    lda    ptr_file_sh_interactive_size_file
    bne    @notFinished
    lda    ptr_file_sh_interactive_size_file+1
    bne    @notFinished
    ; Reached the end
    lda    #$01
    rts

@notFinished:
    lda    #$01

@S20:
    rts
str_error:
  .asciiz "Syntax error line : "
.endproc

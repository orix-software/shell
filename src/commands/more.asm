.export _more

    more_ptr1:= userzp ;

    more_mainargs_argv     := userzp+2
    more_mainargs_argc     := userzp  + 4 ; 8 bits
    more_mainargs_arg1_ptr := userzp + 5 ; 16 bits
    more_fp                := userzp + 7;
    more_buffer            := userzp + 9;
    more_length            := userzp + 11
    more_nb_lines          := userzp + 13

.proc _more
    lda     #$00 ; return args with cut
    BRK_KERNEL XMAINARGS
    sta     more_mainargs_argv
    sty     more_mainargs_argv+1
    stx     more_mainargs_argc

    cpx     #$01
    beq     usage      ; if there is no args, let's displays all banks

    ldx     #$01
    lda     more_mainargs_argv
    ldy     more_mainargs_argv+1

    BRK_KERNEL XGETARGV
    sta     more_mainargs_arg1_ptr
    sty     more_mainargs_arg1_ptr+1

    malloc 1040,more_buffer

    fopen (more_mainargs_arg1_ptr), O_RDONLY,,more_fp

read_again:
    fread (more_buffer), 1040, 1, more_fp
    sta     more_length
    stx     more_length+1

    cpx     #$00
    bne     not_empty

    cmp     #$00
    bne     not_empty

    fclose(more_fp)
    rts


not_empty:
    lda     #$00
    sta     more_nb_lines
read_screen:
    ldy     #$00
    lda     (more_buffer),y
    cmp     #13
    bne     display

    inc     more_nb_lines
    lda     more_nb_lines
    cmp     #25

    beq     read_keyboard
    lda     #13
display:
    BRK_KERNEL XWR0

    inc     more_buffer
    bne     do_not_inc
    inc     more_buffer+1
do_not_inc:

    lda     more_length
    bne     dec_one

    lda     more_length+1
    beq     read_keyboard
    dec     more_length+1

dec_one:
    dec     more_length
    jmp     read_screen
read_keyboard:
    print end_of_screen_str

    cgetc
    jmp     read_screen
usage:
    rts
end_of_screen_str:
  .byte $0A,$0D,"--Plus--",0
.endproc

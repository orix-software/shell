.export _rm

.proc _rm
    rm_mainargs_argv      := userzp
    rm_mainargs_argc      := userzp+2
    rm_mainargs_arg1_ptr  := userzp+4

    initmainargs rm_mainargs_argv, rm_mainargs_argc, 0

    cpx     #$01
    beq     missing_operand

    getmainarg #1, (rm_mainargs_argv)
    sta     rm_mainargs_arg1_ptr
    sty     rm_mainargs_arg1_ptr+1

    ldy     #$00
  ; prevent the rm / case
    lda     (rm_mainargs_arg1_ptr),y
    cmp     #'/'
    bne     skip_rm_slash_case ;
    iny
    lda     (rm_mainargs_arg1_ptr),y
    beq     no_such_file

skip_rm_slash_case:
    lda     rm_mainargs_arg1_ptr
    ldx     rm_mainargs_arg1_ptr+1
    BRK_KERNEL XRM ; FIXME macro
    cmp     #ENOENT
    beq     no_such_file
    rts
no_such_file:
    print rm

    print str_cannot_remove
    lda     #$27
    BRK_KERNEL XWR0      ; FIXME CPUTC


    print (rm_mainargs_arg1_ptr), SAVE
    lda     #$27
    BRK_KERNEL XWR0      ; FIXME CPUTC

    print str_not_found
    rts

missing_operand:

    print rm
    print str_missing_operand

    rts
str_cannot_remove:
    .asciiz ": cannot remove "

.endproc

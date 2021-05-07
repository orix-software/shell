.export _mkdir


mkdir_length_to_malloc := userzp
mkdir_temp             := userzp+3
mkdir_malloc_ptr       := userzp+1 ; .word
; LIMIT : can't malloc more than 255 for the path
   mkdir_mainargs_ptr := userzp+9
   mkdir_argc         := userzp+12

   mkdir_arg          := userzp+14

.proc _mkdir

    BRK_KERNEL XMAINARGS

    sta     mkdir_mainargs_ptr
    sty     mkdir_mainargs_ptr+1
    stx     mkdir_argc
    cpx     #$01
    beq     @missing_operand

    ldx     #$01 ; get arg 2 ; Get the third param
    lda     mkdir_mainargs_ptr
    ldy     mkdir_mainargs_ptr+1

    BRK_KERNEL XGETARGV
    sta     mkdir_arg
    sty     mkdir_arg+1

    ldy     #$00
@L20:
    lda     (mkdir_arg),y
    beq     @out20
    cmp     #'/'
    beq     @slash_found
    iny
    bne     @L20
@out20:
    lda     mkdir_arg
    ldy     mkdir_arg+1
    BRK_KERNEL XMKDIR
    BRK_KERNEL XCLOSE ; ???
    rts
@slash_found:
    print str_arg_not_managed_yet,NOSAVE
    rts
@missing_operand:
    print str_mkdir
    print str_missing_operand
    rts
.endproc


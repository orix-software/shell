.export _pstree

.proc _pstree
    pstree_ptr         := userzp
    pstree_max_process := userzp+2 ; 1 byte
    pstree_savey       := userzp+3
    pstree_ptr2        := userzp+4 ; 2 bytes

    ldx     #$08
    BRK_KERNEL XVARS
    sta     pstree_max_process

    ldx     #$0C ; Busy table id
    BRK_KERNEL XVALUES
    sta     pstree_ptr
    sty     pstree_ptr+1

    print  str_init

    ldy     #$00
@loop:
    lda     (pstree_ptr),y
    beq     @next

    sty     pstree_savey

    print #'-'

    ldy     pstree_savey
    ldx     #$0D
    BRK_KERNEL XVALUES

    sta     pstree_ptr2
    sty     pstree_ptr2+1

    print (pstree_ptr2)
    ;
    ldy     pstree_savey
@next:

    iny
    cpy     pstree_max_process
    bne     @loop
    crlf
    rts
str_init:
    .asciiz "init"
.endproc

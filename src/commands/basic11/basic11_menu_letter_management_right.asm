.proc basic11_menu_letter_management_right
    lda     basic11_first_letter_gui
    sec
    sbc     #'1'
    tax
    lda     $bb80+27*40+2,x
    and     #%01111111
    sta     $bb80+27*40+2,x
    inx
    lda     $bb80+27*40+2,x
    ora     #$80
    sta     $bb80+27*40+2,x
@no_move:

    rts
.endproc

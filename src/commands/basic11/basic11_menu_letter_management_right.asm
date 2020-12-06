.proc basic11_menu_letter_management_right
    ;jmp     basic11_menu_letter_management_right
    lda     basic11_first_letter_gui
    cmp     #'9'
    bne     @skip
    lda     #'@'
    sta     basic11_first_letter_gui
@skip:
    inc     basic11_first_letter_gui
    lda     basic11_first_letter_gui
    sta     $bb80+20

    ldy     basic11_gui_struct::current_index_letter
    lda     (basic11_ptr4),y
    tax
   
    
    lda     $bb80+27*40+3,x
    and     #%01111111
    sta     $bb80+27*40+3,x
    inx     
    lda     $bb80+27*40+3,x
    ora     #$80
    sta     $bb80+27*40+3,x
   
    txa
    sta     (basic11_ptr4),y
@no_move:

    rts
.endproc

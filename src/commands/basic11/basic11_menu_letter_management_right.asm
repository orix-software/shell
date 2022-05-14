.proc basic11_menu_letter_management_right

    lda     basic11_first_letter_gui
    cmp     #'9'
    bne     @skip
    lda     #'@'
    sta     basic11_first_letter_gui
@skip:
    inc     basic11_first_letter_gui

.ifdef basic11_debug
    lda     basic11_first_letter_gui
    ora     #$80
    sta     $bb80+16
.endif

    ldy     #basic11_gui_struct::current_index_letter
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

    ; reset now       #basic11_gui_struct::current_entry_id ; ???
@loopme:    
    ldy     #basic11_gui_struct::current_entry_id ; ???
    lda     #$00
    sta     (basic11_ptr4),y

@no_move:
    ; Displays key

    


    

    rts
.endproc

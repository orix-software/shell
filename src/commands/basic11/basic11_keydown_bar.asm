
.proc basic11_keydown_bar
    ldy     #basic11_gui_struct::max_current_entries
    lda     (basic11_ptr4),y
    pha
    pla

    ; add index now
    ldy     #basic11_gui_struct::current_entry_id
    lda     (basic11_ptr4),y
    sec
    adc     #$00
    sta     (basic11_ptr4),y


    lda     (basic11_ptr4),y
    sec
    adc     #$00
    sta     (basic11_ptr4),y

    jsr     compute_position_bar
    pha
    jsr     erase_bar
    pla
    tax
    inx
    txa
    ldy     #basic11_gui_struct::basic11_posy_screen
    sta     (basic11_ptr4),y
    jsr     compute_position_bar

    jsr     displays_bar    

    rts
.endproc
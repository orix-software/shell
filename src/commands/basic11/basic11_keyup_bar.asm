.proc basic11_keyup_bar
    ldy    #basic11_gui_struct::basic11_posy_screen
    lda    (basic11_ptr4),y
    beq    @out
    jsr    compute_position_bar
    pha
    jsr     erase_bar
    pla
    tax
    dex
    txa
    ldy     #basic11_gui_struct::basic11_posy_screen
    sta     (basic11_ptr4),y
    jsr     compute_position_bar

    jsr     displays_bar    
@out:
    rts
.endproc


.proc basic11_displays_frame
    ; displays line
    ldy     #$00
@display_line:    
    lda     basic_str_fullline_title,y
    
    beq     @outline
    
    sta     $bb80,y

    lda     basic_str_fullline,y
    sta     $bb80+26*40,y

    iny
    bne     @display_line
@outline:
    jsr     basic11_clear_menu
    lda     #'!'
    sta     $bb80+27*40+2

    ldx     #'1'
    ldy     #$00
@L1_menu:    
    txa
    sta     $bb80+27*40+3,y
    iny
    inx
    cpx     #':'
    bne     @L1_menu

    ldx     #'A'
    ldy     #$00
@L2_menu:    
    txa
    sta     $bb80+27*40+10+2,y
    iny
    inx
    cpx     #'Z'+1
    bne     @L2_menu    
    rts
.endproc
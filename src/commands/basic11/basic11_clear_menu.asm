
.proc basic11_clear_menu
    ; displays line
    ldy     #$00
@display_line:    

    lda     basic_str_emptyline,y    
    beq     @outline
    sta     $bb80+40,y
    sta     $bb80+80,y
    sta     $bb80+120,y
    sta     $bb80+160,y
    sta     $bb80+200,y
    sta     $bb80+240,y
    sta     $bb80+280,y
    sta     $bb80+320,y
    sta     $bb80+360,y
    sta     $bb80+400,y
    sta     $bb80+440,y
    sta     $bb80+480,y
    sta     $bb80+520,y
    sta     $bb80+560,y
    sta     $bb80+600,y
    sta     $bb80+640,y
    sta     $bb80+680,y
    sta     $bb80+720,y
    sta     $bb80+760,y
    sta     $bb80+800,y
    sta     $bb80+840,y
    sta     $bb80+880,y
    sta     $bb80+920,y
    sta     $bb80+960,y
    sta     $bb80+1000,y

    iny
    bne     @display_line
@outline:
    rts
.endproc    
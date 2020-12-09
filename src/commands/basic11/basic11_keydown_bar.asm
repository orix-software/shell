
.proc basic11_keydown_bar
    ldy     #basic11_gui_struct::max_current_entries
    lda     (basic11_ptr4),y
    beq     @out
    sta     basic11_saveY
    dec     basic11_saveY 
    ldy     #basic11_gui_struct::basic11_posy_screen
    lda     (basic11_ptr4),y
    cmp     basic11_saveY
    bne     @skip
    rts
@skip:
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



    ldy     #basic11_gui_struct::software_key_to_launch_low
    lda     (basic11_ptr4),y   
    sta     basic11_ptr3
    
    ldy     #basic11_gui_struct::software_key_to_launch_high
    lda     (basic11_ptr4),y
    sta     basic11_ptr3+1

    ldy     #$00
@L1000:    
    lda     (basic11_ptr3),y
    beq     @out2
    iny
    bne     @L1000
@out2:    
    iny
    tya
    clc
    adc     basic11_ptr3
    bcc     @S1
    inc     basic11_ptr3+1
@S1:
    sta     basic11_ptr3

    ldy     #basic11_gui_struct::software_key_to_launch_low
    lda     basic11_ptr3
    sta     (basic11_ptr4),y   
    
    
    ldy     #basic11_gui_struct::software_key_to_launch_high
    lda     basic11_ptr3+1
    sta     (basic11_ptr4),y

@out:
    ; Compute software

    
    

    rts
.endproc
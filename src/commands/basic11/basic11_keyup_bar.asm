.proc basic11_keyup_bar

    
    ldy    #basic11_gui_struct::current_entry_id
    lda    (basic11_ptr4),y
    beq    @out3
    
    
    ldy    #basic11_gui_struct::basic11_posy_screen ; is it 0 ?
    lda    (basic11_ptr4),y
    beq    @continue

    cmp    #24
    bne    @manage_position
    jmp    @manage_position


    
@continue:   
    ; erase bar
    lda     #$10
    sta     $bb80+40+1

    ldx     #$01
    ldy     #25
    BRK_KERNEL XSCROB
    lda     #'|'
    sta     $bb80+40
    sta     $bb80+40+39
    ; and displays again bar
    lda     #$11
    sta     $bb80+40+1
    lda     #$10
    sta     $bb80+40+38

    ldy     #basic11_gui_struct::current_entry_id
    lda     (basic11_ptr4),y
    sec
    sbc     #$01
    sta     (basic11_ptr4),y

    jsr     basic11_compute_software_to_display
@L2000:

    lda     (basic11_ptr3),y
    beq     @out500
    sta     $bb80+40+2,x
    inx
    cpx     #35         ; Cut title (35 chars)
    beq     @out500
    iny

    bne     @L2000
@out500:    

@out3:
    rts

@manage_position:
    jsr    compute_position_bar
    pha
    jsr     erase_bar
    pla
    tax
    dex
    txa

    ldy    #basic11_gui_struct::basic11_posy_screen ; is it 0 ?
    lda    (basic11_ptr4),y
    

    sec
    sbc    #$01
    sta    (basic11_ptr4),y


    ldy     #basic11_gui_struct::basic11_posy_screen
    
    jsr     compute_position_bar

    jsr     displays_bar    
    ; Compute key

    ldy     #basic11_gui_struct::current_entry_id 
    lda     (basic11_ptr4),y
    sec
    sbc     #$01
    sta     (basic11_ptr4),y

    jsr     basic11_compute_software_to_display

@out:
    rts
.endproc


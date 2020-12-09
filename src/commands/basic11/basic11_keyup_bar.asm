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


    ; Compute key
    
    
    ldy     #basic11_gui_struct::software_key_to_launch_high
    lda     (basic11_ptr4),y
    sta     basic11_ptr3+1

    ldy     #basic11_gui_struct::software_key_to_launch_low
    lda     (basic11_ptr4),y   
    sta     basic11_ptr3


    ; dec : ptr is now on previous '0'
    lda     basic11_ptr3
    bne     @dec1
    dec     basic11_ptr3+1
@dec1:
    dec     basic11_ptr3

; dec : ptr is now brefore previous '0'
    lda     basic11_ptr3
    bne     @dec2
    dec     basic11_ptr3+1
@dec2:
    dec     basic11_ptr3



    ldy     #$00
@L1000:    
    lda     (basic11_ptr3),y
    beq     @out2
    
    lda     basic11_ptr3
    bne     @dec3
    dec     basic11_ptr3+1
@dec3:
    dec     basic11_ptr3
    jmp     @L1000
 @out2:  

    inc     basic11_ptr3
    bcc     @inc1
    inc     basic11_ptr3+1
@inc1:
    


    ldy     #basic11_gui_struct::software_key_to_launch_low
    lda     basic11_ptr3
    sta     (basic11_ptr4),y   
    
    
    ldy     #basic11_gui_struct::software_key_to_launch_high
    lda     basic11_ptr3+1
    sta     (basic11_ptr4),y


@out:
    rts
.endproc

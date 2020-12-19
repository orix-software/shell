
.proc basic11_keydown_bar
    ; Do  we have 0 entries ?


    ldy     #basic11_gui_struct::max_current_entries
    lda     (basic11_ptr4),y
    beq     @myout ; yes : do not compute

    sta     basic11_current_parse_software

    ldy     #basic11_gui_struct::basic11_posy_screen
    lda     (basic11_ptr4),y
    cmp     basic11_current_parse_software ; Max entry ?
    beq     @myout
    cmp     #24
    bcs     @scroll
    jmp     @skip


@myout:    
    rts
@scroll:

    ldy     #basic11_gui_struct::max_current_entries
    lda     (basic11_ptr4),y
    sta     basic11_saveY

    ldy     #basic11_gui_struct::current_entry_id
    lda     (basic11_ptr4),y
    cmp     basic11_saveY
    beq     @myout

    ; erase_red_bar
    ; Scroll
    lda     #$10
    sta     $bb80+1001

    ldx     #$01
    ldy     #25
    BRK_KERNEL XSCROH
    lda     #'|'
    sta     $bb80+1000
    sta     $bb80+1000+39
    ; and displays again bar
    lda     #$11
    sta     $bb80+1001
    lda     #$10
    sta     $bb80+1000+38
    ; Now displays software

;@loopme:
    ;jmp     @loopme

    ldy     #basic11_gui_struct::current_entry_id
    lda     (basic11_ptr4),y
    clc
    adc     #$01
    sta     (basic11_ptr4),y

    jsr     basic11_compute_software_to_display


@L2000:

    lda     (basic11_ptr3),y
    beq     @out500
    sta     $bb80+40*25+2,x
    inx
    cpx     #35         ; Cut title (35 chars)
    beq     @out500
    iny

    bne     @L2000
@out500:    

  ;key_software_index_low              .res BASIC11_MAX_NUMBER_OF_SOFTWARE_PER_PAGE
  ;key_software_index_high             .res BASIC11_MAX_NUMBER_OF_SOFTWARE_PER_PAGE

    rts
@skip:
    ;jmp     @skip
    ; add index now
    ldy     #basic11_gui_struct::current_entry_id
    lda     (basic11_ptr4),y
    clc
    adc     #$01
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

.proc basic11_compute_software_to_display


    ldy     #basic11_gui_struct::current_entry_id 
 
    lda     (basic11_ptr4),y
    sta     basic11_current_parse_software

    ;tax
    ldy     #basic11_gui_struct::key_software_index_low
    tya
    clc
    adc     basic11_current_parse_software
    tay
    lda     (basic11_ptr4),y
    sta     basic11_ptr3

    ldy     #basic11_gui_struct::key_software_index_high
    tya
    clc
    adc     basic11_current_parse_software
    tay
    lda     (basic11_ptr4),y
    sta     basic11_ptr3+1
    

    ldy     #basic11_gui_struct::software_key_to_launch_low
    lda     basic11_ptr3
    sta     (basic11_ptr4),y   
    
    
    ldy     #basic11_gui_struct::software_key_to_launch_high
    lda     basic11_ptr3+1
    sta     (basic11_ptr4),y
    
    ldy     #$FF
@L1:
    iny    
    lda     (basic11_ptr3),y
    cmp     #';'
    bne     @L1
    iny
    ldx     #$00
    rts
.endproc

.proc   basic11_launch

    ldy     #basic11_gui_struct::current_entry_id
    lda     (basic11_ptr4),y
    sta     basic11_saveA
    clc
    adc     #basic11_gui_struct::key_software_index_low
    
    tay
    lda     (basic11_ptr4),y
    sta     basic11_ptr3
    
    ; Probably not useful
    lda     basic11_saveA
    clc
    adc     #basic11_gui_struct::key_software_index_high
    sta     basic11_ptr3+1
    tay
    lda     (basic11_ptr4),y
    sta     basic11_ptr3+1

    tay
    lda     basic11_ptr3 ; ??? FIXME

    
    lda     basic11_ptr4
    sta     basic11_ptr1
    lda     basic11_ptr4+1
    sta     basic11_ptr1+1

    ldy     #basic11_gui_struct::command_launch
    clc
    adc     basic11_ptr1
    bcc     @S500
    inc     basic11_ptr1+1
@S500:    
    sta     basic11_ptr1

    ldx     #$00
    ldy     #$00
@L500:    
    lda     str_basic11,x
    beq     @out500
    sta     (basic11_ptr1),y
    inx
    iny
    jmp     @L500
@out500:


    ldy     #basic11_gui_struct::software_key_to_launch_low
    lda     (basic11_ptr4),y   
    sta     basic11_ptr3
    
    ldy     #basic11_gui_struct::software_key_to_launch_high
    lda     (basic11_ptr4),y
    sta     basic11_ptr3+1


    ldy     #$00
@L600:    
    lda     (basic11_ptr3),y
    cmp     #';'
    beq     @end_of_command
    sta     basic11_saveA
    iny
    sty     basic11_saveY
    txa
    tay
    lda     basic11_saveA
    sta     (basic11_ptr1),y
    iny
    tya
    tax
    ldy     basic11_saveY
    jmp     @L600
    ; X

@end_of_command:
    txa
    tay
    lda     #$00
    sta     (basic11_ptr1),y

 
    mfree(basic11_ptr4)
    mfree(basic11_ptr2)
    ;jsr     _lsmem
;@me12:    
    ;jmp     @me12   

    ldy     basic11_ptr1+1
    lda     basic11_ptr1
    BRK_KERNEL XEXEC

    rts
str_basic11:     
    .byte "basic11 "
    .byte $22,$00 ; "
.endproc

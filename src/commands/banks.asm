
.export _banks

.proc _banks
    current_bank := ID_BANK_TO_READ_FOR_READ_BYTE    ; 1 bytes
    
    
    ptr1         := OFFSET_TO_READ_BYTE_INTO_BANK   ; 2 bytes : Used when we type "bank ID"
    tmp2         := userzp                          ; 1 bytes
    bank_save_banking_register := userzp+1	 ; one byte
    save_twilighte_register    := userzp+2 ; 1 bytes
    save_twilighte_banking_register    := userzp+3 ; 1 bytes
    bank_decimal_current_bank := userzp+4 ; One byte
    ptr2         := userzp+5                        ; 2 bytes : Used when we type "bank ID"
    ptr3         := userzp+7    ; 2 bytes
    bank_stop_listing :=userzp+9
    bank_save_argc :=userzp+10
    bank_save_argvlow :=userzp+11
    bank_save_argvhigh:=userzp+12

    XMAINARGS = $2C
    XGETARGV =  $2E

    BRK_KERNEL XMAINARGS

    
    sta     bank_save_argvlow
    sty     bank_save_argvhigh
    stx     bank_save_argc

    cpx     #$01
    beq     displays_all_banks


    ldx     #$01
    lda     bank_save_argvlow
    ldy     bank_save_argvhigh

    BRK_KERNEL XGETARGV

    sta     ptr3
    sty     ptr3+1

    ldy     #$00
    lda     (ptr3),y
    pha
    ; Do we have another char 
    iny
    lda     (ptr3),y ; FIXME
    pla

    sec
    sbc     #$30
    tax
    stx     VAPLIC
    sta     current_bank
    sei
    lda     #<$FFFC
    sta     ptr1
    lda     #>$FFFC
    sta     ptr1+1
    ldy     #$00
    ldx     #$00 ; Read mode
    jsr     READ_BYTE_FROM_OVERLAY_RAM ; get low
    sta     tmp2


    lda     #<$FFFD
    sta     ptr1
    lda     #>$FFFD
    sta     ptr1+1
    ldy     #$00
    ldx     #$00 ; Read mode

    jsr     READ_BYTE_FROM_OVERLAY_RAM ; get low
      
    tay 
    cli
    ; NMI
    lda     tmp2

    sta     VAPLIC+1
    sty     VAPLIC+2
    sta     VEXBNK+1 ; BNK_ADDRESS_TO_JUMP_LOW
    sty     VEXBNK+2 ; BNK_ADDRESS_TO_JUMP_HIGH
    ldx     VAPLIC
    stx     BNKCIB

    ldx     #XVARS_KERNEL_CH376_MOUNT
    BRK_KERNEL XVARS
    sta     ptr2
    sty     ptr2+1
    ldy     #$00
    lda     (ptr2),y
    sta     STORE_CURRENT_DEVICE

    jmp     EXBNK
	
; displays all bank	
displays_all_banks:   
    lda     #$00
    sta     bank_stop_listing
	
    lda     #64
    sta     bank_decimal_current_bank

    lda     $343
    sta     save_twilighte_banking_register
    
    ; switch to ram
    lda     $342
    sta     save_twilighte_register
    ora     #%00100000
    sta     $342

    jsr     displays_banking

    lda     $342
    and     #%11011111
    sta     $342

    jsr     displays_banking


    sei
    lda     save_twilighte_register
    sta     $342

    lda     save_twilighte_banking_register
    sta     $343
    cli

    rts

displays_banking:


    lda     #$07
    sta     $343

parse_next_banking_set:
    lda     bank_decimal_current_bank
    cmp     #$07
    ;bne     @skip
    
    ;lda     #$07
    ;bne     @store

@skip:
    lda     #%00000100                ; we start from the bank 7 to 1
@store:
    sta     current_bank
loop2:
    jsr     display_bank_id

    sei
    lda     #<$FFF8
    sta     ptr1
    lda     #>$FFF8
    sta     ptr1+1
    ldy     #$00
    ldx     #$00 ; Read mode
    jsr     READ_BYTE_FROM_OVERLAY_RAM ; get low
    sta     RES
    iny
    ldx     #$00 ; Read mode 
    jsr     READ_BYTE_FROM_OVERLAY_RAM ; get high
    sta     RES+1
   
    lda     RES
    sta     ptr1
    lda     RES+1
    sta     ptr1+1

.IFPC02
.pc02
    stz     ptr2	
.p02    
.else
    lda     #$00
    sta     ptr2
.endif

@loopme:
    ldy     ptr2
    ldx     #$00 ; Read mode
    jsr     READ_BYTE_FROM_OVERLAY_RAM
    beq     @exit
    cli
    cmp     #' '                        ; 'a'
    bcc     @none_char
    cmp     #$7F                      ; '7f'
    bcs     @none_char
@skip:  
    BRK_ORIX XWR0
@none_char:

@wait_key:    
    BRK_KERNEL XRD0
    bcs     @check_ctrl
    cmp     #' '
    bne     @check_ctrl
    ;@prout:
        ;jmp  @prout
    lda     bank_stop_listing
    beq     @S10
    dec     bank_stop_listing
    jmp     @check_ctrl
@S10:
    inc     bank_stop_listing
    jmp     @wait_key
    ; space here 
    
@check_ctrl:
    lda     bank_stop_listing
    bne     @wait_key
    asl     KBDCTC
    bcc     @no_ctrl    
    rts
@no_ctrl:    
    iny
    cpy     #36    ; Exit if signature is longer than 37 bytes
    beq     @exit
    sty     ptr2

    sei
    jmp     @loopme
@exit:

    cli
    RETURN_LINE
    dec     bank_decimal_current_bank
    dec     current_bank
    bne     loop2

    dec     $343
    bpl     parse_next_banking_set


    rts

display_bank_id:
    lda     bank_decimal_current_bank              ; Load current bank
    cmp     #10
    bcs     greater_than_10
    pha
    lda     #'0'
    BRK_ORIX XWR0
    pla
    clc 
    adc     #44+4                     ; displays the number of the bank

    BRK_ORIX XWR0
    CPUTC ':'                         ; Displays a space
    rts
greater_than_10:
    cmp     #20
    bcs     greater_than_20
    pha
    lda      #'1'
    BRK_ORIX XWR0
    pla
    clc
    adc     #38
    BRK_ORIX XWR0
    CPUTC ':'      
    rts    
greater_than_20:  
    cmp     #30
    bcs     greater_than_30
    pha
    lda      #'2'
    BRK_ORIX XWR0
    pla
    clc
    adc     #28
    BRK_ORIX XWR0
    CPUTC ':'      
    rts    
greater_than_30:
    cmp     #40
    bcs     greater_than_40
    pha
    lda     #'3'
    BRK_ORIX XWR0
    pla
    clc
    adc     #18
    BRK_ORIX XWR0
    CPUTC ':'      
    rts
greater_than_40:
    cmp     #50
    bcs     greater_than_50
    pha
    lda     #'4'
    BRK_ORIX XWR0
    pla
    clc
    adc     #8
    BRK_ORIX XWR0
    CPUTC ':'      
    rts    
greater_than_50:
    cmp     #60
    bcs     greater_than_60
    pha
    lda     #'5'
    BRK_ORIX XWR0
    pla
    sec
    sbc     #2

    BRK_ORIX XWR0
    CPUTC ':'      
    rts    
greater_than_60:
    ;cmp     #60
    ;bcs     greater_than_60
    pha
    lda     #'6'
    BRK_ORIX XWR0
    pla
    sec
    sbc     #12
    BRK_ORIX XWR0
    CPUTC ':'      
    rts    

.endproc 


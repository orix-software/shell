
.export _banks

.proc _banks
    current_bank := ID_BANK_TO_READ_FOR_READ_BYTE    ; 1 bytes
    
    
    ptr1         := OFFSET_TO_READ_BYTE_INTO_BANK   ; 2 bytes
    ptr2         := userzp+10    ; 2 bytes
    tmp2         := userzp+2    ; 1 bytes
    bank_save_banking_register := userzp+3	
    bank_address_driver := userzp+5
    bank_decimal_current_bank := userzp+7

    ldx     #$01
    jsr     _orix_get_opt           ; get arg 
    
    bcc     displays_all_banks      ; if there is no args, let's displays all banks
    lda     ORIX_ARGV
    sec
    sbc     #$30
    tax
    stx     VAPLIC
    ; NMI
    lda     #<$c000
    ldy     #>$c000
    sta     VAPLIC+1
    sty     VAPLIC+2
    sta     VEXBNK+1 ; BNK_ADDRESS_TO_JUMP_LOW
    sty     VEXBNK+2 ; BNK_ADDRESS_TO_JUMP_HIGH
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
	; install driver
    lda     #$FF
    ldy     #$00
    BRK_KERNEL XMALLOC

    sta     bank_address_driver
    sty     bank_address_driver+1
    
	sta     VEXBNK+1 
	sty     VEXBNK+2

    ldx     #$00
    ldy     #$00
@L1:
    lda     bank_address_driver_code,x
    sta     (bank_address_driver),y
    iny
    inx
    bne     @L1

    lda     #32
    sta     bank_decimal_current_bank

restart:
	;jsr		VEXBNK
    ;rts
    ; Telestrat and Twilighte board V0_3
    lda     #%00000111                ; we start from the bank 7 to 1

    sta     current_bank
loop2:
    lda     current_bank              ; Load current bank
    clc 
    adc     #44+4                     ; displays the number of the bank
    BRK_ORIX XWR0
    CPUTC ':'                         ; Displays a space
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
    beq     exit
    cli
    cmp     #' '                        ; 'a'
    bcs     @skip
    lda     #' '
@skip:    
    BRK_ORIX XWR0
    iny
    cpy     #37    ; Exit if signature is longer than 37 bytes
    beq     exit
    sty     ptr2
    sei
    jmp     @loopme
exit:

    cli
    RETURN_LINE
    dec     current_bank
    bne     loop2

    rts

bank_address_driver_code:

  sei
;.ifdef    TWILIGHTEBOARD_BANK_LINEAR
  lda     #$00
  sta     $343
;.endif



    lda     #%00000111                ; we start from the bank 7 to 1

    sta     current_bank
@loop2:
    lda     bank_decimal_current_bank
    ldy     #$00
    ldx     #$20 ;
    stx     DEFAFF
    ldx     #$00
    BRK_KERNEL XDECIM
    



    CPUTC ':'                         ; Displays a space
    sei
  lda     VIA2::PRA
  and     #%11111000                     
  ora     current_bank                           ; but select a bank in $410
  sta     VIA2::PRA    
  lda     #<$FFF8
  sta     ptr1
  lda     #>$FFF8
  sta     ptr1+1
  ldy     #$00
  lda     (ptr1),y
  sta     RES
  iny
  lda     (ptr1),y
  sta     RES+1
   
  lda     RES
  sta     ptr1
  
  lda     RES+1
  sta     ptr1+1


    lda     #$00
    sta     ptr2


@loopme:
    ldy     ptr2
    ldx     #$00 ; Read mode
    lda     (ptr1),y
    ;jsr     READ_BYTE_FROM_OVERLAY_RAM
    beq     exit
    cli
    cmp     #' '                        ; 'a'
    bcs     @skip
    lda     #' '
@skip:    
    BRK_KERNEL XWR0
    iny
    cpy     #37    ; Exit if signature is longer than 37 bytes
    beq     @exit
    sty     ptr2
    sei
    jmp     @loopme
@exit:
  lda     VIA2::PRA
  and     #%11111111                     
  sta     VIA2::PRA
  ;ora     current_bank                           ; but select a bank in $410
    cli
    RETURN_LINE
    dec     current_bank
    bpl     @out
    dec     bank_decimal_current_bank
    bne     @loop2
@out:
    



;.ifdef    TWILIGHTEBOARD_BANK_LINEAR
  lda     #$00
  sta     $343
;.endif
  cli 
  rts

.endproc 


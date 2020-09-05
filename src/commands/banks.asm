
.export _banks

.proc _banks
    current_bank := ID_BANK_TO_READ_FOR_READ_BYTE    ; 1 bytes
    
    tmp2         := userzp+2    ; 1 bytes
    ptr1         := OFFSET_TO_READ_BYTE_INTO_BANK   ; 2 bytes
    ptr2         := userzp    ; 2 bytes



    ldx     #$01
    jsr     _orix_get_opt           ; get arg 
    
    bcc     displays_all_banks      ; if there is no args, let's displays all banks
    lda     ORIX_ARGV
    sec
    sbc     #$30
    tax
    stx     VAPLIC
    lda     #<$C000
    ldy     #>$C000
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
    sty     ptr2
    sei
    jmp     @loopme
exit:
    cli
    RETURN_LINE
    dec     current_bank
    bne     loop2

    rts

.endproc


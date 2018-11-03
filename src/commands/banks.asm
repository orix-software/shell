BANKS_PTR1=ZP_APP_PTR1 ; 2 bytes

.proc _banks
    ldx     #$01
    jsr     _orix_get_opt           ; get arg 
    bcc     displays_all_banks      ; if there is no args, let's displays all banks
	lda     ORIX_ARGV
	sec
	sbc     #$30
	tax
	stx     VAPLIC
	lda     #<$c000
	ldy     #>$c000
    sta     VAPLIC+1
	sty     VAPLIC+2
	STA     VEXBNK+1 ; BNK_ADDRESS_TO_JUMP_LOW
	STY     VEXBNK+2 ; BNK_ADDRESS_TO_JUMP_HIGH
	STX     BNKCIB
	JMP     SWITCH_TO_BANK_ID
	
; displays all bank	
displays_all_banks:   
    lda     #ORIX_ID_BANK       ; store the current bank
    sta     tmp2
.ifdef      WITH_TWILIGHTE_BOARD_V0_4	
    lda     #%00011111                ; 31
.else
    ; Telestrat and Twilighte board V0_3
    lda     #%00000111                ; we start from the bank 7 to 1
.endif	
    sta     tmp1
loop2:
    PRINT str_bank
    lda     tmp1
    clc 
    adc     #44+4
    BRK_ORIX XWR0
    CPUTC ' '
    sei
    lda     #<$fff8
    sta     ptr1
    lda     #>$fff8
    sta     ptr1+1
    ldy     #$00
    jsr     READ_BYTE_FROM_OVERLAY_RAM ; get low
    sta     RES
    iny 
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
    jsr     READ_BYTE_FROM_OVERLAY_RAM
    beq     exit
    cli
    BRK_ORIX XWR0
    iny
    sty     ptr2
    sei
    jmp     @loopme
exit:
    cli
    RETURN_LINE
    dec     tmp1
    lda     tmp1
    bne     loop2
    rts
str_bank:
    .asciiz "Bank "
.endproc


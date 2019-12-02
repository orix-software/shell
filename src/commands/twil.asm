 

.export _twil

.proc _twil
    ldx     #$01
    jsr     _orix_get_opt           ; get arg 
    bcc     usage      ; if there is no args, let's displays all banks

    lda     ORIX_ARGV
    cmp     #'-'
    bne     usage
    ldx     #$01
    lda     ORIX_ARGV,x
    cmp     #'f'
    bne     check_next_parameter_s
    PRINT   str_version
    lda     TWILIGHTE_REGISTER       ; get Twilighte register
    and     #%00001111 ; Select last 4 bits
    cmp     #15        ; Max version #15 
    bcs     error
    clc
    adc     #48
    BRK_KERNEL XWR0
    RETURN_LINE
    jmp     print_registers 
error:
    PRINT   str_unknown
    RETURN_LINE
    rts
usage:
    PRINT   str_usage
    RETURN_LINE
    rts
; twil -s0 -r     
check_next_parameter_s:
    cmp     #'s'       ; Swap
    bne     check_next_parameter_r
    inx
    lda     ORIX_ARGV,x  ; Get set
    sta     $5000
    cmp     #48+08
    bcs     error_overflowbanking
    sec
    sbc     #48
    ; FIXME bug
    sta     TWILIGHTE_BANKING_REGISTER ; and switch
    jmp     print_registers 
    ;cmp     #'s'       ; Swap    
error_overflowbanking:
    PRINT   str_usage
    RETURN_LINE
    jmp     print_registers 
check_next_parameter_r:
    cmp     #'r'       ; Swap
    bne     check_next_parameter_w
    lda     TWILIGHTE_REGISTER
    AND     #%11011111
    sta     TWILIGHTE_REGISTER
    PRINT   str_swap_to_bank_rom
    RETURN_LINE    
    jmp     print_registers 
check_next_parameter_w:
    cmp     #'w'       ; Swap
    bne     usage
    lda     TWILIGHTE_REGISTER
    ora     #%00100000
    sta     TWILIGHTE_REGISTER
    PRINT   str_swap_to_bank_sram
    RETURN_LINE
print_registers:
    PRINT   str_twilighte_register
    lda     TWILIGHTE_REGISTER
    LDY     #$00
    LDX     #$20 ;
    STX     DEFAFF
    LDX     #$03
    BRK_ORIX XDECIM
    RETURN_LINE
    PRINT   str_twilighte_banking_register
    lda     TWILIGHTE_BANKING_REGISTER
    LDY     #$00
    LDX     #$20 ;
    STX     DEFAFF
    LDX     #$03
    BRK_ORIX XDECIM
    RETURN_LINE

    rts
str_twilighte_register:
    .asciiz "Twilighte register : "
str_twilighte_banking_register:
    .asciiz "Twilighte Banking register : "



str_version: 
  	.asciiz "Version : "    
str_unknown:    
	.asciiz "Unknown version"
str_swap_to_bank_sram:
    .asciiz "Swapped to RAM banking"    
str_swap_to_bank_rom:
    .asciiz "Swapped to EEPROM banking"        
str_overflow_banking:    
	.asciiz "This version of board can only manage 4 sets"    
str_usage:    
	.byte "Usage: twil -f",$0A,$0D
    .byte "       twil -s[idbank]",$0A,$0D
    .byte "       twil -r",$0A,$0D
    .byte "       twil -w",$0A,$0D
    .byte "       twil -u",$0A,$0D   ; update main rom (kernel)
    .byte "       twil -e",$0A,$0D   ; EEPROM informations
    .byte "       twil -l[file64KB]",$0A,$0D,$00
.endproc 


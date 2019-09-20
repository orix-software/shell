 

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
    sec
    adc     #48
    BRK_KERNEL XWR0
    RETURN_LINE
    rts
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
    cmp     #4
    bcc     error_overflowbanking
    clc
    sbc     #48
    ; FIXME bug
    sta     TWILIGHTE_BANKING_REGISTER ; and switch
    rts
    ;cmp     #'s'       ; Swap    
error_overflowbanking:
    PRINT   str_usage
    RETURN_LINE
    rts
check_next_parameter_r:
    cmp     #'r'       ; Swap
    bne     check_next_parameter_w
    lda     TWILIGHTE_REGISTER
    AND     #%11011111
    sta     TWILIGHTE_REGISTER
    rts
check_next_parameter_w:
    cmp     #'w'       ; Swap
    bne     usage
    lda     TWILIGHTE_REGISTER
    ora     #%00100000
    sta     TWILIGHTE_REGISTER
    rts

str_version: 
  	.asciiz "Version : "    
str_unknown:    
	.asciiz "Unknown version"
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



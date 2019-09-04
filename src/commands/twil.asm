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
    bne     usage
    PRINT   str_version
    lda     $343 ; get Twilighte register
    cmp     #$09
    bcc     error
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
str_version: 
  	.asciiz "Version : "    
str_unknown:    
	.asciiz "Unknown version"
str_usage:    
	.asciiz "Usage: twil -f"
.endproc 



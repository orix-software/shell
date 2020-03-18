.proc _debug

;CPU_6502
    ; routine used for some debug
    PRINT   str_cpu
    jsr     _getcpu
    cmp     #CPU_65C02
    bne     @is6502
    PRINT   str_65C02
    RETURN_LINE
.pc02    
    bra     @next        ; At this step we are sure that it's a 65C02, so we use its opcode :)
.p02    
@is6502:
	
    PRINT   str_6502
	RETURN_LINE
@next:
    PRINT   str_ch376
    jsr     _ch376_ic_get_ver
    BRK_KERNEL XWR0
    BRK_KERNEL XCRLF
    ;RETURN_LINE
    
    PRINT   str_ch376_check_exist
    jsr     _ch376_check_exist
    jsr     _print_hexa
	BRK_KERNEL XCRLF
    
    
    lda #$09
    ldy #$02
  
    BRK_KERNEL XMALLOC
    ; A & Y are the ptr here
    BRK_KERNEL XFREE
    
    rts
str_ch376:
    .asciiz "CH376 VERSION : "
str_ch376_check_exist:
    .asciiz "CH376 CHECK EXIST : "
str_cpu:    
    .asciiz "CPU: "
.endproc
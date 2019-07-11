.proc _cat

    ; TODO : use XOPEN
    ldx     #$01
    jsr     _orix_get_opt
    bcc     print_usage
	
    jsr     _ch376_verify_SetUsbPort_Mount
    cmp     #$01
    beq     cat_error_param

    jsr     _cd_to_current_realpath_new

    ldx     #$01
    jsr     _orix_get_opt
    STRCPY  ORIX_ARGV,BUFNOM
	
    jsr     _ch376_set_file_name
    jsr     _ch376_file_open
    cmp     #CH376_ERR_MISS_FILE
    bne     read_byte
  
    PRINT   BUFNOM
    PRINT   str_not_found

    rts
read_byte:
    lda     #$FF
    tay  ; earn 1 byte instead of doing ldy #$ff
    jsr     _ch376_set_bytes_read
continue:
    cmp     #$1D ; something to read FIXME REPLACE for a label
    beq     we_read
    cmp     #$14 ; finished FIXME REPLACE for a label
    beq     finished 

end_cat:
    rts
print_usage:	
cat_error_param:
    PRINT   txt_usage
	rts  
 
we_read:
    lda     #CH376_RD_USB_DATA0
    sta     CH376_COMMAND

    lda     CH376_DATA ; contains length read
	sta	    userzp
loop9:
    lda     CH376_DATA ; read the data
    cmp     #$0A
    bne     @S3

    RETURN_LINE
.ifdef CPU_65C02 ; FIXME
.pc02
    bra     @S4
.p02    
.else
    jmp     @S4
.endif
@S3:
    cmp     #$0D
    bne     @S1
    BRK_TELEMON XCRLF
.ifdef CPU_65C02
.pc02
    bra     @S4
.p02    
.else
    jmp     @S4
.endif
@S1:
    BRK_TELEMON XWR0
@S4:


    dec	    userzp
    bne     loop9
    lda     #CH376_BYTE_RD_GO
    sta     CH376_COMMAND
    jsr     _ch376_wait_response
.ifdef CPU_65C02
.pc02
    bra     continue
.p02    
.else
    jmp     continue
.endif
finished:
    BRK_TELEMON XCRLF
    rts  
txt_usage:
    .byte "usage: cat FILE",$0D,$0A,0
.endproc


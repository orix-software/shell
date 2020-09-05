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
    
    jsr     mount_sdcard
    BRK_KERNEL XCRLF

    jsr     mount_key
    BRK_KERNEL XCRLF

    lda     #$09
    ldy     #$02
  
    BRK_KERNEL XMALLOC
    ; A & Y are the ptr here
    BRK_KERNEL XFREE
    
    rts
mount_sdcard:
    lda     #CH376_SET_USB_MODE ; $15
    sta     CH376_COMMAND
	lda     #CH376_SET_USB_MODE_CODE_SDCARD
    sta     CH376_DATA
    nop
    nop    
    jsr     _ch376_disk_mount
	cmp 	#CH376_USB_INT_SUCCESS
	beq 	ok
    PRINT   str_error_sdcard   	
    rts
ok:    
    PRINT   str_ok_sdcard   
    rts

mount_key:
    lda     #CH376_SET_USB_MODE ; $15
    sta     CH376_COMMAND

    lda     #CH376_SET_USB_MODE_CODE_USB_HOST_SOF_PACKAGE_AUTOMATICALLY
    sta     CH376_DATA
    nop
    nop
    jsr     _ch376_disk_mount
	cmp 	#CH376_USB_INT_SUCCESS
	beq 	ok2
    PRINT   str_error_key	
    rts
ok2:    
    PRINT   str_ok_key
    rts    
    

str_error_sdcard:
    .asciiz "sdcard mount error !  "
str_ok_sdcard:
    .asciiz "sdcard mount OK !  "

str_error_key:
    .asciiz "key mount error !  "
str_ok_key:
    .asciiz "key mount OK !  "

str_ch376:
    .asciiz "CH376 VERSION : "
str_ch376_check_exist:
    .asciiz "CH376 CHECK EXIST : "
str_cpu:    
    .asciiz "CPU: "
.endproc
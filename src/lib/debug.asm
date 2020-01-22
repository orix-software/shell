
.ifdef DEBUG_CH376
str_waiting:
.byt $0d,$0a,"Waiting for CH376  ...",0
str_mounting:
.byt "Mouting usb drive    ...",0
str_resetting:
.byt "Resetting CH376      ...",0
str_detecting:
.byt "Detecting CH376      ...",0
str_configure_usb_port:
.byt "Configuring USB PORT ...",0

str_displaying_catalogue:
.byt "Displaying catalog   ...",$0d,$0a,0
str_setting_filename
.byt "  Setting Filename   ...",0
str_fileopen
.byt "  File opening       ...",0
str_ok_message
.asc $92,"[OK] ",$90,$0d,$0a,0
str_failed_message
.asc $91,"[FAILED] ",$90,$0d,$0a,0
str_not_found_chunk
.byt "  Detecting 32 bytes chunk  ...",$0d,$0a,0


str_error_ch376
	.byte "Error for CH376",$0d,$0a,0
#endif

	
str_function_debug	
.asc "Function used to debug some features",0	


#ifdef DEBUG
print_hex	
	jsr binhex
	stx userzp
	;txa
	BRK_TELEMON(XWR0)
	lda userzp
	;txa
	BRK_TELEMON(XWR0)
	rts                   ;done	
		

binhex
	pha                   ;save byte
    and #%00001111        ;extract LSN
    tax                   ;save it
    pla                   ;recover byte
    lsr                   ;extract...
    lsr                   ;MSN
    lsr
    lsr
    pha                   ;save MSN
    txa                   ;LSN
    jsr lsn          ;generate ASCII LSN
    tax                   ;save
    pla                   ;get MSN & fall thru
;
;
;   convert nybble to hex ASCII equivalent...
;
lsn
	cmp #$0a
    bcc decimal          ;in decimal range
;
    adc #$66              ;hex compensate
;         
decimal	
	eor #%00110000        ;finalize nybble		
	rts
		
#endif
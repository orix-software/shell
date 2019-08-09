
.export _reboot


.proc _reboot
STORE_CODE_TO_REBOOT:=$1000

	sei
	jsr     _ch376_reset_all ; Reset CH376
	; it's a bit crap, but we delete page 2 in order to telemon to do cold restart 
	ldx     #$00
.IFPC02
.pc02
@L1:
	stz     $200,x
	stz     $500,x
.p02	
.else
	lda     #$00
@L1:
	sta     $200,x
	sta     $500,x
.endif	
	dex
	bne		@L1
	
	; flag cold reset
	lda		#128
	sta		FLGRST

copy:
	ldx     #$10
@L2:
	lda     _copy_code,x
	sta     STORE_CODE_TO_REBOOT,x
	dex
	bpl     @L2
	jmp     STORE_CODE_TO_REBOOT
	
_copy_code:
	lda     #$07
	sta     VIA2::PRA 
	jmp     ($fffc)

.endproc


.export _clrscr

.proc _clrscr
	BRK_KERNEL XHIRES ; Hires
	BRK_KERNEL XTEXT  ; and text
	BRK_KERNEL XSCRNE
    rts
.endproc

.proc _clrscr_text
;BRK_KERNEL XSCRNE ; and text
	lda		#' '
	ldx		#$00
@L1:
	sta		$bb80,x
	sta		$bb80+256,x
	sta		$bb80+512,x
	sta		$bb80+512+256,x
	inx
	bne		@L1
    rts
.endproc

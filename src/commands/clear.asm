.export _clear

.import _clrscr

.proc _clear
	; Use FILLM instead or CLS FIXME
	BRK_ORIX XHIRES ; Hires
	BRK_ORIX XTEXT  ; and text
	BRK_ORIX XSCRNE
	rts
.endproc

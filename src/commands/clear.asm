.export _clear

.import _clrscr

.proc _clear
	; Use FILLM instead or CLS FIXME
	BRK_KERNEL XHIRES ; Hires
	BRK_KERNEL XTEXT  ; and text
	BRK_KERNEL XSCRNE
	rts
.endproc

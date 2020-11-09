.export _clrscr

.proc _clrscr
	BRK_KERNEL XHIRES ; Hires
	BRK_KERNEL XTEXT  ; and text
	BRK_KERNEL XSCRNE
    rts
.endproc 
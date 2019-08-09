.export _ioports

.proc _ioports
    PRINT ioports_via1
	PRINT ioports_acia
    PRINT ioports_via2
    PRINT ioports_ch376
    rts
; TODO : replace by defines
ioports_via1:
    .byte "$300-$30F : 6522",$0D,$0A,0
ioports_via2:
    .byte "$320-$32F : 6522",$0D,$0A,0
ioports_ch376:
    .byte "$340-$341 : CH376",$0D,$0A,0
ioports_acia:	
	.byte "$31C-$31F : 6551",$0D,$0A,0
.endproc	


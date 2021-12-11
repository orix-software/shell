.export _ioports

.proc _ioports
    print ioports_via1,NOSAVE

.ifdef WITH_ACIA    
	print ioports_acia,NOSAVE
.endif     

    print ioports_via2,NOSAVE
    print ioports_ch376,NOSAVE
.ifdef WITH_TWILIGHTE_BOARD    
    print ioports_twil,NOSAVE
.endif    
    rts
; TODO : replace by defines
ioports_via1:
    .byte "$300-$30F : 6522",$0D,$0A,0
ioports_via2:
    .byte "$320-$32F : 65c22",$0D,$0A,0
ioports_ch376:
    .byte "$340-$341 : CH376",$0D,$0A,0

.ifdef WITH_ACIA    
ioports_acia:	
	.byte "$31C-$31F : 6551",$0D,$0A,0
.endif     

.ifdef WITH_TWILIGHTE_BOARD    
ioports_twil:    
    .byte "$342-$343 : TWILIGHTE BOARD",$0D,$0A,0
.endif    
.endproc	


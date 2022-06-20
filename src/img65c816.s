


.org $1000
        .byt $01,$00		; non-C64 marker like o65 format
        .byt "o", "r", "i"      ; "ori" MAGIC number :$6f, $36, $35 like o65 format
        .byt $01                ; version of this header
cpu_mode:
        .byt $00                ; CPU see below for description
os_type:
        ; 0 : Orix
        ; 1 : Sedoric
        ; 2 : Stratsed
        ; 3 : FTDOS
        .byt $00	        ;
        .byt $00                ; reserved
 
        .byt $00		; reserved
        .byt $00	        ; operating system id for telemon $00 means telemon 3.0 version
        .byt $00	        ; reserved
        .byt $00                ; reserved
type_of_file:
        ; bit 0 : basic
        ; bit 1 : machine langage
        .byt %00000000                   ; 
        .byt <start_adress,>start_adress ; loading adress
        .byt <EndOfMemory,>EndOfMemory   ; end of loading adress
        .byt <start_adress,>start_adress ; starting adress

dest:= $80
.define src  $82

.define iter  $85

start_adress:

    .byte $00,$1A
sei
.P816
.a8
.i16
    clc
    xce
    rep   #$10

	lda	  #<$a000
	sta	  dest
	lda	  #>$a000
	sta	  dest+1

	lda	  #<yessa
	sta	  src
	lda	  #>yessa
	sta	  src+1

	lda	  #200
	sta   iter

	ldx	  #$00
@loop:	
remove:
	ldy	  #8000
	jsr   draw


.a16
	rep #$30     ; Make Accumulator and index 16-bit



@loopme:

	ldx #$A028   
	ldy #$A000   
	lda #8000   

	mvn $00,$00  
	dec	iter
	bne @loopme
	;    rep   #$10	
;	rts
.a8


	;jsr   compute
	;inx
	;cpx   #200
	;bne   remove

    sec 
    xce
	cli
    rts

compute:

	lda	  src
	clc
	adc   #40
	bcc	  @S1
	inc	  src+1
@S1:
	sta	  src
.a8
	;lda	  remove+1
	;sec
	;sbc   #40
	;bne   @S2
;@S2:
	;sta	  remove+2	
	rts	

draw:

@L1:
@get:
    lda   (src),y
@store:	
    sta   (dest),y
    dey
    bne   @L1
	rts	
number:	
	.res 2
yessa:
	.byt $40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40
	.byt $40,$40,$40,$40,$40,$40,$01,$41,$40,$40,$40,$40,$40,$40,$40,$40
	.byt $40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40
	.byt $40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$01,$44,$40
	.byt $40,$41,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40
	.byt $40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40
	.byt $40,$40,$40,$40,$01,$44,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40
	.byt $40,$40,$40,$40,$40,$40,$40,$40,$04,$44,$40,$40,$40,$40,$40,$40
	.byt $40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$01,$42,$40,$40,$40
	.byt $60,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40
	.byt $40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40
	.byt $40,$40,$40,$40,$40,$40,$01,$50,$40,$40,$50,$40,$40,$40,$40,$40
	.byt $40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40
	.byt $40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$01,$48,$51,$40,$40
	.byt $40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40
	.byt $40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40
	.byt $40,$40,$01,$42,$42,$40,$40,$48,$42,$40,$40,$40,$40,$40,$40,$40
	.byt $40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40
	.byt $40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$01,$60,$60,$40,$40,$40
	.byt $40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40
	.byt $40,$40,$40,$40,$40,$40,$40,$06,$4f,$78,$40,$40,$40,$40,$40,$40
	.byt $40,$40,$01,$48,$40,$61,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40
	.byt $40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$06,$4f
	.byt $7e,$74,$40,$40,$40,$40,$40,$40,$40,$03,$49,$41,$48,$40,$40,$40
	.byt $40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40
	.byt $40,$40,$40,$40,$40,$06,$47,$75,$56,$5c,$40,$40,$40,$40,$40,$40
	.byt $40,$03,$60,$4a,$50,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40
	.byt $40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$06,$5a,$6a
	.byt $6b,$4a,$40,$40,$40,$40,$40,$40,$03,$4a,$4a,$60,$42,$40,$40,$40
	.byt $40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40
	.byt $40,$40,$40,$40,$40,$06,$74,$40,$55,$4e,$40,$40,$40,$40,$40,$40
	.byt $03,$41,$55,$41,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40
	.byt $40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$06,$68,$40
	.byt $4b,$4a,$40,$40,$40,$40,$40,$40,$03,$7c,$6a,$48,$40,$40,$04,$44
	.byt $40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40
	.byt $40,$40,$40,$40,$40,$06,$70,$40,$45,$6d,$40,$40,$40,$40,$40,$03
	.byt $43,$49,$55,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40
	.byt $40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$06,$60,$40
	.byt $43,$67,$40,$40,$40,$40,$40,$03,$4f,$73,$60,$40,$40,$40,$40,$40
	.byt $40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40
	.byt $40,$40,$40,$40,$40,$06,$71,$40,$45,$77,$40,$40,$40,$40,$40,$03
	.byt $5f,$7c,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40
	.byt $40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$06,$6a,$40
	.byt $4a,$7e,$40,$40,$40,$40,$40,$00,$13,$5f,$7f,$7f,$7f,$7f,$7f,$7f
	.byt $7f,$7f,$7f,$7f,$7f,$7f,$7f,$7f,$7f,$97,$78,$40,$5f,$7f,$7f,$7f
	.byt $40,$40,$40,$40,$40,$06,$74,$41,$51,$74,$40,$40,$40,$40,$40,$03
	.byt $4e,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40
	.byt $07,$41,$7f,$7f,$7e,$40,$40,$40,$40,$40,$40,$40,$40,$06,$68,$42
	.byt $62,$69,$60,$40,$40,$40,$07,$46,$40,$40,$40,$40,$40,$40,$40,$40
	.byt $40,$40,$40,$40,$40,$40,$40,$40,$03,$47,$7f,$7f,$7f,$60,$40,$40
	.byt $40,$40,$40,$40,$40,$06,$74,$40,$41,$53,$70,$40,$40,$40,$07,$4f
	.byt $40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40
	.byt $40,$5f,$7f,$7f,$7f,$78,$40,$40,$40,$40,$40,$40,$40,$06,$60,$40
	.byt $42,$65,$78,$40,$40,$40,$07,$4f,$40,$40,$40,$40,$40,$40,$40,$40
	.byt $40,$40,$40,$04,$41,$40,$40,$40,$40,$ff,$ff,$13,$00,$43,$7f,$7f
	.byt $40,$40,$40,$40,$40,$06,$70,$40,$44,$4b,$78,$40,$40,$40,$07,$46
	.byt $40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40
	.byt $41,$7f,$7f,$7f,$7f,$7e,$40,$40,$40,$40,$40,$40,$40,$06,$60,$40
	.byt $48,$65,$78,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40
	.byt $40,$40,$40,$40,$40,$40,$40,$03,$43,$7f,$7f,$7f,$7f,$7f,$40,$40
	.byt $40,$40,$40,$40,$40,$06,$70,$40,$41,$53,$74,$40,$40,$40,$40,$40
	.byt $40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$03
	.byt $47,$7f,$7f,$7f,$7f,$7f,$60,$40,$40,$40,$40,$40,$40,$06,$68,$40
	.byt $4a,$6f,$7c,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40
	.byt $40,$40,$40,$40,$40,$40,$40,$01,$4f,$7f,$7f,$7f,$7f,$7f,$70,$40
	.byt $40,$40,$40,$40,$06,$41,$50,$40,$41,$57,$7a,$40,$40,$40,$40,$40
	.byt $40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$03
	.byt $4f,$7f,$7f,$7f,$7f,$7f,$70,$40,$40,$40,$40,$40,$06,$41,$68,$40
	.byt $40,$6e,$7e,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40
	.byt $40,$40,$40,$40,$40,$40,$40,$01,$5f,$7f,$7f,$7f,$7f,$7f,$78,$40
	.byt $40,$40,$40,$40,$06,$41,$54,$40,$41,$5e,$5e,$40,$40,$40,$40,$40
	.byt $40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$01
	.byt $5f,$7f,$7f,$7f,$7f,$7f,$78,$40,$40,$40,$40,$40,$06,$41,$62,$60
	.byt $42,$6e,$5d,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40
	.byt $40,$40,$40,$40,$40,$40,$40,$40,$15,$40,$40,$40,$40,$00,$43,$7f
	.byt $14,$40,$40,$01,$97,$c1,$d1,$d0,$c4,$de,$cf,$c0,$c0,$14,$40,$40
	.byt $40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$05
	.byt $4c,$51,$60,$78,$7c,$4e,$40,$40,$14,$40,$40,$10,$06,$41,$60,$60
	.byt $42,$6e,$4d,$40,$40,$40,$14,$40,$42,$4c,$5d,$40,$61,$48,$61,$40
	.byt $40,$40,$40,$40,$40,$40,$40,$40,$72,$77,$6f,$7f,$7e,$5c,$64,$40
	.byt $14,$40,$ff,$10,$06,$41,$40,$40,$45,$5c,$66,$60,$40,$40,$40,$40
	.byt $14,$40,$40,$52,$42,$40,$44,$48,$40,$60,$40,$40,$40,$40,$40,$07
	.byt $44,$7f,$5f,$7f,$7f,$6c,$40,$40,$93,$c7,$ff,$10,$06,$42,$40,$40
	.byt $42,$6c,$77,$60,$40,$40,$40,$04,$4b,$7f,$7f,$14,$06,$42,$41,$60
	.byt $60,$51,$40,$40,$40,$40,$40,$40,$51,$7f,$77,$5e,$7f,$77,$68,$40
	.byt $14,$ff,$ff,$10,$06,$43,$41,$40,$55,$5c,$73,$50,$40,$40,$02,$68
	.byt $04,$6f,$7f,$7f,$7f,$7f,$14,$06,$48,$40,$40,$40,$40,$40,$40,$40
	.byt $07,$4e,$4a,$7e,$5c,$40,$40,$40,$40,$40,$40,$40,$06,$42,$40,$68
	.byt $6a,$4f,$73,$70,$40,$40,$02,$52,$68,$04,$42,$7f,$7f,$7f,$7f,$7f
	.byt $7f,$7f,$7f,$7f,$7f,$7f,$14,$06,$4c,$7d,$6f,$79,$7e,$7e,$60,$40
	.byt $40,$40,$40,$40,$06,$43,$41,$55,$50,$5d,$79,$70,$40,$40,$02,$41
	.byt $55,$50,$04,$41,$5f,$7f,$7f,$7f,$7f,$7f,$7f,$7f,$7f,$7f,$7f,$14
	.byt $07,$46,$5c,$63,$59,$60,$40,$40,$40,$40,$40,$40,$06,$42,$40,$6a
	.byt $40,$4c,$41,$68,$40,$40,$40,$02,$42,$6a,$60,$04,$41,$7f,$7f,$7f
	.byt $7f,$7f,$7f,$7f,$7f,$7f,$14,$06,$43,$7b,$7f,$77,$6c,$76,$40,$40
	.byt $40,$40,$40,$40,$06,$45,$40,$50,$40,$5f,$61,$78,$40,$40,$40,$02
	.byt $44,$51,$52,$40,$04,$41,$7f,$7f,$7f,$7f,$7f,$7f,$7f,$7f,$7f,$7f
	.byt $14,$07,$4e,$4e,$60,$40,$40,$40,$40,$40,$40,$40,$06,$46,$40,$48
	.byt $40,$49,$7f,$78,$40,$40,$40,$02,$41,$40,$64,$6a,$40,$04,$41,$7f
	.byt $7f,$7f,$7f,$7f,$7f,$7f,$7f,$14,$06,$5e,$7e,$77,$5b,$4c,$40,$40
	.byt $40,$40,$40,$40,$06,$44,$40,$40,$41,$52,$5b,$70,$40,$40,$40,$40
	.byt $02,$55,$48,$55,$55,$40,$40,$04,$47,$7f,$7f,$7f,$7f,$7f,$7f,$7f
	.byt $7f,$7f,$7f,$7f,$7f,$7f,$7f,$7f,$40,$40,$40,$40,$06,$46,$40,$40
	.byt $42,$65,$45,$40,$40,$40,$40,$40,$02,$48,$42,$60,$4a,$6a,$68,$40
	.byt $40,$04,$47,$7f,$7f,$7f,$7f,$14,$06,$4f,$5b,$4d,$5a,$72,$40,$40
	.byt $40,$40,$40,$40,$06,$44,$41,$41,$45,$46,$68,$70,$40,$40,$40,$40
	.byt $02,$44,$48,$42,$64,$50,$52,$50,$60,$40,$04,$43,$7f,$7f,$7f,$7f
	.byt $7f,$7f,$7f,$7f,$7f,$7f,$7f,$7f,$40,$40,$40,$40,$06,$4a,$4a,$60
	.byt $68,$4f,$75,$78,$40,$40,$40,$40,$40,$40,$02,$50,$42,$68,$44,$4a
	.byt $55,$44,$40,$04,$5f,$7f,$7f,$14,$06,$45,$48,$6e,$7a,$74,$40,$40
	.byt $40,$40,$40,$40,$06,$4d,$54,$51,$40,$57,$7f,$76,$40,$40,$40,$40
	.byt $40,$40,$40,$40,$40,$40,$02,$45,$4b,$78,$64,$04,$47,$7f,$7f,$7f
	.byt $7f,$7f,$7f,$7f,$7f,$7f,$7f,$7f,$40,$40,$40,$40,$06,$48,$68,$40
	.byt $62,$6b,$7f,$7e,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$02
	.byt $41,$7f,$48,$68,$40,$14,$40,$40,$40,$06,$54,$54,$53,$50,$40,$40
	.byt $40,$40,$40,$40,$06,$4d,$40,$40,$51,$47,$7c,$5a,$40,$40,$40,$40
	.byt $40,$40,$40,$40,$40,$40,$40,$02,$42,$6b,$79,$44,$04,$4f,$7f,$7f
	.byt $7f,$7f,$7f,$7f,$7f,$7f,$7f,$7f,$40,$40,$40,$40,$06,$48,$40,$42
	.byt $60,$4b,$79,$7d,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40
	.byt $02,$55,$54,$6a,$40,$04,$47,$7f,$14,$06,$42,$72,$48,$40,$40,$40
	.byt $40,$40,$40,$40,$06,$4c,$40,$41,$40,$47,$73,$7f,$40,$40,$40,$40
	.byt $40,$40,$40,$40,$40,$40,$40,$40,$02,$62,$40,$55,$40,$40,$40,$14
	.byt $40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$06,$48,$40,$40
	.byt $60,$43,$77,$4d,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40
	.byt $02,$41,$50,$49,$50,$40,$04,$4f,$7f,$7f,$7f,$7f,$7f,$7f,$7f,$7f
	.byt $40,$40,$40,$40,$04,$60,$40,$06,$45,$45,$70,$4e,$60,$40,$40,$40
	.byt $40,$40,$40,$40,$40,$40,$40,$40,$40,$02,$68,$42,$60,$04,$5f,$7f
	.byt $7f,$7f,$7f,$7f,$7f,$7f,$7f,$7f,$40,$40,$40,$04,$45,$50,$40,$06
	.byt $42,$6b,$73,$4f,$60,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40
	.byt $40,$02,$50,$45,$44,$40,$14,$40,$40,$40,$40,$40,$40,$40,$40,$40
	.byt $40,$40,$40,$04,$4a,$6a,$40,$40,$06,$55,$7f,$4e,$60,$40,$40,$40
	.byt $40,$01,$45,$6f,$7d,$40,$40,$40,$40,$02,$60,$4a,$78,$40,$14,$40
	.byt $40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$04,$41,$55,$55,$50,$40
	.byt $06,$43,$7e,$5f,$70,$40,$40,$40,$40,$03,$42,$77,$70,$40,$40,$40
	.byt $40,$40,$02,$51,$7d,$04,$5f,$7f,$7f,$7f,$7f,$7f,$7f,$7f,$7f,$7f
	.byt $40,$40,$04,$42,$6a,$6a,$6a,$40,$06,$45,$78,$7d,$50,$40,$40,$40
	.byt $40,$01,$6f,$7f,$7c,$6c,$40,$40,$40,$02,$6a,$42,$7e,$04,$4f,$7f
	.byt $7f,$7f,$7f,$7f,$7f,$7f,$7f,$7f,$40,$40,$04,$55,$55,$55,$55,$50
	.byt $06,$42,$7f,$6a,$60,$40,$40,$40,$40,$03,$45,$6d,$7c,$40,$40,$40
	.byt $02,$41,$55,$41,$7e,$50,$40,$14,$40,$40,$40,$40,$40,$40,$40,$40
	.byt $40,$40,$04,$6a,$6a,$6a,$6a,$6a,$06,$45,$55,$55,$40,$40,$40,$40
	.byt $01,$45,$7f,$c0,$76,$65,$60,$40,$40,$02,$4b,$6a,$5f,$68,$04,$4f
	.byt $7f,$7f,$7f,$7f,$7f,$7f,$7f,$7f,$40,$04,$41,$55,$55,$55,$55,$55
	.byt $06,$4a,$6a,$60,$40,$40,$40,$40,$40,$03,$6e,$77,$76,$60,$40,$40
	.byt $40,$02,$41,$7d,$5f,$74,$04,$43,$7f,$7f,$7f,$7f,$7f,$7f,$7f,$7f
	.byt $40,$04,$4a,$6a,$6a,$6a,$6a,$6a,$68,$40,$40,$40,$40,$40,$40,$40
	.byt $01,$77,$7f,$c0,$7f,$7a,$58,$40,$40,$02,$42,$6a,$7f,$7a,$40,$40
	.byt $14,$40,$40,$40,$40,$40,$40,$40,$40,$04,$55,$55,$55,$55,$55,$55
	.byt $55,$50,$40,$40,$40,$40,$40,$40,$03,$41,$5b,$7f,$7d,$68,$40,$40
	.byt $40,$02,$41,$51,$55,$75,$54,$04,$4f,$60,$41,$7f,$7f,$7f,$7f,$7f
	.byt $40,$04,$4a,$6a,$6a,$6a,$6a,$6a,$6a,$60,$40,$40,$40,$40,$40,$01
	.byt $41,$47,$c0,$c0,$7f,$79,$54,$40,$40,$40,$02,$42,$6a,$7a,$48,$60
	.byt $40,$40,$04,$5f,$7f,$7f,$7f,$7f,$40,$04,$55,$55,$55,$55,$55,$55
	.byt $40,$40,$40,$40,$40,$40,$40,$40,$03,$42,$77,$7f,$76,$50,$40,$40
	.byt $40,$40,$40,$02,$51,$5d,$55,$50,$40,$40,$04,$4f,$7f,$7f,$7f,$7f
	.byt $40,$04,$4a,$6a,$6a,$6a,$6a,$60,$40,$40,$40,$40,$40,$40,$40,$01
	.byt $44,$57,$7f,$c0,$c0,$7e,$73,$40,$40,$40,$02,$41,$42,$6a,$6a,$68
	.byt $40,$40,$04,$41,$7f,$7f,$7f,$7f,$40,$04,$45,$55,$55,$55,$50,$40
	.byt $40,$40,$40,$40,$40,$40,$40,$40,$40,$03,$57,$7f,$7b,$50,$40,$40
	.byt $40,$40,$40,$02,$45,$45,$45,$75,$54,$44,$40,$40,$40,$04,$5f,$7f
	.byt $40,$04,$42,$6a,$6a,$68,$40,$40,$40,$40,$06,$47,$40,$40,$40,$01
	.byt $48,$6d,$7f,$c0,$7f,$7f,$49,$60,$40,$40,$40,$02,$42,$40,$42,$6f
	.byt $6a,$6a,$48,$40,$40,$04,$43,$7f,$40,$40,$04,$55,$40,$40,$40,$40
	.byt $40,$40,$06,$49,$60,$40,$40,$40,$40,$03,$4b,$7f,$7f,$5a,$40,$40
	.byt $40,$40,$40,$40,$40,$40,$02,$55,$77,$75,$51,$40,$50,$40,$40,$40
	.byt $40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$06,$54,$70,$40,$40,$01
	.byt $51,$5f,$c0,$c0,$7f,$7f,$6a,$50,$40,$40,$40,$40,$40,$40,$02,$42
	.byt $5f,$7e,$6a,$6a,$62,$48,$40,$40,$40,$40,$40,$40,$40,$03,$42,$40
	.byt $40,$40,$06,$4a,$70,$40,$40,$40,$40,$03,$45,$7f,$7f,$77,$54,$40
	.byt $40,$40,$40,$40,$40,$40,$40,$02,$63,$7f,$7f,$7f,$55,$50,$40,$40
	.byt $40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$06,$55,$60,$40,$40,$01
	.byt $65,$6f,$7f,$c0,$7f,$7f,$75,$48,$40,$40,$40,$40,$40,$40,$40,$02
	.byt $44,$6f,$7f,$7f,$7e,$6a,$60,$40,$40,$40,$40,$40,$40,$03,$48,$40
	.byt $40,$40,$04,$7b,$40,$40,$40,$40,$40,$03,$57,$7f,$7f,$7d,$68,$40
	.byt $40,$40,$40,$40,$40,$40,$40,$02,$41,$55,$5f,$7f,$7f,$7d,$54,$40
	.byt $40,$40,$40,$40,$40,$40,$40,$40,$40,$04,$41,$54,$40,$40,$01,$41
	.byt $45,$77,$7f,$c0,$c0,$7f,$7b,$4a,$40,$40,$40,$40,$40,$40,$40,$40
	.byt $02,$42,$6f,$6f,$7f,$7f,$6a,$68,$40,$40,$40,$40,$40,$40,$40,$40
	.byt $40,$40,$04,$60,$40,$40,$40,$40,$40,$03,$6f,$7f,$7f,$7e,$6a,$40
	.byt $40,$40,$40,$40,$06,$41,$70,$40,$02,$41,$55,$55,$7f,$7f,$7f,$74
	.byt $40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$01,$41
	.byt $56,$7f,$c0,$c0,$c0,$7f,$7b,$64,$40,$40,$40,$40,$06,$43,$68,$40
	.byt $02,$42,$6a,$4a,$7f,$7f,$7e,$6a,$40,$40,$40,$40,$40,$40,$03,$60
	.byt $40,$40,$40,$40,$40,$40,$40,$40,$40,$45,$6f,$7f,$7f,$7d,$54,$40
	.byt $40,$40,$40,$40,$06,$43,$74,$40,$02,$45,$50,$50,$57,$7f,$55,$50
	.byt $40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$01,$42
	.byt $5b,$7f,$7f,$7f,$c0,$c0,$7b,$55,$40,$40,$40,$40,$06,$47,$7a,$40
	.byt $02,$42,$40,$40,$63,$7f,$6a,$48,$40,$40,$40,$40,$40,$03,$44,$40
	.byt $40,$40,$40,$40,$40,$40,$40,$40,$40,$42,$77,$7f,$7f,$7f,$6a,$40
	.byt $40,$40,$40,$40,$06,$44,$7d,$40,$02,$44,$40,$40,$45,$7f,$55,$40
	.byt $40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$01,$42
	.byt $47,$5f,$7f,$c0,$c0,$c0,$75,$64,$60,$40,$40,$40,$06,$4a,$5e,$40
	.byt $40,$40,$40,$02,$4a,$6e,$60,$60,$40,$40,$40,$40,$40,$03,$41,$40
	.byt $40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$5f,$7f,$7f,$7b,$40
	.byt $40,$40,$40,$40,$06,$45,$5f,$40,$40,$40,$40,$02,$41,$55,$41,$50
	.byt $40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$01,$42
	.byt $4a,$6a,$7f,$7f,$c0,$c0,$7d,$5a,$48,$40,$40,$40,$06,$4a,$74,$40
	.byt $40,$40,$40,$02,$4a,$68,$40,$60,$40,$40,$40,$40,$40,$03,$60,$40
	.byt $40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$43,$7f,$7f,$7d,$50
	.byt $40,$40,$40,$40,$04,$55,$50,$40,$40,$40,$40,$02,$55,$40,$40,$40
	.byt $40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$01,$44
	.byt $45,$50,$42,$6f,$7f,$7f,$7a,$62,$60,$40,$40,$40,$04,$6a,$60,$40
	.byt $40,$40,$40,$02,$68,$60,$40,$40,$40,$40,$40,$40,$40,$03,$42,$40
	.byt $40,$40,$40,$40,$40,$40,$40,$40,$40,$46,$47,$40,$41,$7f,$7d,$50
	.byt $40,$40,$40,$04,$41,$55,$40,$40,$40,$40,$40,$02,$44,$40,$40,$40
	.byt $40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$01,$48
	.byt $52,$4f,$47,$61,$4f,$7f,$7e,$54,$49,$40,$40,$04,$42,$68,$40,$40
	.byt $40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$03,$48,$50
	.byt $40,$40,$40,$40,$40,$40,$40,$40,$40,$5f,$47,$70,$60,$57,$7e,$60
	.byt $40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40
	.byt $40,$40,$40,$40,$40,$01,$4c,$40,$40,$40,$40,$40,$40,$40,$40,$48
	.byt $64,$7f,$47,$70,$71,$7f,$7a,$4a,$42,$40,$40,$40,$40,$40,$40,$40
	.byt $40,$40,$40,$40,$40,$06,$4f,$40,$40,$40,$40,$40,$40,$03,$66,$60
	.byt $40,$40,$40,$40,$40,$40,$40,$40,$41,$7f,$67,$70,$78,$45,$7f,$50
	.byt $40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$06,$53,$70
	.byt $40,$40,$40,$40,$40,$01,$4b,$40,$40,$40,$40,$40,$40,$40,$40,$4a
	.byt $71,$7f,$67,$78,$7c,$5f,$7a,$52,$60,$60,$40,$40,$40,$40,$40,$40
	.byt $40,$40,$40,$40,$40,$06,$69,$78,$40,$40,$40,$40,$40,$03,$56,$60
	.byt $40,$40,$40,$40,$40,$40,$40,$40,$43,$7f,$67,$78,$7e,$42,$7f,$68
	.byt $40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$06,$55,$78
	.byt $40,$40,$40,$40,$40,$01,$46,$40,$40,$40,$40,$40,$40,$40,$40,$52
	.byt $73,$7f,$63,$78,$5f,$47,$7f,$7e,$56,$40,$40,$40,$40,$40,$40,$40
	.byt $40,$40,$40,$40,$40,$06,$6b,$78,$40,$40,$40,$40,$40,$03,$77,$54
	.byt $40,$40,$40,$40,$40,$40,$40,$40,$43,$7f,$63,$7c,$5f,$61,$5f,$50
	.byt $40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$04,$41,$76,$60
	.byt $40,$40,$40,$40,$40,$01,$4e,$40,$40,$40,$40,$40,$40,$40,$42,$5d
	.byt $5b,$7f,$73,$7c,$5f,$79,$7f,$7e,$78,$58,$40,$40,$40,$40,$40,$40
	.byt $40,$40,$40,$40,$04,$42,$6d,$40,$40,$40,$40,$40,$40,$03,$57,$50
	.byt $40,$40,$40,$40,$40,$40,$40,$40,$43,$6f,$73,$7e,$5f,$7c,$6f,$68
	.byt $40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$04,$41,$4a,$40
	.byt $40,$40,$40,$40,$40,$01,$47,$60,$40,$40,$40,$40,$40,$40,$52,$72
	.byt $7b,$73,$73,$7e,$4f,$76,$5f,$7d,$60,$42,$40,$40,$40,$40,$40,$40
	.byt $40,$40,$40,$40,$40,$04,$50,$40,$40,$40,$40,$40,$03,$42,$73,$68
	.byt $40,$40,$40,$40,$40,$40,$40,$40,$43,$74,$49,$7f,$4e,$4f,$4b,$68
	.byt $40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40
	.byt $40,$40,$40,$40,$40,$01,$4e,$40,$40,$40,$40,$40,$40,$42,$45,$6b
	.byt $73,$79,$51,$5f,$4c,$68,$6f,$7a,$43,$61,$40,$40,$40,$40,$40,$40
	.byt $40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$03,$41,$47,$74
	.byt $40,$40,$40,$40,$40,$40,$40,$40,$43,$7d,$6d,$4f,$67,$5b,$63,$60
	.byt $44,$7c,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40
	.byt $40,$40,$40,$40,$40,$40,$96,$df,$ff,$ff,$ff,$ff,$ff,$f7,$ff,$cc
	.byt $d6,$c1,$c3,$c8,$cc,$c8,$c8,$cb,$e4,$c1,$df,$ff,$ff,$ff,$ff,$ff
	.byt $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$40,$40,$40,$40,$03,$42,$7f,$42
	.byt $40,$40,$40,$40,$40,$40,$40,$40,$41,$7f,$46,$77,$5a,$4f,$70,$40
	.byt $67,$7f,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40
	.byt $40,$40,$40,$40,$40,$40,$96,$cb,$ff,$ff,$ff,$ff,$ff,$dc,$c0,$fa
	.byt $d6,$c0,$c1,$e0,$e2,$c0,$c4,$ce,$f0,$c0,$df,$ff,$ff,$ff,$ff,$ff
	.byt $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$40,$40,$40,$40,$03,$44,$7f,$62
	.byt $40,$40,$40,$40,$40,$4c,$40,$60,$41,$7f,$7f,$4f,$5e,$5f,$79,$62
	.byt $5f,$7f,$60,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40
	.byt $40,$40,$40,$40,$01,$41,$7f,$78,$40,$40,$40,$40,$41,$59,$7c,$62
	.byt $71,$7f,$7f,$67,$5f,$67,$7d,$74,$7f,$7f,$60,$40,$40,$40,$40,$40
	.byt $40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$03,$41,$7f,$79
	.byt $40,$40,$40,$40,$40,$4f,$7f,$58,$40,$7f,$7f,$77,$5f,$79,$7c,$74
	.byt $6f,$7f,$70,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40
	.byt $40,$40,$40,$40,$01,$44,$7f,$7a,$40,$40,$40,$40,$41,$5f,$7f,$69
	.byt $58,$7f,$7f,$7b,$6f,$7e,$41,$65,$7f,$7f,$70,$40,$40,$40,$40,$40
	.byt $40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$03,$49,$7f,$7e
	.byt $60,$40,$40,$40,$40,$7f,$7f,$76,$40,$5f,$7f,$7c,$7f,$7f,$78,$45
	.byt $5f,$7f,$78,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40
	.byt $40,$40,$40,$40,$01,$42,$5f,$70,$40,$40,$40,$40,$41,$7f,$7f,$7a
	.byt $68,$5f,$7f,$6f,$4f,$7f,$73,$45,$7f,$7f,$78,$40,$40,$40,$40,$40
	.byt $40,$5f,$70,$40,$40,$40,$40,$40,$40,$40,$40,$40,$03,$41,$5f,$7a
	.byt $40,$40,$40,$40,$41,$7f,$7d,$6b,$40,$4f,$7f,$7f,$71,$7f,$70,$45
	.byt $5f,$7f,$78,$40,$40,$40,$40,$40,$5f,$7f,$7f,$70,$40,$40,$40,$40
	.byt $40,$40,$40,$40,$40,$01,$57,$7a,$40,$40,$40,$40,$43,$7f,$7f,$75
	.byt $4a,$4f,$7f,$5f,$77,$7f,$63,$45,$6f,$7f,$7c,$40,$40,$40,$40,$43
	.byt $7f,$7f,$7f,$7f,$78,$40,$40,$40,$40,$40,$40,$40,$03,$42,$4f,$79
	.byt $40,$40,$40,$40,$43,$7f,$7f,$55,$60,$47,$7f,$5f,$77,$7f,$60,$44
	.byt $6f,$7f,$7c,$40,$40,$40,$40,$4f,$7f,$7f,$7f,$7f,$7f,$40,$40,$40
	.byt $40,$40,$40,$40,$40,$01,$43,$74,$40,$40,$40,$40,$43,$7f,$7f,$7a
	.byt $6c,$47,$7f,$67,$4f,$7f,$43,$42,$6b,$7f,$7c,$40,$40,$40,$40,$7f
	.byt $7f,$7f,$7f,$7f,$7f,$78,$40,$40,$40,$40,$40,$40,$40,$03,$57,$7c
	.byt $40,$40,$40,$40,$43,$7f,$7f,$6a,$60,$43,$7b,$78,$7e,$7e,$40,$42
	.byt $6b,$7f,$70,$40,$40,$40,$43,$7f,$7f,$7f,$7f,$7f,$7f,$7e,$40,$40
	.byt $40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$01,$47,$7f,$7f,$7a
	.byt $65,$41,$7c,$7f,$79,$7c,$45,$60,$75,$7f,$61,$7f,$7f,$40,$47,$7f
	.byt $7f,$7f,$7f,$7f,$7f,$7f,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40
	.byt $40,$40,$40,$03,$47,$7f,$7f,$6a,$60,$41,$7c,$4f,$61,$79,$40,$40
	.byt $55,$7f,$6f,$7f,$7f,$78,$4f,$7f,$7f,$7f,$7d,$57,$7f,$7f,$40,$40
	.byt $40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$01,$4f,$7f,$7f,$7a
	.byt $63,$40,$7e,$40,$43,$79,$43,$60,$5a,$7f,$5f,$7f,$7f,$7f,$5f,$7f
	.byt $7f,$7f,$7d,$6e,$6a,$6e,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40
	.byt $40,$40,$40,$03,$4f,$7f,$7f,$54,$60,$42,$5f,$40,$47,$72,$40,$40
	.byt $4a,$7e,$7f,$7f,$7f,$7e,$7f,$7f,$7f,$7e,$6a,$42,$6a,$6c,$40,$40
	.byt $40,$40,$40,$40,$40,$01,$43,$7f,$7e,$40,$40,$40,$4f,$7f,$7f,$75
	.byt $42,$42,$4f,$60,$4f,$62,$42,$70,$4d,$5e,$7f,$7f,$7f,$7e,$7f,$7f
	.byt $7f,$75,$55,$60,$47,$70,$40,$40,$40,$40,$40,$40,$03,$41,$7f,$7f
	.byt $7f,$78,$40,$40,$4f,$7f,$7e,$71,$40,$41,$57,$70,$5f,$54,$40,$40
	.byt $45,$5d,$7f,$7f,$7f,$7d,$7f,$7f,$7f,$6b,$7f,$70,$40,$40,$40,$40
	.byt $40,$40,$40,$40,$01,$4f,$7f,$7f,$7f,$7f,$40,$47,$67,$7f,$7f,$6a
	.byt $41,$41,$5b,$7f,$7e,$74,$41,$58,$46,$5d,$7f,$7f,$7f,$7d,$7f,$7f
	.byt $7f,$7f,$7f,$7c,$40,$40,$40,$40,$40,$40,$40,$03,$41,$7f,$7f,$7f
	.byt $7f,$7f,$73,$7f,$79,$7f,$7d,$54,$40,$41,$5d,$7f,$7d,$74,$40,$40
	.byt $42,$6f,$7f,$7f,$7f,$7b,$7f,$7f,$7e,$7f,$7f,$7e,$40,$40,$40,$40
	.byt $40,$40,$40,$40,$11,$40,$40,$40,$40,$00,$42,$40,$41,$40,$40,$6f
	.byt $7e,$7e,$61,$40,$44,$4b,$7f,$53,$7d,$50,$40,$40,$40,$44,$40,$40
	.byt $40,$40,$40,$40,$7f,$7f,$7f,$7f,$40,$40,$03,$4f,$7f,$7f,$7f,$7f
	.byt $7f,$7f,$7e,$5f,$7f,$5f,$7d,$40,$40,$41,$4f,$4f,$67,$74,$40,$40
	.byt $41,$57,$7f,$7f,$7f,$77,$7f,$7f,$7f,$7f,$7f,$7f,$60,$40,$40,$40
	.byt $40,$01,$41,$7f,$7f,$7f,$7f,$7f,$7f,$7f,$7f,$6f,$7f,$6f,$7e,$60
	.byt $42,$40,$6f,$70,$5f,$74,$40,$64,$41,$57,$7f,$7f,$7f,$77,$7f,$7f
	.byt $7f,$7f,$7f,$7f,$70,$40,$40,$40,$40,$03,$47,$7f,$7f,$75,$5b,$7f
	.byt $7f,$7f,$7f,$77,$7f,$77,$75,$40,$40,$40,$6f,$7f,$7f,$64,$40,$40
	.byt $40,$6b,$7f,$7f,$7f,$6f,$7f,$7f,$7f,$7f,$7f,$7f,$78,$40,$40,$40
	.byt $40,$01,$5f,$7f,$7e,$6b,$57,$7f,$7f,$7f,$7f,$7b,$7f,$7b,$7d,$40
	.byt $44,$40,$6f,$7f,$7f,$68,$41,$42,$40,$55,$7f,$7f,$7f,$6d,$7f,$7f
	.byt $7f,$7f,$7f,$7f,$7c,$40,$40,$40,$40,$03,$5f,$7f,$7d,$55,$7f,$7f
	.byt $7f,$7f,$7f,$7b,$7f,$7d,$7d,$40,$40,$40,$67,$7f,$7f,$68,$40,$40
	.byt $40,$4b,$7f,$7f,$7f,$6e,$7f,$7f,$7f,$7f,$7f,$7f,$7f,$40,$40,$40
	.byt $40,$01,$5f,$7e,$6a,$47,$7f,$7f,$7f,$7f,$7f,$7d,$7f,$7e,$7a,$40
	.byt $4a,$40,$67,$7f,$7f,$48,$42,$42,$40,$4a,$7f,$7f,$7f,$75,$7f,$7f
	.byt $7f,$7f,$7f,$7f,$7f,$60,$40,$40,$40,$03,$4a,$6a,$70,$47,$7f,$7f
	.byt $7f,$7f,$7f,$7d,$7f,$7f,$56,$40,$40,$40,$53,$7f,$7f,$48,$40,$40
	.byt $40,$45,$7f,$7f,$7f,$76,$6f,$7f,$7f,$7f,$7f,$7f,$7f,$78,$40,$40
	.byt $40,$01,$45,$56,$40,$4f,$7f,$7f,$7f,$7f,$7f,$7b,$7f,$7f,$54,$40
	.byt $4a,$40,$53,$7f,$7e,$50,$42,$41,$40,$46,$7f,$7f,$7f,$75,$5f,$7f
	.byt $7f,$7f,$7f,$7f,$7f,$7c,$40,$40,$40,$40,$40,$40,$03,$5f,$7f,$7f
	.byt $7f,$7f,$7f,$6b,$7f,$7f,$5c,$40,$40,$40,$49,$7f,$7e,$50,$40,$40
	.byt $40,$42,$6b,$7f,$7f,$7a,$6f,$7f,$7f,$7f,$7f,$7f,$7f,$7f,$40,$40
	.byt $40,$40,$40,$40,$01,$5f,$7f,$7f,$7f,$7f,$7f,$7b,$7f,$7d,$68,$40
	.byt $51,$40,$49,$7f,$7c,$60,$44,$40,$40,$41,$55,$5f,$7f,$7b,$5f,$7f
	.byt $7f,$7f,$7f,$7f,$7f,$7f,$60,$40,$40,$40,$40,$40,$40,$13,$40,$40
	.byt $40,$40,$00,$64,$40,$41,$5f,$7f,$7f,$7f,$7b,$40,$43,$5f,$7f,$7f
	.byt $7f,$7e,$6a,$6a,$68,$52,$50,$40,$40,$40,$40,$40,$40,$40,$47,$7f
	.byt $40,$40,$40,$01,$41,$7f,$7f,$7f,$7f,$7f,$7f,$77,$7f,$7e,$60,$40
	.byt $60,$60,$42,$5f,$79,$40,$40,$40,$40,$40,$6a,$6b,$7c,$45,$57,$7f
	.byt $7f,$7f,$7f,$7f,$7f,$7f,$7e,$40,$40,$40,$40,$03,$41,$7f,$7f,$7f
	.byt $7f,$7f,$7d,$57,$7f,$7d,$50,$40,$40,$40,$41,$4f,$72,$40,$40,$40
	.byt $40,$40,$4b,$6d,$40,$42,$6b,$7f,$7f,$7f,$7f,$7f,$75,$7f,$7f,$40
	.byt $40,$40,$40,$01,$43,$7f,$7f,$7f,$7f,$7f,$7e,$6f,$7f,$7e,$70,$40
	.byt $40,$50,$40,$67,$64,$40,$40,$40,$40,$40,$40,$40,$40,$41,$55,$7f
	.byt $7f,$7f,$7f,$7f,$73,$7f,$7f,$60,$40,$40,$40,$03,$47,$7f,$7f,$7f
	.byt $7f,$7f,$7a,$6f,$7f,$7a,$60,$40,$40,$40,$40,$53,$48,$40,$40,$40
	.byt $04,$54,$40,$40,$40,$03,$6a,$7f,$7f,$7f,$7f,$7f,$7c,$6f,$7f,$78
	.byt $40,$40,$40,$01,$47,$7f,$7f,$7f,$7f,$7f,$7e,$6f,$7f,$7d,$60,$40
	.byt $40,$40,$40,$48,$50,$40,$40,$40,$04,$48,$40,$40,$40,$01,$55,$7f
	.byt $7f,$7f,$7f,$7f,$7e,$5f,$7f,$7c,$40,$40,$40,$03,$4f,$7f,$7f,$7f
	.byt $7f,$7f,$75,$5a,$7f,$55,$40,$40,$40,$40,$40,$48,$50,$40,$40,$40
	.byt $04,$54,$40,$40,$40,$03,$4b,$5f,$7f,$7f,$7f,$7f,$7f,$65,$7f,$7f
	.byt $40,$40,$40,$01,$4f,$7f,$7f,$7f,$7f,$7f,$7d,$5a,$7e,$6b,$40,$40
	.byt $40,$40,$40,$44,$60,$40,$40,$40,$04,$6c,$40,$40,$40,$01,$46,$6f
	.byt $7f,$7f,$7f,$5f,$7f,$71,$7f,$7f,$40,$40,$40,$03,$5f,$7f,$7f,$7f
	.byt $7f,$7f,$5a,$75,$55,$56,$04,$60,$40,$40,$03,$44,$60,$40,$40,$40
	.byt $04,$58,$40,$40,$40,$03,$41,$57,$7f,$7f,$7f,$6b,$7f,$78,$57,$7f
	.byt $40,$40,$40,$01,$7f,$7f,$7f,$7f,$7f,$7e,$54,$43,$7d,$5c,$04,$60
	.byt $40,$40,$01,$43,$40,$40,$40,$40,$04,$78,$40,$40,$40,$40,$01,$6b
	.byt $7f,$7f,$7f,$75,$7f,$7e,$47,$7f,$40,$40,$03,$41,$7f,$7f,$7f,$7f
	.byt $7f,$7d,$68,$40,$4f,$70,$04,$70,$40,$40,$03,$44,$60,$40,$40,$04
	.byt $41,$58,$40,$40,$40,$40,$03,$56,$7f,$7f,$5f,$69,$5f,$7f,$41,$5f
	.byt $40,$40,$01,$43,$7f,$7f,$7f,$7f,$7f,$7d,$50,$40,$40,$40,$04,$50
	.byt $40,$40,$01,$43,$40,$40,$40,$04,$42,$70,$40,$40,$40,$40,$01,$4d
	.byt $5b,$7f,$6f,$7e,$77,$7f,$70,$7f,$40,$40,$03,$47,$7f,$7f,$7f,$7f
	.byt $7f,$7b,$50,$40,$40,$40,$04,$58,$40,$40,$03,$44,$60,$40,$40,$04
	.byt $45,$70,$40,$40,$40,$40,$03,$42,$75,$7f,$57,$7f,$4b,$7f,$78,$57
	.byt $40,$40,$01,$4f,$7f,$5f,$7f,$7f,$7f,$7a,$60,$40,$40,$40,$04,$48
	.byt $40,$40,$01,$43,$40,$40,$04,$42,$53,$70,$40,$40,$40,$40,$01,$41
	.byt $6f,$7d,$6b,$7f,$75,$7f,$7e,$47,$40,$40,$03,$4f,$7e,$7f,$7f,$7f
	.byt $7f,$6d,$40,$40,$40,$40,$04,$4e,$40,$40,$03,$44,$60,$40,$04,$44
	.byt $4f,$60,$40,$40,$40,$40,$40,$03,$57,$7d,$55,$71,$7a,$7f,$7f,$41
	.byt $40,$40,$01,$5f,$7d,$7f,$7f,$7f,$7f,$6a,$40,$40,$40,$40,$04,$45
	.byt $40,$40,$01,$43,$40,$04,$44,$6b,$5f,$60,$40,$40,$40,$40,$40,$01
	.byt $4b,$7e,$43,$6f,$7c,$6f,$7f,$70,$40,$40,$40,$94,$c4,$c0,$c0,$c0
	.byt $c0,$e5,$ff,$ff,$ff,$10,$04,$46,$68,$44,$03,$44,$60,$04,$41,$57
	.byt $77,$40,$40,$40,$40,$40,$40,$03,$45,$7e,$41,$5f,$7f,$57,$7f,$78
	.byt $40,$01,$41,$7f,$77,$7f,$5f,$7f,$7f,$64,$40,$40,$40,$40,$04,$47
	.byt $55,$50,$01,$43,$40,$40,$04,$4a,$6f,$40,$40,$40,$40,$40,$40,$01
	.byt $45,$7f,$40,$57,$7f,$65,$7f,$7c,$40,$03,$43,$7f,$6f,$7e,$7f,$7f
	.byt $7d,$68,$40,$40,$40,$40,$04,$43,$7a,$60,$03,$44,$60,$40,$04,$55
	.byt $5e,$40,$40,$40,$40,$40,$40,$03,$42,$7f,$40,$45,$7f,$79,$5f,$7f
	.byt $40,$01,$47,$7f,$5f,$7d,$7f,$7f,$7d,$50,$40,$40,$40,$40,$04,$43
	.byt $75,$40,$01,$43,$40,$40,$04,$4b,$7e,$40,$40,$40,$40,$40,$40,$01
	.byt $41,$5f,$60,$43,$5e,$4e,$4b,$7f,$40,$03,$4f,$7c,$7f,$7b,$7f,$7b
	.byt $76,$60,$40,$40,$40,$40,$04,$41,$6a,$40,$03,$44,$60,$40,$04,$45
	.byt $7e,$40,$40,$40,$40,$40,$40,$40,$03,$6f,$70,$40,$6d,$7f,$42,$7f
	.byt $40,$01,$5f,$7b,$4f,$77,$7f,$73,$75,$40,$40,$40,$40,$40,$04,$43
	.byt $74,$40,$01,$43,$40,$40,$04,$42,$7e,$40,$40,$40,$40,$40,$40,$40
	.byt $01,$57,$78,$40,$5b,$7f,$71,$5f,$40,$40,$94,$c8,$c8,$d7,$c0,$f8
	.byt $d5,$ff,$ff,$ff,$ff,$10,$04,$41,$68,$40,$03,$44,$60,$40,$04,$41
	.byt $7e,$40,$40,$40,$40,$40,$40,$40,$03,$4b,$7c,$40,$45,$7f,$78,$6f
	.byt $01,$41,$7f,$6f,$7b,$5f,$4e,$4f,$64,$40,$40,$40,$40,$40,$04,$41
	.byt $50,$40,$01,$43,$40,$40,$04,$42,$7c,$40,$40,$40,$40,$40,$40,$40
	.byt $01,$45,$7e,$40,$45,$6f,$7c,$4b,$03,$43,$7f,$5f,$7e,$7f,$74,$4e
	.byt $68,$40,$40,$40,$40,$40,$04,$41,$68,$40,$03,$43,$40,$40,$04,$41
	.byt $7c,$40,$40,$40,$40,$40,$40,$40,$03,$42,$7f,$40,$42,$6b,$7e,$43
	.byt $01,$43,$7e,$7f,$79,$7f,$79,$73,$50,$40,$40,$40,$40,$40,$04,$41
	.byt $70,$40,$40,$43,$40,$40,$40,$40,$7c,$40,$40,$40,$40,$40,$40,$40
	.byt $01,$41,$5f,$60,$40,$4b,$7c,$40,$03,$47,$79,$7f,$66,$7f,$73,$7c
	.byt $60,$40,$40,$40,$40,$40,$04,$41,$78,$40,$03,$43,$40,$40,$04,$41
	.byt $5c,$40,$40,$40,$40,$40,$40,$40,$40,$03,$6f,$60,$40,$45,$60,$40
	.byt $01,$47,$77,$7f,$5f,$5f,$47,$7d,$40,$40,$40,$40,$40,$40,$40,$04
	.byt $70,$40,$40,$47,$60,$40,$40,$40,$7c,$40,$40,$40,$40,$40,$40,$40
	.byt $40,$01,$5b,$70,$40,$40,$40,$40,$03,$4f,$6f,$7e,$7f,$6e,$47,$6a
	.byt $40,$40,$40,$40,$40,$40,$04,$41,$68,$40,$03,$47,$60,$40,$04,$41
	.byt $58,$40,$40,$40,$40,$40,$40,$40,$40,$03,$45,$70,$40,$40,$40,$40
	.byt $01,$4f,$5f,$7d,$7f,$68,$47,$74,$40,$40,$40,$40,$40,$40,$40,$04
	.byt $70,$40,$40,$4f,$70,$40,$40,$40,$7c,$40,$40,$40,$40,$40,$40,$40
	.byt $40,$01,$41,$70,$40,$40,$40,$40,$03,$4e,$7f,$79,$7f,$60,$43,$70
	.byt $40,$40,$40,$40,$40,$40,$40,$04,$68,$40,$03,$4f,$70,$40,$04,$41
	.byt $58,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40
	.byt $01,$49,$7f,$70,$7e,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$04
	.byt $70,$40,$40,$47,$60,$40,$40,$40,$78,$40,$40,$40,$40,$40,$40,$40
	.byt $40,$40,$40,$40,$40,$40,$40,$40,$03,$43,$7f,$60,$40,$40,$40,$40
	.byt $40,$40,$40,$40,$40,$40,$40,$04,$78,$40,$03,$43,$40,$40,$04,$41
	.byt $78,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40
	.byt $01,$43,$7f,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$04
	.byt $70,$40,$40,$43,$40,$40,$40,$42,$78,$40,$40,$40,$40,$40,$40,$40
	.byt $40,$40,$40,$40,$40,$07,$47,$7c,$03,$43,$7c,$40,$40,$40,$40,$40
	.byt $40,$40,$40,$40,$40,$40,$40,$04,$78,$40,$03,$43,$40,$40,$04,$41
	.byt $70,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$07,$48,$40
	.byt $01,$43,$78,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$04
	.byt $54,$40,$40,$40,$40,$40,$40,$43,$78,$40,$40,$40,$40,$40,$40,$40
	.byt $40,$40,$40,$40,$40,$07,$48,$7e,$03,$41,$70,$40,$40,$40,$40,$40
	.byt $40,$40,$40,$40,$40,$40,$40,$04,$78,$40,$40,$40,$40,$40,$40,$41
	.byt $70,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$03,$48,$6a
	.byt $40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$04
	.byt $5c,$40,$40,$40,$40,$40,$40,$43,$70,$40,$40,$40,$40,$40,$40,$40
	.byt $40,$40,$40,$40,$40,$07,$48,$7a,$40,$40,$40,$40,$40,$40,$40,$40
	.byt $40,$40,$40,$40,$40,$40,$40,$04,$58,$40,$40,$40,$40,$40,$40,$41
	.byt $70,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$03,$48,$42
	.byt $40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$04
	.byt $5c,$40,$40,$40,$40,$40,$40,$43,$70,$40,$40,$40,$40,$40,$40,$40
	.byt $40,$40,$40,$40,$40,$03,$48,$7a,$40,$40,$40,$40,$40,$40,$40,$40
	.byt $40,$40,$40,$40,$40,$40,$40,$04,$58,$40,$40,$40,$40,$40,$40,$41
	.byt $70,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$01,$48,$4a
	.byt $40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$04
	.byt $5c,$40,$40,$40,$40,$40,$40,$43,$70,$01,$55,$7d,$68,$40,$40,$40
	.byt $40,$40,$40,$40,$40,$03,$48,$72,$40,$40,$40,$40,$40,$40,$40,$40
	.byt $40,$40,$40,$40,$40,$40,$40,$04,$5a,$40,$40,$40,$40,$40,$40,$45
	.byt $70,$01,$6b,$6f,$7f,$70,$40,$40,$40,$40,$40,$40,$40,$40,$48,$42
	.byt $40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$01,$6a,$04
	.byt $7e,$40,$40,$40,$40,$40,$40,$4b,$70,$01,$55,$5f,$7f,$7f,$70,$40
	.byt $40,$40,$40,$40,$40,$40,$48,$7a,$40,$40,$40,$40,$40,$40,$40,$40
	.byt $40,$40,$40,$01,$41,$7b,$55,$04,$5a,$40,$40,$40,$40,$40,$40,$57
	.byt $70,$01,$6e,$7f,$7f,$7f,$7f,$40,$40,$40,$40,$40,$40,$05,$48,$6a
	.byt $40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$01,$5f,$7d,$6a,$04
	.byt $75,$40,$40,$40,$40,$40,$40,$6b,$70,$40,$01,$4b,$5f,$7f,$7f,$78
	.byt $40,$40,$40,$40,$40,$40,$4b,$7a,$40,$40,$40,$40,$40,$40,$40,$40
	.byt $40,$40,$01,$43,$7f,$7e,$40,$04,$6a,$40,$40,$40,$40,$40,$41,$55
	.byt $70,$40,$40,$40,$40,$11,$40,$40,$10,$40,$40,$40,$40,$05,$48,$42
	.byt $40,$40,$40,$40,$40,$40,$40,$40,$40,$01,$41,$7f,$7f,$70,$40,$04
	.byt $75,$50,$40,$40,$40,$40,$4a,$6a,$78,$40,$40,$40,$01,$41,$7f,$7f
	.byt $78,$40,$40,$40,$40,$05,$49,$7a,$40,$40,$40,$40,$40,$40,$40,$40
	.byt $40,$01,$4f,$7f,$7c,$40,$40,$04,$6a,$4a,$40,$40,$40,$40,$40,$55
	.byt $50,$40,$40,$40,$40,$01,$43,$7f,$7f,$40,$40,$40,$40,$04,$4a,$4a
	.byt $40,$40,$40,$40,$40,$40,$40,$40,$01,$41,$7f,$7c,$40,$40,$04,$41
	.byt $74,$40,$40,$40,$40,$40,$40,$42,$78,$40,$40,$40,$40,$40,$01,$5f
	.byt $7f,$78,$40,$40,$40,$05,$4a,$4a,$40,$40,$40,$40,$40,$40,$40,$40
	.byt $01,$4f,$7f,$60,$40,$40,$40,$04,$68,$40,$40,$40,$40,$40,$40,$41
	.byt $58,$40,$40,$40,$40,$40,$01,$41,$7f,$7f,$40,$40,$40,$04,$4b,$7a
	.byt $40,$40,$40,$40,$40,$40,$40,$01,$41,$7f,$7e,$40,$40,$40,$04,$41
	.byt $70,$40,$40,$40,$40,$40,$40,$40,$68,$40,$40,$40,$40,$40,$40,$11
	.byt $40,$00,$4f,$7f,$10,$04,$48,$42,$40,$40,$40,$40,$40,$40,$40,$01
	.byt $47,$7f,$7e,$40,$40,$40,$04,$41,$60,$40,$40,$40,$40,$40,$40,$40
	.byt $5c,$40,$40,$40,$40,$01,$57,$7f,$7f,$7f,$7e,$40,$40,$04,$47,$7c
	.byt $40,$40,$40,$40,$40,$40,$40,$40,$11,$40,$00,$47,$7f,$10,$04,$43
	.byt $50,$40,$40,$40,$40,$40,$40,$40,$68,$40,$40,$40,$01,$4b,$7f,$7f
	.byt $63,$7f,$7f,$60,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$01,$47
	.byt $7f,$7b,$7f,$7f,$7f,$40,$04,$41,$60,$40,$40,$40,$40,$40,$40,$40
	.byt $5c,$40,$40,$01,$45,$7f,$7f,$74,$43,$77,$7f,$7c,$40,$40,$40,$40
	.byt $40,$40,$40,$40,$40,$40,$01,$7f,$7f,$67,$6f,$7f,$7d,$6a,$04,$43
	.byt $50,$40,$40,$40,$40,$40,$40,$40,$4c,$40,$01,$42,$7f,$7f,$7e,$40
	.byt $43,$60,$7f,$7f,$60,$40,$40,$40,$40,$40,$40,$40,$40,$01,$43,$7f
	.byt $7c,$43,$60,$5f,$77,$55,$04,$46,$60,$40,$40,$40,$40,$40,$40,$40
	.byt $54,$40,$01,$4f,$7f,$7f,$68,$40,$43,$60,$47,$7f,$78,$40,$40,$40
	.byt $40,$40,$40,$40,$40,$01,$5f,$7f,$70,$43,$70,$40,$4a,$6a,$04,$43
	.byt $40,$40,$40,$40,$40,$40,$40,$40,$4c,$01,$41,$5f,$7f,$7a,$40,$40
	.byt $47,$60,$40,$7f,$7e,$40,$40,$40,$40,$40,$40,$40,$01,$41,$7f,$7e
	.byt $40,$43,$70,$40,$40,$40,$04,$46,$60,$40,$40,$40,$40,$40,$40,$40
	.byt $54,$01,$4a,$6f,$7a,$40,$40,$40,$47,$60,$40,$47,$7f,$60,$40,$40
	.byt $40,$40,$40,$40,$01,$43,$7f,$78,$40,$41,$70,$40,$40,$40,$04,$47
	.byt $40,$40,$40,$40,$40,$40,$40,$40,$4e,$01,$45,$5e,$60,$40,$40,$40
	.byt $4f,$60,$40,$41,$7f,$78,$40,$40,$40,$40,$40,$40,$01,$5f,$7f,$60
	.byt $40,$43,$70,$40,$40,$40,$04,$46,$60,$40,$40,$40,$40,$40,$40,$40
	.byt $44,$01,$42,$68,$40,$40,$40,$40,$47,$40,$40,$40,$5f,$7e,$40,$40
	.byt $40,$40,$40,$01,$41,$7f,$7e,$40,$40,$41,$78,$40,$40,$40,$04,$4d
	.byt $40,$40,$40,$40,$40,$40,$40,$40,$4a,$01,$45,$40,$40,$40,$40,$40
	.byt $4f,$40,$40,$40,$47,$7f,$60,$40,$40,$40,$40,$01,$43,$7f,$70,$40
	.byt $40,$41,$78,$40,$40,$40,$04,$46,$40,$40,$40,$40,$40,$40,$40,$40
	.byt $46,$40,$40,$40,$40,$40,$40,$01,$4f,$60,$40,$40,$41,$7f,$78,$40
	.byt $40,$40,$40,$01,$5f,$7f,$60,$40,$40,$41,$78,$40,$40,$40,$04,$4d
	.byt $40,$40,$40,$40,$40,$40,$40,$40,$4b,$40,$40,$40,$40,$40,$40,$01
	.byt $5f,$40,$40,$40,$40,$7f,$7e,$40,$40,$40,$01,$41,$7f,$7e,$40,$40
	.byt $40,$41,$7c,$40,$40,$40,$04,$5a,$40,$40,$40,$40,$40,$40,$40,$40
	.byt $46,$40,$40,$40,$40,$40,$40,$01,$4e,$60,$40,$40,$40,$4f,$7f,$40
	.byt $40,$40,$01,$47,$7f,$78,$40,$40,$40,$41,$7c,$40,$40,$40,$04,$4c
	.byt $40,$40,$40,$40,$40,$40,$40,$40,$4b,$40,$40,$40,$40,$40,$40,$01
	.byt $5f,$40,$40,$40,$40,$43,$7f,$70,$40,$40,$01,$4f,$7f,$70,$40,$40
	.byt $40,$41,$6c,$40,$40,$40,$04,$5a,$40,$40,$40,$40,$40,$40,$40,$40
	.byt $45,$40,$40,$40,$40,$40,$40,$01,$5a,$40,$40,$40,$40,$41,$7f,$78
	.byt $40,$40,$01,$7b,$6f,$40,$40,$40,$40,$40,$76,$40,$40,$40,$04,$54
	.byt $40,$40,$40,$40,$40,$40,$40,$40,$43,$60,$40,$40,$40,$40,$40,$01
	.byt $57,$40,$40,$40,$40,$40,$7f,$7e,$40,$01,$41,$77,$5c,$40,$40,$40
	.byt $40,$41,$6a,$40,$40,$40,$04,$5a,$40,$40,$40,$40,$40,$40,$40,$40
	.byt $45,$40,$40,$40,$40,$40,$40,$01,$4a,$40,$40,$40,$40,$40,$4f,$7f
	.byt $40,$01,$4a,$7a,$68,$40,$40,$40,$40,$40,$55,$40,$40,$40,$04,$54
	.byt $40,$40,$40,$40,$40,$40,$40,$40,$42,$60,$40,$40,$40,$40,$40,$01
	.byt $55,$40,$40,$40,$40,$40,$47,$7f,$40,$01,$55,$55,$50,$40,$40,$40
	.byt $40,$40,$6a,$40,$40,$40,$04,$7a,$40,$40,$40,$40,$40,$40,$40,$40
	.byt $45,$40,$40,$40,$40,$40,$40,$01,$6a,$40,$40,$40,$40,$40,$43,$7f
	.byt $ff,$00,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
	.byt $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
	.byt $20,$20,$20,$20,$20,$20,$20,$20,$17,$00,$52,$65,$61,$64,$79,$20
	.byt $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
	.byt $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
	.byt $17,$00,$43,$53,$41,$56,$45,$22,$59,$45,$53,$53,$41,$2e,$54,$41
	.byt $50,$22,$2c,$41,$23,$41,$30,$30,$30,$2c,$45,$23,$42,$46,$45,$30
	.byt $20,$20,$20,$20,$20,$20,$20,$20,$17,$00,$a0,$20,$20,$20,$20,$20
	.byt $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
	.byt $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
	.byt $55



EndOfMemory:

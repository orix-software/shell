; Conversion: 4484 cycles
LSB  = RES
NLSB = LSB+1
NMSB = NLSB+1
MSB  = NMSB+1


.macro print str, option
	;
	; Call XWSTR0 function
	;
	; usage:
	;	PRINT #byte [,TELEMON|NOSAVE]
	;	PRINT (pointer) [,TELEMON|NOSAVE]
	;	PRINT address [,TELEMON|NOSAVE]
	;
	; Option:
	;	- TELEMON: when used within TELEMON bank
	;	- NOSAVE : does not preserve A,X,Y registers
	;
	.if (.not .blank({option})) .and (.not .xmatch({option}, NOSAVE)) .and (.not .xmatch({option}, TELEMON) )
		.error .sprintf("Unknown option: '%s' (not in [NOSAVE,TELEMON])", .string(option))
	.endif

	.if (.not .blank({option})) .and .xmatch({option}, NOSAVE)
		.out "Don't save regs values"
	.endif

	.if .blank({option})
		pha
		txa
		pha
		tya
		pha
	.endif

	.if (.not .blank({option})) .and .xmatch({option}, TELEMON)
		pha
		txa
		pha
		tya
		pha

		lda RES
		pha
		lda RES+1
		pha
	.endif


	.if (.match (.left (1, {str}), #))
		; .out "Immediate mode"

		lda # .right (.tcount ({str})-1, {str})
		.byte $00, XWR0

	.elseif (.match(.left(1, {str}), {(}) )
		; Indirect
		.if (.match(.right(1,{str}), {)}))
			; .out"Indirect mode"

			lda .mid (1,.tcount ({str})-2, {str})
			ldy 1+(.mid (1,.tcount ({str})-2, {str}))
			.byte $00, XWSTR0

		.else
			.error "-- PRINT: Need ')'"
		.endif

	.else
		; assume absolute
		; .out "Aboslute mode"

		lda #<str
		ldy #>str
		.byte $00, XWSTR0
	.endif

	.if .blank({option})
		pla
		tay
		pla
		txa
		pla
	.endif

	.if (.not .blank({option})) .and .xmatch({option}, TELEMON)
		pla
		sta RES+1
		pla
		sta RES

		pla
		tay
		pla
		txa
		pla
	.endif

.endmacro


; .org 1000
.proc _df
	jsr _ch376_verify_SetUsbPort_Mount
	bcc @ZZ0001

		print str_df_columns
		jsr   _ch376_disk_capacity

		lda TR0
		sta RES
		lda TR1
		sta RES+1
		lda TR2
		sta RESB
		lda TR3
		sta RESB+1
		jsr convd

		MALLOC 11
		; FIXME test OOM
		TEST_OOM_AND_MAX_MALLOC

		sta RESB
		sty RESB+1

		jsr bcd2str
		print (RESB)
		FREE RESB

	@ZZ0001:
	BRK_ORIX XCRLF
	rts



    convd:
        ldx #$04          ; Clear BCD accumulator
        lda #$00

    BRM:
        sta TR0,x        ; Zeros into BCD accumulator
        dex
        bpl BRM

        sed               ; Decimal mode for add.

        ldy #$20          ; Y has number of bits to be converted

    BRN:
        asl LSB           ; Rotate binary number into carry
        rol NLSB
        rol NMSB
        rol MSB

;-------
; Pour MSB en premier dans BCDA
;    ldx #$05
;
;BRO:
;    lda BCDA-1,X
;    adc BCDA-1,X
;    sta BCDA-1,x
;    dex
;    bne BRO

; Pour LSB en premier dans BCDA

BCDA = (TR0-$FB) & $ff ; = $0C

        ldx #$fb          ; X will control a five byte addition.

    BRO:
        lda BCDA,x    ; Get least-signficant byte of the BCD accumulator
        adc BCDA,x    ; Add it to itself, then store.
        sta BCDA,x
        inx               ; Repeat until five byte have been added
        bne BRO

        dey               ; et another bit rom the binary number.
        bne BRN

        cld               ; Back to binary mode.
        rts               ; And back to the program.

bcd2str:
	sta RES
	sty RES+1

	ldx #$04          ; Nombre d'octets à convertir
	ldy #$00
;	clc

loop:
	; BCDA: LSB en premier
	lda TR0,X
	pha
	; and #$f0
	lsr
	lsr
	lsr
	lsr
        clc
	adc #'0'
	sta (RES),Y

	pla
	and #$0f
	adc #'0'
	iny
	sta (RES),y

	iny
	dex
	bpl loop

	lda #$00
	sta (RES),y
	rts


str_df_columns:
    .byte "512-blocks Used Avail. Use% Mounted on",$0d,$0A,0

str_free:
	.res 11

str_sda1:
    .asciiz "/dev/sda1"

.endproc

; ------------------
; Temporaire, pour tests
;RES = *

;LSB = RES

;	.byte  $d2, $02, $96, $00

; Temporaire, pour tests
;TR0 = *

;BCDA = TR0
;	.res 5

;str:
;	.res 11


; vim: set ft=asm6502-2 ts=8:

; Conversion: 4484 cycles
;LSB  = RES
;NLSB = LSB+1
;NMSB = NLSB+1
;MSB  = NMSB+1

;----------------------------------------------------------------------
;				Defines
;----------------------------------------------------------------------
;.ifdef WITH_SDCARD_FOR_ROOT
;		        "512-blocks Used Avail. Use% Mounted on"
	.define df_msg  "xxxxxxxxxx xxxxxxxxxx  xxx   /dev/"
;.else
;		        "512-blocks Used Avail. Use% Mounted on"
;	.define df_msg  "xxxxxxxxxx xxxxxxxxxx  xxx   /dev/"
;.endif

;----------------------------------------------------------------------
;				Macros
;----------------------------------------------------------------------

;----------------------------------------------------------------------
;				Command
;----------------------------------------------------------------------
.proc _df


	; Force le montage du périphérique, sinon un changement avec la
	; commande twil directement suivie par df indique les valeurs du
	; périphériques précédent (il faut exécuter une commande qui utilise
	; le périphérique avant de faire df)

    BRK_KERNEL XGETCWD ; Return A and Y the string


    sty     TR6
    ldy     #O_RDONLY
    ldx     TR6
    BRK_KERNEL XOPEN
    cmp     #$FF
    bne     @free

    cpx     #$FF
    bne     @free
    rts
@free:


	malloc .strlen(df_msg)+1, userzp


df_suite:
	strcpy AY, str_df_values


	print df_header, SAVE
	jsr     _ch376_disk_query

	; Sauvegarde l'espace dispo pour plus tard
	; (XWSTR0 utilise TRx)
	;Conversion en blocs de 1k de l'espace libre
	lsr     TR7
	ror     TR6
	ror     TR5
	ror     TR4

	; Sauvegarde l'espace dispo pour plus tard
	; (XWSTR0 utilise TRx)
	lda     TR4
	sta     userzp+2
	lda     TR5
	sta     userzp+3
	lda     TR6
	sta     userzp+4
	lda     TR7
	sta     userzp+5

	; Conversion en blocs de 1k de l'espace total
	lsr     TR3
	ror     TR2
	ror     TR1
	ror     TR0

	lda     TR0
	sta     RES
	lda     TR1
	sta     RES+1
	lda     TR2
	sta     RESB
	lda     TR3
	sta     RESB+1

	jsr     convd

	lda     userzp

	ldy     userzp+1

	jsr     bcd2str
	; Remplace le caractère nul par un ' '
	lda #' '
	sta (RES),y

	jsr display_size

	lda userzp+2
	sta RES
	lda userzp+3
	sta RES+1
	lda userzp+4
	sta RESB
	lda userzp+5
	sta RESB+1
	jsr convd

	clc
	lda userzp
	adc #$0b
	ldy userzp+1
	bcc *+3
	iny
	jsr bcd2str
	; Remplace le caractère nul par un ' '
	lda #' '
	sta (RES),y

	jsr display_size

	print (userzp), SAVE


	mfree (userzp)

	; Récupère le périphérique de root
	ldx #XVARS_KERNEL_CH376_MOUNT
	BRK_KERNEL XVARS
	sta userzp
	sty userzp+1
	ldy #$00
	lda (userzp),y

	tax
	lda #<str_sda1
	ldy #>str_sda1
	; SDCARD?
	cpx #$03
	beq print_device
	lda #<str_usb1
	ldy #>str_usb1
print_device:
	BRK_KERNEL XWSTR0


df_end:
	crlf
	rts


;----------------------------------------------------------------------
;		Suppression des '0' non significatifs
;----------------------------------------------------------------------

display_size:
    ; Remplace les '0' non significatifs par des ' '
    ldy #$ff
    ldx #' '
  @skip:
    iny
    cpy #$09
    beq @display
    lda (RES),y
    cmp #'0'
    bne @display
    txa
    sta (RES),y
    bne @skip

  @display:


     ; La chaine fait 10 caractères
     ; Taille maximale: < 999 999
     ; donc on saute les 4 premiers caractères
.if 0
    clc
    lda #$04
    adc RES
    sta RES
    bcc *+4
    inc RES+1


.endif


    rts


;----------------------------------------------------------------------
;				DATA
;----------------------------------------------------------------------
df_header:
    .byte   "512-blocks Used Avail. Use% Mounted on",$0d,$0A,0

str_df_values:
    .asciiz df_msg

str_sda1:
    .asciiz "sda1"

str_usb1:
    .asciiz "usb1"

.endproc



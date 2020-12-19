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
;	jsr _ch376_verify_SetUsbPort_Mount
;	;bcc @ZZ0001
;	bcs *+5
;	jmp df_end

	; Force le montage du périphérique, sinon un changement avec la
	; commande twil directement suivie par df indique les valeurs du
	; périphériques précédent (il faut exécuter une commande qui utilise
	; le périphérique avant de faire df)
	jsr _cd_to_current_realpath_new

	;lda #<( .strlen(df_msg))
	;ldy #>(.strlen(df_msg))
	;.byte $00, XMALLOC
	malloc .strlen(df_msg)+1, userzp
	; FIXME test OOM
	;TEST_OOM_AND_MAX_MALLOC
	;sta userzp
	;sty userzp+1

	;ora userzp+1
	;bne df_suite
	;jmp df_end

df_suite:
	strcpy AY, str_df_values
;	sta RESB
;	sty RESB+1
;	lda #<str_sda1
;	ldy #>str_sda1
;	sta RES
;	sty RES+1
;	jsr _strcpy

	print df_header
	jsr   _ch376_disk_query

	; Sauvegarde l'espace dispo pour plus tard
	; (XWSTR0 utilise TRx)
	;Conversion en blocs de 1k de l'espace libre
	lsr TR7
	ror TR6
	ror TR5
	ror TR4

	; Sauvegarde l'espace dispo pour plus tard
	; (XWSTR0 utilise TRx)
	lda TR4
	sta userzp+2
	lda TR5
	sta userzp+3
	lda TR6
	sta userzp+4
	lda TR7
	sta userzp+5

	; Conversion en blocs de 1k de l'espace total
	lsr TR3
	ror TR2
	ror TR1
	ror TR0

	lda TR0
	sta RES
	lda TR1
	sta RES+1
	lda TR2
	sta RESB
	lda TR3
	sta RESB+1

	jsr convd

;	clc
	lda userzp
;	adc #$04
	ldy userzp+1
;	bcc *+3
;	iny
	jsr bcd2str
	; Remplace le caractère nul par un ' '
	lda #' '
	sta (RES),y

	jsr display_size
	;print (RES)

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

	print (userzp)

	;lda userzp
	;ldy userzp+1
	;.byte $00, XFREE
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

	; SDCARD?
;	cmp #$03
;	bne usb
;	lda #<str_sda1
;	ldy #>str_sda1
;	bne xxx
;	lda #<str_usb1
;	ldy #>str_usb1
;print_device:
;	BRK_KERNEL XWSTR0



	;ZZ0001:
df_end:
	BRK_ORIX XCRLF
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
    ; On saute les espaces du début
;    clc
;    tya
;    adc RES
;    sta RES
;    bcc *+4
;    inc RES+1

; Résultat dans AY
;    clc
;    tya
;    adc RES
;    ldy RES+1
;    bcc *+3
;    iny

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

; Résultat dans AY
;    clc
;    lda #$04
;    adc RES
;    ldy RES+1
;    bcc *+3
;    iny
.endif
    ; print (RES),NOSAVE

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



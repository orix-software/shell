NUMBER_OF_COLUMNS_LS = 3

.proc _ls
    lda #NUMBER_OF_COLUMNS_LS+1
    sta NUMBER_OF_COLUMNS

    jsr _ch376_verify_SetUsbPort_Mount
    bcc @ZZ0001
    ;bcs *+5
    ;jmp @ZZ0001
        jsr _cd_to_current_realpath_new
        ldx #$01
        jsr _orix_get_opt

        ; Potentiel buffer overflow ici
        ; Il faudrait un STRNCPY
        STRCPY ORIX_ARGV, BUFNOM

        ;MALLOC 13
        ; FIXME test OOM
        ;TEST_OOM_AND_MAX_MALLOC
        ;sta RESB
        ;sty RESB+1

        lda #<BUFEDT
        sta RESB
        lda #>BUFEDT
        sta RESB+1

        ; Potentiel buffer overflow ici
        ; Il faudrait un STRNCPY
        lda #<BUFNOM
        sta RES
        lda #>BUFNOM
        sta RES+1
        jsr _strcpy

        ; RESB pointe toujours sur BUFNOM
        jsr WildCard
        bne Error               ; Il faut une autre erreur, il c'est parce qu'il y a des caractères incorrects
        ;bcc @ZZ0002             ; Pas de '?' ni de '*'
        bcs @all

        lda BUFNOM
        bne @ZZ0002
            @all:
            lda #'*'
            sta BUFNOM
            lda #$00
            sta BUFNOM+1

        @ZZ0002:
        jsr _ch376_set_file_name
        jsr _ch376_file_open
        ; Au retour, on peut avoir USB_INT_SUCCESS ou USB_INT_DISK_READ)

        ; $14 -> Fichier existant (USB_INT_SUCCESS) (cas 'ls fichie.ext')
        ; $1D -> Lecture OK (USB_INT_DISk_READ
        ; $41 -> Fin de liste (ERR_OPEN_DIR) ou ouverture répertoire (cas 'ls repertoire')
        ; $42 -> fichier inexistant (ERR_MISS_FILE)

        cmp #CH376_ERR_MISS_FILE
        beq Error

        ; Ajuste le pointeur vers BUFNOM pour plus tard
        ; (le 1er caractère contient la couleur)
        inc RES
        bne *+4
        inc RES+1

        @ZZ1001:
        cmp #CH376_USB_INT_SUCCESS
        bne @ZZ1002
            lda #COLOR_FOR_FILES
            bne display_one_file_catalog

        @ZZ1002:
        cmp #CH376_ERR_OPEN_DIR
        bne @ZZ0003
            lda #COLOR_FOR_DIRECTORY
            bne display_one_file_catalog

        @ZZ0003:
            cmp #CH376_USB_INT_DISK_READ
            bne @ZZ0004
                lda #CH376_RD_USB_DATA0
                sta CH376_COMMAND
                lda CH376_DATA
                cmp #32
                beq @ZZ0005
                    ;FREE RESB
                    rts

                @ZZ0005:
                jsr display_catalog

        ; display_one_file_catalog renvoie la valeur de _ch376_wait_response qui renvoie 1 en cas d'erreur
        ; et le CH376 ne renvoie pas de valeur 0
        ; donc le bne devient un saut inconditionnel!
        ; jmp @ZZ0003
        bne @ZZ0003

        @ZZ0004:
        ;FREE RESB
        BRK_ORIX XCRLF

    @ZZ0001:
    rts

; ------------------------------------------------------------------------------
Error:
    PRINT txt_file_not_found
    ; ldx #$01
    ; jsr _orix_get_opt
    .BYTE $2C

display_one_file_catalog:
    .BYTE $00, XWR0

    ;FREE RESB

    PRINT BUFNOM
    BRK_ORIX XCRLF
rts

; ------------------------------------------------------------------------------

display_catalog:
    lda #COLOR_FOR_FILES
    sta BUFNOM
    ldy #$01
    ldx #$01

    @ZZ0007:
.if 0
        lda CH376_DATA
        cmp #' '
        beq @ZZ0008
            jsr _lowercase_char
            sta BUFNOM,y
            iny

        @ZZ0008:

        inx
        cpx #9
        bne @ZZ0009
            lda #'.'
            sta BUFNOM,Y
            sty TR5
            iny
        @ZZ0009:

        cpx #10
        bne @ZZ0010
            cmp #' '
            bne @ZZ0011
                lda TR5
                sty TR5
                tay
                lda #' '
                sta BUFNOM,Y
                ldy TR5
            @ZZ0011:
        @ZZ0010:
.else
        lda CH376_DATA
        sta BUFNOM,y
        iny
        inx
.endif
        cpx #12
    bne @ZZ0007

    lda CH376_DATA
    cmp #$10
    bne @ZZ0012
        lda #COLOR_FOR_DIRECTORY
        sta BUFNOM
        ;dey     ; BUG!?

    @ZZ0012:
    lda #$00
    sta BUFNOM,Y
    ;sty TEMP_ORIX_1

    ldx #20

    @ZZ0013:
        lda CH376_DATA
        dex
    bpl @ZZ0013

    jsr Match
    bne @ZZ0014

    ; Devrait être BUFNOM+1 et BUFNOM+2
    lda BUFNOM
    cmp #'.'
    beq @ZZ0014
        lda BUFNOM+1
        cmp #'.'
        beq @ZZ0015
            dec NUMBER_OF_COLUMNS
            bne @ZZ0016
                BRK_ORIX XCRLF
                lda #NUMBER_OF_COLUMNS_LS
                sta NUMBER_OF_COLUMNS
            @ZZ0016:

            PRINT BUFNOM

            ;ldy TEMP_ORIX_1

            @ZZ0017:
                cpy #13
                beq @ZZ0018
                    iny
                    CPUTC ' '
            jmp @ZZ0017

            @ZZ0018:
        @ZZ0015:
    @ZZ0014:

    lda #CH376_FILE_ENUM_GO
    sta CH376_COMMAND
    jsr _ch376_wait_response
rts

optstring:
.BYT 'l',0

.endproc

; ==============================================================================
;
; Entrée:
;	RES: Pointeur vers la chaîne
;	RESB: Pointeur vers la chaîne résultat
;
; Sortie:
;	Z = 1 -> OK , C=1 -> '?' ou '*' utilisés dans le masque, (C=0 & Y=$FF -> pas de '?' ni de '*')
;	Z = 0 -> Nok, ACC=Erreur, Y=Offset dans RES, X=Offset dans RESB
;
; Prepare le buffer: "????????.??"
;
.proc WildCard
	lda #'?'
	ldy #$0B-1

@loop:
	sta (RESB),y
	dey
	bpl @loop

; Pas de '.' renvoyé par le CH376
;	lda #'.'
;	ldy #$08
;	sta (RESB),y

	lda #$00
	ldy #$0C-1
	sta (RESB),y

	ldx #$00
	ldy #$00

Suivant:
	lda (RES),y
	beq ExtensionFill

	cmp #'.'
	beq Extension

;	cpx #$07
	cpx #$08
	beq Erreur3

	cmp #'?'
	beq Question

	cmp #'*'
	beq Star

	cmp #'0'
	bcc Erreur
	cmp #'9'+1
	bcc Ok

; Pour forcer le masque en majuscules
	cmp #'A'
	bcc Erreur
	cmp #'Z'+1
	bcc Ok

	cmp #'a'
	bcc Erreur
	cmp #'z'+1
	bcs Erreur
	and #$DF
	bne Ok

; Pour forcer le masque en minuscules
;        cmp #'z'+1
;        bcs Erreur
;        cmp #'a'
;        bcs Ok
;
;	cmp #'A'
;	bcc Erreur
;	cmp #'Z'+1
;	bcs Erreur
;	ora #$20
;	bne Ok
.if 0
Erreur4:
	; Extension trop longue
	lda #$04
	.byte $2c

Erreur3:
	;Nom trop long
	lda #$03
	.byte $2c

Erreur2:
	; Chaine RES trop longue
	lda #$02
	.byte $2c

Erreur:
	; Caractère incorrect
	lda #$01

	; ldy #$00

	;sec
	rts
.endif
;Fin:

; Ajoute le caractère au tampon
Ok:
	sta TR0
	sty TR1
	txa
	tay
	lda TR0
	sta (RESB),y
	ldy TR1

; Incrémente les index
; Ajouter test X=09 -> erreur3?
Question:
	inx
	iny
	bne Suivant
	beq Erreur2

ExtensionFill:
	;Cas de la chaîne vide
	cpx #$00
	beq ExtensionFin

	; Complète l'extension avec des ' '
	txa
	tay
	lda #' '
@loop:
	cpy #$0c-1
	beq ExtensionFin
	sta (RESB),y
	iny
	bne @loop

ExtensionFin:
	; Place le '.' de séparation
	;lda #'.'
	;ldy #$08
	;sta (RESB),y

	;Cherche si on a utilisé des wildcards
	ldy #$0B-1
	lda #'?'
@loop:
	cmp (RESB),Y
	beq @fin
	dey
	bpl @loop
	; On peut supprimer le clc
	; dans ce cas, il faudra tester Y=$FF ou Y+1=0 pour savoir
	; si il y a des caractères '?'
	clc

@fin:
	lda #$00
	;tay

	rts

Erreur4:
	; Extension trop longue
	lda #$04
	.byte $2c

Erreur3:
	;Nom trop long
	lda #$03
	.byte $2c

Erreur2:
	; Chaine RES trop longue
	lda #$02
	.byte $2c

Erreur:
	; Caractère incorrect
	lda #$01

	; ldy #$00

	;sec
	rts

Star:
	ldx #$0c-1
@loop:
	iny
	beq Erreur2
	lda (RES),y
	beq ExtensionFill
	cmp #'.'
	bne @loop
	ldx #$08-1

Extension:
	cpx #$08
	beq ExtensionQuestion

	sty TR1
	txa
	tay
	lda #' '
@loop:
	sta (RESB),y
	iny
	cpy #$08
	bne @loop

	ldy TR1
	ldx #$08-1

ExtensionQuestion:
	inx
	iny
	beq Erreur2

	lda (RES),y
	beq ExtensionFill

	cpx #$0C-1
	beq Erreur4

	cmp #'?'
	beq ExtensionQuestion

	cmp #'*'
	beq ExtensionFin

	cmp #'0'
	bcc Erreur
	cmp #'9'+1
	bcc ExtensionOk

; Pour forcer le masque en majuscules
	cmp #'A'
	bcc Erreur
	cmp #'Z'+1
	bcc ExtensionOk

	cmp #'a'
	bcc Erreur
	cmp #'z'+1
	bcs Erreur
	and #$DF
	;bne Ok

ExtensionOk:
	sta TR0
	sty TR1
	txa
	tay
	lda TR0
	sta (RESB),y
	ldy TR1
	bne ExtensionQuestion

.endproc

;
; Entrée:
;	RES : Chaine
;	RESB: Masque
;
; Sortie:
;	Z = 1 -> Ok
;	Y: Offset du dernier caractère testé
;	A: Dernier caractère testé (0 si fin du masque atteinte)
;
; Note: ne vérifie pas si la longueur de la chaîne est > à celle du masque
;
.proc Match
	ldy #$ff

@loop:
	iny

	; Fin du masque?
	lda (RESB),y
	beq @fin

	; Caractères identiques?
	cmp (RES),y
	beq @loop

	; Note: ls z?? affiche un fichier 'zx' si il existe
	cmp #'?'
	beq @loop

	; Si on veut vérifier que la chaîne fait la même longueur que le masque
	; (pas valable ici, les noms de fichiers sont complétés avec des ' ')
	; rts

@fin:
	; Si on veut vérifier que la chaîne fait la même longueur que le masque
	; (pas valable ici, les noms de fichiers sont complétés avec des ' ')
	; lda (RES),y

	rts
.endproc


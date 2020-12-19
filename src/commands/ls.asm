; vim: set ft=asm6502-2 ts=8:

; Taille: $d3c6 -> $d7e0 := 1051 octets avec malloc
;         $d3c6 -> $d7b7 := 1010 sans malloc
CH376_DIR_INFO_READ = $37

ls_column_max            := userzp
ls_column                := userzp+1
ls_save_line_command_ptr := userzp+2 ; 2 bytes
ls_file_found            := userzp+4
ls_argc                  := userzp+5

; L'utilisation de malloc permet de mettre plusieurs noms de fichier en paramètre
;ls_use_malloc = 1

.struct ls_command_struct
.endstruct

.proc _ls
    lda #3
    sta ls_column_max

    jsr _ch376_verify_SetUsbPort_Mount
    ;bcc @ZZ0001
    bcs *+5
    jmp ZZ0001

    jsr _cd_to_current_realpath_new
    ; Prends le premier paramètre, retour avec C=0 si pas de paramètre, C=1 sinon
    ; ORIX_ARGV[0] = 0 si pas de paramètre
    ldx #$01
    stx ls_argc
    jsr _orix_get_opt
    bcc list

    ; Paramètre: -l ?
    lda ORIX_ARGV
    cmp #'-'
    bne list
    lda ORIX_ARGV+1
    cmp #'l'
    bne list
    lda ORIX_ARGV+2
    bne list
    ; format long
    lda #$ff
    sta ls_column_max

    ldx #$02
    stx ls_argc
    jsr _orix_get_opt

list:
    ; Potentiel buffer overflow ici
    ; Il faudrait un STRNCPY
    ; Utilisation de la macro strcpy pour remplacer le code suivant
    ; STRCPY ORIX_ARGV, BUFNOM
    ; /!\ ATTENTION les paramètrtes sont inversés par rapport à STRCPY
    strcpy BUFNOM, ORIX_ARGV

.ifdef ls_use_malloc
    malloc 13
    sta RESB
    sty RESB+1
    ora RESB
    bne copy_mask
    jmp error_oom
    ;MALLOC 13
    ; FIXME test OOM
    ;TEST_OOM_AND_MAX_MALLOC
    ;sta RESB
    ;sty RESB+1
.else
    lda bash_struct_command_line_ptr
    sta RESB
    lda bash_struct_command_line_ptr+1
    sta RESB+1
.endif

copy_mask:
    ; Copie BUFNOM -> (RESB)
    ; Potentiel buffer overflow ici
    ; Il faudrait un STRNCPY
    lda #<BUFNOM
    ldy #>BUFNOM
    sta ls_save_line_command_ptr         ; ls_save_line_command_ptr: Cf Match
    sty ls_save_line_command_ptr+1
    ; Utilisation de la macro strcpy pour remplacer le code suivant
    ; sta RES
    ; sty RES+1
    ; jsr _strcpy
    ; la destination, RESB, est déjà renseignée et AY contient l'adresse de la source
    strcpy , AY

    ; RESB pointe toujours sur BUFEDT
    jsr WildCard
.ifndef ls_use_malloc
    bne Error       ; Il faut une autre erreur, ici c'est parce qu'il y a des caractères incorrects
    ;bcc @ZZ0002     ; Pas de '?' ni de '*'
.else
    beq *+5
    jmp Error
.endif
    bcs all

    lda BUFNOM
    bne ZZ0002

  all:
    lda #'*'
    sta BUFNOM
    lda #$00
    sta BUFNOM+1

  ZZ0002:
    jsr _ch376_set_file_name
    jsr _ch376_file_open
    ; Au retour, on peut avoir USB_INT_SUCCESS ou USB_INT_DISK_READ)

    ; $14 -> Fichier existant (USB_INT_SUCCESS) (cas 'ls fichie.ext')
    ; $1D -> Lecture OK (USB_INT_DISK_READ)
    ; $41 -> Fin de liste (ERR_OPEN_DIR) ou ouverture répertoire (cas 'ls repertoire')
    ; $42 -> fichier inexistant (ERR_MISS_FILE)

    cmp #CH376_ERR_MISS_FILE
    beq Error

    ; Indique pas de fichier trouvé pour le moment
    ldx #$00
    stx ls_file_found

    ; Mets à jour le nombre de colonnes
    ldx ls_column_max
    inx
    stx ls_column

    ; Ajuste le pointeur vers BUFNOM pour plus tard
    ; (le 1er caractère contient la couleur)
    inc ls_save_line_command_ptr
    bne *+4
    inc ls_save_line_command_ptr+1

  ZZ1001:
    cmp #CH376_USB_INT_SUCCESS
    bne ZZ1002
    lda #COLOR_FOR_FILES
    bne display_one_file_catalog

  ZZ1002:
    cmp #CH376_ERR_OPEN_DIR
    bne ZZ0003
    lda #COLOR_FOR_DIRECTORY
    bne display_one_file_catalog

  ZZ0003:
    cmp #CH376_USB_INT_DISK_READ
    bne ZZ0004
    beq go

display_one_file_catalog:
    lda #CH376_DIR_INFO_READ
    sta CH376_COMMAND
    lda #$ff
    sta CH376_DATA
    jsr _ch376_wait_response
    cmp #CH376_USB_INT_SUCCESS
    bne Error

go:
    lda #CH376_RD_USB_DATA0
    sta CH376_COMMAND
    lda CH376_DATA
    cmp #$20
    beq ZZ0005

.ifdef ls_use_malloc
    ;FREE RESB
    mfree (RESB)
.endif
    rts

  ZZ0005:
    jsr display_catalog

    ; display_one_file_catalog renvoie la valeur de _ch376_wait_response qui renvoie 1 en cas d'erreur
    ; et le CH376 ne renvoie pas de valeur 0
    ; donc le bne devient un saut inconditionnel!
    ; jmp @ZZ0003
    bne ZZ0003

  ZZ0004:
    ;FREE RESB

    BRK_KERNEL XCRLF

    ; Erreur si aucun fichier trouvé
    lda ls_file_found
    beq Error

.ifdef ls_use_malloc
    ;FREE RESB
    mfree (RESB)

    ldx ls_argc
    inx
    stx ls_argc
    jsr _orix_get_opt
    bcc ZZ0001
    jmp list
.endif

  ZZ0001:
    rts

; ------------------------------------------------------------------------------
Error:
    print txt_file_not_found, NOSAVE
;    .BYTE $2C

;display_one_file_catalog:
;    .BYTE $00, XWR0

    ;FREE RESB

    ;print BUFNOM, NOSAVE
    print ORIX_ARGV, NOSAVE

error_oom:
    BRK_KERNEL XCRLF

.ifdef ls_use_malloc
    ;FREE RESB
    mfree (RESB)
.endif
    rts

; ------------------------------------------------------------------------------
; Entrée du catalogue:
;   Offset              Description
;   00-07               Filename
;   08-0A               Extension
;   0B                  File attributes
;                           0x01: Read only
;                           0x02: Hidden
;                           0x04: System
;                           0x08: Volume label
;                           0x10: Subdirectory
;                           0x20: Archive
;                           0x40: Device (internal use only)
;                           0x80: Unused
;   0C                  Reserved
;   0D                  Create time: fine resolution (10ms) 0 -> 199
;   0E-0F               Create time: Hour, minute, second
;                            bits
;                           15-11: Hour  (0-23)
;                           10- 5: Minutes (0-59)
;                            4- 0: Seconds/2 (0-29)
;   10-11               Create time:Year, month, day
;                            bits
;                           15- 9: Year (0->1980, 127->2107)
;                            8- 5: Month (1->Jan, 12->Dec)
;                            4- 0: Day (1-31)
;   12-13               Last access date
;   14-15               EA index
;   16-17               Last modified time
;   18-19               Last modified date
;   1A-1B               First cluster
;   1C-1F               File size
;
; Sortie:
; TR0: Modifié
; ls_file_found: $ff si on a trouvé un fichier correspondant au masque
; ------------------------------------------------------------------------------
display_catalog:
    lda #COLOR_FOR_FILES
    sta BUFNOM
    ldy #$01

  ZZ0007:
    lda CH376_DATA
    sta BUFNOM,y
    iny
    cpy #12
    bne ZZ0007

    lda CH376_DATA
    sta TR0         ; Sauvegarde l'attribut pour plus tard
;    cmp #$10
;    bne @ZZ0012

    and #$10
    beq ZZ0012

    lda #COLOR_FOR_DIRECTORY
;    clc
;    adc #$40
    sta BUFNOM

  ZZ0012:
    lda #$00
    sta BUFNOM,Y
    ;sty TEMP_ORIX_1

    ldx #$14

  ZZ0013:
    lda CH376_DATA
    sta BUFEDT+1,y
    iny
    dex
    bpl ZZ0013

    jsr Match
    bne ZZ0014

    lda BUFNOM
    cmp #'.'
    beq ZZ0014

    lda BUFNOM+1
    cmp #'.'
    beq ZZ0015

    ; Indique qu'on a trouvé un fichier
    lda #$ff
    sta ls_file_found

    ; Mode verbose?
    lda ls_column_max
    bmi _verbose

    ; Mode normal, on décrémente le nombre de colonnes restantes pour l'affichage
    dec ls_column
    bne ZZ0016

    ; Attention XCRLF modifie RES
    ; [HCL]
    ; Pas de saut de ligne, on est déjà au dernier caractère
    ; (UNIQUEMENT POUR LA VERSION LONGUE AVEC AFFICHAGE DE L'ATTRIBUT)
    BRK_KERNEL XCRLF

    lda ls_column_max
    sta ls_column
    bne ZZ0016

_verbose:
    ; Affiche l'attribut
    lda TR0
    ; jsr PrintHexByte
    jsr PrintFileAttr

  ZZ0016:

    ; PRINT BUFNOM
;    ldy #$ff
    ldy #$00
    ldx #$00

    ; Affiche directement la couleur
    ; Ne doit pas être 0
    lda BUFNOM,y
    bne  skip

  loop:
    iny
    lda BUFNOM,y
    beq end

    cmp #' '
    beq loop

    cpy #$09
    bne suite

    pha
;    CPUTC '.'
    print #'.', NOSAVE
    pla
    inx

  suite:
    ; jsr _lowercase_char
    cmp     #'A'
    bcc     skip
    cmp     #'Z'+1
    bcs     skip
    adc     #'a'-'A'

  skip:
    BRK_KERNEL XWR0
    inx
    bne loop
  end:

    ;ldy TEMP_ORIX_1

  ZZ0017:
    cpx #13
    beq ZZ0018

    inx
;    CPUTC ' '
    print #' ', NOSAVE
    jmp ZZ0017

  ZZ0018:
    lda ls_column_max
    bpl ZZ0014

    jsr ls_display_date_size

  ZZ0015:
  ZZ0014:
    asl KBDCTC
    bcs  display_catalog_end

    lda #CH376_FILE_ENUM_GO
    sta CH376_COMMAND
    jsr _ch376_wait_response

 display_catalog_end:
    rts

.endproc


; $D57a -> $D64c: 211 octets
; ------------------------------------------------------------------------------
;
; Entrée:
;    RES: Pointeur vers la chaîne
;    RESB: Pointeur vers la chaîne résultat
;
; Sortie:
;    Z = 1 -> OK , C=1 -> '?' ou '*' utilisés dans le masque, (C=0 & Y=$FF -> pas de '?' ni de '*')
;    Z = 0 -> Nok, ACC=Erreur, Y=Offset dans RES, X=Offset dans RESB
;
; Utilise:
;    TR0, TR1
;
; Prepare le buffer: "***********"
;
; ------------------------------------------------------------------------------
.proc WildCard

    ; Initialise le buffer: '***********'
    lda #'*'
    ldy #11-1

loop:
    sta (RESB),y
    dey
    bpl loop

; Pas de '.' renvoyé par le CH376
;    lda #'.'
;    ldy #$08
;    sta (RESB),y

    ; ajoute un NULL à la fin du buffer
    lda #$00
    ldy #12-1
    sta (RESB),y

    ; X: Pointeur dans le buffer résultat
    ; Y: Pointeur dans le buffer source
    ldx #$00
    ldy #$00

    ; Si masque vide <-> *.*
    lda (RES),y
    beq extension_star

fill_name:
    lda (RES),y
    beq end_mask
;    cmp #'?'
;    beq name_next
    cmp #'*'
    beq name_star
    cmp #'.'
    beq extension

    ; Nombre de caractères maximal pour le nom >=8?
    cpx #08
    beq error_too_many_characters_name

    ; Ajoute le caractère au masque si il est valide
    jsr add_char
    bcs error_invalid

name_next:
    inx
    iny
    bne fill_name
    ; Ne doit pas arriver, mais au cas où...
    beq error_too_many_characters

    ; On a vu une '*', on cherche le '.'
name_star:
    ; Place le pointeur de RESB au niveau début de l'extension
    ldx #08
@loop:
    iny
    ; Ne doit pas arriver, mais au cas où...
    beq error_too_many_characters
    lda (RES),y
    beq end_mask
    cmp #'.'
    beq extension
    bne @loop

    ; On a vu un '.'
extension:
    iny
    cpx #08
    beq fill_extension
    ; Sauvegarde Y et complète le nom avec des ' '
    sty TR0
    txa
    tay
    lda #' '
@loop:
    sta (RESB),y
    iny
    cpy #$08
    bne @loop
    ; Restaure X et Y
    tya
    tax
    ldy TR0

fill_extension:
    lda (RES),y
    beq end_mask
;    cmp #'?'
;    beq extension_next
    cmp #'*'
    beq extension_star
    cmp #'.'
    beq error_invalid

    ; Nombre de caractères maximal pour le nom+extension >=12?
    cpx #12
    beq error_too_many_characters_ext

    ; Ajoute le caractère au masque si il est valide
    jsr add_char
    bcs error_invalid

extension_next:
    inx
    iny
    bne fill_extension
    ; Ne doit pas arriver, mais au cas où...
    beq error_too_many_characters

    ; Complète le masque avec des ' '
end_mask:
    cpx #12-1
    bcs extension_star
    txa
    tay
    lda #' '
@loop:
    sta (RESB),y
    iny
    cpy #12-1
    bne @loop

    ; On arrive ici si l'extension se termine par '*' ou via end_mask
extension_star:
    ; Vérifie si on a utiliser un caractère joker
;    lda #'?'
    ldy #11-1
check:
    lda (RESB),y
    cmp #'?'
    beq wild_found
    cmp #'*'
    beq wild_found
    dey
    bpl check
    ; N=1, Z=0, C=1, Y=$FF
    iny
    ; Laisser C=1 si on veut quand même faire un ls * avec vérification du modèle
    ; sinon, mettre C=0 pour n'ouvrir que le fichier demandé, dans ce cas ls
    ; utilisera READ_DIR_INFO pour lire les informations de ce fichier (non
    ; supporté par Oricutron au 15-12-2020)
    clc
    ; N=0, Z=1, C=0, Y=$00
    rts

wild_found:
    ; N=0, Z=1, C=1
    rts

    ; Erreur: Z=0, A=erreur
error_invalid:
    lda #$01
    rts
error_too_many_characters:
    lda #$02
    rts
error_too_many_characters_name:
    lda #$03
    rts
error_too_many_characters_ext:
    lda #$04
    rts

.endproc


;----------------------------------------------------------------------
;
; Entrée:
;	A: caractère à vérifier
;   X: Pointeur dans le tampon de sortie
;   RESB: adresse du tampon de sortie
;
; Sortie:
;   A: caractère en majuscule si OK, ou caractère incorect si erreur
;   C: 0->Ok, 1->Erreur (caractère incorrect)
;   X: inchangé
;   Y: inchangé
;
; Variables:
;	Modifiées:
;		TR0
;	Utilisées:
;		RESB
; Sous-routines:
;	-
;----------------------------------------------------------------------
.proc add_char
    ; Caractères '-', '_' ou '?' autorisés
    cmp #'-'
    beq ok
    cmp #'_'
    beq ok
    cmp #'?'
    beq ok

    ; Caractère numérique?
    cmp #'0'
    bcc error
    cmp #'9'+1
    bcc ok

; Pour forcer le caractère en majuscule
    cmp #'A'
    bcc error
    cmp #'Z'+1
    bcc ok

    cmp #'a'
    bcc error
    cmp #'z'+1
    bcs error
    and #$DF
;    bne ok

; Pour forcer le caractère en minuscule
;    cmp #'z'+1
;    bcs Erreur
;    cmp #'a'
;    bcs ok
;
;    cmp #'A'
;    bcc Erreur
;    cmp #'Z'+1
;    bcs Erreur
;    ora #$20
;    bne ok

; Ajoute le caractère au tampon
ok:
    pha
    sty TR0
    txa
    tay
    pla
    sta (RESB),y
    ldy TR0

    clc
    rts

error:
    sec
    rts
.endproc


; ------------------------------------------------------------------------------
;
; Entrée:
;    ls_save_line_command_ptr : Chaine
;    RESB: Masque
;
; Sortie:
;    Z = 1 -> Ok
;    Y: Offset du dernier caractère testé
;    A: Dernier caractère testé (0 si fin du masque atteinte)
;
; Note: ne vérifie pas si la longueur de la chaîne est > à celle du masque
;       - RES ne peut être utilisé à la place de ls_save_line_command_ptr (le XCRLF modifie RES)
;
; ------------------------------------------------------------------------------
.proc Match
    ldy #$ff

  @loop:
    iny

    ; Fin du masque?
    lda (RESB),y
    beq @end

    ; Caractères identiques?
    cmp (ls_save_line_command_ptr),y
    beq @loop

    ; Si le masque est '*', on passe au caractère suivant
    cmp #'*'
    beq @loop

    ; Si le masque est '?', il faut un caractère qui ne soit pas un ' '
    cmp #'?'
    bne @end

    lda (ls_save_line_command_ptr),y
    cmp #' '
    bne @loop

    ; Force Z=0 (pas de concordance, replcae le dernier caractère testé dans ACC)
    lda #'?'

    ; Si on veut vérifier que la chaîne fait la même longueur que le masque
    ; (pas valable ici, les noms de fichiers sont complétés avec des ' ')
    ; rts

  @end:
    ; Si on veut vérifier que la chaîne fait la même longueur que le masque
    ; (pas valable ici, les noms de fichiers sont complétés avec des ' ')
    ; lda (RES),y

    rts
.endproc


; ------------------------------------------------------------------------------
; Affichage Taille, Date & Heure
;
; Utilise:
;
; ------------------------------------------------------------------------------
.proc ls_display_date_size
    ; Sauvegarde RES-RESB
    ; Sauvegarde ls_save_line_command_ptr-ls_save_line_command_ptr+1 (pour Match)
;;    lda RES
;;    pha
;;    lda RES+1
;;    pha
    lda RESB
    pha
    lda RESB+1
    pha
;    lda ls_save_line_command_ptr
;    pha
;    lda ls_save_line_command_ptr+1
;    pha
    jsr ls_display_size
;    pla
;    sta ls_save_line_command_ptr+1
;    pla
;    sta ls_save_line_command_ptr
    pla
    sta RESB+1
    pla
    sta RESB
;;    pla
;;    sta RES+1
;;    pla
;;    sta RES

    jmp ls_display_date

.endproc

; ------------------------------------------------------------------------------
; Affichage Date & Heure
;
; Buffer:
;    Date: 15-9 -> Year
;           8-5 -> Month
;           0-4 -> Day
;
;    Heure: 15-11 -> Hour
;           10- 5 -> Min
;            4- 0 -> Sec
;
; Utilise:
;    TR0-TR1 (directement)
;    TR4-TR6 (indirectement, via Bin2BCD)
;
; ------------------------------------------------------------------------------
.proc ls_display_date
   CPUTC ' '
;    print #' '
;    ; Encre blanche
;    lda #$87
;    BRK_ORIX XWR0


    ; $07bc = 1980
    lda #$bc
    sta TR0
    lda #$07
    sta TR1

    ldy #$0c
    lda BUFEDT+14,y
    lsr
    php

    clc
    adc TR0
    ; sta TR0
    bcc *+4
    inc TR1
    ldx #$10
    jsr Bin2BCD

;    CPUTC '-'
    print #'-', NOSAVE

;    lda #$00
;    sta TR1

;    ldy #$0c
    lda BUFEDT+13,y
    plp
    ror
    lsr
    lsr
    lsr
    lsr

    jsr Bin2BCD

;    CPUTC '-'
    print #'-', NOSAVE

;    ldy #$0c
    lda BUFEDT+13,y
    and #$1f
    jsr Bin2BCD

;    CPUTC ' '
;    CPUTC ' '
;    print #' ', NOSAVE
    print #' ', NOSAVE

    lda BUFEDT+12,y
    lsr
    lsr
    lsr
    jsr Bin2BCD

;    CPUTC ':'
    print #':', NOSAVE
    lda BUFEDT+12,y
    and #$07
    sta TR1
    lda BUFEDT+11,y
    and #$e0
    clc
    ror TR1
    ror
    ror TR1
    ror
    ror TR1
    ror
    ror
    ror

; Nécessaire uniquement pour afficher les secondes
;    jsr Bin2BCD
;
;;    CPUTC ':'
;    print #':', NOSAVE
;    lda BUFEDT+12,y
;    and #$1f
;    asl
.endproc

; ------------------------------------------------------------------------------
;
; ------------------------------------------------------------------------------
.proc Bin2BCD
    ; Entrée:
    ;    TR0-TR1: Valeur binaire
    ;
    ; Sortie:
    ;    TR0-TR1: $0000
    ;    TR4-TR6: Valeur en BCD
    ;      X: $00
    ;      Y: Inchangé
    ;      A: Modifié
    sta TR0
    lda #$00
    sta TR4
    sta TR5
    sta TR6

    ldx #$10
    sed
  @loop:
    asl TR0
    rol TR0+1

    lda TR4
    adc TR4
    sta TR4

    lda TR4+1
    adc TR4+1
    sta TR4+1

    lda TR4+2
    adc TR4+2
    sta TR4+2

    dex
    bne @loop
    cld

    lda TR6
    beq *+5
    jsr PrintHexByte
    lda TR5
    beq *+5
    jsr PrintHexByte
    lda TR4
.endproc

; ------------------------------------------------------------------------------
;
; ------------------------------------------------------------------------------
.proc PrintHexByte
    pha

    ; High nibble
    lsr
    lsr
    lsr
    lsr
    jsr Hex2Asc

    ;Low nibble
    pla
    and #$0f

Hex2Asc:
    ora #$30
    cmp #$3a
    bcc *+4
    adc #$06
    BRK_KERNEL XWR0
    rts
.endproc

; ------------------------------------------------------------------------------
;
; ------------------------------------------------------------------------------
.proc PrintFileAttr
    pha
    and #$10
    beq @attr_nodir
    lda #'d'
    .byte $2c
  @attr_nodir:
    lda #'-'
    BRK_KERNEL XWR0
    pla
    lsr
    bcc @attr_rw
    lda #'r'
    .byte $2c
  @attr_rw:
    lda #'-'
    BRK_KERNEL XWR0
    rts
.endproc

; ------------------------------------------------------------------------------
;
; ------------------------------------------------------------------------------
.proc ls_display_size
;    CPUTC ' '
    ; Encre blanche
    lda #$87
    BRK_KERNEL XWR0

    ; Copie la taille du fichier en RES-RESB
    ldy #$03
 @loop:
    lda BUFEDT+17+$0C,y
    sta RES,y
    dey
    bpl @loop

    ; Conversion en BCD
    jsr convd

    ; Conversion en chaine
    lda #<(BUFEDT+17+$0C+4)
    ldy #>(BUFEDT+17+$0C+4)
    jsr bcd2str

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

     ; La chaine fait 10 caractères
     ; Taille maximale: < 9 999 999
     ; donc on saute les 3 premiers caractères
    clc
    lda #$03
    adc RES
    sta RES
    bcc *+4
    inc RES+1

    print (RES)
    rts
.endproc

; ====================================
LSB  = RES
NLSB = LSB+1
NMSB = NLSB+1
MSB  = NMSB+1

; ------------------------------------------------------------------------------
;
; Entrée:
;    RES-RESB: Valeur binaire
;
; Sortie:
;    TR0-TR4: Valeur en BCD
;
; ------------------------------------------------------------------------------
BCDA = (TR0-$FB) & $ff ; = $0C

.proc convd
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

;-------
; Pour LSB en premier dans BCDA

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
.endproc

; ------------------------------------------------------------------------------
;
; Entrée:
;    RES: Adresse de la chaine (AY)
;    TR0-TR4: Valeur en BCD
;
; ------------------------------------------------------------------------------
.proc bcd2str
	sta RES
	sty RES+1

	ldx #$04          ; Nombre d'octets à convertir
	ldy #$00
;	clc

@loop:
	; BCDA: LSB en premier
	lda TR0,X
	pha
	; and #$f0
	lsr
	lsr
	lsr
	lsr
;	clc
	ora #'0'
	sta (RES),Y

	pla
	and #$0f
	ora #'0'
	iny
	sta (RES),y

	iny
	dex
	bpl @loop

	lda #$00
	sta (RES),y
	; lda RES
	; ldy RES+1
	rts
.endproc



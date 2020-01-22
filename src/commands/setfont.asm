;;
; Setfont: command to change the default charset.
;;

;.include "../dependencies/kernel/src/include/print.mac"

.export _setfont

;----------------------------------------------------------------------
;
;----------------------------------------------------------------------
.define setfont_path "/usr/share/fonts/"
.define setfont_ext  ".chs"

;----------------------------------------------------------------------
;
;----------------------------------------------------------------------
.proc _setfont
    setfont_fp :=userzp+2 ; 2 bytes

    ldx #$01
    jsr _orix_get_opt
    bcs *+5
    jmp usage

    MALLOC .strlen(setfont_path)+FNAME_LEN+1+1
    TEST_OOM_AND_MAX_MALLOC

    sta userzp
    sty userzp+1

    ; Destination du _strcpy
    sta RESB
    sty RESB+1

    ; Source du _strcpy
    lda #<fontpath
    ldy #>fontpath
    sta RES
    sty RES+1

    jsr _strcpy

    ; Source
    lda #<ORIX_ARGV
    ldy #>ORIX_ARGV
    sta RESB
    sty RESB+1

    ; Destination
    lda userzp
    ldy userzp+1
    sta RES
    sty RES+1

    jsr _strcat

    ; Ajoute l'extension
    ; Note: RES est toujours valable
    ; (il pointe à la fin de fontpath avant la concaténation)
    lda #<fontext
    ldy #>fontext
    sta RESB
    sty RESB+1
    jsr _strcat

    ;FOPEN fontpath, O_RDONLY
    lda userzp
    ldx userzp+1
    ldy #O_RDONLY
    BRK_ORIX XOPEN
    
    cmp #NULL
    bne @S1
    cpy #NULL
    bne @S1
    beq error
    
@S1:
	sta	setfont_fp
	sty setfont_fp+1

    ; Chargement du fichier
    ; Destination
    ; count = 1, fp = 0?
    FREAD $b500, $0300, 1, 0

    ; FCLOSE 0
    ; mfree (setfont_fp)
    
    lda setfont_fp
    ldy setfont_fp+1
    BRK_ORIX XCLOSE

	



    ; mfree (userzp)
    lda userzp
    ldy userzp+1
    BRK_ORIX XFREE

    BRK_ORIX XCRLF

    ; Code de retour
    lda #$00
    tay

    rts
;.endproc

;----------------------------------------------------------------------
;
;----------------------------------------------------------------------
.proc usage
    ; print msg_usage, NOSAVE
    lda #<msg_usage
    ldy #>msg_usage
    BRK_ORIX XWSTR0

    BRK_ORIX XCRLF

    ; Code de retour
    lda #$ff
    tay

    rts
.endproc

;----------------------------------------------------------------------
;
;----------------------------------------------------------------------
.proc error
    BRK_ORIX XCRLF

    ; print txt_file_not_found, NOSAVE
    lda #<txt_file_not_found
    ldy #>txt_file_not_found
    BRK_ORIX XWSTR0

    ;print (userzp), NOSAVE
    lda userzp
    ldy userzp+1
    BRK_ORIX XWSTR0

    BRK_ORIX XCRLF
    ; mfree userzp
    lda userzp
    ldy userzp+1
    BRK_ORIX XFREE

    ; Code de retour
    lda #$ff
    tay

    rts
.endproc

;----------------------------------------------------------------------
;
;----------------------------------------------------------------------
msg_usage:
	.asciiz "Usage: setfont <fontname>"

fontpath:
    .asciiz setfont_path
    ; .asciiz "xxxxxxxx.xxx"

fontext:
    .asciiz setfont_ext

;----------------------------------------------------------------------
;
;----------------------------------------------------------------------
.endproc

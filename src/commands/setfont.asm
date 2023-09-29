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

    setfont_mainargs_argv      := userzp+4
    setfont_mainargs_argc      := userzp+6
    setfont_mainargs_arg1_ptr  := userzp+8

    initmainargs setfont_mainargs_argv, setfont_mainargs_argc, 0

    cpx     #$02
    beq     @continue

    jmp     usage
@continue:
 ;   MALLOC .strlen(setfont_path)+FNAME_LEN+1+1
    malloc .strlen(setfont_path)+FNAME_LEN+1+1, userzp, str_oom
    cmp     #$00
    bne     @nooom
    cpy     #$00
    bne     @nooom
    rts

@nooom:
    sta     userzp
    sty     userzp+1

    ; Destination du _strcpy
    sta     RESB
    sty     RESB+1

    ; Source du _strcpy
    lda     #<fontpath
    ldy     #>fontpath
    sta     RES
    sty     RES+1

    jsr     _strcpy

    getmainarg #1, (setfont_mainargs_argv)
    sta     setfont_mainargs_arg1_ptr
    sty     setfont_mainargs_arg1_ptr+1

    ; Source
    lda     setfont_mainargs_arg1_ptr
    ldy     setfont_mainargs_arg1_ptr+1
    sta     RESB
    sty     RESB+1

    ; Destination
    lda     userzp
    ldy     userzp+1
    sta     RES
    sty     RES+1

    jsr     _strcat

    mfree (setfont_mainargs_argv) ; save args

    ; Ajoute l'extension

    strcat (userzp), fontext

    fopen (userzp), O_RDONLY

    cmp     #$FF
    bne     @S1
    cpx     #$FF
    bne     @S1
    beq     error

@S1:
	sta     setfont_fp
	sty     setfont_fp+1

    ; Chargement du fichier
    ; Destination
    ; count = 1, fp = 0?
    fread $b500, $0300, 1, setfont_fp ; myptr is from a malloc for example

    ; FCLOSE 0
    ; mfree (setfont_fp)

    fclose (setfont_fp)
    mfree (userzp)


    ; Code de retour
    lda     #$00
    tay

    rts
;.endproc

;----------------------------------------------------------------------
;
;----------------------------------------------------------------------
.proc usage
    print msg_usage

    crlf

    ; Code de retour
    lda     #$FF
    tay

    rts
.endproc

;----------------------------------------------------------------------
;
;----------------------------------------------------------------------
.proc error
    crlf

    print txt_file_not_found

    print (userzp)


    crlf
    mfree (userzp)

    ; Code de retour
    lda     #$FF
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

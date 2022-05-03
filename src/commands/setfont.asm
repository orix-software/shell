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

    BRK_KERNEL XMAINARGS
    sta     setfont_mainargs_argv
    sty     setfont_mainargs_argv+1
    stx     setfont_mainargs_argc

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

    ldx     #$01
    lda     setfont_mainargs_argv
    ldy     setfont_mainargs_argv+1

    BRK_KERNEL XGETARGV
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
    

    lda     setfont_fp
    ldy     setfont_fp+1
    BRK_KERNEL XCLOSE
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
    print msg_usage, NOSAVE
    
    BRK_ORIX     XCRLF

    ; Code de retour
    lda     #$ff
    tay

    rts
.endproc

;----------------------------------------------------------------------
;
;----------------------------------------------------------------------
.proc error
    BRK_ORIX XCRLF

    print txt_file_not_found, NOSAVE


    print (userzp), NOSAVE


    BRK_ORIX XCRLF
    mfree (userzp)

    ; Code de retour
    lda     #$ff
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

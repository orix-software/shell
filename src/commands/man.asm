.export _man

; TODO : move MALLOC macro after arg test : it avoid a malloc if there is no parameter on command line

.proc _man
    MAN_SAVE_MALLOC_PTR :=userzp
    MAN_FP              :=userzp+2
    man_xmainargs_ptr  :=userzp+4

    BRK_KERNEL XMAINARGS
    sta     man_xmainargs_ptr
    sty     man_xmainargs_ptr+1
    cpx     #$01 ; No args ?
    bne     start_man
    jmp     error
start_man:   
    ; 
    MALLOC  (.strlen("/usr/share/man/")+FNAME_LEN+1+4)             ; length of /usr/share/man/ + 8 + .hlp + \0
    ; FIXME test OOM
    TEST_OOM


    sta     MAN_SAVE_MALLOC_PTR
    sta     RESB
    sty     MAN_SAVE_MALLOC_PTR+1
    sty     RESB+1

    lda     #<man_path
    sta     RES
    lda     #>man_path
    sta     RES+1
    jsr     _strcpy               ; MAN_SAVE_MALLOC_PTR contains adress of a new string
 
    ldx   #$01 ; get arg 
    lda   man_xmainargs_ptr
    ldy   man_xmainargs_ptr+1
    BRK_KERNEL XGETARGV

    sta     RESB
    sty     RESB+1
    
    lda     MAN_SAVE_MALLOC_PTR
    sta     RES
    lda     MAN_SAVE_MALLOC_PTR+1
    sta     RES+1
    jsr     _strcat
    
    lda     #<str_man_hlp
    sta     RESB
    lda     #>str_man_hlp
    sta     RESB+1
    
    lda     MAN_SAVE_MALLOC_PTR
    sta     RES
    lda     MAN_SAVE_MALLOC_PTR+1
    sta     RES+1
    jsr     _strcat
 

    fopen (MAN_SAVE_MALLOC_PTR), O_RDONLY
    cpx     #$FF
    bne     next

    cmp     #$FF
    bne     next

    ; Not found
    ; Free memory for path
    lda     MAN_SAVE_MALLOC_PTR
    ldy     MAN_SAVE_MALLOC_PTR+1
    BRK_KERNEL XFREE

    print   txt_file_not_found

    ldx   #$01 ; get arg 
    lda   man_xmainargs_ptr
    ldy   man_xmainargs_ptr+1
    BRK_KERNEL XGETARGV
    BRK_KERNEL XWSTR0

    RETURN_LINE

    rts
error:
    ; Free memory for path
    lda     MAN_SAVE_MALLOC_PTR
    ldy     MAN_SAVE_MALLOC_PTR+1
    BRK_KERNEL XFREE
    print   str_man_error
    rts

next:
    sta     MAN_FP
    stx     MAN_FP+1
    CLS
    SWITCH_OFF_CURSOR
  ; We read 1080 bytes
    fread SCREEN, 1080, 1, MAN_FP
  ;  FREAD   SCREEN, 1080, 1, 0

cget_loop:
    BRK_KERNEL  XRDW0
    bmi cget_loop
    ; A bit crap to flush screen ...
    ; read again ?
out:   
    BRK_KERNEL XHIRES
    BRK_KERNEL XTEXT
    
    SWITCH_ON_CURSOR

    lda MAN_SAVE_MALLOC_PTR
    ldy MAN_SAVE_MALLOC_PTR+1
    BRK_KERNEL XFREE

    fclose(MAN_FP)
    
    rts

str_man_error:
  .byte   "What manual page do you want?",$0D,$0A,0
man_path:
  .asciiz "/usr/share/man/"
str_man_hlp:
  .asciiz ".hlp"
.endproc

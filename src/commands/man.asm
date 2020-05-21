.export _man

; TODO : move MALLOC macro after arg test : it avoid a malloc if there is no parameter on command line

.proc _man
    MAN_SAVE_MALLOC_PTR:=userzp
    MAN_SAVE_MALLOC_FP :=userzp+2
    ; 
    MALLOC  (.strlen("/usr/share/man/")+FNAME_LEN+1+4)             ; length of /usr/share/man/ + 8 + .hlp + \0
    ; FIXME test OOM
    TEST_OOM_AND_MAX_MALLOC

start_man:   
    sta     MAN_SAVE_MALLOC_PTR
    sta     RESB
    sty     MAN_SAVE_MALLOC_PTR+1
    sty     RESB+1

    lda     #<man_path
    sta     RES
    lda     #>man_path
    sta     RES+1
    jsr     _strcpy               ; MAN_SAVE_MALLOC_PTR contains adress of a new string
 
    ; get the first parameter
    ldx     #$01
    jsr     _orix_get_opt
    bcc     error                 ; there is not parameter, jumps and displays str_man_error
    STRCPY  ORIX_ARGV,BUFNOM
 
    ; strcat(ptr,ORIX_ARGV) 
    lda     #<ORIX_ARGV
    sta     RESB
    lda     #>ORIX_ARGV
    sta     RESB+1
    
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
 
    lda     MAN_SAVE_MALLOC_PTR
    ldx     MAN_SAVE_MALLOC_PTR+1
    
    ldy     #O_RDONLY
    BRK_KERNEL XOPEN

    cmp     #NULL
    bne     next
    cpy     #NULL
    bne     next


    ; Not found
    ; Free memory for path
    lda     MAN_SAVE_MALLOC_PTR
    ldy     MAN_SAVE_MALLOC_PTR+1
    BRK_KERNEL XFREE

    PRINT   txt_file_not_found
    ldx     #$01
    jsr     _orix_get_opt
    PRINT   BUFNOM
    RETURN_LINE

    rts
error:
    ; Free memory for path
    lda     MAN_SAVE_MALLOC_PTR
    ldy     MAN_SAVE_MALLOC_PTR+1
    BRK_ORIX XFREE
    PRINT   str_man_error
    rts

next:
    sta     MAN_SAVE_MALLOC_FP
    sty     MAN_SAVE_MALLOC_FP+1
    CLS
    SWITCH_OFF_CURSOR
  ; We read 1080 bytes
    FREAD   SCREEN, 1080, 1, 0
    BRK_ORIX  XCLOSE
cget_loop:
    BRK_ORIX  XRDW0
    bmi cget_loop
    ; A bit crap to flush screen ...
out:   
    BRK_ORIX XHIRES
    BRK_ORIX XTEXT
    
    SWITCH_ON_CURSOR

    lda MAN_SAVE_MALLOC_PTR
    ldy MAN_SAVE_MALLOC_PTR+1
    BRK_ORIX XFREE

    lda MAN_SAVE_MALLOC_FP
    ldy MAN_SAVE_MALLOC_FP+1
    BRK_ORIX XFREE

    rts

str_man_error:
  .byte   "What manual page do you want?",$0D,$0A,0
man_path:
  .asciiz "/usr/share/man/"
str_man_hlp:
  .asciiz ".hlp"
.endproc


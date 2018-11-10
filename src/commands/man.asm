.proc _man

  MAN_SAVE_MALLOC_PTR:=VARLNG
  MAN_SAVE_MALLOC_FP :=VARLNG+2
    ;
    MALLOC 29              ; length of /usr/share/man/ + 8 + .hlp + \0
    ; FIXME test OOM
    TEST_OOM_AND_MAX_MALLOC
   
start_man:   
    sta MAN_SAVE_MALLOC_PTR
    sta RESB
    sty MAN_SAVE_MALLOC_PTR+1
    sty RESB+1
    lda #<man_path
    sta RES
    lda #>man_path
    sta RES+1
    jsr _strcpy             ; MAN_SAVE_MALLOC_PTR contains adress of a new string
 
    ; get the first parameter
    ldx #$01
    jsr _orix_get_opt
    bcc error                 ; there is not parameter, jumps and displays str_man_error
    STRCPY ORIX_ARGV,BUFNOM
 
    ; strcat(ptr,ORIX_ARGV) 
    lda #<ORIX_ARGV
    sta RESB
    lda #>ORIX_ARGV
    sta RESB+1
    
    lda MAN_SAVE_MALLOC_PTR
    sta RES
    lda MAN_SAVE_MALLOC_PTR+1
    sta RES+1
    jsr _strcat

    
    lda   #<str_man_hlp
    sta   RESB
    lda   #>str_man_hlp
    sta   RESB+1
    
    lda   MAN_SAVE_MALLOC_PTR
    sta   RES
    lda   MAN_SAVE_MALLOC_PTR+1
    sta   RES+1
    jsr   _strcat

    lda   MAN_SAVE_MALLOC_PTR
    ldx   MAN_SAVE_MALLOC_PTR+1
    ldy   #O_RDONLY
    BRK_ORIX XOPEN
    sta   MAN_SAVE_MALLOC_FP
    
    cpx   #$ff
    bne   next
    cmp   #$ff
    bne   next
    beq   not_found
    rts
error:
    PRINT str_man_error
    rts
not_found:
    PRINT txt_file_not_found
    ldx   #$01
    jsr   _orix_get_opt
    PRINT BUFNOM
    RETURN_LINE
    rts 
next:
    CLS
    SWITCH_OFF_CURSOR
    ; now we read
    lda #$01 ; 1 is the fd id of the file opened
    sta TR0
  ; define target address
    lda #<SCREEN
    sta PTR_READ_DEST
    lda #>SCREEN
    sta PTR_READ_DEST+1
  ; We read 1080 bytes
    lda #<1080      ; FIXME  size from parameters
    ldy #>1080
  ; reads byte 
    BRK_ORIX XFREAD
    BRK_ORIX XCLOSE
cget_loop:
    BRK_ORIX XRDW0
    bmi cget_loop
    ; A bit crap to flush screen ...
out:   
    BRK_ORIX XHIRES
    BRK_ORIX XTEXT
    
    SWITCH_ON_CURSOR

    FREE MAN_SAVE_MALLOC_PTR
    rts

str_man_error:
  .byte "What manual page do you want?",$0D,$0A,0
man_path:
  .asciiz "/usr/share/man/"
str_man_hlp:
  .asciiz ".hlp"
.endproc

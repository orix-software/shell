.include "commands/lib/common.asm"

CP_SIZE_OF_BUFFER=40000

cp_tmp := userzp+4

.export _mv,_cp

;.proc
.proc _mv
  rts
  lda   #$01 ; don't Delete param1 file
  sta   cp_tmp
  jmp   _cp_mv_execute
.endproc  

.proc _cp
  rts
  lda   #$00 ; don't Delete param1 file FIXME 65c02
  sta   cp_tmp
  jmp   _cp_mv_execute
.endproc

.proc _cp_mv_execute
  ptr1         :=userzp
  MALLOC_PTR1  :=userzp+2
  ;ptr2 will be used to save fp
  lda   #$00
  sta   ptr1_32         ; FIXME 65C02
  sta   ptr1_32+1
  sta   ptr1_32+2
  sta   ptr1_32+3
  jsr   commands_check_2_params
  beq   @next
  rts
  
@next:
  ; open first params
  ldx   #$01
  jsr   _orix_get_opt

  lda   #<ORIX_ARGV
  ldx   #>ORIX_ARGV
  
  ldy   #O_RDONLY ; Open in readonly
  BRK_TELEMON XOPEN
  cmp   #$FF
  beq   no_such_file

  ; Let's copy
  
  ; Send the fp pointer

  sta   TR0
; define target address
    
  MALLOC CP_SIZE_OF_BUFFER
  sta   MALLOC_PTR1
  sty   MALLOC_PTR1+1

  ;MALLOC(209)
  cmp   #$00
  bne   @not_oom
  cpy #$00
  bne   @not_oom
  PRINT str_oom
  ; oom
  rts
@not_oom:  
  sta   PTR_READ_DEST
  sta   ptr1

  sty   ptr1+1
  sty   PTR_READ_DEST+1
; We read 8000 bytes
  lda   #<CP_SIZE_OF_BUFFER
  ldy   #>CP_SIZE_OF_BUFFER
; reads byte 
  BRK_TELEMON XFREAD
  ; Compute bytes written
  lda     PTR_READ_DEST+1
  sec
  sbc     ptr1+1
  sta     ptr1+1
  ;tax			
  lda     PTR_READ_DEST
  sec
  sbc     ptr1
  sta     ptr1


  BRK_TELEMON XCLOSE
 
  ldx   #$02
  jsr   _orix_get_opt ; get second arg

  lda   #<ORIX_ARGV
  ldx   #>ORIX_ARGV
  
  ldy   #O_WRONLY ; Open in readonly
  BRK_KERNEL XOPEN
 
  lda   MALLOC_PTR1
  sta   PTR_READ_DEST
  lda   MALLOC_PTR1+1
  sta   PTR_READ_DEST+1
; We read 8000 bytes
  lda   ptr1
  ldy   ptr1+1
; reads byte 
  BRK_KERNEL XFWRITE

  BRK_KERNEL XCLOSE
  ; and we write the file
  
  lda   cp_tmp
  beq   @out
  
  ldx   #$01
  jsr   _orix_get_opt
  lda   #<ORIX_ARGV
  ldx   #>ORIX_ARGV
  BRK_KERNEL XRM
  ; now remove file

@out:
  
  rts
no_such_file:
  PRINT   cp
  CPUTC   ':'
  CPUTC   ' ' 
  PRINT   str_cannot_stat
  CPUTC   '''
  
 
  ldx   #$01
  jsr   _orix_get_opt
 
  PRINT ORIX_ARGV
  lda     #$27
  BRK_KERNEL XWR0
  
  PRINT   str_not_found
  rts
str_cannot_stat:
  .asciiz   "cannot stat "

.endproc


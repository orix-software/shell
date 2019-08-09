.export _rm

.proc _rm
  ldx   #$01               ; get the fiest arg
  jsr   _orix_get_opt      ; 
  lda   ORIX_ARGV
  beq   missing_operand
; prevent the rm / case  
  lda   ORIX_ARGV
  cmp   #'/'
  bne   skip_rm_slash_case ;  
  lda   ORIX_ARGV+1
  beq   no_such_file
  
skip_rm_slash_case:
  lda   #<ORIX_ARGV
  ldx   #>ORIX_ARGV
  BRK_ORIX XRM
  cmp   #ENOENT
  beq   no_such_file
  rts
no_such_file:
  PRINT rm

  PRINT str_cannot_remove
  lda   #$27
  BRK_ORIX XWR0      ; FIXME CPUTC  

  ldx #$01
  jsr _orix_get_opt
  PRINT ORIX_ARGV
  lda   #$27
  BRK_ORIX XWR0      ; FIXME CPUTC
  
  PRINT str_not_found
  rts
  
missing_operand: 

  PRINT rm
  PRINT str_missing_operand
    
  rts
str_cannot_remove:
  .asciiz ": cannot remove "

.endproc

  

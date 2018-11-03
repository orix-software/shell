.proc _touch
  ldx #$01
  jsr _orix_get_opt
  lda ORIX_ARGV
  beq missing_operand
; prevent the rm / case  
  lda ORIX_ARGV
  cmp #'/'
  bne skip_touch_slash_case ;  
  lda ORIX_ARGV+1
  beq missing_operand
  
skip_touch_slash_case:
  FOPEN ORIX_ARGV,O_WRONLY
  rts
  
missing_operand:
  PRINT touch
  PRINT str_missing_operand
  rts  
.)


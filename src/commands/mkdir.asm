.proc _mkdir
    ldx   #$01
    jsr   _orix_get_opt
    lda   ORIX_ARGV
    beq   missing_operand
  
    MKDIR ORIX_ARGV
    rts
missing_operand:
    PRINT mkdir
    PRINT str_missing_operand
    rts
.endproc


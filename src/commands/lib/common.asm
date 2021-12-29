
.proc commands_check_2_params

  ldx #$01

  rts  
str_missing_operand_after:  
  .asciiz "missing destination file operand after '"
.endproc



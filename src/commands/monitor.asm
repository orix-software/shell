.proc _monitor
 
  ldx   #MONITOR_ID_BANK
  stx   VAPLIC
  lda   #<$c000
  sta   VAPLIC+1
  ldy   #>$c000
  sty   VAPLIC+2
 
call_routine_in_another_bank:
  STA   VEXBNK+1 ; BNK_ADDRESS_TO_JUMP_LOW
  STY   VEXBNK+2 ; BNK_ADDRESS_TO_JUMP_HIGH
  STX   BNKCIB
  JMP   EXBNK
.endproc

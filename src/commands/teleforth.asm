.proc _forth
;ef0a
  ldx     #TELEFORTH_ID_BANK
  stx     VAPLIC
  lda     #<$C000
  sta     VAPLIC+1
  ldy     #>$C000
  sty     VAPLIC+2
 
call_routine_in_another_bank:
  sta     VEXBNK+1 ; BNK_ADDRESS_TO_JUMP_LOW
  sty     VEXBNK+2 ; BNK_ADDRESS_TO_JUMP_HIGH
  stx     BNKCIB
  jmp     EXBNK
.endproc 



.proc _trim
; This routine modify RES
; Each time a space is found, RES is modified (+1 to the pointer) until it reached 0
  ldy    #$00
@L1:  
  lda    (RES),y
  beq    @S1
  cmp    #' '
  beq    @trim
  iny
  bne    @L1
@S1:
  rts
@trim:
  inc    RES
  bcc    @next
  inc    RES+1
@next:
  bne    @L1    
.endproc

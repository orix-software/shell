.export _date
.proc _date
    lda     #<(SCREEN+32)
    ldy     #>(SCREEN+32)
    BRK_KERNEL XWRCLK
    rts
.endproc    

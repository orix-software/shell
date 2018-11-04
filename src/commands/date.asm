.proc _date
    lda     #<(SCREEN+32)
    ldy     #>(SCREEN+32)
    BRK_TELEMON XWRCLK
    rts
.endproc    

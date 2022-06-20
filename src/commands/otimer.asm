.export _otimer

.proc _otimer
    lda     #<(SCREEN+32)
    ldy     #>(SCREEN+32)
    BRK_KERNEL XWRCLK
    rts
.endproc

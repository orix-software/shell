.proc read_joy
        lda     VIA2::PRB
        and     #%01111111
        ora     #%01000000
        sta     VIA2::PRB
        ; then read
        lda     VIA2::PRB
        eor     #%01011111

        rts
.endproc

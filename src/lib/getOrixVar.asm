
; ORIX_PATH_CURRENT
.proc _getTelemonVar

    ; X contains the id 
    lda low,x
    ldy high,x
    rts
low:    
    .byt <ORIX_PATH_CURRENT
high:
    .byt >ORIX_PATH_CURRENT

.endproc   


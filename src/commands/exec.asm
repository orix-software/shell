.proc _exec
    ; Now we remove exec word from BUFEDT
     ldx     #$00
 @loop:    
     lda     BUFEDT+4,x ; we know that exec is has a length of 4 + 1 byte for space
     beq     @out
     sta     BUFEDT,x
     inx
     bne     @loop
 @out:
    sta     BUFEDT,x

;   unregister exec
    lda     ORIX_CURRENT_PROCESS_FOREGROUND
    jsr     _orix_unregister_process

    lda     #<BUFEDT
    ldy     #>BUFEDT
    
    BRK_TELEMON($63) ; Exec

    rts
str_test:  

.endproc

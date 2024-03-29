; strcat (RES, RESB)

.proc _strcat
    ldy #$00
loop:
    lda (RES),y
    beq end_string_found
    iny
    beq end ; prevent BOF
.IFPC02
.pc02
    bra loop
.p02
.else
    jmp loop
.endif
end_string_found:
    tya
    clc
    adc RES
    bcc skip
    inc RES+1
skip:
    sta RES

    ldy #$00
loopcopy:
    lda (RESB),y
    beq end
    sta (RES),y
    iny
    beq end
.IFPC02
.pc02
    bra loopcopy
.p02
.else
    jmp loopcopy
.endif
end:
    lda #$00
    sta (RES),y
    ; y return the length
    rts
.endproc

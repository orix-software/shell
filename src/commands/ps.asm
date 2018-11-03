.proc _ps

    PRINT str_ps_title

    ;PRINT(str_init)

    
    ldx #$00
loop:
    stx TR7
    lda LIST_PID,x
    beq next_process

    LDY #$00
    PRINT_BINARY_TO_DECIMAL_16BITS 1
    
    CPUTC ' '

    ldx TR7
    lda orix_command_table_low,x
    ldy orix_command_table_high,x
    BRK_TELEMON XWSTR0
    BRK_TELEMON XCRLF
next_process:
    ldx TR7
    inx

    cpx #ORIX_MAX_PROCESS
    bne loop
exit:
    rts
str_ps_title:
    .byte "PID CMD",$0D,$0A,0
str_init:
   .byte  "  1 init",$0D,$0A
   .byte  "  2 bash",$0D,$0A,0
.endproc


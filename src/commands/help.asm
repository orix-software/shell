.proc _help
HELP_NUMBER_OF_COLUMNS=3

    lda #BASH_NUMBER_OF_COMMANDS/HELP_NUMBER_OF_COLUMNS
    sta TR7
  
    ldx #$00
loop:
    lda list_command_low,x
    ldy list_command_high,x
    stx TEMP_ORIX_2
    BRK_ORIX XWSTR0
    ldx TEMP_ORIX_2

    lda commands_length,x
    sta TR6
    tax
loopme: 
    stx TR6
    CPUTC " "
    ldx TR6
    inx
    cpx #$08
    bne loopme
    ldx TEMP_ORIX_2
    inx 
    cpx #BASH_NUMBER_OF_COMMANDS-1 
    bne loop
  
    BRK_TELEMON XCRLF
    rts
.endproc 


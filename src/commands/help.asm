.proc _help
    HELP_NUMBER_OF_COLUMNS=3

    lda     #BASH_NUMBER_OF_COMMANDS/HELP_NUMBER_OF_COLUMNS
    sta     TR7
  
    ldx     #$00
loop:
    lda     list_command_low,x          ; Get the ptr of command string
    ldy     list_command_high,x
    stx     TEMP_ORIX_2                 ; Save X
    BRK_ORIX XWSTR0                     ; Print command

    ldx     TEMP_ORIX_2                 ; load X register with the current command to display

    ; Next lines are build to put in columns commands
    lda     commands_length,x               ; get the length of the command
    tax
loopme: 
    stx TR6
    CPUTC ' '
    ldx TR6
    inx
    cpx #$08                            ; Do we reached 8 columns ?
    bne loopme
    ldx TEMP_ORIX_2
    inx 
    cpx #BASH_NUMBER_OF_COMMANDS-1
    bne loop
  
    RETURN_LINE
    rts
.endproc 


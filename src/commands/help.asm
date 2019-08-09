.export _help

.proc _help

    ; This command works if commands have not a length greater than 8

    current_command         :=  userzp      ; 1 byte
    current_column          :=  userzp+1    ; 1 byte

    ldx     #$00
loop:
    lda     list_command_low,x          ; Get the ptr of command string
    ldy     list_command_high,x
    stx     current_command             ; Save X
    BRK_ORIX XWSTR0                     ; Print command

    ldx     current_command            ; Load X register with the current command to display

    ; Next lines are build to put in columns commands
    lda     commands_length,x           ; get the length of the command
    tax                                 ; Save in X 
loopme:                     
    stx     current_column              ; Save X in TR6
    CPUTC   ' '                         ; Displays a char 
    ldx     current_column              ; Get again X 
    inx                                 ; inx
    cpx     #$08                        ; Do we reached 8 columns ?
    bne     loopme                      ; no, let's display again a space
    ldx     current_command             ; do we reached 
    inx 
    cpx     #BASH_NUMBER_OF_COMMANDS-1  ; loop until we have display all commands
    bne     loop
  
    RETURN_LINE
    rts
.endproc 


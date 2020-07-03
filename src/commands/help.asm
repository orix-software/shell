.export _help

.proc _help

    ; This command works if commands have not a length greater than 8

.struct help_command_vars
;.res     userzp
.endstruct



    current_command         :=  userzp      ; 1 byte
    current_column          :=  userzp+1    ; 1 byte
    help_number_command     :=  userzp+2     ; 1 byte
    help_length             :=  userzp+3    ; 1 bytes
    help_ptr2               :=  userzp+4    ; 2 bytes
    help_ptr3               :=  userzp+6    ; 2 bytes
    current_bank            :=  ID_BANK_TO_READ_FOR_READ_BYTE    ; 1 bytes
    ptr1                    :=  OFFSET_TO_READ_BYTE_INTO_BANK    ; 2 bytes
    help_ID_BANK_TO_READ_FOR_READ_BYTE_save := userzp+8
.code
    ; let's get opt
    lda     ID_BANK_TO_READ_FOR_READ_BYTE
    sta     help_ID_BANK_TO_READ_FOR_READ_BYTE_save


    ldx     #$01
    jsr     _orix_get_opt
    ldx     #$00
    lda     ORIX_ARGV,x
    beq     @noparam
    cmp     #'-'
    bne     usage
    inx
    lda     ORIX_ARGV,x
    beq     usage
    cmp     #'b'
    bne     usage
@read_next_byte:    
    inx
    lda     ORIX_ARGV,x ; get arg
    beq     usage
    cmp     #' '
    beq     @read_next_byte
    bne     list_command_in_bank
     ; there is a char
@noparam:

    lda    #<internal_commands_str
    sta    help_ptr3
    
    lda    #>internal_commands_str
    sta    help_ptr3+1

    ldx     #$00
loop:
    lda     help_ptr3         ; Get the ptr of command string
    ldy     help_ptr3+1

    stx     current_command             ; Save X

    BRK_KERNEL XWSTR0                     ; Print command

    ldx     current_command            ; Load X register with the current command to display

    ; Next lines are build to put in columns commands
    lda     internal_commands_length,x           ; get the length of the command
    

    sec      ; Add \0 to the compute of the string
    adc     help_ptr3
    bcc     @S1
    inc     help_ptr3+1
@S1:
    sta     help_ptr3


    lda     internal_commands_length,x           ; get the length of the command
    tax

loopme:                     
    stx     current_column              ; Save0 X in TR6
    CPUTC   ' '                         ; Displays a char 
    ldx     current_column              ; Get again X 
    inx                                 ; inx
    cpx     #$08                        ; Do we reached 8 columns ?
    bne     loopme                      ; no, let's display again a space
    ldx     current_command             ; do we reached 
    inx 
    cpx     #BASH_NUMBER_OF_COMMANDS_BUILTIN  ; loop until we have display all commands
    bne     loop
  
    RETURN_LINE
    rts
usage:
    PRINT str_usage
    rts
list_command_in_bank:
    sec
    sbc     #$30
    sta     current_bank


; Get number of commands
    sei
    lda     #<$FFF7
    sta     ptr1
    lda     #>$FFF7
    sta     ptr1+1
    ldy     #$00
    ldx     #$00
    jsr     READ_BYTE_FROM_OVERLAY_RAM ; get low

    beq     @no_commands ; no commands out
    sta     help_number_command


    ; Get now adress of commands
    lda     #<$FFF5
    sta     ptr1
    lda     #>$FFF5
    sta     ptr1+1
    ldy     #$00
    ldx     #$00
    jsr     READ_BYTE_FROM_OVERLAY_RAM ; get low
    sta     RES

    iny
    ldx     #$00
    jsr     READ_BYTE_FROM_OVERLAY_RAM ; get high
    sta     RES+1

    lda     RES
    sta     ptr1
    lda     RES+1
    sta     ptr1+1



    lda     #$00
    sta     help_ptr2 ; Bug ...

@loopme:
    ldy     help_ptr2
    ldx     #$00
    jsr     READ_BYTE_FROM_OVERLAY_RAM
    
    beq     @S1
    cli
    BRK_KERNEL XWR0
    inc     help_ptr2
    sei
    bne     @loopme

@S1:
    cli

    ldy     help_ptr2
    iny
    sty     help_length
    cpy     #$08
    bne     @add_spaces
@continue:    
    CPUTC ' '
    sei
    jsr     @update_ptr
    ldy     #$00
    sty     help_ptr2
    dec     help_number_command
    bne     @loopme
@out:    
    lda     help_ID_BANK_TO_READ_FOR_READ_BYTE_save
    sta     ID_BANK_TO_READ_FOR_READ_BYTE
    
    cli
    RETURN_LINE
    rts
@no_commands:    
    cli
    PRINT str_nocommands_found
    rts
@add_spaces:
    sty     help_ptr2
    CPUTC ' ' 
    ldy     help_ptr2
    iny
    cpy     #$08
    bne     @add_spaces
    beq     @continue

@update_ptr:
    lda     help_length
    clc
    adc     ptr1
    bcc     @S2
    inc     ptr1+1
@S2:
    sta     ptr1
    rts



str_nocommands_found:
    .byte "No commands found in this bank",$0A,$0D,0
str_usage:
    .byte "Usage: help [-bBANKID]",$0A,$0D,0
.endproc 


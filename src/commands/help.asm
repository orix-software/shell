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
    bank_save_argc          := userzp+10
    help_argv1_ptr          := userzp+12
    help_save_value         := userzp+14

.code
    ; let's get opt
    lda     ID_BANK_TO_READ_FOR_READ_BYTE
    sta     help_ID_BANK_TO_READ_FOR_READ_BYTE_save

  ; Get first arg

    lda     bash_struct_ptr
    sta     help_argv1_ptr

    lda     bash_struct_ptr+1
    sta     help_argv1_ptr+1

    ldy     #shell_bash_struct::command_line

@get_first_arg:
    lda     (bash_struct_ptr),y
    beq     @noparam
    cmp     #' ' ; Read command line until we reach a space.
    beq     @found_space
    inc     help_argv1_ptr
    bne     @skip30
    inc     help_argv1_ptr+1

@skip30:
    iny
    bne     @get_first_arg

@found_eos:
   ; mfree(cd_path)
    rts

@found_space:
    ldy     #$00
    inc     help_argv1_ptr
    bne     @skip31
    inc     help_argv1_ptr+1
@skip31:
    lda     (help_argv1_ptr),y
    cmp     #' '
    beq     @found_space

    ;ldy     #$00
    lda     (help_argv1_ptr),y
    beq     @noparam
    cmp     #'-'
    bne     usage
    iny
    lda     (help_argv1_ptr),y
    beq     usage
    cmp     #'b'
    bne     usage

@read_next_byte:
    iny
    lda     (help_argv1_ptr),y ; get arg
    beq     usage
    cmp     #' '
    beq     @read_next_byte
    bne     list_command_in_bank
     ; there is a char
@noparam:
    lda     #<internal_commands_str
    sta     help_ptr3

    lda     #>internal_commands_str
    sta     help_ptr3+1

    ldx     #$00

loop:
    stx     current_command               ; Save X
    print (help_ptr3)
    ldx     current_command               ; Load X register with the current command to display
    ; Next lines are build to put in columns commands
    lda     internal_commands_length,x    ; get the length of the command
    sec      ; Add \0 to the compute of the string
    adc     help_ptr3
    bcc     @S1
    inc     help_ptr3+1

@S1:
    sta     help_ptr3
    lda     internal_commands_length,x    ; get the length of the command
    tax

loopme:
    stx     current_column               ; Save0 X in TR6
    print #' '
    ldx     current_column               ; Get again X
    inx                                  ; inx
    cpx     #$08                         ; Do we reached 8 columns ?
    bne     loopme                       ; no, let's display again a space
    ldx     current_command              ; do we reached
    inx
    cpx     #BASH_NUMBER_OF_COMMANDS_BUILTIN  ; loop until we have display all commands
    bne     loop

    crlf
    rts

usage:
    print str_usage
    rts

list_command_in_bank:
    sec
    sbc     #$30
    sta     current_bank

    iny
    lda     (help_argv1_ptr),y
    beq     @only_one_digit
    ; convert to decimal
    sec
    sbc     #$30
    sta     bank_save_argc
    ldx     current_bank ; 2 chars, get the first digit

    lda     #$00

@compute_again:
    clc
    adc     #10
    dex
    bne     @compute_again
    clc
    adc     bank_save_argc
    sta     bank_save_argc
    ; is it greater than 32 ?
    cmp     #32
    bcc     @do_not_switch_to_ram_bank
    pha
    lda     $342
    ora     #%00100000
    sta     $342
    pla
@do_not_switch_to_ram_bank:
    jsr     _twil_get_registers_from_id_bank
    ; A bank

    sta     current_bank
    stx     $343

@only_one_digit:

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
    lda     ptr1+1
    cmp     #$C0   ; Does ptr of command are in the rom ?
    bcc     @no_commands ; If it's lower than $c0 then skip

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
    print   #' '
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
    crlf
    rts

@no_commands:
    cli
    print str_nocommands_found
    rts

@add_spaces:
    sty     help_ptr2
    print #' '
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

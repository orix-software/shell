; A, X, Y contains the string to search

.define TWILIGHTE_ROM_MAGIC_TOKEN_OFFSET $FFED

.proc checking_rom_signature
    routine_to_load:=userzp+4 ; FIXME erase shell commands


   

    malloc   100,routine_to_load,str_oom ; [,fail_value]
    cmp      #$00
    bne      @not_oom
    cpy      #$00
    bne      @not_oom    

    rts




@not_oom:

    ; Copy


    ldy     #$00
@loop:    
    lda     twil_copy_routine_to_bank,y
    sta     (routine_to_load),y
    iny
    bne     @loop
    jsr     @run
    mfree(routine_to_load)

    rts
@run:
    ldx     #33
    jmp     (routine_to_load)    
.endproc


.proc twil_copy_routine_to_bank
    current_bank       := TR0
    sector_to_update   := TR1
    tmp1               := TR3
    tmp3               := TR4
    ptr1               := TR5 ; 2 bytes adress of the buffer
    save_bank          := TR7
    
    ;       check bank

    txa
    jsr     _twil_get_registers_from_id_bank
    stx     sector_to_update
    sta     current_bank

@start:
	sei
    ldx     TWILIGHTE_BANKING_REGISTER
    stx     tmp1

    ldx     TWILIGHTE_REGISTER
    stx     tmp3

    ldx     VIA2::PRA
    stx     save_bank
	; on swappe pour que les banques 8,7,6,5 se retrouvent en bas en id : 1, 2, 3, 4

    lda     VIA2::PRA
    and     #%11111000
    ora     current_bank
    sta     VIA2::PRA


    lda     sector_to_update ; pour debug FIXME, cela devrait être à 4
    sta  	TWILIGHTE_BANKING_REGISTER

	lda		TWILIGHTE_REGISTER
	ora		#%00100000
	sta		TWILIGHTE_REGISTER


    lda     #'S'
    cmp     TWILIGHTE_ROM_MAGIC_TOKEN_OFFSET
    bne     @out

    lda     #'Y'
    cmp     TWILIGHTE_ROM_MAGIC_TOKEN_OFFSET+1
    bne     @out    

    lda     #'S'
    cmp     TWILIGHTE_ROM_MAGIC_TOKEN_OFFSET+2
    bne     @out    

    ; FOUND

    lda     #LOAD_ROM ; No Force to check rom signature to load or not
    sta     TR2     ; Success






    lda     save_mode
    beq     @firmware



    jsr     $c006       ; Twil firm buffer
    lda     #$00
    beq     @out
@firmware:    

    jsr     $c003


@out:
    ldx     #$05 ; Return to shell
    stx     VIA2::PRA

    lda     tmp1
    sta     TWILIGHTE_BANKING_REGISTER

    ldx     tmp3
    stx     TWILIGHTE_REGISTER

	lda		#$00
	cli

	rts

.endproc


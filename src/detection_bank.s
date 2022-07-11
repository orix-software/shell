.proc detection_bank

        ptr1                    :=  OFFSET_TO_READ_BYTE_INTO_BANK    ; 2 bytes
        current_bank            :=  ID_BANK_TO_READ_FOR_READ_BYTE    ; 1 bytes

        lda     TWILIGHTE_REGISTER
        ora     #%00100000
        sta     TWILIGHTE_REGISTER

        ; Shellext is usually load in bank 33 (set = 0, bank = 0)
        ldx     #$00

        stx     TWILIGHTE_BANKING_REGISTER
        inx     ; store 1
        inx
        stx     current_bank

        sei
        lda     #<MAGIC_TOKEN_ROM
        sta     ptr1
        lda     #>MAGIC_TOKEN_ROM
        sta     ptr1+1
        ldy     #$00
        ldx     #$00
        ; detect shell extensions
        jsr     READ_BYTE_FROM_OVERLAY_RAM ; get low
        cmp     #'S'
        bne     @systemd_not_loaded

        ldy     #$01
        ldx     #$00
        jsr     READ_BYTE_FROM_OVERLAY_RAM ; get low
        cmp     #'E'
        bne     @systemd_not_loaded

        ldy     #$02
        ldx     #$00
        jsr     READ_BYTE_FROM_OVERLAY_RAM ; get low
        cmp     #'T'
        bne     @systemd_not_loaded

       ; jsr     $c000 

        ldy     #shell_bash_struct::shell_extension_loaded
        lda     #$01
        sta     (bash_struct_ptr),y



@systemd_not_loaded:

        lda     TWILIGHTE_REGISTER
        and     #%11011111  ; Switch to eeprom again
        sta     TWILIGHTE_REGISTER

        cli



        lda     #$00
        ldy     #shell_bash_struct::command_line
        sta     (bash_struct_ptr),y

        rts

.endproc

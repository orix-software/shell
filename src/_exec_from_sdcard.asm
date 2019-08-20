orix_try_to_find_command_in_bin_path:
    ; here we found no command, let's go trying to find it in /bin

    ldx     #$00
    jsr     _orix_get_opt

    jsr     _start_from_root_bin

    cmp     #$FF ; if it return x=$ff a=$ff (it's not open)
    beq     even_in_slash_bin_command_not_found
    ; we should start code here
    lda     #$00
    sta     ERRNO ; FIXME 65C02
    jsr     _orix_load_and_start_app_xopen_done
    rts


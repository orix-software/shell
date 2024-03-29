.define NETWORK_ROM  $02
.define SHELLEXT_ROM $03
.define SYSTEMD_ROM  $04

.define NO_LOAD_ROM $00
.define LOAD_ROM    $01

save_mode := userzp+11 ; FIXME erase shell commands

.proc systemd_start
    lda    #SYSTEMD_ROM
    jmp    _twilbank
.endproc

.proc shellext_start
    lda    #SHELLEXT_ROM
    jmp    _twilbank
.endproc

.proc network_start
    ; Test version
    lda     $342
    and     #%00000111
    cmp     #$04
    bne     @out

    lda    #NETWORK_ROM
    jmp    _twilbank
@out:
    crlf
    rts
.endproc

.proc twillauncher
    jmp     @load_and_start

@load_and_start:
    lda    #$01
    jmp    _twilbank
.endproc

.proc twilfirmware

@load_and_start:
    lda    #$00
    jmp    _twilbank
.endproc

.proc _twilbank
    buffer          := userzp+2 ; FIXME erase shell commands
    routine_to_load := userzp+4 ; FIXME erase shell commands
    ptr1            := userzp+6 ; FIXME erase shell commands
    current_bank    := userzp+8 ; FIXME erase shell commands
    ptr2            := userzp+9 ; FIXME erase shell commands
    fd_systemd      := userzp+13 ; FIXME erase shell commands

    sta     save_mode

    malloc   100,ptr1,str_oom ; [,fail_value]

    lda     save_mode
    cmp     #SYSTEMD_ROM
    bne     @test_shellext

    lda     #<str_path_rom
    sta     ptr2
    lda     #>str_path_rom
    sta     ptr2+1
    jmp     @copy

@test_shellext:
    lda     save_mode
    cmp     #SHELLEXT_ROM
    bne     @check_network_rom

    lda     #<str_path_shellext
    sta     ptr2
    lda     #>str_path_shellext
    sta     ptr2+1
    jmp     @copy

@check_network_rom:
    lda     save_mode
    cmp     #NETWORK_ROM
    bne     @systemd_rom

    lda     #<str_path_network
    sta     ptr2
    lda     #>str_path_network
    sta     ptr2+1
    jmp     @copy

@systemd_rom:
    lda     #<str_path_rom
    sta     ptr2
    lda     #>str_path_rom
    sta     ptr2+1

@copy:
    ldy     #$00
@loop4:
    lda     (ptr2),y
    beq     @out
    sta     (ptr1),y
    iny
    bne     @loop4

@out:
    sta     (ptr1),y
    ; FIXME macro
    ldy     #O_RDONLY
    lda     ptr1
    ldx     ptr1+1
    BRK_KERNEL XOPEN


    cpx     #$FF
    bne     @read ; not null then  start because we did not found a conf
    cmp     #$FF
    bne     @read ; not null then  start because we did not found a conf
    print   str_failed
    print (ptr1)
    mfree(ptr1)
    print str_not_found

    ldy     #$01 ; Error

    rts
@read:
    sta     fd_systemd
    stx     fd_systemd+1
    mfree(ptr1)     ; Free path string

    malloc   512,routine_to_load,str_oom ;  [,fail_value]
    cmp      #$00
    bne      @not_oom
    cpy      #$00
    bne      @not_oom
    fclose(fd_systemd)
    rts

@not_oom:

    malloc   16384,buffer,str_oom ; [,fail_value]

    cmp      #$00
    bne      @not_oom2
    cpy      #$00
    bne      @not_oom2
    mfree (routine_to_load)
    fclose(fd_systemd)
    rts

@not_oom2:

    ; FIXME macro
    lda     buffer ; We read db version and rom version, and we write it, we avoid a seek to 2 bytes in the file
    sta     PTR_READ_DEST

    lda     buffer+1
    sta     PTR_READ_DEST+1

  ; We read the file with the correct
    lda     #<16384
    ldy     #>16384
    ldx     fd_systemd

    ; reads byte
    BRK_KERNEL XFREAD

    fclose(fd_systemd)

; X contains the bankid
; AY contains the the adress of the buffer
; RES contains the size in pages ; One byte
; RESB contains the ptr address to write

    ldy     #$00

@loop:
    lda     twil_copy_buffer_to_ram_bank,y
    sta     (routine_to_load),y
    iny
    bne     @loop

@loop2:
    lda     twil_copy_buffer_to_ram_bank,y
    sta     (routine_to_load),y
    iny
    bne     @loop2

    lda     #$C0
    sta     RESB+1

    lda     #$00
    sta     RESB

    lda     #64
    sta     RES

    lda     save_mode
    cmp     #SYSTEMD_ROM
    beq     @systemd_bank


@check_shellext_rom:
    lda     save_mode
    cmp     #SHELLEXT_ROM
    bne     @check_systemd_bank
    ldx     #34
    jmp     @loading_rom


@check_systemd_bank:
    lda     save_mode
    cmp     #NETWORK_ROM
    bne     @systemd_bank
    ldx     #35 ; bank33
    jmp     @loading_rom

@systemd_bank:
    ldx     #33 ; bank33
    ; Send buffer address
@loading_rom:
    lda     buffer
    ldy     buffer+1

    jsr     run

    mfree   (routine_to_load)
    ldy     #$00 ; Error code ok
    rts

    ; if s, then start : load rom into ram
    ; execute RAM
    ; Call kernel to get

run:

    jmp (routine_to_load)
    rts
str_failed:
    .byte "..............",$81,"[FAILED]",$0D,$00
str_path_rom:
    .asciiz "/usr/share/systemd/systemd.rom"
str_path_network:
    .asciiz "/usr/share/network/network.rom"
str_path_shellext:
    .asciiz "/usr/share/shell/shellext.rom"
.endproc

.proc twil_copy_buffer_to_ram_bank
    buffer             := userzp+2
    current_bank       := TR0
    sector_to_update   := TR1
    nb_bytes           := TR2
    tmp1               := TR3
    tmp3               := TR4
    ptr1               := TR5 ; 2 bytes adress of the buffer
    save_bank          := TR7

    sta     ptr1
    sty     ptr1+1

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
    sta     TWILIGHTE_BANKING_REGISTER

    lda     TWILIGHTE_REGISTER
    ora     #%00100000
    sta     TWILIGHTE_REGISTER

    ldx     #$00
    ldy     #$00
@loop:
    lda     (ptr1),y
    sta     (RESB),y
    iny
    bne     @loop
    inc     RESB+1
    inc     ptr1+1
    inx
    cpx     RES
    bne     @loop
    ; then execute


    mfree    (buffer)



    lda     save_mode
    cmp     #SYSTEMD_ROM
    bne     @check_shellext

    jsr     $c000
    lda     #$00
    beq     @out

@check_shellext:

    lda     save_mode
    beq     @firmware
    cmp     #SHELLEXT_ROM
    bne     @check_others


    jsr     $c000       ; Shell extentions
    lda     #$00
    beq     @out

@check_others:
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

    lda     #$00
    cli

    rts

.endproc

.include "lib/checking_rom_signature.asm"

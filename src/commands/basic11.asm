.export _basic11

basic11_tmp := userzp

.proc _basic11
    COPY_CODE_TO_BOOT_ATMOS_ROM_ADRESS := $200
    ; Get current pwd and open
    BRK_KERNEL XGETCWD_ROUTINE  ; Get A & Y 
    sty     basic11_tmp
    ldx     basic11_tmp
    ldy     #O_RDONLY

    BRK_KERNEL XOPEN ; open current

    sei
    

    ; stop t2 from via1
    lda #0+32
    sta VIA::IER
    ; stop via 2
    lda #0+32+64
    sta VIA2::IER
	
    ldx #$00
loop:
    lda #$00                                    ; FIXME 65C02
    sta $00,x
    sta COPY_CODE_TO_BOOT_ATMOS_ROM_ADRESS,x
    lda copy,x
    sta COPY_CODE_TO_BOOT_ATMOS_ROM_ADRESS,x
    dex
    bne loop
    lda #$00                                    ; FIXME 65C02
    sta $2DF ; Flush keyboard for atmos rom
    jmp COPY_CODE_TO_BOOT_ATMOS_ROM_ADRESS
copy:
    sei
    lda #ATMOS_ID_BANK
    sta VIA2::PRA
    jmp $F88F ; NMI vector of ATMOS rom
.endproc

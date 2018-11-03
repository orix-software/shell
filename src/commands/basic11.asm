.proc _basic11
    sei
    ; stop t2 from via1
    lda #0+32
    sta V1IER
    ; stop via 2
    lda #0+32+64
    sta V2IER	
	
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
    sta $2df ; Flush keyboard for atmos rom
    jmp COPY_CODE_TO_BOOT_ATMOS_ROM_ADRESS
copy:
    sei
    lda #ATMOS_ID_BANK
    sta V2DRA
    jmp $F88F ; NMI vector of ATMOS rom
.endproc

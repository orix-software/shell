.export _systemd

.proc _systemd
    fd_systemd := userzp
    buffer := userzp+2
    routine_to_load:=userzp+4
    ;routine_to_load_save:=userzp+6
    ptr1 := userzp+8
    ; start : 
    ; systemd -s 
    ;PRINT str_path_rom
    ;RETURN_LINE
    PRINT str_starting

    malloc   100 ; [,oom_msg_ptr] [,fail_value]
    sta     ptr1
    sty     ptr1+1

    ldy  #$00
@loop4:    

    lda     str_path_rom,y
    beq     @out
    sta     (ptr1),y
    iny
    bne     @loop4
    
@out:
    sta  (ptr1),y
    
    ldy     #O_RDONLY
    lda     ptr1
    ldx     ptr1+1
    BRK_KERNEL XOPEN

  ;  fopen (ptr1), O_RDONLY

    cpx     #$FF
    bne     @read ; not null then  start because we did not found a conf
    cmp     #$FF
    bne     @read ; not null then  start because we did not found a conf
    PRINT   str_failed
    mfree(ptr1)
    rts
@read:
    sta     fd_systemd
    stx     fd_systemd+1
    mfree(ptr1)

    malloc   512,routine_to_load,str_oom ; [,oom_msg_ptr] [,fail_value]
    ;sta      routine_to_load
   ; sta      routine_to_load_save

    ;sty      routine_to_load+1
    ;sty      routine_to_load_save+1

    malloc 16384,buffer,str_oom ; [,oom_msg_ptr] [,fail_value]
    
    lda     buffer ; We read db version and rom version, and we write it, we avoid a seek to 2 bytes in the file
    sta     PTR_READ_DEST

    lda     buffer+1
    sta     PTR_READ_DEST+1


  ; We read the file with the correct
    lda     #<16384
    ldy     #>16384

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
    ldx     #33
    lda     buffer
    ldy     buffer+1
    jsr     run
    mfree    (buffer)
    mfree    (routine_to_load)
    rts
    
    ;jsr     twil_copy_buffer_to_ram_bank
    ; XMAINARGS

    ; if s, then start : load rom into ram
    ; execute RAM
    ; Call kernel to get

run:
    jmp (routine_to_load)
    rts  
str_failed:
    .byte "..............",$81,"[FAILED]",$0D,$00
str_starting:
    .asciiz "Starting systemd "    
str_path_rom:
    .asciiz "/usr/share/systemd/systemd.rom"    
.endproc

.proc twil_copy_buffer_to_ram_bank
    current_bank:=TR0
    sector_to_update:=TR1
    nb_bytes:=TR2
    tmp1:=TR3
    tmp3:=TR4
    ptr1:=TR5 ; 2 bytes adress of the buffer
    save_bank:= TR7
    
    sta     ptr1
    sty     ptr1+1



    txa
    jsr     _twil_get_registers_from_id_bank
    stx     sector_to_update
    sta     current_bank
    ;



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

    sei


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
    jsr     $c000



@out:
    ldx     save_bank
    stx     VIA2::PRA

    lda     tmp1
    sta     TWILIGHTE_BANKING_REGISTER

    ldx     tmp3
    stx     TWILIGHTE_REGISTER

	lda		#$00
	cli
	rts

.endproc


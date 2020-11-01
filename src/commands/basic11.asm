

.export _basic11

basic11_tmp   := userzp

basic11_ptr1  := userzp+1
basic11_ptr2  := userzp+3

basic11_tmp0  := userzp+5
basic11_tmp1  := userzp+6
basic11_found := userzp+7
basic11_stop  := userzp+8

basic11_fp    := userzp+10
basic11_ptr3  := userzp+12
basic11_ptr4  := userzp+14

.define BASIC11_PATH_DB "/var/cache/basic11/"
.define BASIC11_MAX_MAINDB_LENGTH 10000

.define basic11_sizeof_max_length_of_conf_file_bin .strlen(BASIC11_PATH_DB)+1+1+8+1+2+1 ; used for the path but also for the cnf content

.define basic11_sizeof_binary_conf_file 9 ; Rom + direction + fire1 + fire2 + fire3

.proc _basic11
    COPY_CODE_TO_BOOT_ATMOS_ROM_ADRESS := $200

    ldx     #$01
    jsr     _orix_get_opt
    ; get parameter
    bcc     @start      ; if there is no args, let's start

    lda     ORIX_ARGV
    cmp     #'-'
    bne     @is_a_tape_file_in_arg
    jmp     @basic11_option_management

@is_a_tape_file_in_arg:
    lda     #basic11_sizeof_max_length_of_conf_file_bin
    ldy     #$00
    BRK_KERNEL XMALLOC

    TEST_OOM 

    sta     basic11_ptr1
    sty     basic11_ptr1+1

@no_check_param:

    ldy     #$00
@L2:    
    lda     basic_conf_str,y
    beq     @outcpy
    sta     (basic11_ptr1),y 
    iny
    bne     @L2

@outcpy:


    ; do strcat
    ; get letter
    ldx     #$01      ; skip double quote and get first char
    lda     ORIX_ARGV,x
    sta     (basic11_ptr1),y
    iny
    lda     #'/' ; add /
    sta     (basic11_ptr1),y ; get another letter
   
    iny

@L3:    
    lda     ORIX_ARGV,x
    cmp     #$22 ; " char
    beq     @outstrcat
    cmp     #$00
    beq     @outstrcat
    sta     (basic11_ptr1),y ; get another letter
    iny
    inx     
    bne     @L3
@outstrcat:
    ; concat .db
    lda     #'.'
    sta     (basic11_ptr1),y
    iny
    lda     #'d'
    sta     (basic11_ptr1),y
    iny
    lda     #'b'
    sta     (basic11_ptr1),y    
    iny
    lda     #$00 ; store end of string
    sta     (basic11_ptr1),y    


    ldx     basic11_ptr1+1
    lda     basic11_ptr1


    ldy     #O_RDONLY

    BRK_KERNEL XOPEN ; open current

    cpy     #$00
    bne     @parsecnf ; not null then  start because we did not found a conf
    cmp     #$00
    beq     @noparam_free ; not null then  start because we did not found a conf
    bne     @parsecnf





@noparam:
    ; Get current pwd and open
    BRK_KERNEL XGETCWD  ; Get A & Y 
    sty     basic11_tmp
    ldx     basic11_tmp
    ldy     #O_RDONLY

    BRK_KERNEL XOPEN ; open current

@start:
    sei
    

    ldx     #XVARS_KERNEL_CH376_MOUNT
    BRK_KERNEL XVARS
    sta     basic11_ptr2
    sty     basic11_ptr2+1
    
    ldy     #$00
    lda     (basic11_ptr2),y
    pha

    ; stop t2 from via1
    lda     #$00+32
    sta     VIA::IER
    ; stop via 2
    lda     #$00+32+64
    sta     VIA2::IER

    ldx     #$00
@loop:
    lda     #$00                                    ; FIXME 65C02
    sta     COPY_CODE_TO_BOOT_ATMOS_ROM_ADRESS,x
    lda     @copy,x
    sta     COPY_CODE_TO_BOOT_ATMOS_ROM_ADRESS,x
    dex
    bne     @loop
    lda     #$00                                    ; FIXME 65C02
    sta     $2DF ; Flush keyboard for atmos rom

    ldx     #$05
@copy_rnd_value:    
    lda     basic_rnd_init,x
    sta     $FA,x
    dex
    bpl     @copy_rnd_value

    jmp     COPY_CODE_TO_BOOT_ATMOS_ROM_ADRESS
@copy:
    sei
    pla

    sta     STORE_CURRENT_DEVICE ; For atmos ROM : it pass the current device ()
    lda     #ATMOS_ID_BANK
    sta     VIA2::PRA

    jmp     $F88F ; NMI vector of ATMOS rom
    ; Check if it's a .tap
@noparam_free:

    lda     basic11_ptr1
    ldy     basic11_ptr1+1

    BRK_KERNEL XFREE
    jmp     @start

@parsecnf:
    sta     basic11_fp
    sty     basic11_fp+1

  ; define target address
    lda     #$F1 ; We read db version and rom version, and we write it, we avoid a seek to 2 bytes in the file
    sta     PTR_READ_DEST
    
    lda     #$00
    sta     PTR_READ_DEST+1

  ; We read the file with the correct
    lda     #<basic11_sizeof_binary_conf_file
    ldy     #>basic11_sizeof_binary_conf_file
  ; reads byte 
    BRK_KERNEL XFREAD

    BRK_KERNEL XCLOSE

    ; Close fp
    lda     basic11_fp
    ldy     basic11_fp+1
    BRK_KERNEL XFREE

    ; Let's free
    lda     basic11_ptr1
    ldy     basic11_ptr1+1
    BRK_KERNEL XFREE

    jmp     @load_ROM_in_memory_and_start
    ;jmp     @noparam_free

@basic11_option_management:
    ldx     #$01
    lda     ORIX_ARGV,x
    cmp     #'l'
    bne     @option_not_known
    ; get second ARG
    ldx     #$02
    jsr     _orix_get_opt
 
    lda     #<(.strlen(BASIC11_PATH_DB)+8+4+1)
    ldy     #>(.strlen(BASIC11_PATH_DB)+8+4+1)
    BRK_KERNEL XMALLOC

    sta     basic11_ptr2
    sty     basic11_ptr2+1

    ldy     #$00
@L10:    
    lda     str_basic11_maindb,y
    beq     @S10
    sta     (basic11_ptr2),y
    iny
    bne     @L10
@S10:
    sta     (basic11_ptr2),y

    lda     basic11_ptr2
    ldx     basic11_ptr2+1


    ldy     #O_RDONLY

    BRK_KERNEL XOPEN ; open current
    cpy     #$00
    bne     @read_maindb ; not null then  start because we did not found a conf
    cmp     #$00
    bne     @read_maindb ; not null then  start because we did not found a conf
    
    PRINT   str_basic11_missing
    rts

@option_not_known:
    PRINT   str_basic11_not_known        
    rts


@read_maindb:
    lda     basic11_ptr2
    ldy     basic11_ptr2+1
    BRK_KERNEL XFREE



    lda     #<BASIC11_MAX_MAINDB_LENGTH
    ldy     #>BASIC11_MAX_MAINDB_LENGTH
    BRK_KERNEL XMALLOC

    sta     basic11_ptr1
    sty     basic11_ptr1+1

  ; define target address
    lda     basic11_ptr1 ; We read db version and rom version, and we write it, we avoid a seek to 2 bytes in the file
    sta     PTR_READ_DEST
    
    lda     basic11_ptr1+1
    sta     PTR_READ_DEST+1

  ; We read the file with the correct
    lda     #<BASIC11_MAX_MAINDB_LENGTH
    ldy     #>BASIC11_MAX_MAINDB_LENGTH
  ; reads byte 
    BRK_KERNEL XFREAD

    BRK_KERNEL XCLOSE    

    ; Search now
    PRINT   basic_str_search
    
    lda     ORIX_ARGV
    beq     @displays_all

    ldx     #$00
    ldy     #$00
@L11:    
    lda     (basic11_ptr1),y
    beq     @end_of_line
    cmp     ORIX_ARGV,x
    beq     @found
    cmp     #';' ; Check if end of key
    beq     @end_of_key
    cmp     #$FF 
    beq     @exit
    ; not found
    lda     #$01
    sta     basic11_found
@continue:    
    iny
    bne     @L11
    inc     basic11_ptr1+1
    jmp     @L11
@exit_search:
    PRINT   basic_str_last_line

@exit:
    lda     basic11_ptr1
    ldy     basic11_ptr1+1
    BRK_KERNEL XFREE

    ; Open
    rts
@end_of_line:    
    rts
@end_of_key:
    rts    
@found:
    lda     #$00
    sta     basic11_found
    rts
@displays_all:
    lda     #$01
    sta     basic11_stop ; Define that there is no space bar pressed

    ldx     #$00
    lda     #'|'
    BRK_KERNEL XWR0
    ldy     #$01
@L12:
    BRK_KERNEL XRD0
    bcs     @no_char_action
    pha
    asl     KBDCTC
    bcc     @no_ctrl
    pla
    BRK_KERNEL XCRLF
    rts
@no_ctrl:
    pla
    cmp     #' '
    bne     @no_char
    lda     basic11_stop
    beq     @inv_to_1

    lda     #$00
    sta     basic11_stop
    jmp     @L12

@inv_to_1:
    inc     basic11_stop
    jmp     @L12

@no_char_action:
    lda     basic11_stop
    beq     @L12
    ;bne     @L12
@no_char:    
    lda     (basic11_ptr1),y
    beq     @end_of_line_all
    cmp     #$FF
    beq     @exit_search
    cmp     #';'
    beq     @end_of_key_all
    cpx     #29
    beq     @end_of_line_all
    BRK_KERNEL XWR0
    inx
    
    iny
    bne     @L12
    inc     basic11_ptr1+1
    ldy     #$00
    jmp     @L12

@end_of_line_all:
    cpx     #29
    beq     @next2
    lda     #' '
    BRK_KERNEL XWR0
    inx     
    bne     @end_of_line_all
@next2:
    lda     (basic11_ptr1),y
    beq     @end_of_line_all_column
    iny
    bne     @next2
    inc     basic11_ptr1+1
    jmp     @next2
    ldy     #$FF
@end_of_line_all_column:
    lda     #'|'
    BRK_KERNEL XWR0
    lda     #'|'
    BRK_KERNEL XWR0    
    ldx     #$00
    iny
    bne     @L12
    inc     basic11_ptr1+1
    jmp     @L12

@end_of_key_all:
    cpx     #$08
    beq     @next
    lda     #' '
    BRK_KERNEL XWR0
    inx     
    bne     @end_of_key_all
@next:    
    lda     #'|'
    BRK_KERNEL XWR0
    ldx     #$00
    iny

    jmp     @L12

@load_ROM_in_memory_and_start:

    lda     #<16384 ; size if a rom
    ldy     #>16384
    BRK_KERNEL XMALLOC
    
    TEST_OOM

    sta     basic11_ptr1
    sty     basic11_ptr1+1

    ; Manage path now

    ; copy path
    ldy     #$00
@L100:    
    lda     rom_path,y
    beq     @end_copy
    sta     (basic11_ptr1),y


    iny
    bne     @L100
@end_copy:
    ; Now check if we are in USB or not
    sty     basic11_tmp0  ; Save Y
    iny
    sta     (basic11_ptr1),y
 
    ; Get value
    ldx     #XVARS_KERNEL_CH376_MOUNT
    BRK_KERNEL XVARS
    sta     basic11_ptr2
    sty     basic11_ptr2+1

    ldy     #$00
    lda     (basic11_ptr2),y   ; 
    cmp     #CH376_SET_USB_MODE_CODE_SDCARD
    beq     @sdcard
    ldy     basic11_tmp0
    ; concat 'us' 
    lda     #'u'
    sta     (basic11_ptr1),y
    iny
    lda     #'s'
    sta     (basic11_ptr1),y
    iny
    jmp     @concat_end

@sdcard:
    ldy     basic11_tmp0
    ; concat 'sd' 
    lda     #'s'
    sta     (basic11_ptr1),y
    iny
    lda     #'d'
    sta     (basic11_ptr1),y
    iny
@concat_end:    
    lda     $F2 ; Load id ROM
    clc
    adc     #$30 ; Add '0' to get the right ascii rom
    ; add rom id
    sta     (basic11_ptr1),y
    iny
    ; add .rom
    lda     #'.'
    sta     (basic11_ptr1),y
    iny
    lda     #'r'
    sta     (basic11_ptr1),y
    iny
    lda     #'o'
    sta     (basic11_ptr1),y
    iny
    lda     #'m'
    sta     (basic11_ptr1),y
    iny
    ; Add EOS
    lda     #$00
    sta     (basic11_ptr1),y

   


    lda     basic11_ptr1
    ldx     basic11_ptr1+1
    
    ldy     #O_RDONLY

    BRK_KERNEL XOPEN 
    cpy     #$00
    bne     @read_rom 
    cmp     #$00
    bne     @read_rom 

    ldx     #$04 ; Get kernel ERRNO
    BRK_KERNEL XVARS
    sta     basic11_ptr2
    sty     basic11_ptr2+1

    ldy     #$00
    lda     (basic11_ptr2),y ; FIXME ERRNO
    cmp     #ENOMEM
    bne     @no_enomem_kernel_error
    PRINT   str_enomem

@no_enomem_kernel_error:
    cmp     #ENOENT
    bne     @no_enoent_kernel_error
    PRINT   str_not_found
   ; rts
@no_enoent_kernel_error:    

    PRINT   str_basic11_missing_rom

    ldy     basic11_ptr1+1
    lda     basic11_ptr1

    BRK_KERNEL XWSTR0
    BRK_KERNEL XCRLF

    rts
@read_rom:
    sta     basic11_fp
    sty     basic11_fp+1
 ; define target address
    lda     basic11_ptr1 
    sta     PTR_READ_DEST
    
    lda     basic11_ptr1+1
    sta     PTR_READ_DEST+1

  ; We read the file with the correct
    lda     #<$FFFF
    ldy     #>$FFFF
  ; reads byte 
    BRK_KERNEL XFREAD

    BRK_KERNEL XCLOSE

    lda     basic11_fp
    ldy     basic11_fp+1
    BRK_KERNEL XFREE

    ldy     #$00
    lda     (basic11_ptr2),y
    sta     STORE_CURRENT_DEVICE ; For atmos ROM : it pass the current device ()

    lda     #$00
    sta     basic11_ptr2

    lda     #$C0
    sta     basic11_ptr2+1

    ; Copy the driver
    ; and start
    lda     #<100
    ldy     #>100
    BRK_KERNEL XMALLOC
    
    TEST_OOM

    sta     basic11_ptr3
    sty     basic11_ptr3+1

    ldy     #$00
@L200:
    lda     basic11_driver,y
    sta     (basic11_ptr3),y
    iny
    cpy     #100
    bne     @L200




    ; and start
    lda     basic11_ptr3
    sta     VEXBNK+1
    lda     basic11_ptr3+1
    sta     VEXBNK+2
  
  basic11_ptr3  := userzp+12

    ; stop t2 from via1
    lda     #$00+32
    sta     VIA::IER
    ; stop via 2
    lda     #$00+32+64
    sta     VIA2::IER

    ldx     #$00
    lda     #$00                                    ; FIXME 65C02
@loop12:

    sta     $200,x
    dex
    bne     @loop12


    lda     #$00                                    ; FIXME 65C02
    sta     $2DF ; Flush keyboard for atmos rom

    jsr     prepare_rom_rnd

    jmp     VEXBNK


basic11_driver:
    sei

    lda     #$00 ; RAM bank
    sta     VIA2::PRA

    ldx     #$00
    ldy     #$00
@loop_copy_rom:
    lda     (basic11_ptr1),y
    sta     (basic11_ptr2),y
    iny
    bne     @loop_copy_rom
    inc     basic11_ptr1+1
    inc     basic11_ptr2+1
    inx     
    cpx     #64
    bne     @loop_copy_rom

    ; Let's forge path
    ldx     #$00
    ldy     #tapes_path-basic11_driver
@L300:    
    lda     (basic11_ptr3),y
    beq     @end
    sta     $FE70,x
    iny
    inx
    bne     @L300
@end:    
    sta     $FE70,x
    dex
    stx     $FE6F

    ;$FE6F


    jmp     $F88F ; NMI vector of ATMOS rom
tapes_path:
    .asciiz "/usr/share/basic11/"    


prepare_rom_rnd:

    ldx     #$05
@copy_rnd_value2:    
    lda     basic_rnd_init,x
    sta     $FA,x
    dex
    bpl     @copy_rnd_value2
    rts

str_basic11_missing_rom:
    .asciiz "Missing ROM file : "
rom_path:
    .asciiz "/usr/share/basic11/basic"

str_enomem:
    .byte "Kernel error : Out of Memory",$0D,$0A,$00

str_basic11_not_known:
    .byte "Unknown option",$0D,$0A,$00

str_basic11_missing:
    .byte "Missing file : "
; don't put any other string here, the is no EOS because we earn one byte to displays message error with next path
str_basic11_maindb:
    .byte BASIC11_PATH_DB
    .asciiz "basic11.db"
basic_conf_str:
    .asciiz BASIC11_PATH_DB
basic_str_search:
    .byte  "+--------+-----------------------------+"
    .byte  "|  key   |            NAME             |"
    .byte  "+--------+-----------------------------+",0
basic_str_last_line:
    .byte  "--------+-----------------------------+",0
basic_rnd_init:
    .byte   $80,$4F,$C7,$52,$FF,$FF
.endproc

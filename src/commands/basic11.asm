.export _basic11

.define basic11_color_bar $11

basic11_tmp   := userzp  ; One byte (used in gui)
basic11_ptr1  := userzp+1 ; Two bytes
basic11_ptr2  := userzp+3 ; Two bytes


basic11_saveA           := userzp+5 ; Used in menu
basic11_tmp0            := userzp+5

basic11_gui_key_reached := userzp+6
basic11_tmp1            := userzp+6

basic11_saveY := userzp+7 ; used in menu
basic11_found := userzp+7 ; used in menu
basic11_first_letter := userzp+7 ;

basic11_stop  := userzp+8
basic11_current_parse_software  := userzp+8
basic11_skip_dec  := userzp+8

basic11_fp    := userzp+9

basic11_ptr3  := userzp+11
basic11_mainargs_ptr := userzp+11
 ; Avoid 13 because it's device store offset
basic11_first_letter_gui:= userzp+14

basic11_ptr4 := userzp+15 ; Contains basic11 gui struct
basic11_do_not_display := userzp+17


.define BASIC11_PATH_DB "/var/cache/basic11/"
.define BASIC11_MAX_MAINDB_LENGTH 20000

.define basic11_sizeof_max_length_of_conf_file_bin .strlen(BASIC11_PATH_DB)+1+1+8+1+2+1 ; used for the path but also for the cnf content

.define basic11_sizeof_binary_conf_file 9 ; Rom + direction + fire1 + fire2 + fire3

.proc _basic11
    COPY_CODE_TO_BOOT_ATMOS_ROM_ADRESS := $200
    

    ldx     #$01
    jsr     _orix_get_opt2
    bcc     @no_arg      ; if there is no args, let's start
    ldx     #$01
    jsr     _orix_get_opt2
    
    
   ; BRK_KERNEL XMAINARGS_GETV
   ; sta   basic11_ptr2
   ; sty   basic11_ptr2+1
    ;ldy   #$00
   ; lda   (basic11_ptr2),y


    lda     ORIX_ARGV
    cmp     #'-'
    bne     @is_a_tape_file_in_arg
    jmp     @basic11_option_management
@no_arg:    

    jmp     @start
@is_a_tape_file_in_arg:


    ;malloc basic11_sizeof_max_length_of_conf_file_bin,basic11_ptr1,str_enomem ; Index ptr

    lda     #basic11_sizeof_max_length_of_conf_file_bin
    
    ldy     #$00
    BRK_KERNEL XMALLOC

    TEST_OOM 

    sta     basic11_ptr1
    sty     basic11_ptr1+1

    ;malloc basic11_sizeof_max_length_of_conf_file_bin,basic11_ptr1,str_enomem ; Index ptr

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
    sta     basic11_first_letter

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
    ldx     #$00
@L400:    
    lda     str_dot_db,x
    beq     @out_concat
    sta     (basic11_ptr1),y
    inx
    iny
    bne     @L400
@out_concat:
    sta     (basic11_ptr1),y
  
    ;fopen src, O_RDONLY, TELEMON, ptr1, msg, $EC
    ;fopen file, mode [,TELEMON] [,ptr] [,oom_msg_ptr] [,fail_value]
    ;fopen basic11_ptr1, O_RDONLY, , ptr1, msg, $EC

    fopen (basic11_ptr1), O_RDONLY
    cpx     #$FF
    bne     @parsecnf ; not null then  start because we did not found a conf
    cmp     #$FF
    beq     @noparam_free ; not null then  start because we did not found a conf
    bne     @parsecnf


@start:


    sei
    

    ldx     #XVARS_KERNEL_CH376_MOUNT
    BRK_KERNEL XVARS
    sta     basic11_ptr2
    sty     basic11_ptr2+1
    
    ldy     #$00
    lda     (basic11_ptr2),y
    pha

    jsr     basic11_stop_via


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

    jsr     prepare_rom_rnd

    jmp     COPY_CODE_TO_BOOT_ATMOS_ROM_ADRESS
@copy:
    sei
    pla

    sta     STORE_CURRENT_DEVICE ; For atmos ROM : it pass the current device ()

    ; Crap fix

    lda     #%10110111 ; 0001 0111
    sta     VIA2::DDRA

    lda     #%10110110 
    sta     VIA2::PRA   

    lda     #%00010111
    sta     VIA2::DDRA
    

    lda     VIA2::PRA
    and     #%10100000
    ora     #ATMOS_ID_BANK
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

    ; Close fp
    fclose (basic11_fp)

    ; Let's free
    lda     basic11_ptr1
    ldy     basic11_ptr1+1
    BRK_KERNEL XFREE

    jmp     @load_ROM_in_memory_and_start

@gui:

    jsr     basic11_read_main_dbfile
    cmp     #$FF
    bne     @continuegui
    cpx     #$FF
    bne     @continuegui
    PRINT str_basic11_missing
    rts

@continuegui:
    ; save fp
    
    jmp     basic11_start_gui

@option_not_known:
    PRINT   str_basic11_not_known        
    rts

@basic11_option_management:
    ldx     #$01
    lda     ORIX_ARGV,x
    cmp     #'g'
    beq     @gui

    cmp     #'l'
    bne     @option_not_known
    ; get second ARG
    ldx     #$02
    jsr     _orix_get_opt
 
    jsr     basic11_read_main_dbfile
    cmp     #$FF
    bne     @continue_l_option
    cpy     #$FF
    bne     @continue_l_option
    rts



@continue_l_option:



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
    BRK_KERNEL XMINMA
    BRK_KERNEL XWR0
    inx
    
    iny
    bne     @L12
    inc     basic11_ptr1+1
    ;rts
   ; ldy     #$00
    jmp     @L12


@end_of_line_all:
    cpx     #29
    beq     @next2
    ; Displays a space until we reached the end of line
    lda     #' '
    BRK_KERNEL XWR0
    inx     
    bne     @end_of_line_all
@next2:
    lda     (basic11_ptr1),y
    beq     @end_of_line_all_column
    iny
    bne     @next2
  ;  inc     basic11_ptr1+1
    ;rts
    ;jmp     @next2
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
    ;rts
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
    bne     @L12
    inc     basic11_ptr1+1
    jmp     @L12
; #############################################################
; # Code to load ROM into RAM bank
; #############################################################
@load_ROM_in_memory_and_start:

    malloc 16384,basic11_ptr1,str_enomem ; Index ptr

    ;lda     #<16384 ; size if a rom
    ;ldy     #>16384
    ;BRK_KERNEL XMALLOC
    
;    TEST_OOM

 ;   sta     basic11_ptr1
    ;sty     basic11_ptr1+1

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



    fopen (basic11_ptr1), O_RDONLY
    cpx     #$FF
    bne     @read_rom 
    cmp     #$FF
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
    rts
@no_enomem_kernel_error:
    cmp     #ENOENT
    bne     @no_enoent_kernel_error
   ; PRINT   str_not_found
   ; rts
@no_enoent_kernel_error:    

    PRINT   str_basic11_missing_rom

    ldy     basic11_ptr1+1
    lda     basic11_ptr1

    BRK_KERNEL XWSTR0
    BRK_KERNEL XCRLF

    rts
@read_rom:
    ; We found the rom, now load it
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



    fclose(basic11_fp)
   

    ldy     #$00
    lda     (basic11_ptr2),y
    sta     STORE_CURRENT_DEVICE ; For atmos ROM : it pass the current device ()

    lda     #$00
    sta     basic11_ptr2

    lda     #$C0
    sta     basic11_ptr2+1

    ; Copy the driver
    ; and start

    malloc 100,basic11_ptr3,str_enomem ; Index ptr


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
    jsr     basic11_stop_via


    ldx     #$98 ; to avoid to remove $99 value
    lda     #$00                                    ; FIXME 65C02
@loop12:
    sta     $00
    sta     $200,x
    dex
    bne     @loop12


    lda     #$00                                    ; FIXME 65C02
    sta     $2DF ; Flush keyboard for atmos rom

    jsr     prepare_rom_rnd

    jmp     VEXBNK


basic11_driver:
    sei

    lda     VIA2::PRA
    and     #%11111000
    ;lda     #$00 ; RAM bank
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

    ; If the rom id is equal to 0, it means that it's for the hobbit. 
    ; The hobbit rom does not handle path
    lda     $F2 ; Load id ROM
    beq     @hobbit_rom_do_not_forge_path

    ; Let's forge path
    ldx     #$00
    ldy     #tapes_path-basic11_driver
@L300:    
    lda     (basic11_ptr3),y
    beq     @end
    cmp     #'a'                        ; 'a'
    bcc     @do_not_uppercase
    cmp     #'z'+1                        ; 'z'
    bcs     @do_not_uppercase
    sbc     #$1F
@do_not_uppercase:
    sta     $FE70,x
    iny
    inx
    bne     @L300
@end:

    lda     basic11_first_letter
    sta     $FE70,x




    inx

    lda     #'/'
    sta     $FE70,x

    stx     $FE6F

@hobbit_rom_do_not_forge_path:
    ;$FE6F


    jmp     $F88F ; NMI vector of ATMOS rom

; don't move it because it's used in the copy of basic11_driver
tapes_path:
    .asciiz "/usr/share/basic11/"    

.proc   basic11_read_main_dbfile


    ;
    malloc #(.strlen("/var/cache/basic11/")+8+4+1),basic11_ptr2,str_enomem ; Index ptr

    ldy     #$00
@L10:    
    lda     str_basic11_maindb,y
    beq     @S10
    sta     (basic11_ptr2),y
    iny
    bne     @L10
@S10:
    sta     (basic11_ptr2),y





    fopen (basic11_ptr2), O_RDONLY
    cpx     #$FF
    bne     @read_maindb ; not null then  start because we did not found a conf
    cmp     #$FF
    bne     @read_maindb ; not null then  start because we did not found a conf
    
    PRINT   str_basic11_missing
    BRK_KERNEL XCRLF
    lda     #$FF
    ldx     #$FF
    rts



@read_maindb:
    sta     basic11_fp
    sty     basic11_fp+1

    lda     basic11_ptr2
    ldy     basic11_ptr2+1

    BRK_KERNEL XFREE

    malloc BASIC11_MAX_MAINDB_LENGTH,basic11_ptr1,str_enomem ; Index ptr
    

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
   
    fclose  (basic11_fp)


    lda     #$00 ; OK
    rts
.endproc

.proc prepare_rom_rnd

    ldx     #$05
@copy_rnd_value2:    
    lda     basic_rnd_init,x
    sta     $FA,x
    dex
    bpl     @copy_rnd_value2
    rts
.endproc    

.proc basic11_stop_via
    lda     #$00+32
    sta     VIA::IER
    ; stop via 2
    lda     #$00+32+64
    sta     VIA2::IER
    rts
.endproc    

.include "basic11/basic11_gui.asm"

str_basic11_missing_rom:
    .asciiz "Missing ROM file : "
rom_path:
    .asciiz "/usr/share/basic11/basic"
str_can_not:
    .asciiz "Can not open"
str_enomem:
    .byte "Kernel error : Out of Memory",$0D,$0A,$00
str_dot_db:
    .asciiz ".db"

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

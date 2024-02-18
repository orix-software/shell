.export _basic11
.export _basic10

;; OPTIONS

.define BASIC11_OPTION_DEFAULT_PATH_IS_NOT_SET $00
.define BASIC11_OPTION_DEFAULT_PATH_IS_SET     $01

.define BASIC11_OPTION_ROM_ID_IS_NOT_SET       $00
.define BASIC11_OPTION_ROM_ID_IS_SET           $01

.define BASIC11_MAX_NUMBER_OF_ROM              $03

.define BASIC11_START_GUI                      $01
.define BASIC11_START_LIST                     $02
.define BASIC11_DEFAULT_PATH_SET               $03
.define BASIC11_END_OF_ARGS                    $04
.define BASIC11_SET_ROM                        $05
.define BASIC11_OPTION_UNKNOWN                 $FF

.define BASIC11_NMI_VECTOR                     $F88F
.define BASIC11_OFFSET_ROOT_PATH               $FE70
.define BASIC11_OFFSET_LENGTH_ROOT_PATH        BASIC11_OFFSET_ROOT_PATH-1

.define BASIC10_OFFSET_ROOT_PATH               $FCED
.define BASIC11_OFFSET_FOR_ID_OF_ROM_TO_LOAD   $F2
.define BASIC11_MAX_LENGTH_DEFAULT_PATH        16 ; MAX : 32

.define basic11_color_bar                      $11
.define BASIC11_PATH_DB                        "/var/cache/basic11/"
.define BASIC10_PATH_DB                        "/var/cache/basic10/"
.define BASIC11_MAX_MAINDB_LENGTH              23000
.define basic11_sizeof_max_length_of_conf_file_bin .strlen(BASIC11_PATH_DB)+1+1+8+1+2+1 ; used for the path but also for the cnf content
.define basic11_sizeof_binary_conf_file 9 ; Rom + direction + fire1 + fire2 + fire3

basic11_tmp                     := userzp   ; One byte (used in gui)
basic11_ptr1                    := userzp+1 ; Two bytes
basic11_ptr2                    := userzp+3 ; Two bytes

basic11_saveA                   := userzp+5 ; Used in menu
basic11_tmp0                    := userzp+5

basic11_gui_key_reached         := userzp+6
basic11_tmp1                    := userzp+6

basic11_saveY                   := userzp+7 ; used in menu
basic11_found                   := userzp+7 ; used in menu
basic11_first_letter            := userzp+7 ;

basic11_stop                    := userzp+8
basic11_current_parse_software  := userzp+8
basic11_skip_dec                := userzp+8

basic11_fp                      := userzp+9

basic11_ptr3                    := userzp+11
 ; Avoid 13 because it's device store offset
basic11_first_letter_gui        := userzp+14

basic11_ptr4                    := userzp+15 ; Contains basic11 gui struct
basic11_do_not_display          := userzp+17

basic11_argv_ptr                := userzp+18
basic11_argc                    := userzp+20
basic11_save_pos_arg            := userzp+20
basic11_argv1_ptr               := userzp+21 ; 16 bits

basic11_mode                    := userzp+23 ; 8 bits store if we need to start atmos rom or oric-1
basic11_no_arg_provided         := userzp+24 ; 8 bits store if we need to start atmos rom or oric-1
basic11_option_default_path_set := userzp+26 ; Used when user type "basic11 -p path"
basic11_current_arg_id          := userzp+28 ; One byte
basic11_rootpath_ptr            := userzp + 29 ; Used to save ptr of the path

.define BASIC10_ROM $01
.define BASIC11_ROM $02

.proc _basic10
    lda     #BASIC10_ROM
    sta     basic11_mode   ; Save the mode
    jmp     _basic_main
.endproc

.proc _basic11
    lda     #BASIC11_ROM
    sta     basic11_mode   ; Save the mode
    jmp     _basic_main
.endproc

.proc _basic_main
    COPY_CODE_TO_BOOT_ATMOS_ROM_ADRESS := $200
    ; Set Default ROM
    lda     #$02
    sta     BASIC11_OFFSET_FOR_ID_OF_ROM_TO_LOAD

    lda     #$01
    sta     basic11_current_arg_id

    lda     #$00
    sta     basic11_no_arg_provided

    lda     #BASIC11_OPTION_DEFAULT_PATH_IS_NOT_SET
    sta     basic11_option_default_path_set

    initmainargs basic11_argv_ptr, basic11_argc, 0 ; Get args
    cpx     #$01
    beq     @no_arg

    getmainarg #1, (basic11_argv_ptr) ; Get first arg
    sta     basic11_argv1_ptr
    sty     basic11_argv1_ptr+1

    ldy     #$00

    lda     (basic11_argv1_ptr),y
    cmp     #'-'                     ; is it Dash ?
    bne     @is_a_tape_file_in_arg   ; No we check if a .tape file is provieded
    jmp     @basic11_option_management ; Yes, check options

@no_arg:
    mfree (basic11_argv_ptr)

    lda     basic11_mode
    cmp     #BASIC11_ROM
    beq     @start_rom_in_eeprom
    jmp     @load_ROM_in_memory_and_start

@start_rom_in_eeprom:
    jmp     @start

@is_a_tape_file_in_arg:
    lda     #$01
    sta     basic11_no_arg_provided

    ; Allocating memory to load conf file
    ; FIXME macro

    malloc #basic11_sizeof_max_length_of_conf_file_bin
    cmp     #$00
    bne     @no_oom5
    cpy     #$00
    bne     @no_oom5
    print   str_enomem

    crlf

    lda     #<basic11_sizeof_max_length_of_conf_file_bin
    ldy     #>basic11_sizeof_max_length_of_conf_file_bin

    print_int  ,2, 2 ; an arg is skipped because the number is from register
    rts

@no_oom5:
    sta     basic11_ptr1
    sty     basic11_ptr1+1

    ;malloc basic11_sizeof_max_length_of_conf_file_bin,basic11_ptr1,str_enomem ; Index ptr

@no_check_param:
    ldy     #$00

@L2:
    lda     basic11_mode        ; Is it atmos ?
    cmp     #BASIC11_ROM
    beq     @copy_atmos_db_path   ; Yes copy basic path in atmos path offset
    lda     basic10_conf_str,y    ; Copy db path into ptr
    jmp     @continue_copy_path_db

@copy_atmos_db_path:
    lda     basic_conf_str,y    ; Copy db path into ptr

@continue_copy_path_db:
    beq     @outcpy
    sta     (basic11_ptr1),y
    iny
    bne     @L2

@outcpy:
    ; do strcat
    ; get letter
    sty     basic11_saveY

    ldy     #$01      ; skip double quote and get first char
    lda     (basic11_argv1_ptr),y
    ldx     #$01      ; skip double quote and get first char
    ldy     basic11_saveY

    sta     (basic11_ptr1),y
    sta     basic11_first_letter

    iny
    lda     #'/' ; add /
    sta     (basic11_ptr1),y ; get another letter

    iny

@L3:
    sty     basic11_save_pos_arg
    txa
    tay
    lda     (basic11_argv1_ptr),y
    ldy     basic11_save_pos_arg
    cmp     #'"' ; " char
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
    mfree (basic11_argv_ptr)

    fopen  (basic11_ptr1), O_RDONLY
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

    ; Let's copy BUFEDT
    jsr     copy_bufedt

    ldy     #$00
    lda     (basic11_ptr2),y
    pha

    ; At this step we lost orix management (kernel calls)
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

    ldx     #$00

@L1000:
    lda     code_overlay_switch_sedoric,x
    sta     $477,x
    inx
    cpx     #13
    bne     @L1000

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

@jmp_basic10_vector:
    jmp     $F42D
    ; Check if it's a .tap

@noparam_free:
    mfree (basic11_ptr1)
    jmp     @start

@parsecnf:
    sta     basic11_fp
    sty     basic11_fp+1


  ; define target address
    lda     #$F1 ; We read db version and rom version, and we write it, we avoid a seek to 2 bytes in the file
    sta     PTR_READ_DEST

    lda     #$00
    sta     PTR_READ_DEST+1

    ; FIXME macro

    ; We read the file with the correct
    lda     #<basic11_sizeof_binary_conf_file
    ldy     #>basic11_sizeof_binary_conf_file
    ; reads byte
    ldx     basic11_fp
    BRK_KERNEL XFREAD

    ; Close fp
    fclose (basic11_fp)
    mfree(basic11_ptr1)

    jmp     @load_ROM_in_memory_and_start

@gui:
    mfree (basic11_argv_ptr)
    jsr     basic11_read_main_dbfile
    cmp     #$FF
    bne     @continuegui
    cpx     #$FF
    bne     @continuegui
    print   str_basic11_missing
    rts

@continuegui:
    ; save fp

    jmp     basic11_start_gui

@option_not_known:
    mfree (basic11_argv_ptr)
    print   str_basic11_not_known
    rts

@basic11_option_management:
    jsr     basic11_manage_option_cmdline
    cmp     #BASIC11_START_GUI
    beq     @gui

    cmp     #BASIC11_START_LIST
    beq     @start_list

    cmp     #BASIC11_SET_ROM
    beq     @set_rom

    cmp     #BASIC11_END_OF_ARGS
    beq     @start_rom

    cmp     #BASIC11_DEFAULT_PATH_SET
    beq     @root_path
    bne     @option_not_known

@start_list:
    mfree (basic11_argv_ptr)

    jsr     basic11_read_main_dbfile
    cmp     #$FF
    bne     @continue_l_option
    cpx     #$FF
    bne     @continue_l_option
    print   str_can_not
    rts

@set_rom:
    getmainarg basic11_current_arg_id, (basic11_argv_ptr)
    sta     basic11_ptr2
    sty     basic11_ptr2+1
    ;BASIC11_MAX_NUMBER_OF_ROM
    ldy     #$00
    lda     (basic11_ptr2),y
    beq     @param_empty
    sec
    sbc     #$30

    cmp     #BASIC11_MAX_NUMBER_OF_ROM
    bcc     @set_rom_id
    print   str_rom_not_known
    crlf
    rts

@set_rom_id:
    sta     BASIC11_OFFSET_FOR_ID_OF_ROM_TO_LOAD
    inc     basic11_current_arg_id
    jmp     @basic11_option_management

@root_path:
    getmainarg basic11_current_arg_id, (basic11_argv_ptr)
    sta     basic11_rootpath_ptr
    sty     basic11_rootpath_ptr+1
    ; Checking if the path is less than 32 chars (Atmos rom can't contains more than 32 chars)

    ldy     #$00

@check_path:
    lda     (basic11_rootpath_ptr),y
    beq     @end_check
    iny
    cpy     #BASIC11_MAX_LENGTH_DEFAULT_PATH
    bne     @check_path

    print   str_error_path_too_long
    crlf
    rts

@end_check:
    cpy     #$00
    bne     @path_not_empty

@param_empty:
    print   str_basic11_missing_arg
    crlf
    rts

@path_not_empty:
    lda     #BASIC11_OPTION_DEFAULT_PATH_IS_SET
    sta     basic11_option_default_path_set
    inc     basic11_current_arg_id
    jmp     @basic11_option_management

@start_rom:
    jmp     @load_ROM_in_memory_and_start

@continue_l_option:
    ; Search now
    print   basic_str_search
    jmp     @displays_all

@exit_search:
    print   basic_str_last_line

@exit:
    mfree(basic11_ptr1)

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
    print   #'|'

    ldy     #$01
@L12:
    BRK_KERNEL XRD0
    bcs     @no_char_action
    pha
    asl     KBDCTC
    bcc     @no_ctrl
    pla
    crlf
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

    jmp     @L12

@end_of_line_all:
    cpx     #29
    beq     @next2
    ; Displays a space until we reached the end of line
    print     #' '
    inx
    bne     @end_of_line_all

@next2:
    lda     (basic11_ptr1),y
    beq     @end_of_line_all_column
    iny
    bne     @next2

    ldy     #$FF

@end_of_line_all_column:
    print     #'|'
    print     #'|'
    ldx     #$00
    iny
    bne     @L12
    inc     basic11_ptr1+1
    jmp     @L12

@end_of_key_all:
    cpx     #$08
    beq     @next
    print   #' '
    inx
    bne     @end_of_key_all

@next:
    print     #'|'
    ldx     #$00
    iny
    bne     @L12
    inc     basic11_ptr1+1
    jmp     @L12

; #############################################################
; # Code to load ROM into RAM bank
; #############################################################
@load_ROM_in_memory_and_start:
    malloc #16384, basic11_ptr1 ; Index ptr
    cmp     #$00
    bne     @no_oom
    cpy     #$00
    bne     @no_oom
    print   str_enomem

    lda     #<16384 ; 12
    ldy     #>16384 ; 0 because the number is 12 (from A)
    print_int  ,2, 2 ; an arg is skipped because the number is from register

    crlf
    rts

@no_oom:
    lda     basic11_mode
    cmp     #BASIC11_ROM
    beq     @start_copy_path
    ; For rom oric-1 we force to rom 2 (why because i don't know :) => it's the only rom available :)
    lda     #$02
    sta     BASIC11_OFFSET_FOR_ID_OF_ROM_TO_LOAD

@start_copy_path:
    ; copy path of the root folder
    ldy     #$00

@L100:
    lda     basic11_mode
    cmp     #BASIC10_ROM
    bne     @copy_rom_path

    lda     rom_path_basic10,y
    jmp     @enter_test_eos

@copy_rom_path:
    ; Does user set -p arg ?


@normal_path:
    lda     rom_path,y

@enter_test_eos:
    beq     @end_copy
    sta     (basic11_ptr1),y
    iny
    bne     @L100

@end_copy:
    ; Now check if we are in USB or not
    sty     basic11_tmp0  ; Save Y
    iny
    sta     (basic11_ptr1),y

    ; Get if kernel default is sdcard or usb device
    ldx     #XVARS_KERNEL_CH376_MOUNT
    BRK_KERNEL XVARS
    sta     basic11_ptr2
    sty     basic11_ptr2+1

    ldy     #$00
    lda     (basic11_ptr2),y   ;
    cmp     #CH376_SET_USB_MODE_CODE_SDCARD
    beq     @sdcard
    ; It's usb device, let's load basicusX.rom
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
    lda     BASIC11_OFFSET_FOR_ID_OF_ROM_TO_LOAD ; Load id ROM

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
    print   str_enomem
    rts

@no_enomem_kernel_error:
    cmp     #ENOENT
    bne     @no_enoent_kernel_error
    print   (basic11_ptr1)
    print   str_not_found
    rts

@no_enoent_kernel_error:
    print   str_basic11_missing_rom
    print   (basic11_ptr1)

    crlf

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

    ; FIXME macro
    ; We read the file with the correct
    lda     #<$FFFF
    ldy     #>$FFFF
    ; reads byte
    ldx     basic11_fp
    BRK_KERNEL XFREAD
    fclose(basic11_fp)

    ldy     #$00
    lda     (basic11_ptr2),y
    sta     STORE_CURRENT_DEVICE ; For atmos ROM : it pass the current device ()

    lda     #$00
    sta     basic11_ptr2

    lda     #$C0
    sta     basic11_ptr2+1


@start_with_default_path:
    ; Copy the driver
    ; and start
    ; Allocate memory in order to load copy routine to bank
    malloc 255,basic11_ptr3 ; Index ptr
    cmp     #$00
    bne     @no_oom2
    cpy     #$00
    bne     @no_oom2
    print   str_enomem
    rts

@no_oom2:
    ldy     #$00

@L200:
    lda     basic11_driver,y
    sta     (basic11_ptr3),y
    iny
    cpy     #255
    bne     @L200

    ; and start
    lda     basic11_ptr3
    sta     VEXBNK+1
    lda     basic11_ptr3+1
    sta     VEXBNK+2

    ; stop t2 from via1
    jsr     basic11_stop_via
    ldx     #$98 ; to avoid to remove $99 value (ch376 mount)
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

code_overlay_switch_sedoric:
    .byt $08,$48,$78,$a9,$00,$8d,$21,$03,$68,$28,$60

;*******************************************************
;; This code to

basic11_driver:
    sei
    ldx     #$00

@L1000:
    lda     code_overlay_switch_sedoric,x
    sta     $477,x
    inx
    cpx     #13
    bne     @L1000
    lda     VIA2::PRA
    and     #%11111000
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
    lda     basic11_option_default_path_set
    beq     @manage_others_cases


; Clear BUFEDT when we don't need to insert any tape file
    ldy     #$00
    lda     #$00

@loop_copy_bufedt:
    sta     BUFEDT,y   ; Because we pass to basic ROM the command line
    iny
    bne     @loop_copy_bufedt

; Copy default path into rom path (ram bank)
    ldy     #$00

@copy_rootpath:
    lda     (basic11_rootpath_ptr),y
    beq     @end_start_with_default_path
    cmp     #'a'                          ; 'a'
    bcc     @do_not_uppercase_copy
    cmp     #'z'+1                        ; 'z'
    bcs     @do_not_uppercase_copy
    sbc     #$1F

@do_not_uppercase_copy:
    sta     basic11_tmp
    lda     basic11_mode
    cmp     #BASIC11_ROM
    beq     @forge_path_for_atmos
    lda     basic11_tmp
    sta     BASIC10_OFFSET_ROOT_PATH,y
    bne     @skip_basic11_forge_path

@forge_path_for_atmos:
    lda     basic11_tmp
    sta     BASIC11_OFFSET_ROOT_PATH,y

@skip_basic11_forge_path:
    iny
    bne     @copy_rootpath

@end_start_with_default_path:
    ; Store the length of the string
    sty     BASIC11_OFFSET_LENGTH_ROOT_PATH
    beq     @let_s_start_atmos

@manage_others_cases:
    lda     BASIC11_OFFSET_FOR_ID_OF_ROM_TO_LOAD ; Load id ROM
    beq     @hobbit_rom_do_not_forge_path
    lda     basic11_mode
    cmp     #BASIC11_ROM
    beq     @forge_path
    lda     basic11_no_arg_provided
    beq     @skip_forge_path

@forge_path:
    ; Let's forge path
    ldx     #$00
    lda     basic11_mode
    cmp     #BASIC11_ROM
    beq     @isatmosforpath_tape_path
    ldy     #tapes_path_basic10-basic11_driver
    bne     @L300

@isatmosforpath_tape_path:
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
    sta     basic11_saveA
    lda     basic11_mode
    cmp     #BASIC11_ROM
    beq     @isatmosforpath
    lda     basic11_saveA
    sta     $FCED,x         ; Rootpath for Oric-1
    bne     @continue_path

@isatmosforpath:
    lda     basic11_saveA   ; Rootpath for Atmos
    sta     BASIC11_OFFSET_ROOT_PATH,x

@continue_path:
    iny
    inx
    bne     @L300

@end:
    lda     basic11_mode
    cmp     #BASIC11_ROM
    beq     @isatmos_fix_EOS_and_length

    ; Set path for Oric-1
    lda     basic11_first_letter
    sta     $FCED,x
    inx
    lda     #'/'
    sta     $FCED,x
    stx     $FCEC ; Store length of the path
    bne     @let_s_start

@isatmos_fix_EOS_and_length:
    lda     basic11_first_letter
    sta     BASIC11_OFFSET_ROOT_PATH,x ; We store the into default path, the first letter
    inx
    lda     #'/'
    sta     BASIC11_OFFSET_ROOT_PATH,x
    stx     BASIC11_OFFSET_ROOT_PATH-1 ; Store length of the path

@let_s_start:

@skip_forge_path:

@hobbit_rom_do_not_forge_path:
    ;$FE6F
    ; now copy sedoric code
    lda     basic11_mode
    cmp     #BASIC10_ROM
    beq     @jmp_basic10_vector

@let_s_start_atmos:
    jmp     $F88F ; NMI vector of ATMOS rom

@jmp_basic10_vector:
    jmp     $F42D
end_basic11_driver:


;; this end will be in main memory !!!
;*******************************************************


; don't move it because it's used in the copy of basic11_driver
tapes_path:
    .asciiz "/usr/share/basic11/"

tapes_path_basic10:
    .asciiz "/usr/share/basic10/"

.if     end_basic11_driver-basic11_driver > 254
    .out     .sprintf("Basic11: Size of copy routine = %d", (end_basic11_driver-basic11_driver))
    .error  "Basic11: Size of copy routine us greater than 255. Basic11 will crash"
.endif

copy_bufedt:
    initmainargs basic11_ptr1, basic11_ptr4, 1

    ldy     #$00

@copy_bufedt:
    lda     (basic11_ptr1),y
    beq     @end_copy_bufedt
    sta     BUFEDT,y   ; Because we pass to basic ROM the command line
    iny
    bne     @copy_bufedt

@end_copy_bufedt:
    sta     BUFEDT,y
    rts

.proc   basic11_read_main_dbfile
    ;
    malloc #(.strlen("/var/cache/basic11/")+8+4+1),basic11_ptr2 ; Index ptr

    cmp     #$00
    bne     @no_oom3
    cpy     #$00
    bne     @no_oom3
    print   str_enomem
    rts

@no_oom3:
    ldy     #$00

@L10:
    lda     basic11_mode
    cmp     #BASIC10_ROM
    bne     @isBasic11
    lda     str_basic10_maindb,y
    jmp     @continue

@isBasic11:
    lda     str_basic11_maindb,y

@continue:
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
    print   str_basic11_missing
    crlf
    lda     #$FF
    ldx     #$FF
    rts

@read_maindb:
    sta     basic11_fp
    sty     basic11_fp+1
    mfree(basic11_ptr2)

    malloc BASIC11_MAX_MAINDB_LENGTH,basic11_ptr1 ; Index ptr
    cmp     #$00
    bne     @no_oom4
    cpy     #$00
    bne     @no_oom4
    print   str_enomem
    rts

@no_oom4:
    ; define target address
    lda     basic11_ptr1 ; We read db version and rom version, and we write it, we avoid a seek to 2 bytes in the file
    sta     PTR_READ_DEST

    lda     basic11_ptr1+1
    sta     PTR_READ_DEST+1

    ; FIXME macro
    ; We read the file with the correct
    lda     #<BASIC11_MAX_MAINDB_LENGTH
    ldy     #>BASIC11_MAX_MAINDB_LENGTH
    ; reads byte
    ldx     basic11_fp
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

str_rom_not_known:
    .asciiz "Rom not known"

str_error_path_too_long:
    .byte "Path can not longer than ",.string(BASIC11_MAX_LENGTH_DEFAULT_PATH)," chars",0

str_basic11_missing_rom:
    .asciiz "Missing ROM file : "

str_basic11_missing_arg:
    .asciiz "Missing arg "

rom_path:
    .asciiz "/usr/share/atmos/basic"

rom_path_basic10:
    .asciiz "/usr/share/oric1/basic"

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

basic10_conf_str:
    .asciiz BASIC10_PATH_DB

str_basic10_maindb:
    .byte BASIC10_PATH_DB
    .asciiz "basic10.db"

basic_str_search:
    .byte  "+--------+-----------------------------+"
    .byte  "|  key   |            NAME             |"
    .byte  "+--------+-----------------------------+",0

basic_str_last_line:
    .byte  "--------+-----------------------------+",0

basic_rnd_init:
    .byte   $80,$4F,$C7,$52,$FF,$FF
.endproc

.include "commands/basic11/basic11_manage_option_cmdline.s"

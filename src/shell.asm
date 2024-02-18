;----------------------------------------------------------------------
;                       cc65 includes
;----------------------------------------------------------------------
.include   "telestrat.inc"          ; from cc65
.include   "fcntl.inc"              ; from cc65
.include   "errno.inc"              ; from cc65
.include   "cpu.mac"                ; from cc65

;----------------------------------------------------------------------
;                       Orix Kernel includes
;----------------------------------------------------------------------
.include   "dependencies/kernel/src/include/kernel.inc"
.include   "dependencies/kernel/src/include/process.inc"
.include   "dependencies/kernel/src/include/process.mac"
.include   "dependencies/kernel/src/include/keyboard.inc"
.include   "dependencies/kernel/src/include/memory.inc"
.include   "dependencies/kernel/src/include/files.inc"


;----------------------------------------------------------------------
;                       Orix SDK includes
;----------------------------------------------------------------------
.include   "dependencies/orix-sdk/macros/SDK.mac"
.include   "dependencies/orix-sdk/macros/SDK_print.mac"
.include   "dependencies/orix-sdk/include/SDK.inc"


;----------------------------------------------------------------------
;                   Twilighte board includes
;----------------------------------------------------------------------
.include   "../libs/usr/arch/include/twil.inc"

;----------------------------------------------------------------------
;                           Zero Page
;----------------------------------------------------------------------
userzp                       :=	VARLNG ; $8C don't change VARLNG : there is conflict with systemd rom


bash_struct_ptr              := userzp   ; Struct for shell, when shell start, it malloc a struct 16bits
sh_esc_pressed               := userzp+2

sh_length_of_command_line    := userzp+3 ; Only useful when we are un prompt mode
;tmp1_for_internal_command    :=userzp+3

exec_address                 := userzp+4 ; 2 bytes
ptr1_for_internal_command    := userzp+4

bash_struct_command_line_ptr := userzp+6 ; For compatibility but should be removed (echo, ls)
bash_tmp1                    := userzp+8
sh_ptr_for_internal_command  := userzp+10 ; cd

sh_ptr1                      := userzp+12
sh_history_flag              := userzp+16 ; Used to store the position of the entry of  his history

sh_esc_pressed_at_boot       := userzp+17
fp                           := userzp+18


STORE_CURRENT_DEVICE :=$99

;----------------------------------------------------------------------
;                       Defines / Constants
;----------------------------------------------------------------------

RETURN_BANK_READ_BYTE_FROM_OVERLAY_RAM := $78

.include   "build.inc"
.include   "include/bash.inc"

.ifdef RELEASE_VERSION
    .include   "include/release.inc"
.else
    .include   "include/dev.inc"
.endif

.include   "include/orix.inc"

.define MAGIC_TOKEN_ROM $FFED


;----------------------------------------------------------------------
;                               Shell
;----------------------------------------------------------------------
.org        $C000

.code

.proc start_sh_interactive

        ptr1                    :=  OFFSET_TO_READ_BYTE_INTO_BANK    ; 2 bytes
        current_bank            :=  ID_BANK_TO_READ_FOR_READ_BYTE    ; 1 bytes

        lda     #$01                ; ESC not pressed
        sta     sh_esc_pressed_at_boot

        BRK_KERNEL XRD0 ; primitive exits even if no key had been pressed
        bcs   @no_key_pressed
        ; When a key is pressed, A contains the ascii of the value

@here_a_key_is_pressed:
        dec     sh_esc_pressed_at_boot

@no_key_pressed:

        .out    .sprintf("SHELL: SIZEOF SHELL STRUCT : %s", .string(.sizeof(shell_bash_struct)))

        malloc  .sizeof(shell_bash_struct)

        cpy     #$00
        bne     @no_oom
        cmp     #$00
        bne     @no_oom
        rts
@no_oom:
        ; FIXME test NULL pointer
        sta     bash_struct_ptr
        sty     bash_struct_ptr+1

        ; Init lenght of the comman line
        ldy     #shell_bash_struct::pos_command_line
        lda     #$00
        sta     (bash_struct_ptr),y

    ; ****************************************************************
    ; *                Checking if systemd rom is loaded             *
    ; ****************************************************************

    ; Define that systemd rom is not presnet in order to detect it
        ldy     #shell_bash_struct::systemd_rom_loaded
        lda     #$00
        sta     (bash_struct_ptr),y

        ; Don't remove this line for instance
        ldy     #shell_bash_struct::shell_extension_loaded
        sta     (bash_struct_ptr),y


        lda     #ORIX_ID_BANK       ; Kernel bank
        sta     RETURN_BANK_READ_BYTE_FROM_OVERLAY_RAM

        jsr     detection_bank


@error_loading_shell_extensions:
        ; set lowercase keyboard should be move in telemon bank
        lda     FLGKBD
        and     #%00111111 ; b7 : lowercase, b6 : no sound
        sta     FLGKBD

        ; if it's hot reset, then don't initialize current path.
        bit     FLGRST ; COLD RESET ?

        ; Checking if we have to start /etc/autoboot


        lda     sh_esc_pressed_at_boot
        beq     @do_not_boot_autoboot

        jsr     start_autoboot

@do_not_boot_autoboot:


    loop:
        cursor  on

        lda     #$00
        sta     sh_history_flag

        lda     #ORIX_ID_BANK       ; Kernel bank
        sta     RETURN_BANK_READ_BYTE_FROM_OVERLAY_RAM


        jsr     readline
        beq     loop

        ; Saute les espaces au début de la ligne de commande
        ldy     #$ff
    ltrim:
        iny
        lda     (bash_struct_ptr),y
        beq     exec_cmd

        cmp     #' '
        beq     ltrim

        cmp     #'#' ; Comment ?
        bne     exec_cmd
        jsr     verify_shell_extension_rom_and_launch
        jmp     loop


    exec_cmd:
        ; Si Z=1 alors on a atteint la fin de la ligne
        beq     loop

        ; Ajuste bash_struct_command_line_ptr pour pointer
        ; vers le premier caractère différent de ' '
        lda     bash_struct_ptr+1
        sta     bash_struct_command_line_ptr+1

        tya
        clc
        adc     bash_struct_ptr
        sta     bash_struct_command_line_ptr
        bcc     skip
        inc     bash_struct_command_line_ptr+1

    skip:
        jsr     verify_shell_extension_rom_and_launch

        lda     bash_struct_command_line_ptr
        ldy     bash_struct_command_line_ptr+1
        jsr     _bash

        cmp     #EOK
        beq     loop


        ; lda     bash_struct_command_line_ptr
        ; ldy     bash_struct_command_line_ptr+1
        ; BRK_KERNEL XEXEC
        ldx     #$00
        exec (bash_struct_command_line_ptr)
        jsr     external_cmd
        jmp     loop
.endproc

.proc verify_shell_extension_rom_and_launch

        ldy     #shell_bash_struct::shell_extension_loaded
        lda     (bash_struct_ptr),y
        beq     @shell_extension_not_loaded
        ; Disable for bug : Quannd on lance bootcfg et que cela lance cp, on se retrouve à essayer d'enregister la commande tapée alors que la rom history n'est pas chargée

       ; jsr     register_command_line

        lda     TWILIGHTE_REGISTER
        and     #%11011111  ; Switch to eeprom again
        sta     TWILIGHTE_REGISTER

        lda     $321
        and     #%11111000
        ora     #$05
        sta     $321

        ldx     #$05
        stx     BNKCIB
        stx     VAPLIC
        stx     ID_BANK_TO_READ_FOR_READ_BYTE
        lda     #$00
        sta     TWILIGHTE_BANKING_REGISTER
@shell_extension_not_loaded:
        rts
.endproc

.proc start_autoboot
  ;  rts
    strcpy (bash_struct_ptr), autoboot_path

   ; strncpy (ptr2), (exec_address),#20

    fopen (bash_struct_ptr), O_RDONLY,,fp ; open the filename located in ptr 'basic11_ptr2', in readonly and store the fp in fp address
    cpx     #$FF
    bne     @autoboot_present ; not null then  start because we did not found a conf
    cmp     #$FF
    bne     @autoboot_present ; not null then  start because we did not found a conf
    rts

@autoboot_present:
    fclose(fp)
    print str_starting
    print autoboot_path
    crlf
    strcpy (bash_struct_ptr), autoboot_exec
    ; lda     bash_struct_ptr
    ; ldy     bash_struct_ptr+1
    ; BRK_KERNEL XEXEC
    ldx     #$00
    exec (bash_struct_ptr)

    jsr     external_cmd

    rts
str_starting:
    .asciiz "Starting "
autoboot_path:
    .asciiz "/etc/autoboot"
autoboot_exec:
    .asciiz "submit /etc/autoboot"
.endproc

.proc register_command_line
        rts
        lda     #$00
        sta     TWILIGHTE_BANKING_REGISTER

        lda     #<$c003
        sta     VAPLIC+1
        sta     VEXBNK+1 ; BNK_ADDRESS_TO_JUMP_LOW
        lda     #>$c003
        sta     VAPLIC+2
        sta     VEXBNK+2 ; BNK_ADDRESS_TO_JUMP_HIGH

        ldx     #$02
        stx     BNKCIB

        lda     TWILIGHTE_REGISTER
        ora     #%00100000
        sta     TWILIGHTE_REGISTER

        lda     bash_struct_command_line_ptr
        ldy     bash_struct_command_line_ptr+1

        jmp     EXBNK

.endproc

;----------------------------------------------------------------------
; Pour sh.asm
;----------------------------------------------------------------------
.proc _bash
        sta     RES
        sty     RES+1

    find_command:
        ; Search command
        ; Insert each command pointer in zpTemp02Word
        ldx     #$00

    mloop:
        stx     bash_tmp1
        txa
        asl
        tax
        lda     internal_commands_ptr,x
        sta     RESB
        inx
        lda     internal_commands_ptr,x
        sta     RESB+1


        ldy     #$00
    next_char:
        lda     (RES),y
        cmp     (RESB),y        ; same character?
        beq     no_space

        cmp     #' '             ; space?
        bne     command_not_found

        lda     (RESB),y        ; Last character of the command name?

    no_space:                   ; FIXME
        cmp     #$00            ; Test end of command name or EOL
        beq     command_found

        iny
        bne     next_char

    command_not_found:
        ldx     bash_tmp1
        inx

        cpx     #BASH_NUMBER_OF_COMMANDS_BUILTIN
        bne     mloop

        ; at this step we did not found the command in the rom
        ; not found

        lda     #ENOENT         ; Error
        rts

    command_found:
        ; at this step we found the command from a rom
	    ; bash_tmp1 contains ID of the command

        lda     bash_tmp1                             ; get the id of the command

        ; save zp ptr for shell
        asl
        tax

        lda     internal_commands_addr,x
        sta     exec_address

        inx

        lda     internal_commands_addr,x
        sta     exec_address+1
        jsr     execute_rom_command ; jsr could be avoided but it's the way we use to store EOK to A after command started

        lda     #EOK
        rts

    execute_rom_command:
        jmp     (exec_address)               ; be careful with 6502 bug (jmp xxFF)
.endproc

;----------------------------------------------------------------------
;
;----------------------------------------------------------------------
.proc external_cmd


        cpy    #EOK
        beq    @S20

        cpy    #ENOMEM
        bne    @check_too_many_open_files

        print  str_oom
        ; HCL
        rts

    @check_too_many_open_files:
        cpy    #EMFILE
        bne    @check_i_o_error

        print  str_too_many_open_files

    @S20: ; Used also when all is ok
        ; HCL
        rts

    @check_i_o_error:
        cpy    #EIO
        bne    @check_format_error

        print  str_i_o_error
        ; HCL
        rts

    @check_format_error:
        cpy    #ENOEXEC
        bne    @check_other

        print  str_exec_format_error
        ; HCL
        rts

    @check_other:

    @print_not_found_command:
        ldy    #$00

    @S30:
        lda    (bash_struct_command_line_ptr),y
        beq    @print_not_found

        cmp    #$20
        beq    @print_not_found

        BRK_KERNEL XWR0
        iny
        bne    @S30

    @print_not_found:
        print   str_command_not_found

        ; HCL
        rts
.endproc

;----------------------------------------------------------------------
;
;----------------------------------------------------------------------
.include "readline.s"



;----------------------------------------------------------------------
;
;----------------------------------------------------------------------
.include "shortcut.asm"

;----------------------------------------------------------------------
;
;----------------------------------------------------------------------
.include "detection_bank.s"



;----------------------------------------------------------------------
;
;----------------------------------------------------------------------
internal_commands_str:
.ifdef WITH_CD
cd:
    .asciiz "cd"
.endif

echo:
    .asciiz "echo"

help:
    .asciiz "help"

pwd:
    .asciiz "pwd"



internal_commands_ptr:
.ifdef WITH_CD
    .addr   cd
.endif

.addr   echo
;.addr   exec
.addr   help
.addr   pwd


internal_commands_addr:
.ifdef WITH_CD
    .addr _cd
.endif

.addr _echo
;.addr _exec
.addr _help
.addr _pwd


internal_commands_length:
.ifdef WITH_CD
    .byte 2 ; cd
.endif

.byte 4 ; echo
;.byte 4 ; exec
.byte 4 ; help
.byte 3 ; pwd


.ifdef WITH_CD
    .include "commands/cd.asm"
.endif

.include "commands/echo.asm"
.include "commands/exec.asm"
.include "commands/help.asm"
.include "commands/pwd.asm"
.include "commands/loader.asm"
.include "commands/twiconf.asm"
.include "commands/twilbank.asm"

; Commands
.ifdef WITH_BANK
    .include "commands/banks.asm"
.endif

.ifdef WITH_BASIC11
    .include "commands/basic11.asm"
.endif

.ifdef WITH_CAT
    .include "commands/cat.asm"
.endif

.ifdef WITH_CLEAR
    .include "commands/clear.asm"
.endif

.ifdef WITH_CP ; commented because mv is also include in cp.asm
    .include "commands/cp.asm"
.endif

.include "commands/debug.asm"

.ifdef WITH_DF
    .include "commands/df.asm"
.endif

.ifdef WITH_DATE
    .include "commands/otimer.asm"
.endif

.ifdef WITH_ENV
    .include "commands/env.asm"
.endif


.ifdef WITH_IOPORT
    .include "commands/ioports.asm"
.endif

.ifdef WITH_KILL
    .include "commands/kill.asm"
.endif

.ifdef WITH_LESS
    .include "commands/less.asm"
.endif

.ifdef WITH_LS
    .include "commands/ls.asm"
.endif

.ifdef WITH_LSCPU
    .include "commands/lscpu.asm"
.endif

.ifdef WITH_LSMEM
    .include "commands/lsmem.asm"
.endif

.ifdef WITH_LSOF
    .include "commands/lsof.asm"
.endif

.ifdef WITH_LSPROC
    .include "commands/lsproc.asm"
.endif

.ifdef WITH_MAN
    .include "commands/man.asm"
.endif

.ifdef WITH_MEMINFO
    .include "commands/meminfo.asm"
.endif

.ifdef WITH_MKDIR
    .include "commands/mkdir.asm"
.endif

.ifdef WITH_MOUNT
    .include "commands/mount.asm"
.endif

.ifdef WITH_PS
    .include "commands/ps.asm"
.endif

.ifdef WITH_PSTREE
    .include "commands/pstree.asm"
.endif

.ifdef WITH_REBOOT
    .include "commands/reboot.asm"
.endif

.ifdef WITH_RM
    .include "commands/rm.asm"
.endif

.ifdef WITH_TOUCH
    .include "commands/touch.asm"
.endif


.ifdef WITH_TWILIGHT
    .include "commands/twil.asm"
.endif

.ifdef WITH_TREE
    .include "commands/tree.asm"
.endif

    .include "commands/uname.asm"

.ifdef WITH_SETFONT
    .include "commands/setfont.asm"
.endif

.ifdef WITH_SH
    .include "commands/sh.asm"
.endif

;.ifdef WITH_RESCUE
.include "commands/systemd.asm"
;.endif

.ifdef WITH_WATCH
    .include "commands/watch.asm"
.endif

.ifdef WITH_VIEWHRS
    .include "commands/viewhrs.asm"
.endif



; Functions
.include "lib/strcpy.asm"
.include "lib/trim.asm"
.include "lib/strcat.asm"
.include "lib/strlen.asm"
.include "lib/_clrscr.asm"

; hardware (sh.asm, twil.asm, reboot, mount, ls, df, debug, cat, basic11
.include "lib/ch376.s"
.include "lib/ch376_verify.s"

;----------------------------------------------------------------------
; FIXME common with telemon
;----------------------------------------------------------------------
.proc _lowercase_char
        cmp     #'A' ; 'a'
        bcc     @skip
        cmp     #'[' ; Found by assinie (bug)
        bcs     @skip
        adc     #97-65
    @skip:
        rts
.endproc

;----------------------------------------------------------------------
;
;----------------------------------------------------------------------
.proc _getcpu
        lda     #$00
        .byt    $1A        ; .byte $1A ; nop on nmos, "inc A" every cmos
        cmp     #$01
        bne     @is6502Nmos

    .pushcpu
    .p816
        ; is it 65c816
        xba                     ; .byte $EB, put $01 in B accu (nop on 65C02/65SC02)
        dec     a               ; .byte $3A, A=$00
        xba                     ; .byte $EB, A=$01 if 65816/65802 and A=$00 if 65C02/65SC02
        inc     a               ; .byte $1A, A=$02 if 65816/65802 and A=$01 if 65C02/65SC02
        cmp     #$02
        beq     @isA65C816

        lda     #CPU_65C02       ; it's a 65C02
        rts
    .popcpu

    @isA65C816:
        lda     #CPU_65816
        rts

    @is6502Nmos:
        lda     #CPU_6502
        rts
.endproc

;----------------------------------------------------------------------
; lsmem, debug
;----------------------------------------------------------------------
.proc _print_hexa
        pha
        cputc   '#'
        pla

        BRK_KERNEL XHEXA
        sty     TR7

        BRK_KERNEL XWR0
        lda     TR7
        BRK_KERNEL XWR0
        rts
.endproc

;----------------------------------------------------------------------
; lsmem, debug
;----------------------------------------------------------------------
.proc _print_hexa_no_sharp
        BRK_KERNEL XHEXA
        sty     TR7

        BRK_KERNEL XWR0
        lda     TR7
        BRK_KERNEL XWR0
        rts
.endproc

;----------------------------------------------------------------------
;
;----------------------------------------------------------------------
addr_commands:
; 0
; 1
.ifdef WITH_BANK
    .addr  _banks
.endif
; 0
.ifdef WITH_BASIC10
    .addr  _basic10
.endif

.ifdef WITH_BASIC11
    .addr  _basic11
.endif

; 2
.ifdef WITH_CAT
    .addr  _cat
.endif

; 4
.ifdef WITH_CLEAR
    .addr  _clear ;
.endif
; 5
.ifdef WITH_CP
    .addr  _cp
.endif
; 6

; 7
.ifdef WITH_DEBUG
    .addr  _debug
.endif
; 8
.ifdef WITH_DF
    .addr  _df
.endif
; 9

; 11
.ifdef WITH_ENV
    .addr  _env
.endif

; 17
.ifdef WITH_IOPORT
    .addr  _ioports ;
.endif
; 18
.ifdef WITH_KILL
    .addr  _kill ;
.endif
; 19
.ifdef WITH_LESS
    .addr  _less
.endif

    .addr  _loader
; 20
.ifdef WITH_LS
    .addr  _ls
.endif
; 21
.ifdef WITH_LSCPU
    .addr  _lscpu
.endif
; 22
.ifdef WITH_LSMEM
    .addr  _lsmem
.endif
; 23
.ifdef WITH_LSOF
    .addr  _lsof
.endif
; 24
.ifdef WITH_MAN
    .addr  _man
.endif
; 25
.ifdef WITH_MEMINFO
    .addr  _meminfo
.endif
; 26
.ifdef WITH_MKDIR
    .addr  _mkdir
.endif
; 27
; 28
.ifdef WITH_MV
    .addr  _mv ; is in _cp
.endif
; 29
.ifdef WITH_MOUNT
    .addr  _mount
.endif

; 30

.ifdef WITH_DATE
    .addr  _otimer
.endif

; 32
.ifdef WITH_PS
    .addr  _ps
.endif
; 33
.ifdef WITH_PSTREE
    .addr  _pstree
.endif
; 34

.ifdef WITH_REBOOT
    .addr  _reboot
.endif

.ifdef WITH_RM
    .addr  _rm
.endif

.ifdef WITH_SETFONT
    .addr  _setfont
.endif

.ifdef WITH_SH
    .addr  _sh
.endif

.addr  _systemd

.ifdef WITH_TOUCH
    .addr  _touch
.endif

.ifdef WITH_TREE
    .addr  _tree
.endif

    .addr  _twiconf

.ifdef WITH_TWILIGHT
    .addr  _twil
.endif

    .addr  _uname

.ifdef WITH_VIEWHRS
    .addr  _viewhrs
.endif

.ifdef WITH_WATCH
    .addr  _watch
.endif

addr_commands_end:

.if addr_commands_end-addr_commands > 255
    .error  "Error too many commands, kernel won't be able to start command"
.endif

commands_length:

.ifdef WITH_BANK
    .byt 4 ; _banks
.endif

.ifdef WITH_BASIC10
    .byt 7 ; _basic10
.endif

.ifdef WITH_BASIC11
    .byt 7 ; _basic11
.endif

.ifdef WITH_CAT
    .byt 3 ; _cat
.endif

.ifdef WITH_CA65
    .byt 4 ;ca65
.endif

.ifdef WITH_CLEAR
    .byt 5 ; _clear ;
.endif

.ifdef WITH_CP
    .byt 2 ; _cp
.endif

.ifdef WITH_DATE
    .byt 5 ; _otimer
.endif

.ifdef WITH_DEBUG
    .byt 5 ;_debug
.endif

.ifdef WITH_DF
    .byt 2 ; _df ;
.endif

.ifdef WITH_ENV
    .byt 2 ; _env
.endif

.ifdef WITH_IOPORT
    .byt 7 ; _ioports
.endif

.ifdef WITH_KILL
    .byt 4 ; _kill
.endif

.ifdef WITH_LESS
    .byt 4 ;_less
.endif

    .byt 5 ; _loader

.ifdef WITH_LS
    .byt 2 ; _ls
.endif

.ifdef WITH_LSCPU
    .byt 5 ; lscpu
.endif

.ifdef WITH_LSMEM
    .byt 5 ; lsmem
.endif

.ifdef WITH_LSOF
    .byt 4 ; lsof
.endif

.ifdef WITH_MAN
    .byt 3 ; man
.endif

.ifdef WITH_MEMINFO
    .byt 7 ; meminfo
.endif

.ifdef WITH_MKDIR
    .byt 5 ; _mkdir
.endif

.ifdef WITH_MV
    .byt 2 ; mv
.endif

.ifdef WITH_MOUNT
    .byt 5 ; mount
.endif

.ifdef WITH_PS
    .byt 2 ; ps
.endif

.ifdef WITH_PSTREE
    .byt 6 ; pstree
.endif

.ifdef WITH_REBOOT
    .byt 6 ;_reboot
.endif

.ifdef WITH_RM
    .byt 2 ; rm
.endif

.ifdef WITH_SETFONT
    .byt 7
.endif

.ifdef WITH_SH
    .byt 2 ; sh
.endif

;.ifdef WITH_RESCUE
.byt 7 ; sh
;.endif

.ifdef WITH_TOUCH
    .byt 5 ; touch
.endif

.ifdef WITH_TREE
    .byt 4 ; tree
.endif

    .byt 6 ; _twiconf

.ifdef WITH_TWILIGHT
    .byt 4 ; twil
.endif

    .byt 5 ; _uname


.ifdef WITH_VIEWHRS
    .byt 7 ; viewhrs
.endif

.ifdef WITH_WATCH
    .byt 5 ; watch
.endif

list_of_commands_bank:
; 0
.ifdef WITH_BANK
banks:
    .asciiz "bank"
.endif

.ifdef WITH_BASIC10
basic10:
    .asciiz "basic10"
.endif

.ifdef WITH_BASIC11
basic11:
    .asciiz "basic11"
.endif
; 1

; 2
.ifdef WITH_CAT
cat:
    .asciiz "cat"
.endif
; 3

.ifdef WITH_CLEAR
clear:
    .asciiz "clear"
.endif
; 5
.ifdef WITH_CP
; Because cp & mv are in same file
cp:
    .asciiz "cp"
.endif
; 6

.ifdef WITH_DEBUG
debug:
    .asciiz "debug"
.endif

.ifdef WITH_DF
df:
    .asciiz "df"
.endif

; 10
.ifdef WITH_ENV
env:
    .asciiz "env"
.endif
; 11

; 15
.ifdef WITH_IOPORT
ioports:
    .asciiz "ioports"
.endif
; 16
.ifdef WITH_KILL
kill:
    .asciiz "kill"
.endif
; 17
.ifdef WITH_LESS
less:
    .asciiz "less"
.endif

loader:
    .asciiz "loader"

; 18
.ifdef WITH_LS
ls:
    .asciiz "ls"
.endif

; 19
.ifdef WITH_LSCPU
lscpu:
    .asciiz "lscpu"
.endif
; 20
.ifdef WITH_LSMEM
lsmem:
    .asciiz "lsmem"
.endif
; 21
.ifdef WITH_LSOF
lsof:
    .asciiz "lsof"
.endif
; 22
.ifdef WITH_MAN
man:
    .asciiz "man"
.endif

; 23
.ifdef WITH_MEMINFO
meminfo:
    .asciiz "meminfo"
.endif
; 24
.ifdef WITH_MKDIR
str_mkdir:
    .asciiz "mkdir"
.endif
; 25

; 26
.ifdef WITH_MOUNT
mount:
    .asciiz "mount"
.endif

; 27
.ifdef WITH_MV
mv:
    .asciiz "mv"
.endif

.ifdef WITH_DATE
date:
    .asciiz "otimer"
.endif

; 31
.ifdef WITH_PS
ps:
    .asciiz "ps"
.endif
; 32
.ifdef WITH_PSTREE
pstree:
    .asciiz "pstree"
.endif
; 33

; 34
.ifdef WITH_REBOOT
reboot:
    .asciiz "reboot"
.endif

.ifdef WITH_RM
rm:
    .asciiz "rm"
.endif

.ifdef WITH_SETFONT
setfont:
    .asciiz "setfont"
.endif

.ifdef WITH_SH
sh:
    .asciiz "sh"
.endif

;.ifdef WITH_RESCUE
systemd:
    .asciiz "systemd"

.ifdef WITH_TOUCH
touch:
    .asciiz "touch"
.endif

.ifdef WITH_TREE
tree:
    .asciiz "tree"
.endif

twiconf:
    .asciiz "twiconf"

.ifdef WITH_TWILIGHT
twilight:
    .asciiz "twil"
.endif

uname:
    .asciiz "uname"

.ifdef WITH_VIEWHRS
viewhrs:
    .asciiz "viewhrs"
.endif

.ifdef WITH_WATCH
watch:
    .asciiz "watch"
.endif

.ifdef WITH_CA65
ca65:
    .asciiz "c"
.endif

;----------------------------------------------------------------------
;
;----------------------------------------------------------------------
str_6502:                           ; use for lscpu
    .asciiz "6502"

str_65C02:                          ; use for lscpu
    .asciiz "65C02"

str_cant_execute:
    .asciiz ": is not an Orix file"

str_missing_operand:
    .byte ": missing operand",$0D,$0A,0

; used by uname
str_os:
    .asciiz "Orix"

str_not_found:
    .byte " : No such file or directory",$0D,$0A,0

str_oom:
    .byte     "Out of memory",$0D,$0A,0 ; FIXME

str_too_many_open_files:
    .byte     "Too many open files",$0D,$0A,0

str_i_o_error:
    .byte     "I/O error",$0D,$0A,0

str_exec_format_error:
    .byte     "Exec format error",$0D,$0A,0

str_command_not_found:
    .byte ": command not found",$0a,$0d,0

txt_file_not_found:
    .asciiz "File not found :"

str_max_malloc_reached:
    .asciiz "Max number of malloc reached"

signature:
    .asciiz "Shell v2024.2"

shellext_found:
    .byte "Shell extentions found",$0A,$0D,$00

str_compile_time:
    .byt    __DATE__
    .byt    " "

.IFPC02
cpu_build:
    .asciiz "65C02"
.else
cpu_build_:
    .asciiz "6502"
.endif

end_rom:


;----------------------------------------------------------------------
;
;----------------------------------------------------------------------
.out   .sprintf("Size of ROM : %d bytes", end_rom-$c000)

;.out     .sprintf("kernel_end_of_memory_for_kernel (malloc will start at this adress) : %x", kernel_end_of_memory_for_kernel)

    .res $FFF0-*
    .org $FFF0
.byt 1 ; Command ROM
; $fff1
parse_vector:
    .byt $00,$00
; fff3
signature_adress_commands:
    .addr addr_commands
; fff5-fff6
list_commands:
    .addr list_of_commands_bank
; fff7
number_of_commands:
    .byt BASH_NUMBER_OF_COMMANDS

; fff8-fff9
copyright:
    .word   signature
; fffa-fffb
NMI:
	.word   start_sh_interactive

; fffc-fffd
RESET:
    .word   start_sh_interactive
; fffe-ffff
BRK_IRQ:
    .word   IRQVECTOR

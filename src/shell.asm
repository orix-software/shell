.include   "telestrat.inc"          ; from cc65
.include   "fcntl.inc"              ; from cc65
.include   "errno.inc"              ; from cc65
.include   "cpu.mac"                ; from cc65

.include   "dependencies/kernel/src/include/kernel.inc"
.include   "dependencies/kernel/src/include/process.inc"
.include   "dependencies/kernel/src/include/process.mac"
.include   "dependencies/kernel/src/include/keyboard.inc"
.include   "dependencies/kernel/src/include/memory.inc"
.include   "dependencies/kernel/src/include/files.inc"
.include   "dependencies/twilighte/src/include/io.inc"

;.include   "dependencies/orix-sdk/macros/strnxxx.mac"

bash_struct_ptr              :=userzp ; 16bits
sh_esc_pressed               :=userzp+2
sh_length_of_command_line    :=userzp+3 ; 
exec_address                 :=userzp+4

bash_struct_command_line_ptr :=userzp+6 ; For compatibility but should be removed
bash_tmp1                    :=userzp+8 
sh_ptr_for_internal_command  :=userzp+10
sh_ptr1                      :=userzp+12

STORE_CURRENT_DEVICE :=$99

XEXEC = $63

BASH_NUMBER_OF_USERZP = 8

.include   "build.inc"
.include   "include/bash.inc"

.ifdef RELEASE_VERSION
.include   "include/release.inc"
.else
.include   "include/dev.inc"
.endif

.include   "include/orix.inc"

XGETCWD=$48
XGETCWD_ROUTINE=$48
XPUTCWD_ROUTINE=$49

RETURN_BANK_READ_BYTE_FROM_OVERLAY_RAM := $78

.org        $C000
.code

start_sh_interactive:

.out     .sprintf("SHELL: SIZEOF SHELL STRUCT : %s", .string(.sizeof(shell_bash_struct)))

    MALLOC .sizeof(shell_bash_struct)

    ; FIXME test NULL pointer
    sta    bash_struct_ptr
    sty    bash_struct_ptr+1



    lda    #$00
    ldy    #shell_bash_struct::command_line
    sta    (bash_struct_ptr),y
    


    ; set lowercase keyboard should be move in telemon bank
    lda     FLGKBD
    and     #%00111111 ; b7 : lowercase, b6 : no sound
    sta     FLGKBD

    ; if it's hot reset, then don't initialize current path.
    BIT     FLGRST ; COLD RESET ?
    bpl     start_prompt	; yes


;****************************************************************************/
start_prompt_and_jump_a_line:

start_prompt:
    lda     #$00
    sta     sh_esc_pressed

.IFPC02
.pc02
    stz    sh_length_of_command_line               ; Used to store the length of the command line
    stz    ORIX_ARGV
    lda    #$00
    ldy    #shell_bash_struct::command_line
    sta    (bash_struct_ptr),y

    ldy    #shell_bash_struct::pos_command_line
    sta    (bash_struct_ptr),y
    
.p02    
.else
    lda    #$00
    sta    sh_length_of_command_line               ; Used to store the length of the command line
    sta    ORIX_ARGV            ; argv buffer
    lda    #$00
    ldy    #shell_bash_struct::command_line
    sta    (bash_struct_ptr),y
    ldy    #shell_bash_struct::pos_command_line
    sta    (bash_struct_ptr),y
.endif	


display_prompt:

sh_switch_on_prompt:

    ; Displays current path
    BRK_KERNEL XGETCWD

    BRK_KERNEL XWSTR0
    
    BRK_KERNEL XECRPR           ; display prompt (# char)
    SWITCH_ON_CURSOR

start_commandline:
    lda     #ORIX_ID_BANK    ; Kernel bank
    sta     RETURN_BANK_READ_BYTE_FROM_OVERLAY_RAM

    BRK_KERNEL XRDW0            ; read keyboard

    cmp     #KEY_LEFT
    beq     start_commandline    ; left key not managed
    cmp     #KEY_RIGHT
    beq     start_commandline    ; right key not managed
    cmp     #KEY_UP
    beq     start_commandline    ; up key not managed
    cmp     #KEY_DOWN
    beq     start_commandline    ; down key not managed
    cmp     #KEY_RETURN          ; is it enter key ?
    bne     @next_key             ; no we display the char

    ldx     sh_length_of_command_line               ; no command ?
    bne     @sh_launch_command ; yes it's an empty line
    RETURN_LINE
    jmp     start_prompt


@function_key:


@next_key:
    cmp     #KEY_DEL             ; is it del pressed ?
    beq     @key_del_routine      ; yes let's remove the char in the BUFEDT buffer
    cmp     #KEY_ESC                   ; ESC key not managed, but could do autocompletion (Pressed twice)
    beq     @key_esc_routine 

    ldx     sh_length_of_command_line  ; get the length of the current line
    cpx     #BASH_MAX_LENGTH_COMMAND_LINE-1 ; do we reach the size of command line buffer ?
    beq     start_commandline    ; yes restart command line until enter or del keys are pressed, but
    BRK_KERNEL XWR0             ; write key on the screen (it's really a key pressed

    pha
    ldy    #shell_bash_struct::pos_command_line
    ; inc a
    lda    (bash_struct_ptr),y
    sec
    sta    (bash_struct_ptr),y

    txa
    clc
    adc     #shell_bash_struct::command_line
    tay
    pla
    sta    (bash_struct_ptr),y
    iny

    ldx     sh_length_of_command_line               ; get the position on the command line
    inx                          ; increase by 1 the current position in the command line buffer
    stx     sh_length_of_command_line
  
.IFPC02
.pc02         
    
    sta    (bash_struct_ptr),y
.p02    
.else
    lda     #$00
    sta    (bash_struct_ptr),y
.endif		

    jmp     start_commandline    ; and loop interpreter




@key_esc_routine:
    ldx     sh_esc_pressed
    bne     @sh_launch_autocompletion
    inx
    stx     sh_esc_pressed
    jmp     start_commandline

@key_del_routine:
    ldx     sh_length_of_command_line    ; load the length of the command line buffer
    beq     send_oups_and_loop   ; command line is empty send oups sound
    dex                          ; command line is NOT empty, remove last char in the buffer
    
    txa
    clc
    adc    #shell_bash_struct::command_line
    tay

    lda    #$00                 ; remove last char FIXME 65c02
    sta    (bash_struct_ptr),y
    stx    sh_length_of_command_line               ; and store the length

    ldy    #shell_bash_struct::pos_command_line
    lda    (bash_struct_ptr),y
    tax
    dex
    txa
    sta    (bash_struct_ptr),y

    SWITCH_OFF_CURSOR
    dec     SCRX                 ; go one step to the left on the screen

    SWITCH_ON_CURSOR

; no_action
    jmp     start_commandline    ; and restart 


@sh_launch_command:    
    RETURN_LINE
    ldy    bash_struct_ptr+1

    lda    bash_struct_ptr

    clc
    adc    #shell_bash_struct::command_line
    bcc    @S7
    iny
@S7:
    sta    bash_struct_command_line_ptr
    sty    bash_struct_command_line_ptr+1  ; should be removed when orix_get_opt will be removed

    jsr    _bash
    cmp    #EOK
    bne    @call_xexec
    jmp    start_prompt
@call_xexec:   

    lda    bash_struct_command_line_ptr
    ldy    bash_struct_command_line_ptr+1  ; should be removed when orix_get_opt will be removed
    jsr    ltrim ; Trim

    lda    bash_struct_command_line_ptr
    ldy    bash_struct_command_line_ptr+1  ; should be removed when orix_get_opt will be removed

    BRK_KERNEL XEXEC
    cmp    #EOK
    beq    @S20
    ; display error
    ;cmp    #ENOENT 
    ;bne    @print_not_found_command
    ;PRINT  str_impossible_to_mount_sdcard
    ;jmp     start_prompt

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
    PRINT   str_command_not_found
@S20:    
    jmp     start_prompt

@sh_launch_autocompletion:
    RETURN_LINE
    jsr     _ls
    ldx     #$00
    stx     sh_esc_pressed
    jmp     sh_switch_on_prompt


send_oups_and_loop:
    BRK_KERNEL XOUPS
    jmp     start_commandline


; Key left
@key_left_routine:
    ;adc    #shell_bash_struct::command_line
    ;    sta    (bash_struct_ptr),y
    ldy    #shell_bash_struct::pos_command_line
    ; dec a
    lda    (bash_struct_ptr),y
    beq    @out_key_left
    tax
    dex
    txa
    sta    (bash_struct_ptr),y

    SWITCH_OFF_CURSOR

    ldy      #$00
    lda     (ADSCR),y
    sta     CURSCR
    dec     SCRX
    SWITCH_ON_CURSOR
@out_key_left:
    jmp     start_commandline





.proc _bash
    sta     RES
    sty     RES+1

    ldy     #$00
@loop:
    lda     (RES),y
    cmp     #' '
    bne     no_more_space 
    iny
    cpy     #BASH_MAX_LENGTH_COMMAND_LINE
    bne     @loop
no_command:
    rts 
no_more_space:
    cmp     #$00
    beq     no_command   ;  "     ",0 on command line


find_command:
    ; Search command
    ; Insert each command pointer in zpTemp02Word
    ;ldx     #$01
    ;jsr     _orix_get_opt
  
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
    ; jmp     orix_try_to_find_command_in_bin_path
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



; [IN] X get the id of the parameter

; Return in AY the ptr of the parameter

.proc ltrim


    sta     sh_ptr1
    sty     sh_ptr1+1
restart_test_space:     
    ldy     #$00
   
    lda     (sh_ptr1),y
    cmp     #' '
    beq     trimme
    rts
loop:
.IFPC02
.pc02
    bra     restart_test_space  
.p02    
.else
    jmp     restart_test_space  
.endif  
trimme:
    iny ; 1
    lda     (sh_ptr1),y
    beq     @out
    dey ; 0
    sta     (sh_ptr1),y
    iny ;1 
    jmp     trimme
@out:    
    dey
    sta     (sh_ptr1),y
    jmp     restart_test_space

.endproc
; This routine is used to read into /bin directory, and tries to open a binary, if it's Not ok it return in A and X $ffff

.proc sh_function_key
    lda #$11
    sta $bb80
    rts
.endproc



str_oom:
  .byte     "Out of memory",$0D,$0A,0 ; FIXME

internal_commands_str:
.ifdef WITH_CD
cd:
.asciiz "cd"
.endif

echo:
.asciiz "echo"
;exec:
;.asciiz "exec"
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
.include "commands/date.asm"
.endif

.ifdef WITH_ENV
.include "commands/env.asm"
.endif

.ifdef WITH_HISTORY
.include "commands/history.asm"
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

.ifdef WITH_OCONFIG
.include "commands/oconfig.asm"
.endif

.ifdef WITH_ORICSOFT
.include "commands/oricsoft.asm"
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

.ifdef WITH_SEDSD
.include "commands/sedsd.asm"
.endif

.ifdef WITH_TOUCH
.include "commands/touch.asm"
.endif

.ifdef WITH_TELNETD
.include "commands/telnetd.asm"
.endif

.ifdef WITH_TWILIGHT
.include "commands/twil.asm"
.endif

.ifdef WITH_TREE
.include "commands/tree.asm"
.endif

.ifdef WITH_UNAME
.include "commands/uname.asm"
.endif

.ifdef WITH_SETFONT
.include "commands/setfont.asm"
.endif

.ifdef WITH_SH
.include "commands/sh.asm"
.endif

.ifdef WITH_WATCH
.include "commands/watch.asm"
.endif

.ifdef WITH_VI
.include "commands/vi.asm"
.endif

.ifdef WITH_VIEWHRS
.include "commands/viewhrs.asm"
.endif

.ifdef WITH_XORIX
.include "commands/xorix.asm"
.endif

; Functions

.include "lib/strcpy.asm"
.include "lib/trim.asm"
.include "lib/strcat.asm"
.include "lib/strlen.asm"
.include "lib/fread.asm"
.include "lib/get_opt.asm"
; hardware
.include "lib/ch376.s"
.include "lib/ch376_verify.s"


_cd_to_current_realpath_new:
    BRK_KERNEL XGETCWD ; Return A and Y the string
    sty     TR6
    ;pha
    ;sta     RES
    ;sty     RES+1

;    ldy     #$00
;@myloop:    
    ;lda     (RES),y
    ;beq     @out
    ;sta     $bb80,y
    ;iny
    ;bne     @myloop

;@out:
    ;pla


    ldy     #O_RDONLY
    ldx     TR6
    BRK_KERNEL XOPEN
    cmp     #NULL
    bne     @free
    
    cpy     #NULL
    bne     @free    
    rts
    ; get A&Y
@free:
    BRK_KERNEL XFREE
    rts

; FIXME common with telemon
  
.proc _lowercase_char
    cmp     #'A' ; 'a'
    bcc     @skip
    cmp     #'[' ; Found by assinie (bug)
    bcs     @skip 
    ADC     #97-65
@skip:
    rts
.endproc    


.proc _XREAD
	
; [IN] AY contains the length to read
; [IN] PTR_READ_DEST must be set because it's the ptr_dest
; [IN] TR0 contains the fd id 

; [OUT]  PTR_READ_DEST updated
; [OUT]  A could contains 0 or the CH376 state
; [OUT]  Y contains the last size of bytes 

; [UNCHANGED] X

  jsr     _ch376_set_bytes_read
continue:
  cmp     #CH376_USB_INT_DISK_READ  ; something to read
  beq     readme
  cmp     #CH376_USB_INT_SUCCESS    ; finished
  beq     finished 
  ; TODO  in A : $ff X: $ff
  lda     #$00
  tax
  rts
readme:
  jsr     we_read

  lda     #CH376_BYTE_RD_GO
  sta     CH376_COMMAND
  jsr     _ch376_wait_response

.IFPC02
.pc02
  bra     continue
.p02
.else 
  jmp     continue
.endif    

finished:
  ; at this step PTR_READ_DEST is updated
  rts	

we_read:
  lda     #CH376_RD_USB_DATA0
  sta     CH376_COMMAND

  lda     CH376_DATA                ; contains length read
  beq     finished                  ; we don't have any bytes to read then stops (Assinie report)
  sta     TR0                       ; Number of bytes to read, storing this value in order to loop

  ldy     #$00
loop:
  lda     CH376_DATA                ; read the data
  sta     (PTR_READ_DEST),y         ; send data in the ptr address
  iny                               ; inc next ptr addrss
  cpy     TR0                       ; do we read enough bytes
  bne     loop                      ; no we read
  
  tya                               ; We could do "lda TR0" but TYA is quicker. Add X bytes to A in order to update ptr (Y contains the size of the bytes reads)
  clc                               ; 
  adc     PTR_READ_DEST
  bcc     next
  inc     PTR_READ_DEST+1
next:
  sta     PTR_READ_DEST
  rts
.endproc

.proc _getcpu
    lda     #$00
    .byt    $1A        ; .byte $1A ; nop on nmos, "inc A" every cmos
    cmp     #$01
    bne     @is6502Nmos
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
@isA65C816:
    lda     #CPU_65816
    rts
@is6502Nmos:
    lda     #CPU_6502
    rts
.endproc


    


_print_hexa:
    pha
    CPUTC '#'
    pla

    BRK_KERNEL XHEXA
    sty TR7
    
    BRK_KERNEL XWR0
    lda TR7
    BRK_KERNEL XWR0
    rts
   

_print_hexa_no_sharp:

    BRK_KERNEL XHEXA
    sty TR7
    
    BRK_KERNEL XWR0
    lda TR7
    BRK_KERNEL XWR0
    rts   

addr_commands:
; 0
.ifdef WITH_BASIC11
    .addr  _basic11
.endif    
; 1
.ifdef WITH_BANK    
    .addr  _banks
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
.ifdef WITH_DATE
    .addr  _date 
.endif    
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

; 16	
.ifdef WITH_HISTORY
    .addr  _history
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
.ifdef WITH_OCONFIG
    .addr  _oconfig
.endif
; 31
.ifdef WITH_ORICSOFT
    .addr  _oricsoft
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

.ifdef WITH_SEDSD
    .addr  _sedsd
.endif     
    
.ifdef WITH_SETFONT
    .addr  _setfont
.endif

.ifdef WITH_SH
    .addr  _sh
.endif 

.ifdef WITH_TELNETD
    .addr  _telnetd
.endif

.ifdef WITH_TOUCH
    .addr  _touch
.endif

.ifdef WITH_TREE
    .addr  _tree
.endif

.ifdef WITH_TWILIGHT
    .addr  _twil
.endif

.ifdef WITH_UNAME
    .addr  _uname
.endif    
    
.ifdef WITH_VI
    .addr  _vi
.endif

.ifdef WITH_VIEWHRS
    .addr  _viewhrs
.endif    

.ifdef WITH_WATCH
    .addr  _watch
.endif    
    
.ifdef WITH_XORIX
    .addr  _xorix
.endif	
addr_commands_end:

.if     addr_commands_end-addr_commands > 255
  .error  "Error too many commands, kernel won't be able to start command"
.endif


commands_length:
.ifdef WITH_BASIC11
    .byt 7 ; _basic11
.endif    

.ifdef WITH_BANK
    .byt 4 ; _banks
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
    .byt 4 ; _date 
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

.ifdef WITH_HISTORY
    .byt 7 ; history
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

.ifdef WITH_OCONFIG
    .byt 7 ; oconfig
.endif

.ifdef WITH_ORICSOFT
    .byt 7 ; oricsoft
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

.ifdef WITH_SEDSD
    .byt 7
.endif     

.ifdef WITH_SETFONT
    .byt 7
.endif    

.ifdef WITH_SH
    .byt 2 ; sh
.endif   

.ifdef WITH_TELNETD
    .byt 7 ; telnetd
.endif

.ifdef WITH_TOUCH
    .byt 5 ; touch
.endif

.ifdef WITH_TREE
    .byt 4 ; tree
.endif

.ifdef WITH_TWILIGHT
    .byt 4 ; touch
.endif

.ifdef WITH_UNAME
    .byt 5 ;_uname
.endif    
    
.ifdef WITH_VI
    .byt 2  ; vi
.endif

.ifdef WITH_VIEWHRS
    .byt 7  ; viewhrs
.endif    

.ifdef WITH_WATCH
    .byt 5  ; viewhrs
.endif    

.ifdef WITH_XORIX
    .byt 5 ;xorix
.endif	    

list_of_commands_bank:
; 0
.ifdef WITH_BASIC11    
basic11:
    .asciiz "basic11"
.endif    
; 1
.ifdef WITH_BANK    
banks:
    .asciiz "bank"
.endif    
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
.ifdef WITH_DATE    
date:
    .asciiz "date"
.endif    

.ifdef WITH_DEBUG
debug:
    .asciiz "debug"
.endif    

; 7

.ifdef WITH_DF    
df:
    .asciiz "df"
.endif    
; 8

; 9

; 10
.ifdef WITH_ENV    
env:
    .asciiz "env"
.endif  
; 11

.ifdef WITH_HISTORY
history:
    .asciiz "history"
.endif    
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
mkdir:
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
; 28   
.ifdef WITH_OCONFIG
oconfig:
    .asciiz "oconfig"
.endif     
; 29
.ifdef WITH_ORICSOFT
oricsoft:
    .asciiz "oricsft"
.endif      
; 30

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

.ifdef WITH_SEDORIC
sedoric:
    .asciiz "sedoric"
.endif

.ifdef WITH_SETFONT
setfont:
    .asciiz "setfont"
.endif

.ifdef WITH_SH
sh:
    .asciiz "sh"
.endif

.ifdef WITH_TELNETD
telnetd:
    .asciiz "telnetd"
.endif    

.ifdef WITH_TOUCH    
touch:
    .asciiz "touch"
.endif    

.ifdef WITH_TREE
tree:
    .asciiz "tree"
.endif    

.ifdef WITH_TWILIGHT
twilight:
    .asciiz "twil"
.endif   

.ifdef WITH_UNAME
uname:
    .asciiz "uname"
.endif

.ifdef WITH_VI
vi:
    .asciiz "vi"
.endif

.ifdef WITH_VIEWHRS
viewhrs:
    .asciiz "viewhrs"
.endif

.ifdef WITH_WATCH
watch:
    .asciiz "watch"
.endif

.ifdef WITH_XORIX
xorix:
    .asciiz "xorix"
.endif

.ifdef WITH_CA65
ca65:
    .asciiz "c"
.endif

str_impossible_to_mount_sdcard:
    .asciiz "Impossible to mount sdcard"

str_6502:                           ; use for lscpu
    .asciiz "6502"
str_65C02:                          ; use for lscpu
    .asciiz "65C02"

str_cant_execute:
    .asciiz ": is not an Orix file"
str_not_found:
    .byte " : No such file or directory",$0D,$0A,0
str_missing_operand:
    .byte ": missing operand",$0D,$0A,0
; used by uname
str_os:
    .asciiz "Orix"
str_command_not_found:
    .byte ": command not found",$0a,$0d,0
txt_file_not_found:
    .asciiz "File not found :"
str_out_of_memory:
    .asciiz "Out of Memory"      
str_max_malloc_reached:
    .asciiz "Max number of malloc reached"

signature:
    .asciiz  "Shell v2020.4"
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
    .include "tables/text_first_line_adress.asm"  
; .include "tables/malloc_table.asm"  

    .res $FFF1-*
    .org $FFF1
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

	

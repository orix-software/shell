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

exec_address              :=userzp
sh_esc_pressed            :=userzp+2
sh_length_of_command_line :=userzp+3 ; 
bash_struct_ptr           := userzp+4 ; 16bits
bash_struct_command_line_ptr :=userzp+6 ; For compatibility but should be removed


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

    MALLOC .sizeof(shell_bash_struct)

    ; FIXME test NULL pointer
    sta    bash_struct_ptr
    sty    bash_struct_ptr+1



    lda    #$00
    ldy    #shell_bash_struct::command_line
    sta    (bash_struct_ptr),y
    

    lda     #$00
    sta     STACK_BANK
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
    BRK_TELEMON XRDW0            ; read keyboard
   ; bmi     start_commandline    ; don't receive any specials chars (that is the case when funct key is used : it needs to be fixed in bank 7 in keyboard management

    cmp     #KEY_LEFT
    beq     @key_left_routine    ; left key not managed
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

@sh_launch_command:    
    
    ldy    bash_struct_ptr+1

    lda    bash_struct_ptr

    clc
    adc    #shell_bash_struct::command_line
    bcc    @S7
    iny
@S7:
    sta    bash_struct_command_line_ptr
    sty    bash_struct_command_line_ptr+1  ; should be removed when çorix_get_opt will be

    jsr     _bash                ; and launch interpreter
    jmp     start_prompt

@function_key:


@next_key:
    cmp     #KEY_DEL             ; is it del pressed ?
    beq     key_del_routine      ; yes let's remove the char in the BUFEDT buffer
    cmp     #KEY_ESC                   ; ESC key not managed, but could do autocompletion (Pressed twice)
    beq     @key_esc_routine 

    ldx     sh_length_of_command_line  ; get the length of the current line
    cpx     #BASH_MAX_BUFEDT_LENGTH-1 ; do we reach the size of command line buffer ?
    beq     start_commandline    ; yes restart command line until enter or del keys are pressed, but
    BRK_TELEMON XWR0             ; write key on the screen (it's really a key pressed

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
   ; ldx     SCRX
   ; lda     CURSCR
    ldy      #$00
    lda     (ADSCR),y
    sta     CURSCR
    dec     SCRX
    SWITCH_ON_CURSOR
@out_key_left:
    jmp     start_commandline

@key_esc_routine:
    ldx     sh_esc_pressed
    bne     @sh_launch_autocompletion
    inx
    stx     sh_esc_pressed
    jmp     start_commandline
@sh_launch_autocompletion:
    RETURN_LINE
    jsr     _ls
    ldx     #$00
    stx     sh_esc_pressed
    jmp     sh_switch_on_prompt

key_del_routine:
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
    ; dec a
    lda    (bash_struct_ptr),y
    tax
    dex
    txa
    sta    (bash_struct_ptr),y

    SWITCH_OFF_CURSOR
    dec     SCRX                 ; go one step to the left on the screen

    SWITCH_ON_CURSOR

no_action:
    jmp     start_commandline    ; and restart 

send_oups_and_loop:
    BRK_KERNEL XOUPS
    jmp     start_commandline

.proc _bash

    sta     RES
    sty     RES+1


    jsr     ltrim               ; ltrim command line

    ;  Looking if it request ./ : it means that user want to load and execute
    ldy     #$00
@loop:
    lda     (RES),y
    cmp     #' '
    bne     no_more_space 
    iny
    cpy     #BASH_MAX_BUFEDT_LENGTH
    bne     @loop
no_command:
    rts 
no_more_space:
    cmp     #$00
    beq     no_command   ;  "     ",0 on command line


find_command:
    ; Search command
    ; Insert each command pointer in zpTemp02Word
    ldx     #$01
    jsr     _orix_get_opt
  
    ldx     #$00
mloop:
    lda     list_command_low,x
    sta     RESB
    lda     list_command_high,x
    sta     RESB+1  
  
  
    ldy     #$00
next_char:
    lda     (RES),y
    cmp     (RESB),y        ; same character?
    beq     no_space
    cmp     #' '             ; space?
    bne     command_not_found
    lda     (RESB),Y        ; Last character of the command name?
no_space:                   ; FIXME
    cmp     #$00            ; Test end of command name or EOL
    beq     command_found
    iny
    bne     next_char
 
command_not_found:

    inx
    cpx     #BASH_NUMBER_OF_COMMANDS 
    bne     mloop
    ; at this step we did not found the command in the rom

    jmp     orix_try_to_find_command_in_bin_path
command_found:
    ; at this step we found the command from a rom
	; X contains ID of the command
	; Y contains the position of the BUFEDT
    stx     TR7                             ; save the id of the command

    ; save zp ptr for shell

    RETURN_LINE                             ; jump a line
    
    lda     TR7                             ; get the id of the command
    asl
    tax

    lda     addr_commands,x
    sta     exec_address

    inx	

    lda     addr_commands,x
    sta     exec_address+1


    JMP     (exec_address)               ; be careful with 6502 bug (jmp xxFF)
.endproc



; [IN] X get the id of the parameter

; Return in AY the ptr of the parameter

.proc ltrim

restart_test_space:
    ldy     #$00
    lda     (RES),y
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
    lda     (RES),y
    dey ; 0
    sta     (RES),y
    iny ;1 
    lda     (RES),y
    beq     loop
    bne     trimme

    rts
.endproc
; This routine is used to read into /bin directory, and tries to open a binary, if it's Not ok it return in A and X $ffff

.proc sh_function_key
    lda #$11
    sta $bb80
    rts
.endproc



str_oom:
  .byte     "Out of memory",$0D,$0A,0 ; FIXME

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

.ifdef WITH_CD
.include "commands/cd.asm"
.endif

.ifdef WITH_CLEAR
.include "commands/clear.asm"
.endif

;.ifdef WITH_CP ; commented because mv is also include in cp.asm
.include "commands/cp.asm"
;.endif

.ifdef WITH_DF
.include "commands/df.asm"
.endif

.ifdef WITH_DATE
.include "commands/date.asm"
.endif

.ifdef WITH_ECHO
.include "commands/echo.asm"
.endif

.ifdef WITH_ENV
.include "commands/env.asm"
.endif

.ifdef WITH_EXEC
.include "commands/exec.asm"
.endif

.ifdef WITH_FORTH
.include "commands/teleforth.asm"
.endif

.ifdef WITH_HELP
.include "commands/help.asm"
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

.ifdef WITH_PWD
.include "commands/pwd.asm"
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

.ifdef WITH_MONITOR
.include "commands/monitor.asm"
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

.include "_exec_from_sdcard.asm"

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
    ldy     #O_RDONLY
    ldx     TR6
    BRK_KERNEL XOPEN
    ; get A&Y
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
    cmp     #2
    beq     @isA65C816
    lda     #CPU_65C02       ; it's a 65C02
    rts
@isA65C816:
    lda     #CPU_65816
@is6502Nmos:
    lda     #CPU_6502
    rts
.endproc

.proc _debug

;CPU_6502
    ; routine used for some debug
    PRINT   str_cpu
    jsr     _getcpu
    cmp     #CPU_65C02
    bne     @is6502
    PRINT   str_65C02
    RETURN_LINE
.pc02    
    bra     @next        ; At this step we are sure that it's a 65C02, so we use its opcode :)
.p02    
@is6502:
	
    PRINT   str_6502
	RETURN_LINE
@next:
    PRINT   str_ch376
    jsr     _ch376_ic_get_ver
    BRK_TELEMON XWR0
    BRK_TELEMON XCRLF
    ;RETURN_LINE
    
    PRINT   str_ch376_check_exist
    jsr     _ch376_check_exist
    jsr     _print_hexa
	BRK_TELEMON XCRLF
    
    
    lda #$09
    ldy #$02
  
    BRK_TELEMON XMALLOC
    ; A & Y are the ptr here
    BRK_TELEMON XFREE
    
    rts

    
str_ch376:
    .asciiz "CH376 VERSION : "
str_ch376_check_exist:
    .asciiz "CH376 CHECK EXIST : "
str_cpu:    
    .asciiz "CPU: "
.endproc

_print_hexa:
    pha
    CPUTC '#'
    pla

    BRK_TELEMON XHEXA
    sty TR7
    
    BRK_TELEMON XWR0
    lda TR7
    BRK_TELEMON XWR0
    rts
   

_print_hexa_no_sharp:

    BRK_TELEMON XHEXA
    sty TR7
    
    BRK_TELEMON XWR0
    lda TR7
    BRK_TELEMON XWR0
    rts   


;*****************************************************
fork_mode:
; 0 fork process
; 1 generate pid but don't malloc a struct for child
; 2 no fork no pid
.define NOFORK_NOPID   2
.define NOFORK_WITHPID 1
.define FORK_WITHPID   0


.ifdef WITH_BASIC11
    .byt NOFORK_NOPID
.endif    

.ifdef WITH_BANK    
    .byt NOFORK_NOPID
.endif

.ifdef WITH_CAT
    .byt NOFORK_NOPID
.endif    

.ifdef WITH_CA65
    .byt NOFORK_NOPID
.endif    	

.ifdef WITH_CD
    .byt NOFORK_NOPID
.endif    

.ifdef WITH_CLEAR    
    .byt NOFORK_NOPID
.endif    

.ifdef WITH_CP
    .byt NOFORK_NOPID
.endif

.ifdef WITH_DATE
    .byt NOFORK_NOPID
.endif    

.ifdef WITH_DEBUG
    .byt NOFORK_NOPID
.endif    	

.ifdef WITH_DF
    .byt NOFORK_NOPID
.endif

.ifdef WITH_DIR
    .byt NOFORK_NOPID ; dir (alias)
.endif    

.ifdef WITH_ECHO
    .byt NOFORK_NOPID ; 
.endif    

.ifdef WITH_ENV    
    .byt NOFORK_NOPID
.endif    

.ifdef WITH_EXEC
    .byt NOFORK_NOPID
.endif    

.ifdef WITH_FORTH
    .byt NOFORK_NOPID
.endif

.ifdef WITH_HELP
    .byt NOFORK_NOPID ;
.endif    
	
.ifdef WITH_HISTORY
    .byt NOFORK_NOPID
.endif   

.ifdef WITH_IOPORT	
    .byt NOFORK_NOPID ;    
.endif	

.ifdef WITH_KILL
    .byt NOFORK_NOPID ;    
.endif	

.ifdef WITH_LESS
    .byt NOFORK_NOPID
.endif    

.ifdef WITH_LS   
    .byt NOFORK_NOPID
.endif    

.ifdef WITH_LSCPU
    .byt NOFORK_NOPID
.endif

.ifdef WITH_LSMEM
    .byt NOFORK_NOPID
.endif    

.ifdef WITH_LSOF
    .byt NOFORK_NOPID
.endif

.ifdef WITH_MAN
    .byt NOFORK_NOPID
.endif

.ifdef WITH_MEMINFO
    .byt NOFORK_NOPID
.endif    

.ifdef WITH_MKDIR
    .byt NOFORK_NOPID
.endif    

.ifdef WITH_MONITOR
    .byt NOFORK_NOPID
.endif    

.ifdef WITH_MV   
    .byt NOFORK_NOPID
.endif    
    
.ifdef WITH_MOUNT
    .byt NOFORK_NOPID
.endif    

.ifdef WITH_OCONFIG
    .byt NOFORK_NOPID
.endif

.ifdef WITH_ORICSOFT
    .byt NOFORK_NOPID
.endif

.ifdef WITH_PS
    .byt NOFORK_NOPID
.endif

.ifdef WITH_PSTREE
    .byt NOFORK_NOPID
.endif   

.ifdef WITH_PWD    
    .byt NOFORK_NOPID
.endif    

.ifdef WITH_REBOOT
    .byt NOFORK_NOPID
.endif    

.ifdef WITH_RM
    .byt NOFORK_NOPID
.endif    

.ifdef WITH_SEDSD
    .byt NOFORK_NOPID
.endif     
    
.ifdef WITH_SETFONT
    .byt NOFORK_NOPID
.endif

.ifdef WITH_SH
    .byt NOFORK_NOPID
.endif 

.ifdef WITH_TELNETD
    .byt NOFORK_NOPID
.endif

.ifdef WITH_TOUCH
    .byt NOFORK_NOPID
.endif

.ifdef WITH_TREE
    .byt NOFORK_NOPID
.endif

.ifdef WITH_TWILIGHT
    .byt NOFORK_NOPID
.endif

.ifdef WITH_UNAME
    .byt NOFORK_NOPID
.endif    
    
.ifdef WITH_VI
    .byt NOFORK_NOPID
.endif

.ifdef WITH_VIEWHRS
    .byt NOFORK_NOPID
.endif    

.ifdef WITH_WATCH
    .byt NOFORK_NOPID
.endif    
    
.ifdef WITH_XORIX
    .byt NOFORK_NOPID
.endif


addr_commands:

.ifdef WITH_BASIC11
    .addr  _basic11
.endif    

.ifdef WITH_BANK    
    .addr  _banks
.endif

.ifdef WITH_CAT
    .addr  _cat
.endif    

.ifdef WITH_CA65
    .addr  _ca65
.endif    	

.ifdef WITH_CD
    .addr  _cd
.endif    

.ifdef WITH_CLEAR    
    .addr  _clear ; 
.endif    

.ifdef WITH_CP
    .addr  _cp
.endif

.ifdef WITH_DATE
    .addr  _date 
.endif    

.ifdef WITH_DEBUG
    .addr  _debug
.endif    	

.ifdef WITH_DF
    .addr  _df
.endif

.ifdef WITH_DIR
    .addr  _ls ; dir (alias)
.endif    

.ifdef WITH_ECHO
    .addr  _echo ; 
.endif    

.ifdef WITH_ENV    
    .addr  _env
.endif    

.ifdef WITH_EXEC
    .addr  _exec
.endif    

.ifdef WITH_FORTH
    .addr  _forth
.endif

.ifdef WITH_HELP
    .addr  _help ;
.endif    
	
.ifdef WITH_HISTORY
    .addr  _history
.endif   

.ifdef WITH_IOPORT	
    .addr  _ioports ;    
.endif	

.ifdef WITH_KILL
    .addr  _kill ;    
.endif	

.ifdef WITH_LESS
    .addr  _less
.endif    

.ifdef WITH_LS   
    .addr  _ls
.endif    

.ifdef WITH_LSCPU
    .addr  _lscpu
.endif

.ifdef WITH_LSMEM
    .addr  _lsmem
.endif    

.ifdef WITH_LSOF
    .addr  _lsof
.endif

.ifdef WITH_MAN
    .addr  _man
.endif

.ifdef WITH_MEMINFO
    .addr  _meminfo
.endif    

.ifdef WITH_MKDIR
    .addr  _mkdir
.endif    

.ifdef WITH_MONITOR
    .addr  _monitor
.endif    

.ifdef WITH_MV   
    .addr  _mv ; is in _cp
.endif    
    
.ifdef WITH_MOUNT
    .addr  _mount
.endif    

.ifdef WITH_OCONFIG
    .addr  _oconfig
.endif

.ifdef WITH_ORICSOFT
    .addr  _oricsoft
.endif

.ifdef WITH_PS
    .addr  _ps
.endif

.ifdef WITH_PSTREE
    .addr  _pstree
.endif   

.ifdef WITH_PWD    
    .addr  _pwd
.endif    

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



    
.ifdef WITH_XORIX
    .byt >_xorix
.endif	
    
list_command_low:
.ifdef WITH_BASIC11
    .byt <basic11
.endif

.ifdef WITH_BANK
    .byt <banks 
.endif   

.ifdef WITH_CAT    
    .byt <cat
.endif    

.ifdef WITH_CA65
    .byt <ca65
.endif		

.ifdef WITH_CD
    .byt <cd
.endif    

.ifdef WITH_CLEAR    
    .byt <clear
.endif

.ifdef WITH_CP
    .byt <cp
.endif    

.ifdef WITH_DATE
    .byt <date
.endif    

.ifdef WITH_DEBUG
    .byt <debug
.endif    

.ifdef WITH_DF
    .byt <df
.endif        

.ifdef WITH_DIR
    .byt <dir
.endif    

.ifdef WITH_ECHO
    .byt <echocmd
.endif    

.ifdef WITH_ENV    
    .byt <env
.endif

.ifdef WITH_EXEC
    .byt <exec
.endif    

.ifdef WITH_FORTH
    .byt <forth
.endif    

.ifdef WITH_HELP
    .byt <help
.endif    
	
.ifdef WITH_HISTORY
    .byt <history
.endif   

.ifdef WITH_IOPORT	
    .byt <ioports
.endif	

.ifdef WITH_KILL
    .byt <kill
.endif	
    
.ifdef WITH_LESS
    .byt <less
.endif   

.ifdef WITH_LS    
    .byt <ls
.endif    

.ifdef WITH_LSCPU    
    .byt <lscpu
.endif
    
.ifdef WITH_LSMEM
    .byt <lsmem
.endif    

.ifdef WITH_LSOF
    .byt <lsof
.endif    

.ifdef WITH_MAN
    .byt <man
.endif

.ifdef WITH_MEMINFO
    .byt <meminfo
.endif    

.ifdef WITH_MKDIR    
    .byt <mkdir
.endif    

.ifdef WITH_MONITOR
    .byt <monitor
.endif    

.ifdef WITH_MV   
    .byt <mv
.endif    
    
.ifdef WITH_MOUNT
    .byt <mount
.endif 

.ifdef WITH_OCONFIG
    .byt <oconfig
.endif

.ifdef WITH_ORICSOFT
    .byt <oricsoft
.endif

.ifdef WITH_PS       
    .byt <ps
.endif    

.ifdef WITH_PSTREE
    .byt <pstree
.endif    

.ifdef WITH_PWD    
    .byt <pwd
.endif    

.ifdef WITH_REBOOT    
    .byt <reboot
.endif

.ifdef WITH_RM
    .byt <rm
.endif

.ifdef WITH_SEDSD
    .byt <sedoric
.endif     
    
.ifdef WITH_SETFONT
    .byt <setfont
.endif

.ifdef WITH_SH
    .byt <sh
.endif

.ifdef WITH_TELNETD
    .byt <telnetd
.endif    

.ifdef WITH_TOUCH
    .byt <touch
.endif    

.ifdef WITH_TREE
    .byt <tree
.endif    

.ifdef WITH_TWILIGHT
    .byt <twilight
.endif    

.ifdef WITH_UNAME
    .byt <uname
.endif    

.ifdef WITH_VI
    .byt <vi
.endif    
  
.ifdef WITH_VIEWHRS
    .byt <viewhrs
.endif    

.ifdef WITH_WATCH
    .byt <watch
.endif    


.ifdef WITH_XORIX
    .byt <xorix
.endif	
    
list_command_high:
.ifdef WITH_BASIC11
    .byt >basic11
.endif

.ifdef WITH_BANK
    .byt >banks
.endif   

.ifdef WITH_CAT    
    .byt >cat
.endif

.ifdef WITH_CA65
    .byt >ca65
.endif

.ifdef WITH_CD
    .byt >cd
.endif    

.ifdef WITH_CLEAR    
    .byt >clear
.endif

.ifdef WITH_CP    
    .byt >cp
.endif

.ifdef WITH_DATE
    .byt >date
.endif    

.ifdef WITH_DEBUG
    .byt >debug
.endif    

.ifdef WITH_DF
    .byt >df
.endif        

.ifdef WITH_DIR
    .byt >dir
.endif

.ifdef WITH_ECHO
    .byt >echocmd
.endif    

.ifdef WITH_ENV
    .byt >env
.endif

.ifdef WITH_EXEC
    .byt >exec
.endif

.ifdef WITH_FORTH
    .byt >forth
.endif

.ifdef WITH_HELP
    .byt >help
.endif

.ifdef WITH_HISTORY
    .byt >history
.endif   

.ifdef WITH_IOPORT	
    .byt >ioports 
.endif	

.ifdef WITH_KILL
    .byt >kill
.endif	
    
.ifdef WITH_LESS
    .byt >less
.endif    

.ifdef WITH_LS
    .byt >ls
.endif    

.ifdef WITH_LSCPU    
    .byt >lscpu
.endif

.ifdef WITH_LSMEM
    .byt >lsmem
.endif
  
.ifdef WITH_LSOF    
    .byt >lsof
.endif

.ifdef WITH_MAN
    .byt >man
.endif

.ifdef WITH_MEMINFO
    .byt >meminfo
.endif    

.ifdef WITH_MKDIR
    .byt >mkdir
.endif    
    
.ifdef WITH_MONITOR
    .byt >monitor
.endif

.ifdef WITH_MV
    .byt >mv
.endif    

.ifdef WITH_MOUNT
    .byt >mount
.endif 

.ifdef WITH_OCONFIG
    .byt >oconfig
.endif 

.ifdef WITH_ORICSOFT
    .byt >oricsoft
.endif 

.ifdef WITH_PS
    .byt >ps
.endif    

.ifdef WITH_PSTREE
    .byt >pstree
.endif    

.ifdef WITH_PWD
    .byt >pwd
.endif    

.ifdef WITH_REBOOT    
    .byt >reboot
.endif

.ifdef WITH_RM
    .byt >rm
.endif    

.ifdef WITH_SEDSD
    .byt >sedoric
.endif 

.ifdef WITH_SETFONT
    .byt >setfont
.endif

.ifdef WITH_SH
    .byt >sh
.endif

.ifdef WITH_TELNETD
    .byt >telnetd
.endif

.ifdef WITH_TOUCH
    .byt >touch
.endif

.ifdef WITH_TREE
    .byt >tree
.endif

.ifdef WITH_TWILIGHT
    .byt >twilight
.endif

.ifdef WITH_UNAME
    .byt >uname
.endif

.ifdef WITH_VI
    .byt  >vi
.endif

.ifdef WITH_VIEWHRS
    .byt >viewhrs
.endif    

.ifdef WITH_WATCH
    .byt >watch
.endif    

.ifdef WITH_XORIX
    .byt >xorix
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

.ifdef WITH_CD
    .byt 2 ; _cd
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

.ifdef WITH_DIR
    .byt 3 ; _ls ; dir (alias)
.endif    

.ifdef WITH_ECHO
    .byt 4 ; _echo ; 
.endif    

.ifdef WITH_ENV    
    .byt 3 ; _env
.endif   

.ifdef WITH_EXEC
    .byt 4 ; _env
.endif    

.ifdef WITH_FORTH
    .byt 5 ; forth
.endif 

.ifdef WITH_HELP
    .byt 4 ; _help ; 
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

.ifdef WITH_MONITOR
    .byt 7 ; monitor
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

.ifdef WITH_PWD
    .byt 3 ; _pwd
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
.ifdef WITH_BASIC11    
basic11:
    .asciiz "basic11"
.endif    

.ifdef WITH_BANK    
banks:
    .asciiz "bank"
.endif    

.ifdef WITH_CAT    
cat:
    .asciiz "cat"
.endif

.ifdef WITH_CD
cd:
    .asciiz "cd"
.endif    

.ifdef WITH_CLEAR    
clear:
    .asciiz "clear"
.endif

;.ifdef WITH_CP
; Because cp & mv are in same file
cp:
    .asciiz "cp"
;.endif    

.ifdef WITH_DATE    
date:
    .asciiz "date"
.endif    

.ifdef WITH_DF    
df:
    .asciiz "df"
.endif    

.ifdef WITH_DIR
dir:
    .asciiz "dir"
.endif

.ifdef WITH_ECHO    
echocmd:
    .asciiz "echo"
.endif    

.ifdef WITH_ENV    
env:
    .asciiz "env"
.endif  

.ifdef WITH_EXEC
exec:
    .asciiz "exec"
.endif  

.ifdef WITH_FORTH    
forth:
    .asciiz "forth"
.endif

.ifdef WITH_HELP
help:
    .asciiz "help"
.endif

.ifdef WITH_HISTORY
history:
    .asciiz "history"
.endif    

.ifdef WITH_IOPORT	
ioports:
    .asciiz "ioports"
.endif

.ifdef WITH_KILL	
kill:
    .asciiz "kill"
.endif

.ifdef WITH_LESS
less:
    .asciiz "less"
.endif

.ifdef WITH_LS
ls:
    .asciiz "ls"
.endif    

.ifdef WITH_LSCPU    
lscpu:
    .asciiz "lscpu"
.endif    

.ifdef WITH_LSMEM
lsmem:	
    .asciiz "lsmem"
.endif

.ifdef WITH_LSOF    
lsof:	
    .asciiz "lsof"
.endif    

.ifdef WITH_MAN    
man:
    .asciiz "man"  
.endif    
meminfo:
    .asciiz "meminfo"

.ifdef WITH_MKDIR
mkdir:
    .asciiz "mkdir"
.endif    

.ifdef WITH_MONITOR
monitor:
    .asciiz "monitor"
.endif

.ifdef WITH_MOUNT
mount:
    .asciiz "mount"
.endif

.ifdef WITH_MV
mv:
    .asciiz "mv"
.endif    
    
.ifdef WITH_OCONFIG
oconfig:
    .asciiz "oconfig"
.endif     

.ifdef WITH_ORICSOFT
oricsoft:
    .asciiz "oricsft"
.endif      

.ifdef WITH_RM
rm:
    .asciiz "rm"
.endif

.ifdef WITH_PS
ps:
    .asciiz "ps"
.endif

.ifdef WITH_PSTREE
pstree:
    .asciiz "pstree"
.endif

.ifdef WITH_PWD
pwd:
    .asciiz "pwd"
.endif    

.ifdef WITH_REBOOT    
reboot:
    .asciiz "reboot"
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

.ifdef WITH_DEBUG
debug:
    .asciiz "debug"
.endif    
   
str_6502:                           ; use for lscpu
    .asciiz "6502"
str_65C02:                          ; use for lscpu
    .asciiz "65C02"

strMaxProcessReached:
    .byte "Max Process reached : "
    .byt ORIX_MAX_PROCESS+32+8+8
    .byt $0D,$0A,0
str_tape_file:
    .asciiz "Tape file : not working yet"
str_cant_execute:
    .asciiz ": is not an Orix file"
str_not_found:
    .byte " : No such file or directory",$0D,$0A,0
str_missing_operand:
    .byte ": missing operand",$0d,$0a,0
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
    .byte  "Orix Shell-"
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






.proc _commandline_parse
find_command:
    ; Search command
    ; Insert each command pointer in zpTemp02Word
    ldx     #$01
    jsr     _orix_get_opt
  
    ldx     #$00
mloop:
    lda     list_command_low,x
    sta     RESB
    lda     list_command_high,x
    sta     RESB+1  
  
  
    ldy     #$00
next_char:
    lda     (RES),y
    cmp     (RESB),y        ; same character?
    beq     no_space
    cmp     #' '            ; space?
    bne     command_not_found
    lda     (RESB),Y        ; Last character of the command name?
no_space:                   ; FIXME
    cmp     #$00            ; Test end of command name or EOL
    beq     command_found
    iny
    bne     next_char
 
command_not_found:

    inx
    cpx     #BASH_NUMBER_OF_COMMANDS 
    bne     mloop
    rts
command_found:
    ; at this step we found the command from a rom
	; X contains ID of the command
    txa
    asl
    tax

    lda     addr_commands,x
    sta     RES
    inx
    lda     addr_commands,x
    sta     RES+1

    JMP     (RES)               ; be careful with 6502 bug (jmp xxFF)

.endproc

.proc   exec_commandline
    jsr    _bash
    rts
.endproc

    .res $FFF1-*
    .org $FFF1
; $fff1
parse_vector:
    .addr exec_commandline     
; fff3
adress_commands:
    .addr addr_commands
; fff5        
list_commands:
    .addr list_of_commands_bank
; $fff7
number_of_commands:
    .byt BASH_NUMBER_OF_COMMANDS
; fffa

copyright:
    .word   signature

NMI:
	.word   start_sh_interactive

; fffc
RESET:
    .word   start_sh_interactive
; fffe
BRK_IRQ:	
    .word   IRQVECTOR

	

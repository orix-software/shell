.include   "telestrat.inc"          ; from cc65
.include   "fcntl.inc"              ; from cc65
.include   "errno.inc"              ; from cc65
.include   "cpu.mac"                ; from cc65

.include   "build.inc"
.include   "include/orix.inc"


.org $C000
.code
start_orix:
    lda     #$00
    sta     STACK_BANK
    ; set lowercase keyboard should be move in telemon bank
    lda     FLGKBD
    and     #%00111111 ; b7 : lowercase, b6 : no sound
    sta     FLGKBD

  ; Init PID tables
  
    lda     #$00
    ldx     #ORIX_MAX_PROCESS
  @loop:
    sta     LIST_PID,x
    dex
    bpl     @loop
  

  ; register kernel

;**************************************************************************************************************************/
;*                                                     Register in process list 'init' process                            */
;**************************************************************************************************************************/
  
    ldx     #$00              ; PID father
    REGISTER_PROCESS process_init

    tax                    ; get init PID for PID father 

;**************************************************************************************************************************/
;*                                                     Register in process list 'bash' process                            */
;**************************************************************************************************************************/    
    
    REGISTER_PROCESS process_bash

;**************************************************************************************************************************/
;*                                                     init malloc table in memory                                        */
;**************************************************************************************************************************/    
  
; new init malloc table 
    lda     #<orix_end_memory_kernel              ; First byte available when Orix Kernel has started
    sta     ORIX_MALLOC_FREE_BEGIN_LOW_TABLE      ; store it malloc table (low)
    lda     #>orix_end_memory_kernel
    sta     ORIX_MALLOC_FREE_BEGIN_HIGH_TABLE     ; and High
    
    lda     #<ORIX_MALLOC_MAX_MEM_ADRESS          ; Get the max memory adress (in oric.h)
    sta     ORIX_MALLOC_FREE_END_LOW_TABLE        ; store it (low)
    lda     #>ORIX_MALLOC_MAX_MEM_ADRESS
    sta     ORIX_MALLOC_FREE_END_HIGH_TABLE       ; store it high
;-orix_end_memory_kernel
    lda     #<(ORIX_MALLOC_MAX_MEM_ADRESS-orix_end_memory_kernel) ; Get the size (free)
    sta     ORIX_MALLOC_FREE_SIZE_LOW_TABLE                       ; and store
    
    lda     #>(ORIX_MALLOC_MAX_MEM_ADRESS-orix_end_memory_kernel) 
    sta     ORIX_MALLOC_FREE_SIZE_HIGH_TABLE
  
    lda     #$00 ; 0 means One chunk
    sta     ORIX_MALLOC_FREE_TABLE_NUMBER
 

; init the malloc pid busy table
; FIXME 65C02
init_malloc_busy_table:
    ldx     #ORIX_MALLOC_FREE_FRAGMENT_MAX
    lda     #$00

@loop:
    sta     ORIX_MALLOC_BUSY_TABLE_PID,x
    dex
    bpl     @loop
    
    ; Setting the current path to "/",0
    lda     #'/'
    sta     ORIX_PATH_CURRENT

    ; if it's hot reset, then don't initialize current path.
    BIT     FLGRST ; COLD RESET ?
    bpl     start_prompt	; yes



.IFPC02
.pc02
    stz     ORIX_PATH_CURRENT+1
.p02    
.else
    lda     #$00
    sta     ORIX_PATH_CURRENT+1 
.endif
    lda     #$01                 
    sta     ORIX_PATH_CURRENT_POSITION

;****************************************************************************/
start_prompt_and_jump_a_line:
    RETURN_LINE
start_prompt:
  
.IFPC02
.pc02
    stz     VARAPL               ; Used to store the length of the command line
    stz     BUFEDT
    stz     ORIX_ARGV
    stz     ERRNO
    stz     ORIX_CURRENT_PROCESS_FOREGROUND
.p02    
.else
    lda     #$00
    sta     VARAPL               ; Used to store the length of the command line
    sta     BUFEDT               ; command line buffer
    sta     ORIX_ARGV            ; argv buffer
    sta     ERRNO                ; errno : last error from command, not managed everywhere
    sta     ORIX_CURRENT_PROCESS_FOREGROUND
.endif	

display_prompt:
.IFPC02
.pc02
    stz     ORIX_GETOPT_PTR
.p02    
.else
    lda     #$00
    sta     ORIX_GETOPT_PTR      ; init the PTR of the command line
.endif
    PRINT   ORIX_PATH_CURRENT     ; Display current path in the prompt
    BRK_TELEMON XECRPR           ; display prompt (# char)
    SWITCH_ON_CURSOR

start_commandline:
    BRK_TELEMON XRDW0            ; read keyboard
    bmi     start_commandline    ; don't receive any specials chars (that is the case when funct key is used : it needs to be fixed in bank 7 in keyboard management
    cmp     #KEY_LEFT
    beq     start_commandline    ; left key not managed
    cmp     #KEY_RIGHT
    beq     start_commandline    ; right key not managed
    cmp     #KEY_UP
    beq     start_commandline    ; up key not managed
    cmp     #KEY_DOWN
    beq     start_commandline    ; down key not managed
    cmp     #KEY_RETURN          ; is it enter key ?
    bne     next_key             ; no we display the char
    lda     VARAPL               ; no command ?
    beq     start_prompt_and_jump_a_line ; yes it's an empty line
    lda     #<BUFEDT             ; register command line buffer
    ldy     #>BUFEDT
    jsr     _bash                ; and launch interpreter
    lda     ORIX_CURRENT_PROCESS_FOREGROUND
    beq     start_prompt
    jsr     _orix_unregister_process
    jmp     start_prompt
next_key:
    cmp     #KEY_DEL             ; is it del pressed ?
    beq     key_del_routine      ; yes let's remove the char in the BUFEDT buffer
    cmp     #KEY_ESC             ; ESC key not managed, but could do autocompletion (Pressed twice)
    beq     start_commandline

    ldx     VARAPL               ; get the length of the current line
    cpx     #MAX_LENGTH_BUFEDT-1 ; do we reach the size of command line buffer ?
    beq     start_commandline    ; yes restart command line until enter or del keys are pressed, but
    BRK_TELEMON XWR0             ; write key on the screen (it's really a key pressed
    ldx     VARAPL               ; get the position on the command line
    sta     BUFEDT,x             ; stores the char in command line buffer
    inx                      ; increase by 1 the current position in the command line buffer
    stx     VARAPL
  
.IFPC02
.pc02         
    stz     BUFEDT,x             ; flush edition buffer
.p02    
.else
    lda     #$00
    sta     BUFEDT,x             ; flush edition buffer
.endif		

    jmp     start_commandline    ; and loop interpreter
key_del_routine:
    ldx     VARAPL               ; load the length of the command line buffer
    beq     send_oups_and_loop   ; command line is empty send oups sound
    dex                      ; command line is NOT empty, remove last char in the buffer
    lda     #$00                 ; remove last char FIXME 65c02
    sta     BUFEDT,x
    stx     VARAPL               ; and store the length
    SWITCH_OFF_CURSOR
    dec     SCRX                 ; go one step to the left on the screen

    SWITCH_ON_CURSOR

no_action:
    jmp     start_commandline    ; and restart 

send_oups_and_loop:
    BRK_TELEMON XOUPS
    jmp     start_commandline


.proc _bash

    sta     RES
    sty     RES+1
    jsr     ltrim; ltrim command line
    
    ; // Looking if it request ./ : it means that user want to load and execute
    ldy     #$00
@loop:
    lda     (RES),y
    cmp     #' '
    bne     no_more_space 
    iny
    cpy     #MAX_LENGTH_BUFEDT
    bne     @loop
no_command:
    rts 
no_more_space:
    cmp     #$00
    beq     no_command   ;  "     ",0 on command line
    cmp     #'.'
    bne     find_command
    iny
    lda     (RES),y
    cmp     #'/'
    bne     find_command
    
    ; switch off timiers on via2
    lda     #0+32+64
    sta     VIA2::IER
    
    ; here we jump to command because we founded "./"
    jsr     _orix_load_and_start_app
    ; switch on timers en via2
    lda     #128+32+64
    sta     VIA2::IER
    ; switch on the cursor
    SWITCH_ON_CURSOR
    rts

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

orix_try_to_find_command_in_bin_path:
	; here we found no command, let's go trying to find it in /bin

    ldx     #$00
    jsr     _orix_get_opt

    jsr     _start_from_root_bin

    cmp     #$ff ; if it return x=$ff a=$ff (it's not open)
    beq     even_in_slash_bin_command_not_found
    ; we should start code here
    lda     #$00
    sta     ERRNO ; FIXME 65C02
    jsr     _orix_load_and_start_app_xopen_done
    rts
even_in_slash_bin_command_not_found:
    RETURN_LINE
    PRINT ORIX_ARGV
    PRINT str_command_not_found
    lda     #$01
    sta     ERRNO
    rts

command_found:
	; X contains ID of the command
	; Y contains the position of the BUFEDT
    stx     TR7                    ; save the id of the command

    RETURN_LINE         ;jump a line
    
    ldx     TR7                    ; get the id of the command
    
    lda     list_command_low,x     ; get the name of the command
    ldy     list_command_high,x    ; and high
    ; get PID father
    ldx     ORIX_CURRENT_PROCESS_FOREGROUND
    jsr     _orix_register_process ; register process
    bne     register_process_valid ; if it's return 0 then there is an error

    ; we manage only max process here, but it could be also a out of memory error
    ; but here we are in a command in ROM, ooe will not arrive except if command do a malloc exception
    ; display maxProcessReached
    PRINT strMaxProcessReached
    ; at this step we reach the max process 
    rts 

register_process_valid:         ; if we are here, it means that register_process_valid returns a PID
    sta     ORIX_CURRENT_PROCESS_FOREGROUND
    
    ldx     TR7
    lda     commands_low,x
    sta     RES
	
    lda     commands_high,x
    sta     RES+1
    
    JMP     (RES) ; be careful with 6502 bug (jmp xxFF)
	
end_string:

end:

	rts
.endproc

;  [IN] X get the id of the parameter
; [ IN] Y contains the index in BUFEDT
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

.proc _start_from_root_bin

	
    ; copy /bin
    ; do a strcat
    ldx     #$00
loop30:
    lda     str_root_bin,x
    beq     @end
	
    sta     volatile_str,x
    inx
    cpx     #SIZE_OF_VOLATILE_STR
    bne     loop30
@end:
    ldy     #$00
loop20:
    lda     ORIX_ARGV,y
    beq     @end2
    sta     volatile_str,x
    inx
    iny
    cpx     #SIZE_OF_VOLATILE_STR
    bne     loop20
    ; now copy argv[0]
@end2:
    sta     volatile_str,x

    FOPEN volatile_str, O_RDONLY

    rts
str_root_bin:
    .asciiz "/bin/"
.endproc


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

.ifdef WITH_PS
.include "commands/ps.asm"
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

.ifdef WITH_MONITOR
.include "commands/monitor.asm"
.endif

.ifdef WITH_TREE
.include "commands/tree.asm"
.endif

.ifdef WITH_UNAME
.include "commands/uname.asm"
.endif

.ifdef WITH_SH
.include "commands/sh.asm"
.endif

.ifdef WITH_VI
.include "commands/vi.asm"
.endif
; Functions

.ifdef WITH_VIEWHRS
.include "commands/viewhrs.asm"
.endif

.ifdef WITH_XORIX
.include "commands/xorix.asm"
.endif

.include "lib/strcpy.asm"
.include "lib/strcat.asm"
.include "lib/strlen.asm"
.include "lib/fread.asm"
.include "lib/get_opt.asm"
.include "lib/getOrixVar.asm"
; hardware
.include "lib/ch376.s"
.include "lib/ch376_verify.s"


_cd_to_current_realpath_new:
    BRK_TELEMON XOPENRELATIVE
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

end_crap:       ; FIXME
    rts
	
_orix_load_and_start_app:

    jsr     _ch376_verify_SetUsbPort_Mount
    cmp     #$01
    beq     end_crap
	
    jsr     _cd_to_current_realpath_new
    ldx     #$00
    jsr     _orix_get_opt
    STRCPY ORIX_ARGV+2,BUFNOM
 	
    jsr     _ch376_set_file_name
    jsr     _ch376_file_open
    cmp     #CH376_ERR_MISS_FILE
    bne     skip_and_malloc_header
    RETURN_LINE
    PRINT   ORIX_ARGV
    PRINT   str_command_not_found ; MACRO
    
    rts	
  
_orix_load_and_start_app_xopen_done:
skip_and_malloc_header:

    MALLOC(20) ; Malloc 20 bytes (20 bytes for header)
    
    ptr_header:=VARLNG
    
    sta     ptr_header
    sty     ptr_header+1
    
    sta     PTR_READ_DEST
    sty     PTR_READ_DEST+1

    lda     #20
    ldy     #$00
    BRK_TELEMON XFREAD
    
    
    ldy     #$00
    lda     (ptr_header),y ; fixme 65c02

;******************************************** END Manage starting tap file*/	

not_a_tape_file:
    cmp     #$01
    beq     is_an_orix_file
    RETURN_LINE
    
    BRK_TELEMON XCLOSE
    ; not found it means that we display error message
    ldx     #$00
    jsr     _orix_get_opt
    PRINT   ORIX_ARGV

    PRINT   str_cant_execute
    RETURN_LINE
    ; FIXME close the opened file here

    BRK_TELEMON XCLOSE
    rts 
is_an_orix_file:
    RETURN_LINE	

  	; Switch off cursor
    ldx     #$00
    BRK_TELEMON XCOSCR
    ; Storing address to load it

    ldy     #14
    lda     (ptr_header),y ; fixme 65c02
    sta     PTR_READ_DEST

    ldy     #15
    lda     (ptr_header),y ; fixme 65c02
    sta     PTR_READ_DEST+1
		
    ; init RES to start code

    ldy     #18
    lda     (ptr_header),y ; fixme 65c02
    sta     VARAPL+2
    ldy     #19
    lda     (ptr_header),y ; fixme 65c02    
    sta     VARAPL+3
    
    ldx     #$00
    jsr     _orix_get_opt
    
    REGISTER_PROCESS ORIX_ARGV
    
    bne register_process_valid ; if it's return 0 then there is an error
    PRINT strMaxProcessReached
    ; at this step we reach the max process 
    rts 

register_process_valid:        ; if we are here, it means that register_process_valid returns a PID
    sta     ORIX_CURRENT_PROCESS_FOREGROUND

is_not_encapsulated:
	
    lda     #$ff ; read all the binary
    ldy     #$ff
    BRK_TELEMON XFREAD

    ; These nops are used because on real hardware, CLOSE refuse to close
   
    lda     #$00 ; don't update length
    BRK_TELEMON XCLOSE

    jmp     (VARAPL+2) ; jmp : it means that if program launched do an rts, it returns to interpreter
		




switch_off: ; ???? FIXME
.byt $EA,$00,$00,$00,$00,$00,$00,$EF,$00,$00,$00,$00,$00,$00

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
    lda     #CPU_65C02       ; it's a 65C02
    rts
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
    ; BRK_TELEMON XFREE)
    
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

commands_low:

.ifdef WITH_BASIC11
    .byt <_basic11
.endif    

.ifdef WITH_BANK    
    .byt <_banks
.endif

.ifdef WITH_CAT
    .byt <_cat
.endif    

.ifdef WITH_CA65
    .byt <_ca65
.endif    	

.ifdef WITH_CD
    .byt <_cd
.endif    

.ifdef WITH_CLEAR    
    .byt <_clear ; 
.endif    

.ifdef WITH_CP
    .byt <_cp
.endif

.ifdef WITH_DATE
    .byt <_date 
.endif    

.ifdef WITH_DEBUG
    .byt <_debug
.endif    	

.ifdef WITH_DF
    .byt <_df
.endif

.ifdef WITH_DIR
    .byt <_ls ; dir (alias)
.endif    

.ifdef WITH_ECHO
    .byt <_echo ; 
.endif    

.ifdef WITH_ENV    
    .byt <_env
.endif    

.ifdef WITH_FORTH
    .byt <_forth
.endif

.ifdef WITH_HELP
    .byt <_help ;
.endif    
	
.ifdef WITH_HISTORY
    .byt <_history
.endif   

.ifdef WITH_IOPORT	
    .byt <_ioports ;    
.endif	

.ifdef WITH_LESS
    .byt <_less
.endif    

.ifdef WITH_LS   
    .byt <_ls
.endif    

.ifdef WITH_LSCPU
    .byt <_lscpu
.endif

.ifdef WITH_LSMEM
    .byt <_lsmem
.endif    

.ifdef WITH_LSOF
    .byt <_lsof
.endif

.ifdef WITH_MAN
    .byt <_man
.endif

.ifdef WITH_MEMINFO
    .byt <_meminfo
.endif    

.ifdef WITH_MKDIR
    .byt <_mkdir
.endif    

.ifdef WITH_MONITOR
    .byt <_monitor
.endif    

.ifdef WITH_MV   
    .byt <_mv ; is in _cp
.endif    
    
.ifdef WITH_MOUNT
    .byt <_mount
.endif    

.ifdef WITH_OCONFIG
    .byt <_oconfig
.endif

.ifdef WITH_PS
    .byt <_ps
.endif    

.ifdef WITH_PWD    
    .byt <_pwd
.endif    

.ifdef WITH_RM
    .byt <_rm
.endif    

.ifdef WITH_SEDSD
    .byt <_sedsd
.endif     
    
.ifdef WITH_SH
    .byt <_sh
.endif 

.ifdef WITH_TOUCH
    .byt <_touch
.endif

.ifdef WITH_TREE
    .byt <_touch
.endif

.ifdef WITH_UNAME
    .byt <_uname
.endif    
    
.ifdef WITH_VI
    .byt <_vi
.endif

.ifdef WITH_VIEWHRS
    .byt <_viewhrs
.endif    

.ifdef WITH_REBOOT
    .byt <_reboot	
.endif
    
.ifdef WITH_XORIX
    .byt <_xorix
.endif	
  
commands_high:
.ifdef WITH_BASIC11
    .byt >_basic11
.endif

.ifdef WITH_BANK
    .byt >_banks
.endif    

.ifdef WITH_CAT    
    .byt >_cat
.endif    

.ifdef WITH_CA65
    .byt >_ca65
.endif	 	

.ifdef WITH_CD
    .byt >_cd
.endif

.ifdef WITH_CLEAR
    .byt >_clear
.endif    

.ifdef WITH_CP
    .byt >_cp
.endif    

.ifdef WITH_DATE
    .byt >_date 
.endif

.ifdef WITH_DEBUG
    .byt >_debug	
.endif 

.ifdef WITH_DF
    .byt >_df
.endif        

.ifdef WITH_DIR
    .byt >_ls ; (dir)
.endif    

.ifdef WITH_ECHO
    .byt >_echo
.endif    

.ifdef WITH_ENV    
    .byt >_env
.endif    

.ifdef WITH_FORTH
    .byt >_forth
.endif    

.ifdef WITH_HELP
    .byt >_help
.endif    
	
.ifdef WITH_HISTORY
    .byt >_history
.endif   

.ifdef WITH_IOPORT	
    .byt >_ioports
.endif

.ifdef WITH_LESS
    .byt >_less
.endif        

.ifdef WITH_LS
    .byt >_ls
.endif    

.ifdef WITH_LSCPU    
    .byt >_lscpu
.endif

.ifdef WITH_LSMEM
    .byt >_lsmem
.endif    
    
.ifdef WITH_LSOF    
    .byt >_lsof
.endif

.ifdef WITH_MAN
    .byt >_man
.endif

.ifdef WITH_MEMINFO
    .byt >_meminfo
.endif    

.ifdef WITH_MKDIR
    .byt >_mkdir
.endif

.ifdef WITH_MONITOR
    .byt >_monitor
.endif        
    
.ifdef WITH_MV
    .byt >_mv
.endif    
    
.ifdef WITH_MOUNT
    .byt >_mount
.endif

.ifdef WITH_OCONFIG
    .byt >_oconfig
.endif

.ifdef WITH_PS    
    .byt >_ps
.endif    

.ifdef WITH_PWD
    .byt >_pwd
.endif    

.ifdef WITH_RM    
    .byt >_rm
.endif    

.ifdef WITH_SEDSD
    .byt >_sedsd
.endif  
    
.ifdef WITH_SH
    .byt >_sh
.endif  

.ifdef WITH_TOUCH
    .byt >_touch
.endif

.ifdef WITH_TREE
    .byt >_tree
.endif

.ifdef WITH_UNAME
    .byt >_uname
.endif    

.ifdef WITH_VI
    .byt >_vi
.endif

.ifdef WITH_VIEWHRS
    .byt >_viewhrs
.endif    

.ifdef WITH_REBOOT
    .byt >_reboot
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

.ifdef WITH_PS       
    .byt <ps
.endif    

.ifdef WITH_PWD    
    .byt <pwd
.endif    

.ifdef WITH_RM
    .byt <rm
.endif

.ifdef WITH_SEDSD
    .byt <sedoric
.endif     
    
.ifdef WITH_SH
    .byt <sh
.endif

.ifdef WITH_TOUCH
    .byt <touch
.endif    

.ifdef WITH_TREE
    .byt <tree
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

.ifdef WITH_REBOOT    
    .byt <reboot
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

.ifdef WITH_PS
    .byt >ps
.endif    

.ifdef WITH_PWD
    .byt >pwd
.endif    

.ifdef WITH_RM
    .byt >rm
.endif    

.ifdef WITH_SEDSD
    .byt >sedoric
.endif 

.ifdef WITH_SH
    .byt >sh
.endif

.ifdef WITH_TOUCH
    .byt >touch
.endif

.ifdef WITH_TREE
    .byt >tree
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

.ifdef WITH_REBOOT    
    .byt >reboot
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

.ifdef WITH_PS
    .byt 2 ; ps
.endif

.ifdef WITH_PWD
    .byt 3 ; _pwd
.endif    

.ifdef WITH_RM
    .byt 2 ; rm
.endif    

.ifdef WITH_SEDSD
    .byt 7
.endif     
    
.ifdef WITH_SH
    .byt 2 ; sh
.endif   

.ifdef WITH_TOUCH
    .byt 5 ; touch
.endif

.ifdef WITH_TREE
    .byt 4 ; tree
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

.ifdef WITH_REBOOT    
    .byt 6 ;_reboot	
.endif

.ifdef WITH_XORIX
    .byt 5 ;xorix
.endif	    

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

.ifdef WITH_RM
rm:
    .asciiz "rm"
.endif

.ifdef WITH_PS
ps:
    .asciiz "ps"
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

.ifdef WITH_SH
sh:
    .asciiz "sh"
.endif

.ifdef WITH_TREE
tree:
    .asciiz "tree"
.endif    

.ifdef WITH_TOUCH    
touch:
    .asciiz "touch"
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



; [IN] X the id of_orix_register_process the command
process_init:
    .asciiz "init"
process_bash:
    .asciiz "bash"

_orix_register_process:

    ; IN X contains the pid father
    ; IN [A & Y] the string of the command
    ; OUT [A contains the PID]
    ; get available PID
    sta     RES ; save A
    sty     RES+1
; get the next PID available    

    ldx     #$00
@loop:
    lda     LIST_PID,x
    beq     @isFree
    inx     
    cpx     #ORIX_MAX_PROCESS
    bne     @loop

    lda     #$00                 ; Error 
    rts

@isFree:
    ; looking for the next PID
    txa
    pha


    lda     #$01
    sta     TR4
    
; get  next PID number available
get_next_pid_number:
    ldx     #$00
@loop:
    lda     LIST_PID,x
    cmp     TR4
    bne     @next
    inc     TR4

@next:
    inx     
    cpx     #ORIX_MAX_PROCESS
    bne     @loop    

  
    pla
    tax
  
    ; Register process into ps table  
   

    lda     orix_command_table_low,x  ;store in process list
    sta     RESB
    lda     orix_command_table_high,x
    sta     RESB+1
    jsr     _strcpy
    
    stx     RES ; save the position     

    lda     TR4
    ldx     RES
    sta     LIST_PID,x ; register 
    ldx  TR4

 
    rts

orix_command_table_low:
    .byt <LIST_NAME_PID
    .byt <LIST_NAME_PID+9
    .byt <LIST_NAME_PID+9*2
    .byt <LIST_NAME_PID+9*3
    .byt <LIST_NAME_PID+9*4
    .byt <LIST_NAME_PID+9*5
orix_command_table_high:
    .byt >LIST_NAME_PID
    .byt >LIST_NAME_PID+9  
    .byt >LIST_NAME_PID+9*2   
    .byt >LIST_NAME_PID+9*3
    .byt >LIST_NAME_PID+9*4
    .byt >LIST_NAME_PID+9*5



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

_orix_unregister_process:

; [A] id of the process

  ldx     #$00
@loop: 
  cmp     LIST_PID,x               ; looking un ps table where the PID is
  beq     @found
  inx
  cpx     #ORIX_NUMBER_OF_MALLOC
  bne     @loop
  ; not found
  rts
  
  ; at this step X contains the position of the ps list    
@found:
  pha                           ; save PID
  lda     #$00  ; FIXME 65C02  
  sta     LIST_PID,x                ; destroy the PID in ps table
  ; destroy busy chunks of this process
 
  
  ; let's trying to find malloc done for this process
  pla ; get PID

  ldx #$00
loop_free_process:
  cmp     ORIX_MALLOC_BUSY_TABLE_PID,x
  bne     next_chunk
free_chunk:
.ifdef WITH_DEBUG
; in debug mode we keep malloc table
.else  
  ; save A, X and call XFREE
  pha
  txa
  pha

  lda     ORIX_MALLOC_BUSY_TABLE_BEGIN_LOW,x
  ldy     ORIX_MALLOC_BUSY_TABLE_BEGIN_HIGH,x
  BRK_TELEMON XFREE
  ; and flush

  pla
  tax
  ; and clean pid 
  lda     #$00
  sta     ORIX_MALLOC_BUSY_TABLE_PID,x
  pla
.endif 

next_chunk:
  inx
  cpx     #ORIX_NUMBER_OF_MALLOC
  bne     loop_free_process
  rts
 ; TODO destroy fp from this process


_orix_init_filehandle:
    lda     #$02 ; stdin/stdout/sderr
    sta     NUMBER_OPENED_FILES
    rts


; [out] A=#ff if error, else X contains the id of the filehandle
_orix_register_filehandle:


    ldx     NUMBER_OPENED_FILES
    cpx     #ORIX_MAX_OPEN_FILES
    beq     @error
    inc     NUMBER_OPENED_FILES
    lda     #$00
    rts
@error:
    lda     #$00
    rts


_orix_unregister_filehandle:
    rts


ORIX_ROUTINES_TABLE:
ORIX_ROUTINES_TABLE_LOW:
    .byt    <_orix_register_filehandle ;0
    .byt    <_orix_register_process    ;1 
    .byt    <_orix_unregister_process  ;2

ORIX_ROUTINES_TABLE_HIGH:
    .byt    >_orix_register_filehandle
    .byt    >_orix_register_process
    .byt    >_orix_unregister_process


    .res    $FFE0-*
    .org    $FFE0

_call_orix_routine:
    ldx     TR0
    lda     ORIX_ROUTINES_TABLE_LOW,x
    sta     RES
    lda     ORIX_ROUTINES_TABLE_HIGH,x
    sta     RES+1
    jmp     (RES)


    .res    $FFF8-*
    .org    $FFF8

; fffa

copyright:
    .word   signature

NMI:
	.word   start_orix

; fffc
RESET:
    .word   start_orix
; fffe
BRK_IRQ:	
    .word   IRQVECTOR

	

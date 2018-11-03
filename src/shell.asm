.include   "telestrat.inc"
.include   "fcntl.inc"
.include   "cpu.mac"


.macro  BRK_ORIX   value
	.byte $00,value
.endmacro
 
.macro RETURNVAL value
  lda #value
  sta ERRNO
.endmacro
  
.macro RETURN0
    lda #$00
    sta ERRNO  
.endmacro

.macro PRINT_BINARY_TO_DECIMAL_16BITS justif
    LDX #$20
    STX DEFAFF
    LDX #justif
    .byte $00,XDECIM
.endmacro

.macro CLS
  lda     #<SCREEN
  ldy     #>SCREEN
  sta     RES
  sty     RES+1
  ldy     #<(SCREEN+40+27*40)
  ldx     #>(SCREEN+40+27*40)
  lda     #' '
  BRK_ORIX XFILLM
.endmacro
  
.macro UNREGISTER_PROCESS
  lda ORIX_CURRENT_PROCESS_FOREGROUND
  beq skip_UNREGISTER_PROCESS
  jsr _orix_unregister_process
skip_UNREGISTER_PROCESS
.endmacro

.macro UNREGISTER_PROCESS_BY_PID_IN_ACCUMULATOR
  beq skip_UNREGISTER_PROCESS
  jsr _orix_unregister_process
skip_UNREGISTER_PROCESS
.endmacro
 
.macro SWITCH_ON_CURSOR
  ldx #$00
  BRK_ORIX XCSSCR
.endmacro  

.macro SWITCH_OFF_CURSOR
	ldx #$00
	BRK_ORIX XCOSCR
.endmacro    

.macro HIRES
	BRK_ORIX XHIRES
.endmacro    

.macro REGISTER_PROCESS str_name_process 
    lda #<str_name_process
    ldy #>str_name_process
    jsr _orix_register_process  
.endmacro

;FIXME   
.macro GET8_FROM_STRUCT offset, zpaddress
	ldy #offset
	lda (zpaddress),y
.endmacro    

.macro PUT8_FROM_STRUCT offset,zpaddress
	ldy #offset
	sta (zpaddress),y
.endmacro    
  
; O_WRONLY
; O_RDONLY   
.macro FOPEN file, mode
  lda   #<file
  ldx   #>file
  ldy   #mode
  .byte $00,XOPEN
.endmacro  
 
.macro FOPEN_INTO_BANK7 file, mode
  lda   #<file
  ldx   #>file
  ldy   #mode
  jsr   XOPEN_ROUTINE
.endmacro
 
.macro MKDIR PATH 
  lda   #<PATH
  ldx   #>PATH
  .byte $00,XMKDIR
.endmacro  
  
; size_t fread ( void * ptr, size_t size, FILE * stream);  
.macro FREAD ptr, size, count, fp
    lda #<fp
    lda #>fp
    lda #<ptr
    sta PTR_READ_DEST
    lda #>ptr
    sta PTR_READ_DEST+1
    lda #<size
    ldy #>size
    BRK_ORIX XFREAD
.endmacro

.macro  CGETC
    BRK_ORIX XRDW0 
.endmacro    
    
.macro MALLOC size 
  lda #<size
  ldy #>size
  BRK_ORIX XMALLOC
.endmacro

.macro FREE ptr 
  lda #<ptr
  ldy #>ptr
  BRK_ORIX XFREE
.endmacro 

.macro CPUTC char
  lda #char
  BRK_ORIX XWR0
.endmacro
  
.macro  PRINT_CHAR str
  pha
  sta TR6
  txa
  pha
  tya
  pha
  lda TR6
  BRK_TELEMON XWR0
  pla
  tay
  pla
  txa
  pla
.endmacro	

.macro PRINT str
	pha
	txa
	pha
	tya
	pha
	lda #<str
	ldy #>str
	BRK_TELEMON XWSTR0
    pla
	tay
	pla
	txa
    pla
.endmacro

.macro PRINT_NOSAVE_REGISTER str
	lda #<str
	ldy #>str
	BRK_TELEMON XWSTR0
.endmacro

.macro RETURN_LINE_INTO_TELEMON
	pha
	txa
	pha
	tya
	pha
	lda RES
	pha
	lda RES+1
	pha
	jsr XCRLF_ROUTINE 
	pla
	sta RES+1
	pla
	sta RES
	pla
	tay
	pla
	txa
	pla
.endmacro    
	
.macro PRINT_INTO_TELEMON str
	pha
	txa
	pha
	tya
	pha
	lda RES
	pha
	lda RES+1
	pha
	lda #<str
	ldy #>str
	jsr XWSTR0_ROUTINE 
	pla
	sta RES+1
	pla
	sta RES
	pla
	tay
	pla
	txa
	pla
.endmacro

.macro RETURN_LINE
  BRK_ORIX XCRLF
.endmacro  
	
.macro STRCPY str1, str2
	lda #<str1
	sta RES
	lda #>str1
	sta RES+1
	lda #<str2
	sta RESB
	lda #>str2
	sta RESB+1
	jsr _strcpy
.endmacro    

.macro STRCAT str1, str2
	lda #<str1
	sta RES
	lda #>str1
	sta RES+1
	lda #<str2
	sta RESB
	lda #>str2
	sta RESB+1
	jsr _strcat 
.endmacro     
	
; This macro copy AY address to str
.macro STRCPY_BY_AY_SRC str
	sta RES
	sty RES+1
	lda #<str
	sta RESB
	lda #>str
	sta RESB+1
	jsr _strcpy
.endmacro    
  


BASIC11_IRQ_VECTOR_ROM=$EE22

.define CH376_ERROR_VERBOSE

.ifdef WITH_OCONFIG
.define OCONFIG 1
.else
.define OCONFIG 0
.endif

.ifdef WITH_LSOF
.define LSOF 1
.else
.define LSOF 0
.endif

.ifdef WITH_IOPORT
.define IOPORT 1
.else
.define IOPORT 0
.endif

.ifdef WITH_MONITOR
.define MONITOR 1
.else
.define MONITOR 0
.endif

.ifdef WITH_CA65
.define CA65 1
.else
.define CA65 0
.endif

.ifdef WITH_MOUNT
.define MOUNT 1
.else
.define MOUNT 0
.endif

.ifdef WITH_DEBUG
.define DEBUG 1
.else
.define DEBUG 0
.endif

.ifdef WITH_DF
.define DF 1
.else
.define DF 0
.endif

.ifdef WITH_VI
.define VI 1
.else
.define VI 0
.endif

.ifdef WITH_SEDSD
.define SEDSD 1
.else
.define SEDSD 0
.endif

.ifdef WITH_TREE
.define TREE 1
.else
.define TREE 0
.endif

.ifdef WITH_SH
.define SH 1
.else
.define SH 0
.endif

.ifdef WITH_MORE
.define MORE 1
.else
.define MORE 0
.endif

.ifdef WITH_LESS
.define LESS 1
.else
.define LESS 0
.endif

.ifdef WITH_CPUINFO
.define CPUINFO 1
.else
.define CPUINFO 0
.endif

.ifdef WITH_BANKS
.define BANKS 1
.else
.define BANKS 0
.endif

.ifdef WITH_KILL
.define KILL 1
.else
.define KILL 0
.endif

.ifdef WITH_HISTORY
.define HISTORY 1
.else
.define HISTORY 0
.endif

.ifdef WITH_XORIX
.define XORIX 1
.else
.define XORIX 0
.endif

.ifdef WITH_TELEFORTH
.define TELEFORTH 1
.else
.define TELEFORTH 0
.endif

BASH_NUMBER_OF_COMMANDS=26+IOPORT+OCONFIG+LSOF+DF+VI+TREE+SH+MORE+LESS+SEDSD+CPUINFO+BANKS+KILL+HISTORY+XORIX+MOUNT+MONITOR+CA65+TELEFORTH

COLOR_FOR_FILES =             $87 ; colors when ls displays files 
COLOR_FOR_DIRECTORY  =       $86 ; colors when ls display directory
	

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
    stz     ORIX_PATH_CURRENT+1
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
    stz     VARAPL               ; Used to store the length of the command line
    stz     BUFEDT
    stz     ORIX_ARGV
    stz     ERRNO
    stz     ORIX_CURRENT_PROCESS_FOREGROUND
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
    stz     ORIX_GETOPT_PTR
.else
    lda     #$00
    sta     ORIX_GETOPT_PTR      ; init the PTR of the command line
.endif
    PRINT(ORIX_PATH_CURRENT)     ; Display current path in the prompt
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
    sta     V2IER
    
    ; here we jump to command because we founded "./"
    jsr     _orix_load_and_start_app
    ; switch on timers en via2
    lda     #128+32+64
    sta     V2IER
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
    PRINT(strMaxProcessReached)
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
@end:
.IFPC02
    bra     restart_test_space  
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
    beq     @end
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


// Commands
.include "commands/banks.asm"
.include "commands/basic11.asm"
.include "commands/cat.asm"
.include "commands/cd.asm"
.include "commands/clear.asm"
.include "commands/cp.asm"

.ifdef WITH_DF
.include "commands/df.asm"
.endif

.include "commands/echo.asm"
.include "commands/env.asm"

.ifdef WITH_TELEFORTH
.include "commands/teleforth.asm"
.endif

.include "commands/help.asm"

.ifdef WITH_HISTORY
.include "commands/history.asm"
.endif

.ifdef WITH_IOPORT
.include "commands/ioports.asm"
.endif

.include "commands/kill.asm"
.include "commands/less.asm"
.include "commands/ls.asm"
.include "commands/lscpu.asm"
.include "commands/lsmem.asm"
.include "commands/lsof.asm"
.include "commands/man.asm"
.include "commands/meminfo.asm"
.include "commands/mkdir.asm"
.include "commands/mount.asm"

.include "commands/oconfig.asm"

.include "commands/ps.asm"
.include "commands/pwd.asm"
.include "commands/reboot.asm"
.include "commands/rm.asm"
.include "commands/sedsd.asm"
.include "commands/touch.asm"
.include "commands/monitor.asm"
.include "commands/tree.asm"
.include "commands/uname.asm"


.ifdef WITH_SH
.include "commands/sh.asm"
.endif

.ifdef WITH_VI
.include "commands/vi.asm"
.endif
; Functions

.include "commands/viewhrs.asm"

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
	
_date:
    lda     #<SCREEN+32
    ldy     #>SCREEN+32
    BRK_TELEMON XWRCLK
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
    bne     @next
    RETURN_LINE
    PRINT(ORIX_ARGV)
    PRINT(str_command_not_found) ; MACRO
    
    rts	
  
_orix_load_and_start_app_xopen_done:
@next:

    MALLOC(20) ; Malloc 20 bytes (20 bytes for header)
    
    ptr_header:=ZP_APP_PTR1
    
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
    PRINT(ORIX_ARGV)

    PRINT(str_cant_execute)
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
    
    REGISTER_PROCESS(ORIX_ARGV)
    
    bne register_process_valid ; if it's return 0 then there is an error
    PRINT(strMaxProcessReached)
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

_XREAD:
.include "functions/xread.asm"

.proc _getcpu
    lda     #$00
    .byt    $1A        ; .byte $1A ; nop on nmos, "inc A" every cmos
    cmp     #$01
    bne     @is6502Nmos
    lda     #ID_CPU_65C02       ; it's a 65C02
    rts
@is6502Nmos:
    lda     #ID_CPU_6502
    rts
.endproc

.proc _debug

;CPU_6502
    ; routine used for some debug
    PRINT(str_cpu)
    jsr     _getcpu
    cmp     #ID_CPU_65C02
    bne     @is6502
    PRINT(str_65C02)
    RETURN_LINE
.pc02    
    bra     @next        ; At this step we are sure that it's a 65C02, so we use its opcode :)
.p02    
@is6502:
	
    PRINT(str_6502)
	RETURN_LINE
@next:
    PRINT(str_ch376)
    jsr     _ch376_ic_get_ver
    BRK_TELEMON XWR0
    BRK_TELEMON XCRLF
    ;RETURN_LINE
    
    PRINT(str_ch376_check_exist)
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
    .byt <_basic11
    .byt <_banks    
    .byt <_cat
.ifdef WITH_CA65
    .byt <_ca65
.endif    	
    .byt <_cd
    .byt <_clear ; 
    .byt <_cp

    .byt <_date 

.ifdef WITH_DF
    .byt <_df
.endif

    .byt <_ls ; dir (alias)

    .byt <_echo ; 
    .byt <_env

.ifdef WITH_TELEFORTH
    .byt <_forth
.endif

    .byt <_help ;
	
.ifdef WITH_HISTORY
    .byt <_history
.endif   

.ifdef WITH_IOPORT	
    .byt <_ioports ;    
.endif	

.ifdef WITH_LESS
    .byt <_less
.endif    
    
    .byt <_ls
    .byt <_lscpu
    .byt <_lsmem

.ifdef WITH_LSOF
    .byt <_lsof
.endif

    .byt <_man
    .byt <_meminfo
    .byt <_mkdir

.ifdef WITH_MONITOR
    .byt <_monitor
.endif    
    
    .byt <_mv ; is in _cp
    
.ifdef WITH_MOUNT
    .byt <_mount
.endif    

.ifdef WITH_OCONFIG
    .byt <_oconfig
.endif

    .byt <_ps
    .byt <_pwd
    .byt <_rm

.ifdef WITH_SEDSD
    .byt <_sedsd
.endif     
    
.ifdef WITH_SH
    .byt <_sh
.endif 

    .byt <_touch
    .byt <_uname
    
.ifdef WITH_VI
    .byt <_vi
.endif

    .byt <_viewhrs
    .byt <_reboot	
    .byt <_debug	
    
.ifdef WITH_XORIX
    .byt <_xorix
.endif	
  
commands_high:
    .byt >_basic11
    .byt >_banks    
    .byt >_cat

.ifdef WITH_CA65
    .byt >_ca65
.endif	 	

    .byt >_cd
    .byt >_clear
    .byt >_cp

    .byt >_date ; alias()

.ifdef WITH_DF
    .byt >_df
.endif        

    .byt >_ls ; (dir)

    .byt >_echo
    .byt >_env

.ifdef WITH_TELEFORTH
    .byt >_forth
.endif    

    .byt >_help
	
.ifdef WITH_HISTORY
    .byt >_history
.endif   

.ifdef WITH_IOPORT	
    .byt >_ioports
.endif

.ifdef WITH_LESS
    .byt >_less
.endif        

    .byt >_ls
    .byt >_lscpu
    .byt >_lsmem
    
.ifdef WITH_LSOF    
    .byt >_lsof
.endif    
    .byt >_man
    .byt >_meminfo
    .byt >_mkdir

.ifdef WITH_MONITOR
    .byt >_monitor
.endif        
    
    .byt >_mv
    
.ifdef WITH_MOUNT
    .byt >_mount
.endif

.ifdef WITH_OCONFIG
    .byt >_oconfig
.endif
     
    .byt >_ps
    .byt >_pwd
    .byt >_rm

.ifdef WITH_SEDSD
    .byt >_sedsd
.endif  
    
.ifdef WITH_SH
    .byt >_sh
.endif  

    .byt >_touch
    .byt >_uname

.ifdef WITH_VI
    .byt >_vi
.endif
	
    .byt >_viewhrs
    .byt >_reboot
    .byt >_debug	


    
.ifdef WITH_XORIX
    .byt >_xorix
.endif	
    
list_command_low:
    .byt <basic11
    .byt <banks    
    .byt <cat

.ifdef WITH_CA65
    .byt <ca65
.endif		

    .byt <cd
    .byt <clear
    .byt <cp
    .byt <date

.ifdef WITH_DF
    .byt <df
.endif        

    .byt <dir

    .byt <echocmd
    .byt <env

.ifdef WITH_TELEFORTH
    .byt <teleforth
.endif    

    .byt <help
	
.ifdef WITH_HISTORY
    .byt <history
.endif   

.ifdef WITH_IOPORT	
    .byt <ioports
.endif	
    
.ifdef WITH_LESS
    .byt <less
.endif   
    
    .byt <ls
    .byt <lscpu
    .byt <lsmem

.ifdef WITH_LSOF
    .byt <lsof
.endif    

    .byt <man
    .byt <meminfo
    .byt <mkdir

.ifdef WITH_MONITOR
    .byt <monitor
.endif    
    
    .byt <mv
    
.ifdef WITH_MOUNT
    .byt <mount
.endif 

.ifdef WITH_OCONFIG
    .byt <oconfig
.endif
       
    .byt <ps
    .byt <pwd
    .byt <rm

.ifdef WITH_SEDSD
    .byt <sedoric
.endif     
    
.ifdef WITH_SH
    .byt <sh
.endif

    .byt <touch
    .byt <uname

.ifdef WITH_VI
    .byt <vi
.endif    
  
    .byt <viewhrs
    .byt <reboot
    .byt <debug
    
.ifdef WITH_XORIX
    .byt <xorix
.endif	
    
list_command_high:
    .byt >basic11
    .byt >banks    
    .byt >cat
.ifdef WITH_CA65
    .byt >ca65
.endif	 	
    .byt >cd
    .byt >clear
    .byt >cp
    .byt >date

.ifdef WITH_DF
    .byt >df
.endif        
    
    .byt >dir

    .byt >echocmd
    .byt >env
    
.ifdef WITH_TELEFORTH
    .byt >teleforth
.endif    
    .byt >help

.ifdef WITH_HISTORY
    .byt >history
.endif   

.ifdef WITH_IOPORT	
    .byt >ioports 
.endif	
    
.ifdef WITH_LESS
    .byt >less
.endif    

    .byt >ls
    .byt >lscpu
    .byt >lsmem
  
.ifdef WITH_LSOF    
    .byt >lsof
.endif

    .byt >man
    .byt >meminfo
    .byt >mkdir
    
.ifdef WITH_MONITOR
    .byt >monitor
.endif
    
    .byt >mv

.ifdef WITH_MOUNT
    .byt >mount
.endif 

.ifdef WITH_OCONFIG
    .byt >oconfig
.endif 
         
    .byt >ps
    .byt >pwd
    .byt >rm

.ifdef WITH_SEDSD
    .byt >sedoric
.endif 

.ifdef WITH_SH
    .byt >sh
.endif

    .byt >touch
    .byt >uname    

.ifdef WITH_VI
    .byt  >vi
.endif

    .byt >viewhrs
    .byt >reboot
    .byt >debug
   
.ifdef WITH_XORIX
    .byt >xorix
.endif	

commands_length:
    .byt 7 ; _basic11
    .byt 4 ; _banks
    .byt 3 ; _cat
.ifdef WITH_CA65
    .byt 4 ;ca65
.endif		
    .byt 2 ; _cd
    .byt 5 ; _clear ; 
    .byt 2 ; _cp
    .byt 4 ; _date 

.ifdef WITH_DF    
    .byt 2 ; _df ;     
.endif
    .byt 3 ; _ls ; dir (alias)

    .byt 4 ; _echo ; 
    .byt 3 ; _env

.ifdef WITH_TELEFORTH
    .byt 5 ; teleforth
.endif 

    .byt 4 ; _help ; 
	
.ifdef WITH_HISTORY
    .byt 7 ; history
.endif   

.ifdef WITH_IOPORT	
    .byt 7 ; _ioports
.endif	

.ifdef WITH_LESS
    .byt 4 ;_less
.endif

    .byt 2 ; _ls
    .byt 5
    .byt 5 ; lsmem

.ifdef WITH_LSOF
    .byt 4 ; lsof
.endif

    .byt 3 ; man
    .byt 7 ; meminfo
    .byt 5 ; _mkdir

.ifdef WITH_MONITOR
    .byt 7 ; monitor
.endif          
    
    .byt 2 ; mv
    
.ifdef WITH_MOUNT
    .byt 5 ; mount
.endif            

.ifdef WITH_OCONFIG
    .byt 7 ; oconfig
.endif

    .byt 2 ; ps
    .byt 3 ; _pwd
    .byt 2 ; rm

.ifdef WITH_SEDSD
    .byt 7
.endif     
    
.ifdef WITH_SH
    .byt 2 ; sh
.endif   

    .byt 5 ; touch
    .byt 5 ;_uname
    
.ifdef WITH_VI
    .byt 2
.endif

    .byt 7
    .byt 6 ;_reboot	
    .byt 5 ;_debug	

.ifdef WITH_XORIX
    .byt 5 ;xorix
.endif	    
    
basic11:
    .asciiz "basic11"
banks:
    .asciiz "bank"
cat:
    .asciiz "cat"
cd:
    .asciiz "cd"
clear:
    .asciiz "clear"
cp:
    .asciiz "cp"
date:
    .asciiz "date"
df:
    .asciiz "df"
dir:
    .asciiz "dir"
echocmd:
    .asciiz "echo"
env:
    .asciiz "env"

.ifdef WITH_TELEFORTH    
teleforth:
    .asciiz "forth"
.endif

help:
    .asciiz "help"
history:
    .asciiz "history"

.ifdef WITH_IOPORT	
ioports:
    .asciiz "ioports"
.endif
	
kill:
    .asciiz "kill"
less:
    .asciiz "less"
ls:
    .asciiz "ls"
lscpu:
    .asciiz "lscpu"
lsmem:	
    .asciiz "lsmem"
lsof:	
    .asciiz "lsof"
man:
    .asciiz "man"  
meminfo:
    .asciiz "meminfo"
mkdir:
    .asciiz "mkdir"
monitor:
    .asciiz "monitor"
mount:
    .asciiz "mount"
mv:
    .asciiz "mv"
    
.ifdef WITH_OCONFIG
oconfig:
    .asciiz "oconfig"
.endif           

rm:
    .asciiz "rm"
ps:
    .asciiz "ps"
pwd:
    .asciiz "pwd"
reboot:
    .asciiz "reboot"
sedoric:
    .asciiz "sedoric"
sh:
    .asciiz "sh"
tree:
    .asciiz "tree"
touch:
    .asciiz"touch"
uname:
    .asciiz "uname"
vi:
    .asciiz "vi"
viewhrs:
    .asciiz "viewhrs"
xorix:
    .asciiz "xorix"
ca65:
    .asciiz "c"
debug:
    .asciiz "debug"
   
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

.ifndef  __DATEBUILT__
.define __DATEBUILT__ "10/09/2016"
.endif
str_compile_time:
    .byte "Build : ","__DATEBUILT__"," "
	
.IFPC02
cpu_build:
    .asciiz "65C02"
.else
cpu_build:
    .asciiz "6502"
.endif

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
.asciiz  "Orix - __DATEBUILT__"
.include "tables/text_first_line_adress.asm"  

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
  sta LIST_PID,x                ; destroy the PID in ps table
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
    .byt <_orix_register_filehandle ;0
    .byt <_orix_register_process    ;1 
    .byt <_orix_unregister_process  ;2

ORIX_ROUTINES_TABLE_HIGH:
    .byt >_orix_register_filehandle
    .byt >_orix_register_process
    .byt >_orix_unregister_process


    .res $FFE0-*
    .org $FFE0

_call_orix_routine:
    ldx TR0
    lda ORIX_ROUTINES_TABLE_LOW,x
    sta RES
    lda ORIX_ROUTINES_TABLE_HIGH,x
    sta RES+1
    jmp (RES)


    .res $FFF8-*
    .org $FFF8



; fffa

copyright:
    .word signature

NMI:
	.word start_orix

; fffc
RESET:
    .word start_orix
; fffe
BRK_IRQ:	
    .byt IRQVECTOR

	

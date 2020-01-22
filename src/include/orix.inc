



NULL                          =  $00
XDIVIDE_INTEGER32_BY_1024     =  $1E

OFFSET_TO_READ_BYTE_INTO_BANK := $32
ID_BANK_TO_READ_FOR_READ_BYTE := $34
ptr1_32                       := $33

;SWITCH_TO_BANK_ID             := $040C

ATMOS_ID_BANK                 = 6
ORIX_ID_BANK                  = 5
MONITOR_ID_BANK               = 4
TELEFORTH_ID_BANK     	      = 3


ORIX_MAX_OPEN_FILES           = 2
SIZE_OF_VOLATILE_STR          = 50      ; can't be below 20 because it's used to load Orix header


SIZE_OF_STACK_BANK            =  1

XOPENRELATIVE                 = $31

NEXT_STACK_BANK               :=$418


.org $4c7
.bss
;*=end_of_copy_page4-begin_of_copy_page4
FIXME_DUNNO:
    .res 1
STACK_BANK:
    .res SIZE_OF_STACK_BANK
READ_BYTE_FROM_OVERLAY_RAM:
    .res 1

; 6522
.org $500
.bss
; could be removed ... when lsof will be finished
NUMBER_OPENED_FILES: ; ALIAS but in stratsed it's $549
    .res 1
; RemoveME when  ERRNO will move
REMOVEME2:
    .res 1
    ; not removed because it could be declared too in kernel
    ; It could remove as soon as others variables are checked
REMOVEME: 
    .res 1
GETOPT_PTR:
    .res 1 ; Store the index of the current opt
TEMP_ORIX_1:
    .res 1
ORIX_ARGC:
    .res 1
; could be removed ...  until ERRNO is moved somewhere
ORIX_GETOPT_PTR:
    .res 1
; RemoveME when  ERRNO will move
REMOVEME3:
    .res 1
; RemoveME when  ERRNO will move
REMOVEME4:
    .res 1
ERRNO:
    .res 1

.org BUFNOM+14
.bss


ORIX_MALLOC_FREE_TABLE:
; (adress begin) (adress_end) (size of chunk 16 bit)
ORIX_MALLOC_FREE_BEGIN_LOW_TABLE:
    .res ORIX_MALLOC_FREE_FRAGMENT_MAX
ORIX_MALLOC_FREE_BEGIN_HIGH_TABLE:
    .res ORIX_MALLOC_FREE_FRAGMENT_MAX

ORIX_MALLOC_FREE_END_LOW_TABLE:
    .res ORIX_MALLOC_FREE_FRAGMENT_MAX
ORIX_MALLOC_FREE_END_HIGH_TABLE:
    .res ORIX_MALLOC_FREE_FRAGMENT_MAX

MEMFREE:
ORIX_MALLOC_FREE_SIZE_LOW_TABLE:
    .res ORIX_MALLOC_FREE_FRAGMENT_MAX
ORIX_MALLOC_FREE_SIZE_HIGH_TABLE:
    .res ORIX_MALLOC_FREE_FRAGMENT_MAX
    .res 2 ; For 32 bits management

ORIX_MALLOC_FREE_TABLE_NUMBER:
; it contains the number of free chuncks
    .res 1

; Busy table
ORIX_MALLOC_BUSY_TABLE:
ORIX_MALLOC_BUSY_TABLE_BEGIN_LOW:
    .res ORIX_NUMBER_OF_MALLOC
ORIX_MALLOC_BUSY_TABLE_BEGIN_HIGH:
    .res ORIX_NUMBER_OF_MALLOC
ORIX_MALLOC_BUSY_TABLE_END_LOW:
    .res ORIX_NUMBER_OF_MALLOC
ORIX_MALLOC_BUSY_TABLE_END_HIGH:
    .res ORIX_NUMBER_OF_MALLOC
ORIX_MALLOC_BUSY_TABLE_SIZE_LOW:
    .res ORIX_NUMBER_OF_MALLOC
ORIX_MALLOC_BUSY_TABLE_SIZE_HIGH:
    .res ORIX_NUMBER_OF_MALLOC

; We store the PID of the malloc
ORIX_MALLOC_BUSY_TABLE_PID:
    .res ORIX_NUMBER_OF_MALLOC

ORIX_MALLOC_BUSY_TABLE_NUMBER:
    .res 1

.org BUFEDT+BASH_MAX_BUFEDT_LENGTH
.bss
ORIX_ARGV_NAME:
    .res    MAX_LENGTH_OF_FILES  ; name
ORIX_ARGV:
	.res    MAX_LENGTH_OF_FILES*BASH_MAX_ARGS
; used to check term


volatile_str:
    .res SIZE_OF_VOLATILE_STR



shell_bash_variables:
    .tag shell_bash_struct    
; ptr of LIST_NAME_PID
orix_end_memory_kernel:
    .res 1

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
    BRK_ORIX XDECIM
    ;.byte $00,XDECIM
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

; This macro must be placed after MALLOC call
.macro TEST_OOM_AND_MAX_MALLOC
    ; Test if we reached the max number of malloc chunk
    cpx     #ORIX_NUMBER_OF_MALLOC
    bne     @check_for_oom_TEST_OOM_AND_MAX_MALLOC
    ; We reachead max malloc available
    PRINT   str_max_malloc_reached
    RETURN_LINE
    rts
    ; check if malloc is null, if it's equal, displays Out of Memory
@check_for_oom_TEST_OOM_AND_MAX_MALLOC:
    cmp     #NULL
    bne     @TEST_OOM_AND_MAX_MALLOC
    cpy     #NULL
    bne     @TEST_OOM_AND_MAX_MALLOC
    PRINT   str_out_of_memory
    RETURN_LINE
    ; We reached OOM
    rts
@TEST_OOM_AND_MAX_MALLOC: 
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

.ifdef WITH_BANK
    BANK=1
.else
    BANK=0
.endif

.ifdef WITH_BASIC11
    BASIC11=1
.else
    BASIC11=0
.endif

.ifdef WITH_CAT
    CAT=1
.else
    CAT=0
.endif

.ifdef WITH_CLEAR
    CLEAR=1
.else
    CLEAR=0
.endif

.ifdef WITH_CD
    CD=1
.else
    CD=0
.endif

.ifdef WITH_CP
    CP=1
.else
    CP=0
.endif

.ifdef WITH_DATE
    DATE=1
.else
    DATE=0
.endif

.ifdef WITH_DEBUG
    DEBUG=1
.else
    DEBUG=0
.endif

.ifdef WITH_DF
    DF=1
.else
    DF=0
.endif

.ifdef WITH_ECHO
    ECHO=1
.else
    ECHO=0
.endif

.ifdef WITH_ENV
    ENV=1
.else
    ENV=0
.endif

.ifdef WITH_EXEC
    EXEC=1
.else
    EXEC=0
.endif

.ifdef WITH_HELP
    HELP=1
.else
    HELP=0
.endif

.ifdef WITH_IOPORT
    IOPORT=1
.else
    IOPORT=0
.endif

.ifdef WITH_LS
    LS=1
.else
    LS=0
.endif

.ifdef WITH_LSCPU
    LSCPU=1
.else
    LSCPU=0
.endif

.ifdef WITH_LSMEM
    LSMEM=1
.else
    LSMEM=0
.endif

.ifdef WITH_LSOF
    LSOF=1
.else
    LSOF=0
.endif

.ifdef WITH_MAN
    MAN=1
.else
    MAN=0
.endif

.ifdef WITH_MEMINFO
    MEMINFO=1
.else
    MEMINFO=0
.endif

.ifdef WITH_MKDIR
    MKDIR_COMMAND=1
.else
    MKDIR_COMMAND=0
.endif

.ifdef WITH_LESS
    LESS=1
.else
    LESS=0
.endif

.ifdef WITH_MONITOR
    MONITOR=1   
.else
    MONITOR=0
.endif

.ifdef WITH_CA65
    CA65=1
.else
    CA65=0
.endif

.ifdef WITH_MOUNT
    MOUNT=1
.else
    MOUNT=0
.endif

.ifdef WITH_MV
    MV=1
.else
    MV=0
.endif

.ifdef WITH_OCONFIG
    OCONFIG=1
.else
    OCONFIG=0
.endif

.ifdef WITH_PS
    PS=1
.else
    PS=0
.endif

.ifdef WITH_PSTREE
    PSTREE=1
.else
    PSTREE=0
.endif

.ifdef WITH_PWD
    PWD=1
.else
    PWD=0
.endif

.ifdef WITH_RM
    RM=1
.else
    RM=0
.endif

.ifdef WITH_REBOOT
    REBOOT=1
.else
    REBOOT=0
.endif

.ifdef WITH_SEDSD
    SEDSD=1
.else
    SEDSD=0
.endif

.ifdef WITH_TELNETD
    TELNETD=1
.else
    TELNETD=0
.endif

.ifdef WITH_TOUCH
    TOUCH=1
.else
    TOUCH=0
.endif

.ifdef WITH_TREE
    TREE=1
.else
    TREE=0
.endif

.ifdef WITH_UNAME
    UNAME=1
.else
    UNAME=0
.endif

.ifdef WITH_WATCH
    WATCH=1
.else
    WATCH=0
.endif

.ifdef WITH_SH
    SH=1
.else
    SH=0
.endif

.ifdef WITH_SETFONT
    SETFONT=1
.else
    SETFONT=0
.endif

.ifdef WITH_MORE
    MORE=1
.else
    MORE=0
.endif

.ifdef WITH_CPUINFO
    CPUINFO=1
.else
    CPUINFO=0
.endif

.ifdef WITH_KILL
    KILL = 1
.else
    KILL = 0
.endif

.ifdef WITH_HISTORY
    HISTORY=1
.else
    HISTORY=0
.endif

.ifdef WITH_VIEWHRS
    VIEWHRS=1
.else
    VIEWHRS=0
.endif

.ifdef WITH_VI
    VI=1
.else
    VI=0
.endif

.ifdef WITH_XORIX
    XORIX=1
.else
    XORIX=0
.endif

.ifdef WITH_FORTH
    FORTH=1
.else
    FORTH=0
.endif

.ifdef WITH_TWILIGHT
    TWILIGHT=1
.else
    TWILIGHT=0
.endif
;OCONFIG+LSOF+DF+VI+TREE+SH+MORE+LESS+SEDSD+CPUINFO+BANK+KILL+HISTORY+XORIX+MOUNT+MONITOR+CA65+TELEFORTH
BASH_NUMBER_OF_COMMANDS=1+BASIC11+CD+CP+CAT+CLEAR+DEBUG+DF+DATE+ECHO+ENV+EXEC+FORTH+HELP+HISTORY+IOPORT+KILL+LESS+LS+BANK+LSCPU+LSOF+LSMEM+MAN+MOUNT+MEMINFO+MKDIR_COMMAND+MONITOR+MV+PS+PSTREE+PWD+REBOOT+RM+SETFONT+SH+UNAME+VI+VIEWHRS+TELNETD+TOUCH+TWILIGHT+TREE+WATCH+XORIX

COLOR_FOR_FILES =             $87 ; colors when ls displays files 
COLOR_FOR_DIRECTORY  =        $86 ; colors when ls display directory

userzp                  :=	VARLNG

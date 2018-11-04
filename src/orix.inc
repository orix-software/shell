
WITH_BANK=1
WITH_CLEAR=1
WITH_DATE=1
WITH_ENV=1
WITH_HELP=1
WITH_IOPORT=1
WITH_LS=1
WITH_LSCPU=1
WITH_LSOF=1
WITH_MAN=1
WITH_MOUNT=1
WITH_MV=1
WITH_MEMINFO=1
WITH_MKDIR=1
WITH_MONITOR=1
WITH_RM=1

XDIVIDE_INTEGER32_BY_1024=$1E

OFFSET_TO_READ_BYTE_INTO_BANK := $32
ID_BANK_TO_READ_FOR_READ_BYTE := $34
ptr1_32                       := $33

SWITCH_TO_BANK_ID             := $040C

ORIX_ID_BANK                  = 5
MONITOR_ID_BANK               = 4


PATH_CURRENT_MAX_LEVEL        = 4       ; Only in telemon 3.0 number of level, if we add more, we should have to many RAM, if you need to set more level add bytes here : ptr_path_current_low and ptr_path_current_high
MAX_LENGTH_OF_FILES           = 9       ;  We say 8 chars for directory and end of string
MAX_LENGTH_OF_A_COMMAND       = 9
MAX_ARGS                      = 3       ;  Number of possible args in the command line
ORIX_MAX_PROCESS              = 4
ORIX_NUMBER_OF_MALLOC         = 3
ORIX_MALLOC_FREE_FRAGMENT_MAX = 6
ORIX_MALLOC_MAX_MEM_ADRESS    = $B3FF
ORIX_MAX_OPEN_FILES           = 2
SIZE_OF_VOLATILE_STR          = 50      ; can't be below 20 because it's used to load Orix header
KEY_LCTRL                     = 5
KET_RCTRL                     = 6
KEY_LSHIFT                    = 7
KEY_RSHIFT                    = 8
KEY_FUNCT		              = 9
KEY_LEFT		              = 8
KEY_RIGHT		              = 9
KEY_DOWN		              = 10
KEY_UP			              = 11

SIZE_OF_STACK_BANK            =  1

KEY_RETURN                    = $0D
KEY_ESC                       = $1B
KEY_DEL                       = $7F
XOPENRELATIVE                 = $31

NEXT_STACK_BANK               :=$418


ORIX_MAX_PATH_LENGTH = MAX_LENGTH_OF_FILES*PATH_CURRENT_MAX_LEVEL+PATH_CURRENT_MAX_LEVEL

MAX_LENGTH_BUFEDT     =  ORIX_MAX_PATH_LENGTH+9

ORIX_MAX_MAX_LENGTH_BUFEDT     =  ORIX_MAX_PATH_LENGTH+9

ORIX_MALLOC_FREE_TABLE_SIZE  = 3*ORIX_MALLOC_FREE_FRAGMENT_MAX
ORIX_MALLOC_BUSY_TABLE_SIZE  = 6*ORIX_NUMBER_OF_MALLOC


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
NUMBER_OPENED_FILES: ; ALIAS but in stratsed it's $549
    .res 1
TEMP_ORIX_2:
    .res 1
NUMBER_OF_COLUMNS:
    .res 1
GETOPT_PTR:
    .res 1 ; Store the index of the current opt
TEMP_ORIX_1:
    .res 1
ORIX_ARGC:
    .res 1
ORIX_GETOPT_PTR:
    .res 1
ORIX_PATH_CURRENT_POSITION:
    .res 1
ORIX_CURRENT_PROCESS_MULTITASKING:
    .res 1
ERRNO:
    .res 1
TERM:
    .res 1
TEMP_SH_COMMAND: ; For sh command only
    .res 2
ORIX_CURRENT_PROCESS_FOREGROUND:
    .res 1
MEMTOTAL:
    .res 4 ; Store the length of the RAM in bytes

.org BUFNOM+14
.bss
ORIX_PATH_CURRENT:
    .res ORIX_MAX_PATH_LENGTH,0

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

.org BUFEDT+MAX_LENGTH_BUFEDT
.bss
ORIX_ARGV_NAME:
    .res    MAX_LENGTH_OF_FILES  ; name
ORIX_ARGV:
	.res    MAX_LENGTH_OF_FILES*MAX_ARGS
; used to check term



volatile_str:
    .res SIZE_OF_VOLATILE_STR

LIST_PID:
    .res ORIX_MAX_PROCESS
LIST_NAME_PID:
    .res 9*ORIX_MAX_PROCESS
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

.ifdef WITH_BANK
    BANK=1
.else
    BANK=0
.endif

.ifdef WITH_DATE
    DATE=1
.else
    DATE=0
.endif

.ifdef WITH_CLEAR
    CLEAR=1
.else
    CLEAR=0
.endif

.ifdef WITH_ENV
    ENV=1
.else
    ENV=0
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

.ifdef WITH_OCONFIG
.define OCONFIG 1
.else
.define OCONFIG 0
.endif

.ifdef WITH_MONITOR
MONITOR=1
.else
MONITOR=0
.endif

.ifdef WITH_CA65
.define CA65 1
.else
.define CA65 0
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

.ifdef WITH_RM
    RM=1
.else
    RM=0
.endif

.ifdef WITH_DEBUG
.define DEBUG 1
.else
.define DEBUG 0
.endif

.ifdef WITH_DF
    DF=1
.else
    DF=0
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

.ifdef WITH_KILL
    KILL = 1
.else
    KILL = 0
.endif

.ifdef WITH_HISTORY
.define HISTORY 1
.else
.define HISTORY 0
.endif

.ifdef WITH_XORIX
    XORIX=1
.else
    XORIX=0
.endif

.ifdef WITH_TELEFORTH
.define TELEFORTH 1
.else
.define TELEFORTH 0
.endif
;OCONFIG+LSOF+DF+VI+TREE+SH+MORE+LESS+SEDSD+CPUINFO+BANK+KILL+HISTORY+XORIX+MOUNT+MONITOR+CA65+TELEFORTH
BASH_NUMBER_OF_COMMANDS=1+CLEAR+DF+DATE+ENV+HELP+IOPORT+KILL+LS+BANK+LSCPU+LSOF+MAN+MOUNT+MEMINFO+MONITOR+MV+RM+XORIX

COLOR_FOR_FILES =             $87 ; colors when ls displays files 
COLOR_FOR_DIRECTORY  =        $86 ; colors when ls display directory

userzp                  :=	VARLNG

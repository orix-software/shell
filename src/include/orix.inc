NULL                          =  $00
XDIVIDE_INTEGER32_BY_1024     =  $1E

OFFSET_TO_READ_BYTE_INTO_BANK := $32
ID_BANK_TO_READ_FOR_READ_BYTE := $34
ptr1_32                       := $33

;SWITCH_TO_BANK_ID             := $040C

ATMOS_ID_BANK                 = 6
ORIX_ID_BANK                  = 5

.org $4C7
.bss
;*=end_of_copy_page4-begin_of_copy_page4
;FIXME_DUNNO:
    ;.res 2
READ_BYTE_FROM_OVERLAY_RAM:
    .res 1

; 6522

.org BUFEDT
.res 110
ORIX_ARGV:
	.res    MAX_LENGTH_OF_FILES*BASH_MAX_ARGS
TEMP_ORIX_1:
    .res 1
ORIX_ARGC:
    .res 1
.out     .sprintf("ORIX_ARGV  : %x", ORIX_ARGV)
.out     .sprintf("ORIX_ARGC  : %x", ORIX_ARGC)

.macro  BRK_ORIX   value
	.byte $00,value
.endmacro
 
.macro RETURNVAL value
  lda #value
  sta KERNEL_ERRNO
.endmacro
  
.macro RETURN0
    lda #$00
    sta KERNEL_ERRNO  
.endmacro

.macro PRINT_BINARY_TO_DECIMAL_16BITS justif
    LDX #$20
    STX DEFAFF
    LDX #justif
    BRK_KERNEL XDECIM
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
  BRK_KERNEL XFILLM
.endmacro
   
.macro SWITCH_ON_CURSOR
  ldx #$00
  BRK_KERNEL XCSSCR
.endmacro  

.macro SWITCH_OFF_CURSOR
	ldx #$00
	BRK_KERNEL XCOSCR
.endmacro    

.macro HIRES
	BRK_KERNEL XHIRES
.endmacro    

; O_WRONLY
; O_RDONLY   
.macro FOPEN file, mode
  lda   #<file
  ldx   #>file
  ldy   #mode
  .byte $00,XOPEN
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
    BRK_KERNEL XFREAD
.endmacro

; This macro must be placed after MALLOC call
.macro TEST_OOM_AND_MAX_MALLOC
    ; Test if we reached the max number of malloc chunk
    cpx     #KERNEL_MAX_NUMBER_OF_MALLOC
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
    BRK_KERNEL XRDW0 
.endmacro    
    
.macro MALLOC size 
  lda #<size
  ldy #>size
  BRK_KERNEL XMALLOC
.endmacro

.macro CPUTC char
  lda #char
  BRK_KERNEL XWR0
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
	BRK_KERNEL XWSTR0
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
  BRK_KERNEL XCRLF
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



.ifdef WITH_ENV
    ENV=1
.else
    ENV=0
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

.ifdef WITH_ORICSOFT
    ORICSOFT=1
.else
    ORICSOFT=0
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

BASH_NUMBER_OF_COMMANDS=BASIC11+CP+CAT+CLEAR+DEBUG+DF+DATE+ENV+FORTH+HISTORY+IOPORT+KILL+LESS+LS+BANK+LSCPU+LSOF+LSMEM+MAN+MOUNT+MEMINFO+MKDIR_COMMAND+MV+ORICSOFT+PS+PSTREE+REBOOT+RM+SETFONT+SH+UNAME+VI+VIEWHRS+TELNETD+TOUCH+TWILIGHT+TREE+WATCH+XORIX

COLOR_FOR_FILES =             $87 ; colors when ls displays files 
COLOR_FOR_DIRECTORY  =        $86 ; colors when ls display directory

userzp                  :=	VARLNG

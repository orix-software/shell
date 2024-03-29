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
;ORIX_ARGV:
.res 110


.macro  BRK_ORIX   value
	.byte $00,value
.endmacro

.macro RETURNVAL value
  lda #value
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

; This macro must be placed after MALLOC call
.macro TEST_OOM
    ; check if malloc is null, if it's equal, displays Out of Memory
    cmp     #NULL
    bne     *+15
    cpy     #NULL
    bne     *+11
    lda     #<str_oom
    ldy     #>str_oom
    BRK_KERNEL XWSTR0
    BRK_KERNEL XCRLF
    ; We reached OOM
    rts

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

.ifdef WITH_BASIC10
    BASIC10=1
.else
    BASIC10=0
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

.ifdef WITH_TWILIGHT
    TWILIGHT=1
.else
    TWILIGHT=0
.endif

BASH_NUMBER_OF_COMMANDS=BASIC10+BASIC11+CP+CAT+CLEAR+DEBUG+DF+DATE+ENV+HISTORY+IOPORT+KILL+LESS+LS+BANK+LSCPU+LSOF+LSMEM+MAN+MOUNT+MEMINFO+MKDIR_COMMAND+MV+PS+PSTREE+REBOOT+RM+SETFONT+SH+UNAME+VI+VIEWHRS+TOUCH+TWILIGHT+TREE+WATCH+XORIX+2

COLOR_FOR_FILES =             $87 ; colors when ls displays files
COLOR_FOR_DIRECTORY  =        $86 ; colors when ls display directory



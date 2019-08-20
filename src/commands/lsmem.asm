.export _lsmem

.proc _lsmem

   lsmem_ptr_malloc     := userzp
   lsmem_ptr_pid_table  := userzp+2	 ; Get struct
   lsmem_ptr            := userzp+4 
   lsmem_savey          := userzp+6  ; 1 byte
   lsmem_savex          := userzp+7  ; 1 byte

   ldx     #XVARS_KERNEL_PROCESS  ; Get adress struct of process from kernel
   BRK_ORIX(XVARS)
   sta     lsmem_ptr_pid_table
   sty     lsmem_ptr_pid_table+1


   ldx     #XVARS_KERNEL_MALLOC ; Get adress struct of malloc from kernel
   BRK_ORIX(XVARS)
   sta     lsmem_ptr_malloc
   sty     lsmem_ptr_malloc+1

   PRINT   str_column


; Displays all free chunk 

   ldx     #$00
    
@L1:
    stx     lsmem_savex
    ; looking if there is free chunk set
    lda     ORIX_MALLOC_FREE_BEGIN_HIGH_TABLE,x
    bne     @S4
    lda     ORIX_MALLOC_FREE_BEGIN_LOW_TABLE,x
    bne     @S4
    beq     @S5

@S4:
    PRINT   str_FREE
    lda     ORIX_MALLOC_FREE_BEGIN_HIGH_TABLE,x
    jsr     _print_hexa
        
    lda     ORIX_MALLOC_FREE_BEGIN_LOW_TABLE,x
    jsr     _print_hexa_no_sharp
        
    CPUTC   ':'
      
    lda     ORIX_MALLOC_FREE_END_HIGH_TABLE,x
    jsr     _print_hexa
     
        
    lda     ORIX_MALLOC_FREE_END_LOW_TABLE,x
    jsr     _print_hexa_no_sharp
        
    CPUTC   ' '
        
    lda     ORIX_MALLOC_FREE_SIZE_HIGH_TABLE,x
    jsr    _print_hexa
        
    lda    ORIX_MALLOC_FREE_SIZE_LOW_TABLE,x
    jsr    _print_hexa_no_sharp
    
    BRK_ORIX XCRLF
        
@S5:
    ldx     lsmem_savex
    inx 
    cpx     #KERNEL_MALLOC_FREE_FRAGMENT_MAX
    bne     @L1

; Displays all busy chunk 

    ldx #$00


myloop2:

    lda ORIX_MALLOC_BUSY_TABLE_PID,x

    beq busy_chunk_is_empty             ; If malloc pid table is equal to 0 at position X, then there is nothing allocated
    
    ; at this step X contains the first busy chunck    
    stx lsmem_savex

        
        
    PRINT str_BUSY

    ; Get start adress of busy chunk
    ldx lsmem_savex
    lda ORIX_MALLOC_BUSY_TABLE_BEGIN_HIGH,x
    jsr _print_hexa
    lda ORIX_MALLOC_BUSY_TABLE_BEGIN_LOW,x
    jsr _print_hexa_no_sharp
        
    CPUTC ' '

    lda ORIX_MALLOC_BUSY_TABLE_END_HIGH,x
    jsr _print_hexa
    lda ORIX_MALLOC_BUSY_TABLE_END_LOW,x
    jsr _print_hexa_no_sharp
        
        
    CPUTC ' '

    lda ORIX_MALLOC_BUSY_TABLE_SIZE_HIGH,x
    jsr _print_hexa
    lda ORIX_MALLOC_BUSY_TABLE_SIZE_LOW,x
    jsr _print_hexa_no_sharp

    CPUTC ' '

	; display process now
    txa
    clc
    adc     #kernel_malloc_struct::kernel_malloc_pid_list
    ;sta     $7000
    tay

    lda     (lsmem_ptr_malloc),y

    ; we get the process position, now let's get it's name

    pha
    clc
    adc     #kernel_process_struct::kernel_one_process_struct_ptr_low
    tay

    lda     (lsmem_ptr_pid_table),y
    sta     lsmem_ptr

    pla

    clc
    adc     #kernel_process_struct::kernel_one_process_struct_ptr_high
    tay
    lda     (lsmem_ptr_pid_table),y
    sta     lsmem_ptr+1

    ; At this step lsmem_ptr is the first char of the name of the command
    ldy     #$00
@L1:
    lda     (lsmem_ptr),y
    beq     @S1
    sty     lsmem_savey
    BRK_ORIX XWR0
    ldy     lsmem_savey
    iny
    bne     @L1

@S1:

    BRK_TELEMON XCRLF
    ; save X
    ldx     lsmem_savex

busy_chunk_is_empty:
    inx
    cpx     #KERNEL_MAX_NUMBER_OF_MALLOC
    bne     myloop2


skip:

    rts
str_column:
    .byte "TYPE  START END   SIZE  PROGRAM  CHUNK",$0D,$0A,0    

str_empty_program:
    .asciiz "       "
str_FREE:
    .asciiz "Free  "


str_BUSY:
    .asciiz "Busy  "
str_SIZE:
    .asciiz "Size:"
.endproc


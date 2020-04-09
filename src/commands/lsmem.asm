.export _lsmem

.proc _lsmem

   lsmem_ptr_malloc     := userzp
   lsmem_ptr_pid_table  := userzp+2	 ; Get struct
   lsmem_ptr            := userzp+4 
   lsmem_savey          := userzp+6  ; 1 byte
   lsmem_savex          := userzp+7  ; 1 byte
   lsmem_savexbis          := userzp+8  ; 1 byte

   lsmem_savey_kernel_malloc_busy_pid_list := userzp+8

   ldx     #XVARS_KERNEL_PROCESS  ; Get adress struct of process from kernel
   BRK_KERNEL XVARS
   sta     lsmem_ptr_pid_table
   sty     lsmem_ptr_pid_table+1


   ldx     #XVARS_KERNEL_MALLOC ; Get adress struct of malloc from kernel
   BRK_KERNEL XVARS
   sta     lsmem_ptr_malloc
   sty     lsmem_ptr_malloc+1

   PRINT   str_column

; Displays all free chunk 

    ldx     #$00
    
@L1:
    stx     lsmem_savex
    ; looking if there is free chunk set
    txa
    clc
    adc     #kernel_malloc_struct::kernel_malloc_free_chunk_begin_high
    tay
    lda     (lsmem_ptr_malloc),y

    bne     @S4
    txa
    clc
    adc     #kernel_malloc_struct::kernel_malloc_free_chunk_begin_low
    tay
    lda     lsmem_ptr_malloc
    lda     lsmem_ptr_malloc+1

    lda     (lsmem_ptr_malloc),y
    
    
    bne     @S4
    beq     @S5

@S4:
    PRINT   str_FREE
    txa
    clc
    adc     #kernel_malloc_struct::kernel_malloc_free_chunk_begin_high
    tay
    lda     (lsmem_ptr_malloc),y
  
    jsr     _print_hexa

    txa
    clc
    adc     #kernel_malloc_struct::kernel_malloc_free_chunk_begin_low
    tay
    lda     (lsmem_ptr_malloc),y



    jsr     _print_hexa_no_sharp
        
    CPUTC   ':'

    txa
    clc
    adc     #kernel_malloc_struct::kernel_malloc_free_chunk_end_high
    tay
    lda     (lsmem_ptr_malloc),y
    

    jsr     _print_hexa

    txa
    clc
    adc     #kernel_malloc_struct::kernel_malloc_free_chunk_end_low
    tay
    lda     (lsmem_ptr_malloc),y
       
    jsr     _print_hexa_no_sharp
    
    stx     lsmem_savexbis
        
    CPUTC   ' '
  ; Affichage de la size free
    lda     lsmem_savexbis
    clc
    adc     #kernel_malloc_struct::kernel_malloc_free_chunk_size_high
    tay
    lda     (lsmem_ptr_malloc),y

    jsr     _print_hexa

    lda     lsmem_savexbis
    clc
    adc     #kernel_malloc_struct::kernel_malloc_free_chunk_size_low
    tay
    lda     (lsmem_ptr_malloc),y

    jsr    _print_hexa_no_sharp
    
    BRK_KERNEL XCRLF
        
@S5:
    ldx     lsmem_savex
    inx 
    cpx     #KERNEL_MALLOC_FREE_FRAGMENT_MAX
    bne     @L1

; Displays all busy chunk 
; ******************************************************************************************
; ******************************************************************************************
    ldx     #$00

    ldy     #kernel_malloc_struct::kernel_malloc_busy_pid_list
myloop2:
    
    lda     (lsmem_ptr_malloc),y

    beq     busy_chunk_is_empty             ; If malloc pid table is equal to 0 at position X, then there is nothing allocated
    
    ; at this step X contains the first busy chunck    
    stx     lsmem_savex
    sty     lsmem_savey_kernel_malloc_busy_pid_list     
        
    PRINT str_BUSY

    ; Get start adress of busy chunk

    ; Displays the beginning of the Offset (busy)
    ldx     lsmem_savex

    txa
    clc
    adc     #kernel_malloc_struct::kernel_malloc_busy_chunk_begin_high
    tay
    lda     (lsmem_ptr_malloc),y
    jsr     _print_hexa

   ; Displays the low Offset (busy)
    txa
    clc
    adc     #kernel_malloc_struct::kernel_malloc_busy_chunk_begin_low
    tay
    lda     (lsmem_ptr_malloc),y
    jsr     _print_hexa_no_sharp
        
    CPUTC ':'

    ldx     lsmem_savex
    txa
    clc
    adc     #kernel_malloc_struct::kernel_malloc_busy_chunk_end_high
    tay
    lda     (lsmem_ptr_malloc),y
    jsr     _print_hexa

    txa
    clc
    adc     #kernel_malloc_struct::kernel_malloc_busy_chunk_end_low
    tay
    lda     (lsmem_ptr_malloc),y
    jsr     _print_hexa_no_sharp
        
        
    CPUTC ' '

    ldx     lsmem_savex
    txa
    clc
    adc     #kernel_malloc_struct::kernel_malloc_busy_chunk_size_high
    tay
    lda     (lsmem_ptr_malloc),y

    jsr     _print_hexa
    
    txa
    clc
    adc     #kernel_malloc_struct::kernel_malloc_busy_chunk_size_low
    tay
    lda     (lsmem_ptr_malloc),y


    jsr     _print_hexa_no_sharp

    CPUTC ' '
    ; There is a bug here if kernel_malloc_struct::kernel_malloc_busy_pid_list + x are greater than 255
	; display process now
    txa     ; X contains the index of the process
    clc
    adc     #kernel_malloc_struct::kernel_malloc_busy_pid_list

    tay

;.if     KERNEL_MAX_NUMBER_OF_MALLOC+kernel_malloc_struct::kernel_malloc_busy_pid_list > 255
  ;.error  "[lsmem] KERNEL_MAX_NUMBER_OF_MALLOC+kernel_malloc_struct::kernel_malloc_busy_pid_list greater than 255 : overflow in lsmem_ptr_malloc ..."
;.endif


    jsr     display_process

@S1:

    BRK_KERNEL XCRLF
    ; save X
    ldx     lsmem_savex
    ldy     lsmem_savey_kernel_malloc_busy_pid_list
busy_chunk_is_empty:
    iny
    inx
    cpx     #KERNEL_MAX_NUMBER_OF_MALLOC
    bne     myloop2


skip:
    rts

display_process:

    lda     (lsmem_ptr_malloc),y
    ; at this step A contains the id of the pid
    ; we get the process position, now let's get it's name

    pha
    clc
    adc     #kernel_process_struct::kernel_one_process_struct_ptr_low
    tay

    lda     (lsmem_ptr_pid_table),y
 ;   sta     lsmem_ptr

    pla
    rts
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
    rts    

str_column:
    .byte "TYPE  START END   SIZE  PROGRAM  PID",$0D,$0A,0    

str_empty_program:
    .asciiz "       "
str_FREE:
    .asciiz "Free  "
str_BUSY:
    .asciiz "Busy  "

.endproc


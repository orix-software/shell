.export _lsmem

.proc _lsmem

   lsmem_ptr_malloc     := userzp
   lsmem_ptr_pid_table  := userzp+2	 ; Get struct
   lsmem_savey_kernel_malloc_busy_pid_list := userzp+4
   lsmem_savey          := userzp+6  ; 1 byte
   lsmem_savex          := userzp+7  ; 1 byte
   lsmem_savexbis       := userzp+8  ; 1 byte
   lsmem_ptr_command_name := userzp+10
   lsmem_ptr_command_name_tmp := userzp+12
   lsmem_current_process_read := userzp+14
   lsmem_ptr_one_process := userzp+16



   ldx     #XVARS_KERNEL_PROCESS  ; Get struct process adress  from kernel
   BRK_KERNEL XVARS
   sta     lsmem_ptr_pid_table
   sty     lsmem_ptr_pid_table+1


   ldx     #XVARS_KERNEL_MALLOC ; Get adress struct of malloc from kernel
   BRK_KERNEL XVARS
   sta     lsmem_ptr_malloc
   sty     lsmem_ptr_malloc+1


   PRINT   str_column

   BRK_KERNEL XCRLF

; Displays all free chunk 

    ldx     #$00
    
@L1:
    stx     lsmem_savex
   ; stx $5002
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
    ;lda  #$82
    ;BRK_KERNEL XWR0
   ; PRINT   str_SPACE
    ldx     lsmem_savex
    txa
    clc
    adc     #kernel_malloc_struct::kernel_malloc_free_chunk_begin_high
    tay
    lda     (lsmem_ptr_malloc),y
  
    jsr     _print_hexa

    ldx     lsmem_savex
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
 
        
    ;lda  #$81
    ;BRK_KERNEL XWR0
    PRINT   str_BUSY

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
    sty     lsmem_savey
    
    ldy     lsmem_savey_kernel_malloc_busy_pid_list
    ;jsr     display_process2
    
    ldy     lsmem_savey
    ;lda     lsmem_savey_kernel_malloc_busy_pid_list
    ;jsr     display_pid

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
display_pid:
;lsmem_savey_kernel_malloc_busy_pid_list

    lda     (lsmem_ptr_pid_table),y

    ldy     #$00
    ldx     #$20 ;
    stx     DEFAFF
    ldx     #$00
    BRK_KERNEL XDECIM
    rts


 display_process2: 
    sty     lsmem_current_process_read

    lda     #kernel_process_struct::kernel_one_process_struct_ptr_low
    clc     
    adc     lsmem_current_process_read
    tay

    lda     (lsmem_ptr_pid_table),y
    sta     lsmem_ptr_one_process


    lda     #kernel_process_struct::kernel_one_process_struct_ptr_high
    clc     
    adc     lsmem_current_process_read
    tay

    lda     (lsmem_ptr_pid_table),y
    sta     lsmem_ptr_one_process+1


    ldy     #kernel_one_process_struct::process_name
@L1:    
    lda     (lsmem_ptr_one_process),y

    beq     @S1
    BRK_KERNEL XWR0
    iny
    bne     @L1
@S1:    
    rts

display_process:
    txa
    tay
    lda     (lsmem_ptr_pid_table),y
    cmp     #$01 ; init ?
    beq     @is_init_process     



    txa     
    clc     
    adc     #kernel_process_struct::kernel_one_process_struct_ptr_low
    tay

    lda     (lsmem_ptr_pid_table),y
    sta     lsmem_ptr_command_name


    txa
    clc     
    adc     #kernel_process_struct::kernel_one_process_struct_ptr_high
    tay

    lda     (lsmem_ptr_pid_table),y
    sta     lsmem_ptr_command_name+1


    lda     #$00
    sta     lsmem_ptr_command_name_tmp

    ldy     #kernel_one_process_struct::process_name
@L1_string:    
    lda     (lsmem_ptr_command_name),y
    beq     @out
    BRK_KERNEL XWR0
    inc     lsmem_ptr_command_name_tmp
    iny
    bne     @L1_string
@out:
    ; Align now
    lda     lsmem_ptr_command_name_tmp
    cmp     #08
    beq     @finish_align
    lda     #' '
    BRK_KERNEL XWR0
    inc     lsmem_ptr_command_name_tmp
    jmp     @out
@finish_align:
    rts
  
@is_init_process:
    lda     #'i'
    BRK_KERNEL XWR0
    lda     #'n'
    BRK_KERNEL XWR0
    lda     #'i'
    BRK_KERNEL XWR0    
    lda     #'t'
    BRK_KERNEL XWR0
    lda     #' '
    BRK_KERNEL XWR0    
    lda     #' '
    BRK_KERNEL XWR0    
    lda     #' '
    BRK_KERNEL XWR0    
    lda     #' '
    BRK_KERNEL XWR0    
    rts

str_column:
    .asciiz "TYPE START END   SIZE"
    ;  PROGRAM  PID FUNC",0    

str_empty_program:
    .asciiz "       "
str_FREE:
    .asciiz "Free "
str_BUSY:
    .asciiz "Busy "
str_INIT:
    .asciiz "init"
str_SPACE:
    .asciiz "unkn "
.endproc


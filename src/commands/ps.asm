
.export  _ps

.proc _ps
    
    ptr_kernel_process           :=userzp ; 2 bytes
    ptr_kernel_process_current   :=userzp+2
    ptr_one_process              :=userzp+4 ; 2 bytes
    ps_current_process_read      :=userzp+6 ; 1 bytes max 256 process to display


    PRINT   str_ps_title

    ldx     #XVARS_KERNEL_PROCESS ; Get Kernel adress
    BRK_KERNEL XVARS
    sta     ptr_kernel_process
    sty     ptr_kernel_process+1

    lda     #$00
    sta     ps_current_process_read

    
    ;  ldy     #kernel_process_struct::kernel_pid_list
    ldy     #$01 ; because init consume the first byte
    
@NEXT_PROCESS:    
    sty     ps_current_process_read
    ldy     ps_current_process_read

    

    lda     (ptr_kernel_process),y
    beq     @SKIP_NOPROCESS
    tay
    iny
    tya
    ldy     #$00
    PRINT_BINARY_TO_DECIMAL_16BITS 1
    CPUTC   ' '

    
    lda     #kernel_process_struct::kernel_one_process_struct_ptr_low
    clc     
    adc     ps_current_process_read
    tay

    lda     (ptr_kernel_process),y
    sta     ptr_one_process


    lda     #kernel_process_struct::kernel_one_process_struct_ptr_high
    clc     
    adc     ps_current_process_read
    tay

    lda     (ptr_kernel_process),y
    sta     ptr_one_process+1


    ldy     #kernel_one_process_struct::process_name
@L1:    
    lda     (ptr_one_process),y

    beq     @S1
    BRK_KERNEL XWR0
    iny
    bne     @L1
@S1:    


    RETURN_LINE
@SKIP_NOPROCESS:
    ldy     ps_current_process_read
    iny
    cpy     #KERNEL_MAX_PROCESS
    bne     @NEXT_PROCESS

    rts

str_ps_title:
    .byte   "PID CMD",$0D,$0A
    .byte   "  1 init",$0D,$0A,$00
.endproc

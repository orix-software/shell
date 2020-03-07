
.export  _ps

.proc _ps
    
    ptr_kernel_process           :=userzp ; 2 bytes
    ptr_kernel_process_current   :=userzp+2
    ps_tmp1                      :=userzp+3
    ptr_one_process              :=userzp+4 ; 2 bytes
    ps_tmp2                      :=userzp+6
    ps_current_process_read      :=userzp+8 ; 2 bytes

    PRINT   str_ps_title

    ldx     #XVARS_KERNEL_PROCESS ; Get Kernel adress
    BRK_KERNEL XVARS
    sta     ptr_kernel_process
    sty     ptr_kernel_process+1

    lda     #$00
    sta     ps_current_process_read

    ; Displays init process
    ldy     #kernel_process_struct::kernel_pid_list

    sty     ps_current_process_read
    ldy     ps_current_process_read
    lda     (ptr_kernel_process),y
    ldy     #$00
    PRINT_BINARY_TO_DECIMAL_16BITS 1
    CPUTC   ' '

    ldy     #(kernel_process_struct::kernel_one_process_struct_ptr_low+1)
    sty     ps_tmp1
    
    ldy     #(kernel_process_struct::kernel_one_process_struct_ptr_high+1)
    sty     ps_tmp2

    ldy     ps_tmp1
    lda     (ptr_kernel_process),y
    sta     ptr_one_process


    ldy     ps_tmp2
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
    rts

str_ps_title:
    .byte   "PID CMD",$0D,$0A
    .byte   "  1 init",$0D,$0A,$00
.endproc

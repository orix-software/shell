.export _lsof

    ptr_kernel_process_lsof           :=userzp ; 2 bytes
    lsof_saveY                        :=userzp+1
    lsof_ptr_struct_one_process       :=userzp+2 ; 16 bits
    lsof_ptr_struct_fp                :=userzp+4 ; 16 bits
    lsof_ptr_struct_tmp_fp            :=userzp+6 ; 16 bits

.proc _lsof
    PRINT   lsof_header
    RETURN_LINE
    ldx     #XVARS_KERNEL_PROCESS ; Get Kernel adress
    BRK_KERNEL XVARS
    sta     ptr_kernel_process_lsof
    sty     ptr_kernel_process_lsof+1
    ldy     #(kernel_process_struct::kernel_pid_list)
@L1:    
    lda     (ptr_kernel_process_lsof),y
    beq     @S1 ; Skip because PID=0 : process does not exist
    ;       displays PID
    sty     lsof_saveY
    ldy     #$00
    ldx     #$20 ;
    stx     DEFAFF
    ldx     #$00
    BRK_KERNEL XDECIM
    RETURN_LINE

    ldy     #(kernel_process_struct::kernel_one_process_struct_ptr_low)
    lda     (ptr_kernel_process_lsof),y
    sta     lsof_ptr_struct_one_process
    sta     lsof_ptr_struct_fp    ; contains
    sta     lsof_ptr_struct_tmp_fp

    ldy     #(kernel_process_struct::kernel_one_process_struct_ptr_high)
    lda     (ptr_kernel_process_lsof),y
    sta     lsof_ptr_struct_one_process+1
    sta     lsof_ptr_struct_fp+1
    sta     lsof_ptr_struct_tmp_fp+1



    ; Compute string address
    lda     #(kernel_one_process_struct::fp_ptr)
    clc
    adc     lsof_ptr_struct_fp
    bcc     @S2
    inc     lsof_ptr_struct_fp+1
@S2:
    sta     lsof_ptr_struct_fp

    ldy     #$00
    lda     (lsof_ptr_struct_fp),y
    bne     @is_ptr         ; if it's not $00 at this step, it's maybe a right ptr
    iny
    lda     (lsof_ptr_struct_fp),y
    beq     @not_fp         ; if it's not $00 at this step, it's maybe a right ptr

@is_ptr:
    ldy     #$00
  ;  lda     #(_KERNEL_FILE::f_path)
    clc
    adc     (lsof_ptr_struct_fp),y
    bcc     @S3
    inc     lsof_ptr_struct_tmp_fp+1
@S3:
    sta     lsof_ptr_struct_tmp_fp

    ldy     lsof_ptr_struct_tmp_fp+1
    BRK_KERNEL XWSTR0    
   ; inc


   ; sta     
@not_fp:
    ldy     lsof_saveY
    iny
    cpy     #(KERNEL_MAX_PROCESS*2)
    bne     @L1


@S1:  
  rts
lsof_header:
  .asciiz "PID PATH          MODE PROCESS"
.endproc


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
    
    ;sta     $5000
    ;sty     $5001


;.struct kernel_process_struct
  ; don't move kernel_pid_list in an other line because it breaks ps and lsmem
  ;kernel_pid_list                      .res KERNEL_MAX_PROCESS ; list of PID when the byte is equal to 0, it means that this is free, it store the index
  ;kernel_current_process               .res 1                  ; id of the current pid (French, contient l'index et non pas la valeur, l'index sur la table kernel_pid_list)
  ;kernel_one_process_struct_ptr_low    .res KERNEL_MAX_PROCESS
  ;kernel_one_process_struct_ptr_high   .res KERNEL_MAX_PROCESS
  ;kernel_init_string                   .res .strlen("init")+1
  ;kernel_cwd_str                       .res .strlen("/")+1
  ;fp_ptr                               .res KERNEL_MAX_FP_PER_PROCESS*2 ; fp for init for instance, only shell could be in it
;.endstruct

    ldy     #$01 ; because init consume the first byte
    
@NEXT_PROCESS:    
    sty     ps_current_process_read
    ldy     ps_current_process_read

    

    lda     (ptr_kernel_process),y
    beq     @SKIP_NOPROCESS

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

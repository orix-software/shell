.export _pstree

.proc _pstree
    jmp newpstree
    PRINT str_init
    RETURN_LINE
    rts
str_init:
    .asciiz "init---bash---pstree"    
.endproc

.proc newpstree
ptr_kernel_process          :=userzp
ptr_kernel_process_current  :=userzp+2
    ldx #$00 ; Get Kernel adress
    BRK_KERNEL XVARS
    sta     ptr_kernel_process
    sty     ptr_kernel_process+1

   ; ldy     #$00
;    lda     #$01
    ;PRINT_BINARY_TO_DECIMAL_16BITS 1
    ;CPUTC   ' '

    ldy     #kernel_process_struct::kernel_init_string
@L1:    
    lda     (ptr_kernel_process),y
    beq     @S1
    BRK_ORIX XWR0
    iny
    bne     @L1

@S1:
    ldy     #kernel_process_struct::kernel_one_process_struct_ptr_low
    lda     (ptr_kernel_process),y
    sta     ptr_kernel_process_current
    ldy     #kernel_process_struct::kernel_one_process_struct_ptr_high
    lda     (ptr_kernel_process),y
    sta     ptr_kernel_process_current+1

    ldy     #kernel_one_process_struct::process_name
@L2:
    lda     (ptr_kernel_process_current),y
    beq     @S2
    BRK_ORIX XWR0
    iny
    bne     @L2
@S2:    

;.struct kernel_one_process_struct
;process_name        .res KERNEL_MAX_LENGTH_COMMAND+1
;cwd_str             .res KERNEL_MAX_PATH_LENGTH
;child_pid           .res KERNEL_NUMBER_OF_CHILD_PER_PROCESS
;.endstruct 




;.struct kernel_process_struct
;kernel_pid_list                      .res KERNEL_MAX_PROCESS
;kernel_one_process_struct_ptr_low    .res KERNEL_MAX_PROCESS
;kernel_one_process_struct_ptr_high   .res KERNEL_MAX_PROCESS
;kernel_next_process_pid              .res 1
;kernel_init_string                   .res .strlen("init")+1
;kernel_cwd_str                       .res .strlen("/")+1
;.endstruct


    rts
.endproc

.export _pstree

.proc _pstree
    jmp newpstree
    print str_init,NOSAVE
    RETURN_LINE
    rts
str_init:
    .asciiz "init---bash---pstree"    
.endproc

.proc newpstree
    ptr_kernel_process          :=userzp
    ptr_kernel_process_current  :=userzp+2
    ldx     #$00 ; Get Kernel adress
    BRK_KERNEL XVARS
    sta     ptr_kernel_process
    sty     ptr_kernel_process+1


    ldy     #kernel_process_struct::kernel_init_string
@L1:    
    lda     (ptr_kernel_process),y
    beq     @S1
    BRK_KERNEL XWR0
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
    BRK_KERNEL XWR0
    iny
    bne     @L2
@S2:    


    rts
.endproc

.export _watch

save_mainargs_ptr  := userzp
watch_ptr1         := userzp+2

.proc _watch
    ldx     #$01
    jsr     _orix_get_opt
    bcc     @usage

    MALLOC_AND_TEST_OOM_EXIT 100 
    sta     save_mainargs_ptr
    sty     save_mainargs_ptr+1
    
    lda     #<ORIX_ARGV
    ldy     #>ORIX_ARGV
    
    sta     watch_ptr1
    sty     watch_ptr1+1

    ; copy command
    ldy     #$00
@L5:
    lda     (watch_ptr1),y
    beq     @S3
    sta     (save_mainargs_ptr),y
    iny
    bne     @L5
@S3:
    sta     (save_mainargs_ptr),y



@L1:
    asl     KBDCTC
    bcc     @no_ctrl
    rts

@no_ctrl:    
    lda     save_mainargs_ptr
    ldy     save_mainargs_ptr+1

    BRK_KERNEL XEXEC
    jmp     @L1

@usage:    
    rts
    PRINT   str_argc

    BRK_KERNEL $2C ; XMAINARGS
    ; Return in A & Y struct
    ; save ptr
    sta save_mainargs_ptr
    sty save_mainargs_ptr+1


    BRK_KERNEL $2D ; XGETARGC
    PRINT_BINARY_TO_DECIMAL_16BITS 2
    RETURN_LINE 
    PRINT str_param
    ldx     #$00
    lda     save_mainargs_ptr
    ldy     save_mainargs_ptr+1
    BRK_KERNEL $2E ; XGETARGV
    BRK_KERNEL XWSTR0 
    RETURN_LINE 
    
    ldx     #$01
    lda     save_mainargs_ptr
    ldy     save_mainargs_ptr+1
    BRK_KERNEL $2E ; XGETARGV
    BRK_KERNEL XWSTR0 
    RETURN_LINE 

    rts
str_argc:
    .asciiz "Argc: "  
str_param:
    .asciiz "Param: "      
.endproc

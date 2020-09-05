.export _watch

save_mainargs_ptr:=userzp


.proc _watch
    ldx     #$01
    jsr     _orix_get_opt
    bcc     @usage
@L1: 
    lda     #<ORIX_ARGV
    ldy     #>ORIX_ARGV

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

.proc _uname
    ldx     #$01
    jsr     _orix_get_opt
    STRCPY  ORIX_ARGV,BUFNOM
 
    lda     BUFNOM
    beq     no_param
    cmp     #'-'
    bne     error
    lda     BUFNOM+1
    cmp     #'a'
    bne     error
    PRINT   str_os
    lda     #' '                ; FIXME CGETC
    BRK_KERNEL XWR0
    PRINT   str_compile_time 
    BRK_KERNEL XCRLF
    rts
no_param:
    PRINT   str_os
    BRK_KERNEL XCRLF
error:
    rts

.endproc
	

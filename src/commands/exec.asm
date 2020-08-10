
.export _exec

.proc _exec
    ldx     #$01
    jsr     _orix_get_opt
    bcc     @usage
    lda     #<ORIX_ARGV
    ldy     #>ORIX_ARGV
@L1:    
    BRK_KERNEL XEXEC
    
    
@usage:

    rts


.endproc

.export _lsof

    ptr_lsof           :=userzp   ; 2 bytes
    lsof_savey         :=userzp+1
    lsof_current_fd    :=userzp+2 ; 16 bits

.proc _lsof
    print   lsof_header
    crlf
    ldx     #$00
    stx     lsof_current_fd

    ldy     #$00
    ldx     #$09 ; Get path
    BRK_KERNEL XVALUES

    cmp	    #$00
    bne     @fd_opened

    cpy	    #$00
    bne     @fd_opened
    ; no opened file
    rts

@fd_opened:
    sta     ptr_lsof
    sty     ptr_lsof+1
    print(ptr_lsof)
    rts

lsof_header:
    .asciiz "PATH"
  ;.asciiz "PID PATH          MODE PROCESS"
.endproc

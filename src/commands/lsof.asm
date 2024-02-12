.export _lsof

    ptr_lsof           :=userzp   ; 2 bytes
    lsof_savey         :=userzp+2
    lsof_current_fd    :=userzp+3 ; 16 bits

    lsof_max_number_file :=userzp+5
    lsof_savex           :=userzp+6

    lsof_file_ptr := userzp + 8

.proc _lsof

    jsr     fopen_bis
    print   lsof_header
    crlf

    ldy     #$00
    ldx     #$08 ; Get number of files opened
    BRK_KERNEL XVARS
    sty     lsof_max_number_file

    ldx     #$00

@next_file:
    stx     lsof_current_fd
    lda     lsof_current_fd
    clc
    adc     #$03
    tay
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
    crlf

    ldx     lsof_current_fd
    inx
    cpx     lsof_max_number_file
    bne     @next_file
    rts

fopen_bis:
    malloc 100
    sta     lsof_file_ptr
    sty     lsof_file_ptr+1

    ldy     #$00
@me:
    lda     basic11_ptr2,y
    beq     @out
    sta     (lsof_file_ptr),y
    iny
    bne     @me

@out:
    sta     (lsof_file_ptr),y
 ;   rts

    fopen (lsof_file_ptr), O_RDONLY,,fp ; open the filename located in ptr 'basic11_ptr2', in readonly and store the fp in fp address
    cpx     #$FF
    bne     @read_maindb ; not null then  start because we did not found a conf
    cmp     #$FF
    bne     @read_maindb ; not null then  start because we did not found a conf

   ; print   str_basic11_missing
    crlf    ; Macro for return line
    lda     #$FF
    ldx     #$FF
    rts

@read_maindb:
    ; bla
    rts
@fp:
    .res 2

basic11_ptr2:
    .asciiz "/etc/autoboot"

lsof_header:
    .asciiz "PATH"
  ;.asciiz "PID PATH          MODE PROCESS"
.endproc

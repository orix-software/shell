.export _watch

save_mainargs_ptr  := userzp
watch_ptr1         := userzp+2
watch_ptr2         := userzp+4

.proc _watch
    ldx     #$01
    jsr     _orix_get_opt
    

    MALLOC_AND_TEST_OOM_EXIT 100 
    sta     save_mainargs_ptr
    sty     save_mainargs_ptr+1
    
    ldx     #$01
    jsr     _orix_get_opt
    bcc     @usage

    lda     #<ORIX_ARGV
    sta     watch_ptr1
    lda     #>ORIX_ARGV
    sta     watch_ptr1+1
    


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

    lda     save_mainargs_ptr
    ldy     save_mainargs_ptr+1
    BRK_KERNEL XWSTR0
    SWITCH_OFF_CURSOR
@L1:
    asl     KBDCTC
    bcc     @no_ctrl

    SWITCH_ON_CURSOR

    
    rts

@no_ctrl:
    ; reset prompt position
    lda     #<(SCREEN)
    sta     ADSCR
    lda     #>(SCREEN)
    sta     ADSCR+1

    lda     #$00
    sta     SCRDY

    ; reset display position
    ldx     #$00
    stx     SCRY
    stx     SCRX

    lda     #<SCREEN                                ; Get position screen
    ldy     #>SCREEN
    sta     RES
    sty     RES+1

    ldy     #<(SCREEN+SCREEN_XSIZE*SCREEN_YSIZE)
    ldx     #>(SCREEN+SCREEN_XSIZE*SCREEN_YSIZE)
    lda     #' '
    BRK_TELEMON XFILLM                              ; Calls XFILLM : it fills A value from RES address and size of X and Y value

    lda     save_mainargs_ptr
    ldy     save_mainargs_ptr+1

    BRK_KERNEL XEXEC
    cmp     #ENOENT
    beq     @notfound
    jsr     @wait
    jmp     @L1

@notfound:
    lda     save_mainargs_ptr
    ldy     save_mainargs_ptr+1
    BRK_KERNEL XWSTR0 
    PRINT str_not_found
    rts

@usage:    
    rts
 


@wait:
    ldy     #$00
    ldx     #$00
@lwait:
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    inx
    bne     @lwait
    iny
    bne     @lwait
    rts
str_argc:
    .asciiz "Argc: "  
str_param:
    .asciiz "Param: "      
.endproc

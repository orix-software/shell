.export _viewhrs

.proc _viewhrs


    VIEWHRS_SAVE_FP                := userzp
    viewhrs_mainargs_arg1          := userzp+2
    viewhrs_mainargs_argv          := userzp+4
    viewhrs_mainargs_argc          := userzp+6
    viewhrs_mainargs_arg_time      := userzp+8
    viewhrs_mainargs_time_activate := userzp+10

    ; FIXME 65C02
    lda     #$00
    sta     viewhrs_mainargs_time_activate

    initmainargs viewhrs_mainargs_argv, viewhrs_mainargs_argc, 0
    cpx     #$01
    beq     usage_viewhrs                ; there is not parameter, jumps and displays str_man_error

    getmainarg #1, (viewhrs_mainargs_argv)

    sta     viewhrs_mainargs_arg1
    sty     viewhrs_mainargs_arg1+1

    lda     viewhrs_mainargs_argc
    cmp     #$04
    bne     open_and_display

    getmainarg #2, (viewhrs_mainargs_argv)
    sta     viewhrs_mainargs_arg_time
    sty     viewhrs_mainargs_arg_time+1

    ; is it -t ?

    ldy     #$00
    lda     (viewhrs_mainargs_arg_time),y
    cmp     #'-'
    bne     usage_viewhrs

    ldy     #$01
    lda     (viewhrs_mainargs_arg_time),y
    cmp     #'t'
    bne     usage_viewhrs

    getmainarg #3, (viewhrs_mainargs_argv)
    sta     viewhrs_mainargs_arg_time
    sty     viewhrs_mainargs_arg_time+1

    ldy     #$00
    lda     (viewhrs_mainargs_arg_time),y ; get value
    sec
    sbc     #$30   ; convert into int
    sta     viewhrs_mainargs_arg_time

    inc     viewhrs_mainargs_time_activate ; Switch to 1

open_and_display:
    fopen   (viewhrs_mainargs_arg1),O_RDONLY

    cpx     #$FF
    bne     next
    cmp     #$FF
    bne     next
    beq     not_found
    rts

usage_viewhrs:
    print usage_str
    crlf
    rts

wait_viewhrs:
    ldx     viewhrs_mainargs_arg_time
    ldy     #$00
@L2:
    jsr     wait_tmp
    jsr     wait_tmp
    jsr     wait_tmp
    jsr     wait_tmp
    jsr     wait_tmp
    jsr     wait_tmp
    jsr     wait_tmp
    jsr     wait_tmp
    jsr     wait_tmp
    jsr     wait_tmp
    jsr     wait_tmp
    jsr     wait_tmp
    jsr     wait_tmp
    jsr     wait_tmp
    jsr     wait_tmp
    jsr     wait_tmp
    dex
    bne    @L2
    beq    out

not_found:
    print   txt_file_not_found

    print   (viewhrs_mainargs_arg1)
    crlf
    rts

next:
    sta     VIEWHRS_SAVE_FP
    sty     VIEWHRS_SAVE_FP+1
    SWITCH_OFF_CURSOR ; FIXME macro
    BRK_KERNEL XHIRES ; FIXME macro

    fread $A000, 8000, 1, VIEWHRS_SAVE_FP

    fclose (VIEWHRS_SAVE_FP)

    lda     viewhrs_mainargs_time_activate
    bne     wait_viewhrs
    ; Loop during some times before exit

cget_loop:
    BRK_KERNEL XRDW0
    bmi     cget_loop
    ; A bit crap to flush screen ...
out:
    ;
    BRK_KERNEL XTEXT

    rts

wait_tmp:
@L1:
    lda     wait_viewhrs,x ; instead of nop
    lda     wait_viewhrs,x ; instead of nop
    lda     wait_viewhrs,x ; instead of nop
    lda     wait_viewhrs,x ; instead of nop
    lda     wait_viewhrs,x ; instead of nop
    lda     wait_viewhrs,x ; instead of nop
    lda     wait_viewhrs,x ; instead of nop
    lda     wait_viewhrs,x ; instead of nop
    lda     wait_viewhrs,x ; instead of nop
    lda     wait_viewhrs,x ; instead of nop
    lda     wait_viewhrs,x ; instead of nop
    lda     wait_viewhrs,x ; instead of nop
    lda     wait_viewhrs,x ; instead of nop
    lda     wait_viewhrs,x ; instead of nop
    lda     wait_viewhrs,x ; instead of nop
    lda     wait_viewhrs,x ; instead of nop
    lda     wait_viewhrs,x ; instead of nop
    lda     wait_viewhrs,x ; instead of nop
    lda     wait_viewhrs,x ; instead of nop
    lda     wait_viewhrs,x ; instead of nop
    lda     wait_viewhrs,x ; instead of nop
    lda     wait_viewhrs,x ; instead of nop
    lda     wait_viewhrs,x ; instead of nop
    lda     wait_viewhrs,x ; instead of nop
    lda     wait_viewhrs,x ; instead of nop
    lda     wait_viewhrs,x ; instead of nop
    lda     wait_viewhrs,x ; instead of nop
    lda     wait_viewhrs,x ; instead of nop
    lda     wait_viewhrs,x ; instead of nop
    lda     wait_viewhrs,x ; instead of nop
    lda     wait_viewhrs,x ; instead of nop
    lda     wait_viewhrs,x ; instead of nop
    lda     wait_viewhrs,x ; instead of nop
    lda     wait_viewhrs,x ; instead of nop
    lda     wait_viewhrs,x ; instead of nop
    lda     wait_viewhrs,x ; instead of nop
    lda     wait_viewhrs,x ; instead of nop
    lda     wait_viewhrs,x ; instead of nop
    lda     wait_viewhrs,x ; instead of nop
    lda     wait_viewhrs,x ; instead of nop

    dey
    bne    @L1
    rts

usage_str:
    .asciiz "viewhrs file.hrs [-t time]"

.endproc

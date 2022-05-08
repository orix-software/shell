.export _viewhrs

.proc _viewhrs


    VIEWHRS_SAVE_FP       :=userzp
    viewhrs_mainargs_arg1 := userzp+2
    viewhrs_mainargs_argv := userzp+4
    viewhrs_mainargs_argc := userzp+6

    BRK_KERNEL XMAINARGS
    sta     viewhrs_mainargs_argv
    sty     viewhrs_mainargs_argv+1
    stx     viewhrs_mainargs_argc

    cpx     #$01

    beq     @error                 ; there is not parameter, jumps and displays str_man_error

    ldx     #$01
    lda     viewhrs_mainargs_argv
    ldy     viewhrs_mainargs_argv+1

    BRK_KERNEL XGETARGV
    sta     viewhrs_mainargs_arg1
    sty     viewhrs_mainargs_arg1+1


    fopen   (viewhrs_mainargs_arg1),O_RDONLY

    cpx     #$FF
    bne     next
    cmp     #$FF
    bne     next
    beq     not_found
    rts
@error:
    print   str_viewhrs_error
    rts
not_found:

    print   txt_file_not_found

    print   (viewhrs_mainargs_arg1)
    RETURN_LINE
    rts
next:
    sta     VIEWHRS_SAVE_FP
    sty     VIEWHRS_SAVE_FP+1
    SWITCH_OFF_CURSOR
    HIRES
    FREAD   $A000,8000,1,VIEWHRS_SAVE_FP
    fclose (VIEWHRS_SAVE_FP)

cget_loop:
    BRK_KERNEL XRDW0
    bmi     cget_loop
    ; A bit crap to flush screen ...
out:
    BRK_KERNEL XHIRES
    BRK_KERNEL XTEXT

    rts

str_viewhrs_error:
  .byte "What hrs do you want?",$0D,$0A,0

.endproc

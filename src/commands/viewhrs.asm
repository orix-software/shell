.export _viewhrs

.proc _viewhrs
    VIEWHRS_SAVE_FP:=userzp
    ; get the first parameter
    ldx     #$01
    jsr     _orix_get_opt
    bcc     @error                 ; there is not parameter, jumps and displays str_man_error
    
    FOPEN   ORIX_ARGV,O_RDONLY
    
    cpx     #$FF
    bne     next
    cmp     #$FF
    bne     next
    beq     not_found
    rts
@error:
    PRINT   str_viewhrs_error
    rts
not_found: 

    PRINT   txt_file_not_found
    ldx     #$01
    jsr     _orix_get_opt
    PRINT   ORIX_ARGV
    RETURN_LINE
    rts 
next:
    sta     VIEWHRS_SAVE_FP
    sty     VIEWHRS_SAVE_FP+1
    SWITCH_OFF_CURSOR
    HIRES
    FREAD   $A000,8000,1,VIEWHRS_SAVE_FP
    BRK_ORIX XCLOSE
cget_loop:
    BRK_ORIX XRDW0
    bmi     cget_loop
    ; A bit crap to flush screen ...
out:    
    BRK_ORIX XHIRES
    BRK_ORIX XTEXT

    rts

str_viewhrs_error:
  .byte "What hrs do you want?",$0D,$0A,0

.endproc


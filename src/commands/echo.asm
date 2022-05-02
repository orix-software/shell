
.export _echo

.proc _echo
    ldy     #$05

trim_space:
    lda     (bash_struct_command_line_ptr),y
    cmp     #' '
    bne     not_first_param	
    iny
    jmp     trim_space


not_first_param:
    lda     (bash_struct_command_line_ptr),y
    beq     @out
    BRK_KERNEL XWR0
    iny
    bne     not_first_param

@out:
    BRK_KERNEL XCRLF
    rts

.endproc

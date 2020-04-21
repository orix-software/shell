
.export _exec

.proc _exec
    lda bash_struct_command_line_ptr
    lda bash_struct_command_line_ptr+1
    ldy     #$05 ; Now we remove exec word and space
 @loop:
     lda    (bash_struct_command_line_ptr),y
     beq     @out
     dey
     dey
     dey
     dey
     dey
     sta     (bash_struct_command_line_ptr),y

     iny
     iny
     iny
     iny
     iny
     iny
     bne     @loop
 @out:
     dey
     dey
     dey
     dey
     dey
     sta     (bash_struct_command_line_ptr),y

    ldy     bash_struct_command_line_ptr+1
    lda     bash_struct_command_line_ptr
    clc
    adc     #$04
    bcc     @S1
    iny
@S1:    
    
    
    BRK_KERNEL($63) ; Exec

    rts


.endproc

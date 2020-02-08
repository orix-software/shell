
.export _exec

.proc _exec
    
     ldy     #$04 ; Now we remove exec word
 @loop:
     lda     (bash_struct_command_line_ptr),y

     beq     @out
     dey
     dey
     dey
     dey
     sta     (bash_struct_command_line_ptr),y

     iny
     bne     @loop
 @out:
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
    
    
    BRK_TELEMON($63) ; Exec

    rts


.endproc

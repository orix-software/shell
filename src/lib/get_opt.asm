
; ORIX_ARGSV
;  [IN] X get the id of the parameter
; Return in AY the ptr of the parameter
.proc _orix_get_opt

.IFPC02
.pc02
    stz ORIX_ARGC
.p02    
.else
    lda #$00
    sta ORIX_ARGC
.endif	
	stx TEMP_ORIX_1

    ldy #$00
    cpx #$00
    bne not_first_param	
trim_space:
    lda (bash_struct_command_line_ptr),y
    cmp #' '
    bne not_first_param	
    iny
    jmp trim_space
 
;	bne not_first_param
not_first_param:	
    ldx #$00	
loop_opt:
    lda (bash_struct_command_line_ptr),y
    beq end_of_param

next2: 	
    cmp #' '
    beq get_param
    sta ORIX_ARGV,x
    inx
    iny
.IFPC02
.pc02
    bra loop_opt
.p02    
.else
    jmp loop_opt
.endif
get_param:

    lda TEMP_ORIX_1
    cmp ORIX_ARGC
    beq out
    iny
    inc ORIX_ARGC
.IFPC02
.pc02
    bra not_first_param
.p02    
.else
    jmp not_first_param 
.endif

	; Here we have the first param
end_of_param:
    lda TEMP_ORIX_1
    cmp ORIX_ARGC
    bne not_found
out:
.IFPC02
.pc02
    stz ORIX_ARGV,x
.p02    
.else
    lda #$00 ; 65c02 FIXME
    sta ORIX_ARGV,x
.endif	
    sec
    rts
not_found:
.IFPC02
.pc02
    stz ORIX_ARGV
.p02    
.else
    lda #$00
    sta ORIX_ARGV
.endif	
    clc
    rts
.endproc	


.proc _getopt
; [IN] AY : argv
; [IN] X : argc count
; [IN] RES : optstring
  rts
.endproc





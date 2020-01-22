; This routine reads the data and display on the screen

.proc vi_editor_fill_screen_with_text
  ldx     #$27
  ldy     #$00
  lda     (vi_ptr_edition_buffer),y
  beq     @end
@not_return_windows_found:
  sta     (vi_screen_address_position_edition),y
@end:
  rts
.endproc


.proc vi_command_line_vi_editor_switch_on_cursor
    ldy     vi_screen_x_position_command
    lda     VI_COMMANDLINE_VIDEO_ADRESS,y ; display cursor
    ORA     #$80
    sta     VI_COMMANDLINE_VIDEO_ADRESS,y
    rts
.endproc    

.proc vi_editor_switch_off_cursor
	ldy     #$00
	lda     (vi_screen_address_position_edition),y
	AND     #%01111111
	sta     (vi_screen_address_position_edition),y ; display cursor
	rts
.endproc    

.proc vi_editor_switch_on_cursor
.IFPC02
.pc02
	lda     (vi_screen_address_position_edition) ; display cursor
	ORA     #$80
	sta     (vi_screen_address_position_edition) ; display cursor
.p02    
.else
	ldy     #$00
	lda     (vi_screen_address_position_edition),y ; display cursor
	ORA     #$80
	sta     (vi_screen_address_position_edition),y ; display cursor
.endif	
	rts
.endproc    

.proc vi_command_line_vi_editor_switch_off_cursor
    ldy     vi_screen_x_position_command
    lda     VI_COMMANDLINE_VIDEO_ADRESS,y
    AND     #%01111111
    sta     VI_COMMANDLINE_VIDEO_ADRESS,y ; display cursor
    rts      
.endproc    
  
interpret_commandline:

  
  ldx     #$00
@loop:  
  lda     VI_COMMANDLINE_VIDEO_ADRESS,x
  cmp     #'w'
  beq     write
  cmp     #'q'
  beq     quit
  inx
  cpx     #VI_COMMANDLINE_MAX_CHAR
  beq     @skip
  jmp     @loop   
   
@skip:
  jmp     command_edition
  
quit:
  lda     vi_struct
  ldy     vi_struct+1

  BRK_KERNEL XFREE

  lda     vi_ptr_edition_buffer
  ldy     vi_ptr_edition_buffer+1
  BRK_KERNEL XFREE
  CLS
  ;jsr     restore_old_screen
  rts

write:
  ;jmp   command_edition
  
  ;inx
  ;stx     saveX
.IFPC02
.pc02
  lda     (vi_struct)
.p02  
.else  
  ldy     #$00
  lda     (vi_struct),y
.endif

  beq     display_nofilename_error                ; no filename provided on command line, so launch an error

  ldy     #O_WRONLY
  lda     vi_struct
  ldx     vi_struct+1
  BRK_TELEMON XOPEN

  cpx     #$ff
  bne     fileopened
  cmp     #$ff
  bne     fileopened  
  ; Impossible to open error
  lda	  msg_impossibletowrite
  ldy 	  msg_impossibletowrite+1
  jsr     display_message_on_command_line
  
  rts
  
fileopened:  
; sta     saveFP
 ; lda     saveFP
  sta     TR0

  lda     vi_ptr_edition_buffer
  sta     PTR_READ_DEST

  lda     vi_ptr_edition_buffer+1
  sta     PTR_READ_DEST+1
 
  lda     vi_length_file
  ldy     vi_length_file+1
  
  BRK_TELEMON XFWRITE

  BRK_TELEMON XCLOSE
  
  
  ; write file
  ;PTR_READ_DEST
  
  ldx     #$00                                    ; Position 0 for the msg
  jsr     vi_commandline_display_filename
  jsr     vi_display_written_word_on_commandline
  ;ldx     saveX
  jmp     command_edition

display_nofilename_error:

  ldx     #$00

  ldy     #$00
@loop:  
  lda     msg_nofilename,y
  beq     @skip
  sta     VI_COMMANDLINE_VIDEO_ADRESS,x
  inx
  iny
  bne     @loop
@skip:
  jmp     command_edition



.proc display_message_on_command_line
  sta 	  tmp0_16
  sty 	  tmp0_16+1
  ldx     #$00

  ldy     #$00
@loop: 
  lda     (tmp0_16),y
  beq     @skip3
  sta     VI_COMMANDLINE_VIDEO_ADRESS,x
  inx
  iny
  bne     @loop
@skip3:
  jmp     command_edition
 .endproc
  

.proc vi_display_written_word_on_commandline

  ldy     #$00
@loop:  
  lda     msg_written,y
  beq     @skip
  sta     VI_COMMANDLINE_VIDEO_ADRESS,x
  inx
  iny
  bne     @loop
@skip:
  rts
.endproc


.proc vi_commandline_display_filename

  lda     #$22          ; display on commandline '"' char
  sta     VI_COMMANDLINE_VIDEO_ADRESS,x
  inx
  ; display opened file 
  ldy     #$00
@loop:  
  lda     (vi_struct),y
  beq     @skip
  sta     VI_COMMANDLINE_VIDEO_ADRESS,x
  inx
  iny
  bne     @loop

@skip:  
  lda     #$22          ; display on commandline '"' char
  sta     VI_COMMANDLINE_VIDEO_ADRESS,x
  inx
  
  lda     #' '          ; display on commandline ' ' char
  sta     VI_COMMANDLINE_VIDEO_ADRESS,x
  inx  
  
  rts
.endproc
  
.proc fill_screen_with_empty_line

  ldx     #26
.IFPC02  
.else
  ldy     #$00
.endif  
@loop:
  lda     TABLE_LOW_TEXT,x
  sta     tmp0_16
  lda     TABLE_HIGH_TEXT,x
  sta     tmp0_16+1
  inc     tmp0_16
  bne     @skip
  inc     tmp0_16+1
@skip:  
  lda     #VI_EDITOR_CHAR_LIMITS_EMPTY
.IFPC02
.pc02
  sta     (tmp0_16)
.p02  
.else  
  sta     (tmp0_16),y
.endif  
  dex
  bne     @loop
  rts
.endproc

.proc clear_command_line

    ldx     #40
    lda     #32
@loop:
    sta     VI_COMMANDLINE_VIDEO_ADRESS,x
    dex
    bpl     @loop
    rts
.endproc

; use A and Y
.proc update_position_screen

    lda     vi_screen_x_position_edition
    cmp     #39
    bne     skip
    inc     vi_screen_y_position_edition
    lda     vi_screen_y_position_edition
    cmp     #27
    bne     skip3
    jsr     scrollup
    dec     vi_screen_y_position_edition
    lda     vi_is_a_new_file
    beq     is_a_file
    ; It's a new file, then we erase the last edition line (with space)
    lda     #' '
    ldx     #39
@loop:
    sta     VI_EDITION_LAST_VIDEO_ADRESS,x
    dex
    bpl     @loop


is_a_file:
    ; Here read next file
    ;ldx #$00
    ;BRK_ORIX(XSCROH)
skip3: 
.IFPC02
.pc02
    stz     vi_screen_x_position_edition
.p02    
.else 
    lda     #$00
    sta     vi_screen_x_position_edition
.endif    
skip:
  
    ldy     vi_screen_y_position_edition
    lda     TABLE_HIGH_TEXT,y
    sta     vi_screen_address_position_edition+1
    lda     TABLE_LOW_TEXT,y
    sta     vi_screen_address_position_edition    

    sec
    adc     vi_screen_x_position_edition
    bcc     @skip2
    inc     vi_screen_address_position_edition+1 ;
@skip2:
    sta     vi_screen_address_position_edition

    rts
.endproc

.proc edition_mode_routine

restart_edition:
    jsr     vi_editor_switch_off_cursor
    jsr     update_position_screen
    jsr     vi_editor_switch_on_cursor

    CGETC

	cmp     #KEY_LEFT
	beq     left_pressed    
	cmp     #KEY_RIGHT
	bne     @test_up
    jmp     right_pressed
@test_up:    
	cmp     #KEY_UP
	bne    	@test_down
    jmp     up_pressed
@test_down:
	cmp     #KEY_DOWN
	bne     @test_return
    jmp     down_pressed	
@test_return:    
	cmp     #KEY_RETURN ; enter ?
	bne     @test_del
    jmp     return_pressed_routine
@test_del:    
	cmp     #KEY_DEL
	bne     @test_esc
    jmp     key_del_remove
@test_esc:    
	cmp     #KEY_ESC ; ESC don't need
	beq     @esc_pressed
; here we write key 
	jmp     put_key_on_screen

@esc_pressed:
    jmp     vi_clear_and_restart_command_mode


	
down_pressed:

	;jmp     go_down_on_screen ; replace by bne
    lda     vi_current_position_ptr_edition_buffer_end
    cmp     vi_current_position_ptr_edition_buffer        ; end of file ?
    bne     @skip
    lda     vi_current_position_ptr_edition_buffer_end+1
    cmp     vi_current_position_ptr_edition_buffer+1       ; end of file ?
    beq     @skip    
    
    lda     vi_screen_y_position_edition
    cmp     #26
   ; beq     restart_edition
    
    inc     vi_screen_y_position_edition
    inc     vi_screen_y_position_edition_real

    lda     vi_current_position_ptr_edition_buffer
    sec
    sbc     #40
    bcs     @skip
	
	
    dec     vi_current_position_ptr_edition_buffer+1
@skip:
    sta     vi_current_position_ptr_edition_buffer

    
    jmp    edition_mode_routine
    
up_pressed:  
	;jmp     go_up_on_screen
   
    lda     vi_screen_y_position_edition
    beq     @out
  ;  beq     restart_edition

    dec     vi_screen_y_position_edition
    dec     vi_screen_y_position_edition_real
    lda     vi_current_position_ptr_edition_buffer
    clc
    adc     #40
    bcc     @skip
    inc     vi_current_position_ptr_edition_buffer+1
@skip:
    sta     vi_current_position_ptr_edition_buffer
    
    
@out:    
    jmp     edition_mode_routine

    
left_pressed:
  
	;jmp     go_left_on_screen  
    lda     vi_screen_x_position_edition
    cmp     vi_first_column
    ;beq     restart_edition

    dec     vi_screen_x_position_edition
	
	
    lda vi_current_position_ptr_edition_buffer
    bne @nodec
    dec vi_current_position_ptr_edition_buffer+1
@nodec:
    dec vi_current_position_ptr_edition_buffer
	


    jmp     edition_mode_routine
.endproc

.proc right_pressed

    ; let's find if we have characters

    lda     vi_current_position_ptr_edition_buffer_end
    cmp     vi_current_position_ptr_edition_buffer        ; end of file ?
    bne     @continue

    lda     vi_current_position_ptr_edition_buffer_end+1
    cmp     vi_current_position_ptr_edition_buffer+1       ; end of file ?
    beq     @skip

@continue:
    lda     vi_screen_x_position_edition
    cmp     #38
    bne     @next
    jmp     edition_mode_routine
@next:  
    ldy     #$01
    lda     (vi_current_position_ptr_edition_buffer),y
    cmp     #$0A
    beq     @skip
    cmp     #$0D
    beq     @skip
	
    inc     vi_screen_x_position_edition
 
    inc     vi_current_position_ptr_edition_buffer
    bne     @skip
    inc     vi_current_position_ptr_edition_buffer+1
@skip:

    jmp     edition_mode_routine
    rts
.endproc    

.proc return_pressed_routine

.IFPC02
.pc02
	stz 	vi_screen_x_position_edition
.p02    
.else
	lda 	#$00
	sta 	vi_screen_x_position_edition
.endif  
	inc 	vi_screen_y_position_edition

    lda     #$0A
    
.IFPC02
.pc02
    sta     (vi_current_position_ptr_edition_buffer)
.p02    
.else
    ldy     #$00
    sta     (vi_current_position_ptr_edition_buffer),y
.endif    
    inc     vi_current_position_ptr_edition_buffer
    bne     @skip3
    inc     vi_current_position_ptr_edition_buffer+1
@skip3:

    inc     vi_length_file
	bne		@skip2
	inc     vi_length_file+1
@skip2:	
    inc     vi_current_position_ptr_edition_buffer_end
	bne     @skip
	inc     vi_current_position_ptr_edition_buffer_end+1
@skip:
	jmp     edition_mode_routine  
.endproc    
  
.proc key_del_remove

    ;lda vi_first_column
    lda     vi_screen_x_position_edition
    beq     no_key_to_remove
    jsr     remove_char_in_textfile
    jsr     vi_editor_switch_off_cursor

    ldy     vi_screen_y_position_edition
    lda     TABLE_HIGH_TEXT,y
    sta     tmp0_16+1
    lda     TABLE_LOW_TEXT,y
    sta     tmp0_16  
    inc     tmp0_16
    bne     @skip
    inc     tmp0_16+1
@skip:
    
    lda     #38
    sec
    sbc     vi_screen_x_position_edition
    sta     TR7
 
    jsr     vi_editor_switch_off_cursor
    ldy     vi_screen_x_position_edition

@loop:
    lda     (tmp0_16),y
    dey
    sta     (tmp0_16),y
    iny
    iny
    cpy     TR7
    bne     @loop
    dec     vi_screen_x_position_edition
; dec position

    lda     vi_current_position_ptr_edition_buffer
	bne     @nodec
    dec     vi_current_position_ptr_edition_buffer+1
@nodec:
    dec     vi_current_position_ptr_edition_buffer



    lda     vi_length_file
	bne     @nodec2
    dec     vi_length_file+1
@nodec2:
	dec     vi_length_file
skip2:	
    
	lda     vi_current_position_ptr_edition_buffer_end
	bne     @nodec
	dec     vi_current_position_ptr_edition_buffer_end+1
@nodec:
    dec     vi_current_position_ptr_edition_buffer_end
skip5:

no_key_to_remove:    
    jmp     edition_mode_routine
.endproc
  
  
.proc put_key_on_screen

    ; FIXME 65C02
    pha
    lda     vi_current_position_ptr_edition_buffer         ; are we at the end of the file ?
    cmp     vi_current_position_ptr_edition_buffer_end
    bne     scroll
    
    lda     vi_current_position_ptr_edition_buffer+1
    cmp     vi_current_position_ptr_edition_buffer_end+1
    beq     don_t_scroll_line

; move line when a key is inserted    
scroll:
    ldy     vi_screen_y_position_edition
    lda     TABLE_LOW_TEXT,y
    sta     tmp0_16
    lda     TABLE_HIGH_TEXT,y
    sta     tmp0_16+1 
    dec     vi_screen_x_position_edition
    ldy     #38
    
  
@loop:
    lda     (tmp0_16),y
    iny
    sta     (tmp0_16),y
    dey
    dey
    cpy     vi_screen_x_position_edition
    bne     @loop
    inc     vi_screen_x_position_edition

don_t_scroll_line:
    ; move block to insert char in the text buffer
   jsr     insert_char_in_textfile    


	inc     vi_length_file
	bne     @skip
	inc     vi_length_file+1
@skip:	

	
    pla
.IFPC02
.pc02
    sta     (vi_screen_address_position_edition) ; store on the screen
    sta     (vi_current_position_ptr_edition_buffer) ; and store un text buffer
.p02    
.else
    ldy     #$00
    sta     (vi_screen_address_position_edition),y ; store on the screen
    sta     (vi_current_position_ptr_edition_buffer),y ; and store un text buffer
.endif		
    ; inc for next insert move me !
    inc     vi_current_position_ptr_edition_buffer ; inc the nextposition 
    bne     @skipinc
    inc     vi_current_position_ptr_edition_buffer+1 ; inc the nextposition 
@skipinc:   
    inc     vi_screen_x_position_edition

    lda     vi_current_position_ptr_edition_buffer  
    cmp     vi_current_position_ptr_edition_buffer_end
    bne     @fill_zero
    
    lda     vi_current_position_ptr_edition_buffer+1
    cmp     vi_current_position_ptr_edition_buffer_end+1
    beq     out
    
@fill_zero:
out:

    jmp     edition_mode_routine
.endproc  

.proc scrollup
    lda     #<VI_EDITION_VIDEO_ADRESS+40
    sta     SCROLL_TMP_FROM
    lda     #>VI_EDITION_VIDEO_ADRESS+40
    sta     SCROLL_TMP_FROM+1
    
    lda     #<VI_EDITION_VIDEO_ADRESS
    sta     SCROLL_TMP_TO
    lda     #>VI_EDITION_VIDEO_ADRESS
    sta     SCROLL_TMP_TO+1
    
    ldx     #$02
    ldy     #$00
@loop:   
    lda     (SCROLL_TMP_FROM),y
    sta     (SCROLL_TMP_TO),y
    iny
    bne     @loop
    inc     SCROLL_TMP_FROM+1
    inc     SCROLL_TMP_TO+1
    dex
    bpl     @loop
    ldy     #40
@loop2: 
    lda     (SCROLL_TMP_FROM),y
    sta     (SCROLL_TMP_TO),y
    iny
    bne     @loop2
    
    rts
.endproc
 
.proc command_edition
    lda     #$00 ; FIX 65c02
    sta     vi_screen_x_position_command
    jsr     vi_editor_switch_off_cursor
@loop:
    BRK_TELEMON XRDW0 ; read keyboard
    cmp     #'i'
    beq     switch_to_edition_mode
    cmp     #':'
    bne     @loop
    jmp     wait_command
.endproc

; ********************************************************************************* COMMAND edition  


.proc switch_to_edition_mode

    jsr     clear_command_line
    ldx     #$00
@loop:
    lda     msg_insert,x
    beq     @out
    sta     VI_COMMANDLINE_VIDEO_ADRESS,x
    inx
.IFPC02
.pc02
    bra     @loop
.p02    
.else
    jmp     @loop
.endif	
@out:
	jmp     edition_mode_routine
.endproc

.proc wait_command

  jsr     clear_command_line 
  lda     #':'

  sta     VI_COMMANDLINE_VIDEO_ADRESS                ; store ":" for the first char
  
  inc     vi_screen_x_position_command 
    
@wait_command_loopme:
  jsr     vi_command_line_vi_editor_switch_on_cursor       ; switch on cursor on command line
;.scope restart_commandline  
  BRK_TELEMON XRDW0 ; read keyboard
  cmp     #KEY_ESC
  beq     vi_clear_and_restart_command_mode
  cmp     #KEY_DEL
  bne     @test_key_return
  ; delete char on command line
  ldx     vi_screen_x_position_command                     ; Get the position of the cursor on command line
  cpx     #$01                                             ; if it's 1 (because we have on first char ":")
  beq     @wait_command_loopme                             ; We loop
  jsr     vi_command_line_vi_editor_switch_off_cursor      ; Switch off cursor
  lda     #$20                                             ; erase with a space                        
  dex                                                      ; go to left for one column
  sta     VI_COMMANDLINE_VIDEO_ADRESS,x                    ; erase
  inx                                                      ; ? 
  dec     vi_screen_x_position_command                     ; dec the position command
  lda     #$00                                             ; set EOS on command line buffer Fix
  sta     vi_command_line_edition_buffer,x                 ; Set EOS
  bne     @wait_command_loopme
  ; end of delete char on command line
@test_key_return:
  cmp     #KEY_RETURN
  bne     @skip

  jmp     interpret_commandline               ; enter pressed, 

@skip: 
  ldx     vi_screen_x_position_command
  cpx     #VI_COMMANDLINE_MAX_CHAR
  beq     @wait_command_loopme
  sta     VI_COMMANDLINE_VIDEO_ADRESS,x
  
  inx     
  cpx     #VI_COMMANDLINE_MAX_CHAR
  stx     vi_screen_x_position_command

    
  sta     vi_screen_x_position_command,x

  ; manage command line edition
  inx     

  jmp     @wait_command_loopme  ; fixme 65c02
.endproc


.proc vi_clear_and_restart_command_mode
  jsr     clear_command_line  
  jmp     command_edition
.endproc

.proc insert_char_in_textfile


  ; Check here for malloc

  lda     vi_current_position_ptr_edition_buffer_end
  sta     vi_tmp_16
  cmp     vi_current_position_ptr_edition_buffer
  bne     @continue
  
  ;sta     vi_tmp_16
  lda     vi_current_position_ptr_edition_buffer_end+1
  cmp     vi_current_position_ptr_edition_buffer+1
  beq     increment_buffer
  
@continue:
  lda     vi_current_position_ptr_edition_buffer_end+1  
  sta     vi_tmp_16+1

  continue_to_move_block:
    ldy     #$00
    lda     (vi_tmp_16),y
    iny
    sta     (vi_tmp_16),y
	lda     vi_tmp_16
	bne     @nodec
	dec     vi_tmp_16+1
@nodec:	
    dec     vi_tmp_16
    
skip2:
    lda     vi_tmp_16
    cmp     vi_current_position_ptr_edition_buffer
    bne     continue_to_move_block

    lda     vi_tmp_16+1
    cmp     vi_current_position_ptr_edition_buffer+1
    bne     continue_to_move_block
  
  end_copie:
  ; copy now the char below the cursor
    ldy     #$00
    lda     (vi_current_position_ptr_edition_buffer),y
	iny
	sta     (vi_current_position_ptr_edition_buffer),y
  

increment_buffer:
    inc     vi_current_position_ptr_edition_buffer_end
    bne     @skip
    inc     vi_current_position_ptr_edition_buffer_end+1
@skip:
  
    rts
.endproc
 
.proc command_line_suppress_char

  ldx     vi_screen_x_position_command
  cpx     #$01
  beq     @end
  jsr     vi_command_line_vi_editor_switch_off_cursor
  lda     #$20 ; erase with a space
  dex
  sta     VI_COMMANDLINE_VIDEO_ADRESS,x
  inx
  dec     vi_screen_x_position_command
  lda     #$00                            ; set EOS
  sta     vi_command_line_edition_buffer,x   ; Set EOS
  
@end:
    rts
  ; jmp     loopme
.endproc


.proc remove_char_in_textfile

 
    lda     vi_length_file
    bne     @nodec
    dec     vi_length_file+1
@nodec:
	dec     vi_length_file
 

  ; Check here for malloc

  lda     vi_current_position_ptr_edition_buffer  
  cmp     vi_current_position_ptr_edition_buffer_end
  bne     remove
  sta     vi_tmp_16
  lda     vi_current_position_ptr_edition_buffer+1
  cmp     vi_current_position_ptr_edition_buffer_end+1
  beq     remove
  sta     vi_tmp_16+1
  

continue_to_move_block:

  
    ldy     #$01
    lda     (vi_tmp_16),y
    
.IFPC02
.pc02    
    sta     (vi_tmp_16)
.p02    
.else    
    dey
    sta     (vi_tmp_16),y 
.endif

    inc     vi_tmp_16
    bne     @skip2
    inc     vi_tmp_16+1
@skip2:
  
    lda     vi_tmp_16
    cmp     vi_current_position_ptr_edition_buffer_end
    bne     continue_to_move_block

    lda     vi_tmp_16+1
    cmp     vi_current_position_ptr_edition_buffer_end+1
    bne     continue_to_move_block
  
end_copie: 

remove:  
  lda     vi_current_position_ptr_edition_buffer_end
  bne     @nodec
  dec     vi_current_position_ptr_edition_buffer_end+1
@nodec:
  dec     vi_current_position_ptr_edition_buffer_end
skip5:

  
  
    rts  
.endproc


  


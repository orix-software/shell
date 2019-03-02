
VI_COMMANDLINE_MAX_CHAR        = 8
VI_MAX_LENGTH_FILE             = 2000
VI_EDITOR_CHAR_LIMITS_EMPTY    = '~'
VI_COMMANDLINE_VIDEO_ADRESS    :=$bb80+40*27+1
VI_EDITION_LAST_VIDEO_ADRESS   := $bb80+40*26
VI_EDITION_VIDEO_ADRESS        :=$bb80
VI_EDITOR_MAX_LENGTH_OF_A_LINE = 38
VI_EDITOR_MAX_COLUMN = 40

INK_COLOR_GREEN = 2
INK_COLOR_MAGENTA = 6

ZP_APP_PTR1:=$90
ZP_APP_PTR2:=$92
ZP_APP_PTR3:=$94
ZP_APP_PTR4:=$96
ZP_APP_PTR5:=$98
ZP_APP_PTR6:=$9A
ZP_APP_PTR7:=$A6
ZP_APP_PTR8:=$9C
ZP_APP_PTR9:=$9E
ZP_APP_PTR10:=$A0
ZP_APP_PTR11:=$A2
ZP_APP_PTR12:=$A4

vi_screen_address_position_edition          := ZP_APP_PTR1 ; 2 bytes
tmp0_16                                     :=      ZP_APP_PTR2 ; 2 bytes
SCROLL_TMP_FROM                            :=   ZP_APP_PTR2 ; 2 bytes
vi_tmp_16                                  :=  ZP_APP_PTR2 ; 2 bytes
vi_tmp2_16                                :=   ZP_APP_PTR2 ; 2 bytes
vi_ptr_edition_buffer                      :=  ZP_APP_PTR3 ; 2 bytes
vi_screen_x_position_edition               :=  ZP_APP_PTR4 ; 1 byte
vi_screen_y_position_edition              :=   ZP_APP_PTR4+1 ; 1 byte
vi_screen_x_position_command 	          :=   ZP_APP_PTR5
vi_screen_y_position_edition_real         :=   ZP_APP_PTR5+1
SCROLL_TMP_TO                              :=  ZP_APP_PTR6 ; 2 bytes
vi_is_a_new_file                           :=  ZP_APP_PTR7 ; 1 bytes
vi_first_column                            :=  ZP_APP_PTR7+1 ; one byte, first column for vi
vi_current_position_ptr_edition_buffer     :=  ZP_APP_PTR8 ; 2 bytes
vi_current_position_ptr_edition_buffer_end  := ZP_APP_PTR11 ; 2 bytes
vi_length_file                              := ZP_APP_PTR9 ; 2 bytes
vi_current_position_in_edition_buffer       := ZP_APP_PTR10 ; 2 bytes
vi_struct                                   := ZP_APP_PTR12 ; 2 bytes
; Used only in edition mode when screen needs to scroll
VI_SIZE_OF_BUFFER                         =  1000


 vi_save_fp					 	  =	         tmp0_16
 vi_command_line_edition_buffer  = 		     tmp0_16
 vi_text_address			=		   		     tmp0_16

 SIZE_OF_VI_STRUCT 			=		         8+3+1+1
 VI_STRUCT_FILENAME_INDEX  =                   $00

.struct vi_struct
xpos_screen       .byte    ; position x of the cursor on the screen
ypos_screen       .byte    ; position y of the cursor on the screen
pos_file          .word    ; position on the file (address)
posx_command_line .byte    ; position on command line
ptr_file		  .word    ; adress of the beginning of the file
.endstruct


; VI_MODE_STRUCT_INDEX 						        $00
; SCREEN_X_POSITION_EDITION_STRUCT_INDEX 		        $01
; SCREEN_Y_POSITION_EDITION_STRUCT_INDEX 		 		$02
; SCREEN_ADDRESS_POSITION_EDITION_LOW_STRUCT_INDEX	$03 ; 2 bytes
; SCREEN_ADDRESS_POSITION_EDITION_HIGH_STRUCT_INDEX 	$04 ; 2 bytes



;**           How does it works ?                                                                                                    */
;** there is variables for editor :                                                                                                  */
;**  screen_address_position_edition    : it's the position of the cursor                                                                                             */
;**  screen_x_position_edition          : it saves coord X on the screen max value is VI_EDITOR_MAX_LENGTH_OF_A_LINE                 */
;**  screen_y_position_edition          : it saves coord Y on the screen max value is 27 because the last line is the commandline    */
;**  => each time screen_x_position_edition or screen_y_position_edition, update_position_screen must be called to update address    */

;*  _edition_buffer contains the plain text*/
;*  ptr_edition_buffer  is the adress where we are on the plain text*/ 
;*  text_adress ? */

;* Limits : Max 64 Kbytes for a file, but it's not possible because we have not enough memory, and file pointer are 16 bits        */

;* labels prefixed with _ are populated from C*/
   
   

.proc _vi
	SWITCH_OFF_CURSOR
    CLS
    MALLOC SIZE_OF_VI_STRUCT

    cmp     #NULL
    bne     @not_oom2
    cpy     #NULL
    bne     @not_oom2
    PRINT   str_OOM
    ; oom
    rts    
@not_oom2:   

    sta     vi_struct
    sty     vi_struct+1
	;sta 	$5000
	;sty 	$5001
    
    ldy     #$00
    lda     #$00
    sta     (vi_struct),y  ; FIXME 65C02
    
.IFPC02
.pc02
    stz     vi_screen_x_position_edition
    stz     vi_screen_y_position_edition
    stz     vi_first_column
    stz     vi_current_position_ptr_edition_buffer
    stz     vi_current_position_ptr_edition_buffer+1
    stz     vi_current_position_in_edition_buffer
    stz     vi_current_position_in_edition_buffer+1
	stz     vi_length_file
	stz     vi_length_file+1
.else    
    lda     #$00
    sta     vi_screen_x_position_edition
    sta     vi_screen_y_position_edition
    sta     vi_first_column
    sta     vi_current_position_ptr_edition_buffer
    sta     vi_current_position_ptr_edition_buffer+1
    sta     vi_current_position_in_edition_buffer
    sta     vi_current_position_in_edition_buffer+1
	sta     vi_length_file
	sta     vi_length_file+1	
.endif
   
    lda     #$01
    sta     vi_screen_y_position_edition_real
    sta     vi_is_a_new_file ; If 1 then it's a new file
    
    MALLOC  VI_SIZE_OF_BUFFER
    cmp     #NULL
    bne     not_oom
    cpy     #NULL
    bne     not_oom
    PRINT str_OOM
    ; oom
    rts
str_OOM:
    .asciiz "OOM"       ; FIXME import from general lib
not_oom:
    sta     vi_ptr_edition_buffer
    sta     vi_current_position_ptr_edition_buffer
    sta     vi_current_position_ptr_edition_buffer_end
    
    sty     vi_ptr_edition_buffer+1
    sty     vi_current_position_ptr_edition_buffer+1
    sty     vi_current_position_ptr_edition_buffer_end+1

    
    jsr     update_position_screen
    jsr     fill_screen_with_empty_line
    jsr     vi_editor_switch_on_cursor
	

    ldx     #$01				; get the first arg, 
    jsr     _orix_get_opt
    FOPEN ORIX_ARGV,O_RDONLY    ; tries to open the file
    
    
    cpx     #$ff
    bne     load_file
    cmp     #$ff
    bne     load_file
    beq     not_found

	
load_file:                       ; Valid file		
	; Load the file
    sta     vi_save_fp          ; save fp
    sty     vi_save_fp+1
	
    ldy     #$00             

@loop:
    lda     ORIX_ARGV,y         ; store the filename in vi struct
    sta     (vi_struct),y
    beq     @out
	
    ; store filename in the struct
    
    iny
.IFPC02
.pc02
    bra     @loop
.else
    jmp     @loop
.endif	
@out:

    
    ; 

    lda     vi_ptr_edition_buffer
    sta     PTR_READ_DEST
    lda     vi_ptr_edition_buffer+1

    sta     PTR_READ_DEST+1
    lda     #<VI_SIZE_OF_BUFFER-1
    ldy     #>VI_SIZE_OF_BUFFER-1
    BRK_ORIX XFREAD
    lda     #$00
    ; And of file 
.IFPC02
.pc02
    sta     (PTR_READ_DEST)
.else    
    ldy     #$00  ; fix 65c02
    sta     (PTR_READ_DEST),y
.endif    
    ; compute the length loaded vi_length_file
    
    lda     PTR_READ_DEST+1
    sec
    sbc     vi_ptr_edition_buffer+1
    tax			
    lda     PTR_READ_DEST
    sec
    sbc     vi_ptr_edition_buffer
    sta     vi_length_file
    stx     vi_length_file+1
    ; set the end of the buffer end
	txa
	clc 
	adc     vi_current_position_ptr_edition_buffer_end+1
	sta     vi_current_position_ptr_edition_buffer_end+1
	
    lda     vi_length_file
	clc
	adc     vi_current_position_ptr_edition_buffer_end
	bcc     skipadd
	inc     vi_current_position_ptr_edition_buffer_end+1
skipadd:	
	sta     vi_current_position_ptr_edition_buffer_end
    
    lda     vi_ptr_edition_buffer
    sta     tmp0_16
    
    lda     vi_ptr_edition_buffer+1
    sta     tmp0_16+1
	; and displays
restart_load:    
    ldy     #$00
@loop:
    lda     (tmp0_16),y
    beq     @out
    cmp     #$0A ; return line ?
	bne     @next2
    jsr     add40_to_vi_screen_address_position_edition
    jmp     @loop    

@next:
    cmp     #$0D
    bne     @next2
    jsr     add40_to_vi_screen_address_position_edition
	jmp     @loop
@next2:
    ;jsr syntax_highlight_display
    sta     (vi_screen_address_position_edition),y
@skip:
    iny
    bne     @loop
@out:
.IFPC02
.pc02
    stz     vi_screen_x_position_edition
    stz     vi_screen_y_position_edition
    stz     vi_is_a_new_file ; If 1 then it's an new file   
.p02    
.else
    lda     #$00
    sta     vi_screen_x_position_edition
    sta     vi_screen_y_position_edition
    sta     vi_is_a_new_file ; If 1 then it's an new file   
.endif    
    lda     #$01
    
    sta     vi_screen_y_position_edition_real
    
   


	jsr     vi_editor_fill_screen_with_text
	jmp     start
not_found:  
;********************************
;* Displays "argv[1]" [new file]*
;********************************
    ;  init the current filename with \0 (null)
    lda     #$00
.IFPC02
.pc02
    sta     (vi_struct)
.else
    ldy     #$00
    sta     (vi_struct),y
.endif    
    lda     ORIX_ARGV     
    beq     start ; not args
    ; at this step we have a filename passed in first arg
    ; let's displays "new file ..."

    lda     #34                             ; Displays "
    sta     VI_COMMANDLINE_VIDEO_ADRESS     ; on command line 
    ldx     #$01                
    
    ldy     #$00

@loop:
    lda     ORIX_ARGV,y                     ; read filename passed in arg
    sta     (vi_struct),y
    beq     @out3
    sta     VI_COMMANDLINE_VIDEO_ADRESS,x   ; and displays in command line
    ; store filename in the struct
    
    inx
    iny
    jmp     @loop
    
@out3:
    

    lda     #34
    sta     VI_COMMANDLINE_VIDEO_ADRESS,x
    inx
    lda     #' '
    sta     VI_COMMANDLINE_VIDEO_ADRESS,x
    inx
    
    ldy     #$00
@loop2:
    lda     msg_nofile,y
    beq     @out
    sta     VI_COMMANDLINE_VIDEO_ADRESS,x
    inx
    iny
    jmp     @loop2
@out:
;***************************************/
;* End of Displays "argv[1]" [new file]*/
;***************************************/


; Clear screen  
start:
    jsr     update_position_screen
	jsr     command_edition
    rts
skip_crlf:

    inc     tmp0_16
    bne     @skip
    inc     tmp0_16+1
@skip:
    jmp     restart_load

inc_tmp0_16_with_y:

    tya
    sec ; add one
    adc     tmp0_16
    bcc     @skip
    inc     tmp0_16+1
@skip:
    sta     tmp0_16
    inc     vi_screen_y_position_edition
    lda     #$00
    sta     vi_screen_x_position_edition
    jsr     update_position_screen    
    jmp     restart_load ; fix 650c02
  

syntax_highlight_display:

    pha
    ;vi_screen_x_position_edition
    cmp #';'
    bne @out
    lda #INK_COLOR_GREEN
    sta (vi_screen_address_position_edition),y
    iny
    jmp @finish ; fixme 65C02
@out:
    cmp #'#'
    bne @out2
    lda #INK_COLOR_MAGENTA
    sta (vi_screen_address_position_edition),y
    iny
    jmp @finish  ; fixme 65C02
    
@out2:
@finish:

    pla
   
    rts

vi_detect_syntax_highlight:  
    ; is it asm ?
   
    ldx     #$00
@loop:
    lda     ORIX_ARGV,x
    beq     @out
    cmp     #'.'
    beq     @dot_found
    inx
    bne     @loop
    jmp     @out
@dot_found:
    inx
    lda     ORIX_ARGV,x
    cmp     #'a'
    bne     @out
    inx 
    lda     ORIX_ARGV,x
    cmp     #'s'
    bne     @out    
    lda     ORIX_ARGV,x
    cmp     #'m'
    bne     @out
    ; asm
   ; inc vi_first_column
@out:
   rts

 
add40_to_vi_screen_address_position_edition:

    ; update pointer
	tya
	sec                  ; sec instead of clc because we skip $0A or $0D char
	adc     tmp0_16
	bcc     @skip
	inc     tmp0_16+1
@skip:
    sta     tmp0_16

	inc     vi_screen_y_position_edition
	lda     vi_first_column
	sta     vi_screen_x_position_edition ; fixme 65c02

	jsr     update_position_screen
    ldy     #$00


    rts

    
print_new_file:

.include "vi/lib.asm"

syntax_highlight:
    .byte ".asm",0,0 ; ext, end of string, definition highlight
    .byte ".s",0,0
    .byte ".c",0,1
    .byte ".sh",0,2
definition_highlight:
    .byte ";",2 ; command : color 2


msg_insert:
    .asciiz "-- INSERT --"
msg_nofile:
    .asciiz "[New File]"
    
msg_nofilename:
    .byte 17,"E32: No file name",16,0    
	
msg_impossibletowrite:
    .byte 17,"E99: Impossible to write",16,0
    
msg_written:
    .asciiz "written"
.endproc

.proc _ls
    NUMBER_OF_COLUMNS_LS = 3
   
    
    lda #NUMBER_OF_COLUMNS_LS+1
    sta NUMBER_OF_COLUMNS ; used to do columns

    jsr _ch376_verify_SetUsbPort_Mount
    cmp #$01
    beq @error
    jmp no_error_for_mouting
@error:
    rts
no_error_for_mouting:
    ; jump to all directories :)
    jsr _cd_to_current_realpath_new
    

    ldx #$01
    jsr _orix_get_opt
    STRCPY ORIX_ARGV,BUFNOM

no_param:
    
    lda BUFNOM
    bne ispattern
  
    lda #'*'
    sta BUFNOM


.IFPC02
.pc02
    stz BUFNOM+1
.p02    
.else
	lda #$00
	sta BUFNOM+1
.endif
  
ispattern:
    jsr _ch376_set_file_name
	
;***************************************************************************** opening (root) */
	
    jsr _ch376_file_open
	 
next_entry:
    cmp #CH376_USB_INT_SUCCESS ;int_success
    beq fin_catalogue
    cmp #CH376_USB_INT_DISK_READ
    bne fin_catalogue

    LDA #CH376_RD_USB_DATA0 ;$27
    STA CH376_COMMAND
    lda CH376_DATA ;fetch the length 
    cmp #32
    beq catalogue_ok

out_ls:
    rts
catalogue_ok:
    jsr display_one_file_catalog
.IFPC02
.pc02
    bra next_entry
.p02
.else
    jmp next_entry
.endif

fin_catalogue:
    BRK_TELEMON XCRLF  ;jump a line
    rts

display_one_file_catalog:
    lda #COLOR_FOR_FILES
    sta BUFNOM

    ldy #$01
    ldx #$01
loop12:

    lda CH376_DATA ; Fetch char
    cmp #' '
    beq no_need_to_display_space
    jsr _lowercase_char
    sta BUFNOM,y ; we store it
    iny


no_need_to_display_space:	
	
    inx
    cpx #$09 ; Do we display dot ?
    bne no_dot_to_display

    lda #'.'
    sta BUFNOM,y
    sty TR5 ; store the position of '.'
    iny

no_dot_to_display:
	; Suppress dot if there is not an extension

    ; if X=10 then we test if there is an extension
    cpx #10 
    bne don_t_test_if_extension_contains_chars
    cmp #' ' ; Is it a space ? if yes, we delete . of the filename
    bne don_t_test_if_extension_contains_chars
	; deleting .
    lda TR5
    sty TR5
    tay
    lda #' '
    sta BUFNOM,y ; at this step, filename is "man" instead of "man."
    ldy TR5

	
don_t_test_if_extension_contains_chars:
    cpx #12
    bne loop12
loop19:
    LDA #$00
    sta BUFNOM,y    ; stz can be used in 65C02 but with X register instead of Y
    sty TEMP_ORIX_1 ; Store the length
   
	; reading attributes
    lda CH376_DATA ; fetching attributes
    cmp #$10
    bne it_is_a_file
	; Its a directorty
    lda #COLOR_FOR_DIRECTORY
    sta BUFNOM
    dey ; we remove "."

    LDA #$00
    sta BUFNOM,y

    sty TEMP_ORIX_1
it_is_a_file:
    ldx #20 ; don't care but we read it, it's the attributes

@loop:
    lda CH376_DATA ; First byte is a
    dex
    bpl @loop


    lda BUFNOM           ; read first char of the file
    cmp #'.'             ; is it a dot ?
    beq no_other_space	 ; Yes we don't want to be displayed
	
    lda BUFNOM+1         ; read first char of the file
    cmp #'.'             ; is it a dot ?
    beq no_other_space	 ; Yes we don't want to be displayed

    dec NUMBER_OF_COLUMNS
    bne no_need_to_CRLF

    BRK_TELEMON XCRLF
    lda #NUMBER_OF_COLUMNS_LS
    sta NUMBER_OF_COLUMNS
  
no_need_to_CRLF:
    PRINT BUFNOM

	; Add space in order to have a columns

@loop:
    ldy TEMP_ORIX_1
    cpy #13   ; FIXME FNAME_LEN ?
    beq no_other_space
    iny
    sty TEMP_ORIX_1
    CPUTC ' '
.IFPC02    
.pc02
    bra @loop
.p02    
.else
    jmp @loop
.endif

    
no_other_space:

    lda #CH376_FILE_ENUM_GO ; 33
    sta CH376_COMMAND
    jsr _ch376_wait_response
	
    rts
optstring:
    .asciiz "l"
.endproc




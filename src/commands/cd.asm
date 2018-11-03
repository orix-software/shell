
#define OLD_PATH_MANAGEMENT 1
_cd
.(
    ldx #$01
    jsr _orix_get_opt
    STRCPY(ORIX_ARGV,BUFNOM)
    lda BUFNOM 
    beq end ; ok it's "cd"
    cmp #"/"
    bne not_root
    lda BUFNOM+1
    bne not_root
  
    lda #$01
    sta ORIX_PATH_CURRENT_POSITION
#ifdef CPU_65C02
    stz ORIX_PATH_CURRENT+1
#else
    lda #$00 
    sta ORIX_PATH_CURRENT+1
#endif
    rts
	
	// Here we return to /
not_root
    cmp #"\"
    beq end
    lda BUFNOM
    cmp #"."
    bne not_dot
    lda BUFNOM+1 ;
    beq end2 ; it's "cd ."
    cmp #"."
    bne not_dot 
	; it's "cd .."
pull_last_directory	
    ldx ORIX_PATH_CURRENT_POSITION
loop4	
    dex
    lda ORIX_PATH_CURRENT,x
    cmp #"/"
    bne loop4
    stx ORIX_PATH_CURRENT_POSITION

    ldx ORIX_PATH_CURRENT_POSITION
    bne don_t_inx
    inx
don_t_inx	
    lda #$00 ; FIXME 65C02
    sta ORIX_PATH_CURRENT,x
end
    rts
	
not_dot
		; if we are here, we are in /
;
    ldx ORIX_PATH_CURRENT_POSITION
    cpx #ORIX_MAX_PATH_LENGTH
    bne we_don_t_reach_the_max_folder_level_for_oric
    PRINT(str_max_level) ; MACRO
end2	
	rts

we_don_t_reach_the_max_folder_level_for_oric

    lda ORIX_PATH_CURRENT_POSITION
    cmp #$01
    beq don_t_concat_slash
    lda #"/"
	sta ORIX_PATH_CURRENT,x
    inx
don_t_concat_slash	
    ldy #$00
loop5	
    lda BUFNOM,y ; FIXME 65C02
    beq launch
  ; if it's '/' and it's the first char we don't copy /
    cpy #$00
    bne store_char
    cmp #"\"
    beq end2  
    cmp #"/"
    bne store_char
    iny
#ifdef CPU_65C02
    bra loop5
#else
    jmp loop5
#endif  
store_char  
    sta ORIX_PATH_CURRENT,x
    inx
    iny
#ifdef CPU_65C02
    bra loop5
#else
    jmp loop5
#endif  

	; storing to the array
	; let's go storing it
launch
    sta ORIX_PATH_CURRENT,x
    stx ORIX_PATH_CURRENT_POSITION

    jsr _ch376_verify_SetUsbPort_Mount
    cmp #$01
    beq cd_error_param
    BRK_TELEMON(XOPENRELATIVE)

    beq no_error
    ; error here, pop
    ldx #$00
    jsr _orix_get_opt
    PRINT(BUFNOM)
	
    PRINT(str_not_found) ; MACRO	
#ifdef CPU_65C02
    jmp pull_last_directory
#else
    jmp pull_last_directory	
#endif
no_error
    lda     ERRNO
    cmp     #CH376_ERR_OPEN_DIR
    bne     it_is_not_a_folder
cd_error_param
	rts	
it_is_not_a_folder
    PRINT(str_not_a_directory)
#ifdef CPU_65C02
    jmp pull_last_directory ; too away from label 
#else
    jmp pull_last_directory
#endif
    rts
str_not_a_directory:
    .asc "Not a directory",$0D,$0A,0	
str_max_level
    .asc "Limit is ",$30+(ORIX_MAX_PATH_LENGTH-1)," chars",0
.)	


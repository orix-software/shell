.export _cd


.proc _cd
    jmp     cd_2
    cd_path := userzp
    ; Let's malloc
    MALLOC(KERNEL_MAX_PATH_LENGTH)
    sta     cd_path
    sty     cd_path+1


    ldx     #$01
    jsr     _orix_get_opt
    STRCPY ORIX_ARGV, BUFNOM
    lda     BUFNOM 
    beq     end         ; user typed 'cd'  only we jump to the end
    cmp     #'/'        ; does the user type on the first char '/'
    bne     not_root    ; no
    lda     BUFNOM+1
    bne     not_root
  
    lda     #$01
    sta     ORIX_PATH_CURRENT_POSITION

    ldy     #$00
    lda     #'/'
    sta     (cd_path),y
    iny
    lda     #$00
    sta     (cd_path),y


    lda     cd_path
    ldy     cd_path+1
    BRK_KERNEL   XPUTCWD_ROUTINE

    jmp     free

	
	; Here we return to /
not_root:
    cmp     #'\'        ; Does user type '\'
    beq     end
    lda     BUFNOM
    cmp     #'.'
    bne     not_dot
    lda     BUFNOM+1 ;
    beq     end2 ; it's "cd ."
    cmp     #'.'
    bne     not_dot 
	; it's "cd .."
pull_last_directory:
    ldx     ORIX_PATH_CURRENT_POSITION
@loop:
    dex
    lda     shell_bash_variables+shell_bash_struct::path_current,x
    cmp     #'/'
    bne     @loop
    stx     ORIX_PATH_CURRENT_POSITION

    ldx     ORIX_PATH_CURRENT_POSITION
    bne     don_t_inx
    inx
don_t_inx:	
    lda     #$00 ; FIXME 65C02
    sta     shell_bash_variables+shell_bash_struct::path_current,x
end:
    jmp     free
	
not_dot:
		; if we are here, we are in /
;
    ldx     ORIX_PATH_CURRENT_POSITION
    cpx     #ORIX_MAX_PATH_LENGTH
    bne     we_don_t_reach_the_max_folder_level_for_oric
    PRINT   str_max_level  ; MACRO
end2:
    jmp     free

we_don_t_reach_the_max_folder_level_for_oric:

    lda     ORIX_PATH_CURRENT_POSITION
    cmp     #$01
    beq     don_t_concat_slash
    lda     #'/'
    sta     shell_bash_variables+shell_bash_struct::path_current,x
    inx
don_t_concat_slash:
    ldy     #$00
loop5:
    lda     BUFNOM,y ; FIXME 65C02
    beq     launch
  ; if it's '/' and it's the first char we don't copy /
    cpy     #$00
    bne     store_char
    cmp     #'\'
    beq     end2  
    cmp     #'/'
    bne     store_char
    iny
.IFPC02
.pc02
    bra     loop5
.p02    
.else
    jmp     loop5
.endif  
store_char:
    sta     shell_bash_variables+shell_bash_struct::path_current,x
    inx
    iny
.IFPC02
.pc02
    bra     loop5
.p02    
.else
    jmp     loop5
.endif  

	; storing to the array
	; let's go storing it
launch:
    sta     shell_bash_variables+shell_bash_struct::path_current,x
    stx     ORIX_PATH_CURRENT_POSITION

    jsr     _ch376_verify_SetUsbPort_Mount
    cmp     #$01
    beq     cd_error_param
    lda     #<shell_bash_variables+shell_bash_struct::path_current
    ldy     #>(shell_bash_variables+shell_bash_struct::path_current+1)
    BRK_KERNEL XOPENRELATIVE

    beq     no_error
    ; error here, pop
    ldx     #$00
    jsr     _orix_get_opt
    PRINT   BUFNOM
	
    PRINT   str_not_found ; MACRO	

.IFPC02
.pc02 ; ???? FIXME bra ?
    jmp     pull_last_directory
.p02    
.else
    jmp     pull_last_directory	
.endif
no_error:
    lda     ERRNO
    cmp     #CH376_ERR_OPEN_DIR
    bne     it_is_not_a_folder
cd_error_param:
    jmp     free

it_is_not_a_folder:
    PRINT str_not_a_directory

    jmp pull_last_directory ; too away from label 

free:
    lda     cd_path
    ldy     cd_path+1
    BRK_KERNEL XFREE
    rts

str_not_a_directory:
    .byte "Not a directory",$0D,$0A,0	
str_max_level:
    .byte "Limit is ",$30+(ORIX_MAX_PATH_LENGTH-1)," chars",0
str_root:
    .asciiz "/"
cd_2:
    MALLOC(KERNEL_MAX_PATH_LENGTH)
    sta     cd_path
    ;sta     RES
    sty     cd_path+1
    ;sty     RES+1
    ;jsr     _trim


    ldx     #$01
    jsr     _orix_get_opt

    ; copy in malloc
    ldy     #$00
@L1:
    lda     ORIX_ARGV,y
    beq     @S1
    sta     (cd_path),y
    iny
    bne     @L1
@S1:    
    sta     (cd_path),y

    

    lda     cd_path
    ldx     cd_path+1
    ldy     #O_RDONLY

    BRK_KERNEL XOPEN

    cmp     #NULL
    bne     @not_null
    cpy     #NULL
    bne     @not_null

    PRINT str_not_a_directory
    ; Error
    jmp     free_cd_memory

@not_null:
    lda     cd_path
    ldy     cd_path+1
    BRK_KERNEL   XPUTCWD_ROUTINE


free_cd_memory:
    lda     cd_path
    ldy     cd_path+1
    BRK_KERNEL XFREE
    rts    
.endproc


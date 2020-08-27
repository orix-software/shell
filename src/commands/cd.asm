.export _cd


.proc _cd
    cd_path := sh_ptr_for_internal_command
    cd_fp := userzp+2
    cd_fp_tmp := userzp+2


    ; Let's malloc
    MALLOC(KERNEL_MAX_PATH_LENGTH)
    cmp     #NULL
    bne     @not_null_1
    cpy     #NULL
    bne     @not_null_1
    PRINT   str_oom
    rts 
@not_null_1:
    sta     cd_path
    sty     cd_path+1

    ldx     #$01
    jsr     _orix_get_opt


    ; copy in malloc args
    ldy     #$00
@L1:
    lda     ORIX_ARGV,y
    beq     @S1
    sta     (cd_path),y
    iny
    bne     @L1
@S1:    
    sta     (cd_path),y
    ; Remove / at the end (to avoid cd /usr///)
@L7:    
    dey
    beq     @it_slash
    lda     (cd_path),y
    cmp     #'/'
    bne     @path_with_no_slash_at_the_end
    lda     #$00
    sta     (cd_path),y
    jmp     @L7
@it_slash:

    lda     (cd_path),y

    cmp     #'/'
    beq     @launch_xput


@path_with_no_slash_at_the_end:


@not_slash_only:

    ; check if it's . or ..
    ; FIXME : add trim
    
    ldy     #$00
    lda     (cd_path),y
    cmp     #'.'
    bne     @not_dot
    iny
    lda     (cd_path),y
    beq     @only_one_dot
    cmp     #'.'
    bne     @free_cd_memory ; it's  'cd .' only then, jump. 

    ; Here we have 'cd ..'
    ; let's pull folder
    BRK_KERNEL XGETCWD  ; Get A & Y 
    sta     cd_path
    sty     cd_path+1
    ; loop until we reach 0
    ; is it cd .. when we are in / ?
    ldy     #$01
    lda     (cd_path),y
    beq     @free_cd_memory ; yes we go out

    ldy     #$00
@L2:    
    lda     (cd_path),y
    beq     @end_of_string_found
    
    iny
    bne     @L2
    rts     ; Error overflow return with no error
@end_of_string_found:
    ; now let's find last '/'
    dey
@L3:    
    lda     (cd_path),y
    cmp     #'/'
    beq     @try_to_recurse
    dey
    bne     @L3
    ; We reached 0 : then we are in "/" root
    iny     
    bne     @slash_found
@only_one_dot:    
    rts

@slash_found:


    lda     #$00
    sta     (cd_path),y

@launch_xput:
    lda     cd_path
    ldy     cd_path+1
    BRK_KERNEL   XPUTCWD_ROUTINE
    ; and free
    jmp     @free_cd_memory


@not_dot:
    lda     cd_path
    ldx     cd_path+1
    ldy     #O_RDONLY

    BRK_KERNEL XOPEN

    cmp     #NULL
    bne     @not_null
    cpy     #NULL
    bne     @not_null
    ; Free fp
    BRK_KERNEL XFREE
    PRINT str_not_a_directory

    jmp     @free_cd_memory

@not_null:
    ; Free FP
    BRK_KERNEL XFREE
    lda     cd_path
    ldy     cd_path+1

    BRK_KERNEL   XPUTCWD_ROUTINE

@free_cd_memory:
    lda     cd_path
    ldy     cd_path+1
    BRK_KERNEL XFREE
    rts

@try_to_recurse:
    cpy     #$00
    bne     @fill_eos
    ;lda     #$11
    ;sta     $bb80
    iny
@fill_eos:

    lda     #$00
    sta     (cd_path),y

    lda     cd_path
    ldy     cd_path+1
    ;sta     $5000
    ;sty     $5001
    BRK_KERNEL   XPUTCWD_ROUTINE
    jmp     @free_cd_memory
    
    ; cdpath++
    ; cdpath++
    ; remove ..
    inc     cd_path
    bcc     @do_not_inc_1
    inc     cd_path+1
@do_not_inc_1:    
    inc     cd_path
    bcc     @do_not_inc_2
    inc     cd_path+1
    ; cdpath++ (because ../usr/ for example)
@do_not_inc_2:    
    inc     cd_path
    bcc     @do_not_inc_3
    inc     cd_path+1
@do_not_inc_3:
;   at this step cd_path should be here : usr/ 
 jmp     @free_cd_memory   
    bne     @not_dot
    rts    
str_not_a_directory:
    .byte "Not a directory",$0D,$0A,0	
.endproc


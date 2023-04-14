.export _cd

.proc _cd
    cd_path           := sh_ptr_for_internal_command
    cd_fp             := userzp+2
    cd_fp_tmp         := userzp+4
    ; Avoid userzp+6
    cd_argv1_ptr      := ptr1_for_internal_command ; 16 bits
    cd_path_2         := userzp+6



    ; Let's malloc
    MALLOC(KERNEL_MAX_PATH_LENGTH)
    cmp     #NULL
    bne     @not_null_1
    cpy     #NULL
    bne     @not_null_1
    print   str_oom
    rts
@not_null_1:
    sta     cd_path
    sty     cd_path+1

    ; Get first arg

    lda     bash_struct_ptr
    sta     cd_argv1_ptr

    lda     bash_struct_ptr+1
    sta     cd_argv1_ptr+1

    ldy     #shell_bash_struct::command_line
@get_first_arg:
    lda     (bash_struct_ptr),y
    beq     @found_eos
    cmp     #' ' ; Read command line until we reach a space.
    beq     @found_space
    inc     cd_argv1_ptr
    bne     @skip30
    inc     cd_argv1_ptr+1
@skip30:
    iny
    bne     @get_first_arg
@found_eos:
    mfree(cd_path)
    rts



@found_space:
    inc     cd_argv1_ptr
    bne     @skip40
    inc     cd_argv1_ptr+1
@skip40:


    ; copy in malloc args
    ldy     #$00
@L1:
    lda     (cd_argv1_ptr),y
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
    beq     @launch_xput2


@path_with_no_slash_at_the_end:


@not_slash_only:

    ; check if it's . or ..
    ; FIXME : add trim

    ldy     #$00
    lda     (cd_path),y
    cmp     #'.'
    bne     not_dot
    iny
    lda     (cd_path),y
    beq     @only_one_dot
    cmp     #'.'
    bne     free_cd_memory ; it's  'cd .' only then, jump.

    ; Here we have 'cd ..'
    ; let's pull folder
    BRK_KERNEL XGETCWD  ; Get A & Y

    sta     cd_path_2
    sty     cd_path_2+1
    ; loop until we reach 0
    ; is it cd .. when we are in / ?
    ldy     #$01
    lda     (cd_path),y
    beq     free_cd_memory ; yes we go out

    ldy     #$00
@L2:
    lda     (cd_path_2),y
    beq     @end_of_string_found

    iny
    bne     @L2
    rts     ; Error overflow return with no error
@end_of_string_found:
    ; now let's find last '/'
    dey
@L3:
    lda     (cd_path_2),y
    cmp     #'/'
    beq     try_to_recurse
    dey
    bne     @L3
    ; We reached 0 : then we are in "/" root
    iny
    bne     @slash_found
@only_one_dot:
    rts

@slash_found:


    lda     #$00
    sta     (cd_path_2),y

@launch_xput:
    lda     cd_path_2
    ldy     cd_path_2+1
    BRK_KERNEL   XPUTCWD
    ; and free
    jmp     free_cd_memory

@launch_xput2:
    lda     cd_path
    ldy     cd_path+1
    BRK_KERNEL   XPUTCWD
    ; and free
    jmp     free_cd_memory


not_dot:

    fopen (cd_path), O_RDONLY

    cpx     #$FF
    bne     @not_null
    cmp     #$FF
    bne     @not_null

    mfree(cd_path)

    print str_not_a_directory
    rts


@not_null:
    ; Free FP
    sta     cd_fp
    stx     cd_fp+1
    fclose(cd_fp)

    lda     cd_path
    ldy     cd_path+1
    BRK_KERNEL   XPUTCWD

free_cd_memory:
    mfree(cd_path)
    rts

try_to_recurse:
    cpy     #$00
    bne     @fill_eos

    iny
@fill_eos:

    lda     #$00
    sta     (cd_path_2),y

    lda     cd_path_2
    ldy     cd_path_2+1

    BRK_KERNEL   XPUTCWD
    jmp     free_cd_memory


str_not_a_directory:
    .byte "Not a directory",$0D,$0A,0
.endproc

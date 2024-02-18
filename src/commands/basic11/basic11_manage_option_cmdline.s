.proc basic11_manage_option_cmdline
    lda     basic11_current_arg_id
    cmp     basic11_argc
    beq     @end_of_arg

    getmainarg basic11_current_arg_id, (basic11_argv_ptr) ; Get first arg
    sta     basic11_argv1_ptr
    sty     basic11_argv1_ptr+1

    ldy     #$01
    lda     (basic11_argv1_ptr),y
    beq     @unknown_option

    cmp     #'g'
    beq     @gui

    cmp     #'l'
    beq     @list

    cmp     #'p'
    beq     @root_path

    cmp     #'r'
    beq     @select_rom

@unknown_option:
    lda     #BASIC11_OPTION_UNKNOWN
    rts

@end_of_arg:
    lda     #BASIC11_END_OF_ARGS
    rts

@select_rom:
    inc     basic11_current_arg_id
    lda     #BASIC11_SET_ROM
    rts

@root_path:
    inc     basic11_current_arg_id
    lda     #BASIC11_DEFAULT_PATH_SET
    rts

@gui:
    lda     #BASIC11_START_GUI
    rts

@list:
    lda     #BASIC11_START_LIST
    rts
.endproc

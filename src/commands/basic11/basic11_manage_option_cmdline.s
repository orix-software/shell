.proc basic11_manage_option_cmdline

    ldy     basic11_current_arg_id
    lda     (basic11_argv1_ptr),y

    cmp     #'g'
    beq     @gui

    cmp     #'l'
    beq     @list

    cmp     #'p'
    beq     @root_path

    lda     #BASIC11_OPTION_UNKNOWN
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

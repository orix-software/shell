.proc basic11_menu_letter_management_left
;    jmp     basic11_menu_letter_management_left
    lda     basic11_first_letter_gui
    cmp     #'A'
    bne     @skip
    lda     #':'
    sta     basic11_first_letter_gui
@skip:
    dec     basic11_first_letter_gui

.ifdef basic11_debug
    lda     basic11_first_letter_gui
    sta     $bb80+16
.endif

    ldy     #basic11_gui_struct::current_index_letter
    lda     (basic11_ptr4),y
    tax

    lda     $bb80+27*40+3,x
    and     #%01111111
    sta     $bb80+27*40+3,x
    dex
    lda     $bb80+27*40+3,x
    ora     #$80
    sta     $bb80+27*40+3,x
    ;dex
    txa
    sta     (basic11_ptr4),y

    ; reset now       #basic11_gui_struct::current_entry_id ; ???

    lda     #$00

    ldy     #basic11_gui_struct::current_entry_id ; ???
 
    sta     (basic11_ptr4),y
 
    ldy     #basic11_gui_struct::basic11_posy_screen ; ???
    sta     (basic11_ptr4),y

    ldy     #basic11_gui_struct::max_current_entries
    sta     (basic11_ptr4),y


@no_move:

    rts
.endproc

.define BASIC11_MAX_NUMBER_OF_SOFTWARE_PER_PAGE 26

.struct basic11_gui_struct
  current_index_letter                .res 1 
  index                               .res 46 ; index letter
  basic11_posy_screen                 .res 1
  number_of_lines_displayed           .res 1
  key_found                           .res 1
  max_current_entries                 .res 1
  current_entry_id                    .res 1
  current_key                         .res 8
  command_launch                      .res 7+1+1+8+1 ; basic11 "12345678\0
  key_software_index_low              .res BASIC11_MAX_NUMBER_OF_SOFTWARE_PER_PAGE
  key_software_index_high             .res BASIC11_MAX_NUMBER_OF_SOFTWARE_PER_PAGE
.endstruct

.if     .sizeof(basic11_gui_struct) > 255
  .error  "basic11_gui_struct size can not be greater than 255. It's impossible because code does not handle a struct greater than 255"
.endif

.proc basic11_start_gui
    cursor off
    malloc .sizeof(basic11_gui_struct),basic11_ptr4,str_enomem ; Index ptr

    ; init index
    ldy     #basic11_gui_struct::index
    lda     #$00
@L200:    
    sta     (basic11_ptr4),y
    iny
    cpy     #(basic11_gui_struct::index+46)
    bne     @L200

    ; init posy_screen
    ldy     #basic11_gui_struct::basic11_posy_screen
    lda     #$00
    sta     (basic11_ptr4),y

    ldy     #basic11_gui_struct::max_current_entries
    lda     #$00
    sta     (basic11_ptr4),y

    ldy     #basic11_gui_struct::index
    lda     basic11_ptr1
    sta     (basic11_ptr4),y
    iny
    lda     basic11_ptr1+1
    sta     (basic11_ptr4),y


    ldy     #basic11_gui_struct::current_index_letter
    lda     #$00
    sta     (basic11_ptr4),y

    ldy     #basic11_gui_struct::basic11_posy_screen
    sta     (basic11_ptr4),y

    ; Displays only '1'
    
    lda     #'1'
    sta     basic11_first_letter_gui
    lda     #$00
    sta     basic11_current_letter_index
    ; Skip version DB

    lda     basic11_ptr1+1
    sta     basic11_ptr2+1

    lda     basic11_ptr1
    sec
    adc     #$00
    bcc     @add_to_ptr
    inc     basic11_ptr2+1
@add_to_ptr:    
    sta     basic11_ptr2

    
  
    jsr     basic11_displays_frame

    jsr     basic11_menu_letter_management_right

; Display initial bar


    ; end of initial bar

    jsr     displays_gui_list
    
    jsr     compute_position_bar
    jsr     displays_bar    



@loopinformations:

    BRK_KERNEL XRDW0            ; read keyboard
    cmp     #KEY_RIGHT
    beq     @change_letter_right    ; right key not managed

    cmp     #KEY_LEFT
    beq     @change_letter_left
    ;beq     start_commandline    ; left key not managed
    
    cmp     #KEY_UP
    beq     @keyup
    cmp     #KEY_RETURN
    beq     @keyenter    ; down key not managed
    cmp     #KEY_DOWN
    beq     @keydown    ; down key not managed
    cmp     #KEY_ESC          ; is it enter key ?
    beq     @exitgui             ; no we display the char
    jmp     @loopinformations
@exitgui:
    cursor on
    jmp     _clrscr
@keyenter:
    ; get
    jmp     basic11_launch
    ;jmp     @exitgui

@change_letter_right:
    
    ldx     basic11_current_letter_index
    cpx     #34
    beq     @loopinformations
    inx     
    stx     basic11_current_letter_index
    jsr     basic11_update_ptr_fp
    inc     basic11_first_letter_gui
    jsr     basic11_menu_letter_management_right
    ; init posy_screen
    jsr     basic11_init_bar     
    jmp     @manage_display

@change_letter_left:
    
    lda     basic11_current_letter_index
    cmp     #$00
    beq     @donot_dex
    dec     basic11_first_letter_gui
    dec     basic11_current_letter_index
@donot_dex:       
    lda     basic11_first_letter_gui
    
    jsr     basic11_update_ptr_fp
    inc     basic11_first_letter_gui    
    jsr     basic11_menu_letter_management_left
    jsr     basic11_init_bar

    jmp     @manage_display
@keyup:
    jsr     keyup_bar
    jmp     @loopinformations
@keydown:
    jsr     keydown_bar
    jmp     @loopinformations

@manage_display:
    jsr     basic11_clear_menu
    
    jsr     displays_gui_list
    ;basic11_first_letter_gui
    jmp     @loopinformations


.endproc

.proc basic11_init_bar
    ; init posy_screen
    ldy     #basic11_gui_struct::max_current_entries
    lda     #$00
    sta     (basic11_ptr4),y

    ldy     #basic11_gui_struct::basic11_posy_screen
    lda     #$00
    sta     (basic11_ptr4),y
    jsr     compute_position_bar
    jsr     displays_bar    
    rts
.endproc

.proc   basic11_launch
    lda     basic11_ptr1
    ldy     basic11_ptr1+1
    BRK_KERNEL XFREE

    ldy     #basic11_gui_struct::current_entry_id
    lda     (basic11_ptr4),y
    sta     basic11_saveA
    clc
    adc     #basic11_gui_struct::key_software_index_low
    
    tay
    lda     (basic11_ptr4),y
    sta     basic11_ptr3
    
    lda     basic11_saveA
    clc
    adc     #basic11_gui_struct::key_software_index_high
    sta     basic11_ptr3+1
    tay
    lda     (basic11_ptr4),y
    sta     basic11_ptr3+1

    tay
    lda     basic11_ptr3
    BRK_KERNEL XWSTR0
    
    lda     basic11_ptr4
    sta     basic11_ptr1
    lda     basic11_ptr4+1
    sta     basic11_ptr1+1

    ldy     #basic11_gui_struct::command_launch
    clc
    adc     basic11_ptr1
    bcc     @S500
    inc     basic11_ptr1+1
@S500:    
    sta     basic11_ptr1

    ldx     #$00
    ldy     #$00
@L500:    
    lda     str_basic11,x
    beq     @out500
    sta     (basic11_ptr1),y
    inx
    iny
    jmp     @L500
@out500:

    ldy     #$00
@L600:    
    lda     (basic11_ptr3),y
    cmp     #';'
    beq     @end_of_command
    sta     basic11_saveA
    iny
    sty     basic11_saveY
    txa
    tay
    lda     basic11_saveA
    sta     (basic11_ptr1),y
    iny
    tya
    tax
    ldy     basic11_saveY
    jmp     @L600
    ; X

@end_of_command:
    txa
    tay
    lda     #$00
    sta     (basic11_ptr1),y

    ; free all
    lda     basic11_ptr4
    ldy     basic11_ptr4+1
    BRK_KERNEL XFREE

    lda     basic11_ptr2
    ldy     basic11_ptr2+1
    BRK_KERNEL XFREE

    ldy     basic11_ptr1+1
    lda     basic11_ptr1
    BRK_KERNEL XEXEC
    ;BRK_KERNEL XWSTR0

    


    rts
str_basic11:     
    .byte "basic11 "
    .byte $22,$00 ; "
.endproc

.proc basic11_clear_menu
    ; displays line
    ldy     #$00
@display_line:    

    lda     basic_str_emptyline,y    
    beq     @outline
    sta     $bb80+40,y
    sta     $bb80+80,y
    sta     $bb80+120,y
    sta     $bb80+160,y
    sta     $bb80+200,y
    sta     $bb80+240,y
    sta     $bb80+280,y
    sta     $bb80+320,y
    sta     $bb80+360,y
    sta     $bb80+400,y
    sta     $bb80+440,y
    sta     $bb80+480,y
    sta     $bb80+520,y
    sta     $bb80+560,y
    sta     $bb80+600,y
    sta     $bb80+640,y
    sta     $bb80+680,y
    sta     $bb80+720,y
    sta     $bb80+760,y
    sta     $bb80+800,y
    sta     $bb80+840,y
    sta     $bb80+880,y
    sta     $bb80+920,y
    sta     $bb80+960,y
    sta     $bb80+1000,y

    iny
    bne     @display_line
@outline:
    rts
.endproc    

.proc basic11_displays_frame
    ; displays line
    ldy     #$00
@display_line:    
    lda     basic_str_fullline_title,y
    
    beq     @outline
    
    sta     $bb80,y

    lda     basic_str_fullline,y
    sta     $bb80+26*40,y


    iny
    bne     @display_line
@outline:
    jsr     basic11_clear_menu
    lda     #'!'
    sta     $bb80+27*40+2

    ldx     #'1'
    ldy     #$00
@L1_menu:    
    txa
    sta     $bb80+27*40+3,y
    iny
    inx
    cpx     #':'
    bne     @L1_menu

    ldx     #'A'
    ldy     #$00
@L2_menu:    
    txa
    sta     $bb80+27*40+10+2,y
    iny
    inx
    cpx     #'Z'+1
    bne     @L2_menu    
    rts
.endproc

.proc basic11_menu_letter_management_right
    lda     basic11_first_letter_gui
    sec
    sbc     #'1'
    ;beq     @no_move

    tax
    lda     $bb80+27*40+2,x
    and     #%01111111
    sta     $bb80+27*40+2,x
    inx
    lda     $bb80+27*40+2,x
    ora     #$80
    sta     $bb80+27*40+2,x
@no_move:

    rts
.endproc

.proc basic11_menu_letter_management_left
    lda     basic11_first_letter_gui
    sec
    sbc     #'1'

    tax
    lda     $bb80+27*40+2,x
    and     #%01111111
    sta     $bb80+27*40+2,x
    dex
    lda     $bb80+27*40+2,x
    ora     #$80
    sta     $bb80+27*40+2,x
@no_move:

    rts
.endproc

.proc compute_position_bar
    lda     #>($bb80+40+1)
    sta     basic11_ptr3+1

    lda     #<($bb80+40+1)
    sta     basic11_saveA
    sta     basic11_ptr3

    ldy     #basic11_gui_struct::basic11_posy_screen
    lda     (basic11_ptr4),y
    tax
    pha

    beq     @S1

    lda     basic11_saveA
@L1:
    clc
    adc     #40
    bcc     @S2
    inc     basic11_ptr3+1
@S2:
    dex
    bne     @L1    
    sta     basic11_saveA
@S1:
    lda     basic11_saveA
    sta     basic11_ptr3
    
    jsr     displays_bar
    pla
    rts
.endproc

.proc keyup_bar
    ldy    #basic11_gui_struct::basic11_posy_screen
    lda    (basic11_ptr4),y
    beq    @out
    jsr    compute_position_bar
    pha
    jsr     erase_bar
    pla
    tax
    dex
    txa
    ldy     #basic11_gui_struct::basic11_posy_screen
    sta     (basic11_ptr4),y
    jsr     compute_position_bar

    jsr     displays_bar    
@out:
    rts
.endproc

.proc keydown_bar
    ldy     #basic11_gui_struct::max_current_entries
    lda     (basic11_ptr4),y
    pha
    pla

    ; add index now
    ldy     #basic11_gui_struct::current_entry_id
    lda     (basic11_ptr4),y
    sec
    adc     #$00
    sta     (basic11_ptr4),y


    lda     (basic11_ptr4),y
    sec
    adc     #$00
    sta     (basic11_ptr4),y

    jsr     compute_position_bar
    pha
    jsr     erase_bar
    pla
    tax
    inx
    txa
    ldy     #basic11_gui_struct::basic11_posy_screen
    sta     (basic11_ptr4),y
    jsr     compute_position_bar

    jsr     displays_bar    

    rts
.endproc

.proc  displays_gui_list

    ldy     #basic11_gui_struct::number_of_lines_displayed
    lda     #$00
    sta     (basic11_ptr4),y

    ldy     #basic11_gui_struct::current_entry_id
    lda     #$00
    sta     (basic11_ptr4),y

    lda     #<($bb80+42)
    sta     basic11_ptr3
    
    lda     #>($bb80+42)
    sta     basic11_ptr3+1

    ldy     #$00
    sty     basic11_tmp 


    lda     #$00
    sta     basic11_gui_key_reached
    sta     basic11_current_parse_software

    
    
    ;       index first software
    jsr     basic11_build_index_software

    ldx     #$00
    ldy     #$00
@L1:    
    lda     (basic11_ptr2),y
    beq     @end_name_software_reached
    cmp     #$FF
    beq     @read_end_of_file
    
    cmp     #';'
    beq     @end_key_reached
    
    sta     basic11_saveA

    lda     basic11_gui_key_reached
    beq     @skip_displays
    sty     basic11_saveY

    ldy     basic11_tmp
    lda     basic11_saveA
    sta     (basic11_ptr3),y
    iny
    sty     basic11_tmp

@reload_y:
    ldy     basic11_saveY
    
@skip_displays:    
    iny
    bne     @L1
    inc     basic11_ptr2+1
    jmp     @L1
@read_end_of_file:    
    rts
@end_key_reached:
    ; Max entries 
    sty     basic11_saveY
    jmp         @it_s_the_same_letter_to_parse
    ; Test if the next software char is equal to the current.
    iny
    lda     (basic11_ptr2),y
    cmp     basic11_first_letter_gui
    beq     @it_s_the_same_letter_to_parse
;@loopme:    
    ;jmp     @loopme
    ; Exit
    rts
@it_s_the_same_letter_to_parse:
    ldy     #basic11_gui_struct::max_current_entries
    lda     (basic11_ptr4),y
    sec
    adc     #$00
    sta     (basic11_ptr4),y
    

    inc     basic11_gui_key_reached
    jmp     @reload_y

@end_name_software_reached:
    ;

    iny
    lda     (basic11_ptr2),y   
    cmp     basic11_first_letter_gui
    beq     @same_firt_letter
    ; test if the next letters is basic11_first_letter_gui+1
    tax
    inx
    cpx     basic11_first_letter_gui
    beq     @compute_next_letter
    ; THe next letter is not the current + 1, will fill the next index with 0
@compute_next_letter:
    tya    
    clc
    adc     basic11_ptr2
    ; build next index
    bcc     @S300
    inc     basic11_ptr2+1
@S300:
    sta     basic11_ptr2

    ldy     #basic11_gui_struct::current_entry_id
    



    lda     basic11_first_letter_gui
    sec 
    sbc     #'1'
    asl
    tay
    clc
    adc     #basic11_gui_struct::index
    tay
    lda     basic11_ptr2
    sta     (basic11_ptr4),y
    iny
    lda     basic11_ptr2+1
    sta     (basic11_ptr4),y

    rts
@same_firt_letter:    
    dey


    lda     basic11_ptr3
    clc
    adc     #$28
    bcc     @S1
    inc     basic11_ptr3+1
@S1:
    sta     basic11_ptr3

;key_software_index_low

    tya
    tax ; Save Y

    jsr     basic11_build_index_software
    inc     basic11_current_parse_software
    txa

    clc
    adc     basic11_ptr2
    bcc     @S10
    inc     basic11_ptr2+1
@S10:
    sta     basic11_ptr2

    ldy     #basic11_gui_struct::number_of_lines_displayed
    lda     (basic11_ptr4),y
    cmp     #24
    bne     @continue
    rts
@continue:
    tax
    inx
    txa
    sta     (basic11_ptr4),y

    ldy     #$00

    sty     basic11_tmp
    

    dec     basic11_gui_key_reached
    jmp     @skip_displays
    

.endproc

.proc basic11_build_index_software

    lda     #basic11_gui_struct::key_software_index_low
    clc
    adc     basic11_current_parse_software
    tay
    lda     basic11_ptr2
    sta     (basic11_ptr4),y
    
    lda     #basic11_gui_struct::key_software_index_high
    clc
    adc     basic11_current_parse_software
    tay
    lda     basic11_ptr2+1
    sta     (basic11_ptr4),y
    rts
.endproc

.proc erase_bar
    ldy     #$00
    lda     #$10
    sta     (basic11_ptr3),y
    rts
.endproc

.proc displays_bar
    ldy     #$00
    lda     #$11
    sta     (basic11_ptr3),y
    ldy     #37
    lda     #$10
    sta     (basic11_ptr3),y
    rts
.endproc

.proc  basic11_display_bar_compute

    rts
.endproc

.proc basic11_update_ptr_fp
    lda     basic11_first_letter_gui
    sec
    sbc     #'1'
    asl
    clc
    adc     #basic11_gui_struct::index
    tay
    lda     (basic11_ptr4),y
    sta     basic11_ptr2
    iny
    lda     (basic11_ptr4),y
    sta     basic11_ptr2+1

    rts
.endproc    

basic_str_fullline_title:
    .asciiz  "+-Basic 11 Menu------------------------+"        
basic_str_fullline:
    .asciiz  "+--------------------------------------+"    
basic_str_emptyline:
    .asciiz  "|                                      |"

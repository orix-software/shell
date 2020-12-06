
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

; basic11_ptr1 ptr of the maindb

.proc basic11_start_gui
    cursor off
    malloc #.sizeof(basic11_gui_struct),basic11_ptr4,str_enomem ; Index ptr

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

    ;jsr     basic11_menu_letter_management_right
    ldx     #$00
    lda     $bb80+27*40+3,x
    ora     #$80
    sta     $bb80+27*40+3,x


    ; Initialize position bar to posY)0
    ldy     #basic11_gui_struct::basic11_posy_screen
    lda     #$00
    sta     (basic11_ptr4),y

; Display initial bar


    ; end of initial bar

    jsr     displays_gui_list
    
    jsr     basic11_init_bar



@loopinformations:

  ;  BRK_KERNEL XWR0
    jsr     basic11_read_joystick
    cmp     #$00
    bne     @joystick_pressed
    BRK_KERNEL XRD0     ; Should be removed but when we do ctrl+c we can not launch another command after
    bcs     @loopinformations
@joystick_pressed:


   ; BRK_KERNEL XRDW0            ; read keyboard
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
    lda     basic11_ptr1
    ldy     basic11_ptr1+1
    BRK_KERNEL XFREE    
    jmp     basic11_launch
    ;jmp     @exitgui

@change_letter_right:

    ldy     basic11_gui_struct::current_index_letter
    lda     (basic11_ptr4),y
    cmp     #34
    beq     @loopinformations

    
    ldy     #basic11_gui_struct::max_current_entries
    lda     #$00
    sta     (basic11_ptr4),y

    jsr     basic11_update_ptr_fp
    
    jsr     basic11_menu_letter_management_right
    ; init posy_screen
  
    jmp     @manage_display

@change_letter_left:
    ldy     basic11_gui_struct::current_index_letter
    lda     (basic11_ptr4),y
    
    beq     @loopinformations    

    
    jsr     basic11_menu_letter_management_left

    

     
    lda     basic11_first_letter_gui
    
    jsr     basic11_update_ptr_fp


    jsr     basic11_init_bar
@donot_dex:
    jmp     @manage_display
@keyup:
    jsr     basic11_keyup_bar
    jmp     @loopinformations
@keydown:
    jsr     basic11_keydown_bar
    jmp     @loopinformations

@manage_display:
    jsr     basic11_clear_menu
    
    jsr     displays_gui_list
    jsr     basic11_init_bar   
    ;basic11_first_letter_gui
    jmp     @loopinformations


.endproc

.proc basic11_init_bar
    ; init posy_screen


    ldy     #basic11_gui_struct::basic11_posy_screen
    lda     #$00
    sta     (basic11_ptr4),y
    jmp     compute_position_bar
   
    
.endproc

.include "basic11_launch.asm"
.include "basic11_clear_menu.asm"
.include "basic11_displays_frame.asm"
.include "basic11_menu_letter_management_right.asm"
.include "basic11_menu_letter_management_left.asm"

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


.include  "basic11_keyup_bar.asm"
.include  "basic11_keydown_bar.asm"


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
    cmp     #$FF            ; End of file found
    beq     @read_end_of_file
    
    cmp     #';'  ; We reached the end of key
    beq     @end_key_reached
    
    sta     basic11_saveA

    lda     basic11_gui_key_reached
    beq     @skip_displays
    sty     basic11_saveY

    ldy     basic11_tmp
    ; Displays
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
    ;jmp     @it_s_the_same_letter_to_parse
    ; Test if the next software char is equal to the current.

    ; Exit    
    iny
    lda     (basic11_ptr2),y
    cmp     basic11_first_letter_gui
    beq     @it_s_the_same_letter_to_parse

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
    ; The next letter is not the current + 1, will fill the next index with 0
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
    


    ; Trying to build index
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

.proc   basic11_read_joystick
    lda     $320
    and     #%00011111
    tax
    eor     #%11100100
    cmp     #$04
    bne     @S1
    lda     #KEY_RETURN
    rts
@S1:
    txa
    eor     #%11100001
    cmp     #$01
    bne     @S2
@S2:        
    lda     #$00
    rts
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

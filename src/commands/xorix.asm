.export _xorix

.struct  xorix_struct
  xpos_screen       .byte    ; position x of the cursor on the screen
  ypos_screen       .byte    ; position y of the cursor on the screen
.endstruct


.proc _xorix
XORIX_BEGIN_MENU                  :=$A000
XORIX_BEGIN_BACKGROUND_GRID       :=$A000+40*8+(3)*40
XORIX_BEGIN_BACKGROUND_GRID_EVEN  :=XORIX_BEGIN_BACKGROUND_GRID
XORIX_BEGIN_BACKGROUND_GRID_ODD   :=XORIX_BEGIN_BACKGROUND_GRID+40

XORIX_STRUCT_ptr:=userzp 
;XORIX struct
;unsigned char posx;
;unsigned char posy;
;ptr1_tmp   := userzp+2
pos_cursor := userzp+4

posx         := userzp+2
posy         := userzp+6

posx_old       := userzp+7
posy_old       := userzp+8

cursor       := userzp+9
cursor_read_sprite       := userzp+12
posx_byte_cur       := userzp+13



  BRK_KERNEL XHIRES
  MALLOC .sizeof(xorix_struct)
  sta XORIX_STRUCT_ptr
  sty XORIX_STRUCT_ptr+1
  ; init pos

  ldx #10
  stx posx
  stx posx_old

  ldx #10
  stx posy
  stx posy_old

  ldy #$00
  lda #$00
  sta (XORIX_STRUCT_ptr),y
  iny
  sta (XORIX_STRUCT_ptr),y
 
 ; lda #$17
  ;sta $A000   ; empty
  
  ;sta $A000+40
  ;sta $A000+80  
  ;sta $A000+120
  ;sta $A000+160

;  sta $A000+200
  ;sta $A000+240
  ;sta $A000+280  
  ;sta $A000+320

  ;sta $A000+360 ; empty

  ;jsr _blit_menu
  ;jsr _blit_background
loopme:
  jsr _get_joystick_mouse
  jsr put_cursor
  jsr wait
  jmp  loopme

  rts
 ; rts

 
  _blit_background:

    lda #<XORIX_BEGIN_BACKGROUND_GRID_EVEN
    sta RES
    lda #>XORIX_BEGIN_BACKGROUND_GRID_EVEN
    sta RES+1
    lda #<XORIX_BEGIN_BACKGROUND_GRID_ODD
    sta RESB
    lda #>XORIX_BEGIN_BACKGROUND_GRID_ODD
    sta RESB+1
    ldx #93

blit_line:
    jsr blit_bg_line_odd
    jsr blit_bg_line_even
    lda RES
    clc
    adc #80
    bcc skip2
    inc RES+1
  skip2:
    sta RES

    lda RESB
    clc
    adc #80
    bcc @skip
    inc RESB+1
@skip:
    sta RESB
    dex
    bpl blit_line

    rts
blit_bg_line_even:
    ldy #39
    lda #%01101010
@loop:
    sta (RES),y
    dey
    bpl @loop
    rts

blit_bg_line_odd:
    ldy #39
    lda #%01010101
  @loop:
    sta (RESB),y
    dey
    bpl @loop
    rts


  
  _blit_menu:
   
    lda   #$01
    sta   HRSFB
    lda   #100
    sta   HRS1
    lda   #100
    sta   HRS2
        
      
    lda   #<str_file
    sta   RES
    lda   #>str_file
    sta   RES+1
    jsr   _outtext
  
    rts
str_file:
    .asciiz "File"

wait:
  ldy #$FA
@L2:  
  ldx #$00
@L1:  
  inx
  bne @L1
  iny
  bne @L2
  rts


_get_joystick_mouse:
        lda     VIA2::PRB
        eor     #%11111111
        pha
        and     #%00001000
        cmp     #%00001000
        bne     @not_down
        ldx     posy
        cpx     #200-14
        beq     @not_down
        inc     posy
@not_down:
        pla
        pha
        and     #%00010000
        cmp     #%00010000
        bne     @not_up
        ldx     posy
        beq     @not_up
        dec     posy
@not_up:
        pla

        pha
        and     #%00000001
        cmp     #%00000001
        bne     @not_right
        ldx     posx
        cpx     #240
        beq     @not_right
        inc     posx
@not_right:
        pla

        pha
        and     #%00000010
        cmp     #%00000010
        bne     @not_left
        ldx     posx
        beq     @not_left
        dec     posx
@not_left:
        pla


        rts
_get_usb_mouse:
  jsr     _ch376_wait_response
  rts


SDL_HiresTableHigh:
.byt >($a000)
.byt >($a000+40)
.byt >($a000+80)
.byt >($a000+120)
.byt >($a000+160)
;5
.byt >($a000+200)
.byt >($a000+240)
.byt >($a000+280)
.byt >($a000+320)
.byt >($a000+360)
;10)
.byt >($a000+400)
.byt >($a000+440)
.byt >($a000+480)
.byt >($a000+520)
.byt >($a000+560)
;15
.byt >($a000+600)
.byt >($a000+640)
.byt >($a000+680)
.byt >($a000+720)
.byt >($a000+760)
;20)
.byt >($a000+800)
.byt >($a000+840)
.byt >($a000+880)
.byt >($a000+920)
.byt >($a000+960)
;25
.byt >($a000+1000)
.byt >($a000+1040)
.byt >($a000+1080)
.byt >($a000+1120)
.byt >($a000+1160)
;30)
.byt >($a000+1200)
.byt >($a000+1240)
.byt >($a000+1280)
.byt >($a000+1320)
.byt >($a000+1360)
;35
.byt >($a000+1400)
.byt >($a000+1440)
.byt >($a000+1480)
.byt >($a000+1520)
.byt >($a000+1560)
;40)
.byt >($a000+1600)
.byt >($a000+1640)
.byt >($a000+1680)
.byt >($a000+1720)
.byt >($a000+1760)
;45
.byt >($a000+1800)
.byt >($a000+1840)
.byt >($a000+1880)
.byt >($a000+1920)
.byt >($a000+1960)
;50)
.byt >($a000+2000)
.byt >($a000+2040)
.byt >($a000+2080)
.byt >($a000+2120)
.byt >($a000+2160)
;55
.byt >($a000+2200)
.byt >($a000+2240)
.byt >($a000+2280)
.byt >($a000+2320)
.byt >($a000+2360)
;60)
.byt >($a000+2400)
.byt >($a000+2440)
.byt >($a000+2480)
.byt >($a000+2520)
.byt >($a000+2560)
;65
.byt >($a000+2600)
.byt >($a000+2640)
.byt >($a000+2680)
.byt >($a000+2720)
.byt >($a000+2760)
;70)
.byt >($a000+2800)
.byt >($a000+2840)
.byt >($a000+2880)
.byt >($a000+2920)
;75
.byt >($a000+2960)
.byt >($a000+3000)
.byt >($a000+3040)
.byt >($a000+3080)
.byt >($a000+3120)
;80)
.byt >($a000+3160)
.byt >($a000+3200)
.byt >($a000+3240)
.byt >($a000+3280)
.byt >($a000+3320)
;85
.byt >($a000+3360)
.byt >($a000+3400)
.byt >($a000+3440)
.byt >($a000+3480)
.byt >($a000+3520)
;90)
.byt >($a000+3560)
.byt >($a000+3600)
.byt >($a000+3640)
.byt >($a000+3680)
.byt >($a000+3720)
;95
.byt >($a000+3760)
.byt >($a000+3800)
.byt >($a000+3840)
.byt >($a000+3880)
.byt >($a000+3920)
;100)
.byt >($a000+3960)
.byt >($a000+4000)
.byt >($a000+4040)
.byt >($a000+4080)
.byt >($a000+4120)
;105
.byt >($a000+4160)
.byt >($a000+4200)
.byt >($a000+4240)
.byt >($a000+4280)
.byt >($a000+4320)
;110)
.byt >($a000+4360)
.byt >($a000+4400)
.byt >($a000+4440)
.byt >($a000+4480)
.byt >($a000+4520)
;115
.byt >($a000+4560)
.byt >($a000+4600)
.byt >($a000+4640)
.byt >($a000+4680)
.byt >($a000+4720)
;120)
.byt >($a000+4760)
.byt >($a000+4800)
.byt >($a000+4840)
.byt >($a000+4880)
.byt >($a000+4920)
;125
.byt >($a000+4960)
.byt >($a000+5000)
.byt >($a000+5040)
.byt >($a000+5080)
.byt >($a000+5120)
;130)
.byt >($a000+5160)
.byt >($a000+5200)
.byt >($a000+5240)
.byt >($a000+5280)
.byt >($a000+5320)
;135
.byt >($a000+5360)
.byt >($a000+5400)
.byt >($a000+5440)
.byt >($a000+5480)
.byt >($a000+5520)
;140)
.byt >($a000+5560)
.byt >($a000+5600)
.byt >($a000+5640)
.byt >($a000+5680)
.byt >($a000+5720)
;145
.byt >($a000+5760)
.byt >($a000+5800)
.byt >($a000+5840)
.byt >($a000+5880)
.byt >($a000+5920)
;150)
.byt >($a000+5960)
.byt >($a000+6000)
.byt >($a000+6040)
.byt >($a000+6080)
.byt >($a000+6120)
;155
.byt >($a000+6160)
.byt >($a000+6200)
.byt >($a000+6240)
.byt >($a000+6280)
.byt >($a000+6320)
;160)
.byt >($a000+6360)
.byt >($a000+6400)
.byt >($a000+6440)
.byt >($a000+6480)
.byt >($a000+6520)
;165
.byt >($a000+6560)
.byt >($a000+6600)
.byt >($a000+6640)
.byt >($a000+6680)
.byt >($a000+6720)
;170)
.byt >($a000+6760)
.byt >($a000+6800)
.byt >($a000+6840)
.byt >($a000+6880)
.byt >($a000+6920)
;175
.byt >($a000+6960)
.byt >($a000+7000)
.byt >($a000+7040)
.byt >($a000+7080)
.byt >($a000+7120)
;180)
.byt >($a000+7160)
.byt >($a000+7200)
.byt >($a000+7240)
.byt >($a000+7280)
.byt >($a000+7320)
;185
.byt >($a000+7360)
.byt >($a000+7400)
.byt >($a000+7440)
.byt >($a000+7480)
.byt >($a000+7520)
;190)
.byt >($a000+7560)
.byt >($a000+7600)
.byt >($a000+7640)
.byt >($a000+7680)
.byt >($a000+7720)
;195
.byt >($a000+7760)
.byt >($a000+7800)
.byt >($a000+7840)
.byt >($a000+7880)
.byt >($a000+7920)
.byt >($a000+7920+40)


SDL_HiresTableLow:

.byt <($a000)
.byt <($a000+40)
.byt <($a000+80)
.byt <($a000+120)
.byt <($a000+160)
;5
.byt <($a000+200)
.byt <($a000+240)
.byt <($a000+280)
.byt <($a000+320)
.byt <($a000+360)
;10)
.byt <($a000+400)
.byt <($a000+440)
.byt <($a000+480)
.byt <($a000+520)
.byt <($a000+560)
;15
.byt <($a000+600)
.byt <($a000+640)
.byt <($a000+680)
.byt <($a000+720)
.byt <($a000+760)
;20)
.byt <($a000+800)
.byt <($a000+840)
.byt <($a000+880)
.byt <($a000+920)
.byt <($a000+960)
;25
.byt <($a000+1000)
.byt <($a000+1040)
.byt <($a000+1080)
.byt <($a000+1120)
.byt <($a000+1160)
;30)
.byt <($a000+1200)
.byt <($a000+1240)
.byt <($a000+1280)
.byt <($a000+1320)
.byt <($a000+1360)
;35
.byt <($a000+1400)
.byt <($a000+1440)
.byt <($a000+1480)
.byt <($a000+1520)
.byt <($a000+1560)
;40)
.byt <($a000+1600)
.byt <($a000+1640)
.byt <($a000+1680)
.byt <($a000+1720)
.byt <($a000+1760)
;45
.byt <($a000+1800)
.byt <($a000+1840)
.byt <($a000+1880)
.byt <($a000+1920)
.byt <($a000+1960)
;50)
.byt <($a000+2000)
.byt <($a000+2040)
.byt <($a000+2080)
.byt <($a000+2120)
.byt <($a000+2160)
;55
.byt <($a000+2200)
.byt <($a000+2240)
.byt <($a000+2280)
.byt <($a000+2320)
.byt <($a000+2360)
;60)
.byt <($a000+2400)
.byt <($a000+2440)
.byt <($a000+2480)
.byt <($a000+2520)
.byt <($a000+2560)
;65
.byt <($a000+2600)
.byt <($a000+2640)
.byt <($a000+2680)
.byt <($a000+2720)
.byt <($a000+2760)
;70)
.byt <($a000+2800)
.byt <($a000+2840)
.byt <($a000+2880)
.byt <($a000+2920)
;75
.byt <($a000+2960)
.byt <($a000+3000)
.byt <($a000+3040)
.byt <($a000+3080)
.byt <($a000+3120)
;80)
.byt <($a000+3160)
.byt <($a000+3200)
.byt <($a000+3240)
.byt <($a000+3280)
.byt <($a000+3320)
;85
.byt <($a000+3360)
.byt <($a000+3400)
.byt <($a000+3440)
.byt <($a000+3480)
.byt <($a000+3520)
;90)
.byt <($a000+3560)
.byt <($a000+3600)
.byt <($a000+3640)
.byt <($a000+3680)
.byt <($a000+3720)
;95
.byt <($a000+3760)
.byt <($a000+3800)
.byt <($a000+3840)
.byt <($a000+3880)
.byt <($a000+3920)
;100)
.byt <($a000+3960)
.byt <($a000+4000)
.byt <($a000+4040)
.byt <($a000+4080)
.byt <($a000+4120)
;105
.byt <($a000+4160)
.byt <($a000+4200)
.byt <($a000+4240)
.byt <($a000+4280)
.byt <($a000+4320)
;110)
.byt <($a000+4360)
.byt <($a000+4400)
.byt <($a000+4440)
.byt <($a000+4480)
.byt <($a000+4520)
;115
.byt <($a000+4560)
.byt <($a000+4600)
.byt <($a000+4640)
.byt <($a000+4680)
.byt <($a000+4720)
;120)
.byt <($a000+4760)
.byt <($a000+4800)
.byt <($a000+4840)
.byt <($a000+4880)
.byt <($a000+4920)
;125
.byt <($a000+4960)
.byt <($a000+5000)
.byt <($a000+5040)
.byt <($a000+5080)
.byt <($a000+5120)
;130)
.byt <($a000+5160)
.byt <($a000+5200)
.byt <($a000+5240)
.byt <($a000+5280)
.byt <($a000+5320)
;135
.byt <($a000+5360)
.byt <($a000+5400)
.byt <($a000+5440)
.byt <($a000+5480)
.byt <($a000+5520)
;140)
.byt <($a000+5560)
.byt <($a000+5600)
.byt <($a000+5640)
.byt <($a000+5680)
.byt <($a000+5720)
;145
.byt <($a000+5760)
.byt <($a000+5800)
.byt <($a000+5840)
.byt <($a000+5880)
.byt <($a000+5920)
;150)
.byt <($a000+5960)
.byt <($a000+6000)
.byt <($a000+6040)
.byt <($a000+6080)
.byt <($a000+6120)
;155
.byt <($a000+6160)
.byt <($a000+6200)
.byt <($a000+6240)
.byt <($a000+6280)
.byt <($a000+6320)
;160)
.byt <($a000+6360)
.byt <($a000+6400)
.byt <($a000+6440)
.byt <($a000+6480)
.byt <($a000+6520)
;165
.byt <($a000+6560)
.byt <($a000+6600)
.byt <($a000+6640)
.byt <($a000+6680)
.byt <($a000+6720)
;170)
.byt <($a000+6760)
.byt <($a000+6800)
.byt <($a000+6840)
.byt <($a000+6880)
.byt <($a000+6920)
;175
.byt <($a000+6960)
.byt <($a000+7000)
.byt <($a000+7040)
.byt <($a000+7080)
.byt <($a000+7120)
;180)
.byt <($a000+7160)
.byt <($a000+7200)
.byt <($a000+7240)
.byt <($a000+7280)
.byt <($a000+7320)
;185
.byt <($a000+7360)
.byt <($a000+7400)
.byt <($a000+7440)
.byt <($a000+7480)
.byt <($a000+7520)
;190)
.byt <($a000+7560)
.byt <($a000+7600)
.byt <($a000+7640)
.byt <($a000+7680)
.byt <($a000+7720)
;195
.byt <($a000+7760)
.byt <($a000+7800)
.byt <($a000+7840)
.byt <($a000+7880)
.byt <($a000+7920)
.byt <($a000+7920+40)



 
  
  _outtext:

          ; count the length of the string
          ldy   #$00
  @loop:        
          lda   (RES),y
          beq   @out
          iny
          bne   @loop
  @out:
          ; XSCHAR routine from telemon needs to have the length of the string in X register
          ; copy Y register to X register. It could be optimized in 65C02 with TYX
          tya 
          tax
      
          lda   RES     ; XSCHAR needs in A and Y the adress of the string        
          ldy   RES+1    
          BRK_ORIX XSCHAR
          rts
filename_menu:
    .asciiz "/usr/share/xorix/menu.lst"

put_cursor:

  ldx   posy_old
  lda   SDL_HiresTableLow,x
  sta   pos_cursor

  lda   SDL_HiresTableHigh,x
  sta   pos_cursor+1



  ldy  posx_old
  lda  posx_byte,y
  sta  posx_byte_cur



  ldx   #$00
@L2:
  ldy   posx_byte_cur
@L1:  
  
  lda   #%01000000
  sta   (pos_cursor),y

  lda  pos_cursor
  clc
  adc  #$28
  bcc  @not_inc
  inc  pos_cursor+1
@not_inc:
  sta  pos_cursor

  inx
  cpx  #10
  bne  @L1

flush:


  ldx   posy
  lda   SDL_HiresTableLow,x
  sta   pos_cursor

  lda   SDL_HiresTableHigh,x
  sta   pos_cursor+1




  ldy   posx
  lda   posx_6,y
  tay
  lda  cursorToDisplayLow,y
  sta   cursor
  lda  cursorToDisplayHigh,y
  sta   cursor+1

  ;lda   #<mouse_cursor_0
  ;sta   cursor
  ;lda   #>mouse_cursor_0
  ;sta   cursor+1

  ldy  posx
  lda  posx_byte,y
  sta  posx_byte_cur

  lda   #$00
  sta   cursor_read_sprite

  ldx   #$00
@L2:
  ;ldy   posx
@L1:
  ldy   cursor_read_sprite
  lda   (cursor),y
  
  ldy   posx_byte_cur
  ora   (pos_cursor),y
  sta   (pos_cursor),y
  
  inc   cursor_read_sprite


  inx

  ldy   cursor_read_sprite
  lda   (cursor),y

  inc   cursor_read_sprite
  
  ldy   posx_byte_cur
  iny
  ora   (pos_cursor),y
  sta   (pos_cursor),y

  lda  pos_cursor
  clc
  adc  #$28
  bcc  @not_inc
  inc  pos_cursor+1
@not_inc:
  sta  pos_cursor

  inx
  cpx  #20
  bne  @L2


  lda  posx
  sta  posx_old 

  lda  posy
  sta  posy_old 

  rts


odd:
.byte %01010101
.byte %01101010

.byte %01010101
.byte %01101010

.byte %01010101
.byte %01101010

.byte %01010101
.byte %01101010

.byte %01010101
.byte %01101010

cursorToDisplayLow:
.byte <mouse_cursor_0
.byte <mouse_cursor_1
.byte <mouse_cursor_2
.byte <mouse_cursor_3
.byte <mouse_cursor_4
.byte <mouse_cursor_5

cursorToDisplayHigh:
.byte >mouse_cursor_0
.byte >mouse_cursor_1
.byte >mouse_cursor_2
.byte >mouse_cursor_3
.byte >mouse_cursor_4
.byte >mouse_cursor_5

posx_byte:
.byte 0,0,0,0,0,0
.byte 1,1,1,1,1,1
.byte 2,2,2,2,2,2
.byte 3,3,3,3,3,3
.byte 4,4,4,4,4,4
.byte 5,5,5,5,5,5
.byte 6,6,6,6,6,6
.byte 7,7,7,7,7,7
.byte 8,8,8,8,8,8
.byte 9,9,9,9,9,9
.byte 10,10,10,10,10,10
.byte 11,11,11,11,11,11
.byte 12,12,12,12,12,12
.byte 13,13,13,13,13,13
.byte 14,14,14,14,14,14
.byte 15,15,15,15,15,15
.byte 16,16,16,16,16,16
.byte 17,17,17,17,17,17
.byte 18,18,18,18,18,18
.byte 19,19,19,19,19,19
.byte 20,20,20,20,20,20
.byte 21,21,21,21,21,21
.byte 22,22,22,22,22,22
.byte 23,23,23,23,23,23
.byte 24,24,24,24,24,24
.byte 25,25,25,25,25,25
.byte 26,26,26,26,26,26
.byte 27,27,27,27,27,27
.byte 28,28,28,28,28,28
.byte 29,29,29,29,29,29
.byte 30,30,30,30,30,30
.byte 31,31,31,31,31,31
.byte 32,32,32,32,32,32
.byte 33,33,33,33,33,33
.byte 34,34,34,34,34,34
.byte 35,35,35,35,35,35
.byte 36,36,36,36,36,36
.byte 37,37,37,37,37,37
.byte 38,38,38,38,38,38
.byte 39,39,39,39,39,39

posx_6:
  .byte 0,1,2,3,4,5
  .byte 0,1,2,3,4,5

  .byte 0,1,2,3,4,5
  .byte 0,1,2,3,4,5

  .byte 0,1,2,3,4,5
  .byte 0,1,2,3,4,5

  .byte 0,1,2,3,4,5
  .byte 0,1,2,3,4,5

  .byte 0,1,2,3,4,5
  .byte 0,1,2,3,4,5

  .byte 0,1,2,3,4,5
  .byte 0,1,2,3,4,5

  .byte 0,1,2,3,4,5
  .byte 0,1,2,3,4,5

  .byte 0,1,2,3,4,5
  .byte 0,1,2,3,4,5

  .byte 0,1,2,3,4,5
  .byte 0,1,2,3,4,5

  .byte 0,1,2,3,4,5
  .byte 0,1,2,3,4,5

  .byte 0,1,2,3,4,5
  .byte 0,1,2,3,4,5  

  .byte 0,1,2,3,4,5
  .byte 0,1,2,3,4,5  

  .byte 0,1,2,3,4,5
  .byte 0,1,2,3,4,5  

  .byte 0,1,2,3,4,5
  .byte 0,1,2,3,4,5  

mouse_cursor_0:
.byte  %01100000,%00000000 ; 0
.byte  %01110000,%00000000 ; 1
.byte  %01111000,%00000000 ; 2
.byte  %01111100,%00000000 ; 3
.byte  %01111110,%00000000 ; 4
.byte  %01111111,%00000000 ; 5
.byte  %01111100,%00000000 ; 
.byte  %01011100,%00000000 
.byte  %01000110,%00000000
.byte  %01000110,%00000000

mouse_cursor_1:
.byte  %01010000,%00000000 ; 0
.byte  %01011000,%00000000 ; 1
.byte  %01011100,%00000000 ; 2
.byte  %01011110,%00000000 ; 3
.byte  %01011111,%00000000 ; 4
.byte  %01011111,%01100000 ; 5
.byte  %01011110,%00000000 ; 
.byte  %01001110,%00000000 
.byte  %01000011,%00000000
.byte  %01000011,%00000000


mouse_cursor_2:
.byte  %01001000,%00000000 ; 0
.byte  %01001100,%00000000 ; 1
.byte  %01001110,%00000000 ; 2
.byte  %01001111,%00000000 ; 3
.byte  %01001111,%01100000 ; 4
.byte  %01001111,%01110000 ; 5
.byte  %01001111,%00000000 ; 
.byte  %01000111,%00000000 
.byte  %01000001,%01100000
.byte  %01000001,%01100000


mouse_cursor_3:
.byte  %01000100,%00000000 ; 0
.byte  %01000110,%00000000 ; 1
.byte  %01000111,%00000000 ; 2
.byte  %01000111,%01100000 ; 3
.byte  %01000111,%01110000 ; 4
.byte  %01000111,%01111000 ; 5
.byte  %01000111,%01100000 ; 
.byte  %01000011,%01100000 
.byte  %01000000,%01110000
.byte  %01000000,%01110000


mouse_cursor_4:
.byte  %01000010,%00000000 ; 0
.byte  %01000011,%00000000 ; 1
.byte  %01000011,%01100000 ; 2
.byte  %01000011,%01110000 ; 3
.byte  %01000011,%01111000 ; 4
.byte  %01000011,%01111100 ; 5
.byte  %01000011,%01110000 ; 
.byte  %01000001,%01110000 
.byte  %01000000,%01011000
.byte  %01000000,%01011000

mouse_cursor_5:
.byte  %01000001,%00000000 ; 0
.byte  %01000001,%011000000 ; 1
.byte  %01000001,%01110000 ; 2
.byte  %01000001,%01111000 ; 3
.byte  %01000001,%01111100 ; 4
.byte  %01000001,%01111110 ; 5
.byte  %01000001,%01111000 ; 
.byte  %01000000,%01111000 
.byte  %01000000,%01001100
.byte  %01000000,%01001100


 .endproc


.proc _SDL_GetMouseState
    ;sta ptr1
    ;stx ptr1+1
    ;jsr popax
    ;sta ptr2
    ;stx ptr2+1

;100 OUT CMD,&15:OUT DAT,&7 :' Initialize device in usb HOST mode, reset USB bus
;110 OUT CMD,&15:OUT DAT,&6 :' Initialize device in usb HOST mode, produce SOF
;120 OUT CMD,&B:OUT DAT,&17:OUT DAT,&D8 :' Set USB device speed?
;130 OUT CMD,&45:OUT DAT,&1:v =INP(dat) :' Set device address
;140 GOSUB 510

    lda #$15
    sta CH376_COMMAND

    lda #$07
    sta CH376_DATA

    lda #$15
    sta CH376_COMMAND
    
    lda #$06
    sta CH376_DATA

    lda #$0B
    sta CH376_COMMAND
    
    lda #$17
    sta CH376_DATA
    
    lda #$D8
    sta CH376_DATA


    lda #$45
    sta CH376_COMMAND
    
    lda #$01
    sta CH376_DATA
    
    lda CH376_DATA
    jsr wait_response





;150 OUT CMD,&13:OUT DAT,&1 :' Set CH376 address
;160 :' We can now select configuration 1. In a mouse, this is (usually?) the only available configuration.
;170 OUT CMD,&49:OUT DAT,&1 :' Select configuration 1
;180 GOSUB 510
   rts
   
wait_response:
@L1:
   lda CH376_COMMAND
   and #%10000000
   cmp #128
   bne @L1

@out:
    lda #$22
    sta CH376_COMMAND
    lda CH376_DATA
    ; status
    rts
;500 :' Wait for command to complete and read error code
;510 LOCATE 1,24:sta = INP(CMD):PRINT"Status: &";HEX$(sta,2);:IF sta > 127 THEN GOTO 510
;520 :' GET_STATUS
;530 OUT CMD,&22
;540 STATUS=INP(DAT):LOCATE 1,1:PRINT"Interrupt status (&14,&1D=OK) = ";HEX$(STATUS,2);
;550 RETURN

.endproc
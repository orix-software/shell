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



  BRK_KERNEL XHIRES
  MALLOC .sizeof(xorix_struct)
  sta XORIX_STRUCT_ptr
  sty XORIX_STRUCT_ptr+1
  ; init pos
  ldy #$00
  lda #$00
  sta (XORIX_STRUCT_ptr),y
  iny
  sta (XORIX_STRUCT_ptr),y
 
  lda #$17
  sta $A000   ; empty
  
  sta $A000+40
  sta $A000+80  
  sta $A000+120
  sta $A000+160

  sta $A000+200
  sta $A000+240
  sta $A000+280  
  sta $A000+320

  sta $A000+360 ; empty

  jsr _blit_menu
  jsr _blit_background

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


 .endproc

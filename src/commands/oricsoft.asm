.export _oricsoft

.struct  oricsft_struct
  current_letter       .byte   
  path                 .res 80   
.endstruct

;macros/strnxxx.mac

oricsoft_tmp1:= userzp

oricsoft_struct_ptr:= userzp+1 ;

oricsoft_ptr1:= userzp+3 ;
oricsoft_ptr2:= userzp+5 ;

.proc _oricsoft
     BRK_KERNEL XHIRES

     MALLOC .sizeof(oricsft_struct)
     sta oricsoft_struct_ptr
     sty oricsoft_struct_ptr+1

    ; FUXME nuyll

     lda #'A'
     sta oricsoft_tmp1

@L1:
     BRK_KERNEL XWR0
     ldx oricsoft_tmp1
     cpx #'Z'
     beq @S1
     inx
     stx oricsoft_tmp1
     lda oricsoft_tmp1
     bne @L1
@S1:
     ; Loading title

     ldy  #oricsft_struct::path
     lda  oricsoft_struct_ptr+1
     ;oricsoft_ptr1       



     jsr  init_joystick_left
     jsr  get_joystick_value
     tax
	cmp #%00000100
	beq @fire


     rts
@exit:
     lda oricsoft_struct_ptr
     ldy oricsoft_struct_ptr+1
     BRK_KERNEL XFREE
     rts     
@fire:
     rts
.endproc

.proc init_joystick_left
    lda #%10011111
    sta VIA2::DDRB
    rts
.endproc

.proc init_joystick_right
    lda #%010011111
    sta VIA2::DDRB
    rts
.endproc

.proc get_joystick_value
     lda VIA2::PRB
	and #%00011111
     rts
.endproc
oricsftpathroot:
  .asciiz "/usr/share/oricsft/"
oricsftpathhrs:
  .asciiz "hrs/"  


; joysticks
; PB
; b0 droit
; b1 gauche
; b2 feu
; b3 bas
;  haut
; PB7 : port gauche
; pb6 port droit.



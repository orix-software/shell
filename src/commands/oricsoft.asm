.export _oricsoft

.proc oricsoft
     jsr  init_joystick_left
     jsr  get_joystick_value
     tax
	 cmp #%00000100
	 beq @fire


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

; joysticks
; PB
; b0 droit
; b1 gauche
; b2 feu
; b3 bas
;  haut
; PB7 : port gauche
; pb6 port droit.




.export _banks

.proc _banks
    current_bank := ID_BANK_TO_READ_FOR_READ_BYTE    ; 1 bytes
    
    
    ptr1         := OFFSET_TO_READ_BYTE_INTO_BANK   ; 2 bytes
    tmp2         := userzp+2    ; 1 bytes
    bank_save_banking_register := userzp+3	
    bank_address_driver := userzp+5
    bank_decimal_current_bank := userzp+7
    ptr2         := userzp+10    ; 2 bytes

    jmp     _banks2

    ldx     #$01
    jsr     _orix_get_opt           ; get arg 
    
    bcc     displays_all_banks      ; if there is no args, let's displays all banks
    lda     ORIX_ARGV
    sec
    sbc     #$30
    tax
    stx     VAPLIC
    sta     current_bank
    sei
    lda     #<$FFFC
    sta     ptr1
    lda     #>$FFFC
    sta     ptr1+1
    ldy     #$00
    ldx     #$00 ; Read mode
    jsr     READ_BYTE_FROM_OVERLAY_RAM ; get low
    sta     tmp2
    sta     $6000

    lda     #<$FFFD
    sta     ptr1
    lda     #>$FFFD
    sta     ptr1+1
    ldy     #$00
    ldx     #$00 ; Read mode

    jsr     READ_BYTE_FROM_OVERLAY_RAM ; get low
     
    sta     $6001
      
    tay 
    cli
    ; NMI
    lda     tmp2

    sta     VAPLIC+1
    sty     VAPLIC+2
    sta     VEXBNK+1 ; BNK_ADDRESS_TO_JUMP_LOW
    sty     VEXBNK+2 ; BNK_ADDRESS_TO_JUMP_HIGH
    ldx     VAPLIC
    stx     BNKCIB

    ldx     #XVARS_KERNEL_CH376_MOUNT
    BRK_KERNEL XVARS
    sta     ptr2
    sty     ptr2+1
    ldy     #$00
    lda     (ptr2),y
    sta     STORE_CURRENT_DEVICE



    jmp     EXBNK
	
; displays all bank	
displays_all_banks:   
	; install driver
    lda     #$FF
    ldy     #$00
    BRK_KERNEL XMALLOC

    sta     bank_address_driver
    sty     bank_address_driver+1
    
	sta     VEXBNK+1 
	sty     VEXBNK+2

    ldx     #$00
    ldy     #$00
@L1:
    lda     bank_address_driver_code,x
    sta     (bank_address_driver),y
    iny
    inx
    bne     @L1

    lda     #32
    sta     bank_decimal_current_bank

restart:
	;jsr		VEXBNK
    ;rts
    ; Telestrat and Twilighte board V0_3
    lda     #%00000111                ; we start from the bank 7 to 1

    sta     current_bank
loop2:
    lda     current_bank              ; Load current bank
    clc 
    adc     #44+4                     ; displays the number of the bank
    BRK_ORIX XWR0
    CPUTC ':'                         ; Displays a space
    sei
    lda     #<$FFF8
    sta     ptr1
    lda     #>$FFF8
    sta     ptr1+1
    ldy     #$00
    ldx     #$00 ; Read mode
    jsr     READ_BYTE_FROM_OVERLAY_RAM ; get low
    sta     RES
    iny
    ldx     #$00 ; Read mode 
    jsr     READ_BYTE_FROM_OVERLAY_RAM ; get high
    sta     RES+1
   
    lda     RES
    sta     ptr1
    lda     RES+1
    sta     ptr1+1

.IFPC02
.pc02
    stz     ptr2	
.p02    
.else
    lda     #$00
    sta     ptr2
.endif

@loopme:
    ldy     ptr2
    ldx     #$00 ; Read mode
    jsr     READ_BYTE_FROM_OVERLAY_RAM
    beq     exit
    cli
    cmp     #' '                        ; 'a'
    bcs     @skip
    lda     #' '
@skip:    
    BRK_ORIX XWR0
    iny
    cpy     #37    ; Exit if signature is longer than 37 bytes
    beq     exit
    sty     ptr2
    sei
    jmp     @loopme
exit:

    cli
    RETURN_LINE
    dec     current_bank
    bne     loop2

    rts

bank_address_driver_code:

  sei
;.ifdef    TWILIGHTEBOARD_BANK_LINEAR
    lda     #$00
    sta     $343
;.endif



    lda     #%00000111                ; we start from the bank 7 to 1

    sta     current_bank
@loop2:
    lda     bank_decimal_current_bank
    ldy     #$00
    ldx     #$20 ;
    stx     DEFAFF
    ldx     #$00
    BRK_KERNEL XDECIM
    



    CPUTC ':'                         ; Displays a space
    sei
    lda     VIA2::PRA
    and     #%11111000                     
    ora     current_bank                           ; but select a bank in $410
    sta     VIA2::PRA    
    lda     #<$FFF8
    sta     ptr1
    lda     #>$FFF8
    sta     ptr1+1
    ldy     #$00
    lda     (ptr1),y
    sta     RES
    iny
    lda     (ptr1),y
    sta     RES+1
   
    lda     RES
    sta     ptr1
  
    lda     RES+1
    sta     ptr1+1


    lda     #$00
    sta     ptr2


@loopme:
    ldy     ptr2
    ldx     #$00 ; Read mode
    lda     (ptr1),y
    ;jsr     READ_BYTE_FROM_OVERLAY_RAM
    beq     exit
    cli
    cmp     #' '                        ; 'a'
    bcs     @skip
    lda     #' '
@skip:    
    BRK_KERNEL XWR0
    iny
    cpy     #37    ; Exit if signature is longer than 37 bytes
    beq     @exit
    sty     ptr2
    sei
    jmp     @loopme
@exit:
    lda     VIA2::PRA
    and     #%11111111                     
    sta     VIA2::PRA
  ;ora     current_bank                           ; but select a bank in $410
    cli
    RETURN_LINE
    dec     current_bank
    bpl     @out
    dec     bank_decimal_current_bank
    bne     @loop2
@out:
    



;.ifdef    TWILIGHTEBOARD_BANK_LINEAR
  lda     #$00
  sta     $343
;.endif
  cli 
  rts

.endproc 

.proc _banks2
    current_bank := ID_BANK_TO_READ_FOR_READ_BYTE    ; 1 bytes
    
    
    ptr1         := OFFSET_TO_READ_BYTE_INTO_BANK   ; 2 bytes : Used when we type "bank ID"
    tmp2         := userzp                          ; 1 bytes
    bank_save_banking_register := userzp+1	        ; one byte
    save_twilighte_register    := userzp+2          ; 1 bytes
    save_twilighte_banking_register    := userzp+3  ; 1 bytes
    bank_decimal_current_bank := userzp+4 ; One byte
    ptr2         := userzp+5                        ; 2 bytes : Used when we type "bank ID"
    ptr3         := userzp+7                        ; 2 bytes
    bank_stop_listing :=userzp+9                    ; 
    
    
    bank_save_argvlow :=userzp+11
    bank_save_argvhigh:=userzp+12
    bank_all_banks_display :=userzp+13              ; use when bank has no option
    bank_save_argc :=userzp+14
    first_char_id_bank := userzp+15

    

    XMAINARGS = $2C
    XGETARGV =  $2E

   ; ldx     #$00
   ; stx     bank_save_argc ; Recycle var

    lda         #$01
    sta         bank_all_banks_display

    BRK_KERNEL XMAINARGS

    
    sta     bank_save_argvlow
    sty     bank_save_argvhigh
    stx     bank_save_argc

    cpx     #$01
    beq     @jmp_displays_all_banks


    ldx     #$01
    lda     bank_save_argvlow
    ldy     bank_save_argvhigh

    BRK_KERNEL XGETARGV

    sta     ptr3
    sty     ptr3+1

    ldy     #$00
    lda     (ptr3),y
    cmp     #'-' ; is an option ?
    bne     @not_an_option
   
    iny
    lda     (ptr3),y
    cmp     #'a'  ; displays all banks option ?
    bne     @unknown_option
    dec     bank_all_banks_display
@jmp_displays_all_banks:
    jmp     displays_all_banks

@unknown_option:
    ;PRINT usage
    rts
@not_an_option:

    sec
    sbc     #$30
    sta     first_char_id_bank
    ; Do we have another char 
    iny
    lda     (ptr3),y ; FIXME
    beq     @only_one_digit
    ; convert to decimal 


    sec 
    sbc     #$30
    sta     bank_save_argc
    ldx     first_char_id_bank ; 2 chars, get the first digit
    ;dex
    lda     #$00
@compute_again:

    clc
    adc     #10
    dex
    bne     @compute_again
    clc
    adc     bank_save_argc
    sta     bank_save_argc  
    ; is it greater than 32 ?
    cmp     #32
    bcc     @do_not_switch_to_ram_bank
    pha
    lda     $342
    ora     #%00100000
    sta     $342
    pla
@do_not_switch_to_ram_bank:    
    ;jmp     @do_not_switch_to_ram_bank
    jsr     _twil_get_registers_from_id_bank   
    ; A bank
    ;jmp @not_an_option
    sta     first_char_id_bank
    stx     $343   
    


@only_one_digit: 

    
    lda     first_char_id_bank
    sta     VAPLIC
    sta     current_bank
    sei
    lda     #<$FFFC
    sta     ptr1
    lda     #>$FFFC
    sta     ptr1+1
    ldy     #$00
    ldx     #$00 ; Read mode
    jsr     READ_BYTE_FROM_OVERLAY_RAM ; get low
    sta     tmp2


    lda     #<$FFFD
    sta     ptr1
    lda     #>$FFFD
    sta     ptr1+1
    ldy     #$00
    ldx     #$00 ; Read mode

    jsr     READ_BYTE_FROM_OVERLAY_RAM ; get low
      
    tay 
    cli
    ; NMI
    lda     tmp2

    sta     VAPLIC+1
    sty     VAPLIC+2
    sta     VEXBNK+1 ; BNK_ADDRESS_TO_JUMP_LOW
    sty     VEXBNK+2 ; BNK_ADDRESS_TO_JUMP_HIGH
    ldx     VAPLIC
    stx     BNKCIB

    ldx     #XVARS_KERNEL_CH376_MOUNT
    BRK_KERNEL XVARS
    sta     ptr2
    sty     ptr2+1
    ldy     #$00
    lda     (ptr2),y
    sta     STORE_CURRENT_DEVICE

    jmp     EXBNK
	
; displays all bank	
displays_all_banks:   
    lda     #$00
    sta     bank_stop_listing
	
    lda     #64
    sta     bank_decimal_current_bank

    lda     $343
    sta     save_twilighte_banking_register
    
    ; switch to ram
    lda     $342
    sta     save_twilighte_register
    ora     #%00100000
    sta     $342

    jsr     displays_banking

    lda     $342
    and     #%11011111
    sta     $342

    jsr     displays_banking


    sei
    lda     save_twilighte_register
    sta     $342

    lda     save_twilighte_banking_register
    sta     $343
    cli

    rts

displays_banking:


    lda     #$07
    sta     $343

parse_next_banking_set:


@skip:
    lda     #%00000100                ; we start from the bank 7 to 1
@store:
    sta     current_bank
loop2:
    jsr     check_if_bank_7_6_5
    lda     bank_all_banks_display
      
    beq     @display_all

    jsr     get_rom_type
    cmp     #$00   ; Empty ?
    beq     @next_bank
@display_all:

    jsr     display_bank_id

    jmp     @check_kernel_ram_overlay


@not_ram_overlay_kernel:
    sei
    jsr     upd_ptr

    lda     ptr1+1
    cmp     #$C0   ; Does signature is in rom ?
    bcc     @exit

.IFPC02
.pc02
    stz     ptr2	
.p02    
.else
    lda     #$00
    sta     ptr2
.endif

@loopme:
    ldy     ptr2
    ldx     #$00                        ; Read mode
    jsr     READ_BYTE_FROM_OVERLAY_RAM
    beq     @exit
    cli
    cmp     #' '                        ; 'a'
    bcc     @none_char
    cmp     #$7F                        ; '7f'
    bcs     @none_char
@skip:  
  ;  jmp     @skip
    BRK_ORIX XWR0

@none_char:

@wait_key:    
    BRK_KERNEL XRD0
    bcs     @check_ctrl
    cmp     #' '
    bne     @check_ctrl

    lda     bank_stop_listing
    beq     @S10
    dec     bank_stop_listing
    jmp     @check_ctrl
@S10:
    inc     bank_stop_listing
    jmp     @wait_key
    ; space here 
    
@check_ctrl:
    lda     bank_stop_listing
    bne     @wait_key
    asl     KBDCTC
    bcc     @no_ctrl    
    rts
@no_ctrl:    
    iny
    cpy     #36    ; Exit if signature is longer than 37 bytes
    beq     @exit
    sty     ptr2

    sei
    jmp     @loopme
@exit:

    cli
    RETURN_LINE

@next_bank:    
    dec     bank_decimal_current_bank
    beq     @end_of_bank    
    dec     current_bank
    bne     loop2
    lda     bank_decimal_current_bank
    cmp     #16
    bne     @skip12
    lda     #03
    sta     $343
 
@skip12:
    dec     $343
    bpl     parse_next_banking_set
@end_of_bank:

    rts

@check_kernel_ram_overlay:
    lda     bank_decimal_current_bank
    cmp     #52
    bne     @not_ram_overlay_kernel
    PRINT   str_kernel_reserved
    jmp     @next_bank


check_if_bank_7_6_5:
    lda     bank_decimal_current_bank

    cmp     #$08
    bne     @check_bank4
@set4:
    lda     #$04
    sta     $343
    rts
@check_bank4:
    cmp     #$04
    bne     @others
@set0:    
    lda     #$00
    sta     $343
    rts
@others:
    cmp     #20
    bne     @exit
@set3:
    lda     #$03
    sta     $343
    rts
@exit:
    ;cmp     #61
    ;beq     @set4    
    

    rts

display_bank_id:
    lda     bank_decimal_current_bank              ; Load current bank
    cmp     #10
    bcs     greater_than_10
    pha
    lda     #'0'
    BRK_ORIX XWR0
    pla
    clc 
    adc     #44+4                     ; Displays the number of the bank

    BRK_ORIX XWR0
    CPUTC ':'                         ; Displays a space
    rts
greater_than_10:
    cmp     #20
    bcs     greater_than_20
    pha
    lda      #'1'
    BRK_ORIX XWR0
    pla
    clc
    adc     #38
    BRK_ORIX XWR0
    CPUTC ':'      
    rts    
greater_than_20:  
    cmp     #30
    bcs     greater_than_30
    pha
    lda      #'2'
    BRK_ORIX XWR0
    pla
    clc
    adc     #28
    BRK_ORIX XWR0
    CPUTC ':'      
    rts    
greater_than_30:
    cmp     #40
    bcs     greater_than_40
    pha
    lda     #'3'
    BRK_ORIX XWR0
    pla
    clc
    adc     #18
    BRK_ORIX XWR0
    CPUTC ':'      
    rts
greater_than_40:
    cmp     #50
    bcs     greater_than_50
    pha
    lda     #'4'
    BRK_ORIX XWR0
    pla
    clc
    adc     #8
    BRK_ORIX XWR0
    CPUTC ':'      
    rts    
greater_than_50:
    cmp     #60
    bcs     greater_than_60
    pha
    lda     #'5'
    BRK_ORIX XWR0
    pla
    sec
    sbc     #2

    BRK_ORIX XWR0
    CPUTC ':'      
    rts    
greater_than_60:

    pha
    lda     #'6'
    BRK_ORIX XWR0
    pla
    ;cld
    sec
    sbc     #12
    ;sed
    BRK_ORIX XWR0
    CPUTC ':'      
    rts
        
upd_ptr:
    lda     #<$FFF8
    sta     ptr1
    lda     #>$FFF8
    sta     ptr1+1
    ldy     #$00
    ldx     #$00 ; Read mode
    jsr     READ_BYTE_FROM_OVERLAY_RAM ; get low
    sta     RES
    iny
    ldx     #$00 ; Read mode 
    jsr     READ_BYTE_FROM_OVERLAY_RAM ; get high
    sta     RES+1
   
    lda     RES
    sta     ptr1
    lda     RES+1
    sta     ptr1+1
    rts

get_rom_type:
    lda     #<$FFF0
    sta     ptr1
    lda     #>$FFF0
    sta     ptr1+1
    ldy     #$00
    ldx     #$00 ; Read mode
    jsr     READ_BYTE_FROM_OVERLAY_RAM ; get low
    rts

usage:
    .byte "bank [-a]",$0D,$0A
    .asciiz "bank IDBANK"

str_kernel_reserved:
    .byte "Kernel reserved",$0D,$0A,$00
.endproc 


;unsigned char twil_get_registers_from_id_bank(unsigned char bank);
.proc _twil_get_registers_from_id_bank
    cmp     #$00
    beq     @bank0
    tay
    lda     set,y
    tax
    lda     bank,y
    rts
@bank0:
    ; Impossible to have bank 0
    tax    
    rts
set:
    .byte 0,0,0,0,1,1,1,1
    .byte 1,1,1,1,1,1,1,1
    .byte 1,1,1,1,1,1,1,1
    .byte 1,1,1,1,1,1,1,1

    .byte 0,0,0,0,0,1,1,1
    .byte 1,2,2,2,2,3,3,3
    .byte 3,4,4,4,4,5,5,5
    .byte 5,6,6,6,6,7,7,7,7    

bank:
    .byte 1,2,3,4,1,1,1,1
    .byte 3,1,1,1,1,1,1,1
    .byte 3,1,1,1,1,1,1,1
    .byte 3,1,1,1,1,1,1,1

    .byte 0,1,2,3,4,1,2,3
    .byte 4,1,2,3,4,1,2,3
    .byte 4,1,2,3,4,1,2,3
    .byte 4,1,2,3,4,1,2,3
    .byte 4

.endproc
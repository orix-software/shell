

.export _twil

    twil_current_bank      := ID_BANK_TO_READ_FOR_READ_BYTE    ; 1 bytes
    twil_ptr2              := OFFSET_TO_READ_BYTE_INTO_BANK   ; 2 bytes
    twil_ptr1:= userzp ;
    twil_mainargs_argv     := userzp+2
    twil_mainargs_argc     := userzp+4 ; 8 bits
    twil_mainargs_arg1_ptr := userzp+5 ; 16 bits

.proc _twil
    ; FIXME macro

    initmainargs  twil_mainargs_argv, twil_mainargs_argc, 0
    cpx     #$01
    beq     usage      ; if there is no args, let's displays all banks

    getmainarg #1, (twil_mainargs_argv)
    sta     twil_mainargs_arg1_ptr
    sty     twil_mainargs_arg1_ptr+1

    ldy     #$00
    lda     (twil_mainargs_arg1_ptr),y
    cmp     #'-'
    bne     usage
    iny
    lda     (twil_mainargs_arg1_ptr),y
    cmp     #'f'
    bne     check_next_parameter_u
    print   str_version

    lda     TWILIGHTE_REGISTER       ; get Twilighte register
    and     #%00001111 ; Select last 4 bits
    cmp     #15        ; Max version #15
    bcs     error
    clc
    adc     #48
    BRK_KERNEL XWR0
    crlf
    rts

error:
    print   str_unknown
    crlf
    rts

usage:
    print   str_usage
    crlf
    rts

error_overflowbanking:
    print   str_usage
    crlf
    rts

check_next_parameter_u:
    cmp     #'u'       ; Swap
    bne     check_next_parameter_d

    ldx   #XVARS_KERNEL_CH376_MOUNT
    BRK_KERNEL XVARS

    sta     twil_ptr1
    sty     twil_ptr1+1
    lda     #CH376_SET_USB_MODE_CODE_USB_HOST_SOF_PACKAGE_AUTOMATICALLY
    ldy     #$00
    sta     (twil_ptr1),y
    jsr     savemount
    print str_swap_root_to_usbkey
    crlf
    rts

check_next_parameter_d:
    cmp     #'d'       ; Swap
    bne     usage

    ldx     #XVARS_KERNEL_CH376_MOUNT
    BRK_KERNEL XVARS

    sta     twil_ptr1
    sty     twil_ptr1+1
    lda     #CH376_SET_USB_MODE_CODE_SDCARD
    ldy     #$00
    sta     (twil_ptr1),y
    ; and save
    jsr     savemount
    print str_swap_root_to_sdcard
    crlf
    rts
savemount:
    sta     RES
    ldx     #XVARS_KERNEL_CH376_MOUNT
    BRK_KERNEL XVARS
    sta     twil_ptr2
    sty     twil_ptr2+1
    lda     #$00
    sta     twil_current_bank
    ldy     #$00
    ldx     #$01
    jsr     READ_BYTE_FROM_OVERLAY_RAM
    rts

str_version:
  	.asciiz "Version : "

str_unknown:
	.asciiz "Unknown version"

str_swap_root_to_usbkey:
    .asciiz "Swap / to /dev/usb1"

str_swap_root_to_sdcard:
    .asciiz "Swap / to /dev/sda1"

str_swap_to_bank_sram:
    .asciiz "Swapped to RAM banking"

str_swap_to_bank_rom:
    .asciiz "Swapped to EEPROM banking"

str_overflow_banking:
	.asciiz "This version of board can only manage 4 sets"

str_usage:
	.byte "Usage: twil -f",$0A,$0D
    .byte "       twil -u",$0A,$0D
    .byte "       twil -d",$0A,$0D
    .byte $00
.endproc

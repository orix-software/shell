.proc _ch376_verify_SetUsbPort_Mount
	jsr 	_ch376_check_exist
	cmp 	#CH376_DETECTED
	beq 	detected
	BRK_TELEMON XCRLF
	lda 	#<str_usbdrive_controller_not_found
	ldy 	#>str_usbdrive_controller_not_found
	BRK_TELEMON	XWSTR0
	; let's start reset
	jsr 	_ch376_reset_all
	lda 	#$01 ; error
	rts	
detected:
	jsr 	_ch376_set_usb_mode
	jsr 	_ch376_disk_mount
	cmp 	#CH376_USB_INT_SUCCESS
	beq 	ok
	clc
	lda 	#$01
ok:
	sec 	; Carry = 1
	lda	 	#$00
	rts

str_drive_error
	.asciiz "Impossible to mount key"

.endproc


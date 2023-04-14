.export _mount

;mount -t vfat /dev/sdc1 /

.proc _mount
    mount_ptr1          := userzp ; 16 bits
    mount_mainargs_ptr  := userzp+2

    mount_mainargs_argv := userzp+4
    mount_mainargs_argc := userzp+6 ; 8 bits

    lda     #$00 ; return args with cut
    BRK_KERNEL XMAINARGS
    sta     mount_mainargs_ptr
    sty     mount_mainargs_ptr+1
    stx     mount_mainargs_argc

    ; mount /dev/sda1 /
    ldx   #XVARS_KERNEL_CH376_MOUNT
    BRK_KERNEL XVARS

    sta     mount_ptr1
    sty     mount_ptr1+1

    ldx     mount_mainargs_argc
    cpx     #$01
    beq     mount_no_param      ; if there is no args, let's displays all banks

    ldx     #$01
    lda     mount_mainargs_ptr
    ldy     mount_mainargs_ptr+1

    BRK_KERNEL XGETARGV
    sta     mount_mainargs_argv
    sty     mount_mainargs_argv+1

    ldy     #$00
@L1:
    lda     (mount_mainargs_argv),y
    beq     @out
    cmp     str_sda1,y
    bne     check_sdb1
    iny
    cpy     #9
    bne     @L1
@out:
    cpy     #$09
    bne     check_sdb1

check_sdb1:

    ldy     #$00
@L2:
    lda     (mount_mainargs_argv),y
    beq     @out2
    cmp     str_sdb1,y
    bne     error
    iny
    cpy     #9
    bne     @L2
@out2:
    cpy     #$09
    bne     error
    rts


mount_no_param:

    print str_mount
    ldy     #$00
    lda     (mount_ptr1),y
	cmp     #CH376_SET_USB_MODE_CODE_SDCARD
    bne     usb_key
    print str_sdcard
    rts
usb_key:
    print str_usbkey
	rts
error:
    print str_error
    rts
str_error:
    .byt "error",$0A,$0D,0
str_mount:
    .byte "rootfs on / type FAT32 ",0
str_sdcard:
    .byt "/dev/sda1 (sdcard)",$0A,$0D,0
str_usbkey:
    .byt "/dev/usb1",$0A,$0D,0
str_sda1:
    .asciiz "/dev/sda1"
str_sdb1:
    .asciiz "/dev/sdb1"
.endproc

.export _mount

;mount -t vfat /dev/sdc1 /
mount_ptr1:= userzp ;

.proc _mount
    ; mount /dev/sda1 /
    ldx   #XVARS_KERNEL_CH376_MOUNT
    BRK_KERNEL XVARS

    sta   mount_ptr1
    sty   mount_ptr1+1
   ; sta $5000
    ;sty $5001

    ldx     #$01
    jsr     _orix_get_opt           ; get arg 
    bcc     mount_no_param      ; if there is no args, let's displays all banks
    ldx     #$00
@L1:
    lda     ORIX_ARGV,x
    beq     @out
    cmp     str_sda1,x
    bne     check_sdb1
    inx    
    cpx     #9
    bne     @L1
@out:
    cpx    #$09
    bne    check_sdb1

check_sdb1:

    ldx     #$00
@L2:
    lda     ORIX_ARGV,x
    beq     @out2
    cmp     str_sdb1,x
    bne     error
    inx    
    cpx     #9
    bne     @L2
@out2:
    cpx    #$09
    bne    error
    rts


mount_no_param:

    PRINT str_mount
    ldy   #$00
    lda   (mount_ptr1),y
	cmp   #CH376_SET_USB_MODE_CODE_SDCARD
    bne   usb_key
    PRINT str_sdcard
    rts
usb_key:
    PRINT str_usbkey
	rts
error:
    PRINT str_error
    rts
str_error:
.byt "error",$0A,$0D,0
str_mount:
    .byte "rootfs on / type FAT32 ",0
str_sdcard:
.byt "/dev/sda1 (sdcard)",$0A,$0D,0
str_usbkey:
.byt "/dev/sdb1 (USB key)",$0A,$0D,0
str_sda1:
.asciiz "/dev/sda1"
str_sdb1:
.asciiz "/dev/sdb1"
.endproc


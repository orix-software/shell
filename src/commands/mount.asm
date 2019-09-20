.export _mount

.proc _mount
    ; mount /dev/sda1 /
    PRINT str_mount
	rts
str_mount:
    .byte "rootfs on / type FAT32 (USB key)",$0A,$0D,0
.endproc


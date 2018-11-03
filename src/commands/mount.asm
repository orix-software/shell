.proc _mount

  PRINT str_mount
	rts
str_mount:
    .byte "rootfs on / type FAT32 (USB key)",$0A,$0D,0
.endproc


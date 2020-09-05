

CH376_DETECTED        := $AA

CH376_CMD_NONE        = $00
CH376_GET_IC_VER 	  = $01
CH376_SET_BAUDRATE    = $02
CH376_GET_ENTER_SLEEP = $03
CH376_RESET_ALL       = $05
CH376_CHECK_EXIST     = $06
CH376_GET_FILE_SIZE   = $0C ; Get the current file length
CH376_SET_USB_MODE    = $15
CH376_GET_STATUS 	  = $22
CH376_RD_USB_DATA0    = $27
CH376_WR_USB_DATA     = $2C
CH376_CMD_WR_REQ_DATA = $2D
CH376_SET_FILE_NAME   = $2F
CH376_DISK_CONNECT    = $30 ; check the disk connection status
CH376_DISK_MOUNT 	  = $31
CH376_FILE_OPEN 	  = $32
CH376_FILE_ENUM_GO    = $33
CH376_CMD_FILE_CREATE = $34
CH376_FILE_ERASE	  = $35
CH376_FILE_CLOSE 	  = $36
CH376_BYTE_LOCATE     = $39
CH376_BYTE_READ 	  = $3A
CH376_BYTE_RD_GO 	  = $3B
CH376_BYTE_WRITE 	  = $3C
CH376_BYTE_WR_GO      = $3D
CH376_DISK_CAPACITY   = $3E
CH376_DISK_QUERY   	  = $3F
CH376_DIR_CREATE      = $40
CH376_DISK_RD_GO 	  = $55

; CODE FOR CH376_SET_USB_MODE **************************************************/

CH376_SET_USB_MODE_CODE_SDCARD                      =                       $03
; The code of 06H means switch to valid USB-HOST, produce SOF package automatically. 
CH376_SET_USB_MODE_CODE_USB_HOST_SOF_PACKAGE_AUTOMATICALLY = $06

CH376_USB_INT_SUCCESS 	= $14
CH376_USB_INT_CONNECT 	= $15
CH376_USB_INT_DISCONNECT= $16
CH376_USB_INT_BUF_OVER 	= $17
CH376_USB_INT_USB_READY = $18
CH376_USB_INT_DISK_READ = $1d
CH376_USB_INT_DISK_WRITE= $1e
CH376_USB_INT_DISK_ERR 	= $1f

CH376_ERR_OPEN_DIR      = $41
CH376_ERR_MISS_FILE 	= $42
CH376_ERR_FOUND_NAME 	= $43
CH376_ERR_DISK_DISCON 	= $82
CH376_ERR_LARGE_SECTOR 	= $84
CH376_ERR_TYPE_ERROR 	= $92
CH376_ERR_BPB_ERROR 	= $A1
CH376_ERR_DISK_FULL 	= $B1
CH376_ERR_FDT_OVER 	    = $B2
CH376_ERR_FILE_CLOSE 	= $B4


.export _ch376_file_create
.export _ch376_dir_create
.export _ch376_disk_query
.export _ch376_disk_capacity

.proc _ch376_file_create
    lda     #CH376_CMD_FILE_CREATE
    sta     CH376_COMMAND
    jsr     _ch376_wait_response
    rts
.endproc

.proc _ch376_dir_create
    lda     #CH376_DIR_CREATE
    sta     CH376_COMMAND
    jsr     _ch376_wait_response
    rts
.endproc

.proc _ch376_disk_query
    lda     #CH376_DISK_QUERY
    sta     CH376_COMMAND
    jsr     _ch376_wait_response
    lda     CH376_DATA
    sta     TR0
    lda     CH376_DATA
    sta     TR1
    lda     CH376_DATA
    sta     TR2
    lda     CH376_DATA
    sta     TR3    
    rts
.endproc

.proc _ch376_disk_capacity
    lda     #CH376_DISK_CAPACITY
    sta     CH376_COMMAND
    jsr     _ch376_wait_response
    
    lda     #CH376_RD_USB_DATA0
    sta     CH376_COMMAND
    
    lda     CH376_DATA

    lda     CH376_DATA ; total sector0
    sta     TR0 ; $5F
 
    lda     CH376_DATA ; total sector1
    sta     TR1  ; $ED
 
    lda     CH376_DATA ; total sector2
    sta     TR2 ; $92
    
    lda     CH376_DATA ; total sector3
    sta     TR3 ; $d8    
    
    rts
.endproc

.proc _ch376_file_erase
    lda     #CH376_FILE_ERASE
    sta     CH376_COMMAND
    jsr     _ch376_wait_response
    rts
.endproc

; A contains 0 if it needs to update length
.proc _ch376_file_close
    ldx     #CH376_FILE_CLOSE
    stx     CH376_COMMAND
.IFPC02
.pc02
    stz     CH376_DATA
.p02    
.else
    lda     #$00
    sta     CH376_DATA
.endif    
    jsr     _ch376_wait_response
    rts
.endproc

;  [IN] AY : ptr
.proc _ch376_seek_file
    ldx     #CH376_BYTE_LOCATE
    stx     CH376_COMMAND
    sta     CH376_DATA
    sty     CH376_DATA
.IFPC02
.pc02
    stz     CH376_DATA
    stz     CH376_DATA
.p02    
.else	
    lda     #$00
    sta     CH376_DATA
    sta     CH376_DATA
.endif	
    jsr     _ch376_wait_response
    rts
.endproc

; @set filename, input : A and Y adress of the string, terminated by 0
;  If the set is successful, then A contains 0
.proc _ch376_set_file_name

    lda     #CH376_SET_FILE_NAME        ;$2f
    sta     CH376_COMMAND
    ldx     #$00
loop:	
    lda     BUFNOM,x      
    beq     end                         ; we reached 0 value
    cmp     #'a'                        ; 'a'
    bcc     skip
    cmp     #$7B                        ; 'z'
    bcs     skip
    sbc     #$1F
skip:
   ; sta $bb80,x
    sta     CH376_DATA
    inx
    cpx     #13                         ; because we don't manage longfilename shortname =13 8+3 and dot and \0
    bne     loop
    lda     #$00
end:
    sta     CH376_DATA

    rts
.endproc 

.proc _ch376_file_open

    lda #CH376_FILE_OPEN
    sta CH376_COMMAND
    jsr _ch376_wait_response
    rts
.endproc

.proc _ch376_get_file_size
    lda     #CH376_GET_FILE_SIZE
    sta     CH376_COMMAND
    lda     #$68
    sta     CH376_DATA ; ????
    ; store file length
    lda     CH376_DATA
    sta     TR0
    lda     CH376_DATA
    sta     TR1
    lda     CH376_DATA
    sta     TR2
    lda     CH376_DATA
    sta     TR3
    rts	
.endproc
	
.proc _ch376_reset_all
    lda     #CH376_RESET_ALL ; 5 
    sta     CH376_COMMAND
	; waiting
    ldy     #$00
    ldx     #$00
loop:
    nop
    inx
    bne     loop
    iny
    bne     loop

    rts
.endproc 

.proc _ch376_check_exist
    lda     #CH376_CHECK_EXIST ; 
    sta     CH376_COMMAND
    lda     #$55
    sta     CH376_DATA
    lda     CH376_DATA
    rts
.endproc    

.proc _ch376_ic_get_ver
    lda     #CH376_GET_IC_VER
    sta     CH376_COMMAND
    lda     CH376_DATA
    and     #%00111111 ; A contains revision
    clc
    adc     #$30 ; return ascii version
    rts
.endproc
	
.proc _ch376_set_usb_mode
    lda     #CH376_SET_USB_MODE ; $15
    sta     CH376_COMMAND
.ifdef WITH_SDCARD_FOR_ROOT	
	lda     #CH376_SET_USB_MODE_CODE_SDCARD
.else	    
    lda     #CH376_SET_USB_MODE_CODE_USB_HOST_SOF_PACKAGE_AUTOMATICALLY
.endif    
    sta     CH376_DATA	
    rts
.endproc    

_ch376_set_bytes_read:
    ; A and Y contains number of bytes to read
    ldx     #CH376_BYTE_READ
    .byt     $2C                ; jump 2 bytes with the hack bit $xxxx
_ch376_set_bytes_write:	
    ldx     #CH376_BYTE_WRITE
    stx     CH376_COMMAND
    sta     CH376_DATA
    sty     CH376_DATA
.IFPC02	
    stz     CH376_DATA
    stz     CH376_DATA
.else
    lda     #$00
    sta     CH376_DATA
    sta     CH376_DATA
.endif	
    jsr     _ch376_wait_response
    rts
	
.proc _ch376_disk_mount
    lda     #CH376_DISK_MOUNT
    sta     CH376_COMMAND
    jsr     _ch376_wait_response
    ; if we read data value, we have then length of the volume name
    rts
.endproc    



.proc _ch376_wait_response

; 1 return 1 if usb controller does not respond
; else A contains answer of the controller
    ldy     #$FF
loop3:
    ldx     #$FF ; merci de laisser une valeur importante car parfois en mode non debug, le controleur ne répond pas tout de suite
@loop:
    lda     CH376_COMMAND
    and     #%10000000
    cmp     #128
    bne     no_error
    dex
    bne     @loop
    dey
    bne     loop3
	; error is here
    lda     #$01 
    rts

no_error:

    lda     #CH376_GET_STATUS
    sta     CH376_COMMAND
    lda     CH376_DATA
    rts
good_message:
    rts
.endproc    
str_usbdrive_controller_not_found:
	.byte "Usb drive controller not found !",$0D,$0A,0


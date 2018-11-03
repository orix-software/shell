
;size_t fread ( void * ptr, size_t size, size_t count, FILE * stream );

;Read block of data from stream
;Reads an array of count elements, each one with a size of size bytes, from the stream and stores them in the block of memory specified by ptr.

;The position indicator of the stream is advanced by the total amount of bytes read.

; The total amount of bytes read if successful is (size*count).


.proc _fread

	; ptr=RES
	; size = skip
	; count = AY
	; RESB = ptr stream
	
	jsr _ch376_set_bytes_read ; AY in
continue:	
	cmp #$1d ; something to read
	beq we_read
	cmp #CH376_USB_INT_SUCCESS ; finished
	beq finished 
	
we_read:
	lda #CH376_RD_USB_DATA0
	sta CH376_COMMAND

	lda CH376_DATA ; contains length read
	sta TEMP_ORIX_1; Number of bytes to read
	ldy #0
loop9:
	lda CH376_DATA ; read the data
	sta (RES),y
	
	iny
	cpy TEMP_ORIX_1
	bne loop9
	tya
	clc
	adc RES
	bcc next13
	inc RES+1
next13:
	sta RES
	;jmp end_cat
	lda #CH376_BYTE_RD_GO
	sta CH376_COMMAND
	jsr _ch376_wait_response
	jmp continue
finished:	
	rts	
.endproc	




	
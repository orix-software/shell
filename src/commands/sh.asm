.proc _sh

  SH_LOAD_FILE := $801
  ptr_file     := VARLNG ; 2 bytes
  ptr_file_save:= VARLNG+2

; TODO malloc
; TODO mainargs

  ldx #$01
  jsr _orix_get_opt
  
  FOPEN ORIX_ARGV,O_RDONLY
 
  ; A register contains FP id
  sta TR0
; define target address
  lda #<SH_LOAD_FILE
  sta PTR_READ_DEST
  lda #>SH_LOAD_FILE
  sta PTR_READ_DEST+1
; We read 8000 bytes
  lda #<8000
  ldy #>8000
; reads byte 
  BRK_TELEMON XFREAD
  BRK_TELEMON XCLOSE  
  
; Store return
  ldy #$00
  lda #$0D
  sta (PTR_READ_DEST),y
; store 0 at the end of the file in memory
  iny
  lda #$00
  sta (PTR_READ_DEST),y
   
  ldy #$00
restart:
  ldx #$00  
@loop: 
  lda SH_LOAD_FILE,y
  beq exit
  cmp #$0D
  beq end
  cmp #$0A
  beq end
  sta BUFEDT,x
  inx
  iny
  bne @loop
end:
  lda #$00
  sta BUFEDT,x
  iny
  sty TEMP_SH_COMMAND
 
  lda #<BUFEDT
	ldy #>BUFEDT
	jsr _bash             ; launch interpreter
  ;UNREGISTER_PROCESS_BY_PID_IN_ACCUMULATOR
  ;UNREGISTER_PROCESS    ; macro
skipme:
  ldy TEMP_SH_COMMAND
  jmp restart
exit:
  rts
.endproc


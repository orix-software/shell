.proc _sh

    SH_LOAD_FILE := $801
    ptr_file     := userzp ; 2 bytes
    ptr_file_save:= userzp+2

    ; TODO read file length and malloc
    SH_FILE_LENGTH_MAX = 1000

    MALLOC  SH_FILE_LENGTH_MAX
    ; FIXME test OOM
    TEST_OOM_AND_MAX_MALLOC
    sta     ptr_file
    sty     ptr_file+1

; TODO malloc
; TODO mainargs

    ldx #$01
    jsr _orix_get_opt
  
    FOPEN ORIX_ARGV,O_RDONLY
 
    ; A register contains FP id
    sta TR0
  ; define target address
    lda ptr_file
    sta PTR_READ_DEST
    lda ptr_file+1
    sta PTR_READ_DEST+1
  ; We read 8000 bytes
    lda #<SH_FILE_LENGTH_MAX
    ldy #>SH_FILE_LENGTH_MAX
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
  lda (ptr_file),y
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
  ; Free the process 
  ;lda ORIX_CURRENT_PROCESS_FOREGROUND
  UNREGISTER_PROCESS 
  ;UNREGISTER_PROCESS_BY_PID_IN_ACCUMULATOR
  ;UNREGISTER_PROCESS    ; macro
skipme:
  ldy TEMP_SH_COMMAND
  jmp restart
exit:
  rts
.endproc


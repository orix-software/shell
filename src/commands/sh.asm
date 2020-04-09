.proc _sh
    ptr_file       := userzp ; 2 bytes
    ptr_file_save:= userzp+2
    TEMP_SH_COMMAND :=userzp+4

    ; TODO read file length and malloc
    SH_FILE_LENGTH_MAX = 1000

    ldx     #$01
    jsr     _orix_get_opt
    bcs     @start_normal


   ; MALLOC  SH_FILE_LENGTH_MAX
    ; FIXME test OOM
 ;   TEST_OOM_AND_MAX_MALLOC
;    sta     ptr_file
    ;sta     ptr_file_save
    ;sty     ptr_file+1
    ;sty     ptr_file_save+1

; TODO malloc
; TODO mainargs

    ;ldx     #$01
    ;jsr     _orix_get_opt
    ; is there a file to open ? 
    ;lda     ORIX_ARGV
    ;bne     thereis_a_script_to_execute
    ; Let's start a prompt
    ;lda     ptr_file
    ;ldy     ptr_file+1
    ;BRK_KERNEL XFREE
  @start_normal:
    jmp     start_sh_interactive


thereis_a_script_to_execute:    
    FOPEN   ORIX_ARGV,O_RDONLY
 
    ; A register contains FP id
    sta     TR0
  ; define target address
    lda     ptr_file
    
    sta     PTR_READ_DEST
    lda     ptr_file+1
    sta     PTR_READ_DEST+1
  ; We read 8000 bytes
    lda     #<SH_FILE_LENGTH_MAX
    ldy     #>SH_FILE_LENGTH_MAX
  ; reads byte 
    BRK_TELEMON XFREAD
    BRK_TELEMON XCLOSE  
  
  ; Store return
    ldy     #$00
    lda     #$0D
    sta     (PTR_READ_DEST),y
  ; store 0 at the end of the file in memory
    iny
    lda     #$00
    sta     (PTR_READ_DEST),y
   
    ldy     #$00
restart:
    ; this loop copy the line from textfile and insert it into BUFEDT. Then interpreter is launched
    ldx     #$00  
@loop: 
    lda     (ptr_file),y
    beq     exit
    cmp     #$0D
    beq     end
    cmp     #$0A
    beq     end
    
    inx
    iny
    bne     @loop
end:
    lda     #$00
    
    iny
    sty     TEMP_SH_COMMAND
 
    
    jsr     _bash             ; launch interpreter
  ; Free the process 
  
skipme:
    ldy     TEMP_SH_COMMAND
    tya     
    clc
    adc     ptr_file
    bcc     @skip
    inc     ptr_file+1
@skip:
    sta     ptr_file
    ldy     #$00
    jmp     restart           ; FIXME 65C02
exit:

 ;   FREE    ptr_file_save 
    ; FIXME Free the process too
    rts
.endproc


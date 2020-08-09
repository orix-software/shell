.proc _sh
    ptr_file_sh_interactive := userzp
    ptr_file_sh_interactive_ptr_save := userzp+2
    
    ptr_file_sh_interactive_size_file :=userzp+4  ; 16 bits

    ptr_file_sh_interactive_ptr := userzp+6
    

    
    ; TODO read file length and malloc
    SH_FILE_LENGTH_MAX = 1000

    ldx     #$01
    jsr     _orix_get_opt
    bcc     @start_normal
   
    lda     ORIX_ARGV
    bne     thereis_a_script_to_execute

  @start_normal:
    jmp     start_sh_interactive


thereis_a_script_to_execute: 

    FOPEN   ORIX_ARGV,O_RDONLY
 
    ; A register contains FP id
    sta     ptr_file_sh_interactive
    sty     ptr_file_sh_interactive+1

    lda     #CH376_GET_FILE_SIZE
    sta     CH376_COMMAND
    lda     #$68
    sta     CH376_DATA ; ????
    ; store file length
    ldx     CH376_DATA
    stx     ptr_file_sh_interactive_size_file

    ldy     CH376_DATA
    sty     ptr_file_sh_interactive_size_file+1

    ; and drop others (max 64KB of file)
    lda     CH376_DATA
    lda     CH376_DATA
    
    txa     ; get low byte of the size
    
    BRK_KERNEL XMALLOC
    sta      ptr_file_sh_interactive_ptr
    sta      ptr_file_sh_interactive_ptr

    sty      ptr_file_sh_interactive_ptr+1
    sty      ptr_file_sh_interactive_ptr_save+1

  ; define target address
    lda     ptr_file_sh_interactive_ptr
    sta     PTR_READ_DEST
    
    lda     ptr_file_sh_interactive_ptr+1
    sta     PTR_READ_DEST+1

  ; We read the file with the correct
    lda     ptr_file_sh_interactive_size_file
    ldy     ptr_file_sh_interactive_size_file+1
  ; reads byte 
    BRK_KERNEL XFREAD
    BRK_KERNEL XCLOSE
    
    lda     ptr_file_sh_interactive
    ldy     ptr_file_sh_interactive+1
    BRK_KERNEL XFREE

    ldy     #$00
@L1:    
    lda     (ptr_file_sh_interactive_ptr),y
    cmp     #$0D
    beq     @found_end_command
    iny
    cpy     ptr_file_sh_interactive_size_file
    bne     @L1

    rts
@found_end_command:
    lda     #$00
    rts

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
    ;lda     (ptr_file),y
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
  ;  sty     TEMP_SH_COMMAND
 
    
    jsr     _bash             ; launch interpreter
  ; Free the process 
  
skipme:
 ;   ldy     TEMP_SH_COMMAND
    tya     
    clc
 ;   adc     ptr_file
    bcc     @skip
   ; inc     ptr_file+1
@skip:
    ;sta     ptr_file
    ldy     #$00
    jmp     restart           ; FIXME 65C02
exit:

 ;   FREE    ptr_file_save 
    ; FIXME Free the process too
    rts
.endproc


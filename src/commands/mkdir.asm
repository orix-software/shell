.export _mkdir


mkdir_length_to_malloc := userzp
mkdir_temp             := userzp+3
mkdir_malloc_ptr       := userzp+1 ; .word
; LIMIT : can't malloc more than 255 for the path


.proc _mkdir
; broken

  ldx     #$01
  jsr     _orix_get_opt
  lda     ORIX_ARGV
  beq     @missing_operand
  
  ldx     #$01
  jsr     _orix_get_opt
  lda     ORIX_ARGV
  beq     @missing_operand

  ldy     #$00
@L20:
  lda     ORIX_ARGV,y
  beq     @out20
  cmp     #'/'
  beq     @slash_found
  iny
  bne     @L20
@out20:
    lda     #<ORIX_ARGV

    ldy     #>ORIX_ARGV
    BRK_KERNEL XMKDIR
    BRK_KERNEL XCLOSE
    rts
@slash_found:
  PRINT str_arg_not_managed_yet
  rts


    ;sta     RES+1

    ;compute strlen of the argument
    lda     #<ORIX_ARGV
    sta     RES
    lda     #>ORIX_ARGV
    sta     RES+1
    jsr     _strlen
    sty     mkdir_length_to_malloc
    
    ;  compute strlen of cwd

    sta     RES+1
    sta     mkdir_temp+1
    jsr     _strlen
    iny     ; add for "/" for the 2 arg
    tya
    sec     ; Add 1 for '\0'
    adc     mkdir_length_to_malloc
    ldy     #$00
    BRK_KERNEL XMALLOC
    sta     mkdir_malloc_ptr
    sty     mkdir_malloc_ptr+1

    ; Now concat

    ldy     #$00
@loop:    
    lda     (mkdir_temp),y
    sta     (mkdir_malloc_ptr),y
    beq     @orix_pwd_copy_done
    iny
    bne     @loop
@orix_pwd_copy_done:
    lda     #'/' ; add slashes
    sta     (mkdir_malloc_ptr),y
; copy argv now
    ldx     #$00
@L2:   
    lda     ORIX_ARGV,x
    sta     (mkdir_malloc_ptr),y
    beq     @out
    iny
    inx
    bne     @L2
@out:
    lda     #$00
    sta     (mkdir_malloc_ptr),y
    lda     mkdir_malloc_ptr
    ldy     mkdir_malloc_ptr+1

    BRK_KERNEL XMKDIR
    rts
@missing_operand:
    PRINT mkdir
    PRINT str_missing_operand
    rts
.endproc


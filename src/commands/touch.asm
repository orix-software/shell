.export _touch

.proc _touch
 ; .byte $00,$2C ; XMAINARGS

  touch_ptr1       :=userzp
  touch_arg_length :=userzp+2

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
  ldy     #O_WRONLY

  lda     #<ORIX_ARGV
  ldx     #>ORIX_ARGV

  BRK_KERNEL XOPEN
  BRK_KERNEL XCLOSE

  rts  
@slash_found:
  PRINT str_arg_not_managed_yet
  rts


; prevent the rm / case
  ;PRINT    ORIX_ARGV
  ; compute the and store
  lda     #<ORIX_MAX_PATH_LENGTH
  ldy     #>ORIX_MAX_PATH_LENGTH

  BRK_KERNEL XMALLOC
  cmp     #NULL
  bne     @S1
  cpy     #NULL
  bne     @S1
  PRINT   str_oom
  rts

@missing_operand:
  PRINT   touch
  PRINT   str_missing_operand
  rts  


@S1:
  sta     touch_ptr1
  sty     touch_ptr1+1
  ; Copy args
  ldy     #$00
@L2:
  lda     ORIX_ARGV,y
  beq     @out
  sta     (touch_ptr1),y
  iny
  bne     @L2
@out:
  lda     #$00
  sta     (touch_ptr1),y

  sty     touch_arg_length

  ; try to get the first / from the end in order to detect path
  dey
@L3:  
  lda     (touch_ptr1),y
  cmp     #'/'
  beq     @path_found
  dey
  bpl     @L3
  jmp     @relative
@path_found:
  cpy     #$00
  beq     @relative
  
  lda     #$00
  sta     (touch_ptr1),y

  lda     touch_ptr1
  ldx     touch_ptr1+1

  ldy     #O_RDONLY
  BRK_KERNEL XOPEN

  ; then create last arg
  ldy     touch_arg_length
  dey
@L4:  
  lda     (touch_ptr1),y
  beq     @param_found
  dey
  bne     @L4
  ; error arg
  rts

@param_found:
  iny
  tya
  clc
  adc     touch_ptr1
  bcc     @S6
  inc     touch_ptr1+1
@S6:
  sta     touch_ptr1

  lda     touch_ptr1
  ldx     touch_ptr1+1

  ldy     #O_WRONLY
  BRK_KERNEL XOPEN


@relative:
  lda     touch_ptr1
  ldx     touch_ptr1+1

  ldy     #O_WRONLY
  BRK_KERNEL XOPEN

  rts

; Y the length
  





  ;lda ORIX_ARGV
  ;cmp #'/'
  ;bne skip_touch_slash_case ;  
  ;lda ORIX_ARGV+1
  ;beq @missing_operand
  
skip_touch_slash_case:
  FOPEN ORIX_ARGV,O_WRONLY
  rts
  

.endproc
str_arg_not_managed_yet:
  .asciiz "path with folders in arg not managed yet"

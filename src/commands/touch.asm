.export _touch

.proc _touch
 ; .byte $00,$2C ; XMAINARGS

    touch_ptr1              :=userzp
    touch_arg_length        :=userzp+2
    touch_mainargs_argv     := userzp+4
    touch_mainargs_argc     := userzp+8 ; 8 bits
    touch_mainargs_arg1_ptr := userzp+15

    BRK_KERNEL XMAINARGS
    sta     touch_mainargs_argv
    sty     touch_mainargs_argv+1
    stx     touch_mainargs_argc

    cpx     #$01
    beq     @missing_operand

    ldx     #$01
    lda     touch_mainargs_argv
    ldy     touch_mainargs_argv+1

    BRK_KERNEL XGETARGV
    sta     touch_mainargs_arg1_ptr
    sty     touch_mainargs_arg1_ptr+1



  ldy     #$00
@L20:
  lda     (touch_mainargs_arg1_ptr),y
  beq     @out20
  cmp     #'/'
  beq     @slash_found
  iny
  bne     @L20
@out20:
  ldy     #O_WRONLY

  lda     touch_mainargs_arg1_ptr
  ldx     touch_mainargs_arg1_ptr+1

  BRK_KERNEL XOPEN
  BRK_KERNEL XCLOSE

  rts
@slash_found:
  print str_arg_not_managed_yet
  rts


; prevent the rm / case

  ; compute the and store
  lda     #<ORIX_MAX_PATH_LENGTH
  ldy     #>ORIX_MAX_PATH_LENGTH

  BRK_KERNEL XMALLOC
  cmp     #NULL
  bne     @S1
  cpy     #NULL
  bne     @S1
  print   str_oom
  rts

@missing_operand:
  print   touch
  print   str_missing_operand
  rts


@S1:
  sta     touch_ptr1
  sty     touch_ptr1+1
  ; Copy args
  ldy     #$00
@L2:
  lda     (touch_mainargs_arg1_ptr),y
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

skip_touch_slash_case:
  fopen (touch_mainargs_argv),O_WRONLY|O_CREAT
  rts


.endproc
str_arg_not_managed_yet:
    .asciiz "path with folders in arg not managed yet"

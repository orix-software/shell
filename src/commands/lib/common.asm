
.proc commands_check_2_params

  ldx #$01
  jsr _orix_get_opt
  lda ORIX_ARGV
  beq missing_operand

  ldx #$02
  jsr _orix_get_opt
  lda ORIX_ARGV
  beq missing_operand_after

  ldx #$01
  jsr _orix_get_opt
  lda ORIX_ARGV
  cmp #'/'
  bne skip_slash_case ;  
  lda ORIX_ARGV+1
  beq no_such_file
skip_slash_case:
  lda #$00
  
  rts
 
missing_operand:
  ldx #$00
  jsr _orix_get_opt
  lda #<ORIX_ARGV
  ldy #>ORIX_ARGV
  BRK_TELEMON XWSTR0 
  lda #<str_missing_operand
  ldy #>str_missing_operand
  BRK_TELEMON XWSTR0          ; FIXME PRINT
  lda #$01 ; Error
  rts  
no_such_file: 
  lda #$01
  rts

missing_operand_after:
  ldx #$00
  jsr _orix_get_opt
  lda #<ORIX_ARGV
  ldy #>ORIX_ARGV

  BRK_TELEMON XWSTR0

  lda #':'
  BRK_TELEMON XWR0
  lda #' '
  BRK_TELEMON XWR0
  lda #<str_missing_operand_after
  ldy #>str_missing_operand_after
  BRK_TELEMON XWSTR0
	ldx #$01
	jsr _orix_get_opt
  PRINT ORIX_ARGV
  ;lda #$27            ; FIXME CGETC
  ;BRK_TELEMON XWR0
  CPUTC '''
  BRK_TELEMON XCRLF
 
  lda #$01
  rts  
str_missing_operand_after:  
.asciiz "missing destination file operand after '"
.endproc

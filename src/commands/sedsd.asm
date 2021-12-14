.proc _sedsd
  ; open first params

  ; FIXME err

  ldy #O_RDONLY ; Open in readonly
  BRK_TELEMON XOPEN
  cmp #$FF
  beq no_such_file

  ; Let's copy
  
  ; Send the fp pointer
  ;lda #$01 ; 1 is the fd id of the file opened
  sta TR0
; define target address
; FIXME MALLOC
  lda #<$801
  sta PTR_READ_DEST
  sta ptr1
  lda #>$801
  sta ptr1+1
  sta PTR_READ_DEST+1
; We read 8000 bytes
  lda #<CP_SIZE_OF_BUFFER
  ldy #>CP_SIZE_OF_BUFFER
; reads byte 
  BRK_TELEMON XFREAD
  ; Compute bytes written
  lda     PTR_READ_DEST+1
  sec
  sbc     ptr1+1
  sta     ptr1+1
  ;tax			
  lda     PTR_READ_DEST
  sec
  sbc     ptr1
  sta     ptr1


  rts
no_such_file:
  rts

.endproc

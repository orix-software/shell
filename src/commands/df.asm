.proc _df
LSB:=TR0 ; FIXME labels and convd
NLSB:=TR1
NMSB:=TR2
MSB:=TR3

  jsr   _ch376_verify_SetUsbPort_Mount
  cmp   #$01
  beq   error
  jmp   no_error_for_mouting
error:
    rts
no_error_for_mouting:
  PRINT str_df_columns
  ;RETURN_LINE
  jsr   _ch376_disk_capacity
  lda   TR3
  jsr   _print_hexa
  lda   TR2
  jsr   _print_hexa_no_sharp
  lda   TR1
  jsr    _print_hexa_no_sharp
  lda   TR0
  jsr   _print_hexa_no_sharp
  RETURN_LINE
  rts
  
  BRK_TELEMON XCRLF
 

  lda   #$d2
  sta   TR0
  lda   #$02
  sta   TR1
  lda   #$96
  sta   TR2
  lda   #$49
  sta   TR3
  
  jsr     convd
  
  lda     volatile_str
  AND     #%11110000
  clc
  adc     #$30
  BRK_TELEMON XWR0

  lda     volatile_str
  AND     #%00001111
  clc
  adc     #$30
  BRK_TELEMON XWR0
  
  ; Divide
  
    ;12
  
  lda     CH376_DATA ; total free sector0
  lda     CH376_DATA ; total free sector1
  lda     CH376_DATA ; total free sector2
  lda     CH376_DATA ; total free sector3
    
  
  
  lda     CH376_DATA  ; DiskFat type



  rts
  
convd:


        ldx #$04          ; Clear BCD accumulator
        lda #$00
    BRM:
        sta volatile_str,x        ; Zeros into BCD accumulator
        dex
        bpl BRM

        sed               ; Decimal mode for add.

        ldy #$20          ; Y has number of bits to be converted
    BRN:
        asl LSB           ; Rotate binary number into carry
        rol NLSB
        rol NMSB
        rol MSB


    
        ldx #$fb          ; X will control a five byte addition.
    BRO:
        lda volatile_str-$fb,x    ; Get least-signficant byte of the BCD accumulator
        adc volatile_str-$fb,x    ; Add it to itself, then store.
        sta volatile_str-$fb,x
        inx               ; Repeat until five byte have been added
        bne BRO

        dey               ; et another bit rom the binary number.
        bne BRN

        cld               ; Back to binary mode.
        rts               ; And back to the program.
  
divide_by_1000:

str_df_columns:
    .byte "512-blocks Used Avail. Use% Mounted on",$0d,$0A,0

str_sda1:
    .asciiz "/dev/sda1"
.endproc

.proc _lsmem
    
   PRINT str_column
    
    ldx #$00
    
    myloop:
        txa
        pha
        PRINT str_FREE
        lda ORIX_MALLOC_FREE_BEGIN_HIGH_TABLE,x
        jsr _print_hexa
 
        
        lda ORIX_MALLOC_FREE_BEGIN_LOW_TABLE,x
        jsr _print_hexa_no_sharp
        
        CPUTC ':'

        
        lda ORIX_MALLOC_FREE_END_HIGH_TABLE,x
        jsr _print_hexa
     
        
        lda ORIX_MALLOC_FREE_END_LOW_TABLE,x
        jsr _print_hexa_no_sharp
        
        CPUTC ' '
        
        lda  ORIX_MALLOC_FREE_SIZE_HIGH_TABLE,x
        jsr _print_hexa
        
        lda  ORIX_MALLOC_FREE_SIZE_LOW_TABLE,x
        jsr _print_hexa_no_sharp
    
        BRK_ORIX XCRLF
        
        pla
        tax



 
    ldx #$00

    myloop2:
        lda ORIX_MALLOC_BUSY_TABLE_PID,x
        beq busy_chunk_is_empty
    
        ; at this step X contains 
        txa
        pha
        
        
        PRINT str_BUSY
        lda ORIX_MALLOC_BUSY_TABLE_BEGIN_HIGH,x
        jsr _print_hexa
        lda ORIX_MALLOC_BUSY_TABLE_BEGIN_LOW,x
        jsr _print_hexa_no_sharp
        
        
        CPUTC ' '
        
        lda ORIX_MALLOC_BUSY_TABLE_END_HIGH,x
        jsr _print_hexa
        lda ORIX_MALLOC_BUSY_TABLE_END_LOW,x
        jsr _print_hexa_no_sharp
        
        
        CPUTC ' '

        lda ORIX_MALLOC_BUSY_TABLE_SIZE_HIGH,x
        jsr _print_hexa
        lda ORIX_MALLOC_BUSY_TABLE_SIZE_LOW,x
        jsr _print_hexa_no_sharp

        CPUTC ' '

        ; looking for PID

          ldy     #$00
        @loop
          lda     LIST_PID,y
          cmp     ORIX_MALLOC_BUSY_TABLE_PID,x
          beq     @found
          iny     
          cpy     #ORIX_MAX_PROCESS
          bne     @loop
          rts
          ; at this step, we did not found the process, we should send an exception
        @found
         tya
         tax
     
        
         ; at this step we found the PID and his position un process list : X contains the position of the process list
  

                
        ; display the program
        lda orix_command_table_low,x
        ldy orix_command_table_high,x
        BRK_ORIX XWSTR0
        
        pla 
        
        pha
        
        ldy #$00 
        PRINT_BINARY_TO_DECIMAL_16BITS 2
        
        BRK_TELEMON XCRLF
        ; save X
        pla 
        tax
     busy_chunk_is_empty:
        inx
        cpx #ORIX_NUMBER_OF_MALLOC
        bne myloop2


skip:

    rts
str_column:
    .byte "TYPE  START END   SIZE  PROGRAM  CHUNK",$0D,$0A,0    
.)
str_empty_program:
    .asciiz "       "
str_FREE
    .asciiz "Free  "


str_BUSY:
    .asciiz "Busy  "
str_SIZE:
    .asciiz "Size:"
.endproc


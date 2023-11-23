.export _lsmem

.define LSMEM_KERNEL_MAX_NUMBER_OF_MALLOC 7
.define MALLOC_TABLE_COPY 2
.define XVALUES $2D

.proc _lsmem

   lsmem_ptr_malloc                        := userzp
   lsmem_ptr_pid_table  := userzp+2	 ; Get struct
   lsmem_savey_kernel_malloc_busy_pid_list := userzp+4
   lsmem_savey                             := userzp+6  ; 1 byte
   lsmem_savex                             := userzp+7  ; 1 byte
   lsmem_savexbis                          := userzp+8  ; 1 byte
   lsmem_ptr_command_name                  := userzp+10
   lsmem_ptr_command_name_tmp              := userzp+12
   lsmem_current_process_read              := userzp+14
   lsmem_ptr_one_process                   := userzp+16
   lsmem_copy_malloc_struct_ptr            := userzp+18 ; 2 bytes
   lsmem_kernel_max_number_of_malloc       := userzp+20 ; 1 byte store the nb of bysy malloc

   ldx     #MALLOC_TABLE_COPY ; Free
   BRK_KERNEL XVALUES
   sta     lsmem_ptr_malloc
   sty     lsmem_ptr_malloc+1

   print   str_column

   crlf

; Displays all free chunk

    ldy     #$00

    ; Get the numnber of line
    lda     (lsmem_ptr_malloc),y
    sta     lsmem_kernel_max_number_of_malloc

    ldx     #$00
    ldy     #$00

    ; Test if free chunk is used
@L1:
    iny
    sty     lsmem_savey

    stx     lsmem_savex

    print   str_FREE

    ldy     lsmem_savey
    lda     (lsmem_ptr_malloc),y ; Low

    jsr     _print_hexa

    inc     lsmem_savey ; high

    ldy     lsmem_savey
    lda     (lsmem_ptr_malloc),y ; high

    jsr     _print_hexa_no_sharp

    print   #':'

    inc     lsmem_savey ; low

    ldy     lsmem_savey
    lda     (lsmem_ptr_malloc),y ; low


    jsr     _print_hexa

    inc     lsmem_savey ; high

    ldy     lsmem_savey
    lda     (lsmem_ptr_malloc),y ; high

    jsr     _print_hexa_no_sharp


    print   #' '
  ; Affichage de la size free
    inc     lsmem_savey ; low

    ldy     lsmem_savey
    lda     (lsmem_ptr_malloc),y ; low

    jsr     _print_hexa

    inc     lsmem_savey ; low

    ldy     lsmem_savey
    lda     (lsmem_ptr_malloc),y ; low

    jsr    _print_hexa_no_sharp

    ldy     lsmem_savey

    crlf

@S5:
    ldx     lsmem_savex
    inx
    cpx     lsmem_kernel_max_number_of_malloc
    bne     @L1

    mfree(lsmem_ptr_malloc)

; ***********************************************************************
; Busy TABLE
; ***********************************************************************

    ldx     #$07 ; Busy table id
    BRK_KERNEL XVALUES
    sta     lsmem_ptr_malloc
    sty     lsmem_ptr_malloc+1

    ; Displays all free chunk

    ldy     #$00

    ; Get the numnber of line
    lda     (lsmem_ptr_malloc),y ; Low
    sta     lsmem_kernel_max_number_of_malloc

    ldx     #$00
    ldy     #$01

    ; Test if free chunk is used
@L1BUSY:
    sty     lsmem_savey

    stx     lsmem_savex

    print   str_BUSY
;;;;;;;;;;;;;;;; High adress
    ldy     lsmem_savey
    lda     (lsmem_ptr_malloc),y ; Low

    jsr     _print_hexa

    inc     lsmem_savey

;;;;;;;;;;;;;;;; low adress

    ldy     lsmem_savey
    lda     (lsmem_ptr_malloc),y

    jsr     _print_hexa_no_sharp

    print   #':'

    inc     lsmem_savey ; low

;;;;;;;;;;;;;;;; High adress

    ldy     lsmem_savey
    lda     (lsmem_ptr_malloc),y ; low

    jsr     _print_hexa
    inc     lsmem_savey ; high

;;;;;;;;;;;;;;;; low adress

    ldy     lsmem_savey
    lda     (lsmem_ptr_malloc),y ; high
    jsr     _print_hexa_no_sharp

    print   #' '
  ; Affichage de la size free
    inc     lsmem_savey ; low

;;;;;;;;;;;;;;;; high size

    ldy     lsmem_savey
    lda     (lsmem_ptr_malloc),y ; low

    jsr     _print_hexa

    inc     lsmem_savey ; low

;;;;;;;;;;;;;;;; low address size

    ldy     lsmem_savey
    lda     (lsmem_ptr_malloc),y ; low

    jsr    _print_hexa_no_sharp

    ldx     lsmem_savex

    txa     ; Get the id of the malloc
    tay

    print   #' '

    ldx     #$08 ; GET ptr of the malloc chunk
    BRK_KERNEL XVALUES
    cpy     #$00
    bne     @display_processname

    cmp     #$00
    bne     @display_processname
    beq     @display_init_name
@display_processname:
    sta     lsmem_ptr_command_name
    sty     lsmem_ptr_command_name+1

    print   (lsmem_ptr_command_name)
    jmp     @skip_display_name

@display_init_name:
    print str_INIT

@skip_display_name:
    inc     lsmem_savey
    crlf
    ldy     lsmem_savey
    ldx     lsmem_savex
    inx
    cpx     lsmem_kernel_max_number_of_malloc
    bne     @L1BUSY

    mfree(lsmem_ptr_malloc)

    rts

str_column:
    .asciiz "TYPE START END   SIZE  PROCESS"
    ;  PROGRAM  PID FUNC",0

str_empty_program:
    .asciiz "       "

str_FREE:
    .asciiz "Free "

str_BUSY:
    .asciiz "Busy "

str_INIT:
    .asciiz "init"

str_SPACE:
    .asciiz "unkn "
.endproc

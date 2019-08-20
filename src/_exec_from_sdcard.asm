
    ptr_header   :=userzp+2
    fp_exec      :=userzp+4
    copy_str:= userzp+8
    temp:= userzp+10

orix_try_to_find_command_in_bin_path:
	; here we found no command, let's go trying to find it in /bin

    ldx     #$00
    jsr     _orix_get_opt

    jsr     _start_from_root_bin
    ; If it return NULL then it's not found.

    cmp     #NULL ; if it return y=$ff a=$ff (it's not open)
    bne     @found_in_bin_folder
    cpy     #NULL ; if it return y=$ff a=$ff (it's not open)
    bne     @found_in_bin_folder
    beq     @even_in_slash_bin_command_not_found
@found_in_bin_folder:    
    ; we should start code here
    jmp     _orix_load_and_start_app_xopen_done

@even_in_slash_bin_command_not_found:
    ; At this step A & Y still contains FP then free
    BRK_ORIX(XFREE)
    RETURN_LINE
    PRINT   ORIX_ARGV
    PRINT   str_command_not_found
    rts


.proc _start_from_root_bin
    ; Malloc
    MALLOC (5+8)
    ; FIX ME test OOM
    sta copy_str
    sty copy_str+1
	
    ; copy /bin
    ; do a strcat
    ldy     #$00
@L1:
    lda     str_root_bin,y
    beq     @end
    sta     (copy_str),y
    iny
    cpy     #.strlen("/bin/")
    bne     @L1

@end:
    ldx     #$00
@L2:
    lda     ORIX_ARGV,x
    beq     @end2
    sta     (copy_str),y
    inx
    iny
    cpx     #8
    bne     @L2
    ; now copy argv[0]
@end2:
    sta     (copy_str),y
    ldy     #O_RDONLY
    lda     copy_str
    ldx     copy_str+1
    BRK_KERNEL XOPEN
    ; save FP
    sta     temp
    sty     temp+1
    
    ; free string allocated
    lda     copy_str
    ldy     copy_str+1
    BRK_KERNEL XFREE
    
    ; return fp (or null if XOPEN failed)
    lda     temp
    ldy     temp+1

    rts
str_root_bin:
    ; If you change this path, you need to change .strlen("/bin/") above
    .asciiz "/bin/"
.endproc    


	
  
_orix_load_and_start_app_xopen_done:

    ; Save pointer
    sta    fp_exec     
    sty    fp_exec+1
    MALLOC 20 ; Malloc 20 bytes (20 bytes for header)
    
    TEST_OOM_AND_MAX_MALLOC
    
    sta     ptr_header
    sty     ptr_header+1
    
    sta     PTR_READ_DEST
    sty     PTR_READ_DEST+1
    ; read 20 bytes in the header
    lda     #20
    ldy     #$00
    BRK_TELEMON XFREAD
   
    
    ldy     #$00
    lda     (ptr_header),y ; fixme 65c02

    cmp     #$01
    beq     @is_an_orix_file
    RETURN_LINE
    
    BRK_TELEMON XCLOSE
    ; not found it means that we display error message
    ldx     #$00
    jsr     _orix_get_opt
    PRINT   ORIX_ARGV

    PRINT   str_cant_execute
    RETURN_LINE
    ; FIXME close the opened file here

    BRK_TELEMON XCLOSE

    jmp     @free_exec

@is_an_orix_file:
    RETURN_LINE	

  	; Switch off cursor
    ldx     #$00
    BRK_TELEMON XCOSCR
    ; Storing address to load it

    ldy     #14
    lda     (ptr_header),y ; fixme 65c02
    sta     PTR_READ_DEST

    ldy     #15
    lda     (ptr_header),y ; fixme 65c02
    sta     PTR_READ_DEST+1
		
    ; init RES to start code

    ldy     #18
    lda     (ptr_header),y ; fixme 65c02
    sta     exec_address

    ldy     #19
    lda     (ptr_header),y ; fixme 65c02    
    sta     exec_address+1
    
    ldx     #$00
    jsr     _orix_get_opt
	
    lda     #$FF ; read all the binary
    ldy     #$FF
    BRK_TELEMON XFREAD
    ; FIXME return nb_bytes read malloc must be done
   
    lda     #$00 ; don't update length
    BRK_TELEMON XCLOSE

    jsr     @free_exec

    jmp     (exec_address) ; jmp : it means that if program launched do an rts, it returns to interpreter

@free_exec:
    lda     fp_exec     
    ldy     fp_exec+1
    BRK_KERNEL XFREE

    lda     ptr_header
    ldy     ptr_header+1
    BRK_TELEMON XFREE
    rts


; shell_bash_variables+shell_bash_struct::path_current
.proc _getTelemonVar

    ; X contains the id 
    lda low,x
    ldy high,x
    rts
low:    
    .byt <shell_bash_variables+shell_bash_struct::path_current
high:
    .byt >shell_bash_variables+shell_bash_struct::path_current

.endproc   


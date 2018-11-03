.proc _kill
    ldx #$01
    jsr _orix_get_opt
    ; stub
    jsr _orix_unregister_process
    rts
.endproc


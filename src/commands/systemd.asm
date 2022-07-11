.proc _systemd
    jsr     systemd_start
    jsr     detection_bank
    rts
.endproc
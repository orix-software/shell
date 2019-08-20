.export _pwd


  XGETCWD_ROUTINE=$48
  XPUTCWD_ROUTINE=$49

.proc _pwd
    BRK_ORIX XGETCWD_ROUTINE
    BRK_ORIX XWSTR0
    BRK_ORIX XCRLF
    rts
.endproc

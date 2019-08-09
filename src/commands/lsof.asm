.export _lsof

.proc _lsof

  PRINT str_nb_of_opened_files
  
  lda  NUMBER_OPENED_FILES
  clc
  adc   #$30
  BRK_ORIX  XWR0
  RETURN_LINE
  
  rts
str_nb_of_opened_files:
    .asciiz  "Number of opened files : "
.endproc

.proc _oconfig

    PRINT oconfig_str_compile_time
    rts
    

oconfig_str_compile_time:

.ifdef WITH_MULTITASKING
.byte ORIX_STRCONFIG_MULTITASKING,$0A,$0D
.endif

.ifdef WITH_ACIA
.byte ORIX_STRCONFIG_ACIA,$0A,$0D
.endif

.ifdef WITH_BANKS       
.byte ORIX_STRCONFIG_BANKS,$0A,$0D
.endif
          
.ifdef WITH_CPUINFO
.byte ORIX_STRCONFIG_CPUINFO,$0A,$0D
.endif

.ifdef WITH_DEBUG
.byte ORIX_STRCONFIG_DEBUG,$0A,$0D 
.endif

.ifdef WITH_DF            
.byte ORIX_STRCONFIG_DF,$0A,$0D
.endif

.ifdef WITH_HISTORY         
.byte ORIX_STRCONFIG_HISTORY,$0A,$0D
.endif

.ifdef WITH_KILL           
.byte ORIX_STRCONFIG_KILL,$0A,$0D
.endif

.ifdef WITH_LESS
.byte ORIX_STRCONFIG_LESS,$0A,$0D
.endif

.ifdef WITH_LSOF
.byte ORIX_STRCONFIG_LSOF,$0A,$0D
.endif

.ifdef WITH_MONITOR             
.byte ORIX_STRCONFIG_MONITOR,$0A,$0D
.endif

.ifdef WITH_MORE           
.byte ORIX_STRCONFIG_MORE,$0A,$0D
.endif

.ifdef WITH_MOUNT       
.byte ORIX_STRCONFIG_MOUNT,$0A,$0D
.endif

.ifdef WITH_SEDSD           
.byte ORIX_STRCONFIG_SEDSD,$0A,$0D
.endif

.ifdef WITH_SH          
.byte ORIX_STRCONFIG_SH,$0A,$0D
.endif

.ifdef WITH_TREE                
.byte ORIX_STRCONFIG_TREE,$0A,$0D
.endif         

.ifdef WITH_TWILIGHTE_BOARD
.byte ORIX_STRCONFIG_TWILIGHTE_BOARD,$0A,$0D
.endif

.ifdef WITH_VI 
.byte ORIX_STRCONFIG_VI,$0A,$0D
.endif

.ifdef WITH_XA                
.byte ORIX_STRCONFIG_XA,$0A,$0D
.endif

.ifdef WITH_XORIX         
.byte ORIX_STRCONFIG_XORIX,$0A,$0D
.endif
.byt 0
.endproc


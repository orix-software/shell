# Command: Monitor

### Start monitor

## SYNOPSYS
+ monitor

## DESCRIPTION
Start monitor.

+ BYTES adrdeb, val1 (,val2,...) : set val1, val2 at adrdeb adress (val1, val2, adrden can be labels or expressions)
+ (L)DESAS adrdeb (,adrfin) (B val) : désassemble le programme à partir de l'adress adrdeb de la banque indiquée, ou celle par défaut, jusqu'à adrfin si précisée
+ (L)DUMP adrdeb (,adrfin) (,B val) : affiche un dump de la mémoire depuis l'adress adrdeb de la banque indiquée, ou celle par défaut, jusqu'à adrfin si précisée
+ TRACE adrdeb (,S adrstop) (,E) (,H) (,N) (,A val) (...) (,B val) : exécute une routine en mode trace
- MODIF adrdeb (,B val) : modification pleine page de la mémoire à partir de l'adresse adrdeb de la banque indiquée ou celle par défaut

## SOURCE
https://github.com/orix-software/monitor/

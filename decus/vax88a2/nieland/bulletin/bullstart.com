$ RUN SYS$SYSTEM:INSTALL
SYS$SYSTEM:BULLETIN/SHAR/OPEN/HEAD/PRIV=(OPER,SYSPRV,CMKRNL,WORLD,DETACH,PRMMBX)
/EXIT
$ BULL*ETIN :== $SYS$SYSTEM:BULLETIN
$ BULLETIN/STARTUP

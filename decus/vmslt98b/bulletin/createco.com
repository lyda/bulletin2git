$ FQ = ""
$ IF F$GETSYI("HW_MODEL") .GT. 1023 THEN FQ = "/SEPARATE_COMPILATION"
$ IF F$GETSYI("VP_MASK") .NE. 0 THEN FQ = FQ + "/NOHPO"
$ FORTRAN/NOWARN/EXTEND/CHECK=(NOBOUNDS,OVERFLOW,NOUNDERFLOW)'FQ' BULLETIN
$ FORTRAN/NOWARN/EXTEND/CHECK=(NOBOUNDS,OVERFLOW,NOUNDERFLOW)'FQ' BULLETIN0
$ FORTRAN/NOWARN/EXTEND/CHECK=(NOBOUNDS,OVERFLOW,NOUNDERFLOW)'FQ' BULLETIN1
$ FORTRAN/NOWARN/EXTEND/CHECK=(NOBOUNDS,OVERFLOW,NOUNDERFLOW)'FQ' BULLETIN2
$ FORTRAN/NOWARN/EXTEND/CHECK=(NOBOUNDS,OVERFLOW,NOUNDERFLOW)'FQ' BULLETIN3
$ FORTRAN/NOWARN/EXTEND/CHECK=(NOBOUNDS,OVERFLOW,NOUNDERFLOW)'FQ' BULLETIN4
$ FORTRAN/NOWARN/EXTEND/CHECK=(NOBOUNDS,OVERFLOW,NOUNDERFLOW)'FQ' BULLETIN5
$ FORTRAN/NOWARN/EXTEND/CHECK=(NOBOUNDS,OVERFLOW,NOUNDERFLOW)'FQ' BULLETIN6
$ FORTRAN/NOWARN/EXTEND/CHECK=(NOBOUNDS,OVERFLOW,NOUNDERFLOW)'FQ' BULLETIN7
$ FORTRAN/NOWARN/EXTEND/CHECK=(NOBOUNDS,OVERFLOW,NOUNDERFLOW)'FQ' BULLETIN8
$ FORTRAN/NOWARN/EXTEND/CHECK=(NOBOUNDS,OVERFLOW,NOUNDERFLOW)'FQ' BULLETIN9
$ FORTRAN/NOWARN/EXTEND/CHECK=(NOBOUNDS,OVERFLOW,NOUNDERFLOW)'FQ' BULLETIN10
$ FORTRAN/NOWARN/EXTEND/CHECK=(NOBOUNDS,OVERFLOW,NOUNDERFLOW)'FQ' BULLETIN11
$ IF F$GETSYI("HW_MODEL") .LE. 1023 THEN MAC ALLMACS
$ IF F$GETSYI("HW_MODEL") .GT. 1023 THEN MAC ALLMACS_AXP
$ SET COMMAND/OBJ BULLCOM
$ SET COMMAND/OBJ BULLMAIN
$ CCQ = ""
$ IF F$GETSYI("HW_MODEL") .GT. 1023 THEN CCQ = "/STAN=VAX"
$ ON WARNING THEN GOTO DUMMY
$ IF F$TRNLNM("MULTINET_SOCKET_LIBRARY") .NES. "" THEN GOTO MULTI
$ IF F$TRNLNM("TWG$TCP") .EQS. "" THEN GOTO MULTI
$ DEFINE VAXC$INCLUDE TWG$TCP:[NETDIST.INCLUDE],-
                      TWG$TCP:[NETDIST.INCLUDE.SYS],-
                      TWG$TCP:[NETDIST.INCLUDE.VMS],-
                      TWG$TCP:[NETDIST.INCLUDE.NETINET],-
                      TWG$TCP:[NETDIST.INCLUDE.ARPA],-
                      SYS$LIBRARY
$ CC'CCQ' BULL_NEWS/DEFINE=(TWG=1)
$ GOTO LINK
$MULTI:
$ IF F$TRNLNM("MULTINET_SOCKET_LIBRARY") .EQS. "" THEN GOTO UCX
$ CC'CCQ' BULL_NEWS/DEFINE=(MULTINET=1)
$ GOTO LINK
$UCX:
$ IF F$TRNLNM("UCX$DEVICE") .EQS. "" THEN GOTO CMU
$ CC'CCQ' BULL_NEWS/DEFINE=(UCX=1)
$ GOTO LINK
$CMU:
$ CC'CCQ' BULL_NEWS
$ GOTO LINK
$DUMMY:
$ WRITE SYS$OUTPUT "There is no C compiler available for the NEWS software."
$ WRITE SYS$OUTPUT "BULLETIN will be assembled without that feature."
$ FORTRAN BULL_NEWSDUMMY
$LINK:
$ SET NOON
$ IF F$SEARCH("BULL_DIR:READ_BOARD.COM") .NES. "" THEN-
  DELETE BULL_DIR:READ_BOARD.COM;*
$ IF F$SEARCH("BULL.OLB") .NES. "" THEN DELETE BULL.OLB;*
$ IF F$SEARCH("BULL.OLB") .EQS. "" THEN LIBRARY/CREATE BULL
$ LIBRARY BULL *.OBJ;
$ DELETE *.OBJ;*
$! @BULLETIN.LNK

From:	CSBVAX::MRGATE!MRL%PFC-VAX.MIT.EDU%XX.LCS.MIT.EDU@EDDIE.MIT.EDU@SMTP 16-AUG-1988 17:17
To:	ARISIA::EVERHART
Subj:	BULLETIN8.FOR


Received: from deep-thought.mit.edu by EDDIE.MIT.EDU via Chaosnet with MAIL with sendmail-5.45/4.7 id <AA05581@EDDIE.MIT.EDU>; Tue, 16 Aug 8
8 10:45:00 EDT
Message-Id: <8808161445.AA05581@EDDIE.MIT.EDU>
Received: from PFC-VAX.MIT.EDU by DEEP-THOUGHT.MIT.EDU via Chaosnet; 16 Aug 88 10:44-EDT
Date: 16 Aug 88 10:44:13 EDT
From: MRL%PFC-VAX.MIT.EDU%XX.LCS.MIT.EDU@EDDIE.MIT.EDU
To: TENCATI@VLSI.JPL.NASA.GOV@EE, MHG@MITRE-BEDFORD.ARPA@EE,
        EVERHART%ARISIA.DECNET@GE-CRD.ARPA@EE, GAYMAN@ARI-HQ1.ARPA@EE
Subject: BULLETIN8.FOR

C
C  BULLETIN8.FOR, Version 8/9/88
C  Purpose: Contains subroutines for the bulletin board utility program.
C  Environment: MIT PFC VAX-11/780, VMS
C  Programmer: Mark R. London
C
	SUBROUTINE START_DECNET

	IMPLICIT INTEGER (A - Z)

	CHARACTER NAMEDESC*9 /'BULLETIN1'/

	COMMON /CHANNEL/ MBX_CHAN,DCL_CHAN

	COMMON /MBXBUF/ MBX_IOSB(4),MBX_BUF(132)	! Buffer area for
	INTEGER*2 MBX_IOSB				! terminal QIO calls.
	LOGICAL*1 MBX_BUF

	PARAMETER MAXLINK = 10

	COMMON /READBUF/ READ_IOSB(4,MAXLINK),READ_BUF(200,MAXLINK)
	COMMON /READBUF/ DEVS(MAXLINK),UNITS(MAXLINK),READ_EFS(MAXLINK),COUNT
	INTEGER*2 READ_IOSB
	LOGICAL*1 READ_BUF

	COMMON /PROCBUF/ WRITE_IOSB(4,MAXLINK),WRITE_BUF(256,MAXLINK)
	COMMON /PROCBUF/ WRITE_EFS(MAXLINK)
	INTEGER*2 WRITE_IOSB
	LOGICAL*1 WRITE_BUF

	DIMENSION NFBDESC(2)
	LOGICAL*1 NFB(5)

	EXTERNAL IO$_ACPCONTROL

	PARAMETER NFB$C_DECLNAME = '15'X

	CALL SETDEFAULT('DECNET')

C	CALL SET_TIMER('02')

	IER = SYS$CREMBX(%VAL(0),MBX_CHAN,%VAL(132),%VAL(528),,,
     &                   'BULL_MBX')
	IF (.NOT.IER) CALL EXIT(IER)

	IER = SYS$ASSIGN('_NET:',DCL_CHAN,,'BULL_MBX')	! Assign net device
	IF (.NOT.IER) CALL EXIT(IER)

	NFBDESC(1) = 5
	NFBDESC(2) = %LOC(NFB)

	NFB(1) = NFB$C_DECLNAME

	IER = SYS$QIOW(,%VAL(DCL_CHAN),IO$_ACPCONTROL,,,,
     &		NFBDESC,NAMEDESC,,,,)
	IF (.NOT.IER) CALL EXIT(IER)

	DO I=1,MAXLINK
	   CALL LIB$GET_EF(READ_EFS(I))
	   CALL LIB$GET_EF(WRITE_EFS(I))
	END DO

	CALL READ_MBX

	RETURN
	END


	SUBROUTINE SETDEFAULT(USERNAME)

	IMPLICIT INTEGER (A-Z)

	INCLUDE '($LNMDEF)'

	INCLUDE '($PSLDEF)'

	INCLUDE '($UAIDEF)'

	CHARACTER DEFDIR*64,DEFDEV*16,USERNAME*(*),ACCOUNT*9

	INTEGER*2 UIC(2)

	CALL INIT_ITMLST
	CALL ADD_2_ITMLST(LEN(DEFDEV),UAI$_DEFDEV,%LOC(DEFDEV))
	CALL ADD_2_ITMLST(LEN(DEFDIR),UAI$_DEFDIR,%LOC(DEFDIR))
	CALL ADD_2_ITMLST(LEN(ACCOUNT),UAI$_ACCOUNT,%LOC(ACCOUNT))
	CALL ADD_2_ITMLST(4,UAI$_UIC,%LOC(UIC))
	CALL END_ITMLST(GETUAI_ITMLST)

	CALL SYS$GETUAI(,,USERNAME,%VAL(GETUAI_ITMLST),,,)

	CALL SETACC(ACCOUNT)
	CALL SETUSER(USERNAME)
	CALL SETUIC(INT(UIC(2)),INT(UIC(1)))

	CALL INIT_ITMLST	! Initialize item list
				! Now add items to list
	CALL ADD_2_ITMLST
     &		(ICHAR(DEFDEV(:1)),LNM$_STRING,%LOC(DEFDEV(2:)))
	CALL END_ITMLST(CRELNM_ITMLST)	! Get address of itemlist

	CALL SYS$CRELNM(,'LNM$PROCESS','SYS$DISK',PSL$C_SUPER,
     &						%VAL(CRELNM_ITMLST))

	CALL SYS$SETDDIR(DEFDIR(2:ICHAR(DEFDIR(:1))+1),,)

	RETURN
	END



	SUBROUTINE READ_MBX

	IMPLICIT INTEGER (A-Z)

	COMMON /CHANNEL/ MBX_CHAN,DCL_CHAN

	COMMON /MBXBUF/ MBX_IOSB(4),MBX_BUF(132)	! Buffer area for
	INTEGER*2 MBX_IOSB				! terminal QIO calls.
	LOGICAL*1 MBX_BUF

	EXTERNAL MBX_AST

	EXTERNAL IO$_READVBLK

	DATA MBX_EF/0/

	IF (MBX_EF.EQ.0) CALL LIB$GET_EF(MBX_EF)

	IER = SYS$QIO(%VAL(MBX_EF),%VAL(MBX_CHAN),IO$_READVBLK,MBX_IOSB,
     &		MBX_AST,,MBX_BUF,%VAL(132),,,,)
	IF (.NOT.IER) CALL EXIT(IER)

	RETURN

	END




	SUBROUTINE MBX_AST

	IMPLICIT INTEGER (A-Z)

	INCLUDE '($MSGDEF)'

	INCLUDE 'BULLUSER.INC'

	PARAMETER MAXLINK = 10

	COMMON /READBUF/ READ_IOSB(4,MAXLINK),READ_BUF(200,MAXLINK)
	COMMON /READBUF/ DEVS(MAXLINK),UNITS(MAXLINK),READ_EFS(MAXLINK),COUNT
	INTEGER*2 READ_IOSB
	LOGICAL*1 READ_BUF

	COMMON /CHANNEL/ MBX_CHAN,DCL_CHAN

	COMMON /MBXBUF/ MBX_IOSB(4),MBX_BUF(132)	! Buffer area for
	INTEGER*2 MBX_IOSB				! terminal QIO calls.
	LOGICAL*1 MBX_BUF

	INTEGER*2 MBXMSG,UNIT2

	EQUIVALENCE (MBX_BUF(1),MBXMSG)

	CHARACTER NODENAME*6,FROMNAME*12

	IF (MBXMSG.EQ.MSG$_CONNECT.AND.MBX_IOSB(1)) THEN
	   LNODE = 0
	   DO WHILE (MBX_BUF(10+LNODE).NE.':')
	      LNODE = LNODE + 1
	      NODENAME(LNODE:LNODE) = CHAR(MBX_BUF(9+LNODE))
	   END DO
	   DO I=LNODE+1,LEN(NODENAME)
	      NODENAME(I:I) = ' '
	   END DO
	   I = 10 + LNODE
	   DO WHILE (MBX_BUF(I).NE.'=')
	      I = I + 1
	   END DO
	   LUSER = 0
	   DO WHILE (MBX_BUF(I+LUSER+1).NE.' '.AND.
     &		     MBX_BUF(I+LUSER+1).NE.'/')
	      LUSER = LUSER + 1
	      USERNAME(LUSER:LUSER) = CHAR(MBX_BUF(I+LUSER))
	   END DO
	   DO I=LUSER+1,LEN(USERNAME)
	      USERNAME(I:I) = ' '
	   END DO
	   FROMNAME = USERNAME
	   CALL GET_PROXY_USERNAME(NODENAME,USERNAME)
	   CALL CONNECT(NODENAME,USERNAME,FROMNAME)
	ELSE IF ((MBXMSG.EQ.MSG$_INTMSG.OR.MBXMSG.EQ.MSG$_REJECT.OR.
     &		 MBXMSG.EQ.MSG$_CONFIRM).AND.MBX_IOSB(1)) THEN
	   CALL READ_MBX
	ELSE
	   CALL LIB$MOVC3(2,MBX_BUF(3),UNIT2)
	   UNIT_INDEX = 1
	   DO WHILE (UNIT_INDEX.LE.MAXLINK.AND.UNITS(UNIT_INDEX).NE.UNIT2)
	      UNIT_INDEX = UNIT_INDEX + 1
	   END DO
	   IF (UNIT_INDEX.LE.MAXLINK) CALL DISCONNECT(UNIT_INDEX)
	   CALL READ_MBX
	END IF

	RETURN
	END




	SUBROUTINE READ_CHAN(CHAN,UNIT_INDEX)

	IMPLICIT INTEGER (A-Z)

	PARAMETER MAXLINK = 10

	COMMON /READBUF/ READ_IOSB(4,MAXLINK),READ_BUF(200,MAXLINK)
	COMMON /READBUF/ DEVS(MAXLINK),UNITS(MAXLINK),READ_EFS(MAXLINK),COUNT
	INTEGER*2 READ_IOSB
	LOGICAL*1 READ_BUF

	EXTERNAL READ_AST

	EXTERNAL IO$_READVBLK

	IER = SYS$QIO(%VAL(READ_EFS(UNIT_INDEX)),%VAL(CHAN),IO$_READVBLK,
     &	   READ_IOSB(1,UNIT_INDEX),READ_AST,
     &	   %VAL(UNIT_INDEX),READ_BUF(1,UNIT_INDEX),%VAL(200),,,,)

	RETURN

	END




	SUBROUTINE WRITE_CHAN(NUM,OUTPUT,UNIT_INDEX,IER)

	IMPLICIT INTEGER (A-Z)

	PARAMETER MAXLINK = 10

	COMMON /READBUF/ READ_IOSB(4,MAXLINK),READ_BUF(200,MAXLINK)
	COMMON /READBUF/ DEVS(MAXLINK),UNITS(MAXLINK),READ_EFS(MAXLINK),COUNT
	INTEGER*2 READ_IOSB
	LOGICAL*1 READ_BUF

	COMMON /PROCBUF/ WRITE_IOSB(4,MAXLINK),WRITE_BUF(256,MAXLINK)
	COMMON /PROCBUF/ WRITE_EFS(MAXLINK)
	INTEGER*2 WRITE_IOSB
	LOGICAL*1 WRITE_BUF

	CHARACTER*(*) OUTPUT

	EXTERNAL IO$_WRITEVBLK, WRITE_AST

	CALL LIB$MOVC3(NUM,%REF(OUTPUT),WRITE_BUF(1,UNIT_INDEX))

	IER = SYS$QIO(%VAL(WRITE_EFS(UNIT_INDEX)),
     &	   %VAL(DEVS(UNIT_INDEX)),
     &	   IO$_WRITEVBLK,WRITE_IOSB(1,UNIT_INDEX),WRITE_AST,
     &	   %VAL(UNIT_INDEX),WRITE_BUF(1,UNIT_INDEX),%VAL(NUM),,,,)

	IF (IER.AND.WRITE_IOSB(1,UNIT_INDEX).NE.0) THEN
	   IER = WRITE_IOSB(1,UNIT_INDEX)
	END IF

	RETURN

	END




	SUBROUTINE WRITE_AST(ASTPRM)

	IMPLICIT INTEGER (A-Z)

	PARAMETER MAXLINK = 10

	COMMON /PROCBUF/ WRITE_IOSB(4,MAXLINK),WRITE_BUF(256,MAXLINK)
	COMMON /PROCBUF/ WRITE_EFS(MAXLINK)
	INTEGER*2 WRITE_IOSB
	LOGICAL*1 WRITE_BUF

	COMMON /CONNECT_STATUS/ FOLDER_NUM(MAXLINK),OUT_NUM(MAXLINK)
	COMMON /CONNECT_STATUS/ USER_SAVE(MAXLINK),FOLDER_NAME(MAXLINK)
	COMMON /CONNECT_STATUS/ FROM_SAVE(MAXLINK),PRIV_SAVE(2,MAXLINK)
	COMMON /CONNECT_STATUS/ NODE_SAVE(MAXLINK),OUT_SAVE(MAXLINK)
	COMMON /CONNECT_STATUS/ REC_SAVE(MAXLINK),LEN_SAVE(MAXLINK)
	COMMON /CONNECT_STATUS/ LAST_SAVE(2,MAXLINK)
	CHARACTER USER_SAVE*12,FOLDER_NAME*25,FROM_SAVE*12,NODE_SAVE*12

	CHARACTER*128 INPUT

	UNIT_INDEX = %LOC(ASTPRM)

	IF (.NOT.WRITE_IOSB(1,UNIT_INDEX)) THEN
	   CALL DISCONNECT(UNIT_INDEX)
	ELSE IF (LEN_SAVE(UNIT_INDEX).GT.0) THEN
	   LEN_SAVE(UNIT_INDEX) = LEN_SAVE(UNIT_INDEX) - 1
	   IF (LEN_SAVE(UNIT_INDEX).EQ.0) THEN
	      IF (REC_SAVE(UNIT_INDEX).EQ.128) THEN
	         REC_SAVE(UNIT_INDEX) = 0
	      ELSE
	         RETURN
	      END IF
	   ELSE
              CALL READ_QUEUE(%VAL(OUT_SAVE(UNIT_INDEX)),
     &		OUT_SAVE(UNIT_INDEX),INPUT)
	   END IF
	   CALL WRITE_CHAN(REC_SAVE(UNIT_INDEX),INPUT,UNIT_INDEX,IER)
	END IFD

	RETURN.
	END



	SUBROUTINE READ_AST(ASTPRM)

	IMPLICIT INTEGER (A-Z)

	PARAMETER MAXLINK = 10h

	COMMON /READBUF/ READ_IOSB(4,MAXLINK),READ_BUF(200,MAXLINK)
	COMMON /READBUF/ DEVS(MAXLINK),UNITS(MAXLINK),READ_EFS(MAXLINK),COUNT
	INTEGER*2 READ_IOSB
	LOGICAL*1 READ_BUFD

	COMMON /ACTIVITY/ IO(MAXLINK),IO_SAVE(MAXLINK)M

	UNIT_INDEX = %LOC(ASTPRM)

	IF (.NOT.READ_IOSB(1,UNIT_INDEX)) RETURNm

	IO(UNIT_INDEX) = IO(UNIT_INDEX) + 1

	CALL EXECUTE_COMMAND(UNIT_INDEX).

	CALL READ_CHAN(DEVS(UNIT_INDEX),UNIT_INDEX)

	RETURN.
	END





	SUBROUTINE CONNECT(NODENAME,USERNAME,FROMNAME)8

	IMPLICIT INTEGER (A-Z)R

	COMMON /ANY_ACTIVITY/ CONNECT_COUNT
	DATA CONNECT_COUNT /0/i

	CHARACTER*(*) USERNAME,FROMNAME

	EXTERNAL IO$_ACCESS,IO$M_ABORTP

	CONNECT_COUNT = CONNECT_COUNT + 1

	IO_REJECT = %LOC(IO$_ACCESS)+%LOC(IO$M_ABORT)

	CALL CONNECT_ACCEPT(REJECT,CHAN,UNIT_INDEX,
     &		NODENAME,USERNAME,FROMNAME)M

	IF (REJECT.NE.IO_REJECT) THEN
	   CALL READ_CHAN(CHAN,UNIT_INDEX)X
	END IF!

	CALL READ_MBX

	RETURNL
	END


	SUBROUTINE CONNECT_ACCEPT(REJECT,CHAN,UNIT_INDEX,
     &		NODENAME,USERNAME,FROMNAME)N

	IMPLICIT INTEGER (A-Z)M

	COMMON /CHANNEL/ MBX_CHAN,DCL_CHAN)

	COMMON /MBXBUF/ MBX_IOSB(4),MBX_BUF(132)	! Buffer area forP
	INTEGER*2 MBX_IOSB				! terminal QIO calls.
	LOGICAL*1 MBX_BUF

	PARAMETER MAXLINK = 10I

	COMMON /PROCBUF/ WRITE_IOSB(4,MAXLINK),WRITE_BUF(256,MAXLINK)
	COMMON /PROCBUF/ WRITE_EFS(MAXLINK)
	INTEGER*2 WRITE_IOSBT
	LOGICAL*1 WRITE_BUF

	COMMON /READBUF/ READ_IOSB(4,MAXLINK),READ_BUF(200,MAXLINK)
	COMMON /READBUF/ DEVS(MAXLINK),UNITS(MAXLINK),READ_EFS(MAXLINK),COUNT
	INTEGER*2 READ_IOSB
	LOGICAL*1 READ_BUFL
	DATA COUNT /0/I

	COMMON /CONNECT_STATUS/ FOLDER_NUM(MAXLINK),OUT_NUM(MAXLINK)
	COMMON /CONNECT_STATUS/ USER_SAVE(MAXLINK),FOLDER_NAME(MAXLINK)
	COMMON /CONNECT_STATUS/ FROM_SAVE(MAXLINK),PRIV_SAVE(2,MAXLINK)
	COMMON /CONNECT_STATUS/ NODE_SAVE(MAXLINK),OUT_SAVE(MAXLINK)I
	COMMON /CONNECT_STATUS/ REC_SAVE(MAXLINK),LEN_SAVE(MAXLINK)
	COMMON /CONNECT_STATUS/ LAST_SAVE(2,MAXLINK)_
	CHARACTER USER_SAVE*12,FOLDER_NAME*25,FROM_SAVE*12,NODE_SAVE*12

	EXTERNAL IO$_ACCESS,IO$M_ABORTI

	CHARACTER*(*) USERNAME,FROMNAME,NODENAME

	CHARACTER*100 NCBDESC

	START_NCB = 7+MBX_BUF(5)T

	LEN_NCB = MBX_BUF(START_NCB-1),

	CALL LIB$MOVC3(LEN_NCB,MBX_BUF(START_NCB),%REF(NCBDESC)) 

	IF (COUNT.GT.MAXLINK) THENE
	   REJECT = %LOC(IO$_ACCESS)+%LOC(IO$M_ABORT)
	   CHAN = DCL_CHANE
	ELSE
	   IER = SYS$ASSIGN('_NET:',DEV_CHAN,,'BULL_MBX')

	   IF (IER) CALL GETDEVUNIT(DEV_CHAN,DEV_UNIT,IER)L

	   IF (IER) THENT
	      CHAN = DEV_CHAN
	      REJECT = %LOC(IO$_ACCESS)

	      UNIT_INDEX = 1U
	      DO WHILE (UNIT_INDEX.LE.MAXLINK.AND.UNITS(UNIT_INDEX).GT.0.)
	          UNIT_INDEX = UNIT_INDEX + 1
	      END DO 
	   ELSE
	      CALL SYS$DASSGN(%VAL(DEV_CHAN))
	   END IF

	   IF (.NOT.IER.OR.UNIT_INDEX.GT.MAXLINK) THENT
	      REJECT = %LOC(IO$_ACCESS)+%LOC(IO$M_ABORT) 
	      CHAN = DCL_CHAN
	   ELSE
	      COUNT = COUNT + 1
	      UNITS(UNIT_INDEX) = DEV_UNIT$
	      DEVS(UNIT_INDEX) = DEV_CHAN
	      USER_SAVE(UNIT_INDEX) = USERNAME 
	      FROM_SAVE(UNIT_INDEX) = FROMNAMEC
	      NODE_SAVE(UNIT_INDEX) = NODENAMEM
	      FOLDER_NUM(UNIT_INDEX) = -1
	      LEN_SAVE(UNIT_INDEX) = 0M
	      PRIV_SAVE(1,UNIT_INDEX) = 0
	      PRIV_SAVE(2,UNIT_INDEX) = 0
	   END IF
	END IFE

	IER = SYS$QIOW(,%VAL(CHAN),%VAL(REJECT),MBX_IOSB,,,
     &		,NCBDESC(:LEN_NCB),,,,)O

	IF (REJECT.EQ.%LOC(IO$_ACCESS).AND.
     &		(.NOT.IER.OR..NOT.MBX_IOSB(1))) THEN
	   REJECT = %LOC(IO$_ACCESS)+%LOC(IO$M_ABORT)
	   COUNT = COUNT - 1S
	   DEVS(UNIT_INDEX) = 0
	   UNITS(UNIT_INDEX) = 0C
	END IFS

	RETURNI
	END



	SUBROUTINE GETDEVUNIT(CHAN,DEV_UNIT,IER)C
CO
C  SUBROUTINE GETDEVUNIT
CN
C  FUNCTION:
C	To get device unit number 
C  INPUT:K
C	CHAN - Channel number(
C  OUTPUT:
C	DEV_UNIT - Device unit numberL
CR

	IMPLICIT INTEGER (A-Z)L

	INCLUDE '($DVIDEF)'

	CALL INIT_ITMLST	! Initialize item list
				! Now add items to listM
	CALL ADD_2_ITMLST(4,DVI$_UNIT,%LOC(DEV_UNIT))
	CALL END_ITMLST(GETDVI_ITMLST)	! Get address of itemlist)

	IER = SYS$GETDVIW(,%VAL(CHAN),,%VAL(GETDVI_ITMLST),,,,)

	RETURNO
	END



	SUBROUTINE GETDEVNAME(CHAN,DEV_NAME,DLEN,IER)
C_
C  SUBROUTINE GETDEVMAME
C 
C  FUNCTION:
C	To get device name
C  INPUT:)
C	CHAN - Channel number
C  OUTPUT:
C	DEV_NAME - Device name
C	DLEN - Length of device name
C

	IMPLICIT INTEGER (A-Z)O

	INCLUDE '($DVIDEF)'

	CHARACTER*(*) DEV_NAME+

	CALL INIT_ITMLST	! Initialize item list
				! Now add items to listN
	CALL ADD_2_ITMLST_WITH_RETS
     &		(LEN(DEV_NAME),DVI$_DEVNAM,%LOC(DEV_NAME),%LOC(DLEN)):
	CALL END_ITMLST(GETDVI_ITMLST)	! Get address of itemlistR

	IER = SYS$GETDVIW(,%VAL(CHAN),,%VAL(GETDVI_ITMLST),,,,)

	RETURN=
	END



	SUBROUTINE DISCONNECT(UNIT_INDEX)
CE
C  SUBROUTINE DISCONNECT
CN
C  FUNCTION: Disconnects channel and remove its entry from the lists.S
CR

	IMPLICIT INTEGER (A-Z).

	PARAMETER MAXLINK = 10S

	COMMON /READBUF/ READ_IOSB(4,MAXLINK),READ_BUF(200,MAXLINK)
	COMMON /READBUF/ DEVS(MAXLINK),UNITS(MAXLINK),READ_EFS(MAXLINK),COUNT
	INTEGER*2 READ_IOSB
	LOGICAL*1 READ_BUFI

	COMMON /MBXBUF/ MBX_IOSB(4),MBX_BUF(132)	! Buffer area forL
	INTEGER*2 MBX_IOSB				! terminal QIO calls.
	LOGICAL*1 MBX_BUF

	IF (UNITS(UNIT_INDEX).EQ.0) RETURND

	CALL SYS$DASSGN(%VAL(DEVS(UNIT_INDEX)))

	CALL UPDATE_REMOTE_USERINFO(UNIT_INDEX)

	COUNT = COUNT - 1
	DEVS(UNIT_INDEX) = 0,
	UNITS(UNIT_INDEX) = 0

	RETURNX
	END



	SUBROUTINE SET_TIMER(MIN)
CT
C SUBROUTINE SET_TIMER
CG
C FUNCTION: Wakes up every MIN minutes to check for idle connections
C=
	IMPLICIT INTEGER (A-Z)I
	INTEGER TIMADR(2)			! Buffer containing timeE
						! in desired system format. 
	CHARACTER TIMBUF*13,MIN*2
	DATA TIMBUF/'0 00:00:00.00'/,

	EXTERNAL CHECK_CONNECTIONS

	CALL LIB$GET_EF(WAITEFN)T

	TIMBUF(6:7) = MIN

	IER=SYS$BINTIM(TIMBUF,TIMADR)

	ENTRY RESET_TIMER

	IER=SYS$SETIMR(%VAL(WAITEFN),TIMADR,CHECK_CONNECTIONS,)
						! Set timer.

	RETURNI
	END




	SUBROUTINE CHECK_CONNECTIONSI

	IMPLICIT INTEGER (A-Z)L

	PARAMETER MAXLINK = 10O

	COMMON /ACTIVITY/ IO(MAXLINK),IO_SAVE(MAXLINK)

	COMMON /READBUF/ READ_IOSB(4,MAXLINK),READ_BUF(200,MAXLINK)
	COMMON /READBUF/ DEVS(MAXLINK),UNITS(MAXLINK),READ_EFS(MAXLINK),COUNT
	INTEGER*2 READ_IOSB
	LOGICAL*1 READ_BUFU

	IF (COUNT.GT.0) THEN)
	   DO UNIT_INDEX=1,MAXLINKT
	      IF (DEVS(UNIT_INDEX).NE.0.AND.V
     &		IO(UNIT_INDEX).EQ.IO_SAVE(UNIT_INDEX)) THEN1
	         CALL DISCONNECT(UNIT_INDEX)L
	      END IFI
	   END DO
	END IF%

	CALL RESET_TIMER 

	RETURNI
	END



	SUBROUTINE GET_USER_PRIV(USERNAME,PRIV)

	IMPLICIT INTEGER (A-Z)

	DIMENSION PRIV(2)

	CHARACTER USERNAME*(*)S

	INCLUDE '($UAIDEF)'

	INTEGER*2 UIC(2)T

	CALL INIT_ITMLSTC
	CALL ADD_2_ITMLST(8,UAI$_PRIV,%LOC(PRIV))
	CALL END_ITMLST(GETUAI_ITMLST)F

	IER = SYS$GETUAI(,,USERNAME,%VAL(GETUAI_ITMLST),,,)

	IF (.NOT.IER) THENC
	   USERNAME = 'DECNET'(
	   IER = SYS$GETUAI(,,USERNAME,%VAL(GETUAI_ITMLST),,,)_
	END IFI

	RETURNN
	END





	SUBROUTINE GET_PROXY_USERNAME(NODE,USERNAME)S

	IMPLICIT INTEGER (A-Z)N

	CHARACTER NODE*(*),USERNAME*(*)

	CHARACTER NETUAF*100C

	COMMON /NETUAF/ NETUAF_QUEUE,NETUAF_NUM

	LNODE = LEN(NODE)
	LUSER = LEN(USERNAME)

	NUM = 1
	NENTRY = NETUAF_QUEUE

	DO WHILE (NUM.LE.NETUAF_NUM)V
	   NUM = NUM + 11
	   CALL READ_QUEUE(%VAL(NENTRY),NENTRY,NETUAF)O
	   IF ((NETUAF(:1).EQ.'*'.OR.NETUAF(:LNODE).EQ.NODE).AND.
     &	       (NETUAF(33:32+LUSER).EQ.USERNAME.OR.
     &	       NETUAF(65:65).EQ.'*')) THEND
	      IF (NETUAF(65:65).NE.'*') USERNAME = NETUAF(65:) 
	      RETURNN
	   END IF
	END DON

	USERNAME = 'DECNET'

	RETURN0
	END





	SUBROUTINE GET_PROXY_ACCOUNTS

	IMPLICIT INTEGER (A-Z)A

	CHARACTER NETUAF*656V

	COMMON /NETUAF/ NETUAF_QUEUE,NETUAF_NUM
	DATA NETUAF_QUEUE/0/

	CALL INIT_QUEUE(NETUAF_QUEUE,NETUAF)I

	OPEN (UNIT=7,FILE='NETPROXY',DEFAULTFILE='SYS$SYSTEM:NETPROXY.DAT',
     &       ACCESS='KEYED',FORM='FORMATTED',ORGANIZATION='INDEXED',
     &       STATUS='OLD',READONLY,SHARED,IOSTAT=IER)A

	FORMAT = 0 

	IF (IER.NE.0) THEN,
	   OPEN (UNIT=7,FILE='NETUAF',DEFAULTFILE='SYS$SYSTEM:NETUAF.DAT',L
     &       ACCESS='KEYED',FORM='FORMATTED',ORGANIZATION='INDEXED',
     &       STATUS='OLD',READONLY,SHARED,IOSTAT=IER)I
	   FORMAT = 1
	END IFT

	NETUAF_NUM = 0N
	NENTRY = NETUAF_QUEUE
	DO WHILE (IER.EQ.0)
	   READ (7,'(Q,A)',IOSTAT=IER) NLEN,NETUAFE
	   IF (IER.EQ.0) THEN
	      NETUAF_NUM = NETUAF_NUM + 1
	      IF (FORMAT.EQ.0) THEN
		 NETUAF = NETUAF(13:)M
		 NLEN = NLEN - 12N
		 DO WHILE (NETUAF(67:67).NE.CHAR(1).AND.NLEN.GT.64)U
		    SKIP = 4 + ICHAR(NETUAF(65:65))S
		    NETUAF(65:) = NETUAF(65+SKIP:)
		    NLEN = NLEN - SKIP
		 END DO_
		 IF (NLEN.GT.64) THEN
		    ULEN = ICHAR(NETUAF(65:65))U
		    NETUAF(65:) = NETUAF(69:)N
		    DO I=65+ULEN,76R
		       NETUAF(I:I) = ' '
		    END DO
		 ELSEN
		    NETUAF(65:) = 'DECNET'
		 END IF
	      END IF
              CALL WRITE_QUEUE(%VAL(NENTRY),NENTRY,NETUAF(:100))
	   END IF
	END DOA

	CLOSE (UNIT=7)N

	RETURNM

	END




	SUBROUTINE EXECUTE_COMMAND(UNIT_INDEX)U

	IMPLICIT INTEGER (A-Z)	

	INCLUDE 'BULLFILES.INC'

	INCLUDE 'BULLFOLDER.INC' 

	INCLUDE 'BULLDIR.INC'

	INCLUDE 'BULLUSER.INC'I

	PARAMETER MAXLINK = 10_

	COMMON /READBUF/ READ_IOSB(4,MAXLINK),READ_BUF(200,MAXLINK)
	COMMON /READBUF/ DEVS(MAXLINK),UNITS(MAXLINK),READ_EFS(MAXLINK),COUNT
	INTEGER*2 READ_IOSB
	LOGICAL*1 READ_BUFA

	COMMON /CONNECT_STATUS/ FOLDER_NUM(MAXLINK),OUT_NUM(MAXLINK)A
	COMMON /CONNECT_STATUS/ USER_SAVE(MAXLINK),FOLDER_NAME(MAXLINK)
	COMMON /CONNECT_STATUS/ FROM_SAVE(MAXLINK),PRIV_SAVE(2,MAXLINK)
	COMMON /CONNECT_STATUS/ NODE_SAVE(MAXLINK),OUT_SAVE(MAXLINK)M
	COMMON /CONNECT_STATUS/ REC_SAVE(MAXLINK),LEN_SAVE(MAXLINK)
	COMMON /CONNECT_STATUS/ LAST_SAVE(2,MAXLINK)A
	CHARACTER USER_SAVE*12,FOLDER_NAME*25,FROM_SAVE*12,NODE_SAVE*12

	COMMON /ACCESS/ READ_ONLY
	LOGICAL READ_ONLY

	COMMON /PRIVILEGES/ PROCPRIV(2),NEEDPRIV(2)

	COMMON /POINT/ BULL_POINT

	COMMON /REMOTE_FOLDER/ REMOTE_SET,REMOTE_UNIT

	COMMON /BROAD_MESSAGE/ BMESSAGE,BLENGTH

	PARAMETER BRDCST_LIMIT = 82*12 + 2B
	CHARACTER*(BRDCST_LIMIT) BMESSAGE

	DIMENSION SCRATCH(MAXLINK),OUT_HEAD(MAXLINK)U
	DATA SCRATCH/MAXLINK*0/,OUT_HEAD/MAXLINK*0/

	EXTERNAL ENABLE_CTRL_EXIT,SS$_NOSUCHNODE,SS$_NOSUCHOBJR

	PARAMETER TIMEOUT = -10*1000*1000*30 
	DIMENSION TIMEBUF(2)V
	DATA TIMEBUF /TIMEOUT,-1/, TIMEEFN/0/

	CHARACTER INPUT*(FOLDER_RECORD+16),DESCRIP_TEMP*53T
	CHARACTER NODENAME*6,BULLCP_USER*12,INQUEUE*128

	EQUIVALENCE (INPUT,CMD_TYPE),(INPUT,INQUEUE)L

	INTEGER BULLCP_PRIV(2)D

	BULLCP_PRIV(1) = PROCPRIV(1) 
	BULLCP_PRIV(2) = PROCPRIV(2)1

	ILEN = READ_IOSB(2,UNIT_INDEX)C
	CALL LIB$MOVC3(ILEN,READ_BUF(1,UNIT_INDEX),%REF(INPUT))

	REC_SAVE(UNIT_INDEX) = 0)
	USERNAME = USER_SAVE(UNIT_INDEX)C
	FOLDER = FOLDER_NAME(UNIT_INDEX) 
	FOLDER_NUMBER = FOLDER_NUM(UNIT_INDEX)T
	NODENAME = NODE_SAVE(UNIT_INDEX)V
	PROCPRIV(1) = PRIV_SAVE(1,UNIT_INDEX)
	PROCPRIV(2) = PRIV_SAVE(2,UNIT_INDEX)

	CALL INIT_QUEUE(OUT_HEAD(UNIT_INDEX),INQUEUE)

	IF (CMD_TYPE.EQ.3.OR.CMD_TYPE.EQ.4.OR.(CMD_TYPE.GE.9.AND.
     &	    CMD_TYPE.LE.11).OR.CMD_TYPE.EQ.15) THEN	! Do we need priv info?
	   IF (PROCPRIV(1).EQ.0.AND.PROCPRIV(2).EQ.0) THENF
	      CALL GET_USER_PRIV(USERNAME,PRIV_SAVE(1,UNIT_INDEX))S
	      PROCPRIV(1) = PRIV_SAVE(1,UNIT_INDEX)
	      PROCPRIV(2) = PRIV_SAVE(2,UNIT_INDEX)
	   END IF
	END IFB

	IF (CMD_TYPE.EQ.1) THEN			! Select folder
	   FOLDER1 = INPUT(5:ILEN)N
	   FOLDER_NUMBER = -2
	   CALL SELECT_FOLDER(.FALSE.,IER)
	   CALL LIB$MOVC3(4,IER,%REF(INPUT(1:1)))
	   CALL LIB$MOVC3(4,READ_ONLY,%REF(INPUT(5:5)))
	   IF (USERNAME.NE.'DECNET'.AND.IER) THEN
	      CALL OPEN_USERINFOK
	      CALL LIB$MOVC3(8,LAST_READ_BTIM(1,FOLDER_NUMBER+1),
     &				%REF(INPUT(9:9))) 
	      LAST_SAVE(1,UNIT_INDEX) = LAST_READ_BTIM(1,FOLDER_NUMBER+1)
	      LAST_SAVE(2,UNIT_INDEX) = LAST_READ_BTIM(2,FOLDER_NUMBER+1)
	   ELSE
	      CALL LIB$MOVC3(4,0,%REF(INPUT(9:9)))T
	      CALL LIB$MOVC3(4,0,%REF(INPUT(13:13)))V
	   END IF
	   INPUT = INPUT(:16)//FOLDER_COM
	   CALL WRITE_CHAN(16+LEN(FOLDER_COM),INPUT,UNIT_INDEX,IER1))
	   IF (IER.AND.IER1) THEN
	      FOLDER_NAME(UNIT_INDEX) = FOLDERe
	      FOLDER_NUM(UNIT_INDEX) = FOLDER_NUMBERU
	   END IF
	ELSE IF (CMD_TYPE.EQ.2) THEN		! Add message
	   LEN_SAVE(UNIT_INDEX) = 0
	   OUT_SAVE(UNIT_INDEX) = OUT_HEAD(UNIT_INDEX)V
	ELSE IF (CMD_TYPE.EQ.6) THEN		! Add message line
	   LEN_SAVE(UNIT_INDEX) = LEN_SAVE(UNIT_INDEX) + 1_
	   CALL WRITE_QUEUE(%VAL(OUT_SAVE(UNIT_INDEX)),
     &			OUT_SAVE(UNIT_INDEX),INPUT(5:132))T
	ELSE IF (CMD_TYPE.EQ.3) THEN		! Add message entry
	   FROM = USER_SAVE(UNIT_INDEX)
	   IF (FROM.EQ.'DECNET') FROM = FROM_SAVE(UNIT_INDEX)
	   CALL LIB$MOVC3(53,%REF(INPUT(5:5)),%REF(DESCRIP))O
	   CALL LIB$MOVC3(11,%REF(INPUT(58:58)),%REF(EXDATE))
	   CALL LIB$MOVC3(11,%REF(INPUT(69:69)),%REF(EXTIME))
	   CALL LIB$MOVC3(4,%REF(INPUT(80:80)),SYSTEM))
	   FOLDER1 = FOLDER
	   FOLDER_NUMBER = -1
	   CALL SELECT_FOLDER(.FALSE.,IER)L
	   IF (READ_ONLY.AND.
     &		FOLDER_OWNER.NE.USERNAME.AND..NOT.SETPRV_PRIV()) THENM
	      INPUT = 'ERROR: Insufficient privileges to add message.' 
	      CALL WRITE_CHAN(TRIM(INPUT),INPUT,UNIT_INDEX,IER)
	      GO TO 1000L
	   ELSE IF (SYSTEM.NE.0) THEN
	      IF (FOLDER_NUMBER.GT.0.AND.IBCLR(SYSTEM,1).NE.0.AND.C
     &			.NOT.BTEST(FOLDER_FLAG,2)) THEN	! Test if SYSTEM folder
		 SYSTEM = SYSTEM.AND.2
	         CALL GET_EXDATE(EXDATE,FOLDER_BBEXPIRE) 
	      END IF 
	      IF (SYSTEM.NE.0.AND..NOT.SETPRV_PRIV()) THEN	! Priv test 
		 IF (FOLDER_OWNER.NE.USERNAME) THENB
	            SYSTEM = 0	
		 ELSE					! Allow permanent if
		    SYSTEM = SYSTEM.AND.2		! owner of folder
	         END IF
	         CALL GET_EXDATE(EXDATE,FOLDER_BBEXPIRE)N
	      END IF:
	      IF (BTEST(SYSTEM,2)) THEN			! Shutdown?
	         CALL GET_NODE_NUMBER(NODE_NUMBER,NODE_AREA)R
	         WRITE (EXTIME,'(I4)') NODE_NUMBERR
	         WRITE (EXTIME(7:),'(I4)') NODE_AREAI
	         DO I=1,11E
		    IF (EXTIME(I:I).EQ.' ') EXTIME(I:I) = '0' 
	         END DO
	         EXTIME = EXTIME(1:2)//':'//EXTIME(3:4)//':'//A
     &			 EXTIME(7:8)//'.'//EXTIME(9:10)
	      END IFI
	   END IF
	   CALL LIB$MOVC3(4,%REF(INPUT(81:81)),BROAD)
	   IF (BROAD.AND..NOT.SETPRV_PRIV().AND..NOT.OPER_PRIV()) THEN_
	      BROAD = 0
	   END IF
	   CALL LIB$MOVC3(4,%REF(INPUT(85:85)),BELL)E
	   CALL LIB$MOVC3(4,%REF(INPUT(89:89)),ALL)
	   CALL LIB$MOVC3(4,%REF(INPUT(93:93)),CLUSTER)
	   FOLDER_FILE =C
     &		FOLDER_DIRECTORY(:TRIM(FOLDER_DIRECTORY))//FOLDERS
	   CALL OPEN_FILE(2)
	   CALL READDIR(0,IER)			! Get NBLOCK
	   IF (IER.EQ.0) NBLOCK = 0		! If new file, NBLOCK is 0
	   CALL OPEN_FILE(1)T
	   OENTRY = OUT_HEAD(UNIT_INDEX)_
	   LENGTH = LEN_SAVE(UNIT_INDEX)L
	   LEN_SAVE(UNIT_INDEX) = 0
	   DO I=1,LENGTH(
	      CALL READ_QUEUE(%VAL(OENTRY),OENTRY,INQUEUE)T
	      WRITE (1'NBLOCK+I) INQUEUE 
	   END DO
	   IF (BROAD) THENG
	      CALL GET_BROADCAST_MESSAGE(BELL)
	      CALL BROADCAST(ALL,CLUSTER)
	   END IF
	   CALL CLOSE_FILE(1)			! Finished adding bulletinT
	   CALL ADD_ENTRY			! Add the new directory entry
	   CALL UPDATE_FOLDER			! Update info in folder fileL
	   CALL CLOSE_FILE(2)			! Totally finished with add
	   CALL WRITE_CHAN(LEN(FOLDER_COM),FOLDER_COM,UNIT_INDEX,IER)

	   CALL SAVE_LAST_READ_BTIM(UNIT_INDEX)

	   IF (.NOT.BROAD) GO TO 1000

100	   CALL GETUSER(BULLCP_USER)		! Get present username
	   CALL OPEN_FILE_SHARED(4)		! Broadcast on other nodes
	   TEMP_USER = ':' 
	   DO WHILE (1)
	      DO WHILE (REC_LOCK(IER))		 
	         READ (4,KEYGT=TEMP_USER,IOSTAT=IER) 
     &		   TEMP_USER,LOGIN_BTIM,READ_BTIM,NEW_FLAG,USERNAME_
		 TEMP_USER = TEMP_USER(:TRIM(TEMP_USER))
		 IF (IER.EQ.0.AND.(TEMP_USER(2:).EQ.NODENAME
     &		     .OR..NOT.TEST2(NEW_FLAG,FOLDER_NUMBER))
     &		     .AND.TEMP_USER(:1).EQ.':') THEN
		    IER1 = REC_LOCK(IER)	! Skip the node thatT
		 END IF				! originated the messageO
	      END DOZ
	      IF (TEMP_USER(:1).NE.':') THENO
		 CALL CLOSE_FILE(4)T
		 CALL SETUSER(BULLCP_USER)
		 REMOTE_SET = .FALSE.P
	         CLOSE (UNIT=REMOTE_UNIT)
		 GO TO 1000T
	      END IF 
	      IER = SYS$SETIMR(%VAL(TIMEEFN),TIMEBUF,ENABLE_CTRL_EXIT,
     &			%VAL(1))=
	      CALL SETUSER(USERNAME)		! Reset to original username
	      FOLDER1 = 'GENERAL'
	      FOLDER1_BBOARD = ':'//TEMP_USER
	      CALL CONNECT_REMOTE_FOLDER(READ_ONLY,IER)
	      IF (IER.NE.0) THENT
		 CALL ERRSNS(IDUMMY,IDUMMY,INODE)F
	         IF (INODE.EQ.%LOC(SS$_NOSUCHNODE).OR.E
     &		     INODE.EQ.%LOC(SS$_NOSUCHOBJ).OR.INODE.EQ.0) THENG
		    DELETE (4)
		 END IFR
	      ELSE)
		 IER = 0
		 I = 1
		 DO WHILE (IER.EQ.0.AND.I.LT.BLENGTH)K
		    WRITE (REMOTE_UNIT,'(4A)',IOSTAT=IER) 
     &			15,-1,I,BMESSAGE(I:MIN(BLENGTH,I+127)) 
		    I = I + 128 
		 END DOL
		 IF (IER.EQ.0) WRITE (REMOTE_UNIT,'(5A)',IOSTAT=IER)
     &			15,BLENGTH,BELL,ALL,CLUSTER
	      END IFE
	      IER = SYS$CANTIM(%VAL(1),)E
	   END DO
	ELSE IF (CMD_TYPE.EQ.8) THEN		! Read directory entryE
	   CALL LIB$MOVC3(4,%REF(INPUT(5:5)),ICOUNT)T
	   FOLDER_FILE =(
     &		FOLDER_DIRECTORY(:TRIM(FOLDER_DIRECTORY))//FOLDERI
	   CALL OPEN_FILE_SHARED(2)
	   IF (ICOUNT.GE.0) THENI
	      CALL READDIR(ICOUNT,IER)I
	   ELSE
	      CALL LIB$MOVC3(8,%REF(INPUT(9:9)),%REF(MSG_KEY(1:1)))
	      CALL READDIR_KEYGE(IER)
	   END IF
	   CALL CLOSE_FILE(2)
	   CALL LIB$MOVC3(4,IER,%REF(INPUT(1:1)))
	   IF (ICOUNT.NE.0) THEN
	      INPUT(5:) = BULLDIR_ENTRY
	      CALL WRITE_CHAN
     &		(LEN(BULLDIR_ENTRY)+4,INPUT,UNIT_INDEX,IER)D
	   ELSE
	      INPUT(5:) = BULLDIR_HEADERO
	      CALL WRITE_CHAN
     &		(LEN(BULLDIR_HEADER)+4,INPUT,UNIT_INDEX,IER)
	   END IF
	ELSE IF (CMD_TYPE.EQ.13) THEN		! Read directory entry
	   CALL LIB$MOVC3(4,%REF(INPUT(5:5)),SBULL)
	   CALL LIB$MOVC3(4,%REF(INPUT(9:9)),EBULL)
	   FOLDER_FILE =A
     &		FOLDER_DIRECTORY(:TRIM(FOLDER_DIRECTORY))//FOLDERR
  	   CALL OPEN_FILE_SHARED(2)
	   OENTRY = OUT_HEAD(UNIT_INDEX) 
	   DO I=SBULL,EBULL,ISIGN(1,EBULL-SBULL)R
	      CALL READDIR(I,IER)
	      INQUEUE = BULLDIR_ENTRY
              CALL WRITE_QUEUE(%VAL(OENTRY),OENTRY,INQUEUE)(
	   END DO
	   CALL CLOSE_FILE(2)
	   OENTRY = OUT_HEAD(UNIT_INDEX)U
	   REC_SAVE(UNIT_INDEX) = LEN(BULLDIR_ENTRY)
	   LEN_SAVE(UNIT_INDEX) = ABS(EBULL - SBULL) + 1U
           CALL READ_QUEUE(%VAL(OENTRY),OENTRY,INQUEUE)I
	   OUT_SAVE(UNIT_INDEX) = OENTRYO
	   CALL WRITE_CHAN(REC_SAVE(UNIT_INDEX),INQUEUE,UNIT_INDEX,IER)
	ELSE IF (CMD_TYPE.EQ.9) THEN		! Write directory entry
	   CALL LIB$MOVC3(4,%REF(INPUT(5:5)),ICOUNT)E
	   FOLDER_FILE =L
     &		FOLDER_DIRECTORY(:TRIM(FOLDER_DIRECTORY))//FOLDERV
	   CALL OPEN_FILE(2)I
	   IF (ICOUNT.GT.0) THENX
	      BULLDIR_ENTRY = INPUT(9:)
	      CALL WRITEDIR_NOCONV(ICOUNT,IER)N
	   ELSE
	      BULLDIR_HEADER = INPUT(9:)D
	      CALL WRITEDIR_NOCONV(ICOUNT,IER)
	   END IF
	   CALL CLOSE_FILE(2)
	ELSE IF (CMD_TYPE.EQ.4) THENT
	   CALL LIB$MOVC3(4,%REF(INPUT(5:5)),BULL_DELETE)
	   CALL LIB$MOVC3(4,%REF(INPUT(9:9)),IMMEDIATE)
	   DESCRIP_TEMP = INPUT(13:ILEN))
	   FOLDER1 = FOLDER
	   FOLDER_NUMBER = -1
	   CALL SELECT_FOLDER(.FALSE.,IER).
	   CALL OPEN_FILE(2)5
	   CALL READDIR(BULL_DELETE,IER) 
	   IF (IER.EQ.BULL_DELETE.OR.DESCRIP.NE.DESCRIP_TEMP) THEN 
	      CALL CLOSE_FILE(2)_
	      INPUT = 'ERROR: Cannot find message to delete.'
	      CALL WRITE_CHAN(TRIM(INPUT),INPUT,UNIT_INDEX,IER)
	      GO TO 1000B
	   ELSE IF (USERNAME.NE.FROM.AND.FROM_SAVE(UNIT_INDEX).NE.FROMU
     &	    .AND.FOLDER_OWNER.NE.USERNAME.AND..NOT.SETPRV_PRIV()) THEN
	      CALL CLOSE_FILE(2)%
	      INPUT = 'ERROR: Insufficient privileges to delete message.'
	      CALL WRITE_CHAN(TRIM(INPUT),INPUT,UNIT_INDEX,IER)
	      GO TO 1000 
	   END IF
	   CALL REMOVE_ENTRYF
     &		(BULL_DELETE,BULL_DELETE,BULL_DELETE,IMMEDIATE)S
	   CALL CLOSE_FILE(2)
	   CALL WRITE_CHAN(LEN(FOLDER_COM),FOLDER_COM,UNIT_INDEX,IER)
	ELSE IF (CMD_TYPE.EQ.5) THEN		! Read message
	   CALL LIB$MOVC3(4,%REF(INPUT(5:5)),ICOUNT) 
	   FOLDER_FILE =(
     &		FOLDER_DIRECTORY(:TRIM(FOLDER_DIRECTORY))//FOLDER)
	   CALL OPEN_FILE_SHARED(2)
	   CALL READDIR(ICOUNT,IER)
	   CALL OPEN_FILE_SHARED(1)
	   OENTRY = OUT_HEAD(UNIT_INDEX)U
	   DO I=BLOCK,BLOCK+LENGTH-1L
	      READ (1'I,IOSTAT=IER) INQUEUE
              CALL WRITE_QUEUE(%VAL(OENTRY),OENTRY,INQUEUE) 
	   END DO
	   CALL CLOSE_FILE(1)
	   CALL CLOSE_FILE(2)
	   OENTRY = OUT_HEAD(UNIT_INDEX)E
	   REC_SAVE(UNIT_INDEX) = 128
	   LEN_SAVE(UNIT_INDEX) = LENGTH(
           CALL READ_QUEUE(%VAL(OENTRY),OENTRY,INQUEUE)_
	   OUT_SAVE(UNIT_INDEX) = OENTRYD
	   CALL WRITE_CHAN(REC_SAVE(UNIT_INDEX),INQUEUE,UNIT_INDEX,IER)
	   CALL SAVE_LAST_READ_BTIM(UNIT_INDEX)
	ELSE IF (CMD_TYPE.EQ.10) THEN		! Replacing bulletin
	   FOLDER1 = FOLDER
	   FOLDER_NUMBER = -1
	   CALL SELECT_FOLDER(.FALSE.,IER)I
	   FOLDER_FILE =X
     &		FOLDER_DIRECTORY(:TRIM(FOLDER_DIRECTORY))//FOLDERE
	   CALL OPEN_FILE(2)4
	   CALL LIB$MOVC3(53,%REF(INPUT(5:5)),%REF(DESCRIP_TEMP))
	   CALL LIB$MOVC3(4,%REF(INPUT(58:58)),ICOUNT)R
	   CALL READDIR(ICOUNT,IER)
	   IF (IER.EQ.ICOUNT.OR.DESCRIP_TEMP.NE.DESCRIP) THEN
	      CALL CLOSE_FILE(2):
	      INPUT = 'ERROR: Cannot find message to replace.'R
	      CALL WRITE_CHAN(TRIM(INPUT),INPUT,UNIT_INDEX,IER)
	      GO TO 1000S
	   END IF
	   CALL LIB$MOVC3(53,%REF(INPUT(62:62)),%REF(DESCRIP))E
	   CALL LIB$MOVC3(4,%REF(INPUT(115:115)),%REF(MSGTYPE))
	   CALL LIB$MOVC3(11,%REF(INPUT(119:119)),%REF(EXDATE))
	   CALL LIB$MOVC3(11,%REF(INPUT(130:130)),%REF(EXTIME))
	   ALLOW = (FOLDER_OWNER.EQ.USERNAME).OR.SETPRV_PRIV()s
	   IF ((FOLDER_NUMBER.GT.0.AND.(BTEST(MSGTYPE,0).OR. 
     &		BTEST(MSGTYPE,2)).AND..NOT.BTEST(FOLDER_FLAG,2)).OR.
     &		(USERNAME.NE.FROM.AND..NOT.ALLOW).OR. 
     &		((MSGTYPE.AND..NOT.8).NE.0.AND..NOT.ALLOW)) THEN
	      CALL CLOSE_FILE(2)E
	      INPUT = 'ERROR: Insufficient privileges to replace message.'_
	      CALL WRITE_CHAN(TRIM(INPUT),INPUT,UNIT_INDEX,IER)
	      GO TO 1000R
	   END IF
	   CALL READDIR(0,IER)			! Get NBLOCK
	   CALL OPEN_FILE(1)I
	   NEW_LENGTH = LEN_SAVE(UNIT_INDEX) 
	   LEN_SAVE(UNIT_INDEX) = 0
	   OENTRY = OUT_HEAD(UNIT_INDEX)A
	   DO I=1,NEW_LENGTH/
	      CALL READ_QUEUE(%VAL(OENTRY),OENTRY,INQUEUE)A
	      WRITE (1'NBLOCK+I) INQUEUER
	   END DO
	   CALL CLOSE_FILE(1)			! Finished adding bulletinT
	   IF (NEW_LENGTH.GT.0) THEN 
	      NEMPTY = NEMPTY + LENGTHU
	      LENGTH = NEW_LENGTH
	      BLOCK = NBLOCK + 1)
	   END IF
	   CALL WRITEDIR(ICOUNT,IER)9
	   NBLOCK = NBLOCK + NEW_LENGTH
	   CALL WRITEDIR(0,IER)
	   CALL UPDATE_DIR_HEADER(BTEST(MSGTYPE,3),BTEST(MSGTYPE,1),A
     &		BTEST(MSGTYPE,2),EXDATE,EXTIME)(
	   IF (BTEST(MSGTYPE,0)) THEN
	      SYSTEM = IBSET(SYSTEM,0)		! System?
	   ELSE
	      SYSTEM = IBCLR(SYSTEM,0)		! General?(
	   END IF
	   CALL WRITEDIR(ICOUNT,IER)
	   CALL CLOSE_FILE(2)
	   CALL WRITE_CHAN(LEN(FOLDER_COM),FOLDER_COM,UNIT_INDEX,IER)
	ELSE IF (CMD_TYPE.EQ.11) THEN		! Undeleting
	   CALL LIB$MOVC3(4,%REF(INPUT(5:5)),BULL_DELETE)
	   DESCRIP_TEMP = INPUT(9:61)
	   FOLDER1 = FOLDER
	   FOLDER_NUMBER = -1
	   CALL SELECT_FOLDER(.FALSE.,IER)E
	   CALL OPEN_FILE(2)r
	   CALL READDIR(BULL_DELETE,IER)R
	   IF (IER.EQ.BULL_DELETE.OR.DESCRIP.NE.DESCRIP_TEMP) THENT
	      CALL CLOSE_FILE(2) 
	      INPUT = 'ERROR: Cannot find message to undelete.'
	      CALL WRITE_CHAN(TRIM(INPUT),INPUT,UNIT_INDEX,IER)
	      GO TO 10000
	   ELSE IF (USERNAME.NE.FROM.AND.FROM_SAVE(UNIT_INDEX).NE.FROM 
     &	    .AND.FOLDER_OWNER.NE.USERNAME.AND..NOT.SETPRV_PRIV()) THEN 
	      CALL CLOSE_FILE(2) 
	      INPUT = 'ERROR: Insufficient privileges to undelete message.'
	      CALL WRITE_CHAN(TRIM(INPUT),INPUT,UNIT_INDEX,IER)
	      GO TO 1000M
	   END IF
	   CALL LIB$MOVC3(11,%REF(INPUT(62:62)),%REF(EXDATE))
	   CALL LIB$MOVC3(11,%REF(INPUT(73:73)),%REF(EXTIME))
	   CALL WRITEDIR(BULL_DELETE,IER)
	   CALL CLOSE_FILE(2)
	   CALL WRITE_CHAN(LEN(FOLDER_COM),FOLDER_COM,UNIT_INDEX,IER)
	ELSE IF (CMD_TYPE.EQ.12) THEN		! Find newest bulletin
	   FOLDER_FILE =)
     &		FOLDER_DIRECTORY(:TRIM(FOLDER_DIRECTORY))//FOLDER)
	   CALL OPEN_FILE_SHARED(2)
	   CALL READDIR(0,IER)E
	   CALL GET_NEWEST_MSG(%REF(INPUT(5:5)),BULL_POINT)
	   CALL CLOSE_FILE(2)
	   CALL WRITE_CHAN(4,%DESCR(BULL_POINT),UNIT_INDEX,IER)
	ELSE IF (CMD_TYPE.EQ.14) THEN		! Register remote folder
	   CALL LIB$MOVC3(4,%REF(INPUT(5:5)),FLAG) 
	   FOLDER1 = FOLDER
	   FOLDER_NUMBER = -1
	   CALL SELECT_FOLDER(.FALSE.,IER).
	   CALL OPEN_FILE_SHARED(4)
	   NODENAME = INPUT(9:)
	   TEMP_USER = ':'//NODENAME(:TRIM(NODENAME))
	   DO WHILE (REC_LOCK(IER))
	      READ (4,KEY=TEMP_USER,IOSTAT=IER) )
     &		TEMP_USER,LOGIN_BTIM,READ_BTIM,NEW_FLAG
	   END DO
	   IF (IER.NE.0) THEN
	      DO I=1,FLONGM
		 NEW_FLAG (I) = 0T
	      END DO	
	   END IF
	   IF (FLAG) THEN
	      CALL SET2(NEW_FLAG,FOLDER_NUMBER)
	   ELSE
	      CALL CLR2(NEW_FLAG,FOLDER_NUMBER)
	   END IF
	   IF (IER.EQ.0) THEN
	      REWRITE (4) TEMP_USER,R
     &				LOGIN_BTIM,READ_BTIM,NEW_FLAG,USERNAME
	   ELSE
	      TEMP_USER =  ':'//NODENAME(:TRIM(NODENAME))
	      WRITE (4) TEMP_USER,
     &				LOGIN_BTIM,READ_BTIM,NEW_FLAG,USERNAME
	   END IF
	   CALL CLOSE_FILE(4)
	ELSE IF (CMD_TYPE.EQ.15) THEN		! Broadcast message 
	   CALL LIB$MOVC3(4,%REF(INPUT(5:5)),BLENGTH)
	   CALL LIB$MOVC3(4,%REF(INPUT(9:9)),START)
	   IF (BLENGTH.EQ.-1) THEN_
	      IF (SCRATCH(UNIT_INDEX).EQ.0) THEN(
		 CALL LIB$GET_VM(BRDCST_LIMIT,SCRATCH(UNIT_INDEX))
	      END IFT
	      CALL LIB$MOVC3(ILEN-12,%REF(INPUT(13:13)), 
     &				%VAL(SCRATCH(UNIT_INDEX)+START-1))
	   ELSE
	      CALL LIB$MOVC3(BLENGTH,%VAL(SCRATCH(UNIT_INDEX)),
     &				%REF(BMESSAGE(1:1)))
	      CALL LIB$MOVC3(4,%REF(INPUT(13:13)),ALL)N
	      CALL LIB$MOVC3(4,%REF(INPUT(17:17)),CLUSTER)y
	      CALL LIB$FREE_VM(BRDCST_LIMIT,SCRATCH(UNIT_INDEX))A
	      IF (ILEN.GT.20) THEN)
	         CALL LIB$MOVC3(4,%REF(INPUT(21:21)),FOLDER_NUMBER)
	         FOLDER = INPUT(25:) 
		 GO TO 100
	      ELSE IF (SETPRV_PRIV().OR.OPER_PRIV()) THEN
	         CALL BROADCAST(ALL,CLUSTER)R
	      END IFE
	   END IF
	END IFI

1000	PROCPRIV(1) = BULLCP_PRIV(1) 
	PROCPRIV(2) = BULLCP_PRIV(2)E

	RETURNE
	END



	SUBROUTINE UPDATE_REMOTE_USERINFO(UNIT_INDEX)

	IMPLICIT INTEGER (A-Z)E

	INCLUDE 'BULLUSER.INC'E

	INCLUDE 'BULLDIR.INC'

	INCLUDE 'BULLFOLDER.INC' 

	PARAMETER MAXLINK = 10E

	COMMON /CONNECT_STATUS/ FOLDER_NUM(MAXLINK),OUT_NUM(MAXLINK)R
	COMMON /CONNECT_STATUS/ USER_SAVE(MAXLINK),FOLDER_NAME(MAXLINK)
	COMMON /CONNECT_STATUS/ FROM_SAVE(MAXLINK),PRIV_SAVE(2,MAXLINK)
	COMMON /CONNECT_STATUS/ NODE_SAVE(MAXLINK),OUT_SAVE(MAXLINK) 
	COMMON /CONNECT_STATUS/ REC_SAVE(MAXLINK),LEN_SAVE(MAXLINK)
	COMMON /CONNECT_STATUS/ LAST_SAVE(2,MAXLINK)
	CHARACTER USER_SAVE*12,FOLDER_NAME*25,FROM_SAVE*12,NODE_SAVE*12

	DIMENSION SAVE_BTIM(2)B

	USERNAME = USER_SAVE(UNIT_INDEX)L
	FOLDER_NUMBER = FOLDER_NUM(UNIT_INDEX)F

	IF (USERNAME.EQ.'DECNET'.OR.FOLDER_NUMBER.LT.0) RETURN 

	CALL OPEN_USERINFO(
	DIFF = COMPARE_BTIM(LAST_READ_BTIM(1,FOLDER_NUMBER+1),(
     &				LAST_SAVE(1,UNIT_INDEX))
	IF (DIFF.GE.0) RETURN
	LAST_READ_BTIM(1,FOLDER_NUMBER+1) = LAST_SAVE(1,UNIT_INDEX)
	LAST_READ_BTIM(2,FOLDER_NUMBER+1) = LAST_SAVE(2,UNIT_INDEX)
	CALL UPDATE_USERINFOE

	RETURNE

	ENTRY SAVE_LAST_READ_BTIM(UNIT_INDEX)

	CALL SYS_BINTIM(DATE//' '//TIME,SAVE_BTIM):

	DIFF = COMPARE_BTIM(LAST_SAVE(1,UNIT_INDEX),SAVE_BTIM)I

	IF (DIFF.GE.0) RETURN

	LAST_SAVE(1,UNIT_INDEX) = SAVE_BTIM(1)N
	LAST_SAVE(2,UNIT_INDEX) = SAVE_BTIM(2)F

	RETURN&

	END